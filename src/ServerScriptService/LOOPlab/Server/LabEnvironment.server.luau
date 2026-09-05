-- Lab environment: creates light strips + platform + screens in workspace
-- Purely visual / environmental art — no gameplay changes

local workspace = game:GetService("Workspace")

local function makePart(name, size, pos, color, mat, anchor)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size or Vector3.new(4, 0.5, 4)
	p.Position = pos or Vector3.new(0, 0, 0)
	p.Anchored = anchor ~= false
	p.CanCollide = false
	p.Transparency = 0.85
	p.Color = color or Color3.fromRGB(30, 35, 60)
	p.Material = mat or Enum.Material.Neon
	p.Parent = workspace
	return p
end

-- Large dark glass platform with subtle glow
local platform = makePart("LabPlatform", Vector3.new(40, 0.15, 40), Vector3.new(0, 0.15, 0), Color3.fromRGB(18, 22, 35), Enum.Material.Glass)
platform.Transparency = 0.7

-- Glowing edge strips around platform
for i = 0, 9 do
	local strip = makePart("EdgeGlint" .. i, Vector3.new(2, 0.05, 2), Vector3.new(-20 + i * 4, 0.2, -20), Color3.fromRGB(70, 175, 255), Enum.Material.Neon)
	strip.Transparency = 0.3
end

-- Background vertical light strips (futuristic lab)
for x = -20, 20, 10 do
	local light = makePart("BackLight" .. x, Vector3.new(0.3, 12, 0.3), Vector3.new(x, 6, -30), Color3.fromRGB(76, 175, 255), Enum.Material.Neon)
	light.Transparency = 0.9
end

-- Large background screen / holographic display
local screen = makePart("HoloScreen", Vector3.new(14, 8, 0.2), Vector3.new(0, 4, -18), Color3.fromRGB(30, 60, 120), Enum.Material.SmoothPlastic)
screen.Transparency = 0.6

-- Subtle floating light orbs in background depth
for i = 1, 8 do
	local orb = Instance.new("Part")
	orb.Name = "Orb" .. i
	orb.Shape = Enum.PartType.Ball
	orb.Size = Vector3.new(0.6, 0.6, 0.6)
	orb.Position = Vector3.new(math.random(-15, 15), math.random(3, 8), math.random(-15, -5))
	orb.Anchored = true
	orb.CanCollide = false
	orb.Transparency = 0.85
	orb.Color = Color3.fromRGB(200, 220, 255)
	orb.Material = Enum.Material.Neon
	orb.Parent = workspace
end

print("[LabEnv] Environment art created — visual only.")
