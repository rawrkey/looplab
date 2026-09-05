-- Cosmetics: title showcase + equip and badge collection wall.

local UIKit = require(script.Parent.Parent.UIKit)
local Theme = require(script.Parent.Parent.Theme)
local AudioService = require(script.Parent.Parent.AudioService)
local GameConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("LOOPlab").Configuration.GameConfig)

local function TableFind(list, key, value)
	for _, item in list do
		if item[key] == value then return item end
	end
	return nil
end

local Cosmetics = {
	Name = "Cosmetics",
	Root = nil,
	Store = {},
	OnClose = nil,
	OnEquipTitle = nil,
	OwnedTitles = {},
	EquippedTitle = "",
}

function Cosmetics:Hide()
	if self.Root then self.Root.Visible = false end
end

function Cosmetics:Show(data)
	if not self.Root then return end
	self.Root.Visible = true
	if data then
		self.OwnedTitles = data.Titles or {}
		self.EquippedTitle = data.EquippedTitle or ""
		self:BuildTitles()
		self:BuildBadges(data.Badges or {})
	end
	UIKit.SlideUpIn(self.Panel, 0.04, Theme.Motion.Normal)
end

function Cosmetics:Build(parent)
	local root = UIKit.Frame({
		Parent = parent,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	})
	self.Root = root
	self.Store = {}

	local scrim = UIKit.Frame({ Parent = root, Size = UDim2.fromScale(1, 1), BackgroundColor3 = Theme.Palette.Scrim, BackgroundTransparency = Theme.Opacity.Scrim })
	scrim.BorderSizePixel = 0

	local panel = UIKit.Card(root, UDim2.new(0.72, 0, 0.84, 0), Theme.Brand.Secondary)
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.BackgroundTransparency = Theme.Opacity.Card
	self.Panel = panel

	local edge = UIKit.Frame({ Parent = panel, Size = UDim2.new(1, 0, 0, 3), AnchorPoint = Vector2.new(0, 0), BackgroundColor3 = Theme.Brand.Secondary })
	UIKit.Corner(Theme.Radius.Small).Parent = edge

	local title = UIKit.Title(panel, "COSMETICS", UDim2.new(0.94, 0, 0, 36), Theme.Palette.Text)
	title.AnchorPoint = Vector2.new(0, 0)
	title.Position = UDim2.new(0.03, 0, 0.04, 0)
	title.TextScaled = false
	title.TextSize = Theme.TypeSize.Huge
	title.TextXAlignment = Enum.TextXAlignment.Left

	local close = UIKit.Button(panel, "✕", UDim2.fromOffset(34, 34), Theme.Palette.PanelAlt, { textColor = Theme.Palette.TextDim })
	close.AnchorPoint = Vector2.new(1, 0)
	close.Position = UDim2.new(0.97, 0, 0.04, 0)
	close.TextScaled = false
	close.TextSize = Theme.TypeSize.Small
	close.Activated:Connect(function()
		AudioService.PlayClick()
		if Cosmetics.OnClose then Cosmetics.OnClose() end
	end)

	local tTitle = UIKit.SectionLabel(panel, "YOUR TITLES · tap to equip", UDim2.new(0.94, 0, 0, 18))
	tTitle.AnchorPoint = Vector2.new(0, 0)
	tTitle.Position = UDim2.new(0.03, 0, 0.12, 0)

	local titlesWrap = UIKit.Frame({ Parent = panel, Size = UDim2.new(0.94, 0, 0, 96), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.16, 0) })
	titlesWrap.BackgroundTransparency = 1
	self.Store.TitlesWrap = titlesWrap

	local bTitle = UIKit.SectionLabel(panel, "BADGES · your collection", UDim2.new(0.94, 0, 0, 18))
	bTitle.AnchorPoint = Vector2.new(0, 0)
	bTitle.Position = UDim2.new(0.03, 0, 0.32, 0)

	local badgesWrap = UIKit.Frame({ Parent = panel, Size = UDim2.new(0.94, 0, 0.4, 0), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.36, 0) })
	badgesWrap.BackgroundTransparency = 1
	self.Store.BadgesWrap = badgesWrap
	local bGrid = Instance.new("UIGridLayout")
	bGrid.CellSize = UDim2.new(0.12, 0, 0.32, 0)
	bGrid.CellPadding = UDim2.new(0.014, 0, 0.02, 0)
	bGrid.FillDirection = Enum.FillDirection.Horizontal
	bGrid.HorizontalAlignment = Enum.HorizontalAlignment.Left
	bGrid.SortOrder = Enum.SortOrder.LayoutOrder
	bGrid.Parent = badgesWrap

	local info = UIKit.Muted(panel, "Titles and badges unlock via progression. Earn XP, win matches, and complete challenges to expand your collection.", UDim2.new(0.94, 0, 0, 36), Theme.Palette.TextDim)
	info.AnchorPoint = Vector2.new(0.5, 1)
	info.Position = UDim2.new(0.5, 0, 0.96, 0)
	info.TextScaled = false
	info.TextSize = Theme.TypeSize.Tiny
	info.TextWrapped = true
	info.TextXAlignment = Enum.TextXAlignment.Center
end

local COLS = { "Frame", "TextLabel", "TextButton", "ImageLabel", "ImageButton", "ScrollingFrame", "TextBox", "CanvasGroup", "ViewportFrame" }

function Cosmetics:_clear(wrap)
	for _, c in wrap:GetChildren() do
		if table.find(COLS, c.ClassName) then c:Destroy() end
	end
end

function Cosmetics:BuildTitles()
	if not self.Store or not self.Store.TitlesWrap then return end
	self:_clear(self.Store.TitlesWrap)
	if #self.OwnedTitles == 0 then
		local empty = UIKit.Text(self.Store.TitlesWrap, "No titles yet — earn them through gameplay!", UDim2.new(1, 0, 0, 30), Theme.Palette.TextFaint)
		empty.TextScaled = false
		empty.TextSize = Theme.TypeSize.Small
		return
	end
	for index, id in self.OwnedTitles do
		local def = TableFind(GameConfig.Titles, "Id", id)
		local display = def and def.Name or id
		local tier = def and Theme.MasteryColor(def.Tier) or Theme.Brand.Secondary
		local isEquipped = (self.EquippedTitle == id)
		local btn = UIKit.Button(self.Store.TitlesWrap, display, UDim2.new(0, 130, 0, 36), isEquipped and tier or Theme.Palette.PanelAlt, { textColor = isEquipped and Color3.new(1, 1, 1) or Theme.Palette.Text })
		btn.Position = UDim2.new(0, 8 + (index - 1) * 138, 0, 0)
		btn.TextScaled = false
		btn.TextSize = Theme.TypeSize.Small
		btn.Activated:Connect(function()
			AudioService.PlayClick()
			if Cosmetics.OnEquipTitle then Cosmetics.OnEquipTitle(id) end
		end)
	end
end

function Cosmetics:BuildBadges(owned)
	owned = owned or {}
	if not self.Store or not self.Store.BadgesWrap then return end
	self:_clear(self.Store.BadgesWrap)
	local ownedSet = {}
	for _, id in owned do ownedSet[id] = true end
	for index, def in GameConfig.Badges do
		local has = ownedSet[def.Id] == true
		local box = UIKit.Frame({ Parent = self.Store.BadgesWrap, BackgroundColor3 = has and Theme.WithAlpha(Theme.Brand.Gold, 0.18) or Theme.Palette.Panel })
		UIKit.Corner(Theme.Radius.Medium).Parent = box
		UIKit.Stroke(has and Theme.Brand.Gold or Theme.Palette.StrokeDim, 1, has and Theme.Opacity.Subtle or Theme.Opacity.Std).Parent = box
		box.BackgroundTransparency = has and Theme.Opacity.Card or 0
		box.LayoutOrder = index
		local icon = UIKit.Text(box, def.Icon or "•", UDim2.new(1, 0, 0.5, 0), has and Theme.Brand.Gold or Theme.Palette.TextDim)
		icon.AnchorPoint = Vector2.new(0.5, 0)
		icon.Position = UDim2.new(0.5, 0, 0.05, 0)
		icon.TextScaled = false
		icon.TextSize = 22
		local nm = UIKit.Muted(box, def.Name, UDim2.new(0.92, 0, 0.4, 0), has and Theme.Palette.Text or Theme.Palette.TextFaint)
		nm.AnchorPoint = Vector2.new(0.5, 1)
		nm.Position = UDim2.new(0.5, 0, 0.95, 0)
		nm.TextScaled = false
		nm.TextSize = Theme.TypeSize.Micro
		box.Name = def.Name
	end
end

return Cosmetics
