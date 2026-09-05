-- PlayerDataService: authoritative player data load/save/migrate/validate.
-- Single owner of the DataStore + in-memory session cache.

local RunService = game:GetService("RunService")
if RunService:IsClient() then
	return {}
end

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.LOOPlab.Configuration.GameConfig)

local Service = {}

-- schema: { SchemaVersion: number, Xp, Coins, OwnedCosmetics: {[string] = true}, Equipped: {[string] = string}, Games: {[id] = {Plays, BestScore, Wins}}, Survival: {Wins, Podiums, RoundsSurvived, BestPlacement, Matches}, Daily: {Date, Claimed}, Recent: { {ActivityId, Mode, Date, Score} }, Settings: {}, Unlocks: {XP level} }

local DATASTORE_KEY = "LOOPLAB_PlayerData_v1"
local _store = DataStoreService:GetDataStore("LOOPLAB_PlayerData")
local _session = {}   -- userId -> data
local _loading = {}   -- userId -> bool

local function defaultData()
	return {
		SchemaVersion = GameConfig.SchemaVersion,
		Xp = 0,
		Coins = GameConfig.PlayerData.DefaultCoins,
		OwnedCosmetics = {},
		Equipped = {},
		Games = {},
		Survival = { Wins = 0, Podiums = 0, RoundsSurvived = 0, BestPlacement = 0, Matches = 0 },
		Daily = { Date = "", Claimed = false },
		Recent = {},
		Settings = {},
	}
end

local function clone(t)
	if type(t) ~= "table" then return nil end
	local out = {}
	for k, v in pairs(t) do
		if type(v) == "table" then out[k] = clone(v) else out[k] = v end
	end
	return out
end

-- naive schema migration: pad missing fields, bump version.
local function migrate(raw: table): table
	local d = defaultData()
	for k, v in pairs(raw) do d[k] = v end
	-- ensure shape of nested tables if present
	if type(raw.Daily) == "table" then
		d.Daily = raw.Daily
	else
		d.Daily = defaultData().Daily
	end
	if type(raw.Settings) ~= "table" then d.Settings = {} end
	if type(raw.OwnedCosmetics) ~= "table" then d.OwnedCosmetics = {} end
	if type(raw.Equipped) ~= "table" then d.Equipped = {} end
	if type(raw.Games) ~= "table" then d.Games = {} end
	if type(raw.Recent) ~= "table" then d.Recent = {} end
	return d
end

function Service.Get(userId: number): table
	if _session[userId] then return _session[userId] end
	return defaultData()
end

function Service.GetForPlayer(player: Player): table
	return Service.Get(player.UserId)
end

function Service.Load(player: Player)
	local userId = player.UserId
	if _session[userId] then
		return true
	end
	if _loading[userId] then
		return false
	end
	_loading[userId] = true
	local ok, result = pcall(function()
		return _store:GetAsync(tostring(userId))
	end)
	_loading[userId] = nil
	if ok and result then
		local validated = migrate(result)
		_session[userId] = validated
	else
		_session[userId] = defaultData()
	end
	return true
end

function Service.Save(userId: number): boolean
	local data = _session[userId]
	if not data then return false end
	local ok, err = pcall(function()
		_store:SetAsync(tostring(userId), data)
	end)
	if not ok then
		warn("[PlayerData] save failed for " .. userId .. ": " .. tostring(err))
		return false
	end
	return true
end

function Service.SavePlayer(player: Player): boolean
	return Service.Save(player.UserId)
end

function Service.Update(player: Player, mutator: (data: table) -> ())
	Service.Load(player)
	local data = Service.GetForPlayer(player)
	mutator(data)
end

function Service.RecordRecent(player: Player, entry: { ActivityId: string, Mode: string, Date: string, Score: number })
	Service.Update(player, function(data)
		table.insert(data.Recent, 1, entry)
		while #data.Recent > GameConfig.PlayerData.MaxRecentGames do
			table.remove(data.Recent)
		end
	end)
end

function Service.OnLeave(player: Player)
	local userId = player.UserId
	if _session[userId] then
		Service.Save(userId)
		_session[userId] = nil
	end
end

Players.PlayerAdded:Connect(function(player)
	Service.Load(player)
end)
Players.PlayerRemoving:Connect(function(player)
	task.spawn(Service.OnLeave, player)
end)

-- periodic save for running sessions
task.spawn(function()
	while true do
		task.wait(GameConfig.PlayerData.SaveIntervalSeconds)
		for userId, _ in pairs(_session) do
			Service.Save(userId)
		end
	end
end)

function Service.GetSessionTable()
	return _session
end

return Service