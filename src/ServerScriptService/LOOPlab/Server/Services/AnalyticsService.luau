-- AnalyticsService: lightweight event logging using AnalyticsService.

local RunService = game:GetService("RunService")
if RunService:IsClient() then
	return {}
end

local Analytics = game:GetService("AnalyticsService")

local Service = {}

function Service.Fire(player: Player?, eventName: string, data: { [string]: any }?)
	local ok, err = pcall(function()
		local param1 = ""
		local param2 = ""
		if data then
			param1 = tostring(data.a or data.ActivityId or data.Mode or "")
			param2 = tostring(data.b or data.Place or data.Score or "")
		end
		if player then
			Analytics:FireEvent(player.UserId, eventName, param1, param2)
		else
			Analytics:FireEvent(eventName, param1, param2)
		end
	end)
	if not ok then
		warn("[Analytics] fire failed: " .. tostring(err))
	end
end

function Service.Log(source: string, message: string)
	print(("[Analytics][%s] %s"):format(source, message))
end

return Service