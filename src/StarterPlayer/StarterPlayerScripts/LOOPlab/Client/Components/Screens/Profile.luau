-- Profile: character overview, stats, daily challenge claim.

local UIKit = require(script.Parent.Parent.UIKit)
local Theme = require(script.Parent.Parent.Theme)
local AudioService = require(script.Parent.Parent.AudioService)

local Profile = {
	Name = "Profile",
	Root = nil,
	Store = {},
	OnClose = nil,
	OnClaim = nil,
}

local STATS = {
	{ key = "MatchesPlayed", label = "Matches", icon = "▤" },
	{ key = "Wins", label = "Wins", icon = "★" },
	{ key = "TotalScore", label = "Total Score", icon = "Σ" },
	{ key = "BestScore", label = "Best Score", icon = "⚑" },
	{ key = "CoinsEarned", label = "Coins Earned", icon = "◉" },
	{ key = "DailiesClaimed", label = "Dailies", icon = "✎" },
}

function Profile:Hide()
	if self.Root then self.Root.Visible = false end
end

function Profile:Show(data)
	if not self.Root then return end
	self.Root.Visible = true
	if data then self:SetProfile(data) end
	UIKit.SlideIn(self.Panel, 0.03, Theme.Motion.Normal)
end

function Profile:Build(parent)
	local root = UIKit.Frame({
		Parent = parent,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	})
	self.Root = root

	local scrim = UIKit.Frame({ Parent = root, Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.5, BorderSizePixel = 0 })

	local panel = UIKit.PanelAlt(root, UDim2.new(0.62, 0, 0.84, 0), Theme.Brand.Primary)
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	self.Panel = panel

	local title = UIKit.Title(panel, "PROFILE", UDim2.new(1, 0, 0, 52), Theme.Brand.Primary)
	title.TextScaled = false
	title.TextSize = Theme.TypeSize.Huge

	local avatarRing = UIKit.Panel(panel, UDim2.fromOffset(72, 72), Theme.Palette.Panel)
	avatarRing.Position = UDim2.new(0.5, 0, 0.14, 0)
	avatarRing.AnchorPoint = Vector2.new(0.5, 0.5)
	UIKit.Corner(Theme.Radius.Pill).Parent = avatarRing
	local avatar = Instance.new("ImageLabel")
	avatar.Size = UDim2.fromScale(1, 1)
	avatar.BackgroundTransparency = 1
	avatar.Image = "rbxthumb://type=AvatarHeadShot&id=0&w=150&h=150"
	avatar.Parent = avatarRing
	self.Store.Avatar = avatar

	local name = UIKit.Title(panel, "", UDim2.new(1, 0, 0, 32), Theme.Palette.Text)
	name.Position = UDim2.new(0, 0, 0, 118)
	name.TextScaled = false
	name.TextSize = Theme.TypeSize.Header
	self.Store.Name = name

	local pLevel = UIKit.Text(panel, "Level 1 · 0/100 XP", UDim2.new(1, 0, 0, 24), Theme.Palette.TextDim)
	pLevel.Position = UDim2.new(0, 0, 0, 150)
	pLevel.TextScaled = false
	pLevel.TextSize = Theme.TypeSize.Body
	self.Store.Level = pLevel

	local stats = UIKit.Frame({ Parent = panel, Size = UDim2.new(0.96, 0, 0.34, 0), Position = UDim2.new(0.02, 0, 0, 186) })
	stats.BackgroundTransparency = 1
	self.Store.StatBoxes = {}
	local grid = Instance.new("UIGridLayout")
	grid.Parent = stats
	grid.CellSize = UDim2.new(0.31, 0, 0.46, 0)
	grid.CellPadding = UDim2.new(0.02, 0, 0.03, 0)
	grid.FillDirection = Enum.FillDirection.Horizontal
	grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
	grid.VerticalAlignment = Enum.VerticalAlignment.Top
	grid.SortOrder = Enum.SortOrder.LayoutOrder

	for order, s in STATS do
		local box = UIKit.Panel(stats, UDim2.fromScale(1, 1), Theme.Palette.Panel)
		box.LayoutOrder = order
		local icon = UIKit.Text(box, s.icon, UDim2.new(1, 0, 0, 24), Theme.Brand.Primary)
		icon.Position = UDim2.new(0, 0, 0, 6)
		icon.TextScaled = false
		icon.TextSize = 18
		local val = UIKit.Title(box, "0", UDim2.new(1, 0, 0, 22), Theme.Palette.Text)
		val.Position = UDim2.new(0, 0, 0, 28)
		val.TextScaled = false
		val.TextSize = Theme.TypeSize.Header
		local lab = UIKit.Text(box, s.label, UDim2.new(1, 0, 0, 18), Theme.Palette.TextDim)
		lab.Position = UDim2.new(0, 0, 0, 50)
		lab.TextScaled = false
		lab.TextSize = 11
		table.insert(self.Store.StatBoxes, { value = val })
	end

	local daily = UIKit.PanelAlt(panel, UDim2.new(0.96, 0, 0, 54), Theme.Brand.Gold)
	daily.Position = UDim2.new(0.02, 0, 0, 560)
	daily.BackgroundTransparency = 0.3
	local dailyText = UIKit.Text(daily, "Daily Challenge · Claim 100 Coins", UDim2.new(0.62, 0, 1, 0), Theme.Brand.Gold)
	dailyText.Position = UDim2.new(0.04, 0, 0, 0)
	dailyText.TextScaled = false
	dailyText.TextSize = Theme.TypeSize.Body
	local claimBtn = UIKit.Button(daily, "CLAIM", UDim2.new(0.24, 0, 0.7, 0), Theme.Brand.Gold, { textColor = Color3.new(1, 1, 1) })
	claimBtn.AnchorPoint = Vector2.new(1, 0.5)
	claimBtn.Position = UDim2.new(0.96, 0, 0.5, 0)
	claimBtn.TextScaled = false
	claimBtn.TextSize = Theme.TypeSize.Body
	self.Store.DailyClaim = claimBtn
	claimBtn.Activated:Connect(function()
		if Profile.OnClaim then Profile.OnClaim() end
	end)

	local btn = UIKit.GradientButton(panel, "BACK", UDim2.new(0.4, 0, 0, 42), Theme.Brand.Primary)
	btn.AnchorPoint = Vector2.new(0.5, 1)
	btn.Position = UDim2.new(0.5, 0, 1, -10)
	btn.TextScaled = false
	btn.TextSize = Theme.TypeSize.Body
	btn.Activated:Connect(function()
		if Profile.OnClose then Profile.OnClose() end
	end)
end

function Profile:SetProfile(data)
	if not self.Store then return end
	if self.Store.Name then
		self.Store.Name.Text = data.DisplayName or data.Name or ""
	end
	if data.Progress and self.Store.Level then
		self.Store.Level.Text = ("Level %d · %d/%d XP"):format(data.Progress.Level or 1, data.Progress.Xp or 0, data.Progress.XpNext or 100)
	end
	local stats = data.Stats or {}
	for i, box in self.Store.StatBoxes do
		local key = STATS[i] and STATS[i].key
		if key and stats[key] ~= nil then
			box.value.Text = tostring(stats[key])
		end
	end
	if data.Settings and self.Store.DailyClaim then
		self.Store.DailyClaim.Text = (data.DailyClaimed or data.Settings.LastDailyClaim) and "CLAIMED" or "CLAIM"
	end
end

function Profile:SetDailyClaim(claimed: boolean)
	if self.Store and self.Store.DailyClaim then
		self.Store.DailyClaim.Text = claimed and "CLAIMED" or "CLAIM"
	end
end

return Profile