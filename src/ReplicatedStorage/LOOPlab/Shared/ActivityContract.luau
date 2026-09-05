-- The activity contract: every mini-game MUST implement this API.
-- ActivityService drives standalone games and Survival rounds through this interface.
-- A new Game #5 must implement this contract + register in ActivityRegistry; no platform rewrite.

local Types = require(script.Parent.Types)

-- A Session is created by ActivityService via ActivityDef.Server.Create and represents
-- one round/match instance on the server.
export type ActivitySession = {
	-- Set by ActivityService before Create is called:
	ActivityId: string,
	Mode: string,           -- "Standalone" | "Survival"
	Difficulty: string,     -- "Normal" | "Hard" | "Extreme"
	Duration: number,       -- seconds for this session
	Players: { Player },    -- participants in order
	OnUpdate: (any) -> (),  -- push per-player/general state to clients
	OnResult: (Types.Scoresheet) -> (), -- report round end with ranked rows

	-- Implemented by the game:
	Start: (self: ActivitySession) -> (),
	Cleanup: (self: ActivitySession) -> (),
	-- Called by ActivityService when the session timer expires; game MUST compute
	-- its scoresheet and call OnResult before returning.
	ForceFinish: (self: ActivitySession) -> (),
	-- Route a player action from the shared ActivityInput remote (optional).
	HandleInput: ((self: ActivitySession, player: Player, action: string, data: any) -> ())?,
	-- Server 'Tick' driven by ActivityService for time-limited games; optional.
	Tick: ((self: ActivitySession, dt: number) -> ())?,
}

export type ActivityDef = {
	Id: string,
	Name: string,
	Description: string,
	MinPlayers: number,
	MaxPlayers: number,
	DurationSeconds: number,   -- standalone
	SurvivalDurationSeconds: number,
	Scoring: string,           -- human-readable
	HigherIsBetter: boolean,
	SupportsStandalone: boolean,
	SupportsSurvival: boolean,
	Icon: string?,             -- rbxassetid
	Server: {
		Create: (deps: { ActivityId: string, Mode: string, Difficulty: string, Duration: number, Players: { Player } }) -> ActivitySession,
		RegisterRemotes: ((remoteTable: { [string]: RemoteEvent | RemoteFunction }, guard: any) -> ())?,
	},
	Client: {
		-- client module receives live updates; optional
		-- Register(viewRefs): called by MatchController with the HUD frame
		Register: ((ctx: any) -> ())?,
	},
}

local Contract = {
	Validate = function(def: ActivityDef): (boolean, string?)
		if type(def) ~= "table" then return false, "def is not a table" end
		if type(def.Id) ~= "string" then return false, "Id missing" end
		if not def.Server or type(def.Server.Create) ~= "function" then
			return false, "Server.Create function missing"
		end
		if def.SupportsStandalone == nil then return false, "SupportsStandalone missing" end
		if def.SupportsSurvival == nil then return false, "SupportsSurvival missing" end
		if def.HigherIsBetter == nil then return false, "HigherIsBetter missing" end
		return true, nil
	end,
}

return Contract