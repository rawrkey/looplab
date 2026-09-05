-- ProgressionController: profile/rewards UX, settings save, daily claim,
-- title equip, and the server push-content Fx queue (badges, titles, mastery).

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
local CosmeticsScreen

local LastProfile = nil

local function xpNextFor(level)
	local curve = GameConfig.Xp.LevelCurve
	return curve[math.min(level + 1, #curve)] or (curve[level] or 100)
end

function ProgressionController.Init(screens)
	Hub = screens.Hub
	ProfileScreen = screens.Profile
	SettingsScreen = screens.Settings
	CosmeticsScreen = screens.Cosmetics

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
	ProfileScreen.OnEquipTitle = function(id)
		ProgressionController.EquipTitle(id)
	end

	if CosmeticsScreen then
		CosmeticsScreen.OnClose = function()
			ViewController.Show("Hub")
		end
		CosmeticsScreen.OnEquipTitle = function(id)
			ProgressionController.EquipTitle(id)
		end
	end
end

-- Serialized handling of the server-side Fx queue (drained on each poll).
function ProgressionController.HandleFxQueue(fxList)
	if not type(fxList) == "table" then return end
	for _, entry in fxList do
		local kind = entry.Kind
		local data = entry.Data or {}
		if kind == "MasteryUp" then
			EffectsService.MasteryUp(data.Rank)
		elseif kind == "PersonalBest" then
			EffectsService.PersonalBest(data.Score or 0)
		elseif kind == "Badge" then
			EffectsService.BadgeReveal(data.Badge)
		elseif kind == "Title" then
			EffectsService.TitleReveal(data.Title)
		end
	end
end

function ProgressionController.ShowProfile()
	ViewController.Show("Profile")
	ProgressionController.FetchProfile()
	task.spawn(function()
		pcall(function()
			local daily = remotes.Functions.DailyState:InvokeServer()
			if daily and ProfileScreen then
				ProfileScreen:SetDailyClaim(daily.Claimed == true)
			end
		end)
	end)
end

function ProgressionController.FetchProfile()
	pcall(function()
		local profile = remotes.Functions.ProfileFetch:InvokeServer()
		if profile then
			LastProfile = profile
			ProgressionController.ApplyProfile(profile)
		end
	end)
end

function ProgressionController.ShowCosmetics()
	if not CosmeticsScreen then return end
	if not LastProfile then
		ProgressionController.FetchProfile()
	end
	if LastProfile then
		CosmeticsScreen:Show({
			Titles = LastProfile.Titles or {},
			Badges = LastProfile.Badges or {},
			EquippedTitle = LastProfile.EquippedTitle or "",
		})
	end
end

local function summaryStats(profile)
	local matches, wins, survivalMatches, survivalWins = 0, 0, 0, 0
	for _, g in (profile.Games or {}) do
		matches += g.Plays or 0
		wins += g.Wins or 0
	end
	local surv = profile.Survival or {}
	survivalMatches = surv.Matches or 0
	survivalWins = surv.Wins or 0
	return {
		MatchesPlayed = matches,
		Wins = wins,
		SurvivalMatches = survivalMatches,
		SurvivalWins = survivalWins,
		CoinsEarned = profile.Coins or 0,
		DailiesClaimed = profile.Daily and profile.Daily.Claimed == true and 1 or 0,
	}
end

function ProgressionController.ApplyProfile(profile)
	if not profile then return end
	LastProfile = profile
	if Hub then
		Hub:SetProgression(profile.Level, profile.Xp, xpNextFor(profile.Level), profile.Coins)
		Hub:SetMastery(profile.MasteryRank)
		Hub:SetRecords(profile.Records)
	end
	if ProfileScreen then
		ProfileScreen:SetProfile({
			Name = profile.DisplayName,
			Progress = {
				Level = profile.Level,
				Xp = profile.Xp,
				XpNext = xpNextFor(profile.Level),
			},
			Stats = summaryStats(profile),
			MasteryRank = profile.MasteryRank,
			MasteryXp = profile.MasteryXp,
			Badges = profile.Badges,
			Titles = profile.Titles,
			EquippedTitle = profile.EquippedTitle,
			Records = profile.Records,
		})
	end
end

function ProgressionController.EconomyUpdate(payload)
	if not payload then return end
	if Hub then
		Hub:SetProgression(payload.Level, payload.Xp, xpNextFor(payload.Level), payload.Coins)
		Hub:SetMastery(payload.MasteryRank)
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
			ProgressionController.FetchProfile()
		else
			EffectsService.Toast("Daily not complete yet.")
		end
	end)
end

function ProgressionController.EquipTitle(titleId: string)
	if type(titleId) ~= "string" then return end
	pcall(function()
		local ok = remotes.Functions.TitleEquip:InvokeServer(titleId)
		if ok then
			AudioService.PlayClick()
			EffectsService.Toast("Title equipped")
			ProgressionController.FetchProfile()
		else
			EffectsService.Toast("You don't own that title yet.")
		end
	end)
end

function ProgressionController.GetDaily()
	pcall(function()
		return remotes.Functions.DailyState:InvokeServer()
	end)
end

return ProgressionController