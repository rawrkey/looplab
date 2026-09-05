-- Spectator: eliminated players cycle survivors during survival matches.

local UIKit = require(script.Parent.Parent.UIKit)
local Theme = require(script.Parent.Parent.Theme)

local Spectator = {
	Name = "Spectator",
	Root = nil,
	Store = {},
	OnCycle = nil,
	Cycle = {},
	Index = 1,
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

	local panel = UIKit.Card(root, UDim2.new(0.4, 0, 0.42, 0), Theme.Accent("survival"))
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.BackgroundTransparency = Theme.Opacity.Card

	local edge = UIKit.Frame({ Parent = panel, Size = UDim2.new(1, 0, 0, 3), AnchorPoint = Vector2.new(0, 0), BackgroundColor3 = Theme.Accent("survival") })
	UIKit.Corner(Theme.Radius.Small).Parent = edge

	local eyebrow = UIKit.Muted(panel, "SPECTATING", UDim2.new(1, -40, 0, 14), Theme.Palette.TextFaint)
	eyebrow.AnchorPoint = Vector2.new(0.5, 0)
	eyebrow.Position = UDim2.new(0.5, 0, 0.12, 0)
	eyebrow.TextScaled = false
	eyebrow.TextSize = Theme.TypeSize.Tiny
	eyebrow.TextXAlignment = Enum.TextXAlignment.Center

	local title = UIKit.Title(panel, "ELIMINATED", UDim2.new(1, -40, 0, 36), Theme.Brand.Danger)
	title.AnchorPoint = Vector2.new(0.5, 0)
	title.Position = UDim2.new(0.5, 0, 0.22, 0)
	title.TextScaled = false
	title.TextSize = Theme.TypeSize.Huge
	title.TextXAlignment = Enum.TextXAlignment.Center

	local targetWrap = UIKit.Frame({ Parent = panel, Size = UDim2.new(1, -40, 0, 80), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.46, 0) })
	targetWrap.BackgroundTransparency = 1

	local ring = UIKit.Frame({ Parent = targetWrap, Size = UDim2.fromOffset(64, 64), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0.04, 0, 0.5, 0), BackgroundColor3 = Theme.Palette.PanelAlt })
	UIKit.Corner(Theme.Radius.Pill).Parent = ring
	UIKit.Stroke(Theme.Accent("survival"), 1, Theme.Opacity.Subtle).Parent = ring
	self.Store.Avatar = ring

	local target = UIKit.Title(targetWrap, "WAITING", UDim2.new(0.7, 0, 0.5, 0), Theme.Palette.Text)
	target.AnchorPoint = Vector2.new(0, 0)
	target.Position = UDim2.new(0.34, 0, 0.05, 0)
	target.TextScaled = false
	target.TextSize = Theme.TypeSize.Header
	target.TextXAlignment = Enum.TextXAlignment.Left
	self.Store.Target = target

	local hint = UIKit.Muted(targetWrap, "cycle the survivors", UDim2.new(0.7, 0, 0, 18), Theme.Palette.TextDim)
	hint.AnchorPoint = Vector2.new(0, 0)
	hint.Position = UDim2.new(0.34, 0, 0.55, 0)
	hint.TextScaled = false
	hint.TextSize = Theme.TypeSize.Tiny
	hint.TextXAlignment = Enum.TextXAlignment.Left
	self.Store.Hint = hint

	local counter = UIKit.Chip(targetWrap, "0/0", Theme.WithAlpha(Theme.Accent("survival"), 0.18), { textColor = Theme.Accent("survival"), autosize = true })
	counter.AutoButtonColor = false
	counter.AnchorPoint = Vector2.new(1, 0)
	counter.Position = UDim2.new(1, 0, 0.55, 0)
	counter.Size = UDim2.new(0, 60, 0, 22)
	self.Store.Counter = counter

	local controls = UIKit.Frame({ Parent = panel, Size = UDim2.new(0.86, 0, 0, 40), AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 0.92, 0) })
	controls.BackgroundTransparency = 1
	local prevBtn = UIKit.Button(controls, "‹ PREV", UDim2.new(0.48, 0, 1, 0), Theme.Palette.PanelAlt, { textColor = Theme.Palette.Text })
	prevBtn.TextScaled = false
	prevBtn.TextSize = Theme.TypeSize.Small
	prevBtn.Activated:Connect(function()
		if Spectator.OnCycle then Spectator.OnCycle("prev") end
	end)
	local nextBtn = UIKit.Button(controls, "NEXT ›", UDim2.new(0.48, 0, 1, 0), Theme.Palette.PanelAlt, { textColor = Theme.Palette.Text })
	nextBtn.AnchorPoint = Vector2.new(1, 0)
	nextBtn.Position = UDim2.new(1, 0, 0, 0)
	nextBtn.TextScaled = false
	nextBtn.TextSize = Theme.TypeSize.Small
	nextBtn.Activated:Connect(function()
		if Spectator.OnCycle then Spectator.OnCycle("next") end
	end)
end

function Spectator:SetCycle(data)
	if not self.Store then return end
	self.Cycle = data.Cycle or self.Cycle or {}
	self.Index = 1
	if self.Store.Counter then
		self.Store.Counter.Text = ("%d/%d"):format(self.Index, #self.Cycle)
	end
end

function Spectator:ShowTarget(player)
	if self.Store and player then
		if self.Store.Target then
			self.Store.Target.Text = player.Name or "Player"
			self.Store.Target.TextColor3 = Theme.Brand.Gold
		end
		if self.Store.Avatar then
			local Players = game:GetService("Players")
			local ok, content = pcall(function()
				return Players:GetUserThumbnailAsync(
					player.UserId,
					Enum.ThumbnailType.HeadShot,
					Enum.ThumbnailSize.Size150x150
				)
			end)
			if ok and content then
				local label = self.Store.Avatar:FindFirstChildOfClass("ImageLabel")
				if not label then
					label = Instance.new("ImageLabel")
					label.Size = UDim2.fromScale(1, 1)
					label.BackgroundTransparency = 1
					label.Parent = self.Store.Avatar
				end
				label.Image = content
			end
		end
		if self.Store.Counter then
			self.Store.Counter.Text = ("%d/%d"):format(self.Index, #self.Cycle)
		end
	end
end

function Spectator:Clear()
	if self.Store then
		if self.Store.Target then
			self.Store.Target.Text = "WAITING"
			self.Store.Target.TextColor3 = Theme.Palette.TextDim
		end
		if self.Store.Counter then
			self.Store.Counter.Text = "0/0"
		end
	end
end

return Spectator
