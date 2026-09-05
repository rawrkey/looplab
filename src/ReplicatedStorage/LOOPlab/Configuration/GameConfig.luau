-- LOOPLAB centralized configuration. Single source of truth for tunables.
-- Any AI session MUST read this file before touching gameplay constants.

type CurrencyDef = { Id: string, DisplayName: string }

local GameConfig = {
	GameName = "LOOPLAB",
	SchemaVersion = 1,

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
		{ Id = "default_hat", Name = "Default Beanie", Category = "Hat", Price = 0, DefaultOwned = true },
		{ Id = "cap", Name = "Classic Cap", Category = "Hat", Price = 0, DefaultOwned = true },
		{ Id = "fire_hat", Name = "Flame Cap", Category = "Hat", Price = 150 },
		{ Id = "ice_hat", Name = "Frost Crown", Category = "Hat", Price = 150 },
		{ Id = "crown", Name = "LOOPLAB Crown", Category = "Hat", Price = 500 },
		{ Id = "horns", Name = "Imp Horns", Category = "Hat", Price = 200 },
		{ Id = "bowtie", Name = "Bowtie", Category = "Accessory", Price = 60 },
		{ Id = "sunglasses", Name = "Pixel Shades", Category = "Accessory", Price = 120 },
		{ Id = "scarf", Name = "Scarlet Scarf", Category = "Accessory", Price = 90 },
		{ Id = "backpack", Name = "Survival Pack", Category = "Accessory", Price = 180 },
		{ Id = "thruster", Name = "Jet Thruster", Category = "Accessory", Price = 250 },
		{ Id = "aura", Name = "Gold Aura", Category = "Effect", Price = 400 },
		{ Id = "trail", Name = "Pixel Trail", Category = "Effect", Price = 220 },
		{ Id = "halo", Name = "Angel Halo", Category = "Hat", Price = 350 },
		{ Id = "headset", Name = "Gamer Headset", Category = "Accessory", Price = 160 },
		{ Id = "vip", Name = "VIP Badge", Category = "Badge", Price = 0 },
	},

	Monetization = {
		PrivateServerProductId = 0,
		CosmeticProducts = {},
	},

	Analytics = {
		Enabled = true,
	},
}

return GameConfig