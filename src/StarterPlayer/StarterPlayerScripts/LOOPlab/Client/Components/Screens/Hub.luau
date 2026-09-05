-- Hub: LOOPLAB command center. Survival flagship, four activity cards, progression.
-- Reads the user's level, mastery, coins, and per-game records.

local UIKit = require(script.Parent.Parent.UIKit)
local Theme = require(script.Parent.Parent.Theme)
local AudioService = require(script.Parent.Parent.AudioService)

local Hub = {
	Name = "Hub",
	Root = nil,
	Store = {},
	OnAction = nil,
}

local ACTIVITIES = {
	{ id = "chaos_run", name = "Chaos Run", desc = "Checkpoint sprint", accent = Theme.Brand.Primary, icon = "➤" },
	{ id = "dodge_lab", name = "Dodge Lab", desc = "Dodge the rain", accent = Theme.Brand.Danger, icon = "✦" },
	{ id = "build_blitz", name = "Build Blitz", desc = "Rapid stacking", accent = Theme.Brand.Warning, icon = "▬" },
	{ id = "sequence_sprint", name = "Sequence Sprint", desc = "Memory repeat", accent = Theme.Brand.Secondary, icon = "⧗" },
}

function Hub:Hide()
	if self.Root then self.Root.Visible = false end
end

function Hub:Show()
	if not self.Root then return end
	self.Root.Visible = true
	if self.Panel then
		UIKit.SlideUpIn(self.Panel, 0.04, Theme.Motion.Normal)
	end
end

function Hub:Build(parent)
	local root = UIKit.Frame({
		Parent = parent,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	})
	self.Root = root

	local bg = UIKit.Frame({ Parent = root, Size = UDim2.fromScale(1, 1) })
	bg.BackgroundColor3 = Theme.Palette.Background
	bg.BorderSizePixel = 0

	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Theme.Palette.Background),
		ColorSequenceKeypoint.new(0.45, Theme.WithAlpha(Theme.Brand.Secondary, 0.12)),
		ColorSequenceKeypoint.new(1, Theme.Palette.Background),
	})
	gradient.Rotation = 90
	gradient.Parent = bg

	-- Central panel that scales with screen
	local panel = UIKit.Frame({
		Parent = root,
		Size = UDim2.new(0.66, 0, 0.94, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		BackgroundColor3 = Theme.Palette.PanelAlt,
		BackgroundTransparency = Theme.Opacity.Card,
	})
	UIKit.Corner(Theme.Radius.Large).Parent = panel
	UIKit.Stroke(Theme.Palette.StrokeDim, 1, Theme.Opacity.Subtle).Parent = panel
	self.Panel = panel

	-- Use a vertical list layout inside the panel
	local list = Instance.new("UIListLayout")
	list.Padding = UDim.new(0, 12)
	list.FillDirection = Enum.FillDirection.Vertical
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = panel

	local pad = UIKit.Padding(0, 0, 0, 0)
	-- padding won't help; we just use fixed-size children for now

	-- Brand row
	local brand = UIKit.Frame({ Parent = panel, Size = UDim2.new(1, -32, 0, 48) })
	brand.BackgroundTransparency = 1
	brand.LayoutOrder = 1

	local brandTitle = UIKit.Title(brand, "LOOPLAB", UDim2.new(0, 280, 0, 44), Theme.Brand.Primary)
	brandTitle.AnchorPoint = Vector2.new(0, 0.5)
	brandTitle.Position = UDim2.new(0, 0, 0.5, 0)
	brandTitle.Font = Theme.Type.Display
	brandTitle.TextSize = 36

	local dot = UIKit.Frame({ Parent = brand, Size = UDim2.fromOffset(8, 8), BackgroundColor3 = Theme.Brand.Accent })
	UIKit.Corner(Theme.Radius.Pill).Parent = dot
	dot.AnchorPoint = Vector2.new(0, 0.5)
	dot.Position = UDim2.new(0, 192, 0.5, 0)

	local tagline = UIKit.Muted(brand, "Test yourself. Survive the Lab.", UDim2.new(0, 320, 0, 22), Theme.Palette.TextDim)
	tagline.AnchorPoint = Vector2.new(0, 0.5)
	tagline.Position = UDim2.new(0, 212, 0.5, 0)
	tagline.TextScaled = false
	tagline.TextSize = Theme.TypeSize.Small

	-- Level / Mastery / Coins strip
	local strip = UIKit.Card(panel, UDim2.new(1, -32, 0, 80), Theme.Palette.StrokeDim)
	strip.BackgroundTransparency = Theme.Opacity.Card
	strip.LayoutOrder = 2

	local lvlLabel = UIKit.Muted(strip, "LEVEL", UDim2.new(0.32, 0, 0, 16), Theme.Palette.TextFaint)
	lvlLabel.AnchorPoint = Vector2.new(0, 0)
	lvlLabel.Position = UDim2.new(0.02, 0, 0.18, 0)
	lvlLabel.TextScaled = false
	lvlLabel.TextSize = Theme.TypeSize.Tiny
	lvlLabel.TextXAlignment = Enum.TextXAlignment.Left

	local lvlVal = UIKit.Title(strip, "1", UDim2.new(0.32, 0, 0, 36), Theme.Brand.Gold)
	lvlVal.AnchorPoint = Vector2.new(0, 0)
	lvlVal.Position = UDim2.new(0.02, 0, 0.42, 0)
	lvlVal.TextScaled = false
	lvlVal.TextSize = Theme.TypeSize.Huge
	lvlVal.TextXAlignment = Enum.TextXAlignment.Left
	self.Store.Level = lvlVal

	local masteryLabel = UIKit.Muted(strip, "MASTERY", UDim2.new(0.36, 0, 0, 16), Theme.Palette.TextFaint)
	masteryLabel.AnchorPoint = Vector2.new(0.5, 0)
	masteryLabel.Position = UDim2.new(0.5, 0, 0.18, 0)
	masteryLabel.TextScaled = false
	masteryLabel.TextSize = Theme.TypeSize.Tiny
	masteryLabel.TextXAlignment = Enum.TextXAlignment.Center

	local masteryVal = UIKit.Title(strip, "BRONZE", UDim2.new(0.36, 0, 0, 32), Theme.MasteryColor("bronze"))
	masteryVal.AnchorPoint = Vector2.new(0.5, 0)
	masteryVal.Position = UDim2.new(0.5, 0, 0.42, 0)
	masteryVal.TextScaled = false
	masteryVal.TextSize = Theme.TypeSize.Title
	masteryVal.TextXAlignment = Enum.TextXAlignment.Center
	self.Store.Mastery = masteryVal

	local coinLabel = UIKit.Muted(strip, "COINS", UDim2.new(0.3, 0, 0, 16), Theme.Palette.TextFaint)
	coinLabel.AnchorPoint = Vector2.new(1, 0)
	coinLabel.Position = UDim2.new(0.98, 0, 0.18, 0)
	coinLabel.TextScaled = false
	coinLabel.TextSize = Theme.TypeSize.Tiny
	coinLabel.TextXAlignment = Enum.TextXAlignment.Right

	local coinVal = UIKit.Title(strip, "0", UDim2.new(0.3, 0, 0, 36), Theme.Brand.Gold)
	coinVal.AnchorPoint = Vector2.new(1, 0)
	coinVal.Position = UDim2.new(0.98, 0, 0.42, 0)
	coinVal.TextScaled = false
	coinVal.TextSize = Theme.TypeSize.Huge
	coinVal.TextXAlignment = Enum.TextXAlignment.Right
	self.Store.Coins = coinVal

	-- XP bar
	local xpBg = UIKit.Frame({ Parent = panel, Size = UDim2.new(1, -64, 0, 10), BackgroundColor3 = Theme.Palette.Panel })
	UIKit.Corner(Theme.Radius.Pill).Parent = xpBg
	xpBg.LayoutOrder = 3
	xpBg.BorderSizePixel = 0
	local xpFill = UIKit.Frame({ Parent = xpBg, Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = Theme.Brand.Primary })
	UIKit.Corner(Theme.Radius.Pill).Parent = xpFill
	self.Store.XpBar = xpFill

	-- Survival flagship card
	local survWrap = UIKit.Frame({ Parent = panel, Size = UDim2.new(1, -32, 0, 156) })
	survWrap.BackgroundTransparency = 1
	survWrap.LayoutOrder = 4
	self:BuildSurvivalCard(survWrap)

	-- Activity grid (2x2)
	local grid = UIKit.Frame({ Parent = panel, Size = UDim2.new(1, -32, 0, 200) })
	grid.BackgroundTransparency = 1
	grid.LayoutOrder = 5
	self.Store.Cards = {}
	self.Store.CardAccents = {}

	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.CellSize = UDim2.new(0.485, 0, 0.48, 0)
	gridLayout.CellPadding = UDim2.new(0.03, 0, 0.04, 0)
	gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	gridLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	gridLayout.FillDirection = Enum.FillDirection.Horizontal
	gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	gridLayout.Parent = grid

	for order, cfg in ACTIVITIES do
		cfg.order = order
		self:BuildActivityCard(grid, cfg)
	end

	-- Nav bar
	local nav = UIKit.Frame({ Parent = panel, Size = UDim2.new(1, -32, 0, 38) })
	nav.BackgroundTransparency = 1
	nav.LayoutOrder = 6
	self:BuildNavBar(nav)
end

function Hub:BuildSurvivalCard(parent)
	local card = UIKit.Frame({ Parent = parent, Size = UDim2.fromScale(1, 1), BackgroundColor3 = Theme.Palette.Panel })
	UIKit.Corner(Theme.Radius.Large).Parent = card
	UIKit.Stroke(Theme.Accent("survival"), 1, Theme.Opacity.Subtle).Parent = card
	card.BorderSizePixel = 0

	local grad = UIKit.Gradient(Theme.WithAlpha(Theme.Accent("survival"), 0.18), Theme.WithAlpha(Theme.Brand.Secondary, 0.04), 0)
	grad.Parent = card

	local accent = UIKit.Frame({ Parent = card, Size = UDim2.new(1, 0, 0, 4), AnchorPoint = Vector2.new(0, 0), BackgroundColor3 = Theme.Accent("survival") })
	accent.BorderSizePixel = 0
	UIKit.Corner(Theme.Radius.Small).Parent = accent

	local flagRow = UIKit.Frame({ Parent = card, Size = UDim2.new(0.5, 0, 0, 24), AnchorPoint = Vector2.new(0, 0), Position = UDim2.new(0.04, 0, 0.08, 0) })
	flagRow.BackgroundTransparency = 1
	local flag = UIKit.Chip(flagRow, "★ FLAGSHIP", Theme.WithAlpha(Theme.Accent("survival"), 0.18), { textColor = Color3.fromRGB(255, 220, 230) })
	flag.AutoButtonColor = false
	flag.Size = UDim2.new(0, 110, 0, 22)
	flag.AnchorPoint = Vector2.new(0, 0.5)
	flag.Position = UDim2.new(0, 0, 0.5, 0)

	local title = UIKit.Title(card, "SURVIVAL", UDim2.new(0.6, 0, 0, 36), Color3.new(1, 1, 1))
	title.AnchorPoint = Vector2.new(0, 0)
	title.Position = UDim2.new(0.04, 0, 0.28, 0)
	title.TextScaled = false
	title.TextSize = 30
	title.TextXAlignment = Enum.TextXAlignment.Left

	local sub = UIKit.Muted(card, "4 games · 10 players · last one standing", UDim2.new(0.6, 0, 0, 20), Theme.Palette.Text)
	sub.AnchorPoint = Vector2.new(0, 0)
	sub.Position = UDim2.new(0.04, 0, 0.5, 0)
	sub.TextScaled = false
	sub.TextSize = Theme.TypeSize.Small
	sub.TextXAlignment = Enum.TextXAlignment.Left

	local best = UIKit.Muted(card, "Wins: —", UDim2.new(0.4, 0, 0, 18), Theme.WithAlpha(Theme.Brand.Gold, 0.9))
	best.AnchorPoint = Vector2.new(0, 0)
	best.Position = UDim2.new(0.04, 0, 0.68, 0)
	best.TextScaled = false
	best.TextSize = Theme.TypeSize.Small
	best.TextXAlignment = Enum.TextXAlignment.Left
	self.Store.SurvBest = best

	local btn = UIKit.GradientButton(card, "JOIN LOBBY", UDim2.new(0.32, 0, 0, 38), Theme.Accent("survival"), { rotation = 0, secondary = Theme.Brand.Primary })
	btn.AnchorPoint = Vector2.new(1, 1)
	btn.Position = UDim2.new(0.97, 0, 0.92, 0)
	btn.TextScaled = false
	btn.TextSize = Theme.TypeSize.Body
	btn.Activated:Connect(function()
		AudioService.PlayClick()
		if Hub.OnAction then Hub.OnAction("Play", { id = "survival", name = "Survival" }) end
	end)
end

function Hub:BuildActivityCard(parent, cfg)
	local card = UIKit.Frame({ Parent = parent, BackgroundColor3 = Theme.Palette.Panel })
	UIKit.Corner(Theme.Radius.Medium).Parent = card
	UIKit.Stroke(cfg.accent, 1, Theme.Opacity.Subtle).Parent = card
	card.BorderSizePixel = 0
	card.BackgroundTransparency = Theme.Opacity.Card

	local accent = UIKit.Frame({ Parent = card, Size = UDim2.new(1, 0, 0, 3), AnchorPoint = Vector2.new(0, 0), BackgroundColor3 = cfg.accent })
	accent.BorderSizePixel = 0
	UIKit.Corner(Theme.Radius.Small).Parent = accent

	local icon = UIKit.Text(card, cfg.icon, UDim2.new(0, 32, 0, 32), cfg.accent)
	icon.AnchorPoint = Vector2.new(0, 0)
	icon.Position = UDim2.new(0, 10, 0.1, 0)
	icon.TextScaled = false
	icon.TextSize = 22

	local name = UIKit.Title(card, cfg.name, UDim2.new(1, -16, 0, 24), Theme.Palette.Text)
	name.AnchorPoint = Vector2.new(0, 0)
	name.Position = UDim2.new(0, 48, 0.12, 0)
	name.TextScaled = false
	name.TextSize = Theme.TypeSize.Header
	name.TextXAlignment = Enum.TextXAlignment.Left

	local desc = UIKit.Muted(card, cfg.desc, UDim2.new(1, -16, 0, 18), Theme.Palette.TextDim)
	desc.AnchorPoint = Vector2.new(0, 0)
	desc.Position = UDim2.new(0, 10, 0.42, 0)
	desc.TextScaled = false
	desc.TextSize = Theme.TypeSize.Tiny
	desc.TextXAlignment = Enum.TextXAlignment.Left

	local best = UIKit.Muted(card, "Best: —", UDim2.new(1, -16, 0, 16), Theme.Palette.TextFaint)
	best.AnchorPoint = Vector2.new(0, 0)
	best.Position = UDim2.new(0, 10, 0.6, 0)
	best.TextScaled = false
	best.TextSize = Theme.TypeSize.Tiny
	best.TextXAlignment = Enum.TextXAlignment.Left
	self.Store.Cards[cfg.id] = best
	self.Store.CardAccents[cfg.id] = cfg.accent

	local btn = UIKit.GradientButton(card, "PLAY", UDim2.new(0.88, 0, 0, 24), cfg.accent, { rotation = 90 })
	btn.AnchorPoint = Vector2.new(0.5, 1)
	btn.Position = UDim2.new(0.5, 0, 0.94, 0)
	btn.TextScaled = false
	btn.TextSize = Theme.TypeSize.Tiny
	btn.Activated:Connect(function()
		AudioService.PlayClick()
		if Hub.OnAction then Hub.OnAction("Play", cfg) end
	end)
end

function Hub:BuildNavBar(parent)
	local list = Instance.new("UIListLayout")
	list.Padding = UDim.new(0, 8)
	list.FillDirection = Enum.FillDirection.Horizontal
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.VerticalAlignment = Enum.VerticalAlignment.Center
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = parent

	local navs = {
		{ id = "Leaderboards", icon = "↺", label = "LEADERBOARDS", color = Theme.Brand.Primary },
		{ id = "Profile", icon = "◉", label = "PROFILE", color = Theme.MasteryColor("gold") },
		{ id = "Cosmetics", icon = "◈", label = "COSMETICS", color = Theme.Brand.Secondary },
		{ id = "Settings", icon = "⚙", label = "SETTINGS", color = Theme.Palette.TextDim },
	}
	for i, nav in navs do
		local btn = UIKit.Button(parent, nav.icon .. "  " .. nav.label, UDim2.new(0.235, 0, 1, 0), Theme.Palette.PanelAlt, { textColor = nav.color })
		btn.LayoutOrder = i
		btn.TextScaled = false
		btn.TextSize = Theme.TypeSize.Small
		btn.Activated:Connect(function()
			AudioService.PlayClick()
			if Hub.OnAction then Hub.OnAction(nav.id) end
		end)
	end
end

function Hub:SetProgression(level, xp, xpNext, coins)
	if not self.Store then return end
	if self.Store.Level then
		self.Store.Level.Text = tostring(level or 1)
	end
	if self.Store.Coins then
		self.Store.Coins.Text = tostring(coins or 0)
	end
	if self.Store.XpBar and xpNext and xpNext > 0 then
		local frac = math.clamp((xp or 0) / xpNext, 0, 1)
		self.Store.XpBar.Size = UDim2.new(frac, 0, 1, 0)
	end
	return ("L%d XP%d/%d C%d"):format(level or 1, xp or 0, xpNext or 0, coins or 0)
end

function Hub:SetMastery(rank)
	if self.Store and self.Store.Mastery and rank then
		self.Store.Mastery.Text = (rank.Display or rank.Name or "BRONZE"):gsub("\n", "")
		self.Store.Mastery.TextColor3 = Theme.MasteryColor(rank.Id or "bronze")
	end
end

function Hub:SetRecords(records)
	if not self.Store then return end
	records = records or {}
	local best = {
		chaos_run = records["chaos_run"],
		dodge_lab = records["dodge_lab"],
		build_blitz = records["build_blitz"],
		sequence_sprint = records["sequence_sprint"],
		survival = records["survival"],
	}
	self.Store.Best = best
	for id, lbl in self.Store.Cards do
		if best[id] then
			lbl.Text = ("Best %d"):format(best[id])
		end
	end
	if self.Store.SurvBest then
		if best.survival then
			self.Store.SurvBest.Text = ("Wins: %d"):format(best.survival)
		else
			self.Store.SurvBest.Text = "Wins: —"
		end
	end
end

return Hub
