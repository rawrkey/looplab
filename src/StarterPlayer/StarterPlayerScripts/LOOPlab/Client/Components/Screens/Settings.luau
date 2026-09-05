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
	UIKit.SlideIn(self.Panel, 0.03, Theme.Motion.Normal)
end

function Settings:Build(parent)
	local root = UIKit.Frame({
		Parent = parent,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	})
	self.Root = root

	local scrim = UIKit.Frame({ Parent = root, Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.5, BorderSizePixel = 0 })

	local panel = UIKit.PanelAlt(root, UDim2.new(0.5, 0, 0.66, 0), Theme.Brand.Primary)
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	self.Panel = panel

	local title = UIKit.Title(panel, "SETTINGS", UDim2.new(1, 0, 0, 52), Theme.Brand.Primary)
	title.TextScaled = false
	title.TextSize = Theme.TypeSize.Huge

	local function toggleRow(yLabel, label, stateRef, onChange)
		local row = UIKit.Frame({ Parent = panel, Size = UDim2.new(0.96, 0, 0, 44), Position = UDim2.new(0.02, 0, yLabel, 0) })
		row.BackgroundTransparency = 1
		local lab = UIKit.Text(row, label, UDim2.new(0.6, 0, 0.5, 0), Theme.Palette.TextDim)
		lab.Position = UDim2.new(0, 0, 0.25, 0)
		lab.TextScaled = false
		lab.TextSize = Theme.TypeSize.Body
		local val = UIKit.Text(row, stateRef() and "ON" or "OFF", UDim2.new(0.2, 0, 0.5, 0), Theme.Brand.Primary)
		val.Position = UDim2.new(0.6, 0, 0.25, 0)
		val.TextScaled = false
		val.TextSize = Theme.TypeSize.Body
		local btn = UIKit.Button(row, "Toggle", UDim2.new(0.16, 0, 0, 28), Theme.Palette.Panel, { textColor = Theme.Palette.Text })
		btn.Position = UDim2.new(0.82, 0, 0.22, 0)
		btn.TextScaled = false
		btn.TextSize = Theme.TypeSize.Tiny
		btn.Activated:Connect(function()
			onChange()
			val.Text = stateRef() and "ON" or "OFF"
			Settings.Dirty = true
		end)
		return val
	end

	local musicVal = toggleRow(0.2, "Music", function() return AudioService.GetMusicVolume() > 0 end, function()
		AudioService.SetMusicVolume(AudioService.GetMusicVolume() > 0 and 0 or 0.5)
	end)
	local sfxVal = toggleRow(0.34, "Sound Effects", function() return AudioService.GetSfxVolume() > 0 end, function()
		AudioService.SetSfxVolume(AudioService.GetSfxVolume() > 0 and 0 or 0.65)
	end)
	local motionVal = toggleRow(0.48, "Reduced Motion", function() return Settings.ReducedMotion end, function()
		Settings.ReducedMotion = not Settings.ReducedMotion
	end)

	self.Store.MusicVal = musicVal
	self.Store.SfxVal = sfxVal
	self.Store.MotionVal = motionVal

	local hint = UIKit.Text(panel, "Audio prefs are local · accessibility persists", UDim2.new(0.96, 0, 0, 22), Theme.Palette.TextFaint)
	hint.Position = UDim2.new(0.02, 0, 0.56, 0)
	hint.TextScaled = false
	hint.TextSize = Theme.TypeSize.Small

	local saveBtn = UIKit.GradientButton(panel, "SAVE", UDim2.new(0.5, 0, 0, 44), Theme.Brand.Success)
	saveBtn.AnchorPoint = Vector2.new(0.5, 1)
	saveBtn.Position = UDim2.new(0.5, 0, 1, -10)
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
		if self.Store.MusicVal then self.Store.MusicVal.Text = AudioService.GetMusicVolume() > 0 and "ON" or "OFF" end
		if self.Store.SfxVal then self.Store.SfxVal.Text = AudioService.GetSfxVolume() > 0 and "ON" or "OFF" end
		if self.Store.MotionVal then self.Store.MotionVal.Text = self.ReducedMotion and "ON" or "OFF" end
	end
end

return Settings