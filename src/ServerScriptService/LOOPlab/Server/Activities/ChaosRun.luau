-- Chaos Run: a checkpoint race on a straight obstacle-free lane.
-- Server-authoritative: falls teleport you back to your last checkpoint; finishing
-- (or surviving to the end) earns points. Faster = better on ties.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local ActivityDef = {
	Id = "chaos_run",
	Name = "Chaos Run",
	Description = "Race across the lane, hit every checkpoint.",
	MinPlayers = 1,
	MaxPlayers = 12,
	DurationSeconds = 120,
	SurvivalDurationSeconds = 90,
	Scoring = "Points from checkpoints + speed bonus",
	HigherIsBetter = true,
	SupportsStandalone = true,
	SupportsSurvival = true,
}

local CHECKPOINTS = 6
local LANE_MIN_X = -10
local LANE_MAX_X = 10
local Z_START = -20
local Z_END = 30
local TOP_Y = 2.5

local function rootOf(player)
	local char = player.Character
	if not char then return nil end
	return char:FindFirstChild("HumanoidRootPart"), char:FindFirstChildOfClass("Humanoid")
end

local function newCheckpoint(index)
	local part = Instance.new("Part")
	part.Name = "Checkpoint_" .. index
	part.Size = Vector3.new(20, 1, 1)
	part.Position = Vector3.new(0, TOP_Y - 0.5, Z_START + ((Z_END - Z_START) / (CHECKPOINTS + 1)) * index)
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = true
	part.Transparency = 0.75
	part.Color = Color3.fromRGB(255, 200, 40)
	part.Material = Enum.Material.Neon
	return part
end

ActivityDef.Server = {
	Create = function(deps)
		local duration = deps.Duration
		local players = deps.Players
		local state = {
			started = os.clock(),
			elapsed = 0,
			done = false,
			cp = {},      -- userId -> checkpoint index reached
			finishTime = {}, -- userId -> elapsed seconds at finish
			root = {},
			checkpoints = {},
			folder = nil,
			lastUpdate = 0,
		}

		local session = {}
		session.OnUpdate = deps.OnUpdate
		session.OnResult = deps.OnResult

		-- build the reusable course under a session-scoped folder
		local folder = Instance.new("Folder")
		folder.Name = "LOOPLAB_ChaosRun_" .. tostring(os.time() + math.random(1, 9999))
		folder.Parent = Workspace
		state.folder = folder

		-- lane floor
		local floor = Instance.new("Part")
		floor.Name = "Lane"
		floor.Size = Vector3.new(20, 1, 70)
		floor.Position = Vector3.new(0, TOP_Y - 1.5, (Z_START + Z_END) / 2)
		floor.Anchored = true
		floor.Color = Color3.fromRGB(60, 60, 80)
		floor.Parent = folder
		state.floor = floor

		-- walls
		for _, x in { LANE_MIN_X - 0.5, LANE_MAX_X + 0.5 } do
			local wall = Instance.new("Part")
			wall.Size = Vector3.new(1, 3, 70)
			wall.Position = Vector3.new(x, TOP_Y - 0.5, (Z_START + Z_END) / 2)
			wall.Anchored = true
			wall.Color = Color3.fromRGB(40, 40, 60)
			wall.Parent = folder
		end

		for i = 1, CHECKPOINTS do
			table.insert(state.checkpoints, newCheckpoint(i))
			state.checkpoints[i].Parent = folder
		end

		-- spawn all players at start
		for i, p in players do
			local x = LANE_MIN_X + 2 + ((i - 1) % 8) * 2.2
			state.cp[p.UserId] = 0
			state.finishTime[p.UserId] = nil
			task.delay(0.5, function()
				local root, hum = rootOf(p)
				if root then
					root.CFrame = CFrame.new(x, TOP_Y + 2, Z_START + 2)
				end
				if hum then hum.WalkSpeed = 20 end
			end)
		end

		local function checkCheckpoints()
			for _, p in players do
				if not p.Parent then continue end
				local root, hum = rootOf(p)
				if not root then continue end
				local uid = p.UserId
				local cIdx = state.cp[uid] or 0
				if cIdx < CHECKPOINTS then
					local gate = state.checkpoints[cIdx + 1]
					if gate and (root.Position - gate.Position).Magnitude < 3 then
						state.cp[uid] = cIdx + 1
					end
				end
				if cIdx == CHECKPOINTS and not state.finishTime[uid] then
					state.finishTime[uid] = state.elapsed
				end
			end
		end

		local function checkFalls()
			for _, p in players do
				if not p.Parent then continue end
				local root, hum = rootOf(p)
				if not root or not hum then continue end
				if root.Position.Y < 0.5 or hum.Health <= 0 then
					local cIdx = state.cp[p.UserId] or 0
					local spawn = cIdx > 0 and state.checkpoints[cIdx] or state.checkpoints[1]
					hum.Health = hum.MaxHealth
					root.CFrame = (spawn.CFrame + Vector3.new(0, 3, 0)) * CFrame.Angles(0, 0, 0)
				end
			end
		end

		local function broadcast()
			local data = {}
			for uid, c in pairs(state.cp) do data[tostring(uid)] = c end
			session.OnUpdate({
				Phase = "active",
				TimeLeft = math.max(0, math.floor(duration - state.elapsed)),
				Kind = "chaos_run",
				Checkpoints = data,
			})
		end

		local function finish()
			if state.done then return end
			state.done = true
			local rows = {}
			for _, p in players do
				local uid = p.UserId
				local c = state.cp[uid] or 0
				local ft = state.finishTime[uid]
				local finished = ft ~= nil
				local score = 0
				if finished then
					score = 600 + math.max(0, math.floor((duration - ft) * 4))
				else
					score = c * 100
				end
				table.insert(rows, {
					Player = p,
					Score = score,
					Time = ft or duration,
					Ranks = { speed = score },
				})
			end
			table.sort(rows, function(a, b)
				if a.Score ~= b.Score then return a.Score > b.Score end
				return a.Time < b.Time
			end)
			session.OnResult({
				ActivityId = ActivityDef.Id,
				Mode = deps.Mode,
				Duration = duration,
				Rows = rows,
			})
		end

		session.Start = function()
			state.lastUpdate = os.clock()
		end

		session.Tick = function(_, dt)
			if state.done then return end
			state.elapsed += dt
			checkCheckpoints()
			checkFalls()
			if state.elapsed - state.lastUpdate >= 0.5 then
				state.lastUpdate = state.elapsed
				pcall(broadcast)
			end
			-- end early if everyone finished
			local allDone = true
			for _, p in players do
				if p.Parent and not state.finishTime[p.UserId] then allDone = false break end
			end
			if #players > 0 and allDone then finish() end
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