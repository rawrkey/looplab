-- ActivityRegistry: the single place every mini-game registers itself.
-- Survival, standalone queue, hub, recommendation and leaderboards all consume this.
-- Adding Game #5 = add a module here + register. Nothing else hard-codes games.

local Types = require(script.Parent.Types)
local Contract = require(script.Parent.ActivityContract)

local Registry = {
	_byId = {},          -- id -> ActivityDef / reference handle
	_order = {},         -- insertion order of ids
	_handles = {},       -- id -> ModuleScript (or loaded def table)
}

-- Register by ModuleScript handle so the containing module can be required lazily.
function Registry.Register(module: ModuleScript): boolean
	local def = require(module)
	local ok, err = Contract.Validate(def)
	if not ok then
		warn("[ActivityRegistry] invalid activity " .. module.Name .. ": " .. err)
		return false
	end
	if Registry._byId[def.Id] then
		warn("[ActivityRegistry] duplicate activity id " .. def.Id)
		return false
	end
	Registry._byId[def.Id] = def
	Registry._handles[def.Id] = module
	table.insert(Registry._order, def.Id)
	return true
end

function Registry.Get(activityId: string)
	return Registry._byId[activityId]
end

function Registry.GetDef(activityId: string): any
	return Registry._byId[activityId]
end

function Registry.List(): { any }
	local out = {}
	for _, id in Registry._order do
		out[id] = Registry._byId[id]
	end
	return out
end

function Registry.GetAllIds(): { string }
	local copy = {}
	for _, id in Registry._order do
		table.insert(copy, id)
	end
	return copy
end

function Registry.GetServers() -- per game server Create func (survival consumes this)
	local out = {}
	for _, id in Registry._order do
		out[id] = Registry._byId[id]
	end
	return out
end

return Registry