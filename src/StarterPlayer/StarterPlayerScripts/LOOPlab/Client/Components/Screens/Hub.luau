-- Hub: LOOPLAB — premium experimental lab hub.
-- Full-screen immersive with layered surfaces, premium typography,
-- strong Survival flagship, refined activity cards, top-level progress.

local UIKit = require(script.Parent.Parent.UIKit)
local Theme = require(script.Parent.Parent.Theme)
local AudioService = require(script.Parent.Parent.AudioService)

local Hub = {
	Name = "Hub",
	Root = nil,
	Store = {},
	OnAction = nil,
}

local ACTIVITY_INFO = {
	chaos_run = { name = "CHAOS RUN", desc = "Race through checkpoints.", accent = Theme.Brand.Primary, icon = "➤", motif = "Speed / Motion" },
	dodge_lab = { name = "DODGE LAB", desc = "Dodge falling hazards.", accent = Theme.Brand.Danger, icon = "✦", motif = "Reaction / Danger" },
	build_blitz = { name = "BUILD BLITZ", desc = "Stack blocks fast.", accent = Theme.Brand.Warning, icon = "▬", motif = "Create / Build" },
	sequence_sprint = { name = "SEQUENCE SPRINT", desc = "Memorize and repeat.", accent = Theme.Brand.Secondary, icon = "⧗", motif = "Pattern / Memory" },
	survival = { name = "SURVIVAL", desc = "4 rounds · 10 players · last standing wins", accent = Theme.Accent("survival"), icon = "★", motif = "Tournament" },
}

function Hub:Hide()
	if self.Root then self.Root.Visible = false end
end

function Hub:Show()
	if not self.Root then return end
	self.Root.Visible = true
end

function Hub:Build(parent)
	local root = UIKit.Frame({ Parent = parent, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 })
	self.Root = root

	-- Background layer: dark lab atmosphere with subtle gradient (no pure black)
	local bg = UIKit.Frame({ Parent = root, Size = UDim2.fromScale(1, 1), BackgroundColor3 = Theme.Palette.Background, BorderSizePixel = 0 })
	local bgGrad = Instance.new("UIGradient")
	bgGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Theme.Palette.Background),
		ColorSequenceKeypoint.new(0.35, Theme.WithAlpha(Theme.Brand.Secondary, 0.20)),
		ColorSequenceKeypoint.new(0.7, Theme.WithAlpha(Theme.Brand.Primary, 0.10)),
		ColorSequenceKeypoint.new(1, Theme.Palette.Background),
	})
	bgGrad.Rotation = 90
	bgGrad.Parent = bg

	-- Subtle top atmospheric glow line
	local glow = UIKit.Frame({ Parent = root, Size = UDim2.new(1, 0, 0, 4), BackgroundColor3 = Color3.fromRGB(70, 175, 255), BackgroundTransparency = 0.6 })
	glow.BorderSizePixel = 0

	-- Premium header bar (not a flat rectangle — translucent with glow edge)
	local header = UIKit.Frame({ Parent = root, Size = UDim2.new(1, -40, 0, 72), Position = UDim2.new(0.5, 0, 0.02, 0), AnchorPoint = Vector2.new(0.5, 0), BackgroundColor3 = Theme.Palette.PanelAlt, BackgroundTransparency = Theme.Opacity.Soft })
	UIKit.Corner(Theme.Radius.Large).Parent = header
	UIKit.Stroke(Theme.Palette.StrokeDim, 1, Theme.Opacity.Subtle).Parent = header

	-- LOOPLAB brand — large display font, centered in header area
	local brand = UIKit.Title(header, "LOOPLAB", UDim2.new(0.6, 0, 0, 36), Theme.Brand.Gold)
	brand.AnchorPoint = Vector2.new(0.5, 0.5)
	brand.Position = UDim2.new(0.5, 0, 0.5, 0)
	brand.TextScaled = false
	brand.TextSize = Theme.TypeSize.Hero
	brand.Font = Theme.Type.Display

	-- Subtitle / tagline below brand
	local tagline = UIKit.Muted(header, "TEST YOURSELF  ·  SURVIVE THE LAB", UDim2.new(0.7, 0, 0, 14), Theme.Palette.TextDim)
	tagline.AnchorPoint = Vector2.new(0.5, 1)
	tagline.Position = UDim2.new(0.5, 0, 0.9, 0)
	tagline.TextScaled = false
	tagline.TextSize = Theme.TypeSize.Tiny
	tagline.TextXAlignment = Enum.TextXAlignment.Center

	-- Player status strip — compact, floating, not a flat block
	local statusStrip = UIKit.Frame({ Parent = root, Size = UDim2.new(1, -60, 0, 50), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.08, 0) })
	statusStrip.BackgroundTransparency = 1

	-- Avatar + name (left)
	local avatarRing = UIKit.Frame({ Parent = statusStrip, Size = UDim2.fromOffset(44, 44), BackgroundColor3 = Theme.Palette.PanelAlt, BorderSizePixel = 0 })
	avatarRing.Position = UDim2.new(0, 0, 0, 2)
	avatarRing.AnchorPoint = Vector2.new(0, 0)
	UIKit.Corner(Theme.Radius.Pill).Parent = avatarRing
	UIKit.Stroke(Theme.MasteryColor("gold"), 1, Theme.Opacity.Subtle).Parent = avatarRing
	self.Store.AvatarRing = avatarRing

	local nameLabel = UIKit.Muted(statusStrip, "Player", UDim2.new(0.25, 0, 0, 22), Theme.Palette.Text)
	nameLabel.AnchorPoint = Vector2.new(0, 0)
	nameLabel.Position = UDim2.new(0.08, 54, 0.08, 0)
	nameLabel.TextScaled = false
	nameLabel.TextSize = Theme.TypeSize.Tiny

	-- Level badge
	local lvlBadge = UIKit.Frame({ Parent = statusStrip, Size = UDim2.fromOffset(48, 28), BackgroundColor3 = Theme.Brand.Gold, BorderSizePixel = 0 })
	lvlBadge.Position = UDim2.new(0.36, 0, 0.02, 0)
	UIKit.Corner(Theme.Radius.Pill).Parent = lvlBadge
	local lvl = UIKit.Title(lvlBadge, "1", UDim2.fromScale(1, 1), Theme.Palette.Background)
	lvl.TextScaled = false
	lvl.TextSize = Theme.TypeSize.Small
	lvl.TextXAlignment = Enum.TextXAlignment.Center
	lvl.AnchorPoint = Vector2.new(0.5, 0.5)
	lvl.Position = UDim2.fromScale(0.5, 0.5)
	self.Store.LevelBadge = lvl

	-- XP bar (small, premium)
	local xpWrap = UIKit.Frame({ Parent = statusStrip, Size = UDim2.new(0.3, 0, 0, 8), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0.66, 0, 0.5, 0) })
	xpWrap.BackgroundTransparency = 1
	local xpBg = UIKit.Frame({ Parent = xpWrap, Size = UDim2.fromScale(1, 1), BackgroundColor3 = Theme.Palette.Panel })
	UIKit.Corner(Theme.Radius.Pill).Parent = xpBg
	local xpFill = UIKit.Frame({ Parent = xpBg, Size = UDim2.new(0.3, 0, 1, 0), BackgroundColor3 = Theme.Brand.Primary })
	UIKit.Corner(Theme.Radius.Pill).Parent = xpFill
	self.Store.XpFill = xpFill

	-- Coins / Mastery (compact, right side)
	local coinChip = UIKit.Frame({ Parent = statusStrip, Size = UDim2.fromOffset(70, 28), BackgroundColor3 = Color3.fromRGB(30, 28, 50), BorderSizePixel = 0 })
	coinChip.Position = UDim2.new(0.92, 0, 0.02, 0)
	coinChip.AnchorPoint = Vector2.new(1, 0)
	UIKit.Corner(Theme.Radius.Pill).Parent = coinChip
	UIKit.Stroke(Theme.Brand.Gold, 0.5, Theme.Opacity.Subtle).Parent = coinChip
	local coinIcon = UIKit.Text(coinChip, "◉", UDim2.new(0.25, 0, 1, 0), Theme.Brand.Gold)
	coinIcon.TextScaled = false
	coinIcon.TextSize = Theme.TypeSize.Small
	coinIcon.AnchorPoint = Vector2.new(0, 0.5)
	coinIcon.Position = UDim2.new(0, 4, 0.5, 0)
	local coinVal = UIKit.Title(coinChip, "0", UDim2.new(0.7, 0, 1, 0), Theme.Brand.Gold)
	coinVal.TextScaled = false
	coinVal.TextSize = Theme.TypeSize.Small
	coinVal.AnchorPoint = Vector2.new(0, 0.5)
	coinVal.Position = UDim2.new(0.28, 0, 0.5, 0)
	self.Store.Coins = coinVal

	-- Survival Hero Card — larger, stronger, distinctive
	local survWrap = UIKit.Frame({ Parent = root, Size = UDim2.new(1, -40, 0, 180), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.14, 0) })
	survWrap.BackgroundTransparency = 1

	local survCard = UIKit.Frame({ Parent = survWrap, Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(14, 16, 28), BorderSizePixel = 0 })
	UIKit.Corner(Theme.Radius.Large).Parent = survCard

	-- Gradient overlay inside card for depth
	local survGrad = Instance.new("UIGradient")
	survGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 60, 120)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(60, 20, 80)),
		ColorSequenceKeypoint.new(1, Theme.Palette.Background),
	})
	survGrad.Rotation = 135
	survGrad.Parent = survCard

	local survEdge = UIKit.Frame({ Parent = survCard, Size = UDim2.new(1, 0, 0, 3), BackgroundColor3 = Theme.Brand.Accent })
	UIKit.Corner(Theme.Radius.Small).Parent = survEdge

	local survIconArea = UIKit.Frame({ Parent = survCard, Size = UDim2.fromOffset(64, 64), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0.04, 0, 0.5, 0) })
	survIconArea.BackgroundColor3 = Theme.WithAlpha(Theme.Brand.Accent, 0.15)
	UIKit.Corner(Theme.Radius.Large).Parent = survIconArea
	UIKit.Stroke(Theme.Brand.Accent, 1, Theme.Opacity.Subtle).Parent = survIconArea
	local survIcon = UIKit.Text(survIconArea, "★", UDim2.fromScale(0.7, 0.7), Theme.Brand.Accent)
	survIcon.AnchorPoint = Vector2.new(0.5, 0.5)
	survIcon.Position = UDim2.fromScale(0.5, 0.5)
	survIcon.TextScaled = false
	survIcon.TextSize = 36

	local survTitle = UIKit.Title(survCard, "SURVIVAL", UDim2.new(0.5, 0, 0, 36), Color3.fromRGB(255, 240, 250))
	survTitle.AnchorPoint = Vector2.new(0, 0.5)
	survTitle.Position = UDim2.new(0.12, 0, 0.36, 0)
	survTitle.TextScaled = false
	survTitle.TextSize = Theme.TypeSize.Huge
	survTitle.TextXAlignment = Enum.TextXAlignment.Left

	local survSub = UIKit.Muted(survCard, "4 ROUNDS · 10 PLAYERS · LAST ONE STANDING", UDim2.new(0.5, 0, 0, 18), Theme.Palette.Text)
	survSub.AnchorPoint = Vector2.new(0, 0.5)
	survSub.Position = UDim2.new(0.12, 0, 0.58, 0)
	survSub.TextScaled = false
	survSub.TextSize = Theme.TypeSize.Small
	survSub.TextXAlignment = Enum.TextXAlignment.Left

	local survBest = UIKit.Muted(survCard, "WINS: —", UDim2.new(0.35, 0, 0, 18), Theme.Brand.Gold)
	survBest.AnchorPoint = Vector2.new(0, 0.5)
	survBest.Position = UDim2.new(0.12, 0, 0.78, 0)
	survBest.TextScaled = false
	survBest.TextSize = Theme.TypeSize.Small
	survBest.TextXAlignment = Enum.TextXAlignment.Left
	self.Store.SurvBest = survBest

	local survBtn = UIKit.GradientButton(survCard, "JOIN LOBBY", UDim2.new(0.28, 0, 0, 36), Theme.Brand.Accent, { rotation = 0 })
	survBtn.AnchorPoint = Vector2.new(1, 0.5)
	survBtn.Position = UDim2.new(0.98, 0, 0.78, 0)
	survBtn.TextScaled = false
	survBtn.TextSize = Theme.TypeSize.Body
	survBtn.Activated:Connect(function()
		AudioService.PlayClick()
		if Hub.OnAction then Hub.OnAction("Play", { id = "survival", name = "Survival" }) end
	end)

	-- Four game cards in a clean row with spacing
	local cardsWrap = UIKit.Frame({ Parent = root, Size = UDim2.new(1, -40, 0, 110), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.42, 0) })
	cardsWrap.BackgroundTransparency = 1

	local cardLayout = Instance.new("UIGridLayout")
	cardLayout.CellSize = UDim2.new(0.23, 0, 1, 0)
	cardLayout.CellPadding = UDim2.new(0.015, 0, 0, 0)
	cardLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	cardLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	cardLayout.SortOrder = Enum.SortOrder.LayoutOrder
	cardLayout.Parent = cardsWrap

	local activityData = {
		{ id = "chaos_run", name = "CHAOS RUN", desc = "Sprint checkpoints", accent = Theme.Brand.Primary, icon = "➤" },
		{ id = "dodge_lab", name = "DODGE LAB", desc = "Dodge hazards", accent = Theme.Brand.Danger, icon = "✦" },
		{ id = "build_blitz", name = "BUILD BLITZ", desc = "Stack fast", accent = Theme.Brand.Warning, icon = "▬" },
		{ id = "sequence_sprint", name = "SEQ. SPRINT", desc = "Memory", accent = Theme.Brand.Secondary, icon = "⧗" },
	}

	for order, a in activityData do
		local card = UIKit.Frame({ Parent = cardsWrap, BackgroundColor3 = Theme.Palette.Panel })
		UIKit.Corner(Theme.Radius.Medium).Parent = card
		card.BorderSizePixel = 0
		card.BackgroundTransparency = Theme.Opacity.Card

		-- Accent top bar (thin shimmer)
		local bar = UIKit.Frame({ Parent = card, Size = UDim2.new(1, 0, 0, 3), BackgroundColor3 = a.accent })
		UIKit.Corner(Theme.Radius.Small).Parent = bar

		-- Large icon
		local iconWrap = UIKit.Frame({ Parent = card, Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1 })
		iconWrap.Position = UDim2.new(0, 0, 0, 6)
		local icon = UIKit.Text(iconWrap, a.icon, UDim2.fromScale(0.9, 1), a.accent)
		icon.TextScaled = true
		icon.TextSize = Theme.TypeSize.Hero
		icon.TextXAlignment = Enum.TextXAlignment.Center
		icon.AnchorPoint = Vector2.new(0.5, 0)
		icon.Position = UDim2.fromScale(0.5, 0)

		-- Title (bold uppercase)
		local title = UIKit.Title(card, a.name, UDim2.new(1, -10, 0, 22), Theme.Palette.Text)
		title.Position = UDim2.new(0, 8, 0.38, 0)
		title.TextScaled = false
		title.TextSize = Theme.TypeSize.Header
		title.TextXAlignment = Enum.TextXAlignment.Center

		-- Subtitle
		local sub = UIKit.Muted(card, a.desc, UDim2.new(1, -10, 0, 14), Theme.Palette.TextDim)
		sub.Position = UDim2.new(0, 8, 0.6, 0)
		sub.TextScaled = false
		sub.TextSize = Theme.TypeSize.Tiny
		sub.TextXAlignment = Enum.TextXAlignment.Center

		-- Best score (compact)
		local best = UIKit.Muted(card, "BEST: —", UDim2.new(1, -10, 0, 14), Theme.Palette.TextFaint)
		best.Position = UDim2.new(0, 8, 0.72, 0)
		best.TextScaled = false
		best.TextSize = Theme.TypeSize.Tiny
		best.TextXAlignment = Enum.TextXAlignment.Center
		self.Store.Cards[a.id] = best

		-- Play button
		local btn = UIKit.Button(card, "PLAY", UDim2.new(0.8, 0, 0, 28), a.accent, { textColor = Color3.new(1, 1, 1) })
		btn.AnchorPoint = Vector2.new(0.5, 1)
		btn.Position = UDim2.new(0.5, 0, 0.94, 0)
		btn.TextScaled = false
		btn.TextSize = Theme.TypeSize.Small
		btn.Activated:Connect(function()
			AudioService.PlayClick()
			if Hub.OnAction then Hub.OnAction("Play", { id = a.id, name = a.name }) end
		end)
	end

	-- Bottom nav bar (clean minimal)
	local navWrap = UIKit.Frame({ Parent = root, Size = UDim2.new(1, -40, 0, 36), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.98, 0) })
	navWrap.BackgroundTransparency = 1

	local navs = {
		{ id = "Leaderboards", icon = "↺", label = "LEADERBOARDS" },
		{ id = "Profile", icon = "◉", label = "PROFILE" },
		{ id = "Cosmetics", icon = "◈", label = "COSMETICS" },
		{ id = "Settings", icon = "⚙", label = "SETTINGS" },
	}
	local navLayout = Instance.new("UIListLayout")
	navLayout.Padding = UDim.new(0, 8)
	navLayout.FillDirection = Enum.FillDirection.Horizontal
	navLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	navLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	navLayout.SortOrder = Enum.SortOrder.LayoutOrder
	navLayout.Parent = navWrap

	for i, n in navs do
		local b = UIKit.Button(navWrap, n.icon .. "  " .. n.label, UDim2.new(0.22, 0, 1, 0), Theme.Palette.PanelAlt, { textColor = Theme.Palette.Text })
		b.LayoutOrder = i
		b.TextScaled = false
		b.TextSize = Theme.TypeSize.Tiny
		b.Activated:Connect(function()
			AudioService.PlayClick()
			if Hub.OnAction then Hub.OnAction(n.id) end
		end)
	end
end

function Hub:SetProgression(level, xp, xpNext, coins)
	if not self.Store then return end
	if self.Store.LevelBadge then
		self.Store.LevelBadge.Text = tostring(level or 1)
	end
	if self.Store.Coins then
		self.Store.Coins.Text = tostring(coins or 0)
	end
	if self.Store.XpFill and xpNext and xpNext > 0 then
		self.Store.XpFill.Size = UDim2.new(math.clamp((xp or 0) / xpNext, 0, 1), 0, 1, 0)
	end
	return ("L%d XP%d/%d C%d"):format(level or 1, xp or 0, xpNext or 0, coins or 0)
end

function Hub:SetMastery(rank)
	if self.Store and rank then
		-- Mastery can be shown via status label or future enhancement
	end
end

function Hub:SetRecords(records)
	if not self.Store then return end
	records = records or {}
	for id, best in pairs(self.Store.Cards or {}) do
		local val = records[id]
		if val then
			best.Text = ("BEST %d"):format(val)
		end
	end
	if self.Store.SurvBest and records["survival"] then
		self.Store.SurvBest.Text = ("WINS: %d"):format(records["survival"])
	end
end

return Hub
