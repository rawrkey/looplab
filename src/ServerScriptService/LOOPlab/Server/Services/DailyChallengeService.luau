-- DailyChallengeService: daily rotating challenge. Claims are validated server-side.
-- Objective: play a specific activity N times, or score best N.

local RunService = game:GetService("RunService")
if RunService:IsClient() then
	return {}
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.LOOPlab.Configuration.GameConfig)
local PlayerData = require(script.Parent.PlayerDataService)
local RemoteBuilder = require(ReplicatedStorage.LOOPlab.Shared.RemoteBuilder)
local ES = require(script.Parent.EconomyService)
local Rewards = require(script.Parent.RewardService)
local Registry = require(ReplicatedStorage.LOOPlab.Shared.ActivityRegistry)

local Service = {}
local _remotes = RemoteBuilder.GetAll()

-- Today's challenge is seeded from the date so all players share it.
function Service.GetTodayChallenge(): table
	local osDate = os.date("Y-m-d", os.time())
	local seed = 0
	for i = 1, #osDate do seed = seed + string.byte(osDate, i) end
	local activities = Registry.GetAllIds()
	local activityId = activities[(seed % #activities) + 1]
	local objective = GameConfig.Daily.Objectives[(seed % #GameConfig.Daily.Objectives) + 1]
	return { ActivityId = activityId, Kind = objective.Kind, Target = objective.Min, ProgressMetric = objective.ProgressMetric, Date = osDate }
end

function Service.GetPlayerChallenge(player: Player): table
	local challenge = Service.GetTodayChallenge()
	local data = PlayerData.GetForPlayer(player)
	local entry = data.Daily
	-- progress tracking: if date mismatch, reset
	if entry.Date ~= challenge.Date then
		entry.Date = challenge.Date
		entry.Progress = 0
		entry.Claimed = false
	end
	return {
		ActivityId = challenge.ActivityId,
		Kind = challenge.Kind,
		Target = challenge.Target,
		Progress = entry.Progress or 0,
		Claimed = entry.Claimed or false,
	}
end

-- Called when a player completes an activity in the challenge activity.
function Service.RecordProgress(player: Player, activityId: string, score: number?)
	local challenge = Service.GetTodayChallenge()
	if activityId ~= challenge.ActivityId then return end
	local data = PlayerData.GetForPlayer(player)
	local entry = data.Daily
	if entry.Date ~= challenge.Date then
		entry.Date = challenge.Date
		entry.Progress = 0
		entry.Claimed = false
	end
	if entry.Claimed then return end
	if challenge.Kind == "best_score" and score then
		entry.Progress = math.max(entry.Progress or 0, score)
	else
		entry.Progress = (entry.Progress or 0) + 1
	end
end

function Service.Setup()
	local guard = require(script.Parent.RemoteGuardService)
	guard.BindFunction(_remotes.Functions.DailyState, function(player: Player)
		return Service.GetPlayerChallenge(player)
	end, "DailyState")

	guard.BindFunction(_remotes.Functions.DailyClaim, function(player: Player)
		local state = Service.GetPlayerChallenge(player)
		if state.Claimed then return { ok = false, message = "Already claimed" } end
		local completed = state.Progress >= state.Target
		if not completed then return { ok = false, message = "Not yet complete" } end
		local data = PlayerData.GetForPlayer(player)
		data.Daily.Claimed = true
		Rewards.GrantDaily(player)
		local coins = ES.GetCoins(player)
		local xp = ES.GetXp(player)
		return { ok = true, coins = coins, xp = xp }
	end, "DailyClaim")
end

return Service