-- LeaderboardController: fetches leaderboard entries per board.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteBuilder = require(ReplicatedStorage:WaitForChild("LOOPlab").Shared.RemoteBuilder)
local remotes = RemoteBuilder.GetAll()
local ViewController = require(script.Parent.Parent.Components.ViewController)

local LeaderboardController = {}

local Screen

function LeaderboardController.Init(screens)
	Screen = screens.Leaderboards
	Screen.OnFetch = function(id)
		LeaderboardController.Fetch(id)
	end
	Screen.OnClose = function()
		ViewController.Show("Hub")
	end
end

function LeaderboardController.Fetch(boardId: string, count: number?)
	count = count or 15
	if not Screen then return end
	pcall(function()
		local entries = remotes.Functions.LeaderboardFetch:InvokeServer(boardId, count) or {}
		Screen:SetEntries(entries)
	end)
end

return LeaderboardController