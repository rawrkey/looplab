-- Theme: LOOPLAB visual identity — brand palette, typography, spacing, motion tokens.
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
	Background = Color3.fromRGB(13, 15, 26),
	BackgroundAlt = Color3.fromRGB(22, 26, 42),
	Panel = Color3.fromRGB(30, 34, 54),
	PanelAlt = Color3.fromRGB(41, 46, 72),
	Stroke = Color3.fromRGB(255, 255, 255),
	StrokeDim = Color3.fromRGB(140, 150, 190),
	Text = Color3.fromRGB(240, 243, 255),
	TextDim = Color3.fromRGB(150, 158, 190),
	TextFaint = Color3.fromRGB(96, 104, 136),
	Scrim = Color3.fromRGB(0, 0, 0),
}

Theme.Type = {
	Title = Enum.Font.GothamBlack,
	Header = Enum.Font.GothamBold,
	Body = Enum.Font.Gotham,
	Mono = Enum.Font.Code,
}

Theme.TypeSize = {
	Hero = 48,
	Huge = 34,
	Title = 26,
	Header = 20,
	Body = 16,
	Small = 13,
	Tiny = 11,
}

Theme.Radius = {
	Small = UDim.new(0, 8),
	Medium = UDim.new(0, 14),
	Large = UDim.new(0, 20),
	Pill = UDim.new(1, 0),
}

Theme.Spacing = { 4, 8, 12, 16, 24, 32, 48 }

Theme.Motion = {
	Instant = 0.05,
	Fast = 0.12,
	Quick = 0.2,
	Normal = 0.32,
	Slow = 0.55,
}

Theme.MotionEaseIn = Enum.EasingStyle.Quad
Theme.MotionEaseOut = Enum.EasingStyle.Quad
Theme.MotionEase = Enum.EasingStyle.Quart

-- Per-activity accent for unique-but-on-brand identity.
Theme.ActivityAccents = {
	chaos_run = Color3.fromRGB(76, 175, 255),
	dodge_lab = Color3.fromRGB(255, 90, 90),
	build_blitz = Color3.fromRGB(255, 200, 60),
	sequence_sprint = Color3.fromRGB(124, 92, 255),
	survival = Color3.fromRGB(255, 76, 152),
}

function Theme.Accent(id: string): Color3
	return Theme.ActivityAccents[id] or Theme.Brand.Primary
end

function Theme.WithAlpha(color: Color3, alpha: number): Color3
	return Color3.fromRGB(
		math.floor(color.R * 255 * alpha + 13 * (1 - alpha)),
		math.floor(color.G * 255 * alpha + 15 * (1 - alpha)),
		math.floor(color.B * 255 * alpha + 26 * (1 - alpha))
	)
end

return Theme