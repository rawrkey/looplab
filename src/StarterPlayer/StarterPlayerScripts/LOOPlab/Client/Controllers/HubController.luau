-- HubController: wires Hub screen to queue, sub-screens, and server bindings.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local RemoteBuilder = require(ReplicatedStorage:WaitForChild("LOOPlab").Shared.RemoteBuilder)
local remotes = RemoteBuilder.GetAll()
local GameConfig = require(ReplicatedStorage.LOOPlab.Configuration.GameConfig)
local ViewController = require(script.Parent.Parent.Components.ViewController)
local AudioService = require(script.Parent.Parent.Components.AudioService)
local EffectsService = require(script.Parent.Parent.Components.EffectsService)
local LeaderboardController = require(script.Parent.LeaderboardController)
local ProgressionController = require(script.Parent.ProgressionController)

local HubController = {}

local Hub
local View
local PLAYER = Players.LocalPlayer

function HubController.Init(screens)
	Hub = screens.Hub
	View = ViewController

	Hub.OnAction = function(action, cfg)
		if action == "Play" then
			AudioService.PlayClick()
			local isSurvival = cfg.id == "survival"
			View.Show("Queue", {
				Title = (cfg.name or cfg.id):upper(),
				Target = isSurvival and GameConfig.Survival.LobbySize or GameConfig.ActivityDefaults.MaxPlayers,
				Message = isSurvival and "Survival lobby is filling..." or "Standing by...",
			})
			local okJoin, res = pcall(function()
				return remotes.Functions.QueueJoin:InvokeServer(cfg.id)
			end)
			if not okJoin or not res then
				EffectsService.Toast("Could not join queue. Try again.")
				View.Show("Hub")
			end
		elseif action == "Leaderboards" then
			AudioService.PlayClick()
			View.Show("Leaderboards")
		elseif action == "Profile" then
			AudioService.PlayClick()
			ProgressionController.ShowProfile()
		elseif action == "Cosmetics" then
			AudioService.PlayClick()
			ProgressionController.ShowCosmetics()
		elseif action == "Settings" then
			AudioService.PlayClick()
			View.Show("Settings")
		end
	end

	LeaderboardController.Fetch("survival")
	ProgressionController.FetchProfile()
end

return HubController