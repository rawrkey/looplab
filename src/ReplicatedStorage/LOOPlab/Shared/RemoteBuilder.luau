-- RemoteBuilder: constructs/fetches remotes under ReplicatedStorage.LOOPlab.Remotes.
-- idempotent; safe to require from both client and server.

local RemoteFolderName = "Remotes"

local RemoteBuilder = {}

type RemoteTable = {
	Functions: { [string]: RemoteFunction },
	Events: { [string]: RemoteEvent },
}

local function getRoot()
	local rs = game:GetService("ReplicatedStorage")
	local lab = rs:FindFirstChild("LOOPlab")
	if not lab then
		lab = Instance.new("Folder")
		lab.Name = "LOOPlab"
		lab.Parent = rs
	end
	return lab
end

local cached: RemoteTable?

function RemoteBuilder.GetAll(): RemoteTable
	if cached then
		return cached
	end

	local lab = getRoot()
	local folder = lab:FindFirstChild(RemoteFolderName)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = RemoteFolderName
		folder.Parent = lab
	end

	local defs = require(script.Parent.RemoteDefinitions)

	local fns = {}
	for name in defs.Functions do
		local rf = folder:FindFirstChild(name)
		if not rf or not rf:IsA("RemoteFunction") then
			if rf then rf:Destroy() end
			rf = Instance.new("RemoteFunction")
			rf.Name = name
			rf.Parent = folder
		end
		fns[name] = rf
	end

	local evs = {}
	for name in defs.Events do
		local re = folder:FindFirstChild(name)
		if not re or not re:IsA("RemoteEvent") then
			if re then re:Destroy() end
			re = Instance.new("RemoteEvent")
			re.Name = name
			re.Parent = folder
		end
		evs[name] = re
	end

	cached = { Functions = fns, Events = evs }
	return cached :: any
end

function RemoteBuilder.FlushCache()
	cached = nil
end

return RemoteBuilder