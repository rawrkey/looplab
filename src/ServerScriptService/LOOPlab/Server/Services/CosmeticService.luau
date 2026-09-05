-- CosmeticService: catalog, ownership, equip/unequip, purchase.

local RunService = game:GetService("RunService")
if RunService:IsClient() then return {} end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.LOOPlab.Configuration.GameConfig)
local RemoteBuilder = require(ReplicatedStorage.LOOPlab.Shared.RemoteBuilder)
local PlayerData = require(script.Parent.PlayerDataService)
local Economy = require(script.Parent.EconomyService)
local Analytics = require(script.Parent.AnalyticsService)

local Service = {}
local _remotes = RemoteBuilder.GetAll()

local function catalog()
	return GameConfig.Cosmetics
end

function Service.GetCatalog(): table
	return catalog()
end

function Service.GetOwned(player: Player): table
	return PlayerData.GetForPlayer(player).OwnedCosmetics or {}
end

function Service.Equip(player: Player, itemId: string): (boolean, string?)
	local data = PlayerData.GetForPlayer(player)
	local owned = data.OwnedCosmetics or {}
	if not owned[itemId] then
		local item = nil
		for _, c in catalog() do
			if c.Id == itemId then item = c break end
		end
		if not item then return false, "not found" end
		if item.Price > 0 then return false, "not owned" end
		-- free items auto-owned
		owned[itemId] = true
	end
	local category = ""
	for _, c in catalog() do
		if c.Id == itemId then category = c.Category break end
	end
	if not data.Equipped then data.Equipped = {} end
	data.Equipped[category] = itemId
	return true
end

function Service.Unequip(player: Player, itemId: string): boolean
	local data = PlayerData.GetForPlayer(player)
	local category = ""
	for _, c in catalog() do
		if c.Id == itemId then category = c.Category break end
	end
	if category == "" then return false end
	if data.Equipped and data.Equipped[category] == itemId then
		data.Equipped[category] = nil
	end
	return true
end

function Service.Buy(player: Player, itemId: string): (boolean, string?)
	local data = PlayerData.GetForPlayer(player)
	if data.OwnedCosmetics and data.OwnedCosmetics[itemId] then
		return false, "already owned"
	end
	local item = nil
	for _, c in catalog() do
		if c.Id == itemId then item = c break end
	end
	if not item then return false, "not found" end
	if item.Price <= 0 then return false, "free item" end
	if not Economy.SpendCoins(player, item.Price) then
		return false, "not enough coins"
	end
	if not data.OwnedCosmetics then data.OwnedCosmetics = {} end
	data.OwnedCosmetics[itemId] = true
	Analytics.Fire(player, "CosmeticPurchased", { a = itemId, b = tostring(item.Price) })
	return true
end

function Service.Setup()
	local guard = require(script.Parent.RemoteGuardService)
	guard.BindFunction(_remotes.Functions.CosmeticEquip, function(player: Player, itemId: any)
		if type(itemId) ~= "string" then return false, "bad arg" end
		return Service.Equip(player, itemId)
	end, "CosmeticEquip")

	guard.BindFunction(_remotes.Functions.CosmeticUnequip, function(player: Player, itemId: any)
		if type(itemId) ~= "string" then return false end
		return Service.Unequip(player, itemId)
	end, "CosmeticUnequip")

	guard.BindFunction(_remotes.Functions.CosmeticBuy, function(player: Player, itemId: any)
		if type(itemId) ~= "string" then return false, "bad arg" end
		return Service.Buy(player, itemId)
	end, "CosmeticBuy")
end

return Service