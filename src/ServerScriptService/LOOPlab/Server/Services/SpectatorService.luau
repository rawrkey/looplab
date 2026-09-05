-- SpectatorService: camera cycle + emote reactions for eliminated players.

local RunService = game:GetService("RunService")
if RunService:IsClient() then return {} end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteBuilder = require(ReplicatedStorage.LOOPlab.Shared.RemoteBuilder)

local Service = {}
local _remotes = RemoteBuilder.GetAll()
local _state = { active = {}, cycle = {} }

function Service.BeginSpectating(player: Player, targets: { Player })
	local t = {}
	for _, p in targets do
		if p ~= player then t[#t + 1] = p end
	end
	_state.active[player.UserId] = { targets = t, index = 1 }
	_remotes.Events.SpectateUpdate:FireClient(player, { Kind = "Begin", Cycle = t })
end

function Service.StopSpectating(player: Player)
	_state.active[player.UserId] = nil
	_remotes.Events.SpectateUpdate:FireClient(player, { Kind = "Stop" })
end

function Service.Cycle(player: Player, direction: string)
	local s = _state.active[player.UserId]
	if not s or #s.targets == 0 then return end
	if direction == "prev" then
		s.index = s.index - 1
		if s.index < 1 then s.index = #s.targets end
	else
		s.index = s.index + 1
		if s.index > #s.targets then s.index = 1 end
	end
	local target = s.targets[s.index]
	_remotes.Events.SpectateUpdate:FireClient(player, { Kind = "Cycle", Target = target })
end

function Service.React(emote: string, fromUserId: number, toPlayer: Player)
	_remotes.Events.Emote:FireClient(toPlayer, { From = fromUserId, Emote = emote })
end

function Service.Setup()
	local guard = require(script.Parent.RemoteGuardService)
	guard.BindFunction(_remotes.Functions.SpectateCycle, function(player: Player, direction: any)
		if type(direction) ~= "string" then return nil end
		Service.Cycle(player, direction)
		return { ok = true }
	end, "SpectateCycle")

	guard.BindFunction(_remotes.Functions.React, function(player: Player, emote: any, toUserId: any)
		if type(emote) ~= "string" or type(toUserId) ~= "number" then return nil end
		local target = Players:GetPlayerByUserId(toUserId)
		if target then
			Service.React(emote, player.UserId, target)
		end
		return { ok = true }
	end, "React")
end

return Service