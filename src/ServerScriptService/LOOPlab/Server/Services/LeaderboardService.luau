-- LeaderboardService: ordered per-game + survival boards in OrderedDataStore.
-- Only this service writes leaderboards from validated, server-produced results.

local RunService = game:GetService("RunService")
if RunService:IsClient() then
	return {}
end

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.LOOPlab.Configuration.GameConfig)
local PlayerData = require(script.Parent.PlayerDataService)
local RemoteBuilder = require(ReplicatedStorage.LOOPlab.Shared.RemoteBuilder)

local Service = {}
local _remotes = RemoteBuilder.GetAll()

-- OrderedDataStore per board; key = "LB_id".
local _stores = {}
local function storeFor(boardId)
	local key = "LB_" .. boardId
	if not _stores[key] then
		_stores[key] = DataStoreService:GetOrderedDataStore(key)
	end
	return _stores[key]
end

-- Score key must be a sortable OrderedDataStore numeric key. We use actual score or rating.
function Service.Submit(boardId: string, userId: number, value: number)
	if type(value) ~= "number" or value < 0 then return end
	local ok, err = pcall(function()
		storeFor(boardId):SetAsync(tostring(userId), value)
	end)
	if not ok then
		warn("[Leaderboard] submit failed " .. boardId .. ": " .. tostring(err))
	end
end

-- Submit a per-game best score (only if better than previously recorded best).
function Service.SubmitGameScore(activityId: string, player: Player, score: number)
	local data = PlayerData.GetForPlayer(player)
	local entry = data.Games[activityId]
	local best = entry and entry.BestScore or 0
	if score > best then
		Service.Submit(activityId, player.UserId, score)
	end
end

-- Survival rating = wins*100 + podiums*30 + matches*2 (from stored player data).
function Service.SubmitSurvival(player: Player)
	local data = PlayerData.GetForPlayer(player)
	local s = data.Survival
	local rating = (s.Wins * 100) + (s.Podiums * 30) + (s.Matches * 2)
	Service.Submit("survival", player.UserId, rating)
end

-- Fetch top entries. Returns list of {userId, name, value}.
function Service.Fetch(boardId: string, count: number): { { UserId: number, Name: string, Value: number } }
	count = math.clamp(count or GameConfig.Leaderboards.MaxEntriesReturned, 1, GameConfig.Leaderboards.MaxEntriesReturned)
	local ok, pages = pcall(function()
		return storeFor(boardId):GetSortedAsync(false, count)
	end)
	if not ok then
		warn("[Leaderboard] fetch failed " .. boardId)
		return {}
	end
	local items = pages:GetCurrentPage()
	local out = {}
	for _, item in items do
		local userId = tonumber(item.key)
		local name = userId and Players:GetNameFromUserIdAsync(userId) or "??"
		table.insert(out, { UserId = userId, Name = name, Value = item.value })
	end
	return out
end

-- Bind remote handler for client fetch.
function Service.Setup()
	local guard = require(script.Parent.RemoteGuardService)
	guard.BindFunction(_remotes.Functions.LeaderboardFetch, function(player: Player, boardId: any)
		if type(boardId) ~= "string" then return nil end
		-- Only allow known boards.
		local known = false
		for _, b in GameConfig.Leaderboards.Boards do
			if b.Id == boardId then known = true break end
		end
		if not known then return nil end
		local rows = Service.Fetch(boardId, GameConfig.Leaderboards.MaxEntriesReturned)
		return { rows = rows }
	end, "LeaderboardFetch")
end

return Service