-- MatchHud: in-match overlay. Activity color identity, round, timer, phase,
-- intensity ladder indicator, center messages. Accepts an ActivityId for palette.

local UIKit = require(script.Parent.Parent.UIKit)
local Theme = require(script.Parent.Parent.Theme)
local AudioService = require(script.Parent.Parent.AudioService)

local MatchHud = {
	Name = "MatchHud",
	Root = nil,
	Store = {},
	ActivityId = nil,
}

local ACTIVITY_ACCENTS = {
	chaos_run = Theme.Brand.Primary,
	dodge_lab = Theme.Brand.Danger,
	build_blitz = Theme.Brand.Warning,
	sequence_sprint = Theme.Brand.Secondary,
	survival = Theme.Accent("survival"),
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
	local edge = UIKit.Frame({ Parent = bar, Size = UDim2.new(1, 0, 0, 4), BackgroundColor3 = Theme.Brand.Primary })
	self.Store.Edge = edge

	local activity = UIKit.Title(bar, "", UDim2.new(0.62, 0, 0.5, 0), Theme.Palette.Text)
	activity.TextScaled = false
	activity.TextSize = Theme.TypeSize.Header
	activity.Position = UDim2.new(0.03, 0, 0.25, 0)
	self.Store.Activity = activity

	local round = UIKit.Text(bar, "", UDim2.new(0.22, 0, 0.38, 0), Theme.Palette.TextDim)
	round.Position = UDim2.new(0.6, 0, 0.06, 0)
	round.TextScaled = false
	round.TextSize = Theme.TypeSize.Small
	self.Store.Round = round

	local timer = UIKit.Text(bar, "0:00", UDim2.new(0.18, 0, 0.5, 0), Theme.Brand.Gold)
	timer.Position = UDim2.new(0.82, 0, 0.38, 0)
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
	if self.Store and self.Store.Edge then
		self.Store.Edge.BackgroundColor3 = accent or Theme.Brand.Primary
	end
end

function MatchHud:SetIntensity(level, maxLevel)
	if not self.Store then return end
	if level and maxLevel and maxLevel > 0 then
		for k, v in ACTIVITY_ACCENTS do
			if self.ActivityId == k then
				if self.Store.Edge then
					self.Store.Edge.BackgroundColor3 = Theme.Lerp(Theme.Brand.Success, v, (level - 1) / maxLevel)
				end
			end
		end
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
	if data.IntensityLevel ~= nil then
		self:SetIntensity(data.IntensityLevel, data.IntensityMax or 4)
	end
end

return MatchHud