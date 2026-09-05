-- Hub: LOOPLAB — Premium Competitive Lab Hub
-- Full-screen immersive with floating layered cards over lab environment

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
	{ id = "dodge_lab", name = "Dodge Lab", desc = "Dodge hazards", accent = Theme.Brand.Danger, icon = "✦" },
	{ id = "build_blitz", name = "Build Blitz", desc = "Stack blocks", accent = Theme.Brand.Warning, icon = "▬" },
	{ id = "sequence_sprint", name = "Sequence Sprint", desc = "Memory pattern", accent = Theme.Brand.Secondary, icon = "⧗" },
}

function Hub:Hide()
	if self.Root then self.Root.Visible = false end
end

function Hub:Show()
	if not self.Root then return end
	self.Root.Visible = true
end

function Hub:Build(parent)
	local root = UIKit.Frame({
		Parent = parent,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	})
	self.Root = root

	-- Full-screen dark lab background (not black void — deep navy with warm glow)
	local bg = UIKit.Frame({ Parent = root, Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(10, 12, 28) })
	bg.BorderSizePixel = 0
	local bgGrad = Instance.new("UIGradient")
	bgGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(12, 14, 30)),
		ColorSequenceKeypoint.new(0.4, Color3.fromRGB(20, 24, 40)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 12, 28)),
	})
	bgGrad.Rotation = 30
	bgGrad.Parent = bg

	-- Subtle top glow line (atmospheric)
	local glowLine = UIKit.Frame({ Parent = root, Size = UDim2.new(1, 0, 0, 2), BackgroundColor3 = Theme.Brand.Primary, BackgroundTransparency = 0.7 })
	glowLine.Position = UDim2.new(0, 0, 0, 0)
	glowLine.BorderSizePixel = 0

	-- Top navigation (compact, floating, not giant strip)
	local nav = UIKit.Frame({ Parent = root, Size = UDim2.new(1, -32, 0, 36), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.02, 0) })
	nav.BackgroundTransparency = 1
	local navLayout = Instance.new("UIListLayout")
	navLayout.Padding = UDim.new(0, 10)
	navLayout.FillDirection = Enum.FillDirection.Horizontal
	navLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	navLayout.SortOrder = Enum.SortOrder.LayoutOrder
	navLayout.Parent = nav

	local navItems = {
		{ id = "Profile", icon = "◉", color = Theme.MasteryColor("gold") },
		{ id = "Cosmetics", icon = "◈", color = Theme.Brand.Secondary },
		{ id = "Leaderboards", icon = "↺", color = Theme.Brand.Primary },
		{ id = "Settings", icon = "⚙", color = Theme.Palette.TextDim },
	}
	for i, item in navItems do
		local btn = UIKit.Button(nav, item.icon, UDim2.new(0, 36, 1, 0), Theme.Palette.PanelAlt, { textColor = item.color, noScale = true })
		btn.LayoutOrder = i
		btn.TextScaled = false
		btn.TextSize = Theme.TypeSize.Small
		btn.Activated:Connect(function()
			AudioService.PlayClick()
			if Hub.OnAction then Hub.OnAction(item.id) end
		end)
		self.Store["Nav" .. item.id] = btn
	end

	-- Brand at top-left (not full center — stronger design)
	local brandArea = UIKit.Frame({ Parent = root, Size = UDim2.new(0.5, 0, 0, 70), AnchorPoint = Vector2.new(0, 0), Position = UDim2.new(0.03, 0, 0.06, 0) })
	brandArea.BackgroundTransparency = 1
	local brandName = UIKit.Title(brandArea, "LOOPLAB", UDim2.new(1, 0, 0, 36), Theme.Brand.Gold)
	brandName.AnchorPoint = Vector2.new(0, 0)
	brandName.Position = UDim2.new(0, 0, 0, 0)
	brandName.TextScaled = false
	brandName.TextSize = Theme.TypeSize.Hero
	brandName.Font = Theme.Type.Display
	brandName.TextXAlignment = Enum.TextXAlignment.Left

	local brandSub = UIKit.Muted(brandArea, "TEST · SURVIVE · REPEAT", UDim2.new(1, 0, 0, 14), Theme.Palette.TextDim)
	brandSub.AnchorPoint = Vector2.new(0, 0)
	brandSub.Position = UDim2.new(0, 0, 0.6, 0)
	brandSub.TextScaled = false
	brandSub.TextSize = Theme.TypeSize.Tiny
	brandSub.TextXAlignment = Enum.TextXAlignment.Left

	-- Player status widget — compact, floating near top-left below brand
	local statusPanel = UIKit.Frame({ Parent = root, Size = UDim2.new(0.35, 0, 0, 52), AnchorPoint = Vector2.new(0, 0), Position = UDim2.new(0.03, 0, 0.18, 0) })
	statusPanel.BackgroundColor3 = Theme.WithAlpha(Theme.Palette.PanelAlt, 0.7)
	UIKit.Corner(Theme.Radius.Medium).Parent = statusPanel

	-- Avatar ring
	local avatarRing = UIKit.Frame({ Parent = statusPanel, Size = UDim2.fromOffset(36, 36), BackgroundColor3 = Theme.Palette.Panel })
	avatarRing.Position = UDim2.new(0.06, 0, 0.5, 0)
	avatarRing.AnchorPoint = Vector2.new(0, 0.5)
	UIKit.Corner(Theme.Radius.Pill).Parent = avatarRing
	UIKit.Stroke(Theme.MasteryColor("gold"), 1, Theme.Opacity.Subtle).Parent = avatarRing

	local nameLbl = UIKit.Muted(statusPanel, "Player", UDim2.new(0.55, 0, 0, 20), Theme.Palette.Text)
	nameLbl.AnchorPoint = Vector2.new(0, 0)
	nameLbl.Position = UDim2.new(0.28, 0, 0.08, 0)
	nameLbl.TextScaled = false
	nameLbl.TextSize = Theme.TypeSize.Tiny

	local lvl = UIKit.Title(statusPanel, "1", UDim2.new(0.2, 0, 0, 16), Theme.Brand.Gold)
	lvl.AnchorPoint = Vector2.new(0, 0)
	lvl.Position = UDim2.new(0.28, 0, 0.3, 0)
	lvl.TextScaled = false
	lvl.TextSize = Theme.TypeSize.Small

	local coins = UIKit.Muted(statusPanel, "◉ 0", UDim2.new(0.35, 0, 0, 16), Theme.Brand.Gold)
	coins.AnchorPoint = Vector2.new(0, 0.5)
	coins.Position = UDim2.new(0.78, 0, 0.5, 0)
	coins.TextScaled = false
	coins.TextSize = Theme.TypeSize.Small

	-- XP progress (compact strip under status)
	local xpWrap = UIKit.Frame({ Parent = root, Size = UDim2.new(0.35, 0, 0, 6), AnchorPoint = Vector2.new(0, 0), Position = UDim2.new(0.03, 0, 0.26, 0) })
	xpWrap.BackgroundTransparency = 1
	local xpBg = UIKit.Frame({ Parent = xpWrap, Size = UDim2.fromScale(1, 1), BackgroundColor3 = Theme.Palette.Panel })
	UIKit.Corner(Theme.Radius.Pill).Parent = xpBg
	local xpFill = UIKit.Frame({ Parent = xpBg, Size = UDim2.new(0.25, 0, 1, 0), BackgroundColor3 = Theme.Brand.Primary })
	UIKit.Corner(Theme.Radius.Pill).Parent = xpFill
	self.Store.XpFill = xpFill

	-- SURVIVAL HERO — large, dominant, floating on the right/center-top
	local survWrap = UIKit.Frame({ Parent = root, Size = UDim2.new(0.48, 0, 0, 200), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.52, 0, 0.18, 0) })
	survWrap.BackgroundTransparency = 1

	local survCard = UIKit.Frame({ Parent = survWrap, Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(20, 22, 38), BorderSizePixel = 0 })
	UIKit.Corner(Theme.Radius.Large).Parent = survCard

	-- Gradient treatment inside survival card (not flat)
	local survGrad = Instance.new("UIGradient")
	survGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 70, 130)),
		ColorSequenceKeypoint.new(0.3, Color3.fromRGB(60, 20, 80)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 18, 30)),
	})
	survGrad.Rotation = 135
	survGrad.Parent = survCard

	-- Glowing top edge
	local survEdge = UIKit.Frame({ Parent = survCard, Size = UDim2.new(1, 0, 0, 3), BackgroundColor3 = Theme.Brand.Accent })
	UIKit.Corner(Theme.Radius.Small).Parent = survEdge

	-- Large star icon
	local survIconWrap = UIKit.Frame({ Parent = survCard, Size = UDim2.fromOffset(70, 70), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0.04, 0, 0.28, 0), BackgroundColor3 = Theme.WithAlpha(Theme.Brand.Accent, 0.15) })
	UIKit.Corner(Theme.Radius.Large).Parent = survIconWrap
	UIKit.Stroke(Theme.Brand.Accent, 1, Theme.Opacity.Subtle).Parent = survIconWrap
	local survIcon = UIKit.Text(survIconWrap, "★", UDim2.fromScale(0.7, 0.7), Theme.Brand.Accent)
	survIcon.AnchorPoint = Vector2.new(0.5, 0.5)
	survIcon.Position = UDim2.fromScale(0.5, 0.5)
	survIcon.TextScaled = false
	survIcon.TextSize = 36

	local survTitle = UIKit.Title(survCard, "SURVIVAL", UDim2.new(0.6, 0, 0, 28), Color3.fromRGB(255, 240, 250))
	survTitle.AnchorPoint = Vector2.new(0, 0.5)
	survTitle.Position = UDim2.new(0.22, 0, 0.28, 0)
	survTitle.TextScaled = false
	survTitle.TextSize = Theme.TypeSize.Huge
	survTitle.TextXAlignment = Enum.TextXAlignment.Left

	local survSub = UIKit.Muted(survCard, "4 ROUNDS · 10 PLAYERS · LAST ONE STANDING", UDim2.new(0.6, 0, 0, 14), Color3.fromRGB(220, 210, 230))
	survSub.AnchorPoint = Vector2.new(0, 0.5)
	survSub.Position = UDim2.new(0.22, 0, 0.48, 0)
	survSub.TextScaled = false
	survSub.TextSize = Theme.TypeSize.Tiny
	survSub.TextXAlignment = Enum.TextXAlignment.Left

	local best = UIKit.Muted(survCard, "WINS: —", UDim2.new(0.6, 0, 0, 14), Theme.Brand.Gold)
	best.AnchorPoint = Vector2.new(0, 0.5)
	best.Position = UDim2.new(0.22, 0, 0.65, 0)
	best.TextScaled = false
	best.TextSize = Theme.TypeSize.Tiny
	self.Store.SurvBest = best

	local survBtn = UIKit.GradientButton(survCard, "JOIN LOBBY", UDim2.new(0.28, 0, 0, 32), Theme.Brand.Accent, { rotation = 0 })
	survBtn.AnchorPoint = Vector2.new(0.5, 1)
	survBtn.Position = UDim2.new(0.5, 0, 0.92, 0)
	survBtn.TextScaled = false
	survBtn.TextSize = Theme.TypeSize.Small
	survBtn.Activated:Connect(function()
		AudioService.PlayClick()
		if Hub.OnAction then Hub.OnAction("Play", { id = "survival", name = "Survival" }) end
	end)

	-- Four game cards — arranged horizontally with visual identity
	local cardsWrap = UIKit.Frame({ Parent = root, Size = UDim2.new(1, -32, 0, 110), AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 0.92, 0) })
	cardsWrap.BackgroundTransparency = 1

	local cardsLayout = Instance.new("UIGridLayout")
	cardsLayout.CellSize = UDim2.new(0.23, 0, 1, 0)
	cardsLayout.CellPadding = UDim2.new(0.015, 0, 0, 0)
	cardsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	cardsLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	cardsLayout.FillDirection = Enum.FillDirection.Horizontal
	cardsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	cardsLayout.Parent = cardsWrap

	local gameInfo = {
		{ id = "chaos_run", label = "CHAOS", sub = "Run", accent = Theme.Brand.Primary, icon = "➤" },
		{ id = "dodge_lab", label = "DODGE", sub = "Lab", accent = Theme.Brand.Danger, icon = "✦" },
		{ id = "build_blitz", label = "BUILD", sub = "Blitz", accent = Theme.Brand.Warning, icon = "▬" },
		{ id = "sequence_sprint", label = "SEQ.", sub = "Sprint", accent = Theme.Brand.Secondary, icon = "⧗" },
	}
	for order, g in gameInfo do
		local card = UIKit.Frame({ Parent = cardsWrap, BackgroundColor3 = Theme.Palette.PanelAlt, BorderSizePixel = 0 })
		UIKit.Corner(Theme.Radius.Medium).Parent = card
		card.BackgroundTransparency = Theme.Opacity.Card

		-- Small top accent
		local top = UIKit.Frame({ Parent = card, Size = UDim2.new(1, 0, 0, 2), BackgroundColor3 = g.accent })
		UIKit.Corner(Theme.Radius.Small).Parent = top

		-- Large icon at top
		local iconWrap = UIKit.Frame({ Parent = card, Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1 })
		local icon = UIKit.Text(iconWrap, g.icon, UDim2.fromScale(0.8, 1), g.accent)
		icon.TextScaled = true
		icon.TextSize = Theme.TypeSize.Hero
		icon.AnchorPoint = Vector2.new(0.5, 0.5)
		icon.Position = UDim2.fromScale(0.5, 0.5)

		-- Title (bold large)
		local title = UIKit.Title(card, g.label, UDim2.new(1, -8, 0, 22), Theme.Palette.Text)
		title.Position = UDim2.new(0, 8, 0.42, 0)
		title.TextScaled = false
		title.TextSize = Theme.TypeSize.Header
		title.TextXAlignment = Enum.TextXAlignment.Center

		-- Subtitle
		local sub = UIKit.Muted(card, g.sub, UDim2.new(1, -8, 0, 16), Theme.Palette.TextDim)
		sub.Position = UDim2.new(0, 8, 0.62, 0)
		sub.TextScaled = false
		sub.TextSize = Theme.TypeSize.Small
		sub.TextXAlignment = Enum.TextXAlignment.Center

		-- Best
		local best = UIKit.Muted(card, "BEST —", UDim2.new(1, -8, 0, 14), Theme.Palette.TextFaint)
		best.Position = UDim2.new(0, 8, 0.78, 0)
		best.TextScaled = false
		best.TextSize = Theme.TypeSize.Tiny
		best.TextXAlignment = Enum.TextXAlignment.Center
		self.Store.Cards = self.Store.Cards or {}
		self.Store.Cards[g.id] = best

		-- Play button — clean pill at bottom
		local btn = UIKit.Button(card, "PLAY", UDim2.new(0.84, 0, 0, 26), g.accent, { textColor = Color3.new(1,1,1) })
		btn.AnchorPoint = Vector2.new(0.5, 1)
		btn.Position = UDim2.new(0.5, 0, 0.94, 0)
		btn.TextScaled = false
		btn.TextSize = Theme.TypeSize.Small
		btn.Activated:Connect(function()
			AudioService.PlayClick()
			if Hub.OnAction then Hub.OnAction("Play", { id = g.id, name = g.name }) end
		end)
	end

	self.Store.Cards = {}
end

function Hub:SetProgression(level, xp, xpNext, coins)
	-- Player status is now in the floating statusPanel; no separate strip needed
end

function Hub:SetMastery(rank)
	-- Mastery shown via status indicator or can be added to statusPanel
end

function Hub:SetRecords(records)
	if not self.Store then return end
	records = records or {}
	for _, g in ({id="chaos_run"},{id="dodge_lab"},{id="build_blitz"},{id="sequence_sprint"}) do
		local lbl = self.Store.Cards and self.Store.Cards[g.id]
		if lbl and records[g.id] then
			lbl.Text = ("BEST %d"):format(records[g.id])
		end
	end
end

return Hub
