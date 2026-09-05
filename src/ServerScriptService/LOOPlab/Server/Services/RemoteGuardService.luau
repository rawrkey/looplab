-- RemoteGuardService: server-side validation + rate limiting + payload guards.

local RunService = game:GetService("RunService")
if RunService:IsClient() then
	warn("[RemoteGuard] tried to load on client, aborting")
	return {}
end

local Guard = {
	_window = 5,
	_limit = 15,
	_burst = {},
}

local function keyFor(player, name)
	return player.UserId .. ":" .. name
end

function Guard.Acquire(player: Player, remoteName: string): boolean
	if not player then return false end
	local now = os.clock()
	local k = keyFor(player, remoteName)
	local bucket = Guard._burst[k]
	if not bucket or (now - bucket.start) > Guard._window then
		Guard._burst[k] = { count = 1, start = now }
		return true
	end
	bucket.count += 1
	return bucket.count <= Guard._limit
end

function Guard.IsSane(v: any)
	local t = type(v)
	return t == "nil" or t == "boolean" or t == "number" or t == "string" or t == "table"
end

function Guard.BindFunction(remote: RemoteFunction, handler: (player, ...any) -> any, name: string)
	remote.OnServerInvoke = function(player: Player, ...)
		if not Guard.Acquire(player, name) then
			return nil, "RATE_LIMITED"
		end
		local args = { ... }
		for _, arg in args do
			if not Guard.IsSane(arg) then
				return nil, "INVALID_ARG"
			end
		end
		local ok, result = pcall(handler, player, unpack(args))
		if not ok then
			warn("[RemoteGuard] handler error for " .. name .. ": " .. tostring(result))
			return nil
		end
		return result
	end
end

function Guard.BindEvent(remote: RemoteEvent, handler: (player, ...any) -> (), name: string)
	remote.OnServerEvent:Connect(function(player: Player, ...)
		if not Guard.Acquire(player, name) then return end
		local args = { ... }
		for _, arg in args do
			if not Guard.IsSane(arg) then return end
		end
		local ok, err = pcall(handler, player, unpack(args))
		if not ok then
			warn("[RemoteGuard] event error for " .. name .. ": " .. tostring(err))
		end
	end)
end

function Guard.Sane(v: any)
	return Guard.IsSane(v)
end

return Guard