-- MatchHud: in-match overlay. Round info, timer, phase, activity color identity.

local UIKit = require(script.Parent.Parent.UIKit)
local Theme = require(script.Parent.Parent.Theme)

local MatchHud = {
	Name = "MatchHud",
	Root = nil,
	Store = {},
	ActivityId = nil,
}

function MatchHud:Hide()
	if self.Root then self.Root.Visible = false end
end

function MatchHud:Show(data)
	if not self.Root then return end
	self.Root.Visible = true
	self:SetState(data or {})
end

function MatchHud:Build(parent)
	local root = UIKit.Frame({
		Parent = parent,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	})
	self.Root = root

	local bar = UIKit.Frame({ Parent = root, Size = UDim2.new(1, 0, 0, 64), AnchorPoint = Vector2.new(0, 0) })
	bar.BackgroundColor3 = Theme.Palette.BackgroundAlt
	bar.BackgroundTransparency = 0.15
	UIKit.Corner(Theme.Radius.Medium).Parent = bar

	local activity = UIKit.Title(bar, "", UDim2.new(0.62, 0, 0.5, 0), Theme.Palette.Text)
	activity.TextScaled = false
	activity.TextSize = Theme.TypeSize.Header
	activity.Position = UDim2.new(0.03, 0, 0.25, 0)
	self.Store.Activity = activity

	local round = UIKit.Text(bar, "", UDim2.new(0.3, 0, 0.38, 0), Theme.Palette.TextDim)
	round.Position = UDim2.new(0.66, 0, 0.06, 0)
	round.TextScaled = false
	round.TextSize = Theme.TypeSize.Small
	self.Store.Round = round

	local timer = UIKit.Text(bar, "0:00", UDim2.new(0.3, 0, 0.5, 0), Theme.Brand.Gold)
	timer.Position = UDim2.new(0.66, 0, 0.38, 0)
	timer.TextScaled = false
	timer.TextSize = Theme.TypeSize.Header
	self.Store.Timer = timer

	local phase = UIKit.Text(root, "", UDim2.new(0.7, 0, 0.08, 0), Theme.Palette.TextDim)
	phase.Position = UDim2.new(0.15, 0, 0.46, 0)
	phase.TextScaled = false
	phase.TextSize = Theme.TypeSize.Header
	self.Store.Phase = phase

	local msgPanel = UIKit.Frame({ Parent = root, Size = UDim2.new(0.7, 0, 0.06, 0), AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -12) })
	msgPanel.BackgroundColor3 = Theme.Palette.PanelAlt
	msgPanel.BackgroundTransparency = 0.2
	UIKit.Corner(Theme.Radius.Pill).Parent = msgPanel
	local msg = UIKit.Text(msgPanel, "", UDim2.fromScale(1, 1), Theme.Palette.Text)
	msg.TextScaled = false
	msg.TextSize = Theme.TypeSize.Body
	self.Store.Message = msg
end

function MatchHud:SetActivity(name, accent)
	if self.Store and self.Store.Activity then
		self.Store.Activity.Text = name or ""
		self.Store.Activity.TextColor3 = accent or Theme.Brand.Primary
	end
end

function MatchHud:SetState(data)
	if not self.Store then return end
	if data.Round and self.Store.Round then
		local total = data.TotalRounds or "?"
		self.Store.Round.Text = ("ROUND %d / %s"):format(data.Round, tostring(total))
	end
	if data.TimeLeft ~= nil and self.Store.Timer then
		local m = math.floor(data.TimeLeft / 60)
		local s = math.floor(data.TimeLeft % 60)
		self.Store.Timer.Text = ("%d:%02d"):format(m, s)
	end
	if data.Phase and self.Store.Phase then
		self.Store.Phase.Text = (data.Phase):gsub("^%l", string.upper)
	end
	if data.Message and self.Store.Message then
		self.Store.Message.Text = data.Message
	end
end

return MatchHud