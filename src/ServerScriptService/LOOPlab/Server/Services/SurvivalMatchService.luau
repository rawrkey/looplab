-- SurvivalMatchService: the flagship LOOPLAB mode.
-- Lobby -> N rounds of elimination down to one winner, using activities.
-- Orchestrates: pull players from queue -> lobby countdown -> rounds -> winner.

local RunService = game:GetService("RunService")
if RunService:IsClient() then
	return {}
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteBuilder = require(ReplicatedStorage.LOOPlab.Shared.RemoteBuilder)
local ActivityService = require(script.Parent.ActivityService)
local GameConfig = require(ReplicatedStorage.LOOPlab.Configuration.GameConfig)
local Analytics = require(script.Parent.AnalyticsService)
local RewardService = require(script.Parent.RewardService)
local Spectator = require(script.Parent.SpectatorService)
local Leaderboard = require(script.Parent.LeaderboardService)
local PlayerData = require(script.Parent.PlayerDataService)
local Registry = require(ReplicatedStorage.LOOPlab.Shared.ActivityRegistry)

local Service = {}
local _remotes = RemoteBuilder.GetAll()

local _match = nil -- { players, alive = {uid=true}, status, round, sessionId, eliminationOrder, survivedRounds }

local function survivalActivityIds(): { string }
	local ids = {}
	for id, def in pairs(Registry.List()) do
		if def.SupportsSurvival then table.insert(ids, id) end
	end
	return ids
end

function Service.GetAlivePlayers(): { Player }
	local out = {}
	if not _match then return out end
	for _, p in _match.players do
		if p.Parent and _match.alive[p.UserId] then
			table.insert(out, p)
		end
	end
	return out
end

function Service.IsMatchRunning(): boolean
	return _match ~= nil and _match.status ~= "done"
end

-- Entry point: called by QueueService when the survival lobby is full/ready.
function Service.StartSurvivalMatch(players: { Player }): boolean
	if _match then return false end
	if #players < GameConfig.Survival.MinFill then
		return false
	end

	_match = {
		players = players,
		alive = {},
		status = "lobby",
		round = 0,
		sessionId = tostring(os.time()) .. ":" .. tostring(math.random(1, 99999)),
		eliminationOrder = {},
		survivedRounds = {},
	}
	for _, p in players do
		_match.alive[p.UserId] = true
		_match.survivedRounds[p.UserId] = 0
	end

	for _, p in players do
		_remotes.Events.LobbyUpdate:FireClient(p, {
			Kind = "LobbyUpdate",
			SessionId = _match.sessionId,
			Players = #players,
			Countdown = GameConfig.Survival.LobbyCountdown,
			Rounds = GameConfig.Survival.Rounds,
		})
	end

	Analytics.Fire(players[1], "SurvivalStart", { a = "survival", b = tostring(#players) })

	task.spawn(function()
		-- lobby countdown
		local t = GameConfig.Survival.LobbyCountdown
		while t > 0 do
			task.wait(1)
			t -= 1
		end
		if not _match then return end
		for round = 1, GameConfig.Survival.Rounds do
			if not _match or _match.status == "done" then break end
			local over = Service.RunRound(round)
			if over then break end
		end
	end)

	return true
end

-- Carry players into the next phase; returns true when the match is finished.
function Service.RunRound(roundNumber: number): boolean
	local alive = Service.GetAlivePlayers()
	if #alive <= 1 then
		Service.FinishMatch(alive[1])
		return true
	end

	_match.status = "round"
	_match.round = roundNumber

	local pool = survivalActivityIds()
	local activityId = pool[math.random(1, #pool)]

	local introPayload = {
		Kind = "RoundBegin",
		Round = roundNumber,
		TotalRounds = GameConfig.Survival.Rounds,
		ActivityId = activityId,
		Count = #alive,
		Message = ("Round %d / %d — %s"):format(roundNumber, GameConfig.Survival.Rounds, tostring(Registry.Get(activityId) and Registry.Get(activityId).Name or activityId)),
	}
	for _, p in _match.players do
		_remotes.Events.RoundBegin:FireClient(p, introPayload)
	end

	local res, err = ActivityService.CreateSession(activityId, "Survival", "Normal", alive)
	if not res then
		warn("[Survival] round create failed: " .. tostring(err))
		return Service.RunRound(roundNumber + 1)
	end

	-- wait for completion
	while res.session.Result == nil do
		task.wait(0.25)
		if not _match then return true end -- cancelled
	end
	local scoresheet = res.session.Result
	local rows = scoresheet.Rows -- best-first

	local n = #rows
	local frac = GameConfig.Survival.SurvivorFractions[math.min(roundNumber, #GameConfig.Survival.SurvivorFractions)]
	local keepCount = math.max(1, math.floor(n * frac + 0.5))
	if roundNumber >= GameConfig.Survival.Rounds then keepCount = 1 end
	if #alive <= keepCount then keepCount = math.max(1, #alive - 1) end

	local kept = {}
	local eliminated = {}
	for i, row in rows do
		local p = row.Player
		if p and p.Parent and _match.alive[p.UserId] then
			if i <= keepCount then
				table.insert(kept, p.UserId)
				_match.survivedRounds[p.UserId] = (_match.survivedRounds[p.UserId] or 0) + 1
			else
				table.insert(eliminated, p.UserId)
			end
		end
	end

	-- apply eliminations
	for _, uid in eliminated do
		if _match then
			_match.alive[uid] = nil
			table.insert(_match.eliminationOrder, uid)
		end
		local p = Players:GetPlayerByUserId(uid)
		if p then Spectator.Reset(p) end
	end

	-- survived-round participation rewards
	for _, uid in kept do
		local p = Players:GetPlayerByUserId(uid)
		if p then RewardService.GrantSurvivalRound(p, roundNumber, _match.sessionId) end
	end

	-- broadcast round end
	local endPayload = {
		Kind = "RoundEnd",
		Round = roundNumber,
		TotalRounds = GameConfig.Survival.Rounds,
		EliminatedUserIds = eliminated,
		SurvivorUserIds = kept,
		ActivityId = activityId,
	}
	for _, p in _match.players do
		_remotes.Events.RoundEnd:FireClient(p, endPayload)
	end

	task.wait(GameConfig.Survival.RoundTransitionSeconds)

	return #kept <= 1
end

function Service.FinishMatch(winner: Player?)
	if not _match then return end
	local finalAlive = Service.GetAlivePlayers()
	local w = winner or finalAlive[1]
	_match.status = "done"

	-- placements: winner=1, else reverse of elimination order.
	local placements = {}
	if w and _match.alive[w.UserId] then
		placements[w.UserId] = 1
	end
	local nextPlace = 2
	for i = #_match.eliminationOrder, 1, -1 do
		local uid = _match.eliminationOrder[i]
		placements[uid] = nextPlace
		nextPlace += 1
	end
	local rows = {}
	for _, p in _match.players do
		table.insert(rows, {
			UserId = p.UserId,
			Name = p.DisplayName,
			Place = placements[p.UserId] or 1,
		})
	end
	table.sort(rows, function(a, b) return a.Place < b.Place end)

	-- rewards + stats
	for _, p in _match.players do
		local place = placements[p.UserId] or 1
		local data = PlayerData.GetForPlayer(p)
		data.Survival.Matches += 1
		data.Survival.RoundsSurvived += _match.survivedRounds[p.UserId] or 0
		if place == 1 then
			data.Survival.Wins += 1
			RewardService.GrantSurvivalOutcome(p, 1, _match.sessionId)
		elseif place <= 3 then
			data.Survival.Podiums += 1
			RewardService.GrantSurvivalOutcome(p, place, _match.sessionId)
		end
		Leaderboard.SubmitSurvival(p)
	end

	if w then
		local payload = {
			Kind = "Winner",
			SessionId = _match.sessionId,
			WinnerUserId = w.UserId,
			WinnerName = w.DisplayName,
			Round = _match.round,
			TotalRounds = GameConfig.Survival.Rounds,
			Rows = rows,
		}
		for _, p in _match.players do
			_remotes.Events.Winner:FireClient(p, payload)
		end
		Analytics.Fire(w, "SurvivalWin", { a = "survival", b = tostring(_match.round) })
	end

	-- persist then release
	for _, p in _match.players do
		PlayerData.SavePlayer(p)
	end
	_match = nil
end

function Service.GetMatch()
	return _match
end

return Service