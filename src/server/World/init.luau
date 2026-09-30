-- Builds the map when the server starts: four areas in a straight line along
-- +X (Forest -> Sahara -> Frozen Peaks -> Sakura Jungle), terrain ground and
-- side scenery, invisible walls along both sides, and a gate between areas.
-- Other modules read the pieces they need from World (gates, breakable
-- spots, leaderboard boards, the fusion machine).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Build = require(ReplicatedStorage.Shared.Build)

local World = {}

local LENGTH = Config.AREA_LENGTH
local HALF = Config.AREA_HALF_WIDTH
local TOTAL = LENGTH * #Config.AREAS
local SIDE = 110 -- how far the scenery reaches to each side

local AREA_MODULES = { script.Forest, script.Sahara, script.Frozen, script.Sakura }

local map = Build.folder(workspace, "Map")
local terrain = workspace.Terrain

World.Areas = {} -- [i] = { Folder, Spots = { Vector3 }, Module }
World.Gates = {} -- [i] = { Barrier, Sign, Button } for the gate into area i (i >= 2)
World.Boards = {} -- [board id] = screen part (set by the Forest)
World.Fusion = nil -- the fusion machine (set by the Sahara)
World.SPAWN = Vector3.new(10, 4, 0)
World.Spawns = {} -- [i] = CFrame on the ground at the start of area i, facing +X

-- Height of the walkable terrain at (x, z), found by casting a ray down onto
-- the terrain (not onto props), or nil if there's no ground there
local groundRay = RaycastParams.new()
groundRay.FilterType = Enum.RaycastFilterType.Include
groundRay.FilterDescendantsInstances = { workspace.Terrain }
function World.groundAt(x, z)
	local hit = workspace:Raycast(Vector3.new(x, 200, z), Vector3.new(0, -400, 0), groundRay)
	return if hit then hit.Position.Y else nil
end

-- True if the ground around (x, z) is flat and at walking height (not on a
-- drift, a hill's edge or in a pond)
function World.flatGround(x, z, radius)
	for _, offset in ipairs({ { 0, 0 }, { radius, 0 }, { -radius, 0 }, { 0, radius }, { 0, -radius } }) do
		local y = World.groundAt(x + offset[1], z + offset[2])
		if not y or math.abs(y) > 0.6 then
			return false
		end
	end
	return true
end

-- Lighting and terrain colours ------------------------------------------------------

-- bright, sunny and a little extra colourful, like a toy world
local Lighting = game:GetService("Lighting")
Lighting.ClockTime = 13
Lighting.Brightness = 3
Lighting.Ambient = Color3.fromRGB(120, 120, 140)
Lighting.OutdoorAmbient = Color3.fromRGB(170, 170, 190)
Lighting.EnvironmentDiffuseScale = 0.8
Lighting.EnvironmentSpecularScale = 0.3
Lighting.ShadowSoftness = 0.6
local atmosphere = Instance.new("Atmosphere")
atmosphere.Density = 0.18
atmosphere.Haze = 0.4
atmosphere.Glare = 0
atmosphere.Color = Color3.fromRGB(215, 235, 255)
atmosphere.Decay = Color3.fromRGB(170, 210, 255)
atmosphere.Parent = Lighting
local colour = Instance.new("ColorCorrectionEffect")
colour.Saturation = 0.18
colour.Brightness = 0.03
colour.Contrast = 0.05
colour.Parent = Lighting
local bloom = Instance.new("BloomEffect")
bloom.Intensity = 0.4
bloom.Size = 20
bloom.Threshold = 1.4
bloom.Parent = Lighting

-- terrain in bright, cartoon colours
terrain:SetMaterialColor(Enum.Material.Grass, Color3.fromRGB(110, 210, 80))
terrain:SetMaterialColor(Enum.Material.LeafyGrass, Color3.fromRGB(125, 215, 105))
terrain:SetMaterialColor(Enum.Material.Sand, Color3.fromRGB(255, 220, 140))
terrain:SetMaterialColor(Enum.Material.Snow, Color3.fromRGB(245, 250, 255))
terrain:SetMaterialColor(Enum.Material.Glacier, Color3.fromRGB(150, 220, 255))
terrain:SetMaterialColor(Enum.Material.Ice, Color3.fromRGB(185, 235, 255))
terrain:SetMaterialColor(Enum.Material.Ground, Color3.fromRGB(225, 180, 115)) -- dirt paths
terrain:SetMaterialColor(Enum.Material.Sandstone, Color3.fromRGB(240, 185, 115))
terrain:SetMaterialColor(Enum.Material.Pavement, Color3.fromRGB(220, 220, 230))

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
-- a lid, so nobody jumps over the walls from a hill or a tall prop
invisibleWall(Vector3.new(TOTAL / 2, 132, 0), Vector3.new(TOTAL + 8, 4, HALF * 2 + 8))

-- Spawn -----------------------------------------------------------------------------

local spawn = Instance.new("SpawnLocation")
spawn.Name = "Spawn"
spawn.Anchored = true
spawn.Size = Vector3.new(9, 1, 9)
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
	local white = Color3.fromRGB(250, 250, 255)

	for _, side in ipairs({ -1, 1 }) do
		Build.block(gate, Vector3.new(x, 0, side * (HALF - 2.5)), Vector3.new(5, 20, 5), { Color = white })
		Build.block(gate, Vector3.new(x, 20, side * (HALF - 2.5)), Vector3.new(6.5, 2, 6.5), { Color = area.Color })
		Build.ball(gate, Vector3.new(x, 23, side * (HALF - 2.5)), 3.4, { Color = area.Color, Material = Enum.Material.Neon })
	end
	Build.block(gate, Vector3.new(x, 17, 0), Vector3.new(4, 3, HALF * 2 - 4), { Color = white })

	local barrier = Build.part(gate, {
		Name = "Barrier",
		Size = Vector3.new(0.6, 17, HALF * 2 - 10),
		CFrame = CFrame.new(x, 8.5, 0),
		Color = area.Color,
		Material = Enum.Material.ForceField,
		Transparency = 0.2,
		CastShadow = false,
	})
	local sign = Build.sign(
		gate,
		CFrame.new(x, 23.5, 0) * CFrame.Angles(0, math.rad(90), 0),
		Vector3.new(34, 6, 0.8),
		area.Name:upper() .. "  ·  " .. Config.formatNumber(Config.areaCost(i)) .. " COINS",
		Color3.new(1, 1, 1),
		area.Color:Lerp(Color3.new(0, 0, 0), 0.15)
	)

	-- the button players walk up to (on the side they come from)
	local button = Build.cylinder(gate, Vector3.new(x - 6, 0, 0), 1, 7, {
		Name = "UnlockButton",
		Color = area.Color,
		Material = Enum.Material.Neon,
	})
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Unlock " .. area.Name
	prompt.ObjectText = Config.formatNumber(Config.areaCost(i)) .. " coins"
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
		else area.Name:upper() .. "  ·  " .. Config.formatNumber(Config.areaCost(i)) .. " COINS")
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

	-- keep the gate paths and the spawn clear (a character that spawns inside
	-- something gets pushed up on top of it)
	space:add(Vector3.new(x0, 0, 0), 9)
	space:add(Vector3.new(x0 + LENGTH, 0, 0), 9)
	space:add(Vector3.new(x0 + 10, 0, 0), 9)

	-- spots for this area's breakables, away from the decorations. Areas call
	-- ctx.reserveSpots() after their big props and before the small ones, so
	-- flowers and rocks never crowd the play space out.
	local spots = {}
	local function reserveSpots()
		if #spots > 0 then
			return
		end
		for _ = 1, 90 do
			local p = space:find(rng, x0 + 7, x0 + LENGTH - 7, -HALF + 6, HALF - 6, 3.5)
			if p then
				table.insert(spots, p)
			end
			if #spots >= 24 then
				break
			end
		end
	end

	local ctx = {
		reserveSpots = reserveSpots,
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

	reserveSpots() -- in case the area didn't
	World.Areas[i] = { Folder = folder, Spots = spots, Module = module, Space = space }

	if i >= 2 then
		buildGate(i)
	end
end

-- The playable strip is flat ground at Y = 0: clear any terrain that ended up
-- above it (the edges of hills, drifts and banks), so nothing can bury a
-- living coin or push the player up when they spawn. New areas get this for free.
terrain:FillBlock(CFrame.new(TOTAL / 2, 30, 0), Vector3.new(TOTAL + 8, 60, HALF * 2), Enum.Material.Air)

-- Breakable spots were picked before the small props and some terrain; keep
-- only the ones on flat ground and set them to its real height
-- only the ones on flat ground and set them to its real height. If too few
-- pass (terrain can come out slightly bumpy), the rest are kept on whatever
-- ground is there, so every area always has enough spots for its targets.
for i, area in ipairs(World.Areas) do
	local valid, rest, total = {}, {}, #area.Spots
	for _, spot in ipairs(area.Spots) do
		if World.flatGround(spot.X, spot.Z, 2.5) then
			table.insert(valid, Vector3.new(spot.X, World.groundAt(spot.X, spot.Z), spot.Z))
		else
			table.insert(rest, Vector3.new(spot.X, World.groundAt(spot.X, spot.Z) or 0, spot.Z))
		end
	end
	local MIN_SPOTS = 12
	for _, spot in ipairs(rest) do
		if #valid >= MIN_SPOTS then
			break
		end
		table.insert(valid, spot)
	end
	-- last resort: a line of spots down the middle of the area
	local x0 = Config.areaStart(i)
	for k = 1, MIN_SPOTS - #valid do
		local x, z = x0 + 12 + (k - 1) * 7, (if k % 2 == 0 then 8 else -8)
		table.insert(valid, Vector3.new(x, World.groundAt(x, z) or 0, z))
	end
	if #rest > 0 then
		warn(string.format("[World] %s: %d of %d target spots were on uneven ground", Config.AREAS[i].Name, #rest, total))
	end
	area.Spots = valid
end

-- a spawn point on the ground at the start of every area
for i = 1, #Config.AREAS do
	local x = Config.areaStart(i) + 10
	local y = World.groundAt(x, 0) or 0
	World.Spawns[i] = CFrame.new(x, y + 3, 0) * CFrame.Angles(0, math.rad(-90), 0)
end
-- the spawn pad sits on the measured ground
spawn.CFrame = CFrame.new(World.SPAWN.X, (World.groundAt(World.SPAWN.X, 0) or 0) + 0.5, 0) * CFrame.Angles(0, math.rad(-90), 0)

-- the far end: a wall of hills so the map doesn't just stop
-- (they start behind the end walls, so they never reach into the playable strip)
terrain:FillBlock(CFrame.new(TOTAL + 32, 6, 0), Vector3.new(48, 24, SIDE * 2), Enum.Material.LeafyGrass)
terrain:FillBlock(CFrame.new(-32, 6, 0), Vector3.new(48, 24, SIDE * 2), Enum.Material.Grass)

return World
