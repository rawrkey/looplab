-- AudioService: centralized audio engine for LOOPLAB.
-- Owns all music categories + SFX. Never scatter Sound playback in screens.
-- Music: hub / per-activity / survival intensity ladder with crossfades.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
if RunService:IsServer() then return {} end

local LOCAL = Players.LocalPlayer or Players.PlayerAdded:Wait()
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage:WaitForChild("LOOPlab").Configuration.GameConfig)

local AudioService = {}

-- ============================================================
-- AUDIO: pull asset library from GameConfig (single source of truth).
-- Fallbacks keep prod safe if config lags.
-- ============================================================
local MUSIC = GameConfig.Audio.Music
local SFX = GameConfig.Audio.Sfx
local FALLBACK_MUSIC = { Hub1 = "rbxassetid://1837678979", Hub2 = "rbxassetid://1841179587", SurvivalCalm = "rbxassetid://9041912631" }
local FALLBACK_SFX = { Click = "rbxassetid://88442833509532", Hover = "rbxassetid://119393948345399", Toast = "rbxassetid://1837768013" }
local function resolve(set, key, fallbackKey)
	if set and set[key] then return set[key] end
	return FALLBACK_MUSIC[fallbackKey or key] or FALLBACK_SFX[key] or ""
end

local SoundService = game:GetService("SoundService")
local root = Instance.new("Folder")
root.Name = "LOOPlabAudio"
root.Parent = SoundService

local Volume = {
	Music = 0.5,
	Sfx = 0.65,
}

local activeId: string? = nil

local sfxChannel = Instance.new("Sound")
sfxChannel.Name = "Sfx"
sfxChannel.Parent = root

local SfxQueue = {}
local SfxBusy = false
local function drainSfx()
	if SfxBusy or #SfxQueue == 0 then return end
	SfxBusy = true
	local nextSfx = table.remove(SfxQueue, 1)
	sfxChannel.SoundId = nextSfx.id
	sfxChannel.Volume = nextSfx.volume or 1
	sfxChannel.PlaybackSpeed = nextSfx.speed or 1
	sfxChannel:Play()
	sfxChannel.Ended:Wait()
	SfxBusy = false
	if #SfxQueue > 0 then drainSfx() end
end

local function playSfx(idOrAsset: string, opts)
	opts = opts or {}
	local asset = SFX and SFX[idOrAsset] or idOrAsset
	if not asset or asset == "" then
		asset = FALLBACK_SFX[idOrAsset] or idOrAsset
	end
	table.insert(SfxQueue, {
		id = asset,
		volume = (opts.volume or 1) * Volume.Sfx,
		speed = opts.speed or 1,
	})
	task.spawn(drainSfx)
end

local musicPool = {}
local function getMusic(assetId)
	local s = musicPool[assetId]
	if not s then
		s = Instance.new("Sound")
		s.SoundId = assetId
		s.Looped = true
		s.Volume = 0
		s.Parent = root
		musicPool[assetId] = s
	end
	return s
end

function AudioService.PlayMusic(assetId: string?, fade: number?)
	fade = fade or 0.6
	if activeId and activeId ~= assetId then
		local old = musicPool[activeId]
		if old then
			task.spawn(function()
				local t = game:GetService("TweenService"):Create(old, TweenInfo.new(fade, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Volume = 0 })
				t:Play()
				t.Completed:Wait()
				old:Stop()
			end)
		end
	end
	activeId = assetId
	if not assetId then
		return
	end
	local new = getMusic(assetId)
	new:Play()
	local t = game:GetService("TweenService"):Create(new, TweenInfo.new(fade, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Volume = Volume.Music })
	t:Play()
end

function AudioService.StopMusic(fade: number?)
	fade = fade or 0.5
	if activeId then
		local old = musicPool[activeId]
		if old then
			task.spawn(function()
				local t = game:GetService("TweenService"):Create(old, TweenInfo.new(fade, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Volume = 0 })
				t:Play()
				t.Completed:Wait()
				old:Stop()
			end)
		end
	end
	activeId = nil
end

-- intensity ladder for survival
function AudioService.SetIntensity(level: number)
	local map = {
		[0] = MUSIC and MUSIC.Survival and MUSIC.Survival.Lobby or FALLBACK_MUSIC.SurvivalCalm,
		[1] = MUSIC and MUSIC.Survival and MUSIC.Survival.Normal or FALLBACK_MUSIC.SurvivalCalm,
		[2] = MUSIC and MUSIC.Survival and MUSIC.Survival.Intense or FALLBACK_MUSIC.SurvivalCalm,
		[3] = MUSIC and MUSIC.Survival and MUSIC.Survival.Final or FALLBACK_MUSIC.SurvivalCalm,
	}
	local asset = map[level] or FALLBACK_MUSIC.SurvivalCalm
	if activeId ~= asset then
		AudioService.PlayMusic(asset, 0.5)
	end
end

function AudioService.PlayActivityMusic(activityId: string, intensity: number?)
	if activityId == "survival" then
		AudioService.SetIntensity(math.clamp(intensity or 1, 0, 3))
		return
	end
	local map = {
		chaos_run = MUSIC and MUSIC.ChaosRun or FALLBACK_MUSIC.Hub1,
		dodge_lab = MUSIC and MUSIC.DodgeLab or FALLBACK_MUSIC.Hub1,
		build_blitz = MUSIC and MUSIC.BuildBlitz or FALLBACK_MUSIC.Hub1,
		sequence_sprint = MUSIC and MUSIC.SequenceSprint or FALLBACK_MUSIC.Hub1,
	}
	AudioService.PlayMusic(map[activityId] or FALLBACK_MUSIC.Hub1, 0.5)
end

function AudioService.PlayHubMusic()
	AudioService.PlayMusic(MUSIC and MUSIC.Hub or FALLBACK_MUSIC.Hub1, 0.7)
end

function AudioService.PlayLobby()
	AudioService.PlayMusic(MUSIC and MUSIC.Survival and MUSIC.Survival.Lobby or FALLBACK_MUSIC.SurvivalCalm, 0.5)
end

function AudioService.PlayVictory()
	playSfx("Win")
end
function AudioService.PlayEliminated()
	playSfx("Eliminate")
end
function AudioService.PlayCountdown()
	playSfx("Countdown")
end
function AudioService.PlayGo()
	playSfx("Go")
end
function AudioService.PlayClick()
	playSfx("Click")
end
function AudioService.PlayHover()
	playSfx("Hover", { volume = Volume.Sfx + 0.2 })
end
function AudioService.PlayCheckpoint()
	playSfx("Checkpoint")
end
function AudioService.PlayHit()
	playSfx("Hit")
end
function AudioService.PlayPlace()
	playSfx("Place")
end
function AudioService.PlayScore()
	playSfx("Score")
end
function AudioService.PlayToast()
	playSfx("Toast")
end

function AudioService.PlayLevelUp()
	playSfx("LevelUp")
end
function AudioService.PlayBadge()
	playSfx("Badge")
end
function AudioService.PlayTitle()
	playSfx("Title")
end
function AudioService.PlayMastery()
	playSfx("Mastery")
end
function AudioService.PlayFinal3()
	playSfx("Final3")
end
function AudioService.PlayFinal2()
	playSfx("Final2")
end
function AudioService.PlayPersonalBest()
	playSfx("PersonalBest")
end
function AudioService.PlayRewardReveal()
	playSfx("Reward")
end

function AudioService.SetMusicVolume(v: number)
	Volume.Music = v
	if activeId then
		local s = musicPool[activeId]
		if s then s.Volume = v end
	end
end
function AudioService.SetSfxVolume(v: number)
	Volume.Sfx = v
end

AudioService.GetMusicVolume = function() return Volume.Music end
AudioService.GetSfxVolume = function() return Volume.Sfx end

return AudioService