-- Queue: lobby/queue status for standalone or survival.

local UIKit = require(script.Parent.Parent.UIKit)
local Theme = require(script.Parent.Parent.Theme)

local Queue = {
	Name = "Queue",
	Root = nil,
	Store = {},
	OnLeave = nil,
}

function Queue:Hide()
	if self.Root then self.Root.Visible = false end
end

function Queue:Show(data)
	if not self.Root then return end
	self.Root.Visible = true
	if data then
		if data.Title then self.Store.Title.Text = data.Title end
		self:Set(data)
	end
	UIKit.SlideIn(self.Panel, 0.04, Theme.Motion.Normal)
end

function Queue:Build(parent)
	local root = UIKit.Frame({
		Parent = parent,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	})
	self.Root = root

	local panel = UIKit.PanelAlt(root, UDim2.new(0.5, 0, 0.62, 0), Theme.Brand.Primary)
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	self.Panel = panel

	local title = UIKit.Title(panel, "QUEUE", UDim2.new(1, 0, 0, 48), Theme.Brand.Primary)
	title.TextScaled = false
	title.TextSize = Theme.TypeSize.Huge
	self.Store.Title = title

	local status = UIKit.Text(panel, "Waiting for players...", UDim2.new(0.9, 0, 0, 28), Theme.Palette.TextDim)
	status.Position = UDim2.new(0.05, 0, 0, 56)
	self.Store.Status = status

	local counts = UIKit.Text(panel, "0 / 10", UDim2.new(0.9, 0, 0, 22), Theme.Palette.Text)
	counts.Position = UDim2.new(0.05, 0, 0, 88)
	self.Store.Counts = counts

	local barWrap = UIKit.Frame({ Parent = panel, Size = UDim2.new(0.9, 0, 0, 18), Position = UDim2.new(0.05, 0, 0, 124) })
	barWrap.BackgroundColor3 = Theme.Palette.Background
	UIKit.Corner(Theme.Radius.Pill).Parent = barWrap
	local fill = UIKit.Frame({ Parent = barWrap, Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = Theme.Brand.Primary })
	UIKit.Corner(Theme.Radius.Pill).Parent = fill
	self.Store.Fill = fill

	local hint = UIKit.Text(panel, "Match starts when the lobby fills.", UDim2.new(0.9, 0, 0, 20), Theme.Palette.TextFaint)
	hint.Position = UDim2.new(0.05, 0, 0, 158)
	hint.TextScaled = false
	hint.TextSize = Theme.TypeSize.Small

	local btn = UIKit.GradientButton(panel, "LEAVE QUEUE", UDim2.new(0.6, 0, 0, 44), Theme.Brand.Danger)
	btn.AnchorPoint = Vector2.new(0.5, 1)
	btn.Position = UDim2.new(0.5, 0, 1, -16)
	btn.TextScaled = false
	btn.TextSize = Theme.TypeSize.Body
	btn.Activated:Connect(function()
		if Queue.OnLeave then Queue.OnLeave() end
	end)
end

function Queue:Set(data)
	local q = data.Queued or 0
	local target = data.Target or 10
	local msg = data.Message or ("Waiting for players... %d/%d"):format(q, target)
	if self.Store then
		self.Store.Status.Text = msg
		if self.Store.Counts then self.Store.Counts.Text = ("%d / %d"):format(q, target) end
		if self.Store.Fill then
			local frac = target > 0 and math.clamp(q / target, 0, 1) or 0
			self.Store.Fill.Size = UDim2.new(frac, 0, 1, 0)
		end
	end
end

return Queue