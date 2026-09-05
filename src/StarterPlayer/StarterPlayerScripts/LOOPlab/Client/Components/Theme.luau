-- Theme: LOOPLAB visual identity - brand palette, typography, spacing, motion tokens.
-- Single source of truth for the game's look. UI never hard-codes colors.

local Theme = {}

Theme.Brand = {
	Primary = Color3.fromRGB(76, 175, 255),
	Secondary = Color3.fromRGB(124, 92, 255),
	Accent = Color3.fromRGB(255, 76, 152),
	Success = Color3.fromRGB(80, 220, 140),
	Warning = Color3.fromRGB(255, 200, 60),
	Danger = Color3.fromRGB(255, 90, 90),
	Gold = Color3.fromRGB(255, 214, 90),
}

Theme.Palette = {
	Background = Color3.fromRGB(11, 13, 22),
	BackgroundAlt = Color3.fromRGB(20, 23, 38),
	Panel = Color3.fromRGB(28, 32, 50),
	PanelAlt = Color3.fromRGB(40, 45, 70),
	Stroke = Color3.fromRGB(255, 255, 255),
	StrokeDim = Color3.fromRGB(140, 150, 190),
	Text = Color3.fromRGB(240, 243, 255),
	TextDim = Color3.fromRGB(150, 158, 190),
	TextFaint = Color3.fromRGB(96, 104, 136),
	Scrim = Color3.fromRGB(0, 0, 0),
}

Theme.Opacity = {
	Solid = 0,
	Panel = 0.05,
	Glow = 0.15,
	Soft = 0.3,
	Dim = 0.5,
	Scrim = 0.65,
	ScrimDeep = 0.82,
	Card = 0.08,
	CardHover = 0.12,
	CardPressed = 0.04,
}

Theme.Border = {
	Width = 1,
	Subtle = 0.35,
	Std = 0.55,
	Strong = 0.9,
}

Theme.Shadow = {
	Offset = Vector2.new(0, 4),
	Transparency = 0.55,
}

Theme.Type = {
	Title = Enum.Font.GothamBlack,
	Header = Enum.Font.GothamBold,
	Body = Enum.Font.Gotham,
	Mono = Enum.Font.Code,
	Display = Enum.Font.GothamBold,
}

Theme.TypeSize = {
	Display = 64,
	Hero = 44,
	Huge = 32,
	Title = 24,
	Header = 20,
	Body = 15,
	Small = 13,
	Tiny = 11,
	Micro = 9,
}

Theme.Radius = {
	Small = UDim.new(0, 8),
	Medium = UDim.new(0, 14),
	Large = UDim.new(0, 20),
	XLarge = UDim.new(0, 28),
	Pill = UDim.new(1, 0),
}

Theme.Spacing = { 4, 8, 12, 16, 24, 32, 48, 64 }

Theme.Stroke = {
	None = 0,
	Hairline = 1,
	Thin = 2,
	Std = 3,
	Thick = 4,
}

Theme.Motion = {
	Instant = 0.05,
	Fast = 0.12,
	Quick = 0.2,
	Normal = 0.32,
	Slow = 0.55,
	Slower = 0.8,
}

Theme.MotionEaseIn = Enum.EasingStyle.Quad
Theme.MotionEaseOut = Enum.EasingStyle.Quad
Theme.MotionEase = Enum.EasingStyle.Quart
Theme.MotionBounce = Enum.EasingStyle.Back
Theme.MotionSnap = Enum.EasingStyle.Elastic

-- Per-activity accent for unique-but-on-brand identity.
Theme.ActivityAccents = {
	chaos_run = Color3.fromRGB(76, 175, 255),
	dodge_lab = Color3.fromRGB(255, 90, 90),
	build_blitz = Color3.fromRGB(255, 200, 60),
	sequence_sprint = Color3.fromRGB(124, 92, 255),
	survival = Color3.fromRGB(255, 76, 152),
}

Theme.MasteryColors = {
	bronze = Color3.fromRGB(176, 141, 87),
	silver = Color3.fromRGB(196, 204, 216),
	gold = Color3.fromRGB(255, 214, 90),
	platinum = Color3.fromRGB(126, 224, 214),
	diamond = Color3.fromRGB(120, 190, 255),
}

function Theme.Accent(id: string): Color3
	return Theme.ActivityAccents[id] or Theme.Brand.Primary
end

function Theme.MasteryColor(id: string): Color3
	return Theme.MasteryColors[id] or Theme.Brand.Primary
end

function Theme.WithAlpha(color: Color3, alpha: number): Color3
	return Color3.fromRGB(
		math.floor(color.R * 255 * alpha + 11 * (1 - alpha)),
		math.floor(color.G * 255 * alpha + 13 * (1 - alpha)),
		math.floor(color.B * 255 * alpha + 22 * (1 - alpha))
	)
end

function Theme.Lighten(color: Color3, amount: number): Color3
	amount = math.clamp(amount or 0.15, 0, 1)
	return Color3.fromRGB(
		math.min(255, math.floor(color.R * 255 + 255 * amount)),
		math.min(255, math.floor(color.G * 255 + 255 * amount)),
		math.min(255, math.floor(color.B * 255 + 255 * amount))
	)
end

function Theme.Darken(color: Color3, amount: number): Color3
	amount = math.clamp(amount or 0.15, 0, 1)
	return Color3.fromRGB(
		math.floor(color.R * 255 * (1 - amount)),
		math.floor(color.G * 255 * (1 - amount)),
		math.floor(color.B * 255 * (1 - amount))
	)
end

function Theme.Lerp(a: Color3, b: Color3, t: number): Color3
	t = math.clamp(t or 0, 0, 1)
	return Color3.fromRGB(
		math.floor(a.R * 255 + (b.R - a.R) * 255 * t),
		math.floor(a.G * 255 + (b.G - a.G) * 255 * t),
		math.floor(a.B * 255 + (b.B - a.B) * 255 * t)
	)
end

function Theme.PodiumColor(place: number): Color3
	if place == 1 then return Theme.Brand.Gold end
	if place == 2 then return Color3.fromRGB(200, 210, 225) end
	if place == 3 then return Color3.fromRGB(210, 140, 90) end
	return Theme.Palette.TextDim
end

function Theme.IsTouch(): boolean
	local UIS = game:GetService("UserInputService")
	return UIS.TouchEnabled and not UIS.KeyboardEnabled
end

return Theme
