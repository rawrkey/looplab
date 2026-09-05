-- QueueService: matchmaking for standalone activities + survival.

local RunService = game:GetService("RunService")
if RunService:IsClient() then return {} end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Registry = require(ReplicatedStorage.LOOPlab.Shared.ActivityRegistry)
local RemoteBuilder = require(ReplicatedStorage.LOOPlab.Shared.RemoteBuilder)
local ActivityService = require(script.Parent.ActivityService)
local GameConfig = require(ReplicatedStorage.LOOPlab.Configuration.GameConfig)
local Analytics = require(script.Parent.AnalyticsService)

local Service = {}
local _remotes = RemoteBuilder.GetAll()
local _queues = {}
local _survivalQueue = { players = {}, timer = 0, waiting = false, session = nil }
local _lastResults = {}

local function getOrCreate(activityId)
	local q = _queues[activityId]
	if not q then
		q = { players = {}, timer = 0, waiting = false, session = nil }
		_queues[activityId] = q
	end
	return q
end

local function broadcastQueue(activityId)
	local q = _queues[activityId]
	if not q then return end
	local def = Registry.Get(activityId)
	for _, p in q.players do
		_remotes.Events.QueueUpdate:FireClient(p, {
			ActivityId = activityId,
			Queued = #q.players,
			Target = def and def.MaxPlayers or GameConfig.ActivityDefaults.MaxPlayers,
			Phase = "waiting",
		})
	end
end

local function broadcastSurvival()
	local q = _survivalQueue
	for _, p in q.players do
		_remotes.Events.QueueUpdate:FireClient(p, {
			ActivityId = "survival",
			Queued = #q.players,
			Target = GameConfig.Survival.LobbySize,
			Phase = "waiting",
		})
	end
end

local function removeFromQueue(activityId, player)
	local q = _queues[activityId]
	if q then
		for i, p in q.players do
			if p == player then
				table.remove(q.players, i)
				break
			end
		end
	end
end

local function removeFromSurvival(player)
	local q = _survivalQueue
	for i, p in q.players do
		if p == player then
			table.remove(q.players, i)
			break
		end
	end
end

local function startStandalone(activityId)
	local q = getOrCreate(activityId)
	if q.session or #q.players == 0 then return end
	local def = Registry.Get(activityId)
	local players = {}
	for _, p in q.players do players[#players + 1] = p end

	-- tell clients the match is starting (standalone uses RoundBegin as MatchStart)
	for _, p in players do
		_remotes.Events.RoundBegin:FireClient(p, {
			Kind = "RoundBegin",
			Mode = "Standalone",
			Round = 1,
			TotalRounds = 1,
			ActivityId = activityId,
			Count = #players,
			Message = def.Name,
		})
	end

	local res, err = ActivityService.CreateSession(activityId, "Standalone", "Normal", players)
	if not res then
		warn("[Queue] failed to start " .. activityId .. ": " .. tostring(err))
		return
	end
	q.session = res.sessionId
	Analytics.Fire(players[1], "ActivityStart", { a = activityId, b = "Standalone" })

	task.spawn(function()
		local cOk, cErr = pcall(function()
			local deadline = os.clock() + (def.DurationSeconds or 60) + 30
			while res.session.Result == nil do
				task.wait(0.5)
				if os.clock() > deadline then break end
			end
			local scoresheet = res.session.Result
			q.session = nil
			q.players = {}
			if not scoresheet then return end

			local RewardService = require(script.Parent.RewardService)
			local Leaderboard = require(script.Parent.LeaderboardService)
			local Daily = require(script.Parent.DailyChallengeService)
			local PlayerData = require(script.Parent.PlayerDataService)

			local rewardsByPlayer = {}
			local winnerId = 0
			local winnerName = "none"
			local best = -1
			for _, row in scoresheet.Rows do
				local score = row.Score or row.Place or 0
				if score > best then
					best = score
					winnerId = row.Player and row.Player.UserId or row.UserId or 0
					winnerName = row.Player and row.Player.Name or row.Name or "none"
				end
			end
			for i, row in scoresheet.Rows do
				local p = row.Player
				if p and p.Parent then
					RewardService.GrantStandalone(p, i, #scoresheet.Rows, activityId, row.Score, res.sessionId)
					Leaderboard.SubmitGameScore(activityId, p, row.Score)
					Daily.RecordProgress(p, activityId, row.Score)
					PlayerData.RecordRecent(p, { ActivityId = activityId, Mode = "Standalone", Date = os.date("Y-m-d"), Score = row.Score })
					local data = PlayerData.GetForPlayer(p)
					rewardsByPlayer[p.UserId] = { Coins = data.Coins, Xp = data.Xp }
				end
			end

			for _, p in players do
				if p.Parent then
					local rw = rewardsByPlayer[p.UserId]
					_lastResults[p.UserId] = {
						Mode = "Results",
						GameMode = "Standalone",
						ActivityId = activityId,
						Rows = scoresheet.Rows,
						Rewards = rw or { Coins = 0, Xp = 0 },
						WinnerUserId = winnerId,
						WinnerName = winnerName,
					}
					_remotes.Events.Results:FireClient(p, {
						ActivityId = activityId,
						Mode = "Standalone",
						Rows = scoresheet.Rows,
						Rewards = rw or { Coins = 0, Xp = 0 },
					})
				end
			end
		end)
		if not cOk then
			warn("[Queue] standalone completion failed: " .. tostring(cErr))
		end
	end)
end

local function startSurvival()
	local q = _survivalQueue
	if q.session or #q.players == 0 then return end
	local Survival = require(script.Parent.SurvivalMatchService)
	local players = {}
	for _, p in q.players do table.insert(players, p) end
	q.session = true
	q.players = {}
	task.spawn(function()
		local ok, err = pcall(function()
			Survival.StartSurvivalMatch(players)
		end)
		q.session = false
		if not ok then
			warn("[Queue] survival match failed: " .. tostring(err))
		end
	end)
end

function Service.Enqueue(activityId: string, player: Player): any
	if activityId == "survival" then
		if _survivalQueue.session then return nil, "match already in progress" end
		for _, p in _survivalQueue.players do
			if p == player then return nil, "already queued" end
		end
		table.insert(_survivalQueue.players, player)
		broadcastSurvival()
		return { queued = _survivalQueue.players }
	end

	local def = Registry.Get(activityId)
	if not def then return nil, "unknown activity" end
	local q = getOrCreate(activityId)
	if q.session then return nil, "match already running" end
	for _, p in q.players do
		if p == player then return nil, "already queued" end
	end
	table.insert(q.players, player)
	broadcastQueue(activityId)
	return { queued = q.players }
end

function Service.Dequeue(activityId: string, player: Player)
	if activityId == "survival" then
		removeFromSurvival(player)
		broadcastSurvival()
		return
	end
	removeFromQueue(activityId, player)
	broadcastQueue(activityId)
end

function Service.GetCounts(): table
	local counts = {}
	for id, q in pairs(_queues) do counts[id] = #q.players end
	counts["survival"] = #_survivalQueue.players
	return counts
end

function Service.GetClientSync(player)
	for id, q in pairs(_queues) do
		if q.session then continue end
		for _, p in q.players do
			if p == player then
				local def = Registry.Get(id)
				return {
					Mode = "Queue",
					Phase = "waiting",
					ActivityId = id,
					Queued = #q.players,
					Target = def and def.MaxPlayers or GameConfig.ActivityDefaults.MaxPlayers,
				}
			end
		end
	end
	for _, p in _survivalQueue.players do
		if p == player then
			if _survivalQueue.session then return nil end
			return {
				Mode = "Queue",
				Phase = "waiting",
				ActivityId = "survival",
				Queued = #_survivalQueue.players,
				Target = GameConfig.Survival.LobbySize,
			}
		end
	end
	return _lastResults[player.UserId]
end

function Service.Setup()
	local guard = require(script.Parent.RemoteGuardService)
	guard.BindFunction(_remotes.Functions.QueueJoin, function(player: Player, activityId: any)
		if type(activityId) ~= "string" then return nil end
		return Service.Enqueue(activityId, player)
	end, "QueueJoin")

	guard.BindFunction(_remotes.Functions.QueueLeave, function(player: Player)
		-- leave all queues
		for id, q in pairs(_queues) do
			Service.Dequeue(id, player)
		end
		Service.Dequeue("survival", player)
		return { ok = true }
	end, "QueueLeave")

	guard.BindFunction(_remotes.Functions.PlayerCounts, function(player: Player)
		return Service.GetCounts()
	end, "PlayerCounts")
end

task.spawn(function()
	while true do
		task.wait(0.5)
		for activityId, q in pairs(_queues) do
			local def = Registry.Get(activityId)
			if def and not q.session and #q.players > 0 then
				if #q.players >= def.MaxPlayers then
					startStandalone(activityId)
				elseif q.timer == 0 then
					q.timer = os.clock()
				elseif (os.clock() - q.timer) >= GameConfig.ActivityDefaults.QueueTimeoutSeconds then
					startStandalone(activityId)
					q.timer = 0
				end
			end
		end
		local q = _survivalQueue
		if not q.session and #q.players > 0 then
			if #q.players >= GameConfig.Survival.LobbySize then
				startSurvival()
				q.timer = 0
			elseif #q.players >= GameConfig.Survival.MinFill then
				if q.timer == 0 then q.timer = os.clock() end
				if (os.clock() - q.timer) >= GameConfig.Survival.FillWaitSeconds then
					startSurvival()
					q.timer = 0
				end
			else
				q.timer = 0
			end
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	for activityId, q in pairs(_queues) do
		removeFromQueue(activityId, player)
	end
	removeFromSurvival(player)
end)

return Service