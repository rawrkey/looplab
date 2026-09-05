-- RewardService: computes and grants rewards from validated match outcomes.

local RunService = game:GetService("RunService")
if RunService:IsClient() then return {} end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.LOOPlab.Configuration.GameConfig)
local Economy = require(script.Parent.EconomyService)
local PlayerData = require(script.Parent.PlayerDataService)
local Analytics = require(script.Parent.AnalyticsService)
local RemoteBuilder = require(ReplicatedStorage.LOOPlab.Shared.RemoteBuilder)
local Poll = require(script.Parent.PollService)

local Rewards = {}
local _remotes = RemoteBuilder.GetAll()
local _grantedKeys = {}

local function _applyGranted(player, amounts, reason, dedupeKey)
	local key = player.UserId .. "|" .. reason .. "|" .. (dedupeKey or "none")
	if _grantedKeys[key] then
		return nil
	end
	_grantedKeys[key] = true
	if amounts.UnlockCosmetic then
		local data = PlayerData.GetForPlayer(player)
		if not data.OwnedCosmetics[amounts.UnlockCosmetic] then
			data.OwnedCosmetics[amounts.UnlockCosmetic] = true
		end
	end
	if (amounts.Coins or 0) > 0 then
		Economy.AddCoins(player, amounts.Coins)
	end
	if (amounts.Xp or 0) > 0 then
		Economy.AddXp(player, amounts.Xp)
	end
	return amounts
end

function Rewards.Grant(player: Player, amounts: { Xp: number?, Coins: number?, UnlockCosmetic: string? }, reason: string, dedupeKey: string): table?
	local granted = _applyGranted(player, amounts, reason, dedupeKey)
	if not granted then return nil end
	local message = ("+%s XP  +%s Coins"):format(tostring(amounts.Xp or 0), tostring(amounts.Coins or 0))
	_remotes.Events.Toast:FireClient(player, { message = message })
	Poll.TrackToast(player, message)
	Analytics.Fire(player, "RewardGranted", { a = reason, b = tostring(amounts.Coins or 0) .. ":" .. tostring(amounts.Xp or 0) })
	return { Xp = amounts.Xp or 0, Coins = amounts.Coins or 0 }
end

function Rewards.GrantStandalone(player: Player, placement: number, totalPlayers: number, activityId: string, score: number, sessionId: string)
	local r = GameConfig.Rewards.Standalone
	local mult = r.EveryoneMult
	if placement <= #r.PlacementMult then
		mult = r.PlacementMult[placement]
	end
	local coins = math.floor(r.BaseCoins * mult)
	local xp = math.floor(r.BaseXp * mult)
	local granted = Rewards.Grant(player, { Coins = coins, Xp = xp }, "standalone_" .. activityId, sessionId .. ":" .. placement)
	local data = PlayerData.GetForPlayer(player)
	local entry = data.Games[activityId]
	if not entry then
		entry = { Plays = 0, BestScore = 0, Wins = 0 }
		data.Games[activityId] = entry
	end
	entry.Plays += 1
	if score > entry.BestScore then entry.BestScore = score end
	if placement == 1 then entry.Wins += 1 end
	return granted
end

function Rewards.GrantSurvivalRound(player: Player, roundIndex: number, sessionId: string)
	local r = GameConfig.Rewards.SurvivalRound
	Rewards.Grant(player, { Coins = r.BaseCoins, Xp = r.BaseXp }, "survival_round", sessionId .. ":" .. roundIndex)
end

function Rewards.GrantSurvivalOutcome(player: Player, placement: number, sessionId: string)
	local r = GameConfig.Rewards
	if placement == 1 then
		Rewards.Grant(player, { Coins = r.SurvivalWin.Coins, Xp = r.SurvivalWin.Xp }, "survival_win", sessionId)
	elseif placement <= 3 then
		Rewards.Grant(player, { Coins = r.SurvivalPodium.Coins, Xp = r.SurvivalPodium.Xp }, "survival_podium", sessionId)
	end
end

function Rewards.GrantDaily(player: Player)
	local r = GameConfig.Rewards.DailyChallenge
	Rewards.Grant(player, { Coins = r.Coins, Xp = r.Xp }, "daily", nil)
end

return Rewards