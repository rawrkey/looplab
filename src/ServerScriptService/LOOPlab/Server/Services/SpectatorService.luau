-- SpectatorService: powers Survival round spectating.
-- After elimination (or from lobby), players enter spectate mode and preview a survivor.

local RunService = game:GetService("RunService")
if RunService:IsClient() then
	return {}
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteBuilder = require(ReplicatedStorage.LOOPlab.Shared.RemoteBuilder)
local Analytics = require(script.Parent.AnalyticsService)

local Service = {}
local _remotes = RemoteBuilder.GetAll()

-- userId -> { targetUserId }
local _targets = {}

-- Choose the next alive target for a spectator, cycling by id.
local function pickTarget(spectator: Player, direction: number): Player?
	local match = require(script.Parent.SurvivalMatchService)
	local alive = match.GetAlivePlayers()
	if #alive == 0 then return nil end

	local current = _targets[spectator.UserId] and _targets[spectator.UserId].targetUserId or 0
	local idx = 0
	for i, p in alive do
		if p.UserId == current then idx = i; break end
	end
	if idx == 0 then
		idx = 1
	else
		idx = idx + direction
		if idx > #alive then idx = 1 elseif idx < 1 then idx = #alive end
	end
	local target = alive[idx]
	_targets[spectator.UserId] = { targetUserId = target.UserId }
	return target
end

-- Bind remote handlers (called by SurvivalMatchService on init, or here).
function Service.Setup()
	local guard = require(script.Parent.RemoteGuardService)
	guard.BindFunction(_remotes.Functions.SpectateCycle, function(player: Player, dir: number)
		if type(dir) ~= "number" then return nil end
		local target = pickTarget(player, dir >= 0 and 1 or -1)
		if not target then return nil end
		Analytics.Fire(player, "SpectateStart", { a = "survival", b = tostring(target.UserId) })
		return { targetName = target.DisplayName, targetUserId = target.UserId }
	end, "SpectateCycle")

	guard.BindFunction(_remotes.Functions.React, function(player: Player, emote: string)
		if type(emote) ~= "string" then return nil end
		for _, p in Players:GetPlayers() do
			_remotes.Events.Emote:FireClient(p, { from = player.Name, emote = emote })
		end
		return true
	end, "React")
end

function Service.Reset(spectator: Player)
	_targets[spectator.UserId] = nil
end

function Service.GetTargetUserId(userId): number?
	local t = _targets[userId]
	return t and t.targetUserId or nil
end

function Service.Cleanup(player: Player)
	_targets[player.UserId] = nil
end

Players.PlayerRemoving:Connect(function(player)
	Service.Cleanup(player)
end)

return Service