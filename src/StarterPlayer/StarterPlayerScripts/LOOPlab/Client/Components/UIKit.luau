-- UIKit: LOOPLAB visual building blocks. Themed, motion-equipped, reusable.
-- Screens should build on these primitives rather than raw instances.

local TweenService = game:GetService("TweenService")

local Theme = require(script.Parent.Theme)

local UIKit = {}

local function new(className, props)
	local inst = Instance.new(className)
	for k, v in pairs(props or {}) do
		inst[k] = v
	end
	return inst
end

function UIKit.Tween(inst, goal, duration, style, direction)
	style = style or Theme.MotionEase
	direction = direction or Enum.EasingDirection.Out
	duration = duration or Theme.Motion.Quick
	return TweenService:Create(inst, TweenInfo.new(duration, style, direction), goal)
end

function UIKit.PlayPop(inst, scale: number?, duration: number?)
	scale = scale or 1.12
	duration = duration or Theme.Motion.Fast
	local t = UIKit.Tween(inst, { Scale = Vector3.new(scale, scale, scale), Position = inst.Position + UDim2.fromScale(0, -0.02) }, duration, Enum.EasingStyle.Back)
	t:Play()
	return t
end

function UIKit.Frame(props)
	return new("Frame", props)
end

function UIKit.Corner(radius: UDim?)
	return new("UICorner", { CornerRadius = radius or Theme.Radius.Medium })
end

function UIKit.Panel(parent, size, color, radius)
	local f = new("Frame", {
		Parent = parent,
		Size = size,
		BackgroundColor3 = color or Theme.Palette.Panel,
		BorderSizePixel = 0,
	})
	UIKit.Corner(radius or Theme.Radius.Medium).Parent = f
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

function UIKit.Button(parent, text, size, color, opts)
	opts = opts or {}
	local btn = new("TextButton", {
		Parent = parent,
		Size = size,
		Text = text,
		TextScaled = not opts.noScale,
		Font = opts.font or Theme.Type.Header,
		TextColor3 = opts.textColor or Theme.Palette.Text,
		BackgroundColor3 = color or Theme.Brand.Primary,
		BorderSizePixel = 0,
		AutoButtonColor = true,
	})
	UIKit.Corner(Theme.Radius.Pill).Parent = btn
	btn.MouseButton1Click:Connect(function()
		UIKit.PlayPop(btn, 0.94, Theme.Motion.Quick)
	end)
	return btn
end

function UIKit.GradientButton(parent, text, size, accent)
	local btn = UIKit.Button(parent, text, size, accent, { font = Theme.Type.Header })
	local gradient = new("UIGradient", {
		Parent = btn,
		Rotation = 90,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, accent),
			ColorSequenceKeypoint.new(1, Theme.Brand.Secondary),
		}),
	})
	return btn
end

function UIKit.Separator(parent, color)
	return new("Frame", {
		Parent = parent,
		Size = UDim2.new(1, -40, 0, 2),
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 0),
		BackgroundColor3 = color or Theme.Palette.StrokeDim,
		BackgroundTransparency = 0.65,
		BorderSizePixel = 0,
	})
end

function UIKit.MakeScreen(withBackground)
	local screen = Instance.new("ScreenGui")
	screen.Name = "LOOPlab"
	screen.ResetOnSpawn = false
	screen.IgnoreGuiInset = true
	screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	if withBackground then
		UIKit.Panel(screen, UDim2.fromScale(1, 1), Theme.Palette.Background)
	end
	return screen
end

function UIKit.FadeIn(inst, duration)
	inst.BackgroundTransparency = 1
	local t = UIKit.Tween(inst, { BackgroundTransparency = 0 }, duration or Theme.Motion.Normal)
	t:Play()
	return t
end

function UIKit.SlideIn(inst, fromX: number, duration)
	fromX = fromX or 0.05
	local ogPos = inst.Position
	inst.Position = UDim2.new(inst.Position.X.Scale + fromX, inst.Position.X.Offset, inst.Position.Y.Scale, inst.Position.Y.Offset)
	local t = UIKit.Tween(inst, { Position = ogPos }, duration or Theme.Motion.Normal, Enum.EasingStyle.Quint)
	t:Play()
	return t
end

function UIKit.Destroy(inst)
	if inst and inst.Parent then
		inst:Destroy()
	end
end

return UIKit