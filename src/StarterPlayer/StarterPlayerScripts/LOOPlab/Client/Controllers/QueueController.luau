-- QueueController: lobby/queue updates, results, toasts.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteBuilder = require(ReplicatedStorage:WaitForChild("LOOPlab").Shared.RemoteBuilder)
local remotes = RemoteBuilder.GetAll()
local GameConfig = require(ReplicatedStorage.LOOPlab.Configuration.GameConfig)
local ViewController = require(script.Parent.Parent.Components.ViewController)
local AudioService = require(script.Parent.Parent.Components.AudioService)
local EffectsService = require(script.Parent.Parent.Components.EffectsService)
local Theme = require(script.Parent.Parent.Components.Theme)

local QueueController = {}

local QueueScreen
QueueController.ResultsDismissed = false

function QueueController.Init(screens)
	QueueScreen = screens.Queue
	QueueScreen.OnLeave = function()
		AudioService.PlayClick()
		pcall(function()
			remotes.Functions.QueueLeave:InvokeServer()
		end)
		ViewController.Show("Hub")
	end
end

function QueueController.LobbyUpdate(payload)
	if not QueueScreen then return end
	local phase = payload.Phase or "Lobby"
	if phase == "Lobby" then
		QueueScreen:Show({
			Title = "SURVIVAL",
			Target = payload.LobbySize or 10,
			Message = payload.Message or "Survival lobby is filling...",
		})
		QueueScreen:Set({
			Queued = payload.PlayerCount or 0,
			Target = payload.LobbySize or 10,
		})
		AudioService.PlayLobby()
	elseif phase == "Countdown" then
		local r = payload.Round or 1
		EffectsService.RoundBanner(r, GameConfig and GameConfig.Survival.Rounds or 4, "SURVIVAL", Theme.Accent("survival"))
	elseif phase == "Aborted" then
		EffectsService.Toast(payload.Message or "Match aborted.")
		ViewController.Show("Hub")
	end
end

function QueueController.QueueUpdate(payload)
	if not QueueScreen then return end
	QueueScreen:Set({
		Queued = payload.Queued or payload.Count or 0,
		Target = payload.Target or 10,
		Message = payload.Message or ("%d / %d players"):format(payload.Queued or payload.Count or 0, payload.Target or 10),
	})
end

function QueueController.DismissResults()
	QueueController.ResultsDismissed = true
end

function QueueController.Results(payload)
	if not payload or QueueController.ResultsDismissed then return end
	if ViewController.GetCurrentName() ~= "Results" then
		ViewController.Show("Results", {
			Rows = payload.Rows,
			Rewards = payload.Rewards,
		})
		return
	end
	-- Already showing: refresh in place so late-arriving reward payloads render.
	pcall(function()
		local Results = require(script.Parent.Parent.Components.Screens.Results)
		Results:SetResults({
			Rows = payload.Rows,
			Rewards = payload.Rewards,
		})
	end)
end

function QueueController.Toast(message, opts)
	EffectsService.Toast(message or "", opts or {})
	AudioService.PlayToast()
end

return QueueController