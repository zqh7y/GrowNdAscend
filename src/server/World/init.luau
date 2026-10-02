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

local AREA_MODULES = { script.Forest, script.Sahara, script.Frozen, script.Sakura, script.Arena }

local map = Build.folder(workspace, "Map")
local terrain = workspace.Terrain

World.Areas = {} -- [i] = { Folder, Spots = { Vector3 }, Module }
World.Gates = {} -- [i] = { Barrier, Sign, Button } for the gate into area i (i >= 2)
World.Boards = {} -- [board id] = screen part (set by the Forest)
World.UpgradeBoard = nil -- the Upgrade Board's screen part (first area)
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
-- (flat compared with the ground's own height there: Roblox's terrain
-- surface doesn't come out at exactly Y = 0, so never assume it does)
function World.flatGround(x, z, radius)
	local center = World.groundAt(x, z)
	if not center then
		return false
	end
	for _, offset in ipairs({ { radius, 0 }, { -radius, 0 }, { 0, radius }, { 0, -radius } }) do
		local y = World.groundAt(x + offset[1], z + offset[2])
		if not y or math.abs(y - center) > 0.6 then
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
terrain:SetMaterialColor(Enum.Material.Basalt, Color3.fromRGB(120, 98, 92)) -- the Lava Arena's warm volcanic rock
terrain:SetMaterialColor(Enum.Material.CrackedLava, Color3.fromRGB(255, 120, 50))

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

-- One side of a gate's wall: a lock, the world's name and the price in big
-- chunky white letters with a dark outline (like the area gates in pet
-- simulator games). Drawn with a SurfaceGui so it is crisp up close.
local function gateFace(barrier, face, area, i)
	local dark = area.Color:Lerp(Color3.new(0, 0, 0), 0.55)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "PriceFace"
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 20
	gui.LightInfluence = 0
	gui.MaxDistance = 250
	gui.Parent = barrier

	local function label(props)
		local l = Instance.new("TextLabel")
		l.BackgroundTransparency = 1
		l.Font = Enum.Font.FredokaOne
		l.TextScaled = true
		l.TextColor3 = Color3.new(1, 1, 1)
		l.AnchorPoint = Vector2.new(0.5, 0.5)
		for k, v in pairs(props) do
			l[k] = v
		end
		local stroke = Instance.new("UIStroke")
		stroke.Color = dark
		stroke.Thickness = props.Name == "Price" and 7 or 5
		stroke.LineJoinMode = Enum.LineJoinMode.Round
		stroke.Parent = l
		l.Parent = gui
		return l
	end
	local function round(frame, radius)
		local c = Instance.new("UICorner")
		c.CornerRadius = radius
		c.Parent = frame
	end

	-- the lock: a shackle over a body with a keyhole
	local lock = Instance.new("Frame")
	lock.Name = "Lock"
	lock.BackgroundTransparency = 1
	lock.AnchorPoint = Vector2.new(0.5, 0.5)
	lock.Position = UDim2.fromScale(0.5, 0.2)
	lock.Size = UDim2.fromOffset(70, 80)
	lock.Parent = gui
	local shackle = Instance.new("Frame")
	shackle.BackgroundTransparency = 1
	shackle.Position = UDim2.fromOffset(15, 0)
	shackle.Size = UDim2.fromOffset(40, 50)
	round(shackle, UDim.new(0.5, 0))
	local ring = Instance.new("UIStroke")
	ring.Color = Color3.new(1, 1, 1)
	ring.Thickness = 9
	ring.Parent = shackle
	shackle.Parent = lock
	local body = Instance.new("Frame")
	body.BackgroundColor3 = Color3.fromRGB(255, 205, 60)
	body.Position = UDim2.fromOffset(0, 32)
	body.Size = UDim2.fromOffset(70, 48)
	round(body, UDim.new(0, 10))
	local edge = Instance.new("UIStroke")
	edge.Color = dark
	edge.Thickness = 5
	edge.Parent = body
	body.Parent = lock
	local hole = Instance.new("Frame")
	hole.BackgroundColor3 = dark
	hole.AnchorPoint = Vector2.new(0.5, 0.5)
	hole.Position = UDim2.fromScale(0.5, 0.5)
	hole.Size = UDim2.fromOffset(12, 20)
	round(hole, UDim.new(0.5, 0))
	hole.Parent = body

	label({ Name = "World", Text = area.Name:upper(), Position = UDim2.fromScale(0.5, 0.42), Size = UDim2.fromScale(0.7, 0.13) })

	-- the price: a gold coin and the number, big
	local row = Instance.new("Frame")
	row.Name = "PriceRow"
	row.BackgroundTransparency = 1
	row.AnchorPoint = Vector2.new(0.5, 0.5)
	row.Position = UDim2.fromScale(0.5, 0.66)
	row.Size = UDim2.fromScale(0.9, 0.26)
	row.Parent = gui
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0, 16)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = row
	local coin = Instance.new("Frame")
	coin.Name = "Coin"
	coin.LayoutOrder = 1
	coin.BackgroundColor3 = Color3.fromRGB(255, 200, 40)
	coin.Size = UDim2.fromOffset(74, 74)
	round(coin, UDim.new(0.5, 0))
	local rim = Instance.new("UIStroke")
	rim.Color = Color3.fromRGB(200, 120, 10)
	rim.Thickness = 6
	rim.Parent = coin
	local shine = Instance.new("Frame")
	shine.BackgroundColor3 = Color3.fromRGB(255, 240, 160)
	shine.AnchorPoint = Vector2.new(0.5, 0.5)
	shine.Position = UDim2.fromScale(0.5, 0.5)
	shine.Size = UDim2.fromScale(0.5, 0.5)
	round(shine, UDim.new(0.5, 0))
	shine.Parent = coin
	coin.Parent = row
	local cost = Config.AREA_COST_FOR_TESTING or area.Cost
	local price = label({ Name = "Price", Text = Config.formatNumber(cost), AnchorPoint = Vector2.new(0, 0.5), LayoutOrder = 2,
		AutomaticSize = Enum.AutomaticSize.X, TextScaled = false, TextSize = 76, Size = UDim2.fromOffset(0, 80),
		TextColor3 = Color3.fromRGB(255, 226, 90) })
	price.Parent = row

	label({ Name = "Hint", Text = if Config.AREA_COST_FOR_TESTING then "TEST PRICE  ·  UNLOCK AT THE BUTTON" else "UNLOCK AT THE BUTTON",
		Position = UDim2.fromScale(0.5, 0.89), Size = UDim2.fromScale(0.6, 0.08) })
	return gui
end

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

	-- the wall itself: coloured glass you can see, with white rails and the
	-- price written on both sides in big chunky letters
	local barrier = Build.part(gate, {
		Name = "Barrier",
		Size = Vector3.new(1, 15, HALF * 2 - 10),
		CFrame = CFrame.new(x, Config.GROUND_Y + 7.5, 0),
		Color = area.Color,
		Material = Enum.Material.Glass,
		Reflectance = 0.15,
		Transparency = 0.25,
		CastShadow = false,
	})
	for _, y in ipairs({ Config.GROUND_Y, Config.GROUND_Y + 15 }) do
		Build.part(barrier, {
			Name = "Rail",
			Size = Vector3.new(1.6, 1.2, HALF * 2 - 10),
			CFrame = CFrame.new(x, y, 0),
			Color = white,
			CanCollide = false,
		})
	end
	-- an invisible wall from the ground up to the lid while it's locked, so
	-- nobody gets over by climbing onto the gate or jumping from a tree
	local blocker = Build.part(gate, {
		Name = "Blocker",
		Size = Vector3.new(2, 140, HALF * 2 + 8),
		CFrame = CFrame.new(x, 60, 0),
		Transparency = 1,
		CastShadow = false,
		CanQuery = false,
	})
	local faces = {}
	for _, face in ipairs({ Enum.NormalId.Left, Enum.NormalId.Right }) do
		table.insert(faces, gateFace(barrier, face, area, i))
	end
	local sign = Build.sign(
		gate,
		CFrame.new(x, 23.5, 0) * CFrame.Angles(0, math.rad(90), 0),
		Vector3.new(34, 6, 0.8),
		area.Name:upper() .. "  ·  " .. Config.areaCostText(i),
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
	prompt.ObjectText = string.lower(Config.areaCostText(i))
	prompt.HoldDuration = 0.3
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = button

	World.Gates[i] = { Barrier = barrier, Blocker = blocker, Sign = sign, Button = button, Prompt = prompt, Faces = faces }
end

-- Opens (or closes) the gate into area i
function World.setGateOpen(i, open)
	local gate = World.Gates[i]
	if not gate then
		return
	end
	local area = Config.AREAS[i]
	gate.Barrier.CanCollide = not open
	gate.Blocker.CanCollide = not open
	gate.Barrier.Transparency = if open then 1 else 0.25
	for _, rail in ipairs(gate.Barrier:GetChildren()) do
		if rail.Name == "Rail" then
			rail.Transparency = if open then 1 else 0
		end
	end
	for _, face in ipairs(gate.Faces) do
		face.Enabled = not open
	end
	gate.Prompt.Enabled = not open
	gate.Button.Transparency = if open then 1 else 0
	Build.setSignText(gate.Sign, if open
		then area.Name:upper()
		else area.Name:upper() .. "  ·  " .. Config.areaCostText(i))
end

-- The Mega Roll pad (Sahara) ----------------------------------------------------------
-- A round pale-blue pad with a glowing ring, a pile of big white dice with
-- navy pips, potion bottles around it and a second little pile of dice
-- beside it. The client hangs the sign over it ("x50,000 Roll!" and the
-- timer) and claims the roll when you step on it once it's ready.

local PIP_PATTERNS = {
	{ { 0, 0 } },
	{ { -1, -1 }, { 1, 1 } },
	{ { -1, -1 }, { 0, 0 }, { 1, 1 } },
	{ { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 } },
	{ { -1, -1 }, { 1, -1 }, { 0, 0 }, { -1, 1 }, { 1, 1 } },
	{ { -1, -1 }, { 1, -1 }, { -1, 0 }, { 1, 0 }, { -1, 1 }, { 1, 1 } },
}
local DIE_WHITE = Color3.fromRGB(236, 243, 255)
local PIP_NAVY = Color3.fromRGB(22, 34, 92)

-- one die of `size` studs at `cf` (its centre), pips on every side
local function die(parent, cf, size)
	local model = Build.model(parent, "Die")
	Build.part(model, { Size = Vector3.new(size, size, size), CFrame = cf, Color = DIE_WHITE })
	local half, spread, pip = size / 2, size * 0.26, size * 0.2
	-- each face: where its centre is and how a pip (a flat cylinder along X) turns to lie on it
	local faces = {
		{ N = 1, At = function(a, b) return CFrame.new(0, half, 0) * CFrame.new(a, 0, b) * CFrame.Angles(0, 0, math.rad(90)) end },
		{ N = 6, At = function(a, b) return CFrame.new(0, -half, 0) * CFrame.new(a, 0, b) * CFrame.Angles(0, 0, math.rad(90)) end },
		{ N = 2, At = function(a, b) return CFrame.new(half, 0, 0) * CFrame.new(0, a, b) end },
		{ N = 5, At = function(a, b) return CFrame.new(-half, 0, 0) * CFrame.new(0, a, b) end },
		{ N = 3, At = function(a, b) return CFrame.new(0, 0, half) * CFrame.new(a, b, 0) * CFrame.Angles(0, math.rad(90), 0) end },
		{ N = 4, At = function(a, b) return CFrame.new(0, 0, -half) * CFrame.new(a, b, 0) * CFrame.Angles(0, math.rad(90), 0) end },
	}
	for _, face in ipairs(faces) do
		for _, p in ipairs(PIP_PATTERNS[face.N]) do
			Build.part(model, {
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(0.12, pip, pip),
				CFrame = cf * face.At(p[1] * spread, p[2] * spread),
				Color = PIP_NAVY,
				CanCollide = false,
				CastShadow = false,
			})
		end
	end
	return model
end

-- a little potion bottle standing at `base`
local function potion(parent, base, liquid, tilt)
	local model = Build.model(parent, "Potion")
	local cf = CFrame.new(base) * CFrame.Angles(0, tilt, math.rad(8) * math.sin(tilt * 3))
	local up = CFrame.Angles(0, 0, math.rad(90))
	Build.part(model, { Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.6, 1.3, 1.3), CFrame = cf * CFrame.new(0, 0.8, 0) * up,
		Color = Color3.fromRGB(220, 240, 255), Material = Enum.Material.Glass, Transparency = 0.45, CanCollide = false })
	Build.part(model, { Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.1, 1.1, 1.1), CFrame = cf * CFrame.new(0, 0.6, 0) * up,
		Color = liquid, Material = Enum.Material.Neon, CanCollide = false })
	Build.part(model, { Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.6, 0.55, 0.55), CFrame = cf * CFrame.new(0, 1.85, 0) * up,
		Color = Color3.fromRGB(220, 240, 255), Material = Enum.Material.Glass, Transparency = 0.45, CanCollide = false })
	Build.part(model, { Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.45, 0.6, 0.6), CFrame = cf * CFrame.new(0, 2.3, 0) * up,
		Color = Color3.fromRGB(176, 120, 70), CanCollide = false })
end

function World.buildMegaRoll(center)
	local model = Build.model(map, "MegaRoll")
	local r = Config.MEGA_ROLL.Radius
	-- stand on the real ground (the sand isn't exactly at Y = 0)
	center = Vector3.new(center.X, math.max(World.groundAt(center.X, center.Z) or 0, Config.GROUND_Y) - 0.3, center.Z)
	-- the pad: a white rim, the pale blue top and a glowing ring on it
	Build.cylinder(model, center, 1, r * 2 + 1.2, { Name = "Rim", Color = Color3.fromRGB(250, 252, 255) })
	local pad = Build.cylinder(model, center, 1.3, r * 2, { Name = "Pad", Color = Color3.fromRGB(184, 210, 255) })
	Build.cylinder(model, center + Vector3.new(0, 1.3, 0), 0.06, r * 2 - 2.5, { Name = "Ring", Color = Color3.fromRGB(255, 236, 150), Material = Enum.Material.Neon, CanCollide = false })
	Build.cylinder(model, center + Vector3.new(0, 1.32, 0), 0.06, r * 2 - 3.3, { Color = Color3.fromRGB(184, 210, 255), CanCollide = false })
	local top = center.Y + 1.3
	-- the big pile at the back of the pad: three dice and one on top
	local back = center + Vector3.new(2.5, top - center.Y, -3)
	local s = 3.4
	die(model, CFrame.new(back + Vector3.new(-s * 0.55, s / 2, 0)) * CFrame.Angles(0, math.rad(12), 0), s)
	die(model, CFrame.new(back + Vector3.new(s * 0.55, s / 2, 0.3)) * CFrame.Angles(0, math.rad(-20), 0), s)
	die(model, CFrame.new(back + Vector3.new(0, s / 2, -s * 0.9)) * CFrame.Angles(0, math.rad(35), 0), s)
	die(model, CFrame.new(back + Vector3.new(0, s * 1.5, -0.3)) * CFrame.Angles(0, math.rad(-8), 0), s)
	-- potions around it
	local colours = { Color3.fromRGB(80, 220, 120), Color3.fromRGB(255, 90, 120), Color3.fromRGB(255, 220, 60), Color3.fromRGB(80, 120, 255), Color3.fromRGB(255, 140, 60) }
	for k, at in ipairs({ { -3.5, 0.5 }, { -2.6, 2.2 }, { 4.6, 1.6 }, { 5.6, -0.4 }, { 3.4, 2.6 } }) do
		potion(model, Vector3.new(back.X + at[1], top, back.Z + at[2]), colours[k], k * 1.3)
	end
	-- a small pile beside the pad
	local side = center + Vector3.new(-r - 3.5, 0, -1)
	local t = 2.6
	die(model, CFrame.new(side + Vector3.new(-t * 0.55, t / 2, 0)) * CFrame.Angles(0, math.rad(25), 0), t)
	die(model, CFrame.new(side + Vector3.new(t * 0.55, t / 2, 0.4)) * CFrame.Angles(0, math.rad(-10), 0), t)
	die(model, CFrame.new(side + Vector3.new(0, t * 1.5, 0.2)) * CFrame.Angles(0, math.rad(40), 0), t)
	-- where the sign hangs (the client puts the text there)
	Build.part(model, { Name = "Sign", Size = Vector3.new(1, 1, 1), CFrame = CFrame.new(back + Vector3.new(0, s * 2 + 4.5, 0)), Transparency = 1, CanCollide = false, CastShadow = false })
	-- soft sparkles rising from the pad
	local sparkles = Instance.new("ParticleEmitter")
	sparkles.Color = ColorSequence.new(Color3.fromRGB(255, 246, 190))
	sparkles.LightEmission = 1
	sparkles.Size = NumberSequence.new(0.35, 0)
	sparkles.Lifetime = NumberRange.new(1.5, 2.5)
	sparkles.Rate = 6
	sparkles.Speed = NumberRange.new(1.5, 3)
	sparkles.SpreadAngle = Vector2.new(25, 25)
	sparkles.EmissionDirection = Enum.NormalId.Top
	sparkles.Parent = pad
	World.MegaPad = Vector3.new(center.X, top, center.Z)
	return model
end

-- Rebirth perk pads ---------------------------------------------------------------------
-- One in each world (Config.PERKS): a square pad with a glowing ring and a
-- gold card floating and turning over it, showing the perk. It's yours as
-- soon as you have enough rebirths (nothing is spent); the client writes
-- "Owned" or "Need 3 rebirths" under the card.
local PERK_ICONS = { Coins = "💰", Luck = "🍀", Damage = "⚔️", Exp = "⭐" }

function World.buildPerkPad(index, perk)
	local folder = map:FindFirstChild("Perks") or Build.folder(map, "Perks")
	local model = Build.model(folder, "PerkPad" .. index)
	model:SetAttribute("PerkIndex", index)
	local x0 = Config.areaStart(perk.Area)
	local at = Vector3.new(x0 + perk.At[1], Config.GROUND_Y, perk.At[2])
	Build.block(model, at - Vector3.new(0, 0.5, 0), Vector3.new(9.6, 1.1, 9.6), { Color = Color3.fromRGB(250, 252, 255) })
	Build.block(model, at - Vector3.new(0, 0.45, 0), Vector3.new(8.4, 1.1, 8.4), { Color = Color3.fromRGB(205, 218, 245) })
	local top = at + Vector3.new(0, 0.65, 0)
	Build.cylinder(model, top, 0.06, 5.4, { Color = Color3.fromRGB(255, 225, 110), Material = Enum.Material.Neon, CanCollide = false })
	Build.cylinder(model, top + Vector3.new(0, 0.02, 0), 0.06, 4.6, { Color = Color3.fromRGB(205, 218, 245), CanCollide = false })
	-- the card
	local card = Build.part(model, {
		Name = "Card",
		Size = Vector3.new(3.6, 4.6, 0.35),
		CFrame = CFrame.new(top + Vector3.new(0, 4.4, 0)),
		Color = Color3.fromRGB(255, 205, 80),
		CanCollide = false,
	})
	Build.spin(card, 30, "Y")
	Build.bob(card, 0.3, 1)
	local glow = Instance.new("PointLight")
	glow.Color = Color3.fromRGB(255, 220, 140)
	glow.Range = 10
	glow.Brightness = 0.8
	glow.Parent = card
	for _, face in ipairs({ Enum.NormalId.Front, Enum.NormalId.Back }) do
		local gui = Instance.new("SurfaceGui")
		gui.Face = face
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 50
		gui.LightInfluence = 0
		gui.Parent = card
		local function label(text, y, h, color)
			local l = Instance.new("TextLabel")
			l.BackgroundTransparency = 1
			l.Position = UDim2.fromScale(0.06, y)
			l.Size = UDim2.fromScale(0.88, h)
			l.Font = Enum.Font.FredokaOne
			l.TextScaled = true
			l.TextColor3 = color
			l.Text = text
			local stroke = Instance.new("UIStroke")
			stroke.Color = Color3.fromRGB(150, 95, 20)
			stroke.Thickness = 2
			stroke.Parent = l
			l.Parent = gui
		end
		label(PERK_ICONS[perk.Stat] or "✨", 0.06, 0.36, Color3.new(1, 1, 1))
		label(perk.Name, 0.46, 0.16, Color3.new(1, 1, 1))
		label(Config.perkText(perk), 0.64, 0.14, Color3.fromRGB(255, 250, 220))
		label(perk.Rebirths .. (if perk.Rebirths == 1 then " rebirth" else " rebirths"), 0.81, 0.12, Color3.fromRGB(255, 240, 200))
	end
	-- the status under the card (the client fills it in for you)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Status"
	gui.Size = UDim2.fromScale(8, 1.6)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 1.6, 0)
	gui.MaxDistance = 80
	gui.LightInfluence = 0
	gui.Adornee = model:FindFirstChildWhichIsA("BasePart")
	gui.Parent = model
	local status = Instance.new("TextLabel")
	status.Name = "Text"
	status.BackgroundTransparency = 1
	status.Size = UDim2.fromScale(1, 1)
	status.Font = Enum.Font.FredokaOne
	status.TextScaled = true
	status.TextColor3 = Color3.new(1, 1, 1)
	status.Text = "Need " .. perk.Rebirths .. " rebirths"
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(40, 40, 70)
	stroke.Thickness = 2.5
	stroke.Parent = status
	status.Parent = gui
	return model
end

-- The Upgrade Board --------------------------------------------------------------------
-- A big stand like an incremental game's upgrade wall: a white frame with
-- a green cap and an "UPGRADES" sign, clovers on top and a screen part the
-- client draws every upgrade on (sections on the left, rows with BUY
-- buttons you click right there). It replaced the upgrade tree screen.
local GREEN = Color3.fromRGB(46, 196, 120)
function World.buildUpgradeBoard(center)
	local model = Build.model(map, "UpgradeBoard")
	local facing = CFrame.lookAt(center, Vector3.new(center.X, center.Y, 0))
	local WIDTH, HEIGHT = 20, 15
	local white = Color3.fromRGB(250, 250, 255)
	-- a raised stage to stand it on (tall enough to show above the grass)
	local STAGE = 2.4
	local lift = STAGE - 1.2 -- (the frame below was laid out for a 1.2 stage)
	Build.part(model, { Name = "Stage", Size = Vector3.new(WIDTH + 4, STAGE - 0.3, 7), CFrame = facing * CFrame.new(0, (STAGE - 0.3) / 2, 0), Color = white })
	Build.part(model, { Size = Vector3.new(WIDTH + 4.2, 0.3, 7.2), CFrame = facing * CFrame.new(0, STAGE - 0.15, 0), Color = GREEN })
	-- wide stairs up to it from the path side (each step 0.6 high, green
	-- edges), and a green carpet from the path to the bottom step
	for k = 1, 3 do
		local top = STAGE - k * 0.6
		local z = -3.5 - (k - 0.5) * 1.2
		Build.part(model, { Name = "Stair" .. k, Size = Vector3.new(WIDTH + 2, top, 1.2), CFrame = facing * CFrame.new(0, top / 2, z), Color = white })
		Build.part(model, { Size = Vector3.new(WIDTH + 2.1, 0.1, 0.3), CFrame = facing * CFrame.new(0, top + 0.05, z - 0.45), Color = GREEN })
	end
	Build.part(model, { Name = "Carpet", Size = Vector3.new(6, 0.12, 10), CFrame = facing * CFrame.new(0, 0.06, -12.1), Color = GREEN, Material = Enum.Material.Fabric })
	-- the frame, the cap, the posts
	Build.part(model, { Size = Vector3.new(WIDTH + 1, HEIGHT + 1, 0.8), CFrame = facing * CFrame.new(0, lift + 1.2 + (HEIGHT + 1) / 2, 0.2), Color = white })
	Build.part(model, { Size = Vector3.new(WIDTH + 1.4, 1.2, 1.2), CFrame = facing * CFrame.new(0, lift + 1.8 + HEIGHT + 0.6, 0.2), Color = GREEN })
	for _, x in ipairs({ -WIDTH / 2 - 1, WIDTH / 2 + 1 }) do
		Build.part(model, { Size = Vector3.new(0.8, HEIGHT + 5 + lift, 0.8), CFrame = facing * CFrame.new(x, (HEIGHT + 5 + lift) / 2 + 1, 0.2), Color = white })
		Build.ball(model, (facing * CFrame.new(x, lift + HEIGHT + 6.2, 0.2)).Position, 1.3, { Color = GREEN, Material = Enum.Material.Neon })
	end
	Build.sign(model, facing * CFrame.new(0, lift + HEIGHT + 4.2, 0.2), Vector3.new(14, 2.8, 0.6), "UPGRADES", Color3.new(1, 1, 1), GREEN)
	-- three big clovers on top
	for k = -1, 1 do
		local at = facing * CFrame.new(k * 6.5, lift + HEIGHT + 7.2, 0.2)
		for _, o in ipairs({ { -0.5, 0.5 }, { 0.5, 0.5 }, { -0.5, -0.5 }, { 0.5, -0.5 } }) do
			Build.ball(model, (at * CFrame.new(o[1], o[2], 0)).Position, 1.1, { Color = GREEN })
		end
	end
	local screen = Build.part(model, {
		Name = "Screen",
		Size = Vector3.new(WIDTH, HEIGHT, 0.2),
		CFrame = facing * CFrame.new(0, lift + 1.8 + HEIGHT / 2, -0.3),
		Color = Color3.fromRGB(255, 255, 255),
	})
	return screen
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

	-- this world's rebirth perk pad (kept clear of props)
	for k, perk in ipairs(Config.PERKS) do
		if perk.Area == i then
			space:add(Vector3.new(x0 + perk.At[1], 0, perk.At[2]), 6.5)
			World.buildPerkPad(k, perk)
		end
	end

	-- the Upgrade Board stands in the first area, on the right of the path
	-- near the spawn (the leaderboards are on the left), facing the middle
	if i == 1 then
		local center = Vector3.new(x0 + 22, Config.GROUND_Y, HALF - 9) -- (back from the edge, on the real ground)
		World.UpgradeBoard = World.buildUpgradeBoard(center)
		for dx = -12, 12, 6 do
			space:add(center + Vector3.new(dx, 0, 0), 5.5)
			-- and the stairs and the carpet in front, kept clear
			space:add(center + Vector3.new(dx, 0, -7), 4.5)
		end
		space:add(center + Vector3.new(0, 0, -13), 5)
	end

	-- the Mega Roll pad stands in the Sahara, on the open sand just past the
	-- gate (the -Z side, across from the Pet Aura Machine)
	if i == 2 then
		local megaAt = Vector3.new(x0 + 17, 0, -(HALF - 13))
		World.buildMegaRoll(megaAt)
		space:add(megaAt, Config.MEGA_ROLL.Radius + 2)
		space:add(megaAt + Vector3.new(-Config.MEGA_ROLL.Radius - 3.5, 0, -1), 3.5)
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
	World.Areas[i] = { Folder = folder, Spots = spots, Module = module, Space = space, BossSpot = ctx.BossSpot }

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

-- Landing on the spawn pad -----------------------------------------------------------
-- When something stands on the pad (another player, a pet, an enemy),
-- Roblox lifts a new character above it, sometimes all the way onto the
-- invisible lid over the map. So every new character is put on the pad
-- itself, and anyone who ends up above the play space (on the lid or
-- falling off) is brought back to the pad.
local Players = game:GetService("Players")
local LID_Y = 110 -- above every hill and prop, below the lid (Y 132)

local function placeOnPad(character)
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local lift = (if humanoid then humanoid.HipHeight else 2) + root.Size.Y / 2 + 0.5
	character:PivotTo(CFrame.new(spawn.Position + Vector3.new(0, spawn.Size.Y / 2 + lift, 0)) * spawn.CFrame.Rotation)
	root.AssemblyLinearVelocity = Vector3.zero
end
World.placeOnPad = placeOnPad

local function watch(player)
	player.CharacterAdded:Connect(function(character)
		-- wait for the body to be assembled, then set it on the pad
		for _ = 1, 50 do
			if character:FindFirstChild("HumanoidRootPart") then
				break
			end
			task.wait(0.1)
		end
		task.wait()
		if character.Parent then
			placeOnPad(character)
		end
	end)
end
Players.PlayerAdded:Connect(watch)
for _, player in ipairs(Players:GetPlayers()) do
	watch(player)
end
task.spawn(function()
	while true do
		task.wait(1)
		for _, player in ipairs(Players:GetPlayers()) do
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if root and (root.Position.Y > LID_Y or root.Position.Y < -40) then
				placeOnPad(character)
			end
		end
	end
end)

return World
