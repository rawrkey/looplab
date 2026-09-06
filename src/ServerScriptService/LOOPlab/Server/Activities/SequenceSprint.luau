-- SequenceSprint: repeat the shown sequence as it grows.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Contract = require(ReplicatedStorage.LOOPlab.Shared.ActivityContract)
local GameConfig = require(ReplicatedStorage.LOOPlab.Configuration.GameConfig)

local Activity = {
	Id = "sequence_sprint",
	Name = "Sequence Sprint",
	Description = "Memorize and repeat the sequence!",
	MinPlayers = 1,
	MaxPlayers = 12,
	DurationSeconds = 45,
	SurvivalDurationSeconds = 45,
	Scoring = "HigherIsBetter",
	HigherIsBetter = true,
	SupportsStandalone = true,
	SupportsSurvival = true,
}

local BASE_LENGTH = 3
local MAX_LENGTH = 12
local SHOW_TIME = 1.2
local INPUT_WINDOW = 6
local PADS = { "A", "B", "C", "D" }

local Session = {}
Session.__index = Session

local function newSession(deps)
	local self = setmetatable({}, Session)
	self.ActivityId = deps.ActivityId
	self.Mode = deps.Mode
	self.Difficulty = deps.Difficulty
	self.Players = deps.Players
	self.Duration = deps.Duration
	self.States = {}
	self.Finished = false
	return self
end

local function makePad(self, index)
	local pad = Instance.new("Part")
	pad.Anchored = true
	pad.Size = Vector3.new(5, 1, 5)
	pad.Position = Vector3.new((index - 1) * 7 - 10, 1, -20)
	pad.Material = Enum.Material.Neon
	pad.Color = Color3.fromRGB(60, 150, 220)
	pad.Name = "Pad" .. PADS[index]
	pad:SetAttribute("Pad", PADS[index])
	pad.Parent = workspace
	table.insert(self.Pads, pad)
	return pad
end

local function showSequence(self, player, seq)
	self.OnUpdate({ Kind = "Activity", ActivityId = self.ActivityId, Data = { Phase = "show", Sequence = seq, PadCount = #self.Pads } })
	task.wait(SHOW_TIME * self.ShowMult * #seq)
end

local function nextRound(self, player)
	local state = self.States[player.UserId]
	local len = math.min(state.Round + BASE_LENGTH - 1, MAX_LENGTH)
	local seq = {}
	for i = 1, len do
		seq[i] = PADS[math.random(1, #PADS)]
	end
	state.Sequence = seq
	state.Index = 1
	state.Waiting = true
	state.RoundTimeout = os.clock() + INPUT_WINDOW * self.InputMult
	showSequence(self, player, seq)
	self.OnUpdate({ Kind = "Activity", ActivityId = self.ActivityId, Data = { Phase = "input", Length = len, PadCount = #self.Pads } })
end

function Session:Start()
	self.Pads = {}
	for i = 1, #PADS do
		makePad(self, i)
	end
	for _, player in self.Players do
		self.States[player.UserId] = { Round = 1, Score = 0, Waiting = false, Index = 1, Sequence = {}, RoundTimeout = 0 }
		local char = player.Character or player.CharacterAdded:Wait()
		if char then
			local hrp = char:WaitForChild("HumanoidRootPart", 5)
			if hrp then
				hrp.CFrame = CFrame.new(0, 8, 0)
			end
		end
	end
	self.StartedAt = os.clock()
	local diff = GameConfig.Survival.DifficultyMultipliers[self.Difficulty or "Normal"] or GameConfig.Survival.DifficultyMultipliers.Normal
	self.ShowMult = diff.ShowMult or 1
	self.InputMult = diff.InputMult or 1
	for _, p in self.Players do
		self.OnUpdate({ Kind = "MatchState", Mode = self.Mode, ActivityId = self.ActivityId, Phase = "running", TimeLeft = self.Duration, Message = "Watch and repeat!" })
		nextRound(self, p)
	end
end

function Session:HandleInput(player, action, data)
	if self.Finished then return end
	local state = self.States[player.UserId]
	if not state or not state.Waiting then return end
	if action ~= "press" then return end
	if not data or type(data) ~= "string" then return end
	if data ~= state.Sequence[state.Index] then
		state.Waiting = false
		state.Score = math.max(0, state.Score - 1)
		self.OnUpdate({ Kind = "Activity", ActivityId = self.ActivityId, Data = { Phase = "wrong", Score = state.Score } })
		self.OnUpdate({ Kind = "MatchState", Mode = self.Mode, ActivityId = self.ActivityId, Phase = "running", TimeLeft = math.max(0, self.Duration - (os.clock() - self.StartedAt)), Message = "Wrong!", Fx = { Kind = "wrong", TargetUserId = player.UserId } })
		state.Index = 1
		nextRound(self, player)
		return
	end
	state.Index += 1
	if state.Index > #state.Sequence then
		state.Waiting = false
		local add = #state.Sequence
		state.Score += add * 10
		state.Round += 1
		self.OnUpdate({ Kind = "Activity", ActivityId = self.ActivityId, Data = { Phase = "correct", Score = state.Score } })
		self.OnUpdate({ Kind = "MatchState", Mode = self.Mode, ActivityId = self.ActivityId, Phase = "running", TimeLeft = math.max(0, self.Duration - (os.clock() - self.StartedAt)), Message = "Round clear!", Fx = { Kind = "roundclear", TargetUserId = player.UserId } })
		nextRound(self, player)
	end
end

function Session:Tick(dt)
	local done = true
	for _, p in self.Players do
		local state = self.States[p.UserId]
		if state and state.Waiting == false then done = false end
	end
	return
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
	for _, p in self.Pads do
		if p.Parent then p:Destroy() end
	end
	for _, player in self.Players do
		local char = player.Character
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