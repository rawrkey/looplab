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

function MatchController.RoundBegin(payload)
	Mode = payload.Mode or "standalone"
	ActivityId = payload.ActivityId or "survival"
	ActivityName = payload.Name or payload.Message or ACTIVITY_NAMES[ActivityId] or "Activity"
	Accent = Theme.Accent(ActivityId)
	Round = payload.Round or 1
	TotalRounds = payload.TotalRounds or 1

	Hud:SetActivity(ActivityName, Accent)
	Hud:SetState({ Round = Round, TotalRounds = TotalRounds, Phase = "Eliminating", Message = payload.Message or "" })

	ViewController.Show("MatchHud")

	if Mode == "Standalone" then
		EffectsService.Banner(ActivityName:upper(), "GOOD LUCK!", Accent)
		AudioService.PlayActivityMusic(ActivityId)
		task.delay(0.4, function()
			EffectsService.Countdown(3, function()
				AudioService.PlayGo()
			end)
		end)
	elseif Mode == "Survival" then
		AudioService.PlayActivityMusic(ActivityId)
		task.delay(0.5, function()
			EffectsService.RoundBanner(Round, TotalRounds, ActivityName, Accent)
			AudioService.PlayCountdown()
		end)
		task.delay(1.1, function()
			EffectsService.Countdown(3, function()
				AudioService.PlayGo()
			end)
		end)
	end
end

function MatchController.ActivityUpdate(payload)
	if not Hud then return end
	Hud:SetState({
		TimeLeft = type(payload.TimeLeft) == "number" and payload.TimeLeft or nil,
		Phase = type(payload.Phase) == "string" and payload.Phase or nil,
	})
end

function MatchController.Elimination(payload)
	if not Hud then return end
	local meOut = false
	for _, id in (payload.EliminatedUserIds or {}) do
		if id == PLAYER.UserId then meOut = true break end
	end
	if meOut then
		AudioService.PlayEliminated()
		EffectsService.EliminateFlash(Theme.Brand.Danger)
		local survivors = resolvePlayers(payload.SurvivorUserIds or {})
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