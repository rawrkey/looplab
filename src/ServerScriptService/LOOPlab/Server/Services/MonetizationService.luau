-- MonetizationService: dev product purchases -> cosmetics/coins (anti-dupe via receipt).

local RunService = game:GetService("RunService")
if RunService:IsClient() then return {} end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local MarketPlaceService = game:GetService("MarketplaceService")
local GameConfig = require(ReplicatedStorage.LOOPlab.Configuration.GameConfig)
local Analytics = require(script.Parent.AnalyticsService)
local PlayerData = require(script.Parent.PlayerDataService)
local Economy = require(script.Parent.EconomyService)

local Service = {}
local _processed = {}

local function findProduct(productId: number)
	for _, p in GameConfig.Monetization.CosmeticProducts do
		if p.ProductId == productId then return p end
	end
	return nil
end

MarketPlaceService.ProcessReceipt = function(receipt: any)
	if _processed[receipt.PurchaseId] then return Enum.ProductPurchaseDecision.PurchaseGranted end
	local product = findProduct(receipt.ProductId)
	if not product then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	if not player then return Enum.ProductPurchaseDecision.NotProcessedYet end
	PlayerData.Load(player)
	local data = PlayerData.GetForPlayer(player)
	local ok = false
	if product.Kind == "Cosmetic" then
		if not data.OwnedCosmetics[product.ItemId] then
			data.OwnedCosmetics[product.ItemId] = true
			ok = true
		end
	elseif product.Kind == "Coins" then
		Economy.AddCoins(player, product.Amount)
		ok = true
	elseif product.Kind == "Xp" then
		Economy.AddXp(player, product.Amount)
		ok = true
	end
	if ok then
		_processed[receipt.PurchaseId] = true
		PlayerData.SavePlayer(player)
		Analytics.Fire(player, "Purchase", { a = tostring(product.ProductId), b = product.ItemId or tostring(product.Amount) })
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	return Enum.ProductPurchaseDecision.NotProcessedYet
end

local function createPrivateServer()
	if GameConfig.Monetization.PrivateServerProductId == 0 then return end
	local ok, err = pcall(function()
		-- placeholder for private server flow
	end)
	if not ok then warn("[Monetization] private server flow failed: " .. tostring(err)) end
end

return Service