-- ProgressionService: mastery ranks, badges, titles, streaks, records, fx queue.

local RunService = game:GetService("RunService")
if RunService:IsClient() then return {} end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.LOOPlab.Configuration.GameConfig)
local RemoteBuilder = require(ReplicatedStorage.LOOPlab.Shared.RemoteBuilder)
local PlayerData = require(script.Parent.PlayerDataService)
local Poll = require(script.Parent.PollService)

local Service = {}
local _remotes = RemoteBuilder.GetAll()

function Service.GetMasteryRank(masteryXp: number): { Id: string, Name: string, Display: string, Xp: number }
	local ranks = GameConfig.Progression.Mastery.Ranks
	local current = ranks[1]
	for _, r in ranks do
		if masteryXp >= r.Xp then
			current = r
		end
	end
	return current
end

function Service.TrackFx(player: Player, kind: string, data: table?)
	if not player then return end
	Poll.TrackFx(player, { Kind = kind, Data = data or {} })
end

function Service.ProcessStandalone(player: Player, placement: number, score: number, activityId: string): { table }
	local data = PlayerData.GetForPlayer(player)
	if not data then return {} end
	if not data.MasteryXp then data.MasteryXp = 0 end
	if not data.Badges then data.Badges = {} end
	if not data.Titles then data.Titles = {} end
	if not data.Records then data.Records = {} end

	local cfg = GameConfig.Progression.Mastery
	local events = {}

	local prevMxp = data.MasteryXp

	local mxp = 0
	if placement == 1 then
		mxp = cfg.Xp.Win
	elseif placement <= 3 then
		mxp = cfg.Xp.Podium
	else
		mxp = cfg.Xp.Play
	end
	mxp = math.min(mxp, cfg.Xp.ScoreCap)
	data.MasteryXp = prevMxp + mxp

	local oldRank = Service.GetMasteryRank(prevMxp)
	local newRank = Service.GetMasteryRank(data.MasteryXp)
	if newRank.Id ~= oldRank.Id then
		table.insert(events, { Kind = "MasteryUp", Rank = newRank })
		Service.TrackFx(player, "MasteryUp", { Rank = newRank })
	end

	if score > (data.Records[activityId] or 0) then
		data.Records[activityId] = score
		table.insert(events, { Kind = "PersonalBest", ActivityId = activityId, Score = score })
		Service.TrackFx(player, "PersonalBest", { ActivityId = activityId, Score = score })
	end

	Service.EvaluateBadges(player, data, events)
	Service.EvaluateTitles(player, data, events)
	return events
end

function Service.ProcessSurvival(player: Player, rank: number, survivedRounds: number, totalRounds: number): { table }
	local data = PlayerData.GetForPlayer(player)
	if not data then return {} end
	if not data.MasteryXp then data.MasteryXp = 0 end
	if not data.Badges then data.Badges = {} end
	if not data.Titles then data.Titles = {} end
	if not data.Records then data.Records = {} end
	if not data.Survival then data.Survival = {} end

	local cfg = GameConfig.Progression.Mastery
	local events = {}
	local isWin = rank == 1
	local isPodium = rank <= 3

	local prevMxp = data.MasteryXp

	local mxp = 0
	if isWin then
		mxp = cfg.Xp.SurvivalWin
	elseif isPodium then
		mxp = cfg.Xp.SurvivalPodium
	else
		mxp = cfg.Xp.SurvivalPlay
	end
	mxp = math.min(mxp, cfg.Xp.ScoreCap)
	data.MasteryXp = prevMxp + mxp

	if not data.Survival.WinStreak then data.Survival.WinStreak = 0 end
	if isWin then
		data.Survival.WinStreak += 1
		if not data.Survival.BestWinStreak then data.Survival.BestWinStreak = 0 end
		if data.Survival.WinStreak > data.Survival.BestWinStreak then
			data.Survival.BestWinStreak = data.Survival.WinStreak
		end
		data.Survival.LastWinDate = os.date("!%Y-%m-%d")
	else
		data.Survival.WinStreak = 0
	end

	if survivedRounds >= totalRounds and totalRounds > 0 then
		if not data.Survival.FinalRoundAppearances then data.Survival.FinalRoundAppearances = 0 end
		data.Survival.FinalRoundAppearances += 1
	end

	if isWin then
		local prevSurvivalWins = (data.Survival.Wins or 1) - 1
		local survRec = data.Records["survival"] or 0
		if prevSurvivalWins + 1 > survRec then
			data.Records["survival"] = prevSurvivalWins + 1
		end
	end

	local oldRank = Service.GetMasteryRank(prevMxp)
	local newRank = Service.GetMasteryRank(data.MasteryXp)
	if newRank.Id ~= oldRank.Id then
		table.insert(events, { Kind = "MasteryUp", Rank = newRank })
		Service.TrackFx(player, "MasteryUp", { Rank = newRank })
	end

	Service.EvaluateBadges(player, data, events)
	Service.EvaluateTitles(player, data, events)
	return events
end

local _badgeChecks = {
	first_win = function(data)
		for _, g in data.Games do
			if g.Wins and g.Wins > 0 then return true end
		end
		return false
	end,
	survival_first = function(data)
		return (data.Survival and data.Survival.Wins or 0) >= 1
	end,
	survival_5 = function(data)
		return (data.Survival and data.Survival.Wins or 0) >= 5
	end,
	survival_10 = function(data)
		return (data.Survival and data.Survival.Wins or 0) >= 10
	end,
	survive_all = function(data)
		return false
	end,
	final_round = function(data)
		return (data.Survival and data.Survival.FinalRoundAppearances or 0) >= GameConfig.Progression.Survival.FinalRoundBadgeThreshold
	end,
	streak_3 = function(data)
		return (data.Survival and data.Survival.BestWinStreak or 0) >= 3
	end,
	streak_5 = function(data)
		return (data.Survival and data.Survival.BestWinStreak or 0) >= 5
	end,
	mastery_gold = function(data)
		local rank = Service.GetMasteryRank(data.MasteryXp or 0)
		local order = { bronze = 1, silver = 2, gold = 3, platinum = 4, diamond = 5 }
		return (order[rank.Id] or 0) >= 3
	end,
	mastery_diamond = function(data)
		local rank = Service.GetMasteryRank(data.MasteryXp or 0)
		return rank.Id == "diamond"
	end,
	collection_10 = function(data)
		local count = 0
		for _ in data.OwnedCosmetics do count += 1 end
		return count >= 10
	end,
	level_10 = function(data)
		local Economy = require(script.Parent.EconomyService)
		return Economy.GetLevelFromXp(data.Xp or 0) >= 10
	end,
	level_25 = function(data)
		local Economy = require(script.Parent.EconomyService)
		return Economy.GetLevelFromXp(data.Xp or 0) >= 25
	end,
}

function Service.EvaluateBadges(player: Player, data: table, events: { table })
	for _, badge in GameConfig.Badges do
		if data.Badges[badge.Id] then continue end
		local check = _badgeChecks[badge.Id]
		if check and check(data) then
			data.Badges[badge.Id] = true
			table.insert(events, { Kind = "Badge", Badge = badge })
			Service.TrackFx(player, "Badge", { Badge = badge })
		end
	end
end

local _titleChecks = {
	last_one_standing = function(data)
		return (data.Survival and data.Survival.Wins or 0) >= 1
	end,
	survivalist = function(data)
		return (data.Survival and data.Survival.Matches or 0) >= 5
	end,
	chaos_specialist = function(data)
		local g = data.Games and data.Games["chaos_run"]
		return g and (g.Wins or 0) >= 3
	end,
	dodge_master = function(data)
		local g = data.Games and data.Games["dodge_lab"]
		return g and (g.Wins or 0) >= 3
	end,
	build_boss = function(data)
		local g = data.Games and data.Games["build_blitz"]
		return g and (g.Wins or 0) >= 3
	end,
	sequence_master = function(data)
		local g = data.Games and data.Games["sequence_sprint"]
		return g and (g.Wins or 0) >= 3
	end,
	lab_veteran = function(data)
		local total = 0
		for _, g in data.Games do total += (g.Plays or 0) end
		return total >= 25
	end,
	final_regular = function(data)
		return (data.Survival and data.Survival.FinalRoundAppearances or 0) >= 3
	end,
	prime = function(data)
		local rank = Service.GetMasteryRank(data.MasteryXp or 0)
		return rank.Id == "diamond"
	end,
}

function Service.EvaluateTitles(player: Player, data: table, events: { table })
	if not data.Titles then data.Titles = {} end
	for _, title in GameConfig.Titles do
		if data.Titles[title.Id] then continue end
		local check = _titleChecks[title.Id]
		if check and check(data) then
			data.Titles[title.Id] = true
			table.insert(events, { Kind = "Title", Title = title })
			Service.TrackFx(player, "Title", { Title = title })
		end
	end
end

function Service.EquipTitle(player: Player, titleId: string): boolean
	local data = PlayerData.GetForPlayer(player)
	if not data then return false end
	if titleId ~= "" and not (data.Titles and data.Titles[titleId]) then return false end
	if not data.Titles then data.Titles = {} end
	data.EquippedTitle = titleId
	return true
end

function Service.Setup()
	local guard = require(script.Parent.RemoteGuardService)
	guard.BindFunction(_remotes.Functions.TitleEquip, function(player: Player, titleId: any)
		if type(titleId) ~= "string" then return false end
		return Service.EquipTitle(player, titleId)
	end, "TitleEquip")
end

return Service
