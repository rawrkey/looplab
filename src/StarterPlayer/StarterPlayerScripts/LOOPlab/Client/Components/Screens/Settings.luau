-- Settings: audio + accessibility prefs. Persists booleans via SettingsSet remote.

local UIKit = require(script.Parent.Parent.UIKit)
local Theme = require(script.Parent.Parent.Theme)
local AudioService = require(script.Parent.Parent.AudioService)

local Settings = {
	Name = "Settings",
	Root = nil,
	Store = {},
	OnClose = nil,
	OnSave = nil,
	ReducedMotion = false,
}

function Settings:Hide()
	if self.Root then self.Root.Visible = false end
end

function Settings:Show()
	if not self.Root then return end
	self.Root.Visible = true
	UIKit.SlideUpIn(self.Panel, 0.04, Theme.Motion.Normal)
end

function Settings:Build(parent)
	local root = UIKit.Frame({
		Parent = parent,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	})
	self.Root = root

	local scrim = UIKit.Frame({ Parent = root, Size = UDim2.fromScale(1, 1), BackgroundColor3 = Theme.Palette.Scrim, BackgroundTransparency = Theme.Opacity.Scrim })
	scrim.BorderSizePixel = 0

	local panel = UIKit.Card(root, UDim2.new(0.5, 0, 0.6, 0), Theme.Brand.Primary)
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.BackgroundTransparency = Theme.Opacity.Card
	self.Panel = panel

	local edge = UIKit.Frame({ Parent = panel, Size = UDim2.new(1, 0, 0, 3), AnchorPoint = Vector2.new(0, 0), BackgroundColor3 = Theme.Brand.Primary })
	UIKit.Corner(Theme.Radius.Small).Parent = edge

	local title = UIKit.Title(panel, "SETTINGS", UDim2.new(0.96, 0, 0, 36), Theme.Palette.Text)
	title.AnchorPoint = Vector2.new(0, 0)
	title.Position = UDim2.new(0.02, 0, 0.05, 0)
	title.TextScaled = false
	title.TextSize = Theme.TypeSize.Huge
	title.TextXAlignment = Enum.TextXAlignment.Left

	local close = UIKit.Button(panel, "✕", UDim2.fromOffset(34, 34), Theme.Palette.PanelAlt, { textColor = Theme.Palette.TextDim })
	close.AnchorPoint = Vector2.new(1, 0)
	close.Position = UDim2.new(0.97, 0, 0.05, 0)
	close.TextScaled = false
	close.TextSize = Theme.TypeSize.Small
	close.Activated:Connect(function()
		if Settings.OnClose then Settings.OnClose() end
	end)

	local function toggleRow(yScale, label, desc, stateRef, onChange)
		local row = UIKit.Card(panel, UDim2.new(0.96, 0, 0, 56), Theme.Palette.StrokeDim)
		row.AnchorPoint = Vector2.new(0.5, 0)
		row.Position = UDim2.new(0.5, 0, yScale, 0)
		row.BackgroundTransparency = Theme.Opacity.Card

		local lab = UIKit.Muted(row, label, UDim2.new(0.6, 0, 0, 18), Theme.Palette.Text)
		lab.AnchorPoint = Vector2.new(0, 0)
		lab.Position = UDim2.new(0.04, 0, 0.18, 0)
		lab.TextScaled = false
		lab.TextSize = Theme.TypeSize.Body
		lab.TextXAlignment = Enum.TextXAlignment.Left

		local d = UIKit.Muted(row, desc or "", UDim2.new(0.6, 0, 0, 14), Theme.Palette.TextFaint)
		d.AnchorPoint = Vector2.new(0, 0)
		d.Position = UDim2.new(0.04, 0, 0.5, 0)
		d.TextScaled = false
		d.TextSize = Theme.TypeSize.Tiny
		d.TextXAlignment = Enum.TextXAlignment.Left

		local val = UIKit.Title(row, "ON", UDim2.new(0.16, 0, 0.5, 0), Theme.Brand.Success)
		val.AnchorPoint = Vector2.new(1, 0.5)
		val.Position = UDim2.new(0.86, 0, 0.5, 0)
		val.TextScaled = false
		val.TextSize = Theme.TypeSize.Header
		val.TextXAlignment = Enum.TextXAlignment.Right

		local btn = UIKit.Button(row, "TOGGLE", UDim2.new(0.18, 0, 0, 32), Theme.Brand.Primary, { textColor = Color3.new(1, 1, 1) })
		btn.AnchorPoint = Vector2.new(1, 0.5)
		btn.Position = UDim2.new(0.97, 0, 0.5, 0)
		btn.TextScaled = false
		btn.TextSize = Theme.TypeSize.Tiny
		btn.Activated:Connect(function()
			onChange()
			local on = stateRef()
			val.Text = on and "ON" or "OFF"
			val.TextColor3 = on and Theme.Brand.Success or Theme.Palette.TextDim
			Settings.Dirty = true
		end)
		return val
	end

	local musicVal = toggleRow(0.18, "Music", "Background music", function() return AudioService.GetMusicVolume() > 0 end, function()
		AudioService.SetMusicVolume(AudioService.GetMusicVolume() > 0 and 0 or 0.5)
	end)
	local sfxVal = toggleRow(0.42, "Sound Effects", "Game SFX and feedback", function() return AudioService.GetSfxVolume() > 0 end, function()
		AudioService.SetSfxVolume(AudioService.GetSfxVolume() > 0 and 0 or 0.65)
	end)
	local motionVal = toggleRow(0.66, "Reduced Motion", "Disable non-essential animations", function() return Settings.ReducedMotion end, function()
		Settings.ReducedMotion = not Settings.ReducedMotion
	end)

	self.Store.MusicVal = musicVal
	self.Store.SfxVal = sfxVal
	self.Store.MotionVal = motionVal

	local saveBtn = UIKit.GradientButton(panel, "SAVE", UDim2.new(0.5, 0, 0, 40), Theme.Brand.Success, { rotation = 0, secondary = Theme.Brand.Primary })
	saveBtn.AnchorPoint = Vector2.new(0.5, 1)
	saveBtn.Position = UDim2.new(0.5, 0, 0.96, 0)
	saveBtn.TextScaled = false
	saveBtn.TextSize = Theme.TypeSize.Body
	saveBtn.Activated:Connect(function()
		if Settings.OnSave then Settings.OnSave() end
	end)
end

function Settings:GetSettings()
	return {
		MusicVolume = AudioService.GetMusicVolume(),
		SfxVolume = AudioService.GetSfxVolume(),
		ReducedMotion = self.ReducedMotion,
	}
end

function Settings:Apply(saved)
	saved = saved or {}
	if saved.MusicOn == false then AudioService.SetMusicVolume(0) end
	if saved.SfxOn == false then AudioService.SetSfxVolume(0) end
	self.ReducedMotion = saved.ReducedMotion == true
end

function Settings:Refresh()
	if self.Store then
		if self.Store.MusicVal then
			local on = AudioService.GetMusicVolume() > 0
			self.Store.MusicVal.Text = on and "ON" or "OFF"
			self.Store.MusicVal.TextColor3 = on and Theme.Brand.Success or Theme.Palette.TextDim
		end
		if self.Store.SfxVal then
			local on = AudioService.GetSfxVolume() > 0
			self.Store.SfxVal.Text = on and "ON" or "OFF"
			self.Store.SfxVal.TextColor3 = on and Theme.Brand.Success or Theme.Palette.TextDim
		end
		if self.Store.MotionVal then
			local on = self.ReducedMotion
			self.Store.MotionVal.Text = on and "ON" or "OFF"
			self.Store.MotionVal.TextColor3 = on and Theme.Brand.Success or Theme.Palette.TextDim
		end
	end
end

return Settings
