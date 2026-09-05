-- SpectatorController: eliminated players browse surviving targets.

local ViewController = require(script.Parent.Parent.Components.ViewController)
local AudioService = require(script.Parent.Parent.Components.AudioService)

local SpectatorController = {}

local Screen
local Cycle = {}
local Index = 1

function SpectatorController.Init(screens)
	Screen = screens.Spectator
	Screen.OnCycle = function(dir)
		SpectatorController.Cycle(dir)
	end
end

function SpectatorController.Begin(payload)
	Cycle = payload.Cycle or {}
	Index = 1
	ViewController.Show("Spectator", { Cycle = Cycle })
	if #Cycle == 0 then
		Screen:Clear()
		return
	end
	SpectatorController.Target()
end

function SpectatorController.Target()
	local u = Cycle[Index]
	if not u then
		Screen:Clear()
		return
	end
	Screen:ShowTarget(u)
end

function SpectatorController.Cycle(dir)
	if #Cycle == 0 then return end
	AudioService.PlayClick()
	if dir == "next" then
		Index = Index + 1
		if Index > #Cycle then Index = 1 end
	elseif dir == "prev" then
		Index = Index - 1
		if Index < 1 then Index = #Cycle end
	end
	SpectatorController.Target()
end

function SpectatorController.Stop()
	Cycle = {}
end

return SpectatorController