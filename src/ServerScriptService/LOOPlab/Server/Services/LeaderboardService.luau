-- LeaderboardService: per-activity and survival leaderboards via OrderedDataStore.

local RunService = game:GetService("RunService")
if RunService:IsClient() then return {} end

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.LOOPlab.Configuration.GameConfig)
local RemoteBuilder = require(ReplicatedStorage.LOOPlab.Shared.RemoteBuilder)

local Service = {}
local _remotes = RemoteBuilder.GetAll()
local _stores = {}
local _cache = {}

local function getStore(boardId: string)
	local key = "LOOPLAB_LB_" .. boardId
	if not _stores[key] then
		_stores[key] = DataStoreService:GetOrderedDataStore(key)
	end
	return _stores[key]
end

function Service.SubmitGameScore(activityId: string, player: Player, score: number)
	if type(score) ~= "number" or score <= 0 then return end
	local board = nil
	for _, b in GameConfig.Leaderboards.Boards do
		if b.Id == activityId then board = b break end
	end
	if not board then return end
	local store = getStore(board.Key)
	local ok, err = pcall(function()
		store:SetAsync(tostring(player.UserId), score)
	end)
	if not ok then warn("[Leaderboard] submit failed: " .. tostring(err)) end
end

function Service.SubmitSurvival(player: Player, placement: number, roundsSurvived: number)
	local board = nil
	for _, b in GameConfig.Leaderboards.Boards do
		if b.Id == "survival" then board = b break end
	end
	if not board then return end
	local store = getStore(board.Key)
	local wins = placement == 1 and 1 or 0
	local rating = wins * 100 + (placement <= 3 and 30 or 0) + roundsSurvived * 2
	pcall(function()
		store:SetAsync(tostring(player.UserId), rating)
	end)
end

function Service.Fetch(boardId: string, count: number?, skip): table
	count = count or GameConfig.Leaderboards.MaxEntriesReturned
	local cacheKey = boardId .. ":" .. tostring(count)
	if _cache[cacheKey] then return _cache[cacheKey] end
	local board = nil
	for _, b in GameConfig.Leaderboards.Boards do
		if b.Id == boardId then board = b break end
	end
	if not board then return {} end
	local store = getStore(board.Key)
	local entries = {}
	local ok, pages = pcall(function()
		return store:GetSortedAsync(true, count)
	end)
	if not ok then return {} end
	local ok2, data = pcall(function()
		return pages:GetCurrentPage()
	end)
	if ok2 then
		for _, item in data do
			table.insert(entries, { UserId = tonumber(item.key), Score = item.value })
		end
	end
	_cache[cacheKey] = entries
	return entries
end

function Service.Setup()
	local guard = require(script.Parent.RemoteGuardService)
	guard.BindFunction(_remotes.Functions.LeaderboardFetch, function(player: Player, boardId: any, count: any)
		if type(boardId) ~= "string" then return {} end
		local n = type(count) == "number" and count or 10
		return Service.Fetch(boardId, n)
	end, "LeaderboardFetch")
end

task.spawn(function()
	while true do
		task.wait(GameConfig.Leaderboards.CacheSeconds)
		for k in pairs(_cache) do _cache[k] = nil end
	end
end)

return Service