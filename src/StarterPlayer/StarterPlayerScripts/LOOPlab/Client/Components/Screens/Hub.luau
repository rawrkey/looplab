-- Hub: LOOPLAB — Premium Experimental Lab Hub
-- Completely different visual composition from original: floating layered elements,
-- large hero Survival at top, compact cards at bottom, no giant flat panel.

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
	{ id = "chaos_run", name = "CHAOS RUN", desc = "Checkpoint sprint", accent = Theme.Brand.Primary, icon = "➤" },
	{ id = "dodge_lab", name = "DODGE LAB", desc = "Dodge the rain", accent = Theme.Brand.Danger, icon = "✦" },
	{ id = "build_blitz", name = "BUILD BLITZ", desc = "Stack blocks", accent = Theme.Brand.Warning, icon = "▬" },
	{ id = "sequence_sprint", name = "SEQ. SPRINT", desc = "Memory repeat", accent = Theme.Brand.Secondary, icon = "⧗" },
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

	-- DARK LAB ENVIRONMENT (not black — deep navy with radial warm glow)
	local envBg = UIKit.Frame({ Parent = root, Size = UDim2.fromScale(1, 1) })
	envBg.BackgroundColor3 = Color3.fromRGB(8, 10, 22)
	envBg.BorderSizePixel = 0
	local envGrad = Instance.new("UIGradient")
	envGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(12, 14, 28)),
		ColorSequenceKeypoint.new(0.3, Color3.fromRGB(30, 20, 50)),
		ColorSequenceKeypoint.new(0.7, Color3.fromRGB(20, 25, 45)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(8, 10, 22)),
	})
	envGrad.Rotation = 45
	envGrad.Parent = envBg

	-- Large glowing top arc (not a panel — decorative)
	local glowArc = UIKit.Frame({ Parent = root, Size = UDim2.new(1, 0, 0, 3), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.08, 0), BackgroundColor3 = Theme.Brand.Primary })
	glowArc.BackgroundTransparency = 0.7
	glowArc.BorderSizePixel = 0

	-- TOP LEFT — Brand
	local brandZone = UIKit.Frame({ Parent = root, Size = UDim2.new(0.5, 0, 0, 50), AnchorPoint = Vector2.new(0, 0), Position = UDim2.new(0.03, 0, 0.04, 0) })
	brandZone.BackgroundTransparency = 1
	local brandText = UIKit.Title(brandZone, "LOOPLAB", UDim2.new(0, 220, 0, 36), Theme.Brand.Gold)
	brandText.TextScaled = false
	brandText.TextSize = Theme.TypeSize.Hero
	brandText.Font = Theme.Type.Display
	brandText.TextXAlignment = Enum.TextXAlignment.Left

	local brandSub = UIKit.Muted(brandZone, "TEST · SURVIVE · REPEAT", UDim2.new(0, 220, 0, 14), Theme.Palette.TextDim)
	brandSub.Position = UDim2.new(0, 0, 0.65, 0)
	brandSub.TextScaled = false
	brandSub.TextSize = Theme.TypeSize.Tiny

	-- TOP RIGHT — Compact Player Status (small floating pill)
	local pStatus = UIKit.Frame({ Parent = root, Size = UDim2.new(0.4, 0, 0, 44), AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(0.97, 0, 0.04, 0), BackgroundColor3 = Theme.WithAlpha(Theme.Palette.PanelAlt, 0.7) })
	pStatus.BackgroundTransparency = Theme.Opacity.Soft
	UIKit.Corner(Theme.Radius.Medium).Parent = pStatus
	UIKit.Stroke(Theme.Brand.Gold, 0.5, Theme.Opacity.Subtle).Parent = pStatus

	local avatar = UIKit.Frame({ Parent = pStatus, Size = UDim2.fromOffset(32, 32), BackgroundColor3 = Theme.Palette.Panel })
	avatar.Position = UDim2.new(0.06, 0, 0.5, 0)
	avatar.AnchorPoint = Vector2.new(0, 0.5)
	UIKit.Corner(Theme.Radius.Pill).Parent = avatar

	local pName = UIKit.Muted(pStatus, "Player", UDim2.new(0.35, 0, 0, 14), Theme.Palette.Text)
	pName.Position = UDim2.new(0.16, 0, 0.22, 0)
	pName.TextScaled = false
	pName.TextSize = Theme.TypeSize.Tiny

	local pLv = UIKit.Title(pStatus, "L1", UDim2.new(0.2, 0, 0, 14), Theme.Brand.Gold)
	pLv.Position = UDim2.new(0.16, 0, 0.55, 0)
	pLv.TextScaled = false
	pLv.TextSize = Theme.TypeSize.Small

	local pCoins = UIKit.Muted(pStatus, "◉ 0", UDim2.new(0.25, 0, 0, 12), Theme.Brand.Gold)
	pCoins.Position = UDim2.new(0.72, 0, 0.55, 0)
	pCoins.TextScaled = false
	pCoins.TextSize = Theme.TypeSize.Tiny

	-- CENTER TOP — SURVIVAL HERO (dominant, fully visible, large)
	local survZone = UIKit.Frame({ Parent = root, Size = UDim2.new(0.9, 0, 0, 220), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.16, 0) })
	survZone.BackgroundTransparency = 1

	local survCard = UIKit.Frame({ Parent = survZone, Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(14, 12, 28), BorderSizePixel = 0 })
	UIKit.Corner(Theme.Radius.Large).Parent = survCard

	-- Bright gradient treatment (red-pink to dark — clearly visible)
	local survGrad = Instance.new("UIGradient")
	survGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 60, 100)),
		ColorSequenceKeypoint.new(0.4, Color3.fromRGB(140, 30, 80)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 12, 28)),
	})
	survGrad.Rotation = 90
	survGrad.Parent = survCard

	-- Glowing top edge
	local survEdge = UIKit.Frame({ Parent = survCard, Size = UDim2.new(1, 0, 0, 4), BackgroundColor3 = Theme.Brand.Accent })
	UIKit.Corner(Theme.Radius.Small).Parent = survEdge

	-- Large icon + title area (left side of hero)
	local heroIconArea = UIKit.Frame({ Parent = survCard, Size = UDim2.fromOffset(72, 72), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0.06, 0, 0.35, 0), BackgroundColor3 = Theme.WithAlpha(Theme.Brand.Accent, 0.2) })
	UIKit.Corner(Theme.Radius.Large).Parent = heroIconArea
	UIKit.Stroke(Theme.Brand.Accent, 1, Theme.Opacity.Subtle).Parent = heroIconArea
	local heroIcon = UIKit.Text(heroIconArea, "★", UDim2.fromScale(0.7, 0.7), Theme.Brand.Accent)
	heroIcon.AnchorPoint = Vector2.new(0.5, 0.5)
	heroIcon.Position = UDim2.fromScale(0.5, 0.5)
	heroIcon.TextScaled = false
	heroIcon.TextSize = 36

	local heroTitle = UIKit.Title(survCard, "SURVIVAL", UDim2.new(0.55, 0, 0, 32), Color3.fromRGB(255, 240, 245))
	heroTitle.AnchorPoint = Vector2.new(0, 0.5)
	heroTitle.Position = UDim2.new(0.18, 0, 0.28, 0)
	heroTitle.TextScaled = false
	heroTitle.TextSize = Theme.TypeSize.Huge
	heroTitle.Font = Theme.Type.Display

	local heroSub = UIKit.Muted(survCard, "4 ROUNDS · 10 PLAYERS · LAST ONE STANDING", UDim2.new(0.55, 0, 0, 18), Color3.fromRGB(220, 210, 230))
	heroSub.AnchorPoint = Vector2.new(0, 0.5)
	heroSub.Position = UDim2.new(0.18, 0, 0.48, 0)
	heroSub.TextScaled = false
	heroSub.TextSize = Theme.TypeSize.Small

	local heroBest = UIKit.Muted(survCard, "BEST WINS —", UDim2.new(0.55, 0, 0, 14), Theme.Brand.Gold)
	heroBest.Position = UDim2.new(0.18, 0, 0.65, 0)
	heroBest.TextScaled = false
	heroBest.TextSize = Theme.TypeSize.Small
	self.Store.SurvBest = heroBest

	local heroBtn = UIKit.GradientButton(survCard, "JOIN LOBBY", UDim2.new(0.25, 0, 0, 36), Theme.Brand.Accent, { rotation = 0 })
	heroBtn.AnchorPoint = Vector2.new(0.5, 1)
	heroBtn.Position = UDim2.new(0.5, 0, 0.92, 0)
	heroBtn.TextScaled = false
	heroBtn.TextSize = Theme.TypeSize.Body
	heroBtn.Activated:Connect(function()
		AudioService.PlayClick()
		if Hub.OnAction then Hub.OnAction("Play", { id = "survival", name = "Survival" }) end
	end)

	-- FOUR GAME CARDS — bottom horizontal row, very different from 2x2 grid
	local cardsZone = UIKit.Frame({ Parent = root, Size = UDim2.new(1, -32, 0, 100), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.78, 0) })
	cardsZone.BackgroundTransparency = 1

	local cards = Instance.new("UIGridLayout")
	cards.CellSize = UDim2.new(0.23, 0, 1, 0)
	cards.CellPadding = UDim2.new(0.02, 0, 0, 0)
	cards.HorizontalAlignment = Enum.HorizontalAlignment.Center
	cards.VerticalAlignment = Enum.VerticalAlignment.Top
	cards.SortOrder = Enum.SortOrder.LayoutOrder
	cards.Parent = cardsZone

	local gameDefs = {
		{ id = "chaos_run", label = "CHAOS", sub = "RUN", accent = Theme.Brand.Primary, icon = "➤" },
		{ id = "dodge_lab", label = "DODGE", sub = "LAB", accent = Theme.Brand.Danger, icon = "✦" },
		{ id = "build_blitz", label = "BUILD", sub = "BLITZ", accent = Theme.Brand.Warning, icon = "▬" },
		{ id = "sequence_sprint", label = "SEQ.", sub = "SPRINT", accent = Theme.Brand.Secondary, icon = "⧗" },
	}
	for i, g in gameDefs do
		local card = UIKit.Frame({ Parent = cardsZone, BackgroundColor3 = Theme.Palette.PanelAlt, BorderSizePixel = 0 })
		UIKit.Corner(Theme.Radius.Medium).Parent = card
		card.BackgroundTransparency = Theme.Opacity.Card

		local bar = UIKit.Frame({ Parent = card, Size = UDim2.new(1, 0, 0, 2), BackgroundColor3 = g.accent })
		UIKit.Corner(Theme.Radius.Small).Parent = bar

		local icon = UIKit.Text(card, g.icon, UDim2.new(1, 0, 0, 28), g.accent)
		icon.Position = UDim2.new(0, 0, 0, 6)
		icon.TextScaled = true
		icon.TextSize = 26
		icon.TextXAlignment = Enum.TextXAlignment.Center

		local title = UIKit.Title(card, g.label, UDim2.new(1, 0, 0, 20), Theme.Palette.Text)
		title.Position = UDim2.new(0, 0, 0, 36)
		title.TextScaled = false
		title.TextSize = Theme.TypeSize.Header
		title.TextXAlignment = Enum.TextXAlignment.Center

		local sub = UIKit.Muted(card, g.sub, UDim2.new(1, 0, 0, 14), Theme.Palette.TextDim)
		sub.Position = UDim2.new(0, 0, 0, 56)
		sub.TextScaled = false
		sub.TextSize = Theme.TypeSize.Tiny
		sub.TextXAlignment = Enum.TextXAlignment.Center

		local best = UIKit.Muted(card, "BEST —", UDim2.new(1, 0, 0, 12), Theme.Palette.TextFaint)
		best.Position = UDim2.new(0, 0, 0, 70)
		best.TextScaled = false
		best.TextSize = Theme.TypeSize.Tiny
		best.TextXAlignment = Enum.TextXAlignment.Center
		self.Store.Cards = self.Store.Cards or {}
		self.Store.Cards[g.id] = best

		local btn = UIKit.Button(card, "PLAY", UDim2.new(0.8, 0, 0, 24), g.accent, { textColor = Color3.new(1,1,1) })
		btn.Position = UDim2.new(0.1, 0, 0.88, 0)
		btn.TextScaled = false
		btn.TextSize = Theme.TypeSize.Small
		btn.Activated:Connect(function()
			AudioService.PlayClick()
			if Hub.OnAction then Hub.OnAction("Play", { id = g.id, name = g.sub }) end
		end)
	end

	-- Navigation at very bottom (small, clean)
	local navWrap = UIKit.Frame({ Parent = root, Size = UDim2.new(1, -32, 0, 32), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.98, 0) })
	navWrap.BackgroundTransparency = 1

	local navLayout = Instance.new("UIListLayout")
	navLayout.Padding = UDim.new(0, 6)
	navLayout.FillDirection = Enum.FillDirection.Horizontal
	navLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	navLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	navLayout.SortOrder = Enum.SortOrder.LayoutOrder
	navLayout.Parent = navWrap

	local navItems = {
		{ id = "Leaderboards", icon = "↺" },
		{ id = "Profile", icon = "◉" },
		{ id = "Cosmetics", icon = "◈" },
		{ id = "Settings", icon = "⚙" },
	}
	for j, n in navItems do
		local b = UIKit.Button(navWrap, n.icon, UDim2.new(0, 36, 1, 0), Theme.Palette.PanelAlt, { textColor = Theme.Palette.TextDim })
		b.LayoutOrder = j
		b.TextScaled = false
		b.TextSize = Theme.TypeSize.Small
		b.Activated:Connect(function()
			AudioService.PlayClick()
			if Hub.OnAction then Hub.OnAction(n.id) end
		end)
	end
end

function Hub:SetProgression(level, xp, xpNext, coins)
	if not self.Store then return end
end

function Hub:SetMastery(rank)
end

function Hub:SetRecords(records)
	if not self.Store then return end
	records = records or {}
	for _, g in ({id="chaos_run"},{id="dodge_lab"},{id="build_blitz"},{id="sequence_sprint"}) do
		local lbl = self.Store.Cards and self.Store.Cards[g.id]
		if lbl and records[g.id] then lbl.Text = ("BEST %d"):format(records[g.id]) end
	end
end

return Hub
