-- Hub: LOOPLAB command center. Activity cards, survival flagship, sub-entries.

local UIKit = require(script.Parent.Parent.UIKit)
local Theme = require(script.Parent.Parent.Theme)

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
	UIKit.SlideIn(self.Panel, 0.04, Theme.Motion.Normal)
end

function Hub:Build(parent)
	local root = UIKit.Frame({
		Parent = parent,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	})
	self.Root = root
	self.Store = {}

	local bgGlow = UIKit.Frame({ Parent = root, Size = UDim2.fromScale(1, 1) })
	bgGlow.BackgroundColor3 = Theme.Palette.Background
	bgGlow.BorderSizePixel = 0
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Theme.Palette.Background),
		ColorSequenceKeypoint.new(0.5, Theme.WithAlpha(Theme.Brand.Secondary, 0.12)),
		ColorSequenceKeypoint.new(1, Theme.Palette.Background),
	})
	gradient.Parent = bgGlow

	local panel = UIKit.Panel(root, UDim2.new(0.62, 0, 0.92, 0), Theme.Palette.PanelAlt)
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	self.Panel = panel

	local logo = UIKit.Title(panel, "LOOPLAB", UDim2.new(1, 0, 0, 64), Theme.Brand.Primary)
	logo.TextScaled = false
	logo.TextSize = Theme.TypeSize.Hero
	local tagline = UIKit.Text(panel, "Test yourself. Survive the Lab.", UDim2.new(1, 0, 0, 28), Theme.Palette.TextDim)
	tagline.Position = UDim2.new(0, 0, 0, 64)

	local strip = UIKit.Frame({ Parent = panel, Size = UDim2.new(1, -40, 0, 34), Position = UDim2.new(0, 20, 0, 100) })
	strip.BackgroundTransparency = 1
	local levelLbl = UIKit.Text(strip, "Level 1", UDim2.new(0.32, 0, 1, 0), Theme.Brand.Gold)
	local xpLbl = UIKit.Text(strip, "0/100 XP", UDim2.new(0.34, 0, 1, 0), Theme.Palette.TextDim)
	xpLbl.Position = UDim2.new(0.32, 0, 0, 0)
	local coinLbl = UIKit.Text(strip, "0 Coins", UDim2.new(0.34, 0, 1, 0), Theme.Brand.Gold)
	coinLbl.Position = UDim2.new(0.66, 0, 0, 0)
	self.Store.Level = levelLbl
	self.Store.Xp = xpLbl
	self.Store.Coins = coinLbl

	local xpBar = UIKit.Frame({ Parent = panel, Size = UDim2.new(1, -80, 0, 8), Position = UDim2.new(0, 40, 0, 140) })
	xpBar.BackgroundColor3 = Theme.Palette.Background
	UIKit.Corner(Theme.Radius.Pill).Parent = xpBar
	local xpFill = UIKit.Frame({ Parent = xpBar, Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = Theme.Brand.Primary })
	UIKit.Corner(Theme.Radius.Pill).Parent = xpFill
	self.Store.XpBar = xpFill

	local gridWrap = UIKit.Frame({ Parent = panel, Size = UDim2.new(1, -48, 0, 300), Position = UDim2.new(0, 24, 0, 165) })
	gridWrap.BackgroundTransparency = 1
	local grid = Instance.new("UIGridLayout")
	grid.Parent = gridWrap
	grid.CellSize = UDim2.new(0.32, 0, 0.44, 0)
	grid.CellPadding = UDim2.new(0.03, 0, 0.04, 0)
	grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
	grid.VerticalAlignment = Enum.VerticalAlignment.Top
	grid.FillDirection = Enum.FillDirection.Horizontal
	grid.SortOrder = Enum.SortOrder.LayoutOrder

	local function makeCard(cfg)
		local card = UIKit.Panel(gridWrap, UDim2.fromScale(1, 1), Theme.Palette.Panel)
		card.LayoutOrder = cfg.order or 0
		local accentLine = UIKit.Frame({ Parent = card, Size = UDim2.new(1, 0, 0, 5), BackgroundColor3 = cfg.accent })
		UIKit.Corner(Theme.Radius.Small).Parent = accentLine
		local icon = UIKit.Text(card, cfg.icon, UDim2.new(1, 0, 0, 40), cfg.accent)
		icon.Position = UDim2.new(0, 0, 0, 8)
		icon.TextSize = 24
		icon.TextScaled = false
		local name = UIKit.Title(card, cfg.name, UDim2.new(1, 0, 0, 30), Theme.Palette.Text)
		name.TextScaled = false
		name.TextSize = Theme.TypeSize.Header
		name.Position = UDim2.new(0, 0, 0, 48)
		local desc = UIKit.Text(card, cfg.desc, UDim2.new(1, 0, 0, 22), Theme.Palette.TextDim)
		desc.TextScaled = false
		desc.TextSize = Theme.TypeSize.Small
		desc.Position = UDim2.new(0, 0, 0, 80)

		local btn = UIKit.GradientButton(card, "PLAY", UDim2.new(0.8, 0, 0, 36), cfg.accent)
		btn.AnchorPoint = Vector2.new(0.5, 1)
		btn.Position = UDim2.new(0.5, 0, 1, -10)
		btn.TextScaled = false
		btn.TextSize = Theme.TypeSize.Body
		btn.Activated:Connect(function()
			if Hub.OnAction then Hub.OnAction("Play", cfg) end
		end)
		return card
	end

	for order, cfg in ACTIVITIES do
		cfg.order = order
		makeCard(cfg)
	end

	local survCard = UIKit.Panel(gridWrap, UDim2.fromScale(1, 1), Theme.Palette.Panel)
	survCard.LayoutOrder = 5
	local sg = Instance.new("UIGradient")
	sg.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Theme.Accent("survival")),
		ColorSequenceKeypoint.new(1, Theme.Palette.Panel),
	})
	sg.Rotation = 90
	sg.Parent = survCard
	local flag = UIKit.Title(survCard, "SURVIVAL", UDim2.new(1, 0, 0, 40), Color3.fromRGB(255, 255, 255))
	flag.TextScaled = false
	flag.TextSize = Theme.TypeSize.Huge
	flag.Position = UDim2.new(0, 0, 0, 10)
	local survDesc = UIKit.Text(survCard, "4 rounds · last standing wins", UDim2.new(1, 0, 0, 24), Color3.fromRGB(255, 220, 220))
	survDesc.TextScaled = false
	survDesc.TextSize = Theme.TypeSize.Body
	survDesc.Position = UDim2.new(0, 0, 0, 56)
	local survBtn = UIKit.GradientButton(survCard, "JOIN LOBBY", UDim2.new(0.86, 0, 0, 40), Theme.Accent("survival"))
	survBtn.AnchorPoint = Vector2.new(0.5, 1)
	survBtn.Position = UDim2.new(0.5, 0, 1, -10)
	survBtn.TextScaled = false
	survBtn.TextSize = Theme.TypeSize.Body
	survBtn.Activated:Connect(function()
		if Hub.OnAction then Hub.OnAction("Play", { id = "survival", name = "Survival" }) end
	end)

	local footer = UIKit.Frame({ Parent = panel, Size = UDim2.new(1, -40, 0, 44), Position = UDim2.new(0, 20, 0, 482) })
	footer.BackgroundTransparency = 1
	local navs = { { "Leaderboards", "↺" }, { "Profile", "◉" }, { "Settings", "⚙" } }
	for i, nav in navs do
		local b = UIKit.Button(footer, nav[2] .. "  " .. nav[1], UDim2.new(0.3, 0, 1, 0), Theme.Palette.Panel, { textColor = Theme.Palette.Text })
		b.Position = UDim2.new((i - 1) * 0.35, 12, 0, 0)
		b.TextScaled = false
		b.TextSize = Theme.TypeSize.Body
		b.Activated:Connect(function()
			if Hub.OnAction then Hub.OnAction(nav[1]) end
		end)
	end
end

function Hub:SetProgression(level, xp, xpNext, coins)
	if not self.Store then return end
	if self.Store.Level then self.Store.Level.Text = ("LEVEL %d"):format(level or 1) end
	if self.Store.Xp then self.Store.Xp.Text = ("%d / %d XP"):format(xp or 0, xpNext or 100) end
	if self.Store.Coins then self.Store.Coins.Text = ("%d Coins"):format(coins or 0) end
	if self.Store.XpBar and xpNext and xpNext > 0 then
		local frac = math.clamp((xp or 0) / xpNext, 0, 1)
		self.Store.XpBar.Size = UDim2.new(frac, 0, 1, 0)
	end
end

return Hub