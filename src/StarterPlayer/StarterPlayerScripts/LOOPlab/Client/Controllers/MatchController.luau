-- MatchController: drives MatchHud from server round/activity events.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local ViewController = require(script.Parent.Parent.Components.ViewController)
local AudioService = require(script.Parent.Parent.Components.AudioService)
local EffectsService = require(script.Parent.Parent.Components.EffectsService)
local Theme = require(script.Parent.Parent.Components.Theme)
local SpectatorController = require(script.Parent.SpectatorController)

local MatchController = {}

local Hud
local Mode = nil
local ActivityId = nil
local ActivityName = nil
local Accent = nil
local Round = 1
local TotalRounds = 1
local _finalShown = {}
local PLAYER = Players.LocalPlayer

local ACTIVITY_NAMES = {
	chaos_run = "Chaos Run",
	dodge_lab = "Dodge Lab",
	build_blitz = "Build Blitz",
	sequence_sprint = "Sequence Sprint",
	survival = "SURVIVAL",
}

function MatchController.Init(screens)
	Hud = screens.MatchHud
end

local function resolvePlayers(userIds)
	local list = {}
	for _, id in userIds do
		local p = Players:GetPlayerByUserId(id)
		if p then table.insert(list, p) end
	end
	return list
end

local function survivalIntensity(round, totalRounds)
	if totalRounds >= 4 then
		if round >= totalRounds then return 3 end
		if round >= totalRounds - 1 then return 2 end
		return 1
	end
	return math.clamp(round, 1, 3)
end

function MatchController.RoundBegin(payload)
	Mode = payload.Mode or "standalone"
	ActivityId = payload.ActivityId or "survival"
	ActivityName = payload.Name or payload.Message or ACTIVITY_NAMES[ActivityId] or "Activity"
	Accent = Theme.Accent(ActivityId)
	Round = payload.Round or 1
	TotalRounds = payload.TotalRounds or 1
	_finalShown = {}

	Hud:SetActivity(ActivityName, Accent, Mode)
	Hud:SetState({ Round = Round, TotalRounds = TotalRounds, Phase = "Running", Message = payload.Message or "" })

	ViewController.Show("MatchHud")

	if Mode == "Standalone" then
		AudioService.PlayActivityMusic(ActivityId, 1)
		EffectsService.Banner(ActivityName:upper(), "GOOD LUCK!", Accent)
		task.delay(0.4, function()
			EffectsService.Countdown(3, function()
				AudioService.PlayGo()
			end)
		end)
	elseif Mode == "Survival" then
		AudioService.PlayActivityMusic(ActivityId, survivalIntensity(Round, TotalRounds))
		task.delay(0.4, function()
			EffectsService.RoundBanner(Round, TotalRounds, ActivityName, Accent)
			AudioService.PlayCountdown()
		end)
		task.delay(1.0, function()
			EffectsService.Countdown(3, function()
				AudioService.PlayGo()
			end)
		end)
	end
end

function MatchController.ActivityUpdate(payload)
	if not Hud then return end
	local update = {}
	if type(payload.TimeLeft) == "number" then update.TimeLeft = payload.TimeLeft end
	if type(payload.Phase) == "string" then update.Phase = payload.Phase end
	if payload.Message then update.Message = payload.Message end
	if payload.ActivityId then update.ActivityId = payload.ActivityId end
	if payload.Mode then update.Mode = payload.Mode end
	if payload.Round then update.Round = payload.Round end
	if payload.TotalRounds then update.TotalRounds = payload.TotalRounds end
	if payload.SubLabel then update.SubLabel = payload.SubLabel end
	if Mode == "Survival" then
		local total = TotalRounds or 4
		update.IntensityLevel = survivalIntensity(Round, total)
		update.IntensityMax = total
	end
	Hud:SetState(update)
end

function MatchController.Elimination(payload)
	if not Hud then return end
	local survivors = resolvePlayers(payload.SurvivorUserIds or {})
	local meOut = false
	for _, id in (payload.EliminatedUserIds or {}) do
		if id == PLAYER.UserId then meOut = true break end
	end

	if Mode == "Survival" then
		local n = #survivors
		if n <= 3 and n >= 2 and not _finalShown[n] then
			_finalShown[n] = true
			AudioService.SetIntensity(3)
			if n == 2 then
				EffectsService.Final2()
			elseif n == 3 then
				EffectsService.Final3()
			end
		end
	end

	if meOut then
		AudioService.PlayEliminated()
		EffectsService.EliminateFlash(Theme.Brand.Danger)
		SpectatorController.Begin({ Cycle = survivors })
	else
		EffectsService.Toast(payload.Message or "A player was eliminated.")
		AudioService.PlayEliminated()
	end
end

function MatchController.Winner(payload)
	local name = payload.WinnerName or ""
	if name == "" or name == "none" then
		name = tostring(payload.WinnerUserId or 0)
	end
	if payload.WinnerUserId == PLAYER.UserId then
		EffectsService.Victory("YOU", Theme.Brand.Gold)
	else
		EffectsService.Victory(name, Accent or Theme.Brand.Gold)
	end
	AudioService.PlayVictory()
end

function MatchController.EndMatch()
	if not Hud then return end
	Hud:SetState({ Message = "" })
end

return MatchController