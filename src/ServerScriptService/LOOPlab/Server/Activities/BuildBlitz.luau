-- BuildBlitz: place blocks within your plot in a limited time.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Contract = require(ReplicatedStorage.LOOPlab.Shared.ActivityContract)

local Activity = {
	Id = "build_blitz",
	Name = "Build Blitz",
	Description = "Stack as many blocks as you can in your plot!",
	MinPlayers = 1,
	MaxPlayers = 12,
	DurationSeconds = 45,
	SurvivalDurationSeconds = 45,
	Scoring = "HigherIsBetter",
	HigherIsBetter = true,
	SupportsStandalone = true,
	SupportsSurvival = true,
}

local PLOT = 10 -- per-player plot width
local MAX_BLOCKS = 30
local BLOCK = Vector3.new(1, 1, 1)

local Session = {}
Session.__index = Session

local function newSession(deps)
	local self = setmetatable({}, Session)
	self.ActivityId = deps.ActivityId
	self.Mode = deps.Mode
	self.Players = deps.Players
	self.Duration = deps.Duration
	self.States = {}
	self.Plots = {}
	self.Finished = false
	self.StartedAt = os.clock()
	return self
end

local function makePlot(player, index)
	local ground = Instance.new("Part")
	ground.Anchored = true
	ground.Size = Vector3.new(PLOT, 1, PLOT)
	ground.Position = Vector3.new(index * (PLOT + 4), 0.5, 0)
	ground.Color = Color3.fromRGB(70, 110, 70)
	ground.Material = Enum.Material.Ground
	ground.Name = "Plot" .. tostring(player.UserId)
	ground:SetAttribute("Owner", tostring(player.UserId))
	ground.Parent = workspace
	return ground
end

local function placeBlock(self, player)
	local state = self.States[player.UserId]
	if not state then return end
	if state.BlockedCount >= MAX_BLOCKS then return false end
	local ground = state.Ground
	local origin = ground.Position
	local x = origin.X + math.random(-(PLOT / 2 - 1), PLOT / 2 - 1)
	local z = origin.Z + math.random(-(PLOT / 2 - 1), PLOT / 2 - 1)
	local y = origin.Y + state.BlockedCount + 1
	local b = Instance.new("Part")
	b.Size = BLOCK
	b.Anchored = true
	b.Position = Vector3.new(x, y, z)
	b.Color = Color3.fromRGB(200, 180, 80)
	b.Material = Enum.Material.Metal
	b.Name = "BuildBlock"
	b.Parent = workspace
	state.BlockParts[#state.BlockParts + 1] = b
	state.BlockedCount += 1
	state.Score = state.BlockedCount
	self.OnUpdate({
		Kind = "MatchState",
		Mode = self.Mode,
		ActivityId = self.ActivityId,
		Phase = "running",
		TimeLeft = math.max(0, self.Duration - (os.clock() - self.StartedAt)),
		Message = ("Blocks: %d"):format(state.BlockedCount),
	})
	return true
end

function Session:Start()
	for i, player in self.Players do
		local ground = makePlot(player, i)
		self.Plots[player.UserId] = ground
		self.States[player.UserId] = {
			Ground = ground,
			BlockedCount = 0,
			Score = 0,
			BlockParts = {},
		}
		local char = player.Character or player.CharacterAdded:Wait()
		if char then
			local hrp = char:WaitForChild("HumanoidRootPart", 5)
			if hrp then
				hrp.CFrame = ground.CFrame + Vector3.new(0, 3, PLOT / 2 + 2)
			end
		end
	end
	self.StartedAt = os.clock()
	for _, p in self.Players do
		self.OnUpdate({ Kind = "MatchState", Mode = self.Mode, ActivityId = self.ActivityId, Phase = "running", TimeLeft = self.Duration, Message = "Build your tower!" })
	end
end

function Session:HandleInput(player, action, data)
	if self.Finished then return end
	local state = self.States[player.UserId]
	if not state then return end
	if action == "place" then
		placeBlock(self, player)
	end
end

function Session:Tick(dt)
	self.OnUpdate({
		Kind = "MatchState",
		Mode = self.Mode,
		ActivityId = self.ActivityId,
		Phase = "running",
		TimeLeft = math.max(0, self.Duration - (os.clock() - self.StartedAt)),
		Message = "Keep building!",
	})
end

function Session:Finish()
	if self.Finished then return end
	self.Finished = true
	local rows = {}
	for _, p in self.Players do
		local s = self.States[p.UserId]
		table.insert(rows, { Player = p, Score = s.Score, Time = (os.clock() - self.StartedAt), Ranks = { [self.ActivityId] = s.Score } })
	end
	table.sort(rows, function(a, b) return a.Score > b.Score end)
	self.OnResult({ ActivityId = self.ActivityId, Mode = self.Mode, Duration = self.Duration, Rows = rows })
end

function Session:ForceFinish()
	self:Finish()
end

function Session:Cleanup()
	for _, p in self.Players do
		local state = self.States[p.UserId]
		if state and state.Ground then state.Ground:Destroy() end
		if state and state.BlockParts then
			for _, b in state.BlockParts do
				if b.Parent then b:Destroy() end
			end
		end
		local char = p.Character
		if char then
			local hrp = char:FindFirstChild("HumanoidRootPart")
			if hrp then hrp.CFrame = CFrame.new(0, 10, 0) end
		end
	end
end

Activity.Server = {
	Create = function(deps)
		return newSession(deps)
	end,
}

return Activity