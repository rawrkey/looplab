-- RemoteDefinitions: single source of truth for every RemoteEvent/RemoteFunction.
-- Both server and client read this. RemoteGuardService enforces rate limits/validation.

return {
	Functions = {
		QueueJoin = "QueueJoin",          -- (mode: string, activityId: string) => { sessionId, phase, pos, target }
		QueueLeave = "QueueLeave",        -- () => { ok = true }
		ReadyForRound = "ReadyForRound",  -- () => bool
		SpectateCycle = "SpectateCycle",  -- (dir: number) => { targetName }
		React = "React",                  -- (emote: string) => bool
		CosmeticEquip = "CosmeticEquip",  -- (category: string, cosmeticId: string) => bool
		CosmeticUnequip = "CosmeticUnequip", -- (category: string) => bool
		CosmeticBuy = "CosmeticBuy",      -- (cosmeticId: string) => { ok, coins, xp }
		DailyClaim = "DailyClaim",        -- () => { ok, coins, xp }
		DailyState = "DailyState",        -- () => { activityId, kind, target, progress, claimed }
		SettingsSet = "SettingsSet",      -- (settings: table) => bool
		LeaderboardFetch = "LeaderboardFetch", -- (boardId: string) => { rows }
		PlayerCounts = "PlayerCounts",    -- () => { counts }
		ProfileFetch = "ProfileFetch",    -- () => profile snapshot
	},

	Events = {
		-- client -> server
		ActivityInput = "ActivityInput",  -- (activityId, action, data)
		Heartbeat = "Heartbeat",          -- (ts: number)
		-- server -> client
		MatchState = "MatchState",        -- broadcast
		ActivityUpdate = "ActivityUpdate",-- broadcast (per-game live data)
		QueueUpdate = "QueueUpdate",      -- to queued players
		LobbyUpdate = "LobbyUpdate",      -- to match lobby
		RoundBegin = "RoundBegin",        -- round intro
		RoundEnd = "RoundEnd",            -- round scoresheet (private)
		Elimination = "Elimination",      -- who was cut
		Results = "Results",              -- full match results
		Winner = "Winner",                -- winner celebration
		SpectateUpdate = "SpectateUpdate",-- to spectator
		Emote = "Emote",                  -- broadcast emote
		EconomyUpdate = "EconomyUpdate",  -- to player: { coins, xp, level } 
		Toast = "Toast",                  -- { message }
		NewSeason = "NewSeason",          -- { season }
	},
}