-- CosmeticService: read/write equipped cosmetics + purchase. Server-authoritative.
-- Cosmetics are cosmetic only; no power. Purchases validated against GameConfig catalog.

local RunService = game:GetService("RunService")
if RunService:IsClient() then
	return {}
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.LOOPlab.Configuration.GameConfig)
local PlayerData = require(script.Parent.PlayerDataService)
local Economy = require(script.Parent.EconomyService)
local RemoteBuilder = require(ReplicatedStorage.LOOPlab.Shared.RemoteBuilder)
local Analytics = require(script.Parent.AnalyticsService)

local Service = {}
local _remotes = RemoteBuilder.GetAll()

local function findCosmetic(id)
	for _, c in GameConfig.Cosmetics do
		if c.Id == id then return c end
	end
	return nil
end

function Service.Owns(player: Player, id: string): boolean
	local data = PlayerData.GetForPlayer(player)
	return data.OwnedCosmetics[id] == true
end

function Service.Equip(player: Player, category: string, id: string): boolean
	local cosmetic = findCosmetic(id)
	if not cosmetic then return false end
	if cosmetic.Category ~= category then return false end
	if not Service.Owns(player, id) then return false end
	local data = PlayerData.GetForPlayer(player)
	data.Equipped[category] = id
	return true
end

function Service.Unequip(player: Player, category: string): boolean
	local data = PlayerData.GetForPlayer(player)
	local known = false
	for _, c in GameConfig.Cosmetics do
		if c.Category == category then known = true break end
	end
	if not known then return false end
	data.Equipped[category] = nil
	return true
end

function Service.Buy(player: Player, id: string)
	local cosmetic = findCosmetic(id)
	if not cosmetic or cosmetic.Price <= 0 or cosmetic.Price == nil then
		return { ok = false, message = "Not purchasable" }
	end
	if Service.Owns(player, id) then
		return { ok = false, message = "Already owned" }
	end
	if not Economy.SpendCoins(player, cosmetic.Price) then
		return { ok = false, message = "Not enough coins" }
	end
	local data = PlayerData.GetForPlayer(player)
	data.OwnedCosmetics[id] = true
	Analytics.Fire(player, "Purchase", { a = id, b = tostring(cosmetic.Price) })
	return { ok = true, coins = Economy.GetCoins(player) }
end

function Service.Setup()
	local guard = require(script.Parent.RemoteGuardService)
	guard.BindFunction(_remotes.Functions.CosmeticEquip, function(player: Player, category: any, id: any)
		if type(category) ~= "string" or type(id) ~= "string" then return nil end
		return Service.Equip(player, category, id)
	end, "CosmeticEquip")

	guard.BindFunction(_remotes.Functions.CosmeticUnequip, function(player: Player, category: any)
		if type(category) ~= "string" then return nil end
		return Service.Unequip(player, category)
	end, "CosmeticUnequip")

	guard.BindFunction(_remotes.Functions.CosmeticBuy, function(player: Player, id: any)
		if type(id) ~= "string" then return nil end
		return Service.Buy(player, id)
	end, "CosmeticBuy")
end

return Service