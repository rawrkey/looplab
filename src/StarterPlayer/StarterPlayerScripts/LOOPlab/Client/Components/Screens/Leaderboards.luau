-- Leaderboards: tabbed per-activity standings with podium highlight.

local UIKit = require(script.Parent.Parent.UIKit)
local Theme = require(script.Parent.Parent.Theme)

local Leaderboards = {
	Name = "Leaderboards",
	Root = nil,
	Store = {},
	OnFetch = nil,
	OnClose = nil,
	selected = "chaos_run",
}

local BOARDS = {
	{ id = "chaos_run", label = "Chaos Run", accent = Theme.Brand.Primary },
	{ id = "dodge_lab", label = "Dodge Lab", accent = Theme.Brand.Danger },
	{ id = "build_blitz", label = "Build Blitz", accent = Theme.Brand.Warning },
	{ id = "sequence_sprint", label = "Sequence Sprint", accent = Theme.Brand.Secondary },
	{ id = "survival", label = "Survival", accent = Theme.Accent("survival") },
}

function Leaderboards:Hide()
	if self.Root then self.Root.Visible = false end
end

function Leaderboards:Show()
	if not self.Root then return end
	self.Root.Visible = true
	self:Select(self.selected)
	UIKit.SlideIn(self.Panel, 0.03, Theme.Motion.Normal)
end

function Leaderboards:Build(parent)
	local root = UIKit.Frame({
		Parent = parent,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	})
	self.Root = root

	local scrim = UIKit.Frame({ Parent = root, Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.5, BorderSizePixel = 0 })

	local panel = UIKit.PanelAlt(root, UDim2.new(0.64, 0, 0.8, 0), Theme.Brand.Primary)
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	self.Panel = panel

	local title = UIKit.Title(panel, "LEADERBOARDS", UDim2.new(1, 0, 0, 52), Theme.Brand.Primary)
	title.TextScaled = false
	title.TextSize = Theme.TypeSize.Huge

	local tabs = UIKit.Frame({ Parent = panel, Size = UDim2.new(0.96, 0, 0, 40), Position = UDim2.new(0.02, 0, 0, 56) })
	tabs.BackgroundTransparency = 1
	self.Store.Tabs = {}
	for i, b in BOARDS do
		local tab = UIKit.Button(tabs, b.label, UDim2.new(0.19, 0, 1, 0), Theme.Palette.Panel, { textColor = Theme.Palette.TextDim })
		tab.Position = UDim2.new((i - 1) * 0.198, 0, 0, 0)
		tab.TextScaled = false
		tab.TextSize = Theme.TypeSize.Small
		tab.Name = b.id
		tab.Activated:Connect(function()
			Leaderboards:Select(b.id)
		end)
		self.Store.Tabs[i] = { btn = tab, accent = b.accent }
	end

	local list = UIKit.Frame({ Parent = panel, Size = UDim2.new(0.96, 0, 0.64, 0), Position = UDim2.new(0.02, 0, 0, 104) })
	list.BackgroundTransparency = 1
	self.Store.List = list
	self.Store.Rows = {}
	local layout = Instance.new("UIListLayout")
	layout.Parent = list
	layout.Padding = UDim.new(0, 4)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

	local btn = UIKit.GradientButton(panel, "BACK", UDim2.new(0.4, 0, 0, 42), Theme.Brand.Primary)
	btn.AnchorPoint = Vector2.new(0.5, 1)
	btn.Position = UDim2.new(0.5, 0, 1, -10)
	btn.TextScaled = false
	btn.TextSize = Theme.TypeSize.Body
	btn.Activated:Connect(function()
		if Leaderboards.OnClose then Leaderboards.OnClose() end
	end)
end

function Leaderboards:Select(id)
	self.selected = id
	if self.Store and self.Store.Tabs then
		for _, t in self.Store.Tabs do
			local active = t.btn.Name == id
			t.btn.BackgroundColor3 = active and t.accent or Theme.Palette.Panel
			t.btn.TextColor3 = active and Color3.new(1, 1, 1) or Theme.Palette.TextDim
		end
	end
	if self.OnFetch then
		self.OnFetch(id)
	end
end

function Leaderboards:SetEntries(entries)
	if not self.Store then return end
	for _, r in self.Store.Rows do
		if r.Parent then r:Destroy() end
	end
	self.Store.Rows = {}
	local accent = Theme.Brand.Primary
	for _, b in BOARDS do
		if b.id == self.selected then accent = b.accent end
	end
	for i, e in entries do
		local placeColor = i == 1 and Theme.Brand.Gold or (i == 2 and Color3.fromRGB(210, 215, 225) or (i == 3 and Color3.fromRGB(220, 150, 95) or Theme.Palette.TextDim))
		local row = UIKit.Frame({ Parent = self.Store.List, Size = UDim2.new(1, 0, 0, 30) })
		row.BackgroundColor3 = Theme.Palette.PanelAlt
		row.BackgroundTransparency = 0.4
		UIKit.Corner(Theme.Radius.Small).Parent = row

		local place = UIKit.Text(row, ("%d."):format(i), UDim2.fromOffset(36, 30), placeColor)
		place.TextScaled = false
		place.TextSize = Theme.TypeSize.Body
		local name = UIKit.Text(row, ("Player %d"):format(e.UserId), UDim2.new(0.6, 0, 1, 0), Theme.Palette.Text)
		name.Position = UDim2.fromOffset(36, 0)
		name.TextScaled = false
		name.TextSize = Theme.TypeSize.Body
		local score = UIKit.Text(row, tostring(e.Score or 0), UDim2.new(0.2, 0, 1, 0), accent)
		score.Position = UDim2.new(0.8, 0, 0, 0)
		score.TextScaled = false
		score.TextSize = Theme.TypeSize.Body
		table.insert(self.Store.Rows, row)
	end
end

return Leaderboards