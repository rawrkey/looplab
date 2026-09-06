-- DailyChallengeService: date-rotated daily objectives + claim.

local RunService = game:GetService("RunService")
if RunService:IsClient() then return {} end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.LOOPlab.Configuration.GameConfig)
local RemoteBuilder = require(ReplicatedStorage.LOOPlab.Shared.RemoteBuilder)
local PlayerData = require(script.Parent.PlayerDataService)
local Analytics = require(script.Parent.AnalyticsService)
local Poll = require(script.Parent.PollService)

local Service = {}
local _remotes = RemoteBuilder.GetAll()

local function todayKey()
	return os.date("!%Y-%m-%d", os.time())
end

function Service.GetTodayChallenge(): table
	local objective = GameConfig.Daily.Objectives[(os.date("!%j") * 7) % #GameConfig.Daily.Objectives + 1]
	return {
		Date = todayKey(),
		Objective = objective,
	}
end

function Service.GetState(player: Player): table
	local data = PlayerData.GetForPlayer(player)
	local t = todayKey()
	if data.Daily.Date ~= t then
		data.Daily.Date = t
		data.Daily.Claimed = false
		data.Daily.Progress = 0
	end
	local challenge = Service.GetTodayChallenge()
	return {
		Date = t,
		Objective = challenge.Objective,
		Progress = data.Daily.Progress,
		Claimed = data.Daily.Claimed,
	}
end

function Service.RecordProgress(player: Player, activityId: string, score: number, isWin: boolean)
	local data = PlayerData.GetForPlayer(player)
	local t = todayKey()
	if data.Daily.Date ~= t then
		data.Daily.Date = t
		data.Daily.Progress = 0
		data.Daily.Claimed = false
	end
	if data.Daily.Claimed then return end
	local objective = Service.GetTodayChallenge().Objective
	local added = 0
	if objective.Kind == "complete" then
		added = 1
	elseif objective.Kind == "win" then
		added = (isWin and 1) or 0
	elseif objective.Kind == "best_score" then
		added = score or 0
	end
	data.Daily.Progress += added
	if added > 0 then
		_remotes.Events.Toast:FireClient(player, { message = "Daily progress updated!" })
		Poll.TrackToast(player, "Daily progress updated!")
	end
end

function Service.Claim(player: Player): (boolean, string?)
	local data = PlayerData.GetForPlayer(player)
	local t = todayKey()
	if data.Daily.Date ~= t then
		data.Daily.Date = t
		data.Daily.Progress = 0
		data.Daily.Claimed = false
	end
	local objective = Service.GetTodayChallenge().Objective
	if data.Daily.Claimed then
		return false, "already claimed"
	end
	if data.Daily.Progress < (objective.Min or 1) then
		return false, "not complete"
	end
	data.Daily.Claimed = true
	local Reward = require(script.Parent.RewardService)
	Reward.GrantDaily(player)
	Analytics.Fire(player, "DailyClaimed", { a = objective.Kind, b = tostring(data.Daily.Progress) })
	return true
end

function Service.Setup()
	local guard = require(script.Parent.RemoteGuardService)
	guard.BindFunction(_remotes.Functions.DailyClaim, function(player: Player)
		return Service.Claim(player)
	end, "DailyClaim")

	guard.BindFunction(_remotes.Functions.DailyState, function(player: Player)
		return Service.GetState(player)
	end, "DailyState")
end

return Service