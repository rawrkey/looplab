-- Queue: lobby/queue status for standalone or survival, plus the Survival
-- LINEUP (the 4-game sequence revealed on match found).

local UIKit = require(script.Parent.Parent.UIKit)
local Theme = require(script.Parent.Parent.Theme)

local Queue = {
	Name = "Queue",
	Root = nil,
	Store = {},
	OnLeave = nil,
}

local ROUND_GAMES = {
	chaos_run = { name = "CHAOS RUN", icon = "➤" },
	dodge_lab = { name = "DODGE LAB", icon = "✦" },
	build_blitz = { name = "BUILD BLITZ", icon = "▬" },
	sequence_sprint = { name = "SEQ. SPRINT", icon = "⧗" },
}

local function accented(activityId)
	return Theme.Accent(activityId)
end

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
		if data.RoundOrder ~= nil or data.Order ~= nil then
			self:SetLineup(data.RoundOrder or data.Order)
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

	local panel = UIKit.Card(root, UDim2.new(0.56, 0, 0.62, 0), Theme.Brand.Primary)
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.BackgroundTransparency = Theme.Opacity.Card
	self.Panel = panel

	local edge = UIKit.Frame({ Parent = panel, Size = UDim2.new(1, 0, 0, 3), AnchorPoint = Vector2.new(0, 0), BackgroundColor3 = Theme.Brand.Primary })
	UIKit.Corner(Theme.Radius.Small).Parent = edge
	self.Store.Edge = edge

	local eyebrow = UIKit.Muted(panel, "MATCHMAKING", UDim2.new(1, -40, 0, 14), Theme.Palette.TextFaint)
	eyebrow.AnchorPoint = Vector2.new(0.5, 0)
	eyebrow.Position = UDim2.new(0.5, 0, 0.06, 0)
	eyebrow.TextScaled = false
	eyebrow.TextSize = Theme.TypeSize.Tiny
	eyebrow.TextXAlignment = Enum.TextXAlignment.Center

	local title = UIKit.Title(panel, "QUEUE", UDim2.new(1, -40, 0, 32), Theme.Brand.Primary)
	title.AnchorPoint = Vector2.new(0.5, 0)
	title.Position = UDim2.new(0.5, 0, 0.12, 0)
	title.TextScaled = false
	title.TextSize = Theme.TypeSize.Huge
	self.Store.Title = title

	local status = UIKit.Muted(panel, "Standing by...", UDim2.new(0.9, 0, 0, 20), Theme.Palette.TextDim)
	status.AnchorPoint = Vector2.new(0.5, 0)
	status.Position = UDim2.new(0.5, 0, 0.3, 0)
	status.TextScaled = false
	status.TextSize = Theme.TypeSize.Small
	status.TextXAlignment = Enum.TextXAlignment.Center
	self.Store.Status = status

	local counts = UIKit.Display(panel, "0 / 10", Theme.Brand.Gold)
	counts.AnchorPoint = Vector2.new(0.5, 0)
	counts.Position = UDim2.new(0.5, 0, 0.36, 0)
	counts.TextScaled = false
	counts.TextSize = Theme.TypeSize.Hero
	self.Store.Counts = counts

	-- LINEUP strip (Survival): the 4-game sequence revealed on match found.
	local lineupLbl = UIKit.Muted(panel, "", UDim2.new(1, -40, 0, 12), Theme.Palette.TextFaint)
	lineupLbl.AnchorPoint = Vector2.new(0.5, 0)
	lineupLbl.Position = UDim2.new(0.5, 0, 0.52, 0)
	lineupLbl.TextScaled = false
	lineupLbl.TextSize = Theme.TypeSize.Micro
	lineupLbl.TextXAlignment = Enum.TextXAlignment.Center
	self.Store.LineupLbl = lineupLbl

	local lineupWrap = UIKit.Frame({ Parent = panel, Size = UDim2.new(0.94, 0, 0, 44), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.56, 0) })
	lineupWrap.BackgroundTransparency = 1
	self.Store.LineupWrap = lineupWrap
	self.Store.LineupList = {}

	local barWrap = UIKit.Frame({ Parent = panel, Size = UDim2.new(0.86, 0, 0, 12), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.82, 0) })
	local bar = UIKit.Frame({ Parent = barWrap, Size = UDim2.fromScale(1, 1), BackgroundColor3 = Theme.Palette.Background })
	UIKit.Corner(Theme.Radius.Pill).Parent = bar
	self.Store.Bar = bar
	local fill = UIKit.Frame({ Parent = bar, Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = Theme.Brand.Primary })
	UIKit.Corner(Theme.Radius.Pill).Parent = fill
	self.Store.Fill = fill

	local hint = UIKit.Muted(panel, "Match starts when the lobby fills.", UDim2.new(0.9, 0, 0, 16), Theme.Palette.TextFaint)
	hint.AnchorPoint = Vector2.new(0.5, 0)
	hint.Position = UDim2.new(0.5, 0, 0.85, 0)
	hint.TextScaled = false
	hint.TextSize = Theme.TypeSize.Tiny
	hint.TextXAlignment = Enum.TextXAlignment.Center
	self.Store.Hint = hint

	local btn = UIKit.Button(panel, "LEAVE QUEUE", UDim2.new(0.6, 0, 0, 34), Theme.Brand.Danger, { textColor = Color3.new(1, 1, 1) })
	btn.AnchorPoint = Vector2.new(0.5, 1)
	btn.Position = UDim2.new(0.5, 0, 0.96, 0)
	btn.TextScaled = false
	btn.TextSize = Theme.TypeSize.Body
	btn.Activated:Connect(function()
		if Queue.OnLeave then Queue.OnLeave() end
	end)
end

-- Render the Survival lineup from the server's authoritative round order.
-- Rebuilds the strip each call so it stays correct as the queue/lobby changes.
-- Handles gracefully: nil/empty order, 1 round, any list length, players with
-- missing name/icon data (falls back to the activity id).
function Queue:SetLineup(roundOrder, title)
	local list = type(roundOrder) == "table" and roundOrder or {}
	if not self.Store or not self.Store.LineupWrap then return end
	for _, pill in self.Store.LineupList do
		if pill and pill.Parent then pill:Destroy() end
	end
	self.Store.LineupList = {}

	if #list == 0 then
		if self.Store.LineupLbl then self.Store.LineupLbl.Text = "" end
		if self.Store.LineupWrap then self.Store.LineupWrap.Visible = false end
		return
	end

	if self.Store.LineupLbl then
		self.Store.LineupLbl.Text = (title or "LINEUP") .. " — ROUNDS AHEAD"
	end
	if self.Store.LineupWrap then self.Store.LineupWrap.Visible = true end

	for i, activityId in list do
		local id = tostring(activityId or "")
		local def = ROUND_GAMES[id] or {}
		local accent = accented(id)
		local pill = UIKit.Frame({
			Parent = self.Store.LineupWrap,
			Size = UDim2.new(1 / math.max(#list, 1) - 0.012, 0, 1, 0),
			BackgroundColor3 = Theme.Palette.PanelAlt,
			BorderSizePixel = 0,
		})
		pill.BackgroundTransparency = Theme.Opacity.Card
		UIKit.Corner(Theme.Radius.Small).Parent = pill

		local top = UIKit.Frame({ Parent = pill, Size = UDim2.new(1, 0, 0, 2), BackgroundColor3 = accent })
		UIKit.Corner(Theme.Radius.Small).Parent = top

		local round = UIKit.Muted(pill, ("%d"):format(i), UDim2.new(1, 0, 0, 12), Theme.Palette.TextFaint)
		round.Position = UDim2.new(0, 0, 0.02, 0)
		round.TextScaled = false
		round.TextSize = Theme.TypeSize.Micro
		round.TextXAlignment = Enum.TextXAlignment.Center

		local nameLbl = UIKit.Title(pill, def.name or id:upper(), UDim2.new(1, -4, 0, 14), accent)
		nameLbl.Position = UDim2.new(0, 0, 0.3, 0)
		nameLbl.TextScaled = false
		nameLbl.TextSize = Theme.TypeSize.Small
		nameLbl.TextXAlignment = Enum.TextXAlignment.Center

		local icon = UIKit.Text(pill, def.icon or "▸", UDim2.new(1, 0, 0, 12), Theme.Palette.TextDim)
		icon.Position = UDim2.new(0, 0, 0.62, 0)
		icon.TextScaled = false
		icon.TextSize = Theme.TypeSize.Tiny
		icon.TextXAlignment = Enum.TextXAlignment.Center

		table.insert(self.Store.LineupList, pill)
	end
end

function Queue:Set(data)
	local q = data.Queued or 0
	local target = data.Target or 10
	local msg = data.Message or ("Waiting for players... %d/%d"):format(q, target)
	if self.Store then
		if data.RoundOrder ~= nil or data.Order ~= nil then
			self:SetLineup(data.RoundOrder or data.Order)
		end
		self.Store.Status.Text = msg
		if self.Store.Counts then self.Store.Counts.Text = ("%d / %d"):format(q, target) end
		if self.Store.Fill then
			local frac = target > 0 and math.clamp(q / target, 0, 1) or 0
			self.Store.Fill.Size = UDim2.new(frac, 0, 1, 0)
		end
	end
end

return Queue
