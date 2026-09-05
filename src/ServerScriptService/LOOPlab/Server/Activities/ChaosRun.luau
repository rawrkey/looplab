-- ChaosRun: checkpoint race on a raised lane track.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Contract = require(ReplicatedStorage.LOOPlab.Shared.ActivityContract)

local Activity = {
	Id = "chaos_run",
	Name = "Chaos Run",
	Description = "Race through checkpoints as fast as you can!",
	MinPlayers = 1,
	MaxPlayers = 12,
	DurationSeconds = 60,
	SurvivalDurationSeconds = 45,
	Scoring = "HigherIsBetter",
	HigherIsBetter = true,
	SupportsStandalone = true,
	SupportsSurvival = true,
}

local TrackLen = 360
local CPCount = 9
local LANE_HEIGHT = 5
local BASE_SCORE = 600

local checkpointInstance = Instance.new("Part")
checkpointInstance.Anchored = true
checkpointInstance.CanCollide = false
checkpointInstance.Transparency = 1
checkpointInstance.Size = Vector3.new(14, 8, 2)
checkpointInstance.Name = "CP"

local function makeLane()
	local lane = Instance.new("Part")
	lane.Anchored = true
	lane.CanCollide = true
	lane.Size = Vector3.new(6, 1, TrackLen)
	lane.Material = Enum.Material.Neon
	lane.Color = Color3.fromRGB(70, 70, 120)
	lane.Name = "Lane"
	return lane
end

local function makeBase()
	local base = Instance.new("Part")
	base.Anchored = true
	base.Size = Vector3.new(60, 1, TrackLen + 20)
	base.Position = Vector3.new(0, LANE_HEIGHT - 4, 0)
	base.Color = Color3.fromRGB(45, 45, 90)
	base.Material = Enum.Material.Grass
	base.Name = "Base"
	return base
end

local Session = {}
Session.__index = Session

local function newSession(deps)
	local self = setmetatable({}, Session)
	self.ActivityId = deps.ActivityId
	self.Mode = deps.Mode
	self.Difficulty = deps.Difficulty
	self.Duration = deps.Duration
	self.Players = deps.Players
	self.States = {}
	self.Finished = false
	self.Lane = makeLane()
	self.Base = makeBase()
	self.Checkpoints = {}
	return self
end

function Session:Start()
	local trackX = (self.ActivityId .. self.Mode):len()
	local laneX = 0
	if self.Mode == "Survival" then laneX = 8 else laneX = 0 end
	self.Lane.Position = Vector3.new(laneX, LANE_HEIGHT, 0)
	self.Lane.Parent = workspace
	self.Base.Parent = workspace

	for i = 1, CPCount do
		local cp = checkpointInstance:Clone()
		cp.Position = Vector3.new(laneX, LANE_HEIGHT + 3, -TrackLen / 2 + (i - 1) * (TrackLen / (CPCount - 1)))
		cp.Parent = workspace
		table.insert(self.Checkpoints, cp)
	end

	local start = Vector3.new(laneX, LANE_HEIGHT + 8, -TrackLen / 2)
	local endPos = Vector3.new(laneX, LANE_HEIGHT + 8, TrackLen / 2)
	for i, player in self.Players do
		local char = player.Character or player.CharacterAdded:Wait()
		if char then
			local hrp = char:WaitForChild("HumanoidRootPart", 5)
			if hrp then
				hrp.CFrame = CFrame.new(start.X + (i - 1) * 3, start.Y, start.Z)
			end
		end
		self.States[player.UserId] = { NextCP = 1, CPMult = 100, Score = 0, Finished = false }
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if hum then hum.WalkSpeed = 22 end
	end

	self.StartedAt = os.clock()
	for _, p in self.Players do
		self.OnUpdate({
			Kind = "MatchState",
			Mode = self.Mode,
			ActivityId = self.ActivityId,
			Phase = "running",
			Duration = self.Duration,
			TimeLeft = self.Duration,
			Message = "Run to the finish!",
		})
	end
end

function Session:Tick(dt)
	if self.Finished then return end
	local elapsed = os.clock() - self.StartedAt
	local remaining = math.max(0, self.Duration - elapsed)
	for _, p in self.Players do
		self.OnUpdate({
			Kind = "MatchState",
			Mode = self.Mode,
			ActivityId = self.ActivityId,
			Phase = "running",
			Duration = self.Duration,
			TimeLeft = remaining,
			Message = "Keep running!",
		})
	end
end

local function touchBind(self, player)
	local char = player.Character
	if not char then return end
	local body = char:FindFirstChild("HumanoidRootPart")
	if not body then return end
	local conn = body.Touched:Connect(function(hit)
		if self.Finished then return end
		local state = self.States[player.UserId]
		if not state or state.Finished then return end
		if hit.Parent == nil then return end
		local cpIndex = hit:GetAttribute("CPIndex")
		if not cpIndex then return end
		if cpIndex == state.NextCP then
			state.Score += state.CPMult
			state.NextCP += 1
			self.OnUpdate({
				Kind = "MatchState",
				Mode = self.Mode,
				ActivityId = self.ActivityId,
				Phase = "running",
				TimeLeft = self.Duration - (os.clock() - self.StartedAt),
				Message = "Checkpoint hit!",
			})
			if state.NextCP > CPCount then
				state.Finished = true
				state.Score += BASE_SCORE + math.floor((self.Duration - (os.clock() - self.StartedAt)) * 20)
				self.OnUpdate({ Kind = "MatchState", Mode = self.Mode, ActivityId = self.ActivityId, Phase = "finished", Message = "You finished!" })
				self.Finish()
			end
		end
	end)
	-- keepalive conn? cleanup
end

function Session:Finish()
	if self.Finished then return end
	self.Finished = true
	local rows = {}
	for _, p in self.Players do
		local s = self.States[p.UserId]
		if not s then s = { Score = 0, NextCP = 1 } end
		local score = s.Score
		if not s.Finished then
			score = (s.NextCP - 1) * 100
		end
		table.insert(rows, { Player = p, Score = score, Time = os.clock() - self.StartedAt, Ranks = { [self.ActivityId] = score } })
	end
	table.sort(rows, function(a, b) return a.Score > b.Score end)
	self.OnResult({ ActivityId = self.ActivityId, Mode = self.Mode, Duration = self.Duration, Rows = rows })
end

function Session:ForceFinish()
	self:Finish()
end

function Session:Cleanup()
	if self.Lane then self.Lane:Destroy() end
	if self.Base then self.Base:Destroy() end
	for _, cp in self.Checkpoints do
		cp:Destroy()
	end
end

Activity.Server = {
	Create = function(deps)
		local session = newSession(deps)
		-- ensure checkpoints have attributes
		for i, cp in session.Checkpoints do
	cp:SetAttribute("CPIndex", i)
		end
		return session
	end,
}

return Activity