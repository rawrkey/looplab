-- QueueService: matchmaking. Manages per-activity queues (standalone) and the
-- survival queue. When enough players, spins up a session via ActivityService.

local RunService = game:GetService("RunService")
if RunService:IsClient() then
	return {}
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Registry = require(ReplicatedStorage.LOOPlab.Shared.ActivityRegistry)
local RemoteBuilder = require(ReplicatedStorage.LOOPlab.Shared.RemoteBuilder)
local ActivityService = require(script.Parent.ActivityService)
local GameConfig = require(ReplicatedStorage.LOOPlab.Configuration.GameConfig)
local Analytics = require(script.Parent.AnalyticsService)

local Service = {}
local _remotes = RemoteBuilder.GetAll()

-- queues: activityId -> { players = {Player}, timer = tick, waiting = bool, session }
local _queues = {}

-- survival: a special queue
local _survivalQueue = { players = {}, timer = 0, waiting = false, session = nil }

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
	for _, p in q.players do
		_remotes.Events.QueueUpdate:FireClient(p, {
			ActivityId = activityId,
			Queued = #q.players,
			Target = Registry.Get(activityId).MaxPlayers,
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

	local res, err = ActivityService.CreateSession(activityId, "Standalone", "Normal", players)
	if not res then
		warn("[Queue] failed to start " .. activityId .. ": " .. tostring(err))
		return
	end
	q.session = res.sessionId
	Analytics.Fire(players[1], "ActivityStart", { a = activityId, b = "Standalone" })

	-- when the session ends, clear queue + notify players
	task.spawn(function()
		while res.session.Result == nil do task.wait(0.5) end
		local scoresheet = res.session.Result
		-- clear the queue and mark done
		q.session = nil
		q.players = {}
		-- results broadcast done by game/survival layer; keep simple: fire Results
		for _, p in players do
			_remotes.Events.Results:FireClient(p, {
				ActivityId = activityId,
				Rows = scoresheet.Rows,
				Rewards = { Coins = 0, Xp = 0 },
			})
		end
	end)
end

local function startSurvival()
	local q = _survivalQueue
	if q.session or #q.players == 0 then return end
	-- survival orchestration is handled by SurvivalMatchService; QueueService just reports ready
	local Survival = require(script.Parent.SurvivalMatchService)
	local started = Survival.StartMatch(#q.players >= GameConfig.Survival.MinFill)
	if started then
		q.session = "survival"
		q.players = {}
	end
end

-- Public API ----------------------------------------------------------------

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

function Service.SetNonSurvivalQueueSession(activityId: string, sessionId: string)
	getOrCreate(activityId).session = sessionId
end

-- Loops: auto-start standalone when target met or after first-wait timeout.
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
		-- survival auto-start if min fill reached and timer passed
		local q = _survivalQueue
		if not q.session and #q.players > 0 then
			if #q.players >= GameConfig.Survival.LobbySize and q.timer == 0 then
				q.timer = os.clock()
			end
			if q.timer ~= 0 and (os.clock() - q.timer) >= 1 then
				startSurvival()
				q.timer = 0
			end
		end
	end
end)

-- cleanup on leave
Players.PlayerRemoving:Connect(function(player)
	for activityId, q in pairs(_queues) do
		removeFromQueue(activityId, player)
	end
	removeFromSurvival(player)
end)

return Service