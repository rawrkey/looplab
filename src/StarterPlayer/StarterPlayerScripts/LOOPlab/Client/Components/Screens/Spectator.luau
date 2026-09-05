-- Spectator: eliminated players cycle survivors during survival matches.

local UIKit = require(script.Parent.Parent.UIKit)
local Theme = require(script.Parent.Parent.Theme)

local Spectator = {
	Name = "Spectator",
	Root = nil,
	Store = {},
	OnCycle = nil,
}

function Spectator:Hide()
	if self.Root then self.Root.Visible = false end
end

function Spectator:Show(data)
	if not self.Root then return end
	self.Root.Visible = true
	if data then self:SetCycle(data) end
end

function Spectator:Build(parent)
	local root = UIKit.Frame({
		Parent = parent,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	})
	self.Root = root

	local panel = UIKit.PanelAlt(root, UDim2.new(0.46, 0, 0.5, 0), Theme.Accent("survival"))
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	self.Panel = panel

	local title = UIKit.Title(panel, "ELIMINATED", UDim2.new(1, 0, 0, 40), Theme.Brand.Danger)
	title.TextScaled = false
	title.TextSize = Theme.TypeSize.Huge

	local hint = UIKit.Text(panel, "You're out! Spectate the survivors.", UDim2.new(0.94, 0, 0, 22), Theme.Palette.TextDim)
	hint.Position = UDim2.new(0.03, 0, 0, 44)
	hint.TextScaled = false
	hint.TextSize = Theme.TypeSize.Small

	local avatarWrap = UIKit.Frame({ Parent = panel, Size = UDim2.new(0.94, 0, 0, 40), Position = UDim2.new(0.03, 0, 0, 76) })
	avatarWrap.BackgroundTransparency = 1

	local target = UIKit.Title(avatarWrap, "WAITING", UDim2.fromScale(1, 1), Theme.Palette.Text)
	target.TextScaled = false
	target.TextSize = Theme.TypeSize.Header
	self.Store.Target = target

	local nameTag = UIKit.Text(panel, "", UDim2.new(0.94, 0, 0, 22), Theme.Brand.Gold)
	nameTag.Position = UDim2.new(0.03, 0, 0, 118)
	nameTag.TextScaled = false
	nameTag.TextSize = Theme.TypeSize.Body
	self.Store.NameTag = nameTag

	local controls = UIKit.Frame({ Parent = panel, Size = UDim2.new(0.94, 0, 0, 48), Position = UDim2.new(0.03, 0, 0, 158) })
	controls.BackgroundTransparency = 1
	local prevBtn = UIKit.Button(controls, "‹ PREV", UDim2.new(0.48, 0, 1, 0), Theme.Palette.Panel, { textColor = Theme.Palette.Text })
	prevBtn.Activated:Connect(function()
		if Spectator.OnCycle then Spectator.OnCycle("prev") end
	end)
	local nextBtn = UIKit.Button(controls, "NEXT ›", UDim2.new(0.48, 0, 1, 0), Theme.Palette.Panel, { textColor = Theme.Palette.Text })
	nextBtn.Position = UDim2.new(0.52, 0, 0, 0)
	nextBtn.Activated:Connect(function()
		if Spectator.OnCycle then Spectator.OnCycle("next") end
	end)
end

function Spectator:SetCycle(data)
	if not self.Store then return end
	if data.Cycle then self.Cycle = data.Cycle or {} end
	self.Index = 1
end

function Spectator:ShowTarget(player)
	if self.Store and player then
		self.Store.Target.Text = player.Name
		self.Store.Target.TextColor3 = Theme.Brand.Gold
		if self.Store.NameTag then
			self.Store.NameTag.Text = ("Spectating: %s"):format(player.Name)
		end
	end
end

function Spectator:Clear()
	if self.Store then
		self.Store.Target.Text = "WAITING"
		self.Store.Target.TextColor3 = Theme.Palette.TextDim
		if self.Store.NameTag then self.Store.NameTag.Text = "" end
	end
end

return Spectator