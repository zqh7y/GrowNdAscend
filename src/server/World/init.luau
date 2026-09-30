-- Builds the map when the server starts: four areas in a straight line along
-- +X (Forest -> Sahara -> Frozen Peaks -> Sakura Jungle), terrain ground and
-- side scenery, invisible walls along both sides, and a gate between areas.
-- Other modules read the pieces they need from World (gates, breakable
-- spots, leaderboard boards, the fusion machine).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Build = require(script.Build)

local World = {}

local LENGTH = Config.AREA_LENGTH
local HALF = Config.AREA_HALF_WIDTH
local TOTAL = LENGTH * #Config.AREAS
local SIDE = 190 -- how far the scenery reaches to each side

local AREA_MODULES = { script.Forest, script.Sahara, script.Frozen, script.Sakura }

local map = Build.folder(workspace, "Map")
local terrain = workspace.Terrain

World.Areas = {} -- [i] = { Folder, Spots = { Vector3 }, Module }
World.Gates = {} -- [i] = { Barrier, Sign, Button } for the gate into area i (i >= 2)
World.Boards = {} -- [board id] = screen part (set by the Forest)
World.Fusion = nil -- the fusion machine (set by the Sahara)
World.SPAWN = Vector3.new(24, 4, 0)

-- Lighting and terrain colours ------------------------------------------------------

local Lighting = game:GetService("Lighting")
Lighting.ClockTime = 14.5
Lighting.Brightness = 2.4
Lighting.EnvironmentDiffuseScale = 0.6
Lighting.EnvironmentSpecularScale = 0.6
local atmosphere = Instance.new("Atmosphere")
atmosphere.Density = 0.28
atmosphere.Haze = 1.2
atmosphere.Color = Color3.fromRGB(200, 225, 255)
atmosphere.Decay = Color3.fromRGB(120, 150, 200)
atmosphere.Parent = Lighting

terrain:SetMaterialColor(Enum.Material.Grass, Color3.fromRGB(95, 175, 70))
terrain:SetMaterialColor(Enum.Material.LeafyGrass, Color3.fromRGB(85, 150, 70))
terrain:SetMaterialColor(Enum.Material.Sand, Color3.fromRGB(235, 200, 130))
terrain:SetMaterialColor(Enum.Material.Sandstone, Color3.fromRGB(215, 170, 110))
terrain:SetMaterialColor(Enum.Material.Snow, Color3.fromRGB(240, 246, 255))
terrain:SetMaterialColor(Enum.Material.Glacier, Color3.fromRGB(150, 205, 235))
terrain:SetMaterialColor(Enum.Material.Ice, Color3.fromRGB(170, 220, 245))
terrain.WaterColor = Color3.fromRGB(40, 140, 180)

-- Invisible walls ----------------------------------------------------------------------

local walls = Build.folder(map, "InvisibleWalls")
local function invisibleWall(center, size)
	Build.part(walls, {
		Name = "InvisibleWall",
		Size = size,
		CFrame = CFrame.new(center),
		Transparency = 1,
		CastShadow = false,
		CanQuery = false,
	})
end
for _, side in ipairs({ -1, 1 }) do
	invisibleWall(Vector3.new(TOTAL / 2, 60, side * (HALF + 2)), Vector3.new(TOTAL + 8, 140, 4))
end
invisibleWall(Vector3.new(-2, 60, 0), Vector3.new(4, 140, HALF * 2 + 8))
invisibleWall(Vector3.new(TOTAL + 2, 60, 0), Vector3.new(4, 140, HALF * 2 + 8))

-- Spawn -----------------------------------------------------------------------------

local spawn = Instance.new("SpawnLocation")
spawn.Name = "Spawn"
spawn.Anchored = true
spawn.Size = Vector3.new(12, 1, 12)
spawn.CFrame = CFrame.new(World.SPAWN.X, 0.5, 0) * CFrame.Angles(0, math.rad(-90), 0) -- facing +X
spawn.Material = Enum.Material.SmoothPlastic
spawn.Color = Color3.fromRGB(255, 120, 150)
spawn.Duration = 0
spawn.Neutral = true
spawn.Parent = map
local spawnDecal = spawn:FindFirstChildOfClass("Decal")
if spawnDecal then
	spawnDecal:Destroy()
end

-- Gates between areas ----------------------------------------------------------------

local function buildGate(i)
	local area = Config.AREAS[i]
	local x = Config.areaStart(i)
	local gate = Build.model(map, "Gate" .. i)
	local stone = Color3.fromRGB(70, 74, 95)

	for _, side in ipairs({ -1, 1 }) do
		Build.block(gate, Vector3.new(x, 0, side * (HALF - 3)), Vector3.new(8, 34, 8), { Color = stone, Material = Enum.Material.Slate })
		Build.block(gate, Vector3.new(x, 34, side * (HALF - 3)), Vector3.new(10, 3, 10), { Color = area.Color, Material = Enum.Material.Neon })
	end
	Build.block(gate, Vector3.new(x, 30, 0), Vector3.new(6, 6, HALF * 2), { Color = stone, Material = Enum.Material.Slate })

	local barrier = Build.part(gate, {
		Name = "Barrier",
		Size = Vector3.new(1, 30, HALF * 2 - 14),
		CFrame = CFrame.new(x, 15, 0),
		Color = area.Color,
		Material = Enum.Material.ForceField,
		Transparency = 0.2,
		CastShadow = false,
	})
	local sign = Build.sign(
		gate,
		CFrame.new(x, 40, 0) * CFrame.Angles(0, math.rad(90), 0),
		Vector3.new(60, 10, 1),
		area.Name:upper() .. "  ·  " .. Config.formatNumber(area.Cost) .. " COINS",
		Color3.new(1, 1, 1),
		Color3.fromRGB(30, 32, 55)
	)

	-- the button players walk up to (on the side they come from)
	local button = Build.cylinder(gate, Vector3.new(x - 8, 0, 0), 1.2, 9, {
		Name = "UnlockButton",
		Color = area.Color,
		Material = Enum.Material.Neon,
	})
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Unlock " .. area.Name
	prompt.ObjectText = Config.formatNumber(area.Cost) .. " coins"
	prompt.HoldDuration = 0.3
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = button

	World.Gates[i] = { Barrier = barrier, Sign = sign, Button = button, Prompt = prompt }
end

-- Opens (or closes) the gate into area i
function World.setGateOpen(i, open)
	local gate = World.Gates[i]
	if not gate then
		return
	end
	local area = Config.AREAS[i]
	gate.Barrier.CanCollide = not open
	gate.Barrier.Transparency = if open then 1 else 0.2
	gate.Prompt.Enabled = not open
	gate.Button.Transparency = if open then 1 else 0
	Build.setSignText(gate.Sign, if open
		then area.Name:upper()
		else area.Name:upper() .. "  ·  " .. Config.formatNumber(area.Cost) .. " COINS")
end

-- Areas -------------------------------------------------------------------------------

for i, area in ipairs(Config.AREAS) do
	local module = require(AREA_MODULES[i])
	local x0 = Config.areaStart(i)
	local folder = Build.folder(map, "Area" .. i .. "_" .. area.Name:gsub(" ", ""))
	local rng = Random.new(1000 + i) -- same layout every time
	local space = Build.space()

	-- ground: the playable strip and the scenery on both sides
	terrain:FillBlock(CFrame.new(x0 + LENGTH / 2, -6, 0), Vector3.new(LENGTH, 12, SIDE * 2), module.GROUND)

	-- keep the gate paths clear
	space:add(Vector3.new(x0, 0, 0), 14)
	space:add(Vector3.new(x0 + LENGTH, 0, 0), 14)

	local ctx = {
		Folder = folder,
		X0 = x0,
		X1 = x0 + LENGTH,
		Half = HALF,
		Side = SIDE,
		Rng = rng,
		Space = space,
		Terrain = terrain,
		World = World,
	}
	module.build(ctx)

	-- spots for this area's breakables, away from the decorations
	local spots = {}
	for _ = 1, 30 do
		local p = space:find(rng, x0 + 14, x0 + LENGTH - 14, -HALF + 12, HALF - 12, 6)
		if p then
			table.insert(spots, p)
		end
	end
	World.Areas[i] = { Folder = folder, Spots = spots, Module = module }

	if i >= 2 then
		buildGate(i)
	end
end

-- the far end: a wall of hills so the map doesn't just stop
terrain:FillBlock(CFrame.new(TOTAL + 30, 10, 0), Vector3.new(60, 40, SIDE * 2), Enum.Material.LeafyGrass)
terrain:FillBlock(CFrame.new(-40, 8, 0), Vector3.new(80, 40, SIDE * 2), Enum.Material.Grass)

return World
