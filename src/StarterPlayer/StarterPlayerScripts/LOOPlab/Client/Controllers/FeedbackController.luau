-- FeedbackController: lightweight in-activity game-feel (audio + subtle
-- on-screen telegraphs) for discrete gameplay moments. Consumes the same
-- server-authoritative Fx queue as progression notifications.
-- Honors Reduced Motion for the visual portion only (audio is always safe).

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local AudioService = require(script.Parent.Parent.Components.AudioService)
local EffectsService = require(script.Parent.Parent.Components.EffectsService)
local Theme = require(script.Parent.Parent.Components.Theme)
local UIKit = require(script.Parent.Parent.Components.UIKit)

local FeedbackController = {}

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "LOOPlabFeedback"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 100
ScreenGui.Parent = PlayerGui

local BELL = Color3.fromRGB(255, 214, 90)

-- Coalesce per-kind so a burst (e.g. rapid block placement) doesn't flood SFX.
local LastPlayed = {}
local COOLDOWN = {
	place = 0.12,
	correct = 0.08,
	checkpoint = 0.25,
	hit = 0.35,
	roundclear = 0.3,
	finish = 0.5,
	_wrong = 0.25,
}

local function throttled(kind)
	local now = os.clock()
	if LastPlayed[kind] and (now - LastPlayed[kind]) < (COOLDOWN[kind] or 0.2) then
		return true
	end
	LastPlayed[kind] = now
	return false
end

-- A tiny centered word that fades out. Motion-aware: with Reduced Motion it
-- simply appears and disappears (no tween).
local function telegraph(text, color, tint)
	if UIKit.ReducedMotion then
		return
	end
	local holder = Instance.new("Frame")
	holder.Name = "Telegraph"
	holder.Size = UDim2.new(0.5, 0, 0.16, 0)
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.Position = UDim2.new(0.5, 0, 0.5, -40)
	holder.BackgroundTransparency = 1
	holder.Parent = ScreenGui

	local word = Instance.new("TextLabel")
	word.Size = UDim2.fromScale(1, 1)
	word.BackgroundTransparency = 1
	word.Text = text
	word.Font = Theme.Type.Display
	word.TextScaled = true
	word.TextColor3 = color or BELL
	word.TextTransparency = 1
	word.Parent = holder

	if tint then
		local flash = Instance.new("Frame")
		flash.Size = UDim2.fromScale(1, 1)
		flash.AnchorPoint = Vector2.new(0.5, 0.5)
		flash.Position = UDim2.fromScale(0.5, 0.5)
		flash.BackgroundColor3 = tint
		flash.BackgroundTransparency = 0.7
		flash.ZIndex = 0
		flash.Parent = holder
		local t = TweenService:Create(flash, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 1 })
		t:Play()
	end

	TweenService:Create(word, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { TextTransparency = 0 }):Play()
	task.delay(0.7, function()
		TweenService:Create(word, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			TextTransparency = 1,
			Position = UDim2.new(0.5, 0, 0.48, -40),
		}):Play()
		task.delay(0.32, function()
			if holder.Parent then holder:Destroy() end
		end)
	end)
end

function FeedbackController.Handle(kind, data)
	if type(kind) ~= "string" then return end
	data = data or {}

	if kind == "checkpoint" then
		-- progression pulse on a successful checkpoint
		if throttled("checkpoint") then return end
		AudioService.PlayCheckpoint()
		telegraph("CHECKPOINT", Theme.Brand.Success, Theme.Brand.Success)
	elseif kind == "finish" then
		if throttled("finish") then return end
		AudioService.PlayScore()
		telegraph("FINISH!", Theme.Brand.Success)
	elseif kind == "hit" then
		if throttled("hit") then return end
		AudioService.PlayHit()
		telegraph("HIT", Theme.Brand.Danger, Theme.Brand.Danger)
	elseif kind == "place" then
		if throttled("place") then return end
		AudioService.PlayPlace()
	elseif kind == "correct" then
		if throttled("correct") then return end
		AudioService.PlayScore()
		telegraph(data.Pad or "+", Theme.Brand.Success)
	elseif kind == "wrong" then
		if throttled("_wrong") then return end
		AudioService.PlayHit()
		telegraph("MISS", Theme.Brand.Danger, Theme.Brand.Danger)
	elseif kind == "roundclear" then
		if throttled("roundclear") then return end
		AudioService.PlayCheckpoint()
		telegraph("ROUND CLEAR", Theme.Brand.Success)
	end
end

return FeedbackController
