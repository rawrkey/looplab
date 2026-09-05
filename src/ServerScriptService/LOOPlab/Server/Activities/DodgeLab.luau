-- Dodge Lab: survive waves of falling hazards on a platform.
-- Server-authoritative hit tracking. Falling off costs HP; HP = 0 means eliminated
-- (placed last). Score = seconds survived (higher = better).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local ActivityDef = {
	Id = "dodge_lab",
	Name = "Dodge Lab",
	Description = "Outlast the hazard storm.",
	MinPlayers = 1,
	MaxPlayers = 12,
	DurationSeconds = 120,
	SurvivalDurationSeconds = 90,
	Scoring = "Survival time",
	HigherIsBetter = true,
	SupportsStandalone = true,
	SupportsSurvival = true,
}

local PLATFORM_HALF = 20
local TOP_Y = 2.5
local MAX_HP = 3
local MAX_HAZARDS = 30
local SPAWN_RATE = 2.2 -- seconds between spawns
local HURT_COOLDOWN = 1.0

local function rootOf(player)
	local char = player.Character
	if not char then return nil end
	return char:FindFirstChild("HumanoidRootPart"), char:FindFirstChildOfClass("Humanoid")
end

ActivityDef.Server = {
	Create = function(deps)
		local duration = deps.Duration
		local players = deps.Players
		local state = {
			elapsed = 0,
			done = false,
			hp = {},
			alive = {},
			survived = {},
			hazards = {},
			nextSpawn = 1,
			lastUpdate = 0,
			folder = nil,
		}

		local session = {}
		session.OnUpdate = deps.OnUpdate
		session.OnResult = deps.OnResult

		local folder = Instance.new("Folder")
		folder.Name = "LOOPLAB_DodgeLab_" .. tostring(os.time() + math.random(1, 9999))
		folder.Parent = Workspace
		state.folder = folder

		local platform = Instance.new("Part")
		platform.Name = "Platform"
		platform.Size = Vector3.new(PLATFORM_HALF * 2, 1, PLATFORM_HALF * 2)
		platform.Position = Vector3.new(0, TOP_Y - 1, 0)
		platform.Anchored = true
		platform.Color = Color3.fromRGB(70, 90, 120)
		platform.Parent = folder
		state.platform = platform

		for i, p in players do
			state.hp[p.UserId] = MAX_HP
			state.alive[p.UserId] = true
			local ang = (i / math.max(1, #players)) * math.pi * 2
			local r = 6
			task.delay(0.5, function()
				local root, hum = rootOf(p)
				if root then
					root.CFrame = CFrame.new(math.cos(ang) * r, TOP_Y + 2, math.sin(ang) * r)
					hum.WalkSpeed = 20
				end
			end)
		end

		local function spawnHazard()
			if state.done then return end
			local part = Instance.new("Part")
			part.Name = "Hazard"
			local brush = math.random(1, 3)
			local size = brush == 1 and 2 or brush == 2 and 1.2 or 0.7
			part.Size = Vector3.one * size
			part.Position = Vector3.new(math.random(-PLATFORM_HALF + 2, PLATFORM_HALF - 2), TOP_Y + 25, math.random(-PLATFORM_HALF + 2, PLATFORM_HALF - 2))
			part.Anchored = false
			part.CanCollide = true
			part.Material = Enum.Material.Neon
			part.Color = Color3.fromRGB(math.random(180, 255), math.random(20, 60), math.random(20, 60))
			part.Parent = folder

			-- bind damage once per collision burst
			local hurtInfo = { player = nil, last = 0 }
			part.Touched:Connect(function(other)
				if state.done then return end
				local p = Players:GetPlayerFromCharacter(other.Parent)
				if not p then return end
				if not state.alive[p.UserId] then return end
				local now = os.clock()
				if (now - (hurtInfo.last or 0)) < HURT_COOLDOWN then return end
				hurtInfo.last = now
				local hp = state.hp[p.UserId] - 1
				state.hp[p.UserId] = hp
				if hp <= 0 then
					state.alive[p.UserId] = false
					state.survived[p.UserId] = state.elapsed
				end
			end)
			table.insert(state.hazards, part)
		end

		local function killFalls()
			for _, p in players do
				if not p.Parent then continue end
				local uid = p.UserId
				if not state.alive[uid] then continue end
				local root, hum = rootOf(p)
				if not root or not hum then continue end
				if root.Position.Y < 0.2 then
					state.hp[uid] -= 1
					if state.hp[uid] <= 0 then
						state.alive[uid] = false
						state.survived[uid] = state.elapsed
					else
						hum.Health = hum.MaxHealth
						root.CFrame = CFrame.new(0, TOP_Y + 2, 0)
					end
				end
			end
		end

		local function broadcast()
			local hpData = {}
			for uid, hp in pairs(state.hp) do hpData[tostring(uid)] = hp end
			local aliveCount = 0
			for uid, alive in pairs(state.alive) do if alive then aliveCount += 1 end end
			session.OnUpdate({
				Phase = "active",
				Kind = "dodge_lab",
				TimeLeft = math.max(0, math.floor(duration - state.elapsed)),
				Hp = hpData,
				Alive = aliveCount,
			})
		end

		local function finish()
			if state.done then return end
			state.done = true
			for _, p in players do
				if state.alive[p.UserId] and not state.survived[p.UserId] then
					state.survived[p.UserId] = state.elapsed
				end
			end
			local rows = {}
			for _, p in players do
				table.insert(rows, {
					Player = p,
					Score = math.floor(state.survived[p.UserId] * 10),
					Time = state.survived[p.UserId],
					Ranks = { hp = state.hp[p.UserId] or 0 },
				})
			end
			table.sort(rows, function(a, b)
				if a.Score ~= b.Score then return a.Score > b.Score end
				return a.Ranks.hp > b.Ranks.hp
			end)
			session.OnResult({
				ActivityId = ActivityDef.Id,
				Mode = deps.Mode,
				Duration = duration,
				Rows = rows,
			})
		end

		session.Start = function()
			state.nextSpawn = SPAWN_RATE
			state.lastUpdate = os.clock()
		end

		session.Tick = function(_, dt)
			if state.done then return end
			state.elapsed += dt
			state.nextSpawn -= dt
			if state.nextSpawn <= 0 then
				state.nextSpawn = SPAWN_RATE
				if #state.hazards < MAX_HAZARDS then spawnHazard() end
			end
			killFalls()
			if state.elapsed - state.lastUpdate >= 0.5 then
				state.lastUpdate = state.elapsed
				pcall(broadcast)
			end
			local aliveCount = 0
			local oneLeft = nil
			for _, p in players do
				if p.Parent and state.alive[p.UserId] then aliveCount += 1; oneLeft = p end
			end
			if aliveCount <= 1 and #players > 1 then
				if aliveCount == 1 then
					local root, hum = rootOf(oneLeft)
					if root and hum then
						state.survived[oneLeft.UserId] = state.elapsed
					end
				end
				finish()
			end
		end

		session.ForceFinish = function()
			finish()
		end

		session.Cleanup = function()
			if state.folder then state.folder:Destroy(); state.folder = nil end
		end

		return session
	end,
}

return ActivityDef