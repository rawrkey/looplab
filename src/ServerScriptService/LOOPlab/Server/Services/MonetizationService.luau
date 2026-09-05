-- MonetizationService: handles Developer Product purchases (cosmetics, private servers).
-- Real product ids come from Studio/GameConfig.Monetization. Auth is server-side.

local RunService = game:GetService("RunService")
if RunService:IsClient() then
	return {}
end

local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.LOOPlab.Configuration.GameConfig)
local Cosmetic = require(script.Parent.CosmeticService)

local Service = {}

-- Maps a DeveloperProductId to a cosmetic id.
local function productToCosmetic(productId: number): string?
	local map = GameConfig.Monetization.CosmeticProducts
	return map[tostring(productId)]
end

function Service.ProcessPurchase(player: Player, productId: number)
	local cosmeticId = productToCosmetic(productId)
	if cosmeticId then
		-- real-time/insto grants are handled by DeveloperProductPurchasePromptFinished; here we
		-- just record+unlock as a fallback for potential duplicated prompts.
		local data = require(script.Parent.PlayerDataService).GetForPlayer(player)
		data.OwnedCosmetics[cosmeticId] = true
	end
end

function Service.Setup()
	if GameConfig.Monetization.PrivateServerProductId > 0 then
		MarketplaceService.ProcessReceipt = function(receiptInfo)
			-- Cloud-time purchase handled via DataStore keyed by receipt; MVP: grant cosmetic.
			local who = game:GetService("Players"):GetPlayerByUserId(receiptInfo.PlayerId)
			if who then Service.ProcessPurchase(who, receiptInfo.ProductId) end
			return Enum.PurchaseGranted? and Enum.PurchaseGranted or Enum.ProductPurchaseDecision.PurchaseGranted
		end
	end
end

return Service