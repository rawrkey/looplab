-- PlayerDataService: authoritative player data load/save/migrate/validate.

local RunService = game:GetService("RunService")
if RunService:IsClient() then
	return {}
end

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.LOOPlab.Configuration.GameConfig)
local RemoteBuilder = require(ReplicatedStorage.LOOPlab.Shared.RemoteBuilder)

local Service = {}
local _remotes = RemoteBuilder.GetAll()

local _store = DataStoreService:GetDataStore("LOOPLAB_PlayerData")
local _session = {}
local _loading = {}

local function defaultData()
	return {
		SchemaVersion = GameConfig.SchemaVersion,
		Xp = 0,
		Coins = GameConfig.PlayerData.DefaultCoins,
		OwnedCosmetics = {},
		Equipped = {},
		Games = {},
		Survival = {
			Wins = 0, Podiums = 0, RoundsSurvived = 0, BestPlacement = 0, Matches = 0,
			WinStreak = 0, BestWinStreak = 0, FinalRoundAppearances = 0, LastWinDate = "",
		},
		MasteryXp = 0,
		Badges = {},
		Titles = {},
		EquippedTitle = "",
		Records = {},
		Daily = { Date = "", Claimed = false, Progress = 0 },
		Recent = {},
		Settings = {},
	}
end

local function migrate(raw: table): table
	local d = defaultData()
	for k, v in pairs(raw) do
		if type(v) == "table" then
			d[k] = v
		else
			d[k] = v
		end
	end
	if type(d.Daily) ~= "table" then d.Daily = defaultData().Daily end
	if type(d.Settings) ~= "table" then d.Settings = {} end
	if type(d.OwnedCosmetics) ~= "table" then d.OwnedCosmetics = {} end
	if type(d.Equipped) ~= "table" then d.Equipped = {} end
	if type(d.Games) ~= "table" then d.Games = {} end
	if type(d.Recent) ~= "table" then d.Recent = {} end
	if type(d.Survival) ~= "table" then d.Survival = defaultData().Survival end
	if not d.Survival.WinStreak then d.Survival.WinStreak = 0 end
	if not d.Survival.BestWinStreak then d.Survival.BestWinStreak = 0 end
	if not d.Survival.FinalRoundAppearances then d.Survival.FinalRoundAppearances = 0 end
	if not d.Survival.LastWinDate then d.Survival.LastWinDate = "" end
	if type(d.MasteryXp) ~= "number" then d.MasteryXp = 0 end
	if type(d.Badges) ~= "table" then d.Badges = {} end
	if type(d.Titles) ~= "table" then d.Titles = {} end
	if type(d.EquippedTitle) ~= "string" then d.EquippedTitle = "" end
	if type(d.Records) ~= "table" then d.Records = {} end
	d.SchemaVersion = GameConfig.SchemaVersion
	return d
end

function Service.Get(userId: number): table
	if _session[userId] then return _session[userId] end
	local data = defaultData()
	_session[userId] = data
	return data
end

function Service.GetForPlayer(player: Player): table
	return Service.Get(player.UserId)
end

function Service.Load(player: Player)
	local userId = player.UserId
	if _session[userId] then return true end
	if _loading[userId] then return false end
	_loading[userId] = true
	local ok, result = pcall(function()
		return _store:GetAsync(tostring(userId))
	end)
	_loading[userId] = nil
	if ok and result then
		_session[userId] = migrate(result)
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
		warn("[PlayerData] save failed for " .. tostring(userId) .. ": " .. tostring(err))
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

task.spawn(function()
	while true do
		task.wait(GameConfig.PlayerData.SaveIntervalSeconds)
		for userId, _ in pairs(_session) do
			Service.Save(userId)
		end
	end
end)

-- Client-facing binds. Lazy-require dependent services to avoid load cycles.
function Service.Setup()
	local guard = require(script.Parent.RemoteGuardService)

	guard.BindFunction(_remotes.Functions.SettingsSet, function(player: Player, settings: any)
		if type(settings) ~= "table" then return nil end
		local data = Service.GetForPlayer(player)
		local writable = {}
		if type(settings.MusicOn) == "boolean" then writable.MusicOn = settings.MusicOn end
		if type(settings.SfxOn) == "boolean" then writable.SfxOn = settings.SfxOn end
		if type(settings.ReducedMotion) == "boolean" then writable.ReducedMotion = settings.ReducedMotion end
		for k, v in writable do data.Settings[k] = v end
		return true
	end, "SettingsSet")

	guard.BindFunction(_remotes.Functions.ProfileFetch, function(player: Player)
		local data = Service.GetForPlayer(player)
		local economy = require(script.Parent.EconomyService)
		local daily = require(script.Parent.DailyChallengeService)
		local progression = require(script.Parent.ProgressionService)
		local owned = {}
		for k in data.OwnedCosmetics do table.insert(owned, k) end
		local badges = {}
		for k in data.Badges do table.insert(badges, k) end
		local titles = {}
		for k in data.Titles do table.insert(titles, k) end
		return {
			Level = economy.GetLevelFromXp(data.Xp),
			Xp = data.Xp,
			Coins = data.Coins,
			Games = data.Games,
			Survival = data.Survival,
			Daily = daily.GetState(player),
			Equipped = data.Equipped,
			OwnedCosmetics = owned,
			Settings = data.Settings,
			MasteryXp = data.MasteryXp,
			MasteryRank = progression.GetMasteryRank(data.MasteryXp),
			Badges = badges,
			Titles = titles,
			EquippedTitle = data.EquippedTitle,
			Records = data.Records,
		}
	end, "ProfileFetch")
end

return Service