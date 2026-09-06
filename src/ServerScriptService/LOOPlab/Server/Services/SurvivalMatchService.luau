-- SurvivalMatchService: orchestrates the full survival tournament (lobby -> rounds -> winner).
-- 4 rounds, 10->8->5->3->1 elimination via SurvivorFractions.

local RunService = game:GetService("RunService")
if RunService:IsClient() then return {} end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteBuilder = require(ReplicatedStorage.LOOPlab.Shared.RemoteBuilder)
local GameConfig = require(ReplicatedStorage.LOOPlab.Configuration.GameConfig)
local Analytics = require(script.Parent.AnalyticsService)
local ActivityService = require(script.Parent.ActivityService)
local Registry = require(ReplicatedStorage.LOOPlab.Shared.ActivityRegistry)

local Service = {}
local _remotes = RemoteBuilder.GetAll()
local _currentMatch = nil
local _matchResults = {}

local _translator = function(name)
	local map = { "Chaos Run", "Dodge Lab", "Build Blitz", "Sequence Sprint" }
	local byId = { chaos_run = 1, dodge_lab = 2, build_blitz = 3, sequence_sprint = 4 }
	return map[byId[name]] or name
end

local function mapUserIds(list)
	local out = {}
	for _, p in list do
		table.insert(out, p.UserId)
	end
	return out
end

local ACTIVITY_POOL = { "chaos_run", "dodge_lab", "build_blitz", "sequence_sprint" }

local function shuffleList(list)
	for i = #list, 2, -1 do
		local j = math.random(1, i)
		list[i], list[j] = list[j], list[i]
	end
end

-- Returns a per-match shuffled order of all activities (round order varies
-- every match, but each activity appears exactly once given Rounds == pool size).
local function shuffledRoundOrder()
	local pool = {}
	for _, id in ACTIVITY_POOL do table.insert(pool, id) end
	shuffleList(pool)
	return pool
end

function Service.StartSurvivalMatch(players: { Player })
	local match = {
		players = {},
		aliveByUserId = {},
		aliveList = {},
		eliminatedOrder = {},
		survivedRounds = {},
		roundIndex = 0,
		totalRounds = GameConfig.Survival.Rounds,
		phase = "Lobby",
		startedAt = os.clock(),
	}
	_currentMatch = match
	for _, p in players do
		table.insert(match.players, p)
		match.aliveByUserId[p.UserId] = p
		table.insert(match.aliveList, p)
		match.survivedRounds[p.UserId] = 0
	end

	-- Decide the per-match round order up front so the client can show the
	-- lineup during the lobby (order rotates every match; each game once).
	match.roundOrder = shuffledRoundOrder()

	-- broadcast lobby
	for _, p in match.players do
		_remotes.Events.LobbyUpdate:FireClient(p, {
			Phase = "Lobby",
			PlayerCount = #match.players,
			LobbySize = GameConfig.Survival.LobbySize,
			Countdown = GameConfig.Survival.LobbyCountdown,
			Message = "Survival lobby is filling...",
			RoundOrder = match.roundOrder,
		})
	end
	task.wait(GameConfig.Survival.LobbyCountdown)

	if #match.players < GameConfig.Survival.MinFill then
		-- abort
		match.phase = "Aborted"
		for _, p in match.players do
			_remotes.Events.LobbyUpdate:FireClient(p, { Phase = "Aborted", Message = "Not enough players. Match aborted." })
		end
		return false
	end

	match.phase = "Running"

	-- pre-round transitions
	for round = 1, match.totalRounds do
		match.roundIndex = round
		if round > 1 then
			match.phase = "Countdown"
			for _, p in match.aliveList do
				_remotes.Events.LobbyUpdate:FireClient(p, {
					Phase = "Countdown",
					Round = round,
					Message = ("Round %d begins in %ds"):format(round, GameConfig.Survival.RoundTransitionSeconds),
				})
			end
			task.wait(GameConfig.Survival.RoundTransitionSeconds)
		end

		local activityId = match.roundOrder[round] or ACTIVITY_POOL[(round - 1) % #ACTIVITY_POOL + 1]
		match.activityId = activityId
		match.phase = "Running"
		local res = Service.RunRound(match, activityId)
		if not res then
			break
		end
		if not Service.ApplyGroupElimination(match, res) then
			break -- all remaining === winner
		end
		if #match.aliveList == 1 then
			break
		end
	end

	Service.FinishMatch(match)
	return true
end

function Service.RunRound(match, activityId: string)
	local difficulty = GameConfig.Survival.DifficultyProgression[match.roundIndex] or "Normal"
	for _, p in match.aliveList do
		_remotes.Events.RoundBegin:FireClient(p, { Round = match.roundIndex, TotalRounds = match.totalRounds, ActivityId = activityId, Mode = "Survival", Difficulty = difficulty })
	end

	local res = ActivityService.CreateSession(activityId, "Survival", difficulty, match.aliveList)
	if not res then
		warn("[Survival] failed to create round session for " .. activityId)
		return nil
	end

	local deadline = os.clock() + res.session.Duration + 30
	while res.session.Result == nil do
		task.wait(0.5)
		if os.clock() > deadline then
			warn("[Survival] round timeout, force-finishing")
			ActivityService.EndSession(res.sessionId)
			break
		end
	end
	return res.session.Result
end

function Service.ApplyGroupElimination(match, scoresheet)
	if #match.aliveList <= 1 then return false end
	local fraction = GameConfig.Survival.SurvivorFractions[match.roundIndex]
	if not fraction then fraction = 1 end
	local keep = math.clamp(math.ceil(#match.aliveList * fraction), 1, #match.aliveList)
	if keep >= #match.aliveList then keep = #match.aliveList - 1 end
	if match.roundIndex == match.totalRounds then keep = 1 end

	local sorted = {}
	for _, row in scoresheet.Rows do
		if row and row.Player and match.aliveByUserId[row.Player.UserId] then
			table.insert(sorted, row)
		end
	end
	table.sort(sorted, function(a, b) return (a.Score or 0) > (b.Score or 0) end)

	local survivors = {}
	local eliminated = {}
	for i, row in sorted do
		if i <= keep then
			table.insert(survivors, row.Player)
		else
			table.insert(eliminated, row.Player)
		end
	end

	local newAlive = {}
	local newMap = {}
	for _, p in survivors do
		table.insert(newAlive, p)
		newMap[p.UserId] = p
		match.survivedRounds[p.UserId] += 1
	end
	match.aliveList = newAlive
	match.aliveByUserId = newMap
	for _, p in eliminated do
		table.insert(match.eliminatedOrder, p)
	end

	local eliminatedIds = mapUserIds(eliminated)
	local survivorIds = mapUserIds(newAlive)
	for _, p in match.players do
		_remotes.Events.Elimination:FireClient(p, {
			Round = match.roundIndex,
			TotalRounds = match.totalRounds,
			EliminatedUserIds = eliminatedIds,
			SurvivorUserIds = survivorIds,
			Message = ("%d eliminated this round. %d remain."):format(#eliminated, #newAlive),
		})
	end

	if #match.aliveList <= 1 then
		return false
	end
	return true
end

function Service.FinishMatch(match)
	local winner = match.aliveList[1]
	local placements = {} -- userId -> { rank, score }
	if winner then
		placements[winner.UserId] = { rank = 1 }
	end
	local rank = 2
	for i = #match.eliminatedOrder, 1, -1 do
		local p = match.eliminatedOrder[i]
		placements[p.UserId] = { rank = rank }
		rank += 1
	end

	local RewardService = require(script.Parent.RewardService)
	local Leaderboard = require(script.Parent.LeaderboardService)
	local PlayerData = require(script.Parent.PlayerDataService)
	local Daily = require(script.Parent.DailyChallengeService)
	local Progression = require(script.Parent.ProgressionService)

	local rows = {}
	local rewardsByUser = {}
	for _, p in match.players do
		if not p or not p.Parent then continue end
		local rank = placements[p.UserId] and placements[p.UserId].rank or (#match.players)
		local granted = RewardService.GrantSurvivalOutcome(p, rank, "sv_match" .. tostring(match.startedAt))

		local survived = match.survivedRounds[p.UserId] or 0
		for r = 1, survived do
			RewardService.GrantSurvivalRound(p, r, "sv_match" .. tostring(match.startedAt))
		end

		local data = PlayerData.GetForPlayer(p)
		if data and data.Survival then
			data.Survival.Matches += 1
			if rank == 1 then data.Survival.Wins += 1 end
			if rank <= 3 then data.Survival.Podiums += 1 end
			data.Survival.RoundsSurvived += survived
			if data.Survival.BestPlacement == 0 or rank < data.Survival.BestPlacement then
				data.Survival.BestPlacement = rank
			end
		end
		local fx = Progression.ProcessSurvival(p, rank, survived, match.totalRounds)
		PlayerData.SavePlayer(p)

		Leaderboard.SubmitSurvival(p, rank, survived)
		Daily.RecordProgress(p, "survival", rank, rank == 1)

		rewardsByUser[p.UserId] = {
			Coins = data and data.Coins or 0,
			Xp = data and data.Xp or 0,
			Granted = granted or { Xp = 0, Coins = 0 },
			Fx = fx,
			MasteryXp = data and data.MasteryXp or 0,
			MasteryRank = Progression.GetMasteryRank(data and data.MasteryXp or 0),
		}
		table.insert(rows, {
			UserId = p.UserId,
			Name = p.Name,
			Score = rank,
			Place = rank,
			Rewards = rewardsByUser[p.UserId],
		})
	end

	for _, p in match.players do
		if p and p.Parent then
			_remotes.Events.Winner:FireClient(p, {
				WinnerUserId = winner and winner.UserId or 0,
				WinnerName = winner and winner.Name or "none",
				Rewards = rewardsByUser[p.UserId] or {},
				Rows = rows,
			})
			_remotes.Events.Results:FireClient(p, {
				Mode = "Survival",
				ActivityId = "survival",
				Rows = rows,
			})
		end
	end

	Analytics.Fire(winner, "SurvivalFinished", { a = tostring(rows[1] and rows[1].Place), b = tostring(rows[1] and rows[1].UserId) })

	for _, p in match.players do
		if p then
			_matchResults[p.UserId] = {
				Mode = "Results",
				GameMode = "Survival",
				ActivityId = "survival",
				Rows = rows,
				Rewards = rewardsByUser[p.UserId] or {},
				WinnerUserId = winner and winner.UserId or 0,
				WinnerName = winner and winner.Name or "none",
			}
		end
	end
	_currentMatch = nil
end

function Service.GetClientSync(player)
	local m = _currentMatch
	if m then
		for _, p in m.players do
			if p == player then
				if m.phase == "Aborted" then
					return { Mode = "Survival", Phase = "Aborted", Message = "Not enough players. Match aborted." }
				end
				if m.phase == "Lobby" then
					return {
						Mode = "Survival",
						Phase = "Lobby",
						PlayerCount = #m.players,
						LobbySize = GameConfig.Survival.LobbySize,
						Countdown = GameConfig.Survival.LobbyCountdown,
						Message = "Survival lobby is filling...",
						TotalRounds = m.totalRounds,
						RoundOrder = m.roundOrder,
					}
				end
				return {
					Mode = "Survival",
					Phase = m.phase,
					Round = m.roundIndex,
					TotalRounds = m.totalRounds,
					ActivityId = m.activityId or "survival",
					EliminatedUserIds = mapUserIds(m.eliminatedOrder),
					SurvivorUserIds = mapUserIds(m.aliveList),
					Message = m.phase == "Countdown" and ("Round %d begins in %ds"):format(m.roundIndex, GameConfig.Survival.RoundTransitionSeconds) or ("Round %d of %d"):format(m.roundIndex, m.totalRounds),
				}
			end
		end
	end
	return _matchResults[player.UserId]
end

return Service