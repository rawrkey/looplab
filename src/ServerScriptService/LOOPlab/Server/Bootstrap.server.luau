-- LOOPLAB server bootstrap. Starts all services in dependency order.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

if RunService:IsClient() then
	return
end
if _G.LOOPLAB_BOOTSTRAPPED then
	return
end
_G.LOOPLAB_BOOTSTRAPPED = true

local SSS = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local lab = SSS:WaitForChild("LOOPlab", 60)
local server = lab:WaitForChild("Server", 60)
local servicesFolder = server:WaitForChild("Services", 60)
local activitiesFolder = server:WaitForChild("Activities", 60)

local OK = {}

local function startService(name)
	local module = servicesFolder:FindFirstChild(name)
	if not module then
		warn("[Bootstrap] missing service " .. name)
		return false
	end
	local ok, svc = pcall(require, module)
	if not ok then
		warn("[Bootstrap] failed to start " .. name .. ": " .. tostring(svc))
		return false
	end
	if type(svc) == "table" and type(svc.Setup) == "function" then
		pcall(svc.Setup, svc)
	end
	table.insert(OK, name)
	return true
end

-- 1. low-level infra
startService("AnalyticsService")
startService("RemoteGuardService")

-- 2. persistence / accounts
startService("PlayerDataService")
startService("EconomyService")
startService("CosmeticService")
startService("MonetizationService")
startService("LeaderboardService")
startService("DailyChallengeService")
startService("ProgressionService")

-- 3. gameplay orchestration
startService("ActivityService")
startService("QueueService")
startService("SpectatorService")
startService("SurvivalMatchService")
startService("RewardService")
startService("PollService")

-- register activities
local registry = require(ReplicatedStorage:WaitForChild("LOOPlab").Shared.ActivityRegistry)
for _, child in activitiesFolder:GetChildren() do
	if child:IsA("ModuleScript") then
		registry.Register(child)
	end
end

print("[LOOPLAB] Bootstrap complete. Services started: " .. table.concat(OK, ", "))
print("[LOOPLAB] Registered activities: " .. table.concat(registry.GetAllIds(), ", "))