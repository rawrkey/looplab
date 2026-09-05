-- Shared types and enums used across server, client, and activities.

export type ActivityId = string
export type Mode = "Standalone" | "Survival"
export type Difficulty = "Normal" | "Hard" | "Extreme"

-- A placement/scoresheet entry produced by an activity at round end.
export type Placement = {
	Player: Player,
	Score: number,      -- raw score (higher = better, as defined by activity)
	Time: number,       -- seconds (server wall clock) from round start; used for ordering
	Ranks: { [string]: number }, -- activity-specific tiebreaker dimensions, higher=better
}

export type RoundResult = {
	ActivityId: ActivityId,
	StartedAt: number,
	Injections: { [Player]: any }, -- per-player result details
}

-- Full scoresheet for one activity session: players ordered best-first.
export type Scoresheet = {
	ActivityId: ActivityId,
	Mode: Mode,
	Duration: number,
	Rows: { Placement }, -- pre-sorted best first
}

-- Broadcast payloads (server -> client)
export type QueueUpdatePayload = {
	Kind: "QueueUpdate",
	Mode: Mode,
	ActivityId: ActivityId?,
	Queued: number,
	Target: number,
	Phase: string, -- "waiting" | "countdown" | "live"
	TimeLeft: number?,
	SessionId: string?,
}

export type MatchStatePayload = {
	Kind: "MatchState",
	Mode: Mode,
	ActivityId: ActivityId,
	Phase: string, -- "intro" | "active" | "ending"
	Duration: number,
	TimeLeft: number,
	Survivors: { [string]: number }, -- userId -> rank/score (keyed by user id for HUD)
	MyRaw?: number,
	Message: string,
	Round?: number,
	TotalRounds?: number,
}

export type EliminationPayload = {
	Kind: "Elimination",
	Round: number,
	TotalRounds: number,
	EliminatedUserIds: { number },
	SurvivorUserIds: { number },
	Message: string,
}

export type ResultsPayload = {
	Kind: "Results",
	Mode: Mode,
	ActivityId: ActivityId?,
	Rows: { { UserId: number, Name: string, Score: number, Place: number } },
	Rewards: { Coins: number, Xp: number }?,
}

export type WinnerPayload = {
	Kind: "Winner",
	Round: number,
	TotalRounds: number,
	WinnerUserId: number,
	WinnerName: string,
	Rewards: { Coins: number, Xp: number },
	Rows: { { UserId: number, Name: string, Score: number, Place: number } },
}

export type ActivityUpdatePayload = {
	Kind: "Activity",
	ActivityId: ActivityId,
	Data: any,
}

export type PlayerCountsPayload = {
	Kind: "PlayerCounts",
	Counts: { [string]: number },
}

return {} :: typeof(nil) -- type-only module