-- ActivityRegistry: the single place every mini-game registers itself.

local Types = require(script.Parent.Types)
local Contract = require(script.Parent.ActivityContract)

local Registry = {
	_byId = {},
	_order = {},
	_handles = {},
}

function Registry.Register(module: ModuleScript): boolean
	local okReq, def = pcall(require, module)
	if not okReq then return false end
	local ok, err = Contract.Validate(def)
	if not ok then
		warn("[ActivityRegistry] invalid activity " .. module.Name .. ": " .. tostring(err))
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

-- Backwards-compatible alias. Use Registry.Get going forward.
Registry.GetDef = Registry.Get

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

function Registry.GetServers()
	local out = {}
	for _, id in Registry._order do
		out[id] = Registry._byId[id]
	end
	return out
end

return Registry