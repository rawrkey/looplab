-- Leaderboards: tabbed per-activity standings with podium highlight.

local UIKit = require(script.Parent.Parent.UIKit)
local Theme = require(script.Parent.Parent.Theme)
local Players = game:GetService("Players")

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
	{ id = "sequence_sprint", label = "Sequence", accent = Theme.Brand.Secondary },
	{ id = "survival", label = "Survival", accent = Theme.Accent("survival") },
}

local PODIUM_COLORS = { Theme.Brand.Gold, Color3.fromRGB(200, 210, 225), Color3.fromRGB(210, 140, 90) }
local PODIUM_LABELS = { "1ST", "2ND", "3RD" }

function Leaderboards:Hide()
	if self.Root then self.Root.Visible = false end
end

function Leaderboards:Show()
	if not self.Root then return end
	self.Root.Visible = true
	self:Select(self.selected)
	UIKit.SlideUpIn(self.Panel, 0.04, Theme.Motion.Normal)
end

function Leaderboards:Build(parent)
	local root = UIKit.Frame({
		Parent = parent,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	})
	self.Root = root

	local scrim = UIKit.Frame({ Parent = root, Size = UDim2.fromScale(1, 1), BackgroundColor3 = Theme.Palette.Scrim, BackgroundTransparency = Theme.Opacity.Scrim })
	scrim.BorderSizePixel = 0

	local panel = UIKit.Card(root, UDim2.new(0.7, 0, 0.84, 0), Theme.Brand.Primary)
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.BackgroundTransparency = Theme.Opacity.Card
	self.Panel = panel

	local edge = UIKit.Frame({ Parent = panel, Size = UDim2.new(1, 0, 0, 3), AnchorPoint = Vector2.new(0, 0), BackgroundColor3 = Theme.Brand.Primary })
	UIKit.Corner(Theme.Radius.Small).Parent = edge

	local title = UIKit.Title(panel, "LEADERBOARDS", UDim2.new(0.96, 0, 0, 36), Theme.Palette.Text)
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
		if Leaderboards.OnClose then Leaderboards.OnClose() end
	end)

	local tabs = UIKit.Frame({ Parent = panel, Size = UDim2.new(0.96, 0, 0, 36), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.12, 0) })
	tabs.BackgroundTransparency = 1
	self.Store.Tabs = {}
	for i, b in BOARDS do
		local tab = UIKit.Button(tabs, b.label, UDim2.new(0.19, 0, 1, 0), Theme.Palette.PanelAlt, { textColor = Theme.Palette.TextDim })
		tab.Position = UDim2.new((i - 1) * 0.198, 0, 0, 0)
		tab.TextScaled = false
		tab.TextSize = Theme.TypeSize.Small
		tab.Name = b.id
		tab.Activated:Connect(function()
			Leaderboards:Select(b.id)
		end)
		self.Store.Tabs[i] = { btn = tab, accent = b.accent }
	end

	local list = UIKit.Frame({ Parent = panel, Size = UDim2.new(0.96, 0, 0.62, 0), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.2, 0) })
	list.BackgroundTransparency = 1
	self.Store.List = list
	self.Store.Rows = {}
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = list

	local empty = UIKit.Muted(panel, "No entries yet — be the first!", UDim2.new(0.96, 0, 0, 24), Theme.Palette.TextDim)
	empty.AnchorPoint = Vector2.new(0.5, 0.5)
	empty.Position = UDim2.new(0.5, 0, 0.5, 0)
	empty.TextScaled = false
	empty.TextSize = Theme.TypeSize.Small
	empty.TextXAlignment = Enum.TextXAlignment.Center
	empty.Visible = true
	self.Store.Empty = empty
end

function Leaderboards:Select(id)
	self.selected = id
	if self.Store and self.Store.Tabs then
		for _, t in self.Store.Tabs do
			local active = t.btn.Name == id
			t.btn.BackgroundColor3 = active and t.accent or Theme.Palette.PanelAlt
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
	if not entries or #entries == 0 then
		if self.Store.Empty then self.Store.Empty.Visible = true end
		return
	end
	if self.Store.Empty then self.Store.Empty.Visible = false end

	local accent = Theme.Brand.Primary
	for _, b in BOARDS do
		if b.id == self.selected then accent = b.accent end
	end
	-- Research a display name for an entry. Only connected players can be
	-- named on the client (the leaderboard store returns userId only); everyone
	-- else gets the honest "Player #id" fallback rather than a fabricated name.
	local function displayName(entry)
		if entry.Name and entry.Name ~= "" then return tostring(entry.Name) end
		if entry.DisplayName and entry.DisplayName ~= "" then return tostring(entry.DisplayName) end
		local uid = entry.UserId
		if type(uid) == "number" then
			for _, p in Players:GetPlayers() do
				if p.UserId == uid then return p.DisplayName or p.Name end
			end
			return ("Player %d"):format(uid)
		end
		return "Player"
	end

	for i, e in entries do
		local isPodium = i <= 3
		local podiumColor = isPodium and PODIUM_COLORS[i] or Theme.Palette.PanelAlt
		local row = UIKit.Frame({ Parent = self.Store.List, Size = UDim2.new(1, 0, 0, isPodium and 42 or 34), BackgroundColor3 = podiumColor })
		UIKit.Corner(Theme.Radius.Medium).Parent = row
		UIKit.Stroke(isPodium and podiumColor or Theme.Palette.StrokeDim, 1, isPodium and Theme.Opacity.Solid or Theme.Opacity.Subtle).Parent = row
		row.BackgroundTransparency = isPodium and Theme.Opacity.Card or 0
		row.LayoutOrder = i

		local placeBg = UIKit.Frame({ Parent = row, Size = UDim2.new(0, 36, 0, 26), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 6, 0.5, 0), BackgroundColor3 = isPodium and podiumColor or Theme.Palette.Panel })
		UIKit.Corner(Theme.Radius.Small).Parent = placeBg
		local place = UIKit.Text(placeBg, isPodium and PODIUM_LABELS[i] or tostring(i), UDim2.fromScale(1, 1), Theme.Palette.Text)
		place.AnchorPoint = Vector2.new(0.5, 0.5)
		place.Position = UDim2.fromScale(0.5, 0.5)
		place.TextScaled = false
		place.TextSize = isPodium and Theme.TypeSize.Small or Theme.TypeSize.Tiny
		if not isPodium then place.TextColor3 = Theme.Palette.TextDim end

		local name = UIKit.Text(row, displayName(e), UDim2.new(0.62, 0, 1, 0), Theme.Palette.Text)
		name.AnchorPoint = Vector2.new(0, 0.5)
		name.Position = UDim2.new(0, 52, 0.5, 0)
		name.TextScaled = false
		name.TextSize = isPodium and Theme.TypeSize.Body or Theme.TypeSize.Small
		name.TextXAlignment = Enum.TextXAlignment.Left

		local score = UIKit.Title(row, tostring(e.Score or 0), UDim2.new(0.2, 0, 1, 0), isPodium and Theme.Brand.Gold or accent)
		score.AnchorPoint = Vector2.new(1, 0.5)
		score.Position = UDim2.new(0.98, 0, 0.5, 0)
		score.TextScaled = false
		score.TextSize = isPodium and Theme.TypeSize.Title or Theme.TypeSize.Body
		score.TextXAlignment = Enum.TextXAlignment.Right
		self.Store.Rows[i] = row
	end
end

return Leaderboards
