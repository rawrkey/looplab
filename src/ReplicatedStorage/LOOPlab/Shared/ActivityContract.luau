-- The activity contract: every mini-game MUST implement this API.
-- ActivityService drives standalone games and Survival rounds through this interface.

local Types = require(script.Parent.Types)

export type ActivitySession = {
	ActivityId: string,
	Mode: string,
	Difficulty: string,
	Duration: number,
	Players: { Player },
	OnUpdate: (any) -> (),
	OnResult: (Types.Scoresheet) -> (),
	Start: (self: ActivitySession) -> (),
	Cleanup: (self: ActivitySession) -> (),
	ForceFinish: (self: ActivitySession) -> (),
	HandleInput: ((self: ActivitySession, player: Player, action: string, data: any) -> ())?,
	Tick: ((self: ActivitySession, dt: number) -> ())?,
}

export type ActivityDef = {
	Id: string,
	Name: string,
	Description: string,
	MinPlayers: number,
	MaxPlayers: number,
	DurationSeconds: number,
	SurvivalDurationSeconds: number,
	Scoring: string,
	HigherIsBetter: boolean,
	SupportsStandalone: boolean,
	SupportsSurvival: boolean,
	Icon: string?,
	Server: {
		Create: (deps: { ActivityId: string, Mode: string, Difficulty: string, Duration: number, Players: { Player } }) -> ActivitySession,
		RegisterRemotes: ((remoteTable: { [string]: RemoteEvent | RemoteFunction }, guard: any) -> ())?,
	},
	Client: {
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