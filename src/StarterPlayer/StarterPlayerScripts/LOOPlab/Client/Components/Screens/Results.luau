-- Results: animated end-of-round scoreboard with rewards + progression payload.

local UIKit = require(script.Parent.Parent.UIKit)
local Theme = require(script.Parent.Parent.Theme)
local AudioService = require(script.Parent.Parent.AudioService)
local EffectsService = require(script.Parent.Parent.EffectsService)

local Results = {
	Name = "Results",
	Root = nil,
	Store = {},
	OnClose = nil,
	Mode = nil,
}

local PODIUM_COLORS = { Theme.Brand.Gold, Color3.fromRGB(200, 210, 225), Color3.fromRGB(210, 140, 90) }
local PODIUM_LABELS = { "1ST", "2ND", "3RD" }

function Results:Hide()
	if self.Root then self.Root.Visible = false end
end

function Results:Show(data)
	if not self.Root then return end
	self.Root.Visible = true
	if data then
		self.Mode = data.Mode or "Standalone"
		self:SetResults(data)
	end
	UIKit.SlideUpIn(self.Panel, 0.04, Theme.Motion.Normal)
end

function Results:Build(parent)
	local root = UIKit.Frame({
		Parent = parent,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	})
	self.Root = root

	local scrim = UIKit.Frame({ Parent = root, Size = UDim2.fromScale(1, 1), BackgroundColor3 = Theme.Palette.Scrim, BackgroundTransparency = Theme.Opacity.Scrim })
	scrim.BorderSizePixel = 0
	self.Scrim = scrim

	local panel = UIKit.Card(root, UDim2.new(0.66, 0, 0.84, 0), Theme.Brand.Primary)
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.BackgroundTransparency = Theme.Opacity.Card
	self.Panel = panel

	local header = UIKit.Frame({ Parent = panel, Size = UDim2.new(1, 0, 0, 76), AnchorPoint = Vector2.new(0, 0) })
	header.BackgroundTransparency = 1
	local headerBar = UIKit.Frame({ Parent = header, Size = UDim2.new(1, 0, 0, 3), AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 0, 0), BackgroundColor3 = Theme.Brand.Primary })
	UIKit.Corner(Theme.Radius.Small).Parent = headerBar

	local eyebrow = UIKit.Muted(header, "MATCH RESULTS", UDim2.new(1, -40, 0, 16), Theme.Palette.TextFaint)
	eyebrow.AnchorPoint = Vector2.new(0, 0)
	eyebrow.Position = UDim2.new(0, 24, 0.18, 0)
	eyebrow.TextScaled = false
	eyebrow.TextSize = Theme.TypeSize.Tiny
	eyebrow.TextXAlignment = Enum.TextXAlignment.Left

	local title = UIKit.Title(header, "RESULTS", UDim2.new(1, -40, 0, 42), Theme.Palette.Text)
	title.AnchorPoint = Vector2.new(0, 0)
	title.Position = UDim2.new(0, 24, 0.38, 0)
	title.TextScaled = false
	title.TextSize = Theme.TypeSize.Huge
	title.TextXAlignment = Enum.TextXAlignment.Left

	local modeLbl = UIKit.Chip(header, "STANDALONE", Theme.WithAlpha(Theme.Brand.Primary, 0.18), { textColor = Theme.Brand.Primary, autosize = true })
	modeLbl.AutoButtonColor = false
	modeLbl.Size = UDim2.new(0, 130, 0, 24)
	modeLbl.AnchorPoint = Vector2.new(1, 0.5)
	modeLbl.Position = UDim2.new(1, -24, 0.5, 0)
	self.Store.ModeChip = modeLbl

	local masteryBar = UIKit.Frame({ Parent = panel, Size = UDim2.new(0.94, 0, 0, 30), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 88) })
	masteryBar.BackgroundTransparency = 1

	local rankLbl = UIKit.Text(masteryBar, "MASTERY: BRONZE", UDim2.new(0.5, 0, 1, 0), Theme.MasteryColor("bronze"))
	rankLbl.AnchorPoint = Vector2.new(0, 0)
	rankLbl.Position = UDim2.new(0, 0, 0, 0)
	rankLbl.TextScaled = false
	rankLbl.TextSize = Theme.TypeSize.Small
	rankLbl.TextXAlignment = Enum.TextXAlignment.Left
	self.Store.MasteryRank = rankLbl

	local mxpLbl = UIKit.Text(masteryBar, "0 MXP", UDim2.new(0.5, 0, 1, 0), Theme.Palette.TextDim)
	mxpLbl.AnchorPoint = Vector2.new(1, 0)
	mxpLbl.Position = UDim2.new(1, 0, 0, 0)
	mxpLbl.TextScaled = false
	mxpLbl.TextSize = Theme.TypeSize.Small
	mxpLbl.TextXAlignment = Enum.TextXAlignment.Right
	self.Store.MasteryXp = mxpLbl

	local listWrap = UIKit.Frame({ Parent = panel, Size = UDim2.new(0.94, 0, 0.52, 0), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 132) })
	listWrap.BackgroundTransparency = 1
	self.Store.List = listWrap
	self.Store.Rows = {}
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = listWrap

	local rewards = UIKit.Card(panel, UDim2.new(0.94, 0, 0, 56), Theme.Brand.Gold)
	rewards.AnchorPoint = Vector2.new(0, 1)
	rewards.Position = UDim2.new(0.03, 0, 1, -78)
	rewards.BackgroundTransparency = Theme.Opacity.Card
	local rewardIcon = UIKit.Text(rewards, "★", UDim2.new(0, 30, 0.7, 0), Theme.Brand.Gold)
	rewardIcon.AnchorPoint = Vector2.new(0, 0.5)
	rewardIcon.Position = UDim2.new(0, 16, 0.5, 0)
	rewardIcon.TextScaled = false
	rewardIcon.TextSize = 22
	rewardIcon.TextXAlignment = Enum.TextXAlignment.Center

	local rewardLbl = UIKit.Title(rewards, "REWARDS", UDim2.new(0.3, 0, 0.4, 0), Theme.Palette.TextFaint)
	rewardLbl.AnchorPoint = Vector2.new(0, 0)
	rewardLbl.Position = UDim2.new(0, 56, 0.12, 0)
	rewardLbl.TextScaled = false
	rewardLbl.TextSize = Theme.TypeSize.Tiny
	rewardLbl.TextXAlignment = Enum.TextXAlignment.Left

	local rewardMsg = UIKit.Title(rewards, "", UDim2.new(0.6, 0, 0.6, 0), Theme.Brand.Gold)
	rewardMsg.AnchorPoint = Vector2.new(0, 0)
	rewardMsg.Position = UDim2.new(0, 56, 0.42, 0)
	rewardMsg.TextScaled = false
	rewardMsg.TextSize = Theme.TypeSize.Header
	rewardMsg.TextXAlignment = Enum.TextXAlignment.Left
	self.Store.Rewards = rewardMsg

	local btn = UIKit.GradientButton(panel, "BACK TO HUB", UDim2.new(0.5, 0, 0, 44), Theme.Brand.Success, { rotation = 0, secondary = Theme.Brand.Primary })
	btn.AnchorPoint = Vector2.new(0.5, 1)
	btn.Position = UDim2.new(0.5, 0, 1, -16)
	btn.TextScaled = false
	btn.TextSize = Theme.TypeSize.Body
	btn.Activated:Connect(function()
		AudioService.PlayClick()
		if Results.OnClose then Results.OnClose() end
	end)
end

function Results:SetResults(data)
	if not self.Store then return end
	for _, r in self.Store.Rows do
		if r.Parent then r:Destroy() end
	end
	self.Store.Rows = {}

	if data.Mode and self.Store.ModeChip then
		local isSurvival = data.Mode == "Survival"
		self.Store.ModeChip.Text = isSurvival and "SURVIVAL" or "STANDALONE"
		self.Store.ModeChip.BackgroundColor3 = isSurvival and Theme.WithAlpha(Theme.Accent("survival"), 0.18) or Theme.WithAlpha(Theme.Brand.Primary, 0.18)
		self.Store.ModeChip.TextColor3 = isSurvival and Theme.Accent("survival") or Theme.Brand.Primary
	end

	local progression = data.Progression or data.Rewards or {}
	if progression.MasteryRank and self.Store.MasteryRank then
		local rank = progression.MasteryRank
		self.Store.MasteryRank.Text = ("MASTERY: %s"):format((rank.Display or rank.Name or "BRONZE"):gsub("\n", ""))
		self.Store.MasteryRank.TextColor3 = Theme.MasteryColor(rank.Id or "bronze")
	end
	if progression.MasteryXp ~= nil and self.Store.MasteryXp then
		self.Store.MasteryXp.Text = ("%d MXP"):format(progression.MasteryXp)
	end

	local rows = data.Rows or {}
	for i, row in rows do
		local isPodium = i <= 3
		local podiumColor = isPodium and PODIUM_COLORS[i] or Theme.Palette.PanelAlt
		local rowFrame = UIKit.Frame({ Parent = self.Store.List, Size = UDim2.new(1, 0, 0, isPodium and 44 or 36), BackgroundColor3 = podiumColor })
		UIKit.Corner(Theme.Radius.Medium).Parent = rowFrame
		if isPodium then
			UIKit.Stroke(podiumColor, 1, Theme.Opacity.Solid).Parent = rowFrame
		else
			UIKit.Stroke(Theme.Palette.StrokeDim, 1, Theme.Opacity.Subtle).Parent = rowFrame
		end
		rowFrame.BackgroundTransparency = isPodium and Theme.Opacity.Card or 0
		rowFrame.LayoutOrder = i

		local placeBg = UIKit.Frame({ Parent = rowFrame, Size = UDim2.new(0, 36, 0, 28), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 6, 0.5, 0), BackgroundColor3 = isPodium and podiumColor or Theme.Palette.Panel })
		UIKit.Corner(Theme.Radius.Small).Parent = placeBg
		local place = UIKit.Text(placeBg, isPodium and PODIUM_LABELS[i] or tostring(i), UDim2.fromScale(1, 1), Theme.Palette.Text)
		place.AnchorPoint = Vector2.new(0.5, 0.5)
		place.Position = UDim2.fromScale(0.5, 0.5)
		place.TextScaled = false
		place.TextSize = isPodium and Theme.TypeSize.Small or Theme.TypeSize.Tiny
		if not isPodium then place.TextColor3 = Theme.Palette.TextDim end

		local p = row.Player
		local name = type(row.Name) == "string" and row.Name
			or (p and p.DisplayName)
			or ("Player " .. tostring(row.UserId or (p and p.UserId) or "?"))
		local nm = UIKit.Text(rowFrame, name, UDim2.new(0.6, 0, 1, 0), Theme.Palette.Text)
		nm.AnchorPoint = Vector2.new(0, 0.5)
		nm.Position = UDim2.new(0, 52, 0.5, 0)
		nm.TextScaled = false
		nm.TextSize = isPodium and Theme.TypeSize.Body or Theme.TypeSize.Small
		nm.TextXAlignment = Enum.TextXAlignment.Left

		local sc = UIKit.Title(rowFrame, tostring(row.Score or 0), UDim2.new(0.18, 0, 1, 0), isPodium and Theme.Brand.Gold or Theme.Palette.Text)
		sc.AnchorPoint = Vector2.new(1, 0.5)
		sc.Position = UDim2.new(0.98, 0, 0.5, 0)
		sc.TextScaled = false
		sc.TextSize = isPodium and Theme.TypeSize.Title or Theme.TypeSize.Body
		sc.TextXAlignment = Enum.TextXAlignment.Right
		self.Store.Rows[i] = rowFrame

		rowFrame.BackgroundTransparency = 1
		rowFrame.Position = UDim2.new(0, -20, 0, 0)
		task.delay((i - 1) * 0.06, function()
			if not rowFrame.Parent then return end
			local targetTransparency = isPodium and Theme.Opacity.Card or 0
			UIKit.Tween(rowFrame, { BackgroundTransparency = targetTransparency, Position = UDim2.new(0, 0, 0, 0) }, Theme.Motion.Quick, Enum.EasingStyle.Back):Play()
		end)
	end

	if data.Rewards then
		local granted = data.Rewards.Granted or {}
		local xp = granted.Xp or 0
		local coins = granted.Coins or 0
		self.Store.Rewards.Text = ("+%d XP   +%d Coins"):format(xp, coins)
	else
		self.Store.Rewards.Text = "No rewards"
	end
end

return Results
