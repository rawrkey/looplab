-- SurvivalMatchService: the flagship LOOPLAB mode.
-- 10-player lobby -> N rounds of elimination down to a winner, using activities.
-- Orchestrates queue->lobby->rounds->winner via ActivityService.

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

local Service = {}
local _remotes = RemoteBuilder.GetAll()
local Registry = require(ReplicatedStorage.LOOPlab.Shared.ActivityRegistry)

local _match = nil -- { players = {Player}, status = "lobby"|"round"|"results"|"done", round = number, ... }

-- Which activities are survival-compatible (from registry).
local function survivalActivities(): { string }
	local ids = {}
	for id, def in pairs(Registry.List()) do
		if def.SupportsSurvival then table.insert(ids, id) end
	end
	return ids
end

function Service.GetAlivePlayers(): { Player }
	if not _match then return {} end
	local out = {}
	for _, p in _match.players do
		if p.Parent and _match.alive[p.UserId] then
			table.insert(out, p)
		end
	end
	return out
end

function Service.StartMatch(force: boolean): boolean
	if _match then return false end
	-- Pull from queue service state.
	local Queue = require(script.Parent.QueueService)
	local q = nil -- survival queue is read via QueueService
	-- We lack a direct handler; instead requeue approach: fetch from queue service.

	-- Actually we get players via queue. For MVP, we pull all queued.
	-- Standalone survival queue injection is handled by QueueService.StartSurvival calling this.
	-- It passes players implicitly; we'll read them from the service table.
	local survivalQueue = require(script.Parent.QueueService)
	return true
end

function Service.StartSurvivalMatch(players: { Player })
	if _match then return false end
	if #players < GameConfig.Survival.MinFill then
		for _, p in players do
			_remotes.Events.Toast:FireClient(p, { message = "Not enough players to start Survival." })
		end
		return false
	end

	match = {
		players = players,
		alive = {},
		status = "lobby",
		round = 0,
		sessionId = tostring(os.time()) .. ":" .. tostring(math.random(1, 99999)),
	}

	for _, p in players do match.alive[p.UserId] = true end
	Analytics.Fire(players[1], "SurvivalStart", { a = "survival", b = tostring(#players) })

	-- lobby broadcast + countdown handled by QueueService, then rounds.
	task.spawn(function()
		task.wait(GameConfig.Survival.LobbyCountdown)
		for round = 1, GameConfig.Survival.Rounds do
			local over = Service.RunRound(round)
			if over then break end
		end
	end)

	return true
end

-- Run a single round. Returns 'over' = true if match finished.
function Service.RunRound(roundNumber: number): boolean
	local alive = Service.GetAlivePlayers()
	if _match.status == "done" then return true end
	if #alive <= 1 then
		Service.FinishMatch(alive[1])
		return true
	end

	_match.status = "round"
	_match.round = roundNumber

	-- Pick a random survival-compatible activity per round.
	local pool = survivalActivities()
	local activityId = pool[math.random(1, #pool)]

	-- Intro broadcast.
	local introPayload = {
		Kind = "RoundBegin",
		Round = roundNumber,
		TotalRounds = GameConfig.Survival.Rounds,
		ActivityId = activityId,
		Count = #alive,
		Message = ("Round %d / %d"):format(roundNumber, GameConfig.Survival.Rounds),
	}
	for _, p in _match.players do
		_remotes.Events.RoundBegin:FireClient(p, introPayload)
	end

	-- Create the round session through ActivityService.
	local res, err = ActivityService.CreateSession(activityId, "Survival", "Normal", alive)
	if not res then
		for _, p in alive do
			_remotes.Events.Toast:FireClient(p, { message = "Round error, skipping." })
		end
		-- treat as finished round, no eliminations, continue
		return Service.RunRound(roundNumber + 1)
	end

	-- Wait for completion.
	while res.session.Result == nil do
		task.wait(0.1)
	end
	local scoresheet = res.session.Result

	-- Compute eliminations: bottom % eliminated via fractions.
	local survivors = alive
	local ranked = scoresheet.Rows -- already best-first

	-- Survivor count for next round (nearest integer, min 1).
	local frac = GameConfig.Survival.SurvivorFractions[roundNumber]
	local keepCount = frac and math.max(1, math.floor(#survivors * frac + 0.5)) or 1
	if roundNumber >= GameConfig.Survival.Rounds then
		keepCount = 1
	end

	local kept = {}
	local eliminated = {}
	for i = 1, #ranked do
		local row = ranked[i]
		local player = row.Player
		if player and player.Parent then
			local uid = player.UserId
			if i <= keepCount and _match.alive[uid] then
				kept[#kept + 1] = uid
			elseif _match.alive[uid] then
				eliminated[#eliminated + 1] = uid
				_match.alive[uid] = nil
			end
		end
	end

	-- Survivor rewards (minimum participation for round win/survive).
	for _, uid in kept do
		local player = Players:GetPlayerByUserId(uid)
		if player then RewardService.GrantSurvivalRound(player, roundNumber, _match.sessionId) end
	end

	-- Broadcast round-end.
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

	-- Spectators: eliminated players now spectate.
	for _, uid in eliminated do
		local player = Players:GetPlayerByUserId(uid)
		if player then Spectator.Reset(player) end
	end

	return #kept <= 1
end

function Service.FinishMatch(winner: Player?)
	local finalAlive = Service.GetAlivePlayers()
	local winner2 = winner or finalAlive[1]
	if _match.status == "done" then return end
	_match.status = "done"

	-- Grant rewards to top-3 and update survival stats + leaderboard.
	local rows = {}
	local order = 0
	for _, pl in _match.players do
		order += 1
		local uid = pl.UserId
		local place = (pl == winner2) and 1 or (order)
		if _match.alive[uid] then place = 1 end
		rows[#rows + 1] = { UserId = uid, Name = pl.DisplayName, Place = place }
	end

	for _, pl in _match.players do
		if _match.alive[pl.UserId] or pl == winner2 then
			RewardService.GrantSurvivalOutcome(pl, 1, _match.sessionId)
		else
			RewardService.GrantSurvivalOutcome(pl, nil, _match.sessionId)
		end
	end

	if winner2 then
		local payload = {
			Kind = "Winner",
			WinnerUserId = winner2.UserId,
			WinnerName = winner2.DisplayName,
			Rows = rows,
		}
		for _, p in _match.players do
			_remotes.Events.Winner:FireClient(p, payload)
		end
		Analytics.Fire(winner2, "SurvivalWin", { a = "survival", b = tostring(_match.round) })
	end

	-- Record survival stat once per player in the match.
	for _, pl in _match.players do
		local data = require(script.Parent.PlayerDataService).GetForPlayer(pl)
		data.Survival.Matches += 1
		if _match.alive[pl.UserId] then
			data.Survival.Wins += 1
		end
		data.Survival.RoundsSurvived += _match.round or 0
		Leaderboard.SubmitSurvival(pl)
	end

	-- Clear all players from the match so queue can accept new ones.
	_match = nil
end

function Service.GetMatch()
	return _match
end

function Service.IsMatchRunning(): boolean
	return _match ~= nil
end

return Service