-- EconomyService: the ONLY writer of coins/XP in the game. Server-authoritative.

local RunService = game:GetService("RunService")
if RunService:IsClient() then return {} end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local GameConfig = require(ReplicatedStorage.LOOPlab.Configuration.GameConfig)
local PlayerData = require(script.Parent.PlayerDataService)
local RemoteBuilder = require(ReplicatedStorage.LOOPlab.Shared.RemoteBuilder)

local Economy = {}
local _remotes = RemoteBuilder.GetAll()

local function pushUpdate(userId: number)
	local player = Players:GetPlayerByUserId(userId)
	if not player then return end
	local data = PlayerData.Get(userId)
	local level = Economy.GetLevelFromXp(data.Xp)
	_remotes.Events.EconomyUpdate:FireClient(player, { Coins = data.Coins, Xp = data.Xp, Level = level })
end

function Economy.GetLevelFromXp(xp: number): number
	local curve = GameConfig.Xp.LevelCurve
	local level = 1
	for i = 2, #curve do
		if xp >= curve[i] then level = i end
		if xp < curve[i] then break end
	end
	return math.min(level, GameConfig.Xp.MaxLevel)
end

function Economy.AddCoins(player: Player, amount: number): number
	local data = PlayerData.GetForPlayer(player)
	data.Coins = math.max(0, data.Coins + amount)
	pushUpdate(player.UserId)
	return data.Coins
end

function Economy.AddXp(player: Player, amount: number): number
	local data = PlayerData.GetForPlayer(player)
	local oldLevel = Economy.GetLevelFromXp(data.Xp)
	data.Xp = math.max(0, data.Xp + amount)
	local newLevel = Economy.GetLevelFromXp(data.Xp)
	if newLevel > oldLevel then
		local levelsGained = newLevel - oldLevel
		local data2 = PlayerData.GetForPlayer(player)
		local coins = GameConfig.Progression.LevelUpCoins * levelsGained
		data2.Coins = math.max(0, data2.Coins + coins)
		local Poll = require(script.Parent.PollService)
		Poll.TrackFx(player, "LevelUp", { Level = newLevel, Coins = coins })
	end
	pushUpdate(player.UserId)
	return data.Xp
end

function Economy.SpendCoins(player: Player, amount: number): boolean
	local data = PlayerData.GetForPlayer(player)
	if data.Coins < amount then return false end
	data.Coins -= amount
	pushUpdate(player.UserId)
	return true
end

function Economy.GetCoins(player: Player): number
	return PlayerData.GetForPlayer(player).Coins
end

function Economy.GetXp(player: Player): number
	return PlayerData.GetForPlayer(player).Xp
end

return Economy