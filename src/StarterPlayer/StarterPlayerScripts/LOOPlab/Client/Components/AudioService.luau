-- AudioService: centralized audio engine for LOOPLAB.
-- Owns all music categories + SFX. Never scatter Sound playback in screens.
-- Music: hub / per-activity / survival intensity ladder with crossfades.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
if RunService:IsServer() then return {} end

local LOCAL = Players.LocalPlayer or Players.PlayerAdded:Wait()

-- ============================================================
-- ASSET LIBRARY (rbxassetid). Swap URLs here to re-skin audio.
-- ============================================================
local AUDIO = {
	Hub1 = "rbxassetid://1837678979",
	Hub2 = "rbxassetid://1841179587",
	ChaosRun = "rbxassetid://9040222828",
	DodgeLab = "rbxassetid://9043422333",
	BuildBlitz = "rbxassetid://1837768013",
	SequenceSprint = "rbxassetid://9045929839",
	SurvivalCalm = "rbxassetid://9041912631",
	SurvivalIntense = "rbxassetid://9040222828",
	SurvivalFinal = "rbxassetid://9044820101",
	Victory = "rbxassetid://1836473422",
	Eliminated = "rbxassetid://9044820101",
	Lobby = "rbxassetid://9042466902",

	Click = "rbxassetid://88442833509532",
	Hover = "rbxassetid://119393948345399",
	Countdown = "rbxassetid://1836473398",
	Go = "rbxassetid://1836473422",
	Checkpoint = "rbxassetid://1837678979",
	Hit = "rbxassetid://9044820101",
	Place = "rbxassetid://88442833509532",
	Score = "rbxassetid://1836473398",
	Toast = "rbxassetid://1837768013",
	Eliminate = "rbxassetid://9044820101",
	Win = "rbxassetid://1836473422",
}

local AudioService = {}

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

local function playSfx(idOrAsset: string, opts)
	opts = opts or {}
	pcall(function()
		sfxChannel.SoundId = AUDIO[idOrAsset] or idOrAsset
		sfxChannel.Volume = (opts.volume or 1) * Volume.Sfx
		sfxChannel.PlaybackSpeed = opts.speed or 1
		sfxChannel:Play()
	end)
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
		[0] = AUDIO.Lobby,
		[1] = AUDIO.SurvivalCalm,
		[2] = AUDIO.SurvivalIntense,
		[3] = AUDIO.SurvivalFinal,
	}
	local asset = map[level] or AUDIO.SurvivalCalm
	if activeId ~= asset then
		AudioService.PlayMusic(asset, 0.5)
	end
end

function AudioService.PlayActivityMusic(activityId: string)
	local map = {
		chaos_run = AUDIO.ChaosRun,
		dodge_lab = AUDIO.DodgeLab,
		build_blitz = AUDIO.BuildBlitz,
		sequence_sprint = AUDIO.SequenceSprint,
	}
	AudioService.PlayMusic(map[activityId] or AUDIO.Hub1, 0.5)
end

function AudioService.PlayHubMusic()
	AudioService.PlayMusic(AUDIO.Hub1, 0.7)
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