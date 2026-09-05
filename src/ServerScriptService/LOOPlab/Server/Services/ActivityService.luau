-- ActivityService: orchestrates activity sessions (standalone & survival).
-- Consumes ActivityRegistry. Knows the generic lifecycle: start -> tick -> end -> result.
-- Games implement the ActivityContract; they do NOT know about survival vs standalone.

local RunService = game:GetService("RunService")
if RunService:IsClient() then
	return {}
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Registry = require(ReplicatedStorage.LOOPlab.Shared.ActivityRegistry)
local RemoteBuilder = require(ReplicatedStorage.LOOPlab.Shared.RemoteBuilder)
local Analytics = require(script.Parent.AnalyticsService)

local ActivityService = {}
local _remotes = RemoteBuilder.GetAll()

-- Sessions being run right now, keyed by session id.
local _active = {}

-- Create a new session for a set of players.
-- Returns { sessionId, broadcast, finish } or nil on error.
function ActivityService.CreateSession(activityId: string, mode: string, difficulty: string, players: { Player })
	local def = Registry.Get(activityId)
	if not def then return nil, "unknown activity" end
	if def.SupportsSurvival == false and mode == "Survival" then return nil, "not survival compatible" end

	local sessionId = tostring(os.time()) .. ":" .. tostring(math.random(1, 99999))
	local duration = mode == "Survival" and def.SurvivalDurationSeconds or def.DurationSeconds

	local session = {
		Id = sessionId,
		ActivityId = activityId,
		Mode = mode,
		Difficulty = difficulty,
		Duration = duration,
		Players = players,
	}

	-- server-side per-game session instance
	local ok, gameSession = pcall(def.Server.Create, {
		ActivityId = activityId,
		Mode = mode,
		Difficulty = difficulty,
		Duration = duration,
		Players = players,
	})
	if not ok then
		warn("[ActivityService] create failed: " .. tostring(gameSession))
		return nil, "create failed"
	end

	session.Game = gameSession

	-- generic broadcast helpers wired into the game session so games don't touch remotes directly
	gameSession.OnUpdate = function(payload)
		for _, p in players do
			_remotes.Events.ActivityUpdate:FireClient(p, payload)
		end
	end
	gameSession.OnResult = function(scoresheet)
		session.Result = scoresheet
	end

	_active[sessionId] = session

	local started = os.clock()
	session.Game.Start(session.Game)

	-- Timer: fire Tick requests to the game & auto-end when time is up or the
	-- game reported a result early (via OnResult).
	task.spawn(function()
		while _active[sessionId] do
			task.wait(0.25)
			if not _active[sessionId] then break end
			if session.Game and session.Game.Tick then
				pcall(session.Game.Tick, session.Game, 0.25)
			end
			if session.Result then
				ActivityService.EndSession(sessionId)
				break
			end
			local elapsed = os.clock() - started
			if elapsed >= session.Duration then
				session.ForceEndedByTimer = true
				ActivityService.EndSession(sessionId)
				break
			end
		end
	end)

	return { sessionId = sessionId, session = session, broadcast = _remotes.Events }
end

-- End a session: collect result from game, clean up, return scoresheet.
function ActivityService.EndSession(sessionId: string)
	local session = _active[sessionId]
	if not session then return nil end

	if session.Game then
		if not session.Result and session.Game.ForceFinish then
			pcall(session.Game.ForceFinish, session.Game)
		end
		pcall(session.Game.Cleanup, session.Game)
	end

	if not session.Result then
		-- fallback: never trust a missing report; build a degenerate scoresheet so
		-- Survival can continue deterministically.
		local rows = {}
		for _, p in session.Players do
			table.insert(rows, { Player = p, Score = 0, Time = os.clock(), Ranks = {} })
		end
		session.Result = {
			ActivityId = session.ActivityId,
			Mode = session.Mode,
			Duration = session.Duration,
			Rows = rows,
		}
	end
	local result = session.Result
	_active[sessionId] = nil
	return result
end

-- Get sorted scoresheet (rows best-first) from session.
function ActivityService.GetScoresheet(sessionId)
	local session = _active[sessionId]
	if not session then return nil end
	return session.Result
end

function ActivityService.IsActive(sessionId)
	return _active[sessionId] ~= nil
end

-- Bind the shared ActivityInput remote: routes to whichever active session the
-- player is in. Games receive (player, action, data) through session.HandleInput.
local _routed = false
function ActivityService.Setup()
	if _routed then return end
	_routed = true
	local guard = require(script.Parent.RemoteGuardService)
	guard.BindEvent(_remotes.Events.ActivityInput, function(player: Player, activityId: any, action: any, data: any)
		if type(activityId) ~= "string" or type(action) ~= "string" then return end
		if not guard.Sane(data) then return end
		for id, session in pairs(_active) do
			if session.ActivityId == activityId then
				for _, p in session.Players do
					if p == player then
						if session.Game and session.Game.HandleInput then
							pcall(session.Game.HandleInput, session.Game, player, action, data)
						end
						return
					end
				end
			end
		end
	end, "ActivityInput")
end

return ActivityService