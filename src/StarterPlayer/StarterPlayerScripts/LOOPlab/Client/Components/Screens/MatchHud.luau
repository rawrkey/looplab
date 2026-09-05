-- MatchHud: in-match overlay. Activity color identity, round, timer, phase,
-- intensity ladder, center messages. Accepts an ActivityId for palette.

local UIKit = require(script.Parent.Parent.UIKit)
local Theme = require(script.Parent.Parent.Theme)
local AudioService = require(script.Parent.Parent.AudioService)

local MatchHud = {
	Name = "MatchHud",
	Root = nil,
	Store = {},
	ActivityId = nil,
	Mode = nil,
}

local ACTIVITY_ACCENTS = {
	chaos_run = Theme.Brand.Primary,
	dodge_lab = Theme.Brand.Danger,
	build_blitz = Theme.Brand.Warning,
	sequence_sprint = Theme.Brand.Secondary,
	survival = Theme.Accent("survival"),
}

local function intensityColor(level, maxLevel)
	if not level or not maxLevel or maxLevel <= 0 then return Theme.Brand.Primary end
	local accent = ACTIVITY_ACCENTS[MatchHud.ActivityId or ""] or Theme.Brand.Primary
	local t = math.clamp((level - 1) / math.max(1, maxLevel - 1), 0, 1)
	return Theme.Lerp(Theme.Brand.Success, accent, t)
end

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

	local topBar = UIKit.Frame({ Parent = root, Size = UDim2.new(1, 0, 0, 60), AnchorPoint = Vector2.new(0, 0) })
	topBar.BackgroundColor3 = Theme.Palette.BackgroundAlt
	topBar.BackgroundTransparency = Theme.Opacity.Soft
	UIKit.Corner(Theme.Radius.Medium).Parent = topBar
	UIKit.Stroke(Theme.Palette.StrokeDim, 1, Theme.Opacity.Subtle).Parent = topBar
	self.Store.TopBar = topBar

	local edge = UIKit.Frame({ Parent = topBar, Size = UDim2.new(1, 0, 0, 3), AnchorPoint = Vector2.new(0, 0), BackgroundColor3 = Theme.Brand.Primary })
	UIKit.Corner(Theme.Radius.Small).Parent = edge
	self.Store.Edge = edge

	local activityWrap = UIKit.Frame({ Parent = topBar, Size = UDim2.new(0.6, 0, 1, 0), AnchorPoint = Vector2.new(0, 0), Position = UDim2.new(0.02, 0, 0, 0) })
	activityWrap.BackgroundTransparency = 1
	local activity = UIKit.Title(activityWrap, "", UDim2.new(1, 0, 0, 26), Theme.Palette.Text)
	activity.AnchorPoint = Vector2.new(0, 0.5)
	activity.Position = UDim2.new(0, 0, 0.4, 0)
	activity.TextScaled = false
	activity.TextSize = Theme.TypeSize.Header
	activity.TextXAlignment = Enum.TextXAlignment.Left
	self.Store.Activity = activity

	local sub = UIKit.Muted(topBar, "", UDim2.new(0.2, 0, 0, 18), Theme.Palette.TextDim)
	sub.AnchorPoint = Vector2.new(0, 0.5)
	sub.Position = UDim2.new(0.02, 0, 0.85, 0)
	sub.TextScaled = false
	sub.TextSize = Theme.TypeSize.Tiny
	sub.TextXAlignment = Enum.TextXAlignment.Left
	self.Store.SubLabel = sub

	local roundWrap = UIKit.Frame({ Parent = topBar, Size = UDim2.new(0.18, 0, 1, 0), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.7, 0, 0, 0) })
	roundWrap.BackgroundTransparency = 1
	local roundLbl = UIKit.Muted(roundWrap, "ROUND", UDim2.new(1, 0, 0, 14), Theme.Palette.TextFaint)
	roundLbl.AnchorPoint = Vector2.new(0.5, 0)
	roundLbl.Position = UDim2.new(0.5, 0, 0.18, 0)
	roundLbl.TextScaled = false
	roundLbl.TextSize = Theme.TypeSize.Tiny
	local round = UIKit.Title(roundWrap, "1/4", UDim2.new(1, 0, 0, 28), Theme.Palette.Text)
	round.AnchorPoint = Vector2.new(0.5, 0)
	round.Position = UDim2.new(0.5, 0, 0.42, 0)
	round.TextScaled = false
	round.TextSize = Theme.TypeSize.Title
	self.Store.Round = round

	local timerWrap = UIKit.Frame({ Parent = topBar, Size = UDim2.new(0.18, 0, 1, 0), AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(0.98, 0, 0, 0) })
	timerWrap.BackgroundTransparency = 1
	local timerLbl = UIKit.Muted(timerWrap, "TIME", UDim2.new(1, 0, 0, 14), Theme.Palette.TextFaint)
	timerLbl.AnchorPoint = Vector2.new(1, 0)
	timerLbl.Position = UDim2.new(1, 0, 0.18, 0)
	timerLbl.TextScaled = false
	timerLbl.TextSize = Theme.TypeSize.Tiny
	timerLbl.TextXAlignment = Enum.TextXAlignment.Right
	local timer = UIKit.Title(timerWrap, "0:00", UDim2.new(1, 0, 0, 30), Theme.Brand.Gold)
	timer.AnchorPoint = Vector2.new(1, 0)
	timer.Position = UDim2.new(1, 0, 0.4, 0)
	timer.TextScaled = false
	timer.TextSize = Theme.TypeSize.Huge
	timer.TextXAlignment = Enum.TextXAlignment.Right
	self.Store.Timer = timer

	local phase = UIKit.Muted(root, "", UDim2.new(0.7, 0, 0, 24), Theme.Palette.TextDim)
	phase.AnchorPoint = Vector2.new(0.5, 0)
	phase.Position = UDim2.new(0.5, 0, 0.08, 0)
	phase.TextScaled = false
	phase.TextSize = Theme.TypeSize.Header
	self.Store.Phase = phase

	local msg = UIKit.Frame({ Parent = root, Size = UDim2.new(0.7, 0, 0.07, 0), AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -16) })
	msg.BackgroundColor3 = Theme.Palette.PanelAlt
	msg.BackgroundTransparency = Theme.Opacity.Soft
	UIKit.Corner(Theme.Radius.Pill).Parent = msg
	UIKit.Stroke(Theme.Palette.StrokeDim, 1, Theme.Opacity.Subtle).Parent = msg
	local msgLbl = UIKit.Text(msg, "", UDim2.fromScale(1, 1), Theme.Palette.Text)
	msgLbl.TextScaled = false
	msgLbl.TextSize = Theme.TypeSize.Body
	self.Store.Message = msgLbl

	local intensity = UIKit.Frame({ Parent = root, Size = UDim2.new(0.18, 0, 0, 6), AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 0.84, 0) })
	intensity.BackgroundColor3 = Theme.Palette.Panel
	UIKit.Corner(Theme.Radius.Pill).Parent = intensity
	self.Store.IntensityWrap = intensity
	self.Store.IntensityFill = UIKit.Frame({ Parent = intensity, Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = Theme.Brand.Success })
	UIKit.Corner(Theme.Radius.Pill).Parent = self.Store.IntensityFill
	self.Store.IntensityWrap.Visible = false
end

function MatchHud:SetActivity(name, accent, mode)
	if self.Store and self.Store.Activity then
		self.Store.Activity.Text = name or ""
		self.Store.Activity.TextColor3 = accent or Theme.Brand.Primary
	end
	if self.Store and self.Store.Edge then
		self.Store.Edge.BackgroundColor3 = accent or Theme.Brand.Primary
	end
	if accent and self.Store.IntensityFill then
		self.Store.IntensityFill.BackgroundColor3 = accent
	end
end

function MatchHud:SetState(data)
	if not self.Store then return end
	if data.ActivityId then
		self.ActivityId = data.ActivityId
		local accent = ACTIVITY_ACCENTS[self.ActivityId]
		if accent then
			if self.Store.Edge then self.Store.Edge.BackgroundColor3 = accent end
			if self.Store.Activity then self.Store.Activity.TextColor3 = accent end
		end
	end
	if data.Mode then
		self.Mode = data.Mode
		if self.Store.IntensityWrap then
			self.Store.IntensityWrap.Visible = (self.Mode == "Survival")
		end
	end
	if data.Round and self.Store.Round then
		local total = data.TotalRounds or "?"
		self.Store.Round.Text = ("%d / %s"):format(data.Round, tostring(total))
	end
	if data.SubLabel and self.Store.SubLabel then
		self.Store.SubLabel.Text = data.SubLabel
	end
	if data.TimeLeft ~= nil and self.Store.Timer then
		local tl = math.max(0, data.TimeLeft)
		local m = math.floor(tl / 60)
		local s = math.floor(tl % 60)
		self.Store.Timer.Text = ("%d:%02d"):format(m, s)
		if tl < 10 and tl > 0 then
			self.Store.Timer.TextColor3 = Theme.Brand.Danger
		else
			self.Store.Timer.TextColor3 = Theme.Brand.Gold
		end
	end
	if data.Phase and self.Store.Phase then
		self.Store.Phase.Text = (data.Phase):gsub("^%l", string.upper)
	end
	if data.Message and self.Store.Message then
		self.Store.Message.Text = data.Message
	end
	if data.IntensityLevel ~= nil and self.Store.IntensityFill then
		local max = data.IntensityMax or 4
		local frac = math.clamp((data.IntensityLevel - 1) / math.max(1, max - 1), 0, 1)
		self.Store.IntensityFill.Size = UDim2.new(frac, 0, 1, 0)
		self.Store.IntensityFill.BackgroundColor3 = intensityColor(data.IntensityLevel, max)
	end
end

return MatchHud
