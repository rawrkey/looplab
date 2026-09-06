-- Profile: character overview, mastery rank, stats grid, title showcase + equip,
-- badge wall, records, daily claim. Redesigned for the progression phase.

local UIKit = require(script.Parent.Parent.UIKit)
local Theme = require(script.Parent.Parent.Theme)
local AudioService = require(script.Parent.Parent.AudioService)
local Players = game:GetService("Players")
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
	{ key = "SurvivalMatches", label = "Surv.", icon = "♛" },
	{ key = "SurvivalWins", label = "S. Wins", icon = "☠" },
	{ key = "CoinsEarned", label = "Coins", icon = "◉" },
	{ key = "DailiesClaimed", label = "Dailies", icon = "✎" },
}

function Profile:Hide()
	if self.Root then self.Root.Visible = false end
end

function Profile:Show(data)
	if not self.Root then return end
	self.Root.Visible = true
	if data then self:SetProfile(data) end
	UIKit.SlideUpIn(self.Panel, 0.04, Theme.Motion.Normal)
end

function Profile:Build(parent)
	local root = UIKit.Frame({
		Parent = parent,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	})
	self.Root = root

	local scrim = UIKit.Frame({ Parent = root, Size = UDim2.fromScale(1, 1), BackgroundColor3 = Theme.Palette.Scrim, BackgroundTransparency = Theme.Opacity.Scrim })
	scrim.BorderSizePixel = 0

	local panel = UIKit.Card(root, UDim2.new(0.78, 0, 0.88, 0), Theme.Brand.Primary)
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.BackgroundTransparency = Theme.Opacity.Card
	self.Panel = panel

	local edge = UIKit.Frame({ Parent = panel, Size = UDim2.new(1, 0, 0, 3), AnchorPoint = Vector2.new(0, 0), BackgroundColor3 = Theme.Brand.Primary })
	UIKit.Corner(Theme.Radius.Small).Parent = edge

	local title = UIKit.Title(panel, "PROFILE", UDim2.new(0.96, 0, 0, 36), Theme.Palette.Text)
	title.AnchorPoint = Vector2.new(0, 0)
	title.Position = UDim2.new(0.02, 0, 0.04, 0)
	title.TextScaled = false
	title.TextSize = Theme.TypeSize.Huge
	title.TextXAlignment = Enum.TextXAlignment.Left

	local close = UIKit.Button(panel, "✕", UDim2.fromOffset(34, 34), Theme.Palette.PanelAlt, { textColor = Theme.Palette.TextDim })
	close.AnchorPoint = Vector2.new(1, 0)
	close.Position = UDim2.new(0.98, 0, 0.04, 0)
	close.TextScaled = false
	close.TextSize = Theme.TypeSize.Small
	close.Activated:Connect(function()
		AudioService.PlayClick()
		if Profile.OnClose then Profile.OnClose() end
	end)

	local identity = UIKit.Card(panel, UDim2.new(0.96, 0, 0, 96), Theme.MasteryColor("gold"))
	identity.AnchorPoint = Vector2.new(0.5, 0)
	identity.Position = UDim2.new(0.5, 0, 0.13, 0)
	identity.BackgroundTransparency = Theme.Opacity.Card
	local edge2 = UIKit.Frame({ Parent = identity, Size = UDim2.new(1, 0, 0, 3), AnchorPoint = Vector2.new(0, 0), BackgroundColor3 = Theme.MasteryColor("gold") })
	UIKit.Corner(Theme.Radius.Small).Parent = edge2
	self.Store.IdentityEdge = edge2

	local avatarRing = UIKit.Frame({ Parent = identity, Size = UDim2.fromOffset(72, 72), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0.02, 0, 0.5, 0), BackgroundColor3 = Theme.Palette.PanelAlt })
	UIKit.Corner(Theme.Radius.Pill).Parent = avatarRing
	UIKit.Stroke(Theme.MasteryColor("gold"), 1, Theme.Opacity.Subtle).Parent = avatarRing
	self.Store.AvatarRingCross = avatarRing:FindFirstChildOfClass("UIStroke")
	local avatar = Instance.new("ImageLabel")
	avatar.Size = UDim2.fromScale(1, 1)
	avatar.BackgroundTransparency = 1
	avatar.Parent = avatarRing
	self.Store.Avatar = avatar
	self:_RefreshAvatar()

	local idCol = UIKit.Frame({ Parent = identity, Size = UDim2.new(0.7, 0, 1, 0), AnchorPoint = Vector2.new(0, 0), Position = UDim2.new(0.16, 0, 0, 0) })
	idCol.BackgroundTransparency = 1
	local name = UIKit.Title(idCol, "", UDim2.new(1, 0, 0, 28), Theme.Palette.Text)
	name.AnchorPoint = Vector2.new(0, 0)
	name.Position = UDim2.new(0, 0, 0.12, 0)
	name.TextScaled = false
	name.TextSize = Theme.TypeSize.Title
	name.TextXAlignment = Enum.TextXAlignment.Left
	self.Store.Name = name

	local pLevel = UIKit.Muted(idCol, "Level 1", UDim2.new(1, 0, 0, 18), Theme.Palette.TextDim)
	pLevel.AnchorPoint = Vector2.new(0, 0)
	pLevel.Position = UDim2.new(0, 0, 0.45, 0)
	pLevel.TextScaled = false
	pLevel.TextSize = Theme.TypeSize.Small
	pLevel.TextXAlignment = Enum.TextXAlignment.Left
	self.Store.Level = pLevel

	local titleLbl = UIKit.Muted(idCol, "No title equipped", UDim2.new(1, 0, 0, 18), Theme.Brand.Gold)
	titleLbl.AnchorPoint = Vector2.new(0, 0)
	titleLbl.Position = UDim2.new(0, 0, 0.68, 0)
	titleLbl.TextScaled = false
	titleLbl.TextSize = Theme.TypeSize.Small
	titleLbl.TextXAlignment = Enum.TextXAlignment.Left
	self.Store.Title = titleLbl

	local masteryBadge = UIKit.Frame({ Parent = identity, Size = UDim2.new(0.18, 0, 0.7, 0), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(0.98, 0, 0.5, 0), BackgroundColor3 = Theme.WithAlpha(Theme.MasteryColor("gold"), 0.18) })
	UIKit.Corner(Theme.Radius.Medium).Parent = masteryBadge
	UIKit.Stroke(Theme.MasteryColor("gold"), 1, Theme.Opacity.Subtle).Parent = masteryBadge
	local masterLbl = UIKit.Title(masteryBadge, "BRONZE", UDim2.new(1, 0, 0, 22), Theme.MasteryColor("gold"))
	masterLbl.AnchorPoint = Vector2.new(0.5, 0)
	masterLbl.Position = UDim2.new(0.5, 0, 0.18, 0)
	masterLbl.TextScaled = false
	masterLbl.TextSize = Theme.TypeSize.Header
	self.Store.Mastery = masterLbl
	local mxp = UIKit.Muted(masteryBadge, "0 MXP", UDim2.new(1, 0, 0, 14), Theme.Palette.TextDim)
	mxp.AnchorPoint = Vector2.new(0.5, 1)
	mxp.Position = UDim2.new(0.5, 0, 0.82, 0)
	mxp.TextScaled = false
	mxp.TextSize = Theme.TypeSize.Tiny
	self.Store.MasteryXp = mxp

	local sectionLabel = UIKit.SectionLabel(panel, "STATS", UDim2.new(0.96, 0, 0, 18))
	sectionLabel.AnchorPoint = Vector2.new(0, 0)
	sectionLabel.Position = UDim2.new(0.02, 0, 0.32, 0)

	local statsWrap = UIKit.Frame({ Parent = panel, Size = UDim2.new(0.96, 0, 0, 76), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.36, 0) })
	statsWrap.BackgroundTransparency = 1
	self.Store.StatBoxes = {}
	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.new(0.155, 0, 1, 0)
	grid.CellPadding = UDim2.new(0.01, 0, 0, 0)
	grid.FillDirection = Enum.FillDirection.Horizontal
	grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
	grid.VerticalAlignment = Enum.VerticalAlignment.Center
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = statsWrap

	for order, s in STATS do
		local box = UIKit.StatBox(statsWrap, UDim2.fromScale(1, 1), s.label, "0", s.icon, Theme.Brand.Primary)
		box.LayoutOrder = order
		box.BackgroundTransparency = Theme.Opacity.Card
		self.Store.StatBoxes[order] = box
	end

	local recLabel = UIKit.SectionLabel(panel, "PERSONAL RECORDS", UDim2.new(0.96, 0, 0, 18))
	recLabel.AnchorPoint = Vector2.new(0, 0)
	recLabel.Position = UDim2.new(0.02, 0, 0.48, 0)

	local recFrame = UIKit.Card(panel, UDim2.new(0.96, 0, 0, 56), Theme.Palette.StrokeDim)
	recFrame.AnchorPoint = Vector2.new(0.5, 0)
	recFrame.Position = UDim2.new(0.5, 0, 0.52, 0)
	recFrame.BackgroundTransparency = Theme.Opacity.Card
	local recLbl = UIKit.Text(recFrame, "No records yet", UDim2.new(0.96, 0, 1, 0), Theme.Palette.TextDim)
	recLbl.AnchorPoint = Vector2.new(0.5, 0.5)
	recLbl.Position = UDim2.new(0.5, 0, 0.5, 0)
	recLbl.TextScaled = false
	recLbl.TextSize = Theme.TypeSize.Small
	recLbl.TextXAlignment = Enum.TextXAlignment.Left
	recLbl.TextWrapped = true
	self.Store.Records = recLbl

	local badgeLabel = UIKit.SectionLabel(panel, "BADGES", UDim2.new(0.96, 0, 0, 18))
	badgeLabel.AnchorPoint = Vector2.new(0, 0)
	badgeLabel.Position = UDim2.new(0.02, 0, 0.62, 0)

	local badgesWrap = UIKit.Frame({ Parent = panel, Size = UDim2.new(0.96, 0, 0, 76), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.66, 0) })
	badgesWrap.BackgroundTransparency = 1
	self.Store.BadgesWrap = badgesWrap
	self.Store.BadgeBoxes = {}
	self.Store.BadgeList = {}
	local badgesGrid = Instance.new("UIGridLayout")
	badgesGrid.CellSize = UDim2.new(0.09, 0, 1, 0)
	badgesGrid.CellPadding = UDim2.new(0.012, 0, 0, 0)
	badgesGrid.FillDirection = Enum.FillDirection.Horizontal
	badgesGrid.HorizontalAlignment = Enum.HorizontalAlignment.Left
	badgesGrid.SortOrder = Enum.SortOrder.LayoutOrder
	badgesGrid.Parent = badgesWrap

	local titlesLabel = UIKit.SectionLabel(panel, "TITLES · tap to equip", UDim2.new(0.96, 0, 0, 18))
	titlesLabel.AnchorPoint = Vector2.new(0, 0)
	titlesLabel.Position = UDim2.new(0.02, 0, 0.78, 0)
	self.Store.TitlesTitle = titlesLabel

	local titlesWrap = UIKit.Frame({ Parent = panel, Size = UDim2.new(0.96, 0, 0, 40), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.82, 0) })
	titlesWrap.BackgroundTransparency = 1
	self.Store.TitlesWrap = titlesWrap

	local dailyBar = UIKit.Card(panel, UDim2.new(0.96, 0, 0, 44), Theme.Brand.Gold)
	dailyBar.AnchorPoint = Vector2.new(0.5, 0)
	dailyBar.Position = UDim2.new(0.5, 0, 0.92, 0)
	dailyBar.BackgroundTransparency = Theme.Opacity.Card
	local dailyText = UIKit.Muted(dailyBar, "Daily Challenge", UDim2.new(0.66, 0, 1, 0), Theme.Brand.Gold)
	dailyText.AnchorPoint = Vector2.new(0, 0.5)
	dailyText.Position = UDim2.new(0.04, 0, 0.5, 0)
	dailyText.TextScaled = false
	dailyText.TextSize = Theme.TypeSize.Body
	dailyText.TextXAlignment = Enum.TextXAlignment.Left
	self.Store.DailyText = dailyText
	local claimBtn = UIKit.Button(dailyBar, "CLAIM", UDim2.new(0.24, 0, 0.7, 0), Theme.Brand.Gold, { textColor = Color3.new(1, 1, 1) })
	claimBtn.AnchorPoint = Vector2.new(1, 0.5)
	claimBtn.Position = UDim2.new(0.97, 0, 0.5, 0)
	claimBtn.TextScaled = false
	claimBtn.TextSize = Theme.TypeSize.Small
	self.Store.DailyClaim = claimBtn
	claimBtn.Activated:Connect(function()
		if Profile.OnClaim then Profile.OnClaim() end
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
		local box = UIKit.Frame({ Parent = self.Store.BadgesWrap, BackgroundColor3 = Theme.WithAlpha(Theme.Brand.Gold, 0.18) })
		UIKit.Corner(Theme.Radius.Medium).Parent = box
		UIKit.Stroke(Theme.Brand.Gold, 1, Theme.Opacity.Subtle).Parent = box
		box.BackgroundTransparency = Theme.Opacity.Card
		if def then
			local icon = UIKit.Text(box, def.Icon, UDim2.new(1, 0, 0.55, 0), Theme.Brand.Gold)
			icon.AnchorPoint = Vector2.new(0.5, 0)
			icon.Position = UDim2.new(0.5, 0, 0.05, 0)
			icon.TextScaled = false
			icon.TextSize = 22
			local name = UIKit.Muted(box, def.Name, UDim2.new(0.92, 0, 0.35, 0), Theme.Palette.Text)
			name.AnchorPoint = Vector2.new(0.5, 1)
			name.Position = UDim2.new(0.5, 0, 0.95, 0)
			name.TextScaled = false
			name.TextSize = Theme.TypeSize.Micro
		else
			local icon = UIKit.Text(box, "•", UDim2.new(1, 0, 0.55, 0), Theme.Palette.TextDim)
			icon.AnchorPoint = Vector2.new(0.5, 0)
			icon.Position = UDim2.new(0.5, 0, 0.05, 0)
			icon.TextScaled = false
			icon.TextSize = 18
		end
		box.Name = def and def.Name or b
		table.insert(self.Store.BadgeBoxes, box)
	end
end

function Profile:_buildTitles(list)
	if not self.Store then return end
	for _, c in self.Store.TitlesWrap:GetChildren() do
		if c:IsA("GuiObject") then c:Destroy() end
	end
	local equipped = self.Store.EquippedTitle or ""
	for index, id in (list or {}) do
		local def = nil
		for _, cand in GameConfig.Titles do
			if cand.Id == id then def = cand break end
		end
		local display = def and def.Name or id
		local tier = def and Theme.MasteryColor(def.Tier) or Theme.Brand.Secondary
		local isEquipped = (equipped == id)
		local btn = UIKit.Button(self.Store.TitlesWrap, display, UDim2.new(0, 120, 0, 36), isEquipped and tier or Theme.Palette.PanelAlt, { textColor = isEquipped and Color3.new(1, 1, 1) or Theme.Palette.Text })
		btn.Position = UDim2.new(0, 8 + (index - 1) * 128, 0, 2)
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
		if key and stats[key] ~= nil and box then
			local v = box:FindFirstChild("Value")
			if v then v.Text = tostring(stats[key]) end
		end
	end
	if data.MasteryRank and self.Store.Mastery then
		local rank = data.MasteryRank
		local rankColor = Theme.MasteryColor(rank.Id or "gold")
		self.Store.Mastery.Text = (rank.Display or rank.Name or "BRONZE"):gsub("\n", "")
		self.Store.Mastery.TextColor3 = rankColor
		-- Signature identity accents follow the player's actual mastery color.
		if self.Store.IdentityEdge then self.Store.IdentityEdge.BackgroundColor3 = rankColor end
		if self.Store.AvatarRingCross then self.Store.AvatarRingCross.Color = rankColor end
	end
	if data.MasteryXp ~= nil and self.Store.MasteryXp then
		self.Store.MasteryXp.Text = ("%d MXP"):format(data.MasteryXp)
	end
	if data.EquippedTitle ~= nil then
		local equipped = data.EquippedTitle or ""
		self.Store.EquippedTitle = equipped
		local def = nil
		for _, cand in GameConfig.Titles do
			if cand.Id == equipped then def = cand break end
		end
		if self.Store.Title then
			self.Store.Title.Text = def and ("《 %s 》"):format(def.Name) or "No title equipped"
		end
		self:_buildTitles(data.Titles or {})
	end
	if data.Records and self.Store.Records then
		local parts = {}
		for id, score in pairs(data.Records) do
			local name = id == "survival" and "Survival" or (id:gsub("_", " "):gsub("^%l", string.upper))
			table.insert(parts, name .. " " .. tostring(score))
		end
		table.sort(parts)
		self.Store.Records.Text = #parts > 0 and table.concat(parts, "   ·   ") or "No records yet"
	end
	if data.Badges then
		self:_buildBadges(data.Badges)
	end
end

local function describeObjective(objective)
	if not objective then return "Complete an activity" end
	local kind = objective.Kind
	local min = objective.Min or 1
	if kind == "win" then
		return ("Win %s match%s"):format(min == 1 and "a" or tostring(min), min == 1 and "" or "es")
	elseif kind == "best_score" then
		return ("Score %s points"):format(tostring(min))
	end
	return ("Complete %s activit%s"):format(tostring(min), min == 1 and "y" or "ies")
end

function Profile:SetDaily(daily)
	local claimed = daily and daily.Claimed == true
	if self.Store and self.Store.DailyClaim then
		self.Store.DailyClaim.Text = claimed and "CLAIMED" or "CLAIM"
	end
	if self.Store and self.Store.DailyText then
		if claimed then
			self.Store.DailyText.Text = "Daily claimed ✓"
		else
			local reward = GameConfig.Rewards.DailyChallenge
			local desc = describeObjective(daily and daily.Objective)
			local progress = daily and daily.Progress or 0
			local min = (daily and daily.Objective and daily.Objective.Min) or 1
			self.Store.DailyText.Text = ("%s (%d/%d) · +%d XP"):format(desc, progress, min, reward and reward.Xp or 0)
		end
	end
end

function Profile:_RefreshAvatar()
	if not self.Store or not self.Store.Avatar then return end
	local localPlayer = Players.LocalPlayer
	if not localPlayer then return end
	local ok, content = pcall(function()
		return Players:GetUserThumbnailAsync(
			localPlayer.UserId,
			Enum.ThumbnailType.HeadShot,
			Enum.ThumbnailSize.Size150x150
		)
	end)
	if ok and content then
		self.Store.Avatar.Image = content
	else
		self.Store.Avatar.Image = ""
	end
end

return Profile
