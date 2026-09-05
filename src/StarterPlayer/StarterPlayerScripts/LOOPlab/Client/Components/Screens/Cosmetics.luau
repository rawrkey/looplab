-- Cosmetics: title showcase + equip and badge collection wall.
-- Titles come from GameConfig.Titles; ownership from player profile (Titles list).

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
	UIKit.SlideIn(self.Panel, 0.03, Theme.Motion.Normal)
end

function Cosmetics:Build(parent)
	local root = UIKit.Frame({
		Parent = parent,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	})
	self.Root = root
	self.Store = {}

	local scrim = UIKit.Frame({ Parent = root, Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.5, BorderSizePixel = 0 })

	local panel = UIKit.PanelAlt(root, UDim2.new(0.72, 0, 0.88, 0), Theme.Brand.Secondary)
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	self.Panel = panel

	local title = UIKit.Title(panel, "COSMETICS", UDim2.new(1, 0, 0, 44), Theme.Brand.Secondary)
	title.TextScaled = false
	title.TextSize = Theme.TypeSize.Huge

	-- owned titles section
	local tTitle = UIKit.Text(panel, "YOUR TITLES · tap to equip", UDim2.new(0.94, 0, 0, 22), Theme.Palette.TextFaint)
	tTitle.Position = UDim2.new(0.03, 0, 0, 48)
	tTitle.TextScaled = false
	tTitle.TextSize = Theme.TypeSize.Small
	tTitle.TextXAlignment = Enum.TextXAlignment.Left

	local titlesWrap = UIKit.Frame({ Parent = panel, Size = UDim2.new(0.94, 0, 0, 92), Position = UDim2.new(0.03, 0, 0, 74) })
	titlesWrap.BackgroundTransparency = 1
	local tGrid = Instance.new("UIGridLayout")
	tGrid.Parent = titlesWrap
	tGrid.CellSize = UDim2.new(0.24, 0, 0.46, 0)
	tGrid.CellPadding = UDim2.new(0.012, 0, 0.02, 0)
	tGrid.FillDirection = Enum.FillDirection.Horizontal
	tGrid.HorizontalAlignment = Enum.HorizontalAlignment.Left
	tGrid.SortOrder = Enum.SortOrder.LayoutOrder
	self.Store.TitlesWrap = titlesWrap

	-- badge collection
	local bTitle = UIKit.Text(panel, "BADGES · your collection", UDim2.new(0.94, 0, 0, 22), Theme.Palette.TextFaint)
	bTitle.Position = UDim2.new(0.03, 0, 0, 180)
	bTitle.TextScaled = false
	bTitle.TextSize = Theme.TypeSize.Small
	bTitle.TextXAlignment = Enum.TextXAlignment.Left

	local badgesWrap = UIKit.Frame({ Parent = panel, Size = UDim2.new(0.94, 0, 0.28, 0) })
	badgesWrap.Position = UDim2.new(0.03, 0, 0, 206)
	badgesWrap.BackgroundTransparency = 1
	local bGrid = Instance.new("UIGridLayout")
	bGrid.Parent = badgesWrap
	bGrid.CellSize = UDim2.new(0.12, 0, 0.32, 0)
	bGrid.CellPadding = UDim2.new(0.014, 0, 0.02, 0)
	bGrid.FillDirection = Enum.FillDirection.Horizontal
	bGrid.HorizontalAlignment = Enum.HorizontalAlignment.Left
	bGrid.SortOrder = Enum.SortOrder.LayoutOrder
	self.Store.BadgesWrap = badgesWrap

	local btn = UIKit.GradientButton(panel, "BACK", UDim2.new(0.3, 0, 0, 40), Theme.Brand.Secondary)
	btn.AnchorPoint = Vector2.new(0.5, 1)
	btn.Position = UDim2.new(0.5, 0, 1, -8)
	btn.TextScaled = false
	btn.TextSize = Theme.TypeSize.Body
	btn.Activated:Connect(function()
		AudioService.PlayClick()
		if Cosmetics.OnClose then Cosmetics.OnClose() end
	end)
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
	for index, id in self.OwnedTitles do
		local def = TableFind(GameConfig.Titles, "Id", id)
		local display = def and def.Name or id
		local tier = def and Theme.MasteryColor(def.Tier) or Theme.Brand.Secondary
		local btn = UIKit.Button(self.Store.TitlesWrap, display, UDim2.fromScale(1, 1), (self.EquippedTitle == id) and tier or Theme.Palette.Panel, { textColor = self.EquippedTitle == id and Color3.new(1, 1, 1) or Theme.Palette.Text })
		btn.LayoutOrder = index
		btn.TextScaled = false
		btn.TextSize = Theme.TypeSize.Body
		btn.Activated:Connect(function()
			AudioService.PlayClick()
			if Cosmetics.OnEquipTitle then Cosmetics.OnEquipTitle(id) end
		end)
	end
	if #self.OwnedTitles == 0 then
		local empty = UIKit.Text(self.Store.TitlesWrap, "No titles yet — complete badge challenges!", UDim2.new(1, 0, 0, 30), Theme.Palette.TextFaint)
		empty.TextScaled = false
		empty.TextSize = Theme.TypeSize.Small
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
		local box = UIKit.PanelAlt(self.Store.BadgesWrap, UDim2.fromScale(1, 1), has and Theme.Brand.Gold or Theme.Palette.Panel)
		box.LayoutOrder = index
		box.BackgroundTransparency = has and 0 or 0.5
		local icon = UIKit.Text(box, def.Icon or "•", UDim2.new(1, 0, 0.5, 0), has and Theme.Brand.Gold or Theme.Palette.TextDim)
		icon.TextScaled = false
		icon.TextSize = 22
		local nm = UIKit.Text(box, def.Name, UDim2.new(1, 0, 0.4, 0), has and Theme.Palette.Text or Theme.Palette.TextFaint)
		nm.Position = UDim2.new(0, 0, 0.52, 0)
		nm.TextScaled = false
		nm.TextSize = Theme.TypeSize.Tiny
		box.Name = def.Name
	end
end

return Cosmetics