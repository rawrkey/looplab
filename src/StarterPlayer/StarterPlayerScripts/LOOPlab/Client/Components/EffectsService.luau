-- EffectsService: screen-level feedback layer. Toasts, countdowns, banners,
-- round transitions, elimination flashes, victory celebration.
-- Uses a single ScreenGui overlay so gameplay UI stays clean.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
if RunService:IsServer() then return {} end

local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

local Theme = require(script.Parent.Theme)

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
	EffectsService.Banner(("ROUND %d"):format(round, total), activityName, accent or Theme.Brand.Primary)
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

return EffectsService