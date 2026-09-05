-- EffectsService: screen-level feedback layer. Toasts, countdowns, banners,
-- round transitions, elimination flashes, victory celebration, and the new
-- progression moments (LevelUp, BadgeReveal, TitleReveal, MasteryUp, PersonalBest).
-- Uses a single ScreenGui overlay so gameplay UI stays clean.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
if RunService:IsServer() then return {} end

local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local AudioService = require(script.Parent.AudioService)

local Theme = require(script.Parent.Theme)
local UIKit = require(script.Parent.UIKit)

local EffectsService = {}

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "LOOPlabFx"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 99
ScreenGui.Parent = PlayerGui

local function panel(parent, size, color, pos)
	local f = Instance.new("Frame")
	f.Size = size
	f.BackgroundColor3 = color
	f.BorderSizePixel = 0
	f.BackgroundTransparency = 1
	f.Position = pos or UDim2.fromScale(0.5, 0.5)
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.Parent = parent
	return f
end

local function label(parent, text, size, color, font)
	local t = Instance.new("TextLabel")
	t.Size = size or UDim2.fromScale(0.6, 0.2)
	t.BackgroundTransparency = 1
	t.Text = text
	t.TextColor3 = color or Theme.Palette.Text
	t.Font = font or Theme.Type.Header
	t.TextScaled = true
	t.TextWrapped = true
	t.Position = UDim2.fromScale(0.5, 0.5)
	t.AnchorPoint = Vector2.new(0.5, 0.5)
	t.Parent = parent
	return t
end

function EffectsService.Toast(message: string, opts)
	opts = opts or {}
	local holder = panel(ScreenGui, UDim2.new(0.4, 0, 0.08, 0), Color3.fromRGB(20, 22, 34), UDim2.new(0.5, 0, 0.86, 0))
	local frame = panel(holder, UDim2.fromScale(1, 1), opts.color or Theme.Palette.PanelAlt)
	frame.BackgroundTransparency = 0.12
	local text = label(frame, message, UDim2.fromScale(1, 1), opts.textColor or Theme.Palette.Text)
	text.TextScaled = false
	text.TextSize = Theme.TypeSize.Body
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.Position = UDim2.new(0.5, 0, 0.9, 0)
	holder.BackgroundTransparency = 1

	frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Size = UDim2.fromScale(0.92, 0.92)
	local goal = UDim2.fromScale(1, 1)
	TweenService:Create(frame, TweenInfo.new(Theme.Motion.Quick, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = goal }):Play()

	task.delay((opts.seconds or 2.2), function()
		TweenService:Create(holder, TweenInfo.new(Theme.Motion.Normal, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 1 }):Play()
		task.delay(Theme.Motion.Normal, function()
			frame:Destroy()
			holder:Destroy()
		end)
	end)
end

function EffectsService.Countdown(count: number, onDone)
	local layer = panel(ScreenGui, UDim2.new(0.5, 0, 0.5, 0), Color3.fromRGB(10, 12, 20), UDim2.fromScale(0.5, 0.5))
	layer.BackgroundColor3 = Color3.fromRGB(8, 10, 18)
	layer.BackgroundTransparency = 0.25

	local txt = label(layer, tostring(count), UDim2.fromScale(1, 1), Theme.Brand.Primary, Theme.Type.Title)
	txt.TextSize = 120
	txt.TextScaled = true

	local step = 1
	local function tick()
		if step > count then
			txt.Text = "GO!"
			txt.TextColor3 = Theme.Brand.Success
			TweenService:Create(txt, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { TextTransparency = 0 }):Play()
			task.delay(0.9, function()
				TweenService:Create(layer, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 1 }):Play()
				task.delay(0.35, function()
					layer:Destroy()
					if onDone then onDone() end
				end)
			end)
			return
		end
		txt.Text = tostring(step)
		txt.TextColor3 = Theme.Brand.Primary
		txt.TextTransparency = 1
		TweenService:Create(txt, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { TextTransparency = 0 }):Play()
		step += 1
		task.delay(0.55, tick)
	end
	tick()
	return layer
end

function EffectsService.Banner(text: string, subtext: string?, accent: Color3?)
	accent = accent or Theme.Brand.Primary
	local layer = panel(ScreenGui, UDim2.new(0.7, 0, 0.5, 0), Color3.fromRGB(10, 12, 20), UDim2.fromScale(0.5, 0.5))
	layer.BackgroundTransparency = 0.4
	local t = label(layer, text, UDim2.fromScale(1, 0.5), accent, Theme.Type.Header)
	t.TextSize = 52
	local s
	if subtext then
		s = label(layer, subtext, UDim2.fromScale(1, 0.5), Theme.Palette.TextDim, Theme.Type.Body)
		s.Position = UDim2.new(0.5, 0, 0.68, 0)
		s.TextScaled = false
		s.TextSize = 22
		s.TextTransparency = 0.3
	end
	t.Position = UDim2.fromScale(0.5, 0.5)
	t.TextTransparency = 1
	TweenService:Create(t, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { TextTransparency = 0 }):Play()
	task.delay(2.6, function()
		local out = TweenService:Create(layer, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 1 })
		out:Play()
		task.delay(0.4, function() layer:Destroy() end)
	end)
	return layer
end

function EffectsService.EliminateFlash(accent: Color3?)
	accent = accent or Theme.Brand.Danger
	local layer = panel(ScreenGui, UDim2.fromScale(1, 1), accent, UDim2.fromScale(0, 0))
	layer.AnchorPoint = Vector2.zero
	layer.BackgroundTransparency = 0.75
	TweenService:Create(layer, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 0.95 }):Play()
	task.delay(0.55, function() layer:Destroy() end)
end

function EffectsService.RoundBanner(round: number, total: number, activityName: string, accent: Color3?)
	EffectsService.Banner(("ROUND %d"):format(round), activityName, accent or Theme.Brand.Primary)
end

function EffectsService.Victory(winnerName: string, accent: Color3?)
	accent = accent or Theme.Brand.Gold
	local layer = panel(ScreenGui, UDim2.fromScale(1, 1), Color3.fromRGB(8, 10, 18), UDim2.fromScale(0, 0))
	layer.AnchorPoint = Vector2.zero
	layer.BackgroundTransparency = 0.2
	local crown = label(layer, "VICTORY", UDim2.fromScale(0.6, 0.18), accent, Theme.Type.Title)
	crown.Position = UDim2.fromScale(0.5, 0.34)
	crown.TextSize = 70
	local who = label(layer, (winnerName .. " takes the crown!"), UDim2.fromScale(0.6, 0.1), Theme.Brand.Gold, Theme.Type.Header)
	who.Position = UDim2.fromScale(0.5, 0.56)
	who.TextScaled = false
	who.TextSize = 26
	who.TextColor3 = Theme.Brand.Gold

	for i = 1, 3 do
		TweenService:Create(crown, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { TextTransparency = 0 }):Play()
		TweenService:Create(crown, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { TextTransparency = 0.4 }):Play()
	end
	TweenService:Create(crown, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { TextTransparency = 0 }):Play()

	task.delay(4.0, function()
		TweenService:Create(layer, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 1 }):Play()
		task.delay(0.5, function() layer:Destroy() end)
	end)
	return layer
end

function EffectsService.HoldLayer(skipTransparency: boolean)
	local layer = panel(ScreenGui, UDim2.fromScale(1, 1), Color3.fromRGB(8, 10, 18), UDim2.fromScale(0, 0))
	layer.AnchorPoint = Vector2.zero
	layer.BackgroundTransparency = 0.3
	if skipTransparency then layer.BackgroundTransparency = 1 end
	return layer
end

-- ========== NEW PROGRESSION PRESENTATIONS ==========

local function revealCard(title, sub, icon, accent)
	accent = accent or Theme.Brand.Primary
	local layer = panel(ScreenGui, UDim2.new(0.56, 0, 0.3, 0), Color3.fromRGB(8, 10, 18), UDim2.fromScale(0.5, 0.5))
	layer.BackgroundTransparency = 0.1
	UIKit.Corner(Theme.Radius.Medium).Parent = layer

	local line = Instance.new("Frame")
	line.Size = UDim2.new(1, 0, 0, 3)
	line.AnchorPoint = Vector2.new(0, 0)
	line.BackgroundColor3 = accent
	line.BorderSizePixel = 0
	line.Parent = layer

	local iconLbl = label(layer, icon or "✦", UDim2.new(1, 0, 0.4, 0), accent, Theme.Type.Title)
	iconLbl.Position = UDim2.new(0.5, 0, 0.28, 0)
	iconLbl.TextSize = 48

	local t = label(layer, title, UDim2.new(0.96, 0, 0.2, 0), Theme.Palette.Text, Theme.Type.Header)
	t.Position = UDim2.new(0.5, 0, 0.66, 0)
	t.TextScaled = false
	t.TextSize = Theme.TypeSize.Huge
	t.TextTransparency = 1

	local s
	if sub then
		s = label(layer, sub, UDim2.new(0.96, 0, 0.12, 0), Theme.Palette.TextDim, Theme.Type.Body)
		s.Position = UDim2.new(0.5, 0, 0.84, 0)
		s.TextScaled = false
		s.TextSize = Theme.TypeSize.Body
		s.TextTransparency = 1
	end

	layer.BackgroundTransparency = 1
	layer.Size = UDim2.new(0.56, 0, 0.16, 0)
	TweenService:Create(layer, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		BackgroundTransparency = 0.1,
		Size = UDim2.new(0.56, 0, 0.3, 0),
	}):Play()
	TweenService:Create(t, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { TextTransparency = 0 }):Play()
	if s then
		TweenService:Create(s, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { TextTransparency = 0 }):Play()
	end
	task.delay(2.2, function()
		TweenService:Create(layer, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 1, Size = UDim2.new(0.56, 0, 0.16, 0) }):Play()
		task.delay(0.4, function() layer:Destroy() end)
	end)
	return layer
end

function EffectsService.LevelUp(payload)
	payload = payload or {}
	local level = payload.Level or 1
	local coins = payload.Coins or 0
	revealCard(("LEVEL %d"):format(level), ("+%d Coins"):format(coins), "▲", Theme.Brand.Success)
	AudioService.PlayLevelUp()
end

function EffectsService.BadgeReveal(badge)
	if not badge then return end
	revealCard(badge.Name or "BADGE", badge.Desc or "Achievement unlocked", badge.Icon or "✦", Theme.Brand.Gold)
	AudioService.PlayBadge()
end

function EffectsService.TitleReveal(title)
	if not title then return end
	revealCard(("TITLE: %s"):format(title.Name or "New Title"), "Equip it from your Profile", "♛", Theme.Accent("survival"))
	AudioService.PlayTitle()
end

function EffectsService.MasteryUp(rank)
	rank = rank or { Display = "BRONZE" }
	local color = Theme.MasteryColor(rank.Id or "bronze")
	revealCard(("MASTERY RANK UP: %s"):format(rank.Display or rank.Id), "Your legend grows", "◆", color)
	AudioService.PlayMastery()
end

function EffectsService.PersonalBest(score)
	revealCard(("PERSONAL BEST!  %d"):format(score or 0), "New record", "⚑", Theme.Brand.Primary)
	AudioService.PlayPersonalBest()
end

function EffectsService.Final3()
	EffectsService.Banner("FINAL 3", "Survive to the end", Theme.Accent("survival"))
	AudioService.PlayFinal3()
end

function EffectsService.Final2()
	EffectsService.Banner("FINAL 2", "One more to win it all", Theme.Accent("survival"))
	AudioService.PlayFinal2()
end

function EffectsService.RewardReveal(xp, coins, extra)
	local layer = panel(ScreenGui, UDim2.new(0.5, 0, 0.16, 0), Color3.fromRGB(8, 10, 18), UDim2.fromScale(0.5, 0.78))
	layer.BackgroundTransparency = 0.1
	UIKit.Corner(Theme.Radius.Medium).Parent = layer
	local txt = label(layer, ("+%d XP   +%d Coins"):format(xp or 0, coins or 0), UDim2.fromScale(1, 1), Theme.Brand.Gold, Theme.Type.Header)
	txt.TextScaled = false
	txt.TextSize = Theme.TypeSize.Header
	if extra then
		local sub = label(layer, extra, UDim2.fromScale(1, 0.4), Theme.Palette.TextDim, Theme.Type.Body)
		sub.Position = UDim2.new(0.5, 0, 0.74, 0)
		sub.TextScaled = false
		sub.TextSize = Theme.TypeSize.Small
	end
	layer.BackgroundTransparency = 1
	TweenService:Create(layer, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { BackgroundTransparency = 0.1 }):Play()
	AudioService.PlayRewardReveal()
	task.delay(2.4, function()
		TweenService:Create(layer, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 1 }):Play()
		task.delay(0.4, function() layer:Destroy() end)
	end)
	return layer
end

return EffectsService