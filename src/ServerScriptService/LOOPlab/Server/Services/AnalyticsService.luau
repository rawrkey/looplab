-- AnalyticsService: lightweight event logging. Uses Roblox AnalyticsService:FireEvent.
-- Never logs PII beyond Roblox-supported Player identity.

local RunService = game:GetService("RunService")
if RunService:IsClient() then
	return {}
end

local HttpService = game:GetService("HttpService")
local Analytics = game:GetService("AnalyticsService")

local Service = {}

-- Fire a gameplay event (name, player optional, data table).
-- Roblox AnalyticsService.FireEvent(player, eventName, ...) supports up to 2 custom fields.
-- We flatten key metrics into event name + 2 params to stay within the API, and log locally.
function Service.Fire(player: Player?, eventName: string, data: { [string]: any }?)
	local ok, err = pcall(function()
		local param1 = ""
		local param2 = ""
		if data then
			param1 = tostring(data.a or data.ActivityId or data.Mode or "")
			param2 = tostring(data.b or data.Place or data.Score or "")
		end
		if player then
			Analytics:FireEvent(player, eventName, param1, param2)
		else
			Analytics:FireEvent(eventName, param1, param2)
		end
	end)
	if not ok then
		warn("[Analytics] fire failed: " .. tostring(err))
	end
end

-- Log a raw line to Output (for local/debug parsing)
function Service.Log(source: string, message: string)
	print(("[Analytics][%s] %s"):format(source, message))
end

return Service