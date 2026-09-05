-- Profile: character overview, mastery rank, stats grid, title showcase + equip,
-- badge wall, records, daily claim. Redesigned for the progression phase.

local UIKit = require(script.Parent.Parent.UIKit)
local Theme = require(script.Parent.Parent.Theme)
local AudioService = require(script.Parent.Parent.AudioService)
local GameConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("LOOPlab").Configuration.GameConfig)

local Profile = {
	Name = "Profile",
	Root = nil,
	Store = {},
	OnClose = nil,
	OnClaim = nil,
	OnEquipTitle = nil,
}

local STATS = {
	{ key = "MatchesPlayed", label = "Matches", icon = "▤" },
	{ key = "Wins", label = "Wins", icon = "★" },
	{ key = "SurvivalMatches", label = "Surv. Matches", icon = "♛" },
	{ key = "SurvivalWins", label = "Surv. Wins", icon = "☠" },
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

	local panel = UIKit.PanelAlt(root, UDim2.new(0.72, 0, 0.88, 0), Theme.Brand.Primary)
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	self.Panel = panel

	local title = UIKit.Title(panel, "PROFILE", UDim2.new(1, 0, 0, 44), Theme.Brand.Primary)
	title.TextScaled = false
	title.TextSize = Theme.TypeSize.Huge

	-- Mastery rank banner
	local mastery = UIKit.PanelAlt(panel, UDim2.new(0.94, 0, 0, 54), Theme.MasteryColor("bronze"))
	mastery.Position = UDim2.new(0.03, 0, 0, 50)
	local rankLbl = UIKit.Title(mastery, "BRONZE", UDim2.new(0.5, 0, 1, 0), Theme.MasteryColor("bronze"))
	rankLbl.TextScaled = false
	rankLbl.TextSize = Theme.TypeSize.Header
	rankLbl.Position = UDim2.new(0.04, 0, 0, 0)
	local mXpLbl = UIKit.Text(mastery, "0 MXP", UDim2.new(0.42, 0, 1, 0), Theme.Palette.TextDim)
	mXpLbl.Position = UDim2.new(0.54, 0, 0, 0)
	mXpLbl.TextScaled = false
	mXpLbl.TextSize = Theme.TypeSize.Body
	self.Store.Mastery = rankLbl
	self.Store.MasteryXp = mXpLbl

	-- identity row: avatar + name + level + equipped title
	local idRow = UIKit.Frame({ Parent = panel, Size = UDim2.new(0.94, 0, 0, 96), Position = UDim2.new(0.03, 0, 0, 112) })
	idRow.BackgroundTransparency = 1
	local avatarRing = UIKit.Panel(idRow, UDim2.fromOffset(88, 88), Theme.Palette.Panel)
	avatarRing.Position = UDim2.new(0.03, 0, 0.5, 0)
	avatarRing.AnchorPoint = Vector2.new(0, 0.5)
	UIKit.Corner(Theme.Radius.Pill).Parent = avatarRing
	local avatar = Instance.new("ImageLabel")
	avatar.Size = UDim2.fromScale(1, 1)
	avatar.BackgroundTransparency = 1
	avatar.Image = "rbxthumb://type=AvatarHeadShot&id=0&w=150&h=150"
	avatar.Parent = avatarRing
	self.Store.Avatar = avatar

	local name = UIKit.Title(idRow, "", UDim2.new(0.6, 0, 0, 30), Theme.Palette.Text)
	name.Position = UDim2.new(0.32, 0, 0.05, 0)
	name.TextScaled = false
	name.TextSize = Theme.TypeSize.Header
	name.TextXAlignment = Enum.TextXAlignment.Left
	self.Store.Name = name

	local pLevel = UIKit.Text(idRow, "Level 1 · 0/100 XP", UDim2.new(0.6, 0, 0, 22), Theme.Palette.TextDim)
	pLevel.Position = UDim2.new(0.32, 0, 0.38, 0)
	pLevel.TextScaled = false
	pLevel.TextSize = Theme.TypeSize.Small
	pLevel.TextXAlignment = Enum.TextXAlignment.Left
	self.Store.Level = pLevel

	local titleLbl = UIKit.Text(idRow, "", UDim2.new(0.6, 0, 0, 22), Theme.Brand.Gold)
	titleLbl.Position = UDim2.new(0.32, 0, 0.62, 0)
	titleLbl.TextScaled = false
	titleLbl.TextSize = Theme.TypeSize.Small
	titleLbl.TextXAlignment = Enum.TextXAlignment.Left
	self.Store.Title = titleLbl

	-- stats grid
	local stats = UIKit.Frame({ Parent = panel, Size = UDim2.new(0.94, 0, 0.24, 0), Position = UDim2.new(0.03, 0, 0, 222) })
	stats.BackgroundTransparency = 1
	self.Store.StatBoxes = {}
	local grid = Instance.new("UIGridLayout")
	grid.Parent = stats
	grid.CellSize = UDim2.new(0.155, 0, 1, 0)
	grid.CellPadding = UDim2.new(0.01, 0, 0, 0)
	grid.FillDirection = Enum.FillDirection.Horizontal
	grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
	grid.VerticalAlignment = Enum.VerticalAlignment.Center
	grid.SortOrder = Enum.SortOrder.LayoutOrder

	for order, s in STATS do
		local box = UIKit.Panel(stats, UDim2.fromScale(1, 1), Theme.Palette.Panel)
		box.LayoutOrder = order
		local icon = UIKit.Text(box, s.icon, UDim2.new(1, 0, 0, 18), Theme.Brand.Primary)
		icon.Position = UDim2.new(0, 0, 0, 2)
		icon.TextScaled = false
		icon.TextSize = 14
		local val = UIKit.Title(box, "0", UDim2.new(1, 0, 0, 20), Theme.Palette.Text)
		val.Position = UDim2.new(0, 0, 0, 20)
		val.TextScaled = false
		val.TextSize = Theme.TypeSize.Body
		local lab = UIKit.Text(box, s.label, UDim2.new(1, 0, 0, 16), Theme.Palette.TextDim)
		lab.Position = UDim2.new(0, 0, 0, 40)
		lab.TextScaled = false
		lab.TextSize = 10
		table.insert(self.Store.StatBoxes, { value = val })
	end

	-- records strip
	local recFrame = UIKit.Frame({ Parent = panel, Size = UDim2.new(0.94, 0, 0, 30), Position = UDim2.new(0.03, 0, 0, 470) })
	recFrame.BackgroundTransparency = 1
	local recTitle = UIKit.Text(recFrame, "RECORDS", UDim2.new(0.2, 0, 1, 0), Theme.Palette.TextFaint)
	recTitle.TextScaled = false
	recTitle.TextSize = Theme.TypeSize.Small
	recTitle.TextXAlignment = Enum.TextXAlignment.Left
	local recLbl = UIKit.Text(recFrame, "—", UDim2.new(0.78, 0, 1, 0), Theme.Palette.TextDim)
	recLbl.Position = UDim2.new(0.2, 0, 0, 0)
	recLbl.TextScaled = false
	recLbl.TextSize = Theme.TypeSize.Small
	recLbl.TextXAlignment = Enum.TextXAlignment.Left
	self.Store.Records = recLbl

	-- badges wall
	local badgeTitle = UIKit.Text(panel, "BADGES", UDim2.new(0.94, 0, 0, 22), Theme.Palette.TextFaint)
	badgeTitle.Position = UDim2.new(0.03, 0, 0, 512)
	badgeTitle.TextScaled = false
	badgeTitle.TextSize = Theme.TypeSize.Small
	badgeTitle.TextXAlignment = Enum.TextXAlignment.Left
	local badgesWrap = UIKit.Frame({ Parent = panel, Size = UDim2.new(0.94, 0, 0, 66), Position = UDim2.new(0.03, 0, 0, 540) })
	badgesWrap.BackgroundTransparency = 1
	local badgesGrid = Instance.new("UIGridLayout")
	badgesGrid.Parent = badgesWrap
	badgesGrid.CellSize = UDim2.new(0.09, 0, 1, 0)
	badgesGrid.CellPadding = UDim2.new(0.012, 0, 0, 0)
	badgesGrid.FillDirection = Enum.FillDirection.Horizontal
	badgesGrid.HorizontalAlignment = Enum.HorizontalAlignment.Left
	self.Store.BadgesWrap = badgesWrap
	self.Store.BadgeBoxes = {}
	self.Store.BadgeList = {}

	-- titles list
	local titleTitle = UIKit.Text(panel, "TITLES · tap to equip", UDim2.new(0.94, 0, 0, 22), Theme.Palette.TextFaint)
	titleTitle.Position = UDim2.new(0.03, 0, 0, 620)
	titleTitle.TextScaled = false
	titleTitle.TextSize = Theme.TypeSize.Small
	titleTitle.TextXAlignment = Enum.TextXAlignment.Left
	self.Store.TitlesTitle = titleTitle
	local titlesWrap = UIKit.Frame({ Parent = panel, Size = UDim2.new(0.94, 0, 0, 48), Position = UDim2.new(0.03, 0, 0, 646) })
	titlesWrap.BackgroundTransparency = 1
	self.Store.TitlesWrap = titlesWrap

	-- daily claim bar
	local daily = UIKit.PanelAlt(panel, UDim2.new(0.94, 0, 0, 46), Theme.Brand.Gold)
	daily.Position = UDim2.new(0.03, 0, 0, 704)
	daily.BackgroundTransparency = 0.3
	local dailyText = UIKit.Text(daily, "Daily Challenge", UDim2.new(0.5, 0, 1, 0), Theme.Brand.Gold)
	dailyText.Position = UDim2.new(0.04, 0, 0, 0)
	dailyText.TextScaled = false
	dailyText.TextSize = Theme.TypeSize.Body
	dailyText.TextXAlignment = Enum.TextXAlignment.Left
	self.Store.DailyText = dailyText
	local claimBtn = UIKit.Button(daily, "CLAIM", UDim2.new(0.2, 0, 0.64, 0), Theme.Brand.Gold, { textColor = Color3.new(1, 1, 1) })
	claimBtn.AnchorPoint = Vector2.new(1, 0.5)
	claimBtn.Position = UDim2.new(0.97, 0, 0.5, 0)
	claimBtn.TextScaled = false
	claimBtn.TextSize = Theme.TypeSize.Body
	self.Store.DailyClaim = claimBtn
	claimBtn.Activated:Connect(function()
		if Profile.OnClaim then Profile.OnClaim() end
	end)

	local btn = UIKit.GradientButton(panel, "BACK", UDim2.new(0.3, 0, 0, 40), Theme.Brand.Primary)
	btn.AnchorPoint = Vector2.new(0.5, 1)
	btn.Position = UDim2.new(0.5, 0, 1, -8)
	btn.TextScaled = false
	btn.TextSize = Theme.TypeSize.Body
	btn.Activated:Connect(function()
		AudioService.PlayClick()
		if Profile.OnClose then Profile.OnClose() end
	end)
end

function Profile:_buildBadges(list)
	if not self.Store or not self.Store.BadgesWrap then return end
	for _, box in self.Store.BadgeBoxes do
		if box.Parent then box:Destroy() end
	end
	self.Store.BadgeBoxes = {}
	self.Store.BadgeList = list or {}
	for _, b in self.Store.BadgeList do
		local def = nil
		for _, cand in GameConfig.Badges do
			if cand.Id == b then def = cand break end
		end
		local box = UIKit.Panel(self.Store.BadgesWrap, UDim2.fromScale(1, 1), Theme.Palette.Panel)
		if def then
			local icon = UIKit.Text(box, def.Icon, UDim2.new(1, 0, 0.5, 0), Theme.Brand.Gold)
			icon.TextScaled = false
			icon.TextSize = 22
		else
			local icon = UIKit.Text(box, "•", UDim2.new(1, 0, 0.5, 0), Theme.Palette.TextDim)
			icon.TextScaled = false
			icon.TextSize = 18
		end
		local tip = UIKit.Text(box, "★", UDim2.new(1, 0, 0.4, 0), Theme.Palette.TextFaint)
		tip.Position = UDim2.new(0, 0, 0.55, 0)
		tip.TextScaled = false
		tip.TextSize = 10
		box.Name = def and def.Name or b
		table.insert(self.Store.BadgeBoxes, box)
	end
end

function Profile:_buildTitles(list)
	if not self.Store then return end
	self.Store.TitlesList = list or {}
	for _, t in self.Store.TitlesWrap:GetChildren() do
		if not t:IsA("UIGridLayout") and not t:IsA("UIListLayout") and t:IsA("GuiObject") then t:Destroy() end
	end
	local equipped = self.Store.EquippedTitle or ""
	for index, id in self.Store.TitlesList do
		local def = nil
		for _, cand in GameConfig.Titles do
			if cand.Id == id then def = cand break end
		end
		local display = def and def.Name or id
		local tier = def and (Theme.MasteryColor(def.Tier) or Theme.Brand.Secondary) or Theme.Palette.TextDim
		local btn = UIKit.Button(self.Store.TitlesWrap, display, UDim2.new(0.24, 0, 1, 0), (equipped == id) and Theme.Brand.Gold or Theme.Palette.Panel, { textColor = equipped == id and Color3.new(1, 1, 1) or Theme.Palette.Text })
		btn.Position = UDim2.new((index - 1) * 0.25, 4, 0, 0)
		btn.TextScaled = false
		btn.TextSize = Theme.TypeSize.Small
		btn.Activated:Connect(function()
			AudioService.PlayClick()
			if Profile.OnEquipTitle then Profile.OnEquipTitle(id) end
		end)
	end
end

function Profile:SetProfile(data)
	if not self.Store then return end
	if self.Store.Name then self.Store.Name.Text = data.DisplayName or data.Name or "" end
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
	if data.MasteryRank and self.Store.Mastery then
		local rank = data.MasteryRank
		self.Store.Mastery.Text = (rank.Display or rank.Name or "BRONZE"):gsub("\n", "")
		self.Store.Mastery.TextColor3 = Theme.MasteryColor(rank.Id)
	end
	if data.MasteryXp ~= nil and self.Store.MasteryXp then
		self.Store.MasteryXp.Text = ("%d MXP"):format(data.MasteryXp)
	end
	if data.EquippedTitle ~= nil and self.Store.Title then
		local equipped = data.EquippedTitle or ""
		self.Store.EquippedTitle = equipped
		local def = nil
		for _, cand in GameConfig.Titles do
			if cand.Id == equipped then def = cand break end
		end
		self.Store.Title.Text = def and ("《 %s 》"):format(def.Name) or "No title equipped"
		self:_buildTitles(data.Titles or {})
	end
	if data.Records and self.Store.Records then
		local parts = {}
		for id, score in pairs(data.Records) do
			local name = id == "survival" and "Survival: " or (id:gsub("_", " ") .. ": ")
			table.insert(parts, name .. tostring(score))
		end
		table.sort(parts)
		self.Store.Records.Text = #parts > 0 and table.concat(parts, "   ") or "No records yet"
	end
	if data.Badges then
		self:_buildBadges(data.Badges)
	end
end

function Profile:SetDailyClaim(claimed: boolean)
	if self.Store and self.Store.DailyClaim then
		self.Store.DailyClaim.Text = claimed and "CLAIMED" or "CLAIM"
	end
	if self.Store and self.Store.DailyText then
		self.Store.DailyText.Text = claimed and "Daily claimed ✓" or "Daily Challenge"
	end
end

return Profile