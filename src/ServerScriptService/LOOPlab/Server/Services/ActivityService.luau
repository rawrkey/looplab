-- ActivityService: orchestrates activity sessions (standalone & survival).

local RunService = game:GetService("RunService")
if RunService:IsClient() then return {} end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Registry = require(ReplicatedStorage.LOOPlab.Shared.ActivityRegistry)
local RemoteBuilder = require(ReplicatedStorage.LOOPlab.Shared.RemoteBuilder)
local Analytics = require(script.Parent.AnalyticsService)

local ActivityService = {}
local _remotes = RemoteBuilder.GetAll()
local _active = {}
local _lastResults = {}

function ActivityService.CreateSession(activityId: string, mode: string, difficulty: string, players: { Player })
	local def = Registry.Get(activityId)
	if not def then return nil, "unknown activity" end
	if def.SupportsSurvival == false and mode == "Survival" then return nil, "not survival compatible" end

	local sessionId = tostring(os.time()) .. ":" .. tostring(math.random(1, 99999))
	local duration = mode == "Survival" and def.SurvivalDurationSeconds or def.DurationSeconds

	local session = {
		Id = sessionId,
		ActivityId = activityId,
		ActivityName = def.Name,
		Mode = mode,
		Difficulty = difficulty,
		Duration = duration,
		Players = players,
		Started = os.clock(),
	}

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

	gameSession.OnUpdate = function(payload)
		for _, p in players do
			_remotes.Events.ActivityUpdate:FireClient(p, payload)
		end
		-- Route lightweight gameplay feedback through the established poll Fx
		-- queue (server-authoritative, coalesced per poll). Optional per-player
		-- targeting via Fx.TargetUserId.
		if payload and type(payload.Fx) == "table" then
			local Poll = require(script.Parent.PollService)
			local fx = payload.Fx
			local target = fx.TargetUserId
			if target then
				for _, p in players do
					if p.UserId == target then
						Poll.TrackFx(p, { Kind = fx.Kind, Data = fx.Data })
						break
					end
				end
			else
				for _, p in players do
					Poll.TrackFx(p, { Kind = fx.Kind, Data = fx.Data })
				end
			end
		end
	end
	gameSession.OnResult = function(scoresheet)
		session.Result = scoresheet
	end

	_active[sessionId] = session

	local started = os.clock()
	session.Game.Start(session.Game)

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

	if session.Mode == "Standalone" and result and result.Rows then
		local winnerId = 0
		local winnerName = "none"
		local best = -1
		for _, row in result.Rows do
			local score = row.Score or row.Place or 0
			if score > best then
				best = score
				winnerId = row.Player and row.Player.UserId or row.UserId or 0
				winnerName = row.Player and row.Player.Name or row.Name or "none"
			end
		end
		for _, p in session.Players do
			if not p then continue end
			_lastResults[p.UserId] = {
				Mode = "Results",
				GameMode = "Standalone",
				ActivityId = session.ActivityId,
				ActivityName = session.ActivityName or session.ActivityId,
				Rows = result.Rows,
				Rewards = {},
				WinnerUserId = winnerId,
				WinnerName = winnerName,
			}
		end
	end

	return result
end

function ActivityService.IsActive(sessionId)
	return _active[sessionId] ~= nil
end

function ActivityService.GetClientSync(player)
	for id, session in pairs(_active) do
		if session.Mode == "Standalone" then
			for _, p in session.Players do
				if p == player then
					return {
						Mode = "Standalone",
						Phase = "Running",
						Round = 1,
						TotalRounds = 1,
						ActivityId = session.ActivityId,
						ActivityName = session.ActivityName or session.ActivityId,
						TimeLeft = math.max(0, session.Duration - (os.clock() - session.Started)),
					}
				end
			end
		end
	end
	return _lastResults[player.UserId]
end

local _routed = false
function ActivityService.Setup()
	if _routed then return end
	_routed = true
	local guard = require(script.Parent.RemoteGuardService)
	guard.BindEvent(_remotes.Events.ActivityInput, function(player: Player, activityId: any, action: any, data: any)
		if type(activityId) ~= "string" or type(action) ~= "string" then return end
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