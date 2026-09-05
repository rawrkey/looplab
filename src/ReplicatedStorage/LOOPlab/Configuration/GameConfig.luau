-- LOOPLAB centralized configuration. Single source of truth for tunables.
-- Any AI session MUST read this file before touching gameplay constants.

type CurrencyDef = { Id: string, DisplayName: string }
type RankDef = { Id: string, Name: string, Display: string, Xp: number }
type BadgeDef = { Id: string, Name: string, Desc: string, Icon: string }
type TitleDef = { Id: string, Name: string, Tier: string }

local GameConfig = {
	GameName = "LOOPLAB",
	SchemaVersion = 2,

	PlayerData = {
		MaxRecentGames = 20,
		SaveIntervalSeconds = 120,
		DefaultCoins = 0,
		DefaultXp = 0,
	},

	Currencies = {
		Coins = { Id = "Coins", DisplayName = "Coins" } :: CurrencyDef,
	},

	Xp = {
		LevelCurve = { 0, 100, 250, 500, 900, 1400, 2000, 2700, 3500, 4500 },
		MaxLevel = 50,
	},

	Progression = {
		LevelUpCoins = 250,
		Mastery = {
			Ranks = {
				{ Id = "bronze", Name = "BRO\nNZE", Display = "BRONZE", Xp = 0 } :: RankDef,
				{ Id = "silver", Name = "SILVER", Display = "SILVER", Xp = 300 } :: RankDef,
				{ Id = "gold", Name = "GOLD", Display = "GOLD", Xp = 800 } :: RankDef,
				{ Id = "platinum", Name = "PLATINUM", Display = "PLATINUM", Xp = 1600 } :: RankDef,
				{ Id = "diamond", Name = "DIAMOND", Display = "DIAMOND", Xp = 3000 } :: RankDef,
			} :: { RankDef },
			Xp = {
				Play = 40,
				Podium = 80,
				Win = 140,
				SurvivalPlay = 60,
				SurvivalPodium = 120,
				SurvivalWin = 200,
				ScoreCap = 100,
			},
		},
		Survival = {
			WinStreakTitle = 3,
			FinalRoundBadgeThreshold = 5,
		},
	},

	Badges = {
		{ Id = "first_win", Name = "Fresh Winner", Desc = "Win any activity", Icon = "✦" },
		{ Id = "survival_first", Name = "Last One Standing", Desc = "Win your first Survival match", Icon = "♛" },
		{ Id = "survival_5", Name = "Survival Veteran", Desc = "Win 5 Survival matches", Icon = "★" },
		{ Id = "survival_10", Name = "Survival Legend", Desc = "Win 10 Survival matches", Icon = "☄" },
		{ Id = "survive_all", Name = "Iron Mind", Desc = "Survive all four rounds in one match", Icon = "◈" },
		{ Id = "final_round", Name = "Deep Runner", Desc = "Reach the final round 5 times", Icon = "⧈" },
		{ Id = "streak_3", Name = "On Fire", Desc = "Hit a 3 Survival win streak", Icon = "▮" },
		{ Id = "streak_5", Name = "Unstoppable", Desc = "Hit a 5 Survival win streak", Icon = "▚" },
		{ Id = "mastery_gold", Name = "Gold Standard", Desc = "Reach GOLD mastery in any game", Icon = "◆" },
		{ Id = "mastery_diamond", Name = "Diamond League", Desc = "Reach DIAMOND mastery in any game", Icon = "◈" },
		{ Id = "collection_10", Name = "Showroom", Desc = "Own 10 cosmetics", Icon = "▣" },
		{ Id = "level_10", Name = "Double Digits", Desc = "Reach level 10", Icon = "⑩" },
		{ Id = "level_25", Name = "Quarter Century", Desc = "Reach level 25", Icon = "⓬" },
	} :: { BadgeDef },

	Titles = {
		{ Id = "last_one_standing", Name = "Last One Standing", Tier = "gold" },
		{ Id = "survivalist", Name = "Survivalist", Tier = "silver" },
		{ Id = "chaos_specialist", Name = "Chaos Specialist", Tier = "gold" },
		{ Id = "dodge_master", Name = "Dodge Master", Tier = "gold" },
		{ Id = "build_boss", Name = "Build Boss", Tier = "gold" },
		{ Id = "sequence_master", Name = "Sequence Master", Tier = "gold" },
		{ Id = "lab_veteran", Name = "Lab Veteran", Tier = "silver" },
		{ Id = "final_regular", Name = "Final Round Regular", Tier = "bronze" },
		{ Id = "prime", Name = "Prime", Tier = "diamond" },
	} :: { TitleDef },

	Rewards = {
		Standalone = {
			BaseXp = 50,
			BaseCoins = 25,
			PlacementMult = { 2.0, 1.5, 1.2 },
			EveryoneMult = 1.0,
		},
		SurvivalRound = { BaseXp = 20, BaseCoins = 10 },
		SurvivalWin = { Xp = 300, Coins = 200 },
		SurvivalPodium = { Xp = 150, Coins = 100 },
		DailyChallenge = { Xp = 100, Coins = 60 },
		Mastery = { MaxCoins = 120, MaxXp = 60 },
	},

	Daily = {
		RotationKey = "LOOPLAB_Daily_v1",
		ResetHourUTC = 0,
		Objectives = {
			{ Kind = "complete", Min = 1 },
			{ Kind = "win", Min = 1 },
			{ Kind = "best_score", Min = 25, ProgressMetric = "points" },
		},
	},

	ActivityDefaults = {
		MinPlayers = 1,
		MaxPlayers = 12,
		QueueTimeoutSeconds = 12,
	},

	Survival = {
		LobbySize = 10,
		MinFill = 1,
		FillWaitSeconds = 20,
		LobbyCountdown = 10,
		Rounds = 4,
		SurvivorFractions = { 0.8, 0.625, 0.6, 1.0 },
		RoundTransitionSeconds = 8,
		RoundIntroSeconds = 5,
		MaxMatchDurationMinutes = 40,
		ReconnectGraceSeconds = 30,
		AfkGraceSeconds = 20,
		HeartbeatInterval = 5,
		TiePolicy = "SuddenDeath",
		SuddenDeathDuration = 15,
		RandomSeed = 1337,
	},

	Leaderboards = {
		MaxEntriesReturned = 50,
		CacheSeconds = 60,
		Boards = {
			{ Id = "chaos_run", Key = "LB_chaos_run" },
			{ Id = "dodge_lab", Key = "LB_dodge_lab" },
			{ Id = "build_blitz", Key = "LB_build_blitz" },
			{ Id = "sequence_sprint", Key = "LB_sequence_sprint" },
			{ Id = "survival", Key = "LB_survival" },
		},
	},

	Cosmetics = {
		{ Id = "default_hat", Name = "Default Beanie", Category = "Hat", Price = 0, DefaultOwned = true, Emoji = "🧢" },
		{ Id = "cap", Name = "Classic Cap", Category = "Hat", Price = 0, DefaultOwned = true, Emoji = "🧢" },
		{ Id = "fire_hat", Name = "Flame Cap", Category = "Hat", Price = 150, Emoji = "🔥" },
		{ Id = "ice_hat", Name = "Frost Crown", Category = "Hat", Price = 150, Emoji = "❄️" },
		{ Id = "crown", Name = "LOOPLAB Crown", Category = "Hat", Price = 500, Emoji = "👑" },
		{ Id = "horns", Name = "Imp Horns", Category = "Hat", Price = 200, Emoji = "😈" },
		{ Id = "bowtie", Name = "Bowtie", Category = "Accessory", Price = 60, Emoji = "🎀" },
		{ Id = "sunglasses", Name = "Pixel Shades", Category = "Accessory", Price = 120, Emoji = "🕶️" },
		{ Id = "scarf", Name = "Scarlet Scarf", Category = "Accessory", Price = 90, Emoji = "🧣" },
		{ Id = "backpack", Name = "Survival Pack", Category = "Accessory", Price = 180, Emoji = "🎒" },
		{ Id = "thruster", Name = "Jet Thruster", Category = "Accessory", Price = 250, Emoji = "🚀" },
		{ Id = "aura", Name = "Gold Aura", Category = "Effect", Price = 400, Emoji = "✨" },
		{ Id = "trail", Name = "Pixel Trail", Category = "Effect", Price = 220, Emoji = "💫" },
		{ Id = "halo", Name = "Angel Halo", Category = "Hat", Price = 350, Emoji = "😇" },
		{ Id = "headset", Name = "Gamer Headset", Category = "Accessory", Price = 160, Emoji = "🎧" },
		{ Id = "vip", Name = "VIP Badge", Category = "Badge", Price = 0, Emoji = "💎" },
	},

	Monetization = {
		PrivateServerProductId = 0,
		CosmeticProducts = {},
	},

	Analytics = {
		Enabled = true,
	},

	Audio = {
		Music = {
			Hub = "rbxassetid://1837678979",
			ChaosRun = "rbxassetid://9040222828",
			DodgeLab = "rbxassetid://9043422333",
			BuildBlitz = "rbxassetid://1837768013",
			SequenceSprint = "rbxassetid://9045929839",
			Survival = {
				Lobby = "rbxassetid://9042466902",
				Normal = "rbxassetid://9041912631",
				Intense = "rbxassetid://9040222828",
				Final = "rbxassetid://9044820101",
			},
			Victory = "rbxassetid://1836473422",
		},
		Sfx = {
			Click = "rbxassetid://88442833509532",
			Hover = "rbxassetid://119393948345399",
			Countdown = "rbxassetid://1836473398",
			Go = "rbxassetid://1836473422",
			Checkpoint = "rbxassetid://1837678979",
			Hit = "rbxassetid://9044820101",
			Place = "rbxassetid://88442833509532",
			Score = "rbxassetid://1836473398",
			Toast = "rbxassetid://1837768013",
			Eliminate = "rbxassetid://9044820101",
			Win = "rbxassetid://1836473422",
			LevelUp = "rbxassetid://1836473422",
			Badge = "rbxassetid://1837678979",
			Title = "rbxassetid://1836473398",
			Mastery = "rbxassetid://9044820101",
			Final3 = "rbxassetid://9042466902",
			Final2 = "rbxassetid://9044820101",
			PersonalBest = "rbxassetid://1836473398",
			Reward = "rbxassetid://1837768013",
		},
	},
}

return GameConfig