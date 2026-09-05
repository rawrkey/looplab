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
		if data.Accent then
			self.Store.Title.TextColor3 = data.Accent
			if self.Store.Edge then
				self.Store.Edge.BackgroundColor3 = data.Accent
			end
			if self.Store.Fill then
				self.Store.Fill.BackgroundColor3 = data.Accent
			end
			if self.Store.Bar then
				self.Store.Bar.BackgroundColor3 = data.Accent
			end
		end
		self:Set(data)
	end
	UIKit.SlideUpIn(self.Panel, 0.04, Theme.Motion.Normal)
end

function Queue:Build(parent)
	local root = UIKit.Frame({
		Parent = parent,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	})
	self.Root = root

	local panel = UIKit.Card(root, UDim2.new(0.5, 0, 0.5, 0), Theme.Brand.Primary)
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.BackgroundTransparency = Theme.Opacity.Card
	self.Panel = panel

	local edge = UIKit.Frame({ Parent = panel, Size = UDim2.new(1, 0, 0, 3), AnchorPoint = Vector2.new(0, 0), BackgroundColor3 = Theme.Brand.Primary })
	UIKit.Corner(Theme.Radius.Small).Parent = edge
	self.Store.Edge = edge

	local eyebrow = UIKit.Muted(panel, "MATCHMAKING", UDim2.new(1, -40, 0, 16), Theme.Palette.TextFaint)
	eyebrow.AnchorPoint = Vector2.new(0.5, 0)
	eyebrow.Position = UDim2.new(0.5, 0, 0.1, 0)
	eyebrow.TextScaled = false
	eyebrow.TextSize = Theme.TypeSize.Tiny
	eyebrow.TextXAlignment = Enum.TextXAlignment.Center

	local title = UIKit.Title(panel, "QUEUE", UDim2.new(1, -40, 0, 38), Theme.Brand.Primary)
	title.AnchorPoint = Vector2.new(0.5, 0)
	title.Position = UDim2.new(0.5, 0, 0.2, 0)
	title.TextScaled = false
	title.TextSize = Theme.TypeSize.Huge
	self.Store.Title = title

	local status = UIKit.Muted(panel, "Standing by...", UDim2.new(0.9, 0, 0, 24), Theme.Palette.TextDim)
	status.AnchorPoint = Vector2.new(0.5, 0)
	status.Position = UDim2.new(0.5, 0, 0.45, 0)
	status.TextScaled = false
	status.TextSize = Theme.TypeSize.Small
	self.Store.Status = status

	local counts = UIKit.Display(panel, "0 / 10", Theme.Brand.Gold)
	counts.AnchorPoint = Vector2.new(0.5, 0)
	counts.Position = UDim2.new(0.5, 0, 0.5, 0)
	counts.TextScaled = false
	counts.TextSize = Theme.TypeSize.Hero
	self.Store.Counts = counts

	local barWrap = UIKit.Frame({ Parent = panel, Size = UDim2.new(0.86, 0, 0, 14), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.78, 0) })
	local bar = UIKit.Frame({ Parent = barWrap, Size = UDim2.fromScale(1, 1), BackgroundColor3 = Theme.Palette.Background })
	UIKit.Corner(Theme.Radius.Pill).Parent = bar
	self.Store.Bar = bar
	local fill = UIKit.Frame({ Parent = bar, Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = Theme.Brand.Primary })
	UIKit.Corner(Theme.Radius.Pill).Parent = fill
	self.Store.Fill = fill

	local hint = UIKit.Muted(panel, "Match starts when the lobby fills.", UDim2.new(0.9, 0, 0, 20), Theme.Palette.TextFaint)
	hint.AnchorPoint = Vector2.new(0.5, 0)
	hint.Position = UDim2.new(0.5, 0, 0.84, 0)
	hint.TextScaled = false
	hint.TextSize = Theme.TypeSize.Small
	hint.TextXAlignment = Enum.TextXAlignment.Center

	local btn = UIKit.Button(panel, "LEAVE QUEUE", UDim2.new(0.6, 0, 0, 38), Theme.Brand.Danger, { textColor = Color3.new(1, 1, 1) })
	btn.AnchorPoint = Vector2.new(0.5, 1)
	btn.Position = UDim2.new(0.5, 0, 0.96, 0)
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
