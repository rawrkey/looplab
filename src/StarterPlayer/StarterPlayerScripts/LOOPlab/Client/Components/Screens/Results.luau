-- Results: animated end-of-round scoreboard with rewards.

local UIKit = require(script.Parent.Parent.UIKit)
local Theme = require(script.Parent.Parent.Theme)
local AudioService = require(script.Parent.Parent.AudioService)

local Results = {
	Name = "Results",
	Root = nil,
	Store = {},
	OnClose = nil,
}

function Results:Hide()
	if self.Root then self.Root.Visible = false end
end

function Results:Show(data)
	if not self.Root then return end
	self.Root.Visible = true
	if data then self:SetResults(data) end
	UIKit.SlideIn(self.Panel, 0.03, Theme.Motion.Normal)
	AudioService.PlayScore()
end

function Results:Build(parent)
	local root = UIKit.Frame({
		Parent = parent,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	})
	self.Root = root

	local scrim = UIKit.Frame({ Parent = root, Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.5, BorderSizePixel = 0 })
	self.Scrim = scrim

	local panel = UIKit.PanelAlt(root, UDim2.new(0.6, 0, 0.76, 0), Theme.Brand.Primary)
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	self.Panel = panel

	local title = UIKit.Title(panel, "RESULTS", UDim2.new(1, 0, 0, 52), Theme.Brand.Primary)
	title.TextScaled = false
	title.TextSize = Theme.TypeSize.Huge

	local list = UIKit.Frame({ Parent = panel, Size = UDim2.new(0.94, 0, 0.62, 0), Position = UDim2.new(0.03, 0, 0, 58) })
	list.BackgroundTransparency = 1
	UIKit.Corner(Theme.Radius.Medium).Parent = list
	self.Store.List = list
	self.Store.Rows = {}
	local layout = Instance.new("UIListLayout")
	layout.Parent = list
	layout.Padding = UDim.new(0, 5)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

	local rewards = UIKit.Panel(panel, UDim2.new(0.94, 0, 0, 44), Theme.Palette.Panel)
	rewards.AnchorPoint = Vector2.new(0, 1)
	rewards.Position = UDim2.new(0.03, 0, 1, -62)
	local rewardMsg = UIKit.Text(rewards, "", UDim2.fromScale(1, 1), Theme.Brand.Gold)
	rewardMsg.TextScaled = false
	rewardMsg.TextSize = Theme.TypeSize.Header
	self.Store.Rewards = rewardMsg

	local btn = UIKit.GradientButton(panel, "BACK TO HUB", UDim2.new(0.6, 0, 0, 44), Theme.Brand.Success)
	btn.AnchorPoint = Vector2.new(0.5, 1)
	btn.Position = UDim2.new(0.5, 0, 1, -10)
	btn.TextScaled = false
	btn.TextSize = Theme.TypeSize.Body
	btn.Activated:Connect(function()
		if Results.OnClose then Results.OnClose() end
	end)
end

local PODIUM_COLORS = { Theme.Brand.Gold, Color3.fromRGB(200, 210, 225), Color3.fromRGB(210, 140, 90) }

function Results:SetResults(data)
	if not self.Store then return end
	for _, r in self.Store.Rows do
		if r.Parent then r:Destroy() end
	end
	self.Store.Rows = {}
	local rows = data.Rows or {}
	for i, row in rows do
		local p = row.Player
		local name = type(row.Name) == "string" and row.Name
			or (p and p.DisplayName)
			or ("Player " .. tostring(row.UserId or (p and p.UserId) or "?"))
		local score = row.Score or 0
		local rowFrame = UIKit.Frame({ Parent = self.Store.List, Size = UDim2.new(1, 0, 0, 34) })
		rowFrame.BackgroundColor3 = (i <= 3 and PODIUM_COLORS[i]) or Theme.Palette.PanelAlt
		rowFrame.BackgroundTransparency = (i <= 3) and 0.15 or 0
		UIKit.Corner(Theme.Radius.Medium).Parent = rowFrame

		local place = UIKit.Text(rowFrame, ("%d."):format(i), UDim2.fromOffset(40, 34), Theme.Palette.Text)
		place.TextScaled = false
		place.TextSize = Theme.TypeSize.Body
		local nm = UIKit.Text(rowFrame, name, UDim2.new(0.6, 0, 1, 0), Theme.Palette.Text)
		nm.Position = UDim2.fromOffset(40, 0)
		nm.TextScaled = false
		nm.TextSize = Theme.TypeSize.Body
		local sc = UIKit.Text(rowFrame, tostring(score), UDim2.new(0.2, 0, 1, 0), (i <= 3) and Theme.Brand.Gold or Theme.Palette.Text)
		sc.Position = UDim2.new(0.8, 0, 0, 0)
		sc.TextScaled = false
		sc.TextSize = Theme.TypeSize.Body
		table.insert(self.Store.Rows, rowFrame)

		rowFrame.BackgroundTransparency = 1
		rowFrame.Position = UDim2.new(0, -40, 0, 0)
		UIKit.Tween(rowFrame, { BackgroundTransparency = 0, Position = UDim2.new(0, 0, 0, 0) }, Theme.Motion.Quick, Enum.EasingStyle.Back):Play()
	end

	if data.Rewards then
		local xp = data.Rewards.Xp or 0
		local coins = data.Rewards.Coins or 0
		self.Store.Rewards.Text = ("REWARDS  +%d XP   +%d Coins"):format(xp, coins)
	else
		self.Store.Rewards.Text = ""
	end
end

return Results