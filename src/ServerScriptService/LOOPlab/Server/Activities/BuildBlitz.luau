-- Build Blitz: stack blocks on your plot, server-validated.
-- Client sends "place" { x, z } grid cell; server verifies the cell is legal
-- (on the ground or directly on top of an existing block) and increments it.
-- Score = number of blocks placed (height). Faster placement = more blocks.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local ActivityDef = {
	Id = "build_blitz",
	Name = "Build Blitz",
	Description = "Stack your tower as high as you can.",
	MinPlayers = 1,
	MaxPlayers = 12,
	DurationSeconds = 90,
	SurvivalDurationSeconds = 60,
	Scoring = "Blocks placed",
	HigherIsBetter = true,
	SupportsStandalone = true,
	SupportsSurvival = true,
}

local CELL = 2      -- grid cell size
local GRID = 3      -- grid is GRID x GRID
local MAX_CELL_H = 50
local TOP_Y = 2.5

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
			placed = {},  -- userId -> { [cellKey] = height }
			cells = {},   -- userId -> { [cellKey] = Part }
			lastUpdate = 0,
			folder = nil,
		}

		local session = {}
		session.OnUpdate = deps.OnUpdate
		session.OnResult = deps.OnResult

		local folder = Instance.new("Folder")
		folder.Name = "LOOPLAB_BuildBlitz_" .. tostring(os.time() + math.random(1, 9999))
		folder.Parent = Workspace
		state.folder = folder

		local function slotPos(index)
			local per = math.ceil(math.sqrt(#players))
			local col = (index - 1) % per
			local row = math.floor((index - 1) / per)
			local span = (GRID - 1) * CELL + CELL
			local ox = (col - (per - 1) / 2) * (span + 8)
			local oz = (row - (per - 1) / 2) * (span + 8)
			return ox, oz
		end

		-- build each player's plot floor
		for i, p in players do
			local ox, oz = slotPos(i)
			state.placed[p.UserId] = {}
			state.cells[p.UserId] = {}
			local floor = Instance.new("Part")
			floor.Name = "Plot_" .. p.Name
			floor.Size = Vector3.new(GRID * CELL, 1, GRID * CELL)
			floor.Position = Vector3.new(ox, TOP_Y - 1, oz)
			floor.Anchored = true
			local hue = (i / math.max(1, #players)) * 0.5
			floor.Color = Color3.fromHSV(hue, 0.6, 0.8)
			floor.Parent = folder
			state.plots = state.plots or {}
			state.plots[p.UserId] = { ox = ox, oz = oz }
			task.delay(0.4, function()
				local root, hum = rootOf(p)
				if root then
					root.CFrame = CFrame.new(ox, TOP_Y + 2, oz)
					hum.WalkSpeed = 16
				end
			end)
		end

		local function placeBlock(p, x, z)
			local uid = p.UserId
			local plot = state.plots[uid]
			if not plot then return false, "no plot" end
			if x < 0 or z < 0 or x >= GRID or z >= GRID then return false, "out of range" end
			local key = x .. "_" .. z
			local h = state.placed[uid][key] or 0
			if h >= MAX_CELL_H then return false, "height cap" end
			if h > 0 then
				-- must exist (it does); we only allow incrementing existing stack = place on top
			else
				-- ground placement is always allowed
			end
			state.placed[uid][key] = h + 1
			local block = Instance.new("Part")
			block.Name = "Block"
			block.Size = Vector3.new(CELL - 0.1, CELL - 0.1, CELL - 0.1)
			block.Position = Vector3.new(plot.ox + x * CELL, TOP_Y - 0.5 + (h + 0.5) * CELL, plot.oz + z * CELL)
			block.Anchored = true
			block.Color = Color3.fromHSV((x + z * 0.5) / (GRID * 2), 0.5, 1)
			block.Parent = folder
			state.cells[uid][key] = block
			return true, block
		end

		local function broadcast()
			local heights = {}
			for uid, cells in pairs(state.placed) do
				local total = 0
				for _, h in cells do total += h end
				heights[tostring(uid)] = total
			end
			session.OnUpdate({
				Phase = "active",
				Kind = "build_blitz",
				TimeLeft = math.max(0, math.floor(duration - state.elapsed)),
				Heights = heights,
			})
		end

		local function finish()
			if state.done then return end
			state.done = true
			local rows = {}
			for _, p in players do
				local total = 0
				local maxH = 0
				for _, h in pairs(state.placed[p.UserId]) do total += h; maxH = math.max(maxH, h) end
				table.insert(rows, {
					Player = p,
					Score = total,
					Time = state.elapsed,
					Ranks = { maxH = maxH },
				})
			end
			table.sort(rows, function(a, b)
				if a.Score ~= b.Score then return a.Score > b.Score end
				return a.Ranks.maxH > b.Ranks.maxH
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
			if state.elapsed - state.lastUpdate >= 0.5 then
				state.lastUpdate = state.elapsed
				pcall(broadcast)
			end
		end

		session.HandleInput = function(_, player, action, data)
			if state.done then return end
			if action ~= "place" then return end
			if type(data) ~= "table" then return end
			local x = data.x
			local z = data.z
			if type(x) ~= "number" or type(z) ~= "number" then return end
			placeBlock(player, math.floor(x), math.floor(z))
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