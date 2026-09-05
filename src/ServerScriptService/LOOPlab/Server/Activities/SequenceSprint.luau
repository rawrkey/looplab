-- Sequence Sprint: mirror the server's button sequence, as fast as possible.
-- Server is authoritative for sequence + progress. Wrong press = reset progress
-- for that sequence (no elimination). Score = correct presses (higher = better).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local ActivityDef = {
	Id = "sequence_sprint",
	Name = "Sequence Sprint",
	Description = "Mirror the flashes, watch the clock.",
	MinPlayers = 1,
	MaxPlayers = 12,
	DurationSeconds = 120,
	SurvivalDurationSeconds = 75,
	Scoring = "Correct presses",
	HigherIsBetter = true,
	SupportsStandalone = true,
	SupportsSurvival = true,
}

local BUTTONS = 4
local BASE_LENGTH = 3
local SHOW_TIME = 1.2 -- seconds the flash prompt is shown before input allowed

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
			sequence = {},      -- per player current sequence (array of 1..BUTTONS)
			progress = {},      -- per player index into sequence
			correct = {},       -- per player total correct count (the score)
			round = 1,
			phase = "show",     -- "show" | "input"
			phaseUntil = 0,
			lastUpdate = 0,
			folder = nil,
		}

		local session = {}
		session.OnUpdate = deps.OnUpdate
		session.OnResult = deps.OnResult

		local folder = Instance.new("Folder")
		folder.Name = "LOOPLAB_SequenceSprint_" .. tostring(os.time() + math.random(1, 9999))
		folder.Parent = Workspace
		state.folder = folder

		-- spawn players around a circle
		for i, p in players do
			local ang = (i / math.max(1, #players)) * math.pi * 2
			task.delay(0.4, function()
				local root, hum = rootOf(p)
				if root then
					root.CFrame = CFrame.new(math.cos(ang) * 10, 2.5, math.sin(ang) * 10)
					hum.WalkSpeed = 10
				end
			end)
		end

		local function newSequence(p)
			local len = BASE_LENGTH + math.floor(state.correct[p.UserId] / 6)
			len = math.min(len, 12)
			local seq = {}
			for i = 1, len do
				seq[i] = math.random(1, BUTTONS)
			end
			state.sequence[p.UserId] = seq
			state.progress[p.UserId] = 0
		end

		-- generate initial sequences and start the show phase
		for _, p in players do
			newSequence(p)
		end
		state.phase = "show"
		state.phaseUntil = os.clock() + SHOW_TIME
		state.roundStart = os.clock()

		local function broadcast()
			local progress = {}
			for uid, idx in pairs(state.progress) do progress[tostring(uid)] = idx end
			local correct = {}
			for uid, c in pairs(state.correct) do correct[tostring(uid)] = c end
			session.OnUpdate({
				Phase = state.phase,
				Kind = "sequence_sprint",
				Round = state.round,
				TimeLeft = math.max(0, math.floor(duration - state.elapsed)),
				-- Only send sequence to the client during show phase; everyone gets it.
				Sequence = (state.phase == "show") and state.sequence or nil,
				Progress = progress,
				Correct = correct,
				ShowUntil = state.phaseUntil,
			})
		end

		local function finish()
			if state.done then return end
			state.done = true
			local rows = {}
			for _, p in players do
				table.insert(rows, {
					Player = p,
					Score = state.correct[p.UserId] or 0,
					Time = state.elapsed,
					Ranks = { round = state.round },
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
			pcall(broadcast)
		end

		session.Tick = function(_, dt)
			if state.done then return end
			state.elapsed += dt
			local now = os.clock()

			if state.phase == "show" and now >= state.phaseUntil then
				state.phase = "input"
				pcall(broadcast)
			end

			-- everyone who finished their sequence gets a new round
			local allDone = true
			local anyone = #players > 0
			for _, p in players do
				if p.Parent then
					local idx = state.progress[p.UserId] or 0
					local seq = state.sequence[p.UserId]
					if seq and idx < #seq then allDone = false end
				end
			end
			if anyone and allDone then
				state.round += 1
				for _, p in players do
					if p.Parent then newSequence(p) end
				end
				state.phase = "show"
				state.phaseUntil = os.clock() + SHOW_TIME
			end

			if state.elapsed - state.lastUpdate >= 0.25 then
				state.lastUpdate = state.elapsed
				pcall(broadcast)
			end
		end

		session.HandleInput = function(_, player, action, data)
			if state.done then return end
			if action ~= "press" then return end
			if state.phase ~= "input" then return end
			local idx = data
			if type(idx) ~= "number" then
				if type(data) == "table" then idx = data.idx end
			end
			if type(idx) ~= "number" then return end
			if idx < 1 or idx > BUTTONS then return end
			local uid = player.UserId
			local seq = state.sequence[uid]
			if not seq then return end
			local expected = seq[(state.progress[uid] or 0) + 1]
			if idx == expected then
				state.progress[uid] = (state.progress[uid] or 0) + 1
				state.correct[uid] = (state.correct[uid] or 0) + 1
			else
				-- reset this sequence (no elimination)
				state.progress[uid] = 0
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