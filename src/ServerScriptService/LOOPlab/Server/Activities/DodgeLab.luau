-- DodgeLab: dodge falling hazards on an elevated platform.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Contract = require(ReplicatedStorage.LOOPlab.Shared.ActivityContract)

local Activity = {
	Id = "dodge_lab",
	Name = "Dodge Lab",
	Description = "Dodge falling hazards for as long as you can!",
	MinPlayers = 1,
	MaxPlayers = 12,
	DurationSeconds = 45,
	SurvivalDurationSeconds = 30,
	Scoring = "HigherIsBetter",
	HigherIsBetter = true,
	SupportsStandalone = true,
	SupportsSurvival = true,
}

local PLATFORM = Vector3.new(60, 1, 60)
local HAZARD_COUNT = 8
local HURT_COOLDOWN = 1.0
local START_HITS = 3

local Session = {}
Session.__index = Session

local function newSession(deps)
	local self = setmetatable({}, Session)
	self.ActivityId = deps.ActivityId
	self.Mode = deps.Mode
	self.Players = deps.Players
	self.Duration = deps.Duration
	self.States = {}
	self.Hazards = {}
	self.Finished = false
	self.TickAcc = 0
	return self
end

local function makePlatform()
	local plat = Instance.new("Part")
	plat.Anchored = true
	plat.Size = PLATFORM
	plat.Position = Vector3.new(0, 2, 0)
	plat.Color = Color3.fromRGB(90, 40, 40)
	plat.Material = Enum.Material.Neon
	plat.Name = "DodgePlatform"
	return plat
end

local function spawnHazard(self)
	local h = Instance.new("Part")
	h.Size = Vector3.new(2, 2, 2)
	h.Shape = Enum.PartType.Block
	h.BrickColor = BrickColor.new("Really red")
	h.Anchored = false
	h.CanCollide = true
	h.Material = Enum.Material.SmoothPlastic
	h.Name = "Hazard"
	h.Position = Vector3.new(math.random(-20, 20), 40, math.random(-20, 20))
	h.Touched:Connect(function(part)
		if self.Finished then return end
		if not part then return end
		local model = part.Parent
		if not model or not model:IsA("Model") then return end
		local player = self.Players and nil
		for _, p in self.Players do
			if p.Character == model then player = p break end
		end
		if player then hitHazard(self, player, h) end
	end)
	h.Parent = workspace
	table.insert(self.Hazards, h)
	task.delay(8, function()
		if h.Parent then h:Destroy() end
	end)
	return h
end

local function hitHazard(self, player, hazard)
	if self.Finished then return end
	local state = self.States[player.UserId]
	if not state then return end
	local now = os.clock()
	if now - (state.LastHit or 0) < HURT_COOLDOWN then return end
	state.LastHit = now
	state.Hits += 1
	state.Score = math.max(0, state.Score)
	self.OnUpdate({
		Kind = "MatchState",
		Mode = self.Mode,
		ActivityId = self.ActivityId,
		Phase = "running",
		TimeLeft = math.max(0, self.Duration - (os.clock() - self.StartedAt)),
		Message = ("Hits: %d/%d"):format(state.Hits, START_HITS),
	})
	if state.Hits >= START_HITS then
		state.Out = true
		state.Score = self.Elapsed
		self.OnUpdate({ Kind = "MatchState", Mode = self.Mode, ActivityId = self.ActivityId, Phase = "eliminated", Message = "Eliminated!" })
		if self.Mode == "Survival" then
			-- survival rounds end when all but one are out
			local active = 0
			for _, p in self.Players do
				local st = self.States[p.UserId]
				if st and not st.Out then active += 1 end
			end
			if active <= 1 then self:Finish() end
		else
			self:Finish()
		end
	end
end

function Session:Start()
	self.Platform = makePlatform()
	self.Platform.Parent = workspace
	for i, player in self.Players do
		local char = player.Character or player.CharacterAdded:Wait()
		if char then
			local hrp = char:WaitForChild("HumanoidRootPart", 5)
			if hrp then
				hrp.CFrame = CFrame.new(math.random(-10, 10), 6, math.random(-10, 10))
			end
		end
		self.States[player.UserId] = { Hits = 0, Score = 0, Out = false }
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if hum then hum.WalkSpeed = 16 end
	end
	self.StartedAt = os.clock()
	self.Elapsed = 0
	for _, p in self.Players do
		self.OnUpdate({ Kind = "MatchState", Mode = self.Mode, ActivityId = self.ActivityId, Phase = "running", TimeLeft = self.Duration, Message = "Dodge the hazards!" })
	end
end

function Session:Tick(dt)
	if self.Finished then return end
	self.Elapsed = os.clock() - self.StartedAt
	self.TickAcc += dt
	if self.TickAcc >= 0.8 then
		self.TickAcc = 0
		if #self.Hazards < HAZARD_COUNT then
			spawnHazard(self)
		end
	end
	self.OnUpdate({
		Kind = "MatchState",
		Mode = self.Mode,
		ActivityId = self.ActivityId,
		Phase = "running",
		TimeLeft = math.max(0, self.Duration - self.Elapsed),
		Message = "Keep dodging!",
	})
end

function Session:Finish()
	if self.Finished then return end
	self.Finished = true
	local rows = {}
	for _, p in self.Players do
		local s = self.States[p.UserId]
		local score = s and s.Out and s.Score or s.Score or 0
		table.insert(rows, { Player = p, Score = score * 10, Time = self.Elapsed or 0, Ranks = { [self.ActivityId] = score } })
	end
	table.sort(rows, function(a, b) return a.Score > b.Score end)
	self.OnResult({ ActivityId = self.ActivityId, Mode = self.Mode, Duration = self.Duration, Rows = rows })
end

function Session:ForceFinish()
	self:Finish()
end

function Session:Cleanup()
	self.Platform:Destroy()
	for _, h in self.Hazards do
		if h.Parent then h:Destroy() end
	end
	self.Hazards = {}
	for _, p in self.Players do
		local char = p.Character
		if char then
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum then hum.WalkSpeed = 16 end
		end
	end
end

Activity.Server = {
	Create = function(deps)
		return newSession(deps)
	end,
}

return Activity