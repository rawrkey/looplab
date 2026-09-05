-- PollService: server->client state sync via a single RemoteFunction.
-- Used because RemoteEvent:Connect is unavailable in some Studio play modes.

local RunService = game:GetService("RunService")
if RunService:IsClient() then return {} end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteBuilder = require(ReplicatedStorage.LOOPlab.Shared.RemoteBuilder)
local Queue = require(script.Parent.QueueService)
local Activity = require(script.Parent.ActivityService)
local Survival = require(script.Parent.SurvivalMatchService)
local PlayerData = require(script.Parent.PlayerDataService)
local Economy = require(script.Parent.EconomyService)

local Poll = {}
local _remotes = RemoteBuilder.GetAll()
local _toasts = {}

function Poll.TrackToast(player, message)
	if not player then return end
	local t = _toasts[player.UserId]
	if not t then
		t = {}
		_toasts[player.UserId] = t
	end
	table.insert(t, { message = message })
	if #t > 5 then table.remove(t, 1) end
end

local function economyFor(player)
	local data = PlayerData.GetForPlayer(player)
	if not data then return nil end
	return {
		Coins = data.Coins,
		Xp = data.Xp,
		Level = Economy.GetLevelFromXp(data.Xp),
	}
end

local function activityFor(player)
	local q = Queue.GetClientSync(player)
	if q and q.Mode == "Queue" then return q end
	local a = Activity.GetClientSync(player)
	if a and a.Mode == "Standalone" then return a end
	local s = Survival.GetClientSync(player)
	if s and s.Mode == "Survival" then return s end
	if q and q.Mode == "Results" then return q end
	if a and a.Mode == "Results" then return a end
	if s and s.Mode == "Results" then return s end
	return nil
end

function Poll.Setup()
	local guard = require(script.Parent.RemoteGuardService)
	guard.BindFunction(_remotes.Functions.PollActivity, function(player)
		local toasts = _toasts[player.UserId]
		_toasts[player.UserId] = nil
		return {
			Activity = activityFor(player),
			Economy = economyFor(player),
			Toasts = toasts,
		}
	end, "PollActivity")
end

return Poll