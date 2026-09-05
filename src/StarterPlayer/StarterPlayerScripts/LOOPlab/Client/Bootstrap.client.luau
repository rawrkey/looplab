-- LOOPLAB client bootstrap. Builds the UI in StarterGui + wires server events to controllers.

local RunService = game:GetService("RunService")
if RunService:IsServer() then
	return
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

local UIKit = require(script.Parent.Components.UIKit)
local ViewController = require(script.Parent.Components.ViewController)
local AudioService = require(script.Parent.Components.AudioService)
local RemoteBuilder = require(ReplicatedStorage:WaitForChild("LOOPlab").Shared.RemoteBuilder)

local Hub = require(script.Parent.Components.Screens.Hub)
local QueueScreen = require(script.Parent.Components.Screens.Queue)
local MatchHud = require(script.Parent.Components.Screens.MatchHud)
local Spectator = require(script.Parent.Components.Screens.Spectator)
local Results = require(script.Parent.Components.Screens.Results)
local Leaderboards = require(script.Parent.Components.Screens.Leaderboards)
local Profile = require(script.Parent.Components.Screens.Profile)
local Settings = require(script.Parent.Components.Screens.Settings)

local HubController = require(script.Parent.Controllers.HubController)
local QueueController = require(script.Parent.Controllers.QueueController)
local MatchController = require(script.Parent.Controllers.MatchController)
local SpectatorController = require(script.Parent.Controllers.SpectatorController)
local ProgressionController = require(script.Parent.Controllers.ProgressionController)
local LeaderboardController = require(script.Parent.Controllers.LeaderboardController)

local screen = UIKit.MakeScreen(true)
screen.Parent = PlayerGui

local screens = {
	Hub = Hub,
	Queue = QueueScreen,
	MatchHud = MatchHud,
	Spectator = Spectator,
	Results = Results,
	Leaderboards = Leaderboards,
	Profile = Profile,
	Settings = Settings,
}

for _, s in screens do
	s:Build(screen)
end

ViewController.Init(screens)

HubController.Init(screens)
QueueController.Init(screens)
MatchController.Init(screens)
SpectatorController.Init(screens)
ProgressionController.Init(screens)
LeaderboardController.Init(screens)

Results.OnClose = function()
	ViewController.Show("Hub")
end

local remotes = RemoteBuilder.GetAll()

local last = { mode = nil, phase = nil, round = nil, elimHash = "", resultsSeen = false }

local function sync()
	local ok, payload = pcall(function()
		return remotes.Functions.PollActivity:InvokeServer()
	end)
	if not ok or type(payload) ~= "table" then
		return
	end

	if type(payload.Toasts) == "table" then
		for _, t in payload.Toasts do
			QueueController.Toast(t.message or t.Message)
		end
	end
	if type(payload.Economy) == "table" then
		ProgressionController.EconomyUpdate(payload.Economy)
	end

	local a = payload.Activity
	if not a or type(a) ~= "table" then
		last.mode = nil
		last.phase = nil
		last.resultsSeen = false
		return
	end

	local mode = a.Mode
	if mode == "Queue" then
		QueueController.QueueUpdate(a)
		last.mode = "Queue"
		last.resultsSeen = false
	elseif mode == "Results" then
		if not last.resultsSeen then
			last.resultsSeen = true
			QueueController.Results({ Rows = a.Rows, Rewards = a.Rewards })
			if a.WinnerUserId and a.WinnerUserId ~= 0 then
				pcall(MatchController.Winner, MatchController, { WinnerUserId = a.WinnerUserId, WinnerName = a.WinnerName })
			end
		end
	elseif mode == "Standalone" then
		if last.mode ~= "Standalone" then
			MatchController.RoundBegin({
				Mode = "Standalone",
				ActivityId = a.ActivityId,
				Round = 1,
				TotalRounds = 1,
				Name = a.ActivityName or a.ActivityId,
			})
		end
		MatchController.ActivityUpdate({ TimeLeft = a.TimeLeft })
		last.mode = "Standalone"
	elseif mode == "Survival" then
		if a.Phase == "Lobby" then
			if last.phase ~= "Lobby" or last.mode ~= "Survival" then
				QueueController.LobbyUpdate({
					Phase = "Lobby",
					PlayerCount = a.PlayerCount,
					LobbySize = a.LobbySize,
					Countdown = a.Countdown,
					Message = a.Message,
				})
			end
		elseif a.Phase == "Aborted" then
			if last.phase ~= "Aborted" then
				QueueController.LobbyUpdate({ Phase = "Aborted", Message = a.Message })
			end
		elseif a.Phase == "Countdown" then
			if last.round ~= a.Round or last.mode ~= "Survival" then
				QueueController.LobbyUpdate({
					Phase = "Countdown",
					Round = a.Round,
					Message = a.Message,
				})
			end
		elseif a.Phase == "Running" then
			if last.phase ~= "Running" or last.round ~= a.Round or last.mode ~= "Survival" then
				MatchController.RoundBegin({
					Mode = "Survival",
					Round = a.Round,
					TotalRounds = a.TotalRounds,
					ActivityId = a.ActivityId,
				})
			end
			MatchController.ActivityUpdate({ TimeLeft = a.TimeLeft })
			local hash = table.concat(a.EliminatedUserIds or {}, ",")
			if hash ~= last.elimHash then
				last.elimHash = hash
				if #(a.EliminatedUserIds or {}) > 0 then
					MatchController.Elimination({
						Round = a.Round,
						TotalRounds = a.TotalRounds,
						EliminatedUserIds = a.EliminatedUserIds,
						SurvivorUserIds = a.SurvivorUserIds,
						Message = a.Message,
					})
				end
			end
		end
		last.mode = "Survival"
		last.phase = a.Phase
		last.round = a.Round
	end
end

task.spawn(function()
	while task.wait(0.45) do
		local okPoll, errPoll = pcall(sync)
		if not okPoll then
			warn("[LOOPLAB] poll error: " .. tostring(errPoll))
		end
	end
end)

ViewController.Show("Hub")
AudioService.PlayHubMusic()

print("[LOOPLAB] Client ready")