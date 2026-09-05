-- UIKit: LOOPLAB visual building blocks. Themed, motion-aware, reusable.
-- Screens should build on these primitives rather than raw instances.
-- Honors ReducedMotion globally: set UIKit.ReducedMotion = true to disable transitions.

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Theme = require(script.Parent.Theme)

local UIKit = {}

UIKit.ReducedMotion = false
UIKit.IsTouch = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local function new(className, props)
	local inst = Instance.new(className)
	for k, v in pairs(props or {}) do
		inst[k] = v
	end
	return inst
end

local function dur(d): number
	if UIKit.ReducedMotion then return 0 end
	return d or Theme.Motion.Quick
end

function UIKit.Tween(inst, goal, duration, style, direction)
	style = style or Theme.MotionEase
	direction = direction or Enum.EasingDirection.Out
	duration = dur(duration)
	return TweenService:Create(inst, TweenInfo.new(duration, style, direction), goal)
end

function UIKit.PlayPop(inst, scale: number?, duration: number?)
	scale = scale or 1.06
	duration = dur(duration or Theme.Motion.Quick)
	if UIKit.ReducedMotion then return nil end
	local s = inst.Size
	local t = UIKit.Tween(inst, {
		Size = UDim2.new(s.X.Scale * scale, s.X.Offset * scale, s.Y.Scale * scale, s.Y.Offset * scale),
		Position = inst.Position + UDim2.fromScale(0, -0.02),
	}, duration, Theme.MotionBounce)
	t:Play()
	return t
end

function UIKit.Frame(props)
	return new("Frame", props)
end

function UIKit.Corner(radius: UDim?)
	return new("UICorner", { CornerRadius = radius or Theme.Radius.Medium })
end

function UIKit.Stroke(color: Color3?, thickness: number?, transparency: number?)
	return new("UIStroke", {
		Color = color or Theme.Palette.StrokeDim,
		Thickness = thickness or Theme.Stroke.Hairline,
		Transparency = transparency or Theme.Opacity.Subtle,
	})
end

function UIKit.Gradient(color1: Color3, color2: Color3, rotation: number?)
	return new("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, color1),
			ColorSequenceKeypoint.new(1, color2),
		}),
		Rotation = rotation or 90,
	})
end

function UIKit.Panel(parent, size, color, radius)
	local f = new("Frame", {
		Parent = parent,
		Size = size,
		BackgroundColor3 = color or Theme.Palette.Panel,
		BorderSizePixel = 0,
		BackgroundTransparency = Theme.Opacity.Solid,
	})
	UIKit.Corner(radius or Theme.Radius.Medium).Parent = f
	return f
end

function UIKit.Card(parent, size, accent)
	local f = UIKit.Panel(parent, size, Theme.Palette.Panel)
	f.BackgroundTransparency = Theme.Opacity.Card
	UIKit.Stroke(accent or Theme.Palette.StrokeDim, Theme.Stroke.Hairline, Theme.Opacity.Std).Parent = f
	return f
end

function UIKit.PanelAlt(parent, size, accent)
	local f = UIKit.Panel(parent, size, Theme.Palette.PanelAlt)
	if accent then
		local line = new("Frame", {
			Parent = f,
			Size = UDim2.new(1, 0, 0, 3),
			AnchorPoint = Vector2.new(0, 0),
			BackgroundColor3 = accent,
			BorderSizePixel = 0,
		})
		UIKit.Corner(Theme.Radius.Small).Parent = line
		line.Parent = f
	end
	return f
end

function UIKit.Title(parent, text, size, color)
	size = size or UDim2.new(1, 0, 0, 40)
	return new("TextLabel", {
		Parent = parent,
		Size = size,
		Text = text,
		TextScaled = true,
		Font = Theme.Type.Title,
		TextColor3 = color or Theme.Palette.Text,
		BackgroundTransparency = 1,
		TextTransparency = 0,
	})
end

function UIKit.Text(parent, text, size, color, font)
	return new("TextLabel", {
		Parent = parent,
		Size = size or UDim2.new(1, 0, 0, 26),
		Text = text,
		TextScaled = true,
		Font = font or Theme.Type.Body,
		TextColor3 = color or Theme.Palette.Text,
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
	})
end

function UIKit.Muted(parent, text, size, color, font)
	return new("TextLabel", {
		Parent = parent,
		Size = size or UDim2.new(1, 0, 0, 22),
		Text = text,
		TextScaled = true,
		Font = font or Theme.Type.Body,
		TextColor3 = color or Theme.Palette.TextDim,
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
	})
end

function UIKit.Display(parent, text, color)
	local l = new("TextLabel", {
		Parent = parent,
		Size = UDim2.new(1, 0, 0, 64),
		Text = text,
		Font = Theme.Type.Display,
		TextColor3 = color or Theme.Palette.Text,
		BackgroundTransparency = 1,
		TextScaled = true,
	})
	return l
end

function UIKit.Button(parent, text, size, color, opts)
	opts = opts or {}
	local base = color or Theme.Brand.Primary
	local btn = new("TextButton", {
		Parent = parent,
		Size = size,
		Text = text,
		TextScaled = not opts.noScale,
		Font = opts.font or Theme.Type.Header,
		TextColor3 = opts.textColor or Theme.Palette.Text,
		BackgroundColor3 = base,
		BorderSizePixel = 0,
		AutoButtonColor = true,
		BackgroundTransparency = opts.transparency or Theme.Opacity.Solid,
	})
	UIKit.Corner(Theme.Radius.Pill).Parent = btn
	btn.MouseButton1Click:Connect(function()
		if not UIKit.ReducedMotion then
			UIKit.PlayPop(btn, 0.94, Theme.Motion.Quick)
		end
	end)
	if not UIKit.IsTouch then
		btn.MouseEnter:Connect(function()
			btn.BackgroundColor3 = Theme.Lighten(base, 0.12)
		end)
		btn.MouseLeave:Connect(function()
			btn.BackgroundColor3 = base
		end)
	end
	return btn
end

function UIKit.GradientButton(parent, text, size, accent, opts)
	opts = opts or {}
	local btn = UIKit.Button(parent, text, size, accent, { font = opts.font or Theme.Type.Header, textColor = opts.textColor or Color3.new(1, 1, 1) })
	local gradient = new("UIGradient", {
		Rotation = opts.rotation or 90,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, accent),
			ColorSequenceKeypoint.new(1, opts.secondary or Theme.Brand.Secondary),
		}),
	})
	gradient.Parent = btn
	return btn
end

function UIKit.SolidButton(parent, text, size, color, opts)
	return UIKit.Button(parent, text, size, color, opts or {})
end

function UIKit.IconButton(parent, icon: string, size, color, opts)
	opts = opts or {}
	local btn = UIKit.Button(parent, "", size, color or Theme.Palette.PanelAlt, { textColor = opts.textColor or Theme.Palette.Text })
	local label = UIKit.Text(btn, icon, UDim2.fromScale(0.5, 0.5), opts.textColor or Theme.Palette.Text)
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Position = UDim2.fromScale(0.5, 0.5)
	return btn
end

function UIKit.Chip(parent, text, color, opts)
	opts = opts or {}
	local chip = new("TextButton", {
		Parent = parent,
		AutoButtonColor = false,
		Size = opts.size or UDim2.new(0, 0, 0, 28),
		Text = text,
		Font = opts.font or Theme.Type.Header,
		TextSize = opts.textSize or Theme.TypeSize.Small,
		TextColor3 = opts.textColor or Theme.Palette.Text,
		BackgroundColor3 = color or Theme.Palette.PanelAlt,
		BackgroundTransparency = Theme.Opacity.Solid,
	})
	UIKit.Corner(Theme.Radius.Pill).Parent = chip
	if opts.autosize then
		local label = chip:FindFirstChildWhichIsA("TextLabel") or chip
		chip.Size = UDim2.new(0, label.TextBounds.X + 24, 0, 28)
	end
	return chip
end

function UIKit.Separator(parent, color, axis)
	axis = axis or "h"
	local size = axis == "h" and UDim2.new(1, -40, 0, 1) or UDim2.new(0, 1, 1, -40)
	return new("Frame", {
		Parent = parent,
		Size = size,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		BackgroundColor3 = color or Theme.Palette.StrokeDim,
		BackgroundTransparency = Theme.Opacity.Std,
		BorderSizePixel = 0,
	})
end

function UIKit.ProgressBar(parent, size, fillColor, fillFraction)
	local wrap = UIKit.Frame({
		Parent = parent,
		Size = size,
		BackgroundColor3 = Theme.Palette.Background,
	})
	wrap.BackgroundTransparency = Theme.Opacity.Solid
	UIKit.Corner(Theme.Radius.Pill).Parent = wrap
	local fill = UIKit.Frame({
		Parent = wrap,
		Size = UDim2.new(fillFraction or 0, 0, 1, 0),
		BackgroundColor3 = fillColor or Theme.Brand.Primary,
	})
	UIKit.Corner(Theme.Radius.Pill).Parent = fill
	return wrap, fill
end

function UIKit.Badge(parent, text, color, size)
	size = size or UDim2.fromOffset(36, 36)
	local b = UIKit.Frame({
		Parent = parent,
		Size = size,
		BackgroundColor3 = color or Theme.Palette.PanelAlt,
	})
	UIKit.Corner(Theme.Radius.Pill).Parent = b
	local t = UIKit.Text(b, text or "", UDim2.fromScale(0.8, 0.8), Theme.Palette.Text)
	t.TextScaled = true
	t.AnchorPoint = Vector2.new(0.5, 0.5)
	t.Position = UDim2.fromScale(0.5, 0.5)
	return b
end

function UIKit.StatBox(parent, size, label, value, icon, accent)
	local box = UIKit.Card(parent, size, accent)
	box.BackgroundTransparency = Theme.Opacity.Card

	if icon then
		local iconLbl = Instance.new("TextLabel")
		iconLbl.Name = "Icon"
		iconLbl.Size = UDim2.new(0.5, 0, 0.5, 0)
		iconLbl.BackgroundTransparency = 1
		iconLbl.Text = icon
		iconLbl.TextColor3 = accent or Theme.Brand.Primary
		iconLbl.Font = Theme.Type.Body
		iconLbl.TextSize = 18
		iconLbl.TextXAlignment = Enum.TextXAlignment.Left
		iconLbl.TextYAlignment = Enum.TextYAlignment.Center
		iconLbl.AnchorPoint = Vector2.new(0, 0)
		iconLbl.Position = UDim2.new(0.05, 0, 0.1, 0)
		iconLbl.Parent = box
	end

	local v = Instance.new("TextLabel")
	v.Name = "Value"
	v.Size = UDim2.new(0.9, 0, 0, 24)
	v.BackgroundTransparency = 1
	v.Text = value or "0"
	v.TextColor3 = Theme.Palette.Text
	v.Font = Theme.Type.Header
	v.TextScaled = false
	v.TextSize = Theme.TypeSize.Header
	v.TextXAlignment = Enum.TextXAlignment.Left
	v.TextYAlignment = Enum.TextYAlignment.Center
	v.AnchorPoint = Vector2.new(0, 0)
	v.Position = UDim2.new(0.05, 0, 0.42, 0)
	v.Parent = box

	local l = Instance.new("TextLabel")
	l.Name = "Label"
	l.Size = UDim2.new(0.9, 0, 0, 16)
	l.BackgroundTransparency = 1
	l.Text = label or ""
	l.TextColor3 = Theme.Palette.TextDim
	l.Font = Theme.Type.Body
	l.TextScaled = false
	l.TextSize = Theme.TypeSize.Tiny
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.TextYAlignment = Enum.TextYAlignment.Center
	l.AnchorPoint = Vector2.new(0, 1)
	l.Position = UDim2.new(0.05, 0, 0.95, 0)
	l.Parent = box
	return box
end

function UIKit.SectionLabel(parent, text, size)
	local l = new("TextLabel", {
		Parent = parent,
		Size = size or UDim2.new(1, 0, 0, 22),
		Text = (text or ""):upper(),
		Font = Theme.Type.Header,
		TextSize = Theme.TypeSize.Tiny,
		TextColor3 = Theme.Palette.TextFaint,
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextTransparency = 0.2,
	})
	return l
end

function UIKit.MakeScreen(withBackground)
	local screen = Instance.new("ScreenGui")
	screen.Name = "LOOPlab"
	screen.ResetOnSpawn = false
	screen.IgnoreGuiInset = true
	screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	if withBackground then
		local bg = UIKit.Frame({
			Parent = screen,
			Size = UDim2.fromScale(1, 1),
		})
		bg.BackgroundColor3 = Theme.Palette.Background
		bg.BorderSizePixel = 0
		local grad = UIKit.Gradient(Theme.Palette.Background, Theme.Palette.BackgroundAlt, 90)
		grad.Parent = bg
	end
	return screen
end

function UIKit.FadeIn(inst, duration)
	if UIKit.ReducedMotion then
		inst.BackgroundTransparency = 0
		return nil
	end
	inst.BackgroundTransparency = 1
	local t = UIKit.Tween(inst, { BackgroundTransparency = 0 }, duration or Theme.Motion.Normal)
	t:Play()
	return t
end

function UIKit.SlideIn(inst, fromX: number, duration)
	fromX = fromX or 0.05
	if UIKit.ReducedMotion then
		return
	end
	local ogPos = inst.Position
	inst.Position = UDim2.new(inst.Position.X.Scale + fromX, inst.Position.X.Offset, inst.Position.Y.Scale, inst.Position.Y.Offset)
	local t = UIKit.Tween(inst, { Position = ogPos }, duration or Theme.Motion.Normal, Enum.EasingStyle.Quint)
	t:Play()
	return t
end

function UIKit.SlideUpIn(inst, fromY: number, duration)
	fromY = fromY or 0.04
	if UIKit.ReducedMotion then
		return
	end
	local ogPos = inst.Position
	inst.Position = UDim2.new(inst.Position.X.Scale, inst.Position.X.Offset, inst.Position.Y.Scale + fromY, inst.Position.Y.Offset)
	local t = UIKit.Tween(inst, { Position = ogPos }, duration or Theme.Motion.Normal, Enum.EasingStyle.Quint)
	t:Play()
	return t
end

function UIKit.Fade(content, duration)
	duration = dur(duration or Theme.Motion.Normal)
	if content:IsA("GuiObject") then
		content.BackgroundTransparency = 1
		local children = content:GetDescendants()
		for _, c in children do
			if c:IsA("TextLabel") or c:IsA("TextButton") then
				c.TextTransparency = 1
			end
		end
		local t = TweenService:Create(content, TweenInfo.new(duration, Theme.MotionEase, Enum.EasingDirection.Out), { BackgroundTransparency = 0 })
		t:Play()
	end
end

function UIKit.SpawnFx(parent, kind, payload)
	local EffectsService = require(script.Parent.EffectsService)
	if kind == "LevelUp" then
		EffectsService.LevelUp(payload)
	elseif kind == "Badge" then
		EffectsService.BadgeReveal(payload and payload.Badge or nil)
	elseif kind == "Title" then
		EffectsService.TitleReveal(payload and payload.Title or nil)
	elseif kind == "MasteryUp" then
		EffectsService.MasteryUp(payload and payload.Rank or nil)
	elseif kind == "PersonalBest" then
		EffectsService.PersonalBest(payload and payload.Score or 0)
	end
end

function UIKit.Destroy(inst)
	if inst and inst.Parent then
		inst:Destroy()
	end
end

return UIKit
