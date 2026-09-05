-- ProgressionController: profile/rewards UX, settings save, daily claim.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteBuilder = require(ReplicatedStorage:WaitForChild("LOOPlab").Shared.RemoteBuilder)
local remotes = RemoteBuilder.GetAll()
local GameConfig = require(ReplicatedStorage.LOOPlab.Configuration.GameConfig)
local ViewController = require(script.Parent.Parent.Components.ViewController)
local AudioService = require(script.Parent.Parent.Components.AudioService)
local EffectsService = require(script.Parent.Parent.Components.EffectsService)

local ProgressionController = {}

local Hub
local ProfileScreen
local SettingsScreen

local function xpNextFor(level)
	local curve = GameConfig.Xp.LevelCurve
	return curve[math.min(level + 1, #curve)] or (curve[level] or 100)
end

function ProgressionController.Init(screens)
	Hub = screens.Hub
	ProfileScreen = screens.Profile
	SettingsScreen = screens.Settings

	SettingsScreen.OnSave = function()
		ProgressionController.SaveSettings()
		AudioService.PlayClick()
		EffectsService.Toast("Settings saved")
	end
	SettingsScreen.OnClose = function()
		ViewController.Show("Hub")
	end

	ProfileScreen.OnClaim = function()
		ProgressionController.ClaimDaily()
	end
	ProfileScreen.OnClose = function()
		ViewController.Show("Hub")
	end
end

function ProgressionController.RefreshProfile()
	ViewController.Show("Profile")
	pcall(function()
		local profile = remotes.Functions.ProfileFetch:InvokeServer()
		if profile then
			ProgressionController.ApplyProfile(profile)
		end
	end)
	task.spawn(function()
		pcall(function()
			local daily = remotes.Functions.DailyState:InvokeServer()
			if daily and ProfileScreen then
				ProfileScreen:SetDailyClaim(daily.Claimed == true)
			end
		end)
	end)
end

function ProgressionController.ApplyProfile(profile)
	if not profile then return end
	if Hub then
		Hub:SetProgression(profile.Level, profile.Xp, xpNextFor(profile.Level), profile.Coins)
	end
	if ProfileScreen then
		ProfileScreen:SetProfile({
			Name = profile.DisplayName,
			Progress = {
				Level = profile.Level,
				Xp = profile.Xp,
				XpNext = xpNextFor(profile.Level),
			},
			Stats = {
				MatchesPlayed = 0,
				Wins = 0,
				TotalScore = 0,
				BestScore = 0,
				CoinsEarned = profile.Coins,
				DailiesClaimed = profile.Daily and profile.Daily.Claimed == true and 1 or 0,
			},
		})
	end
end

function ProgressionController.EconomyUpdate(payload)
	if not payload then return end
	if Hub then
		Hub:SetProgression(payload.Level, payload.Xp, xpNextFor(payload.Level), payload.Coins)
	end
end

function ProgressionController.SaveSettings()
	local s = SettingsScreen:GetSettings()
	pcall(function()
		remotes.Functions.SettingsSet:InvokeServer({
			MusicOn = s.MusicVolume > 0,
			SfxOn = s.SfxVolume > 0,
			ReducedMotion = s.ReducedMotion == true,
		})
	end)
end

function ProgressionController.ClaimDaily()
	pcall(function()
		local ok = remotes.Functions.DailyClaim:InvokeServer()
		if ok then
			EffectsService.Toast("Daily claimed! +60 Coins +100 XP")
			ProfileScreen:SetDailyClaim(true)
			AudioService.PlayVictory()
		else
			EffectsService.Toast("Daily not complete yet.")
		end
	end)
end

function ProgressionController.GetDaily()
	pcall(function()
		return remotes.Functions.DailyState:InvokeServer()
	end)
end

return ProgressionController