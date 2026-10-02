-- The living coins of each world: how they look (built on the client, see
-- client/Living.luau) and how they jump. The server only keeps their data
-- (server/Breakables.luau) and reads the jump numbers from here.
--
-- To add a world's coin: add a STYLES row and a builder. Builders make the
-- model with its feet at (0, 0, 0), facing -Z (its face looks where it hops).
local Build = require(script.Parent.Build)

local Coins = {}

-- How each world's coin moves:
--   Motion   "vertical": springs straight up, stays upright (tree)
--            "sway":     a bouncy hop, swaying side to side, double bounce (cactus)
--            "skate":    a low slide with a full spin (ice cube)
--            "flip":     a hop with a somersault (sushi)
--            "stomp":    a slow, heavy step with a big landing (the boss)
--   Height   how high it jumps (studs), Distance how far (min, max)
--   Air      seconds in the air, Rest seconds waiting between jumps (min, max)
Coins.STYLES = {
	{ Motion = "vertical", Height = 3.4, Distance = { 1.5, 3 }, Air = 0.6, Rest = { 2.4, 3.8 } },
	{ Motion = "sway", Height = 2.4, Distance = { 3, 4.5 }, Air = 0.55, Rest = { 2.6, 4 } },
	{ Motion = "skate", Height = 0.7, Distance = { 3.5, 5 }, Air = 0.7, Rest = { 2.4, 3.8 } },
	{ Motion = "flip", Height = 3, Distance = { 3.5, 5 }, Air = 0.65, Rest = { 2.6, 4 } },
	-- World 5's boss: slow, heavy stomps around the middle of the arena
	{ Motion = "stomp", Height = 1.4, Distance = { 2, 3.5 }, Air = 1.5, Rest = { 4, 7 } },
}

local function pick(rng, list)
	return list[rng:NextInteger(1, #list)]
end

local ORIGIN = Vector3.zero

-- World 1: small fruit trees --------------------------------------------------------------

local BARK = Color3.fromRGB(160, 100, 60)
local LEAF_GREENS = { Color3.fromRGB(95, 200, 75), Color3.fromRGB(125, 210, 70), Color3.fromRGB(70, 185, 95) }

local function tree(parent, rng)
	local model = Build.model(parent, "Tree")
	local trunk = Build.cylinder(model, ORIGIN, 2.4, 0.8, { Color = BARK })
	Build.cylinder(model, ORIGIN, 0.4, 1.3, { Color = BARK }) -- root flare
	local top = Vector3.new(0, 3.6, 0)
	Build.leafCluster(model, rng, top, 3.6, pick(rng, LEAF_GREENS))
	-- apples, oranges or cherries so it reads as "worth something"
	local fruit = pick(rng, { Color3.fromRGB(240, 50, 60), Color3.fromRGB(255, 150, 40), Color3.fromRGB(255, 80, 140) })
	for k = 1, 4 do
		local a = k / 4 * math.pi * 2 + rng:NextNumber(-0.4, 0.4)
		Build.ball(model, top + Vector3.new(math.cos(a) * 1.6, rng:NextNumber(-0.6, 0.6), math.sin(a) * 1.6), 0.6, { Color = fruit })
	end
	Build.face(model, CFrame.new(top + Vector3.new(0, -0.2, -1.75)), 0.9)
	return model, trunk
end

-- World 2: cactuses (saguaro, barrel, prickly pear) ------------------------------------------

local CACTUS = Color3.fromRGB(80, 200, 95)

local function ribbed(model, base, height, width, color)
	local body = Build.cylinder(model, base, height, width, { Color = color })
	Build.ball(model, base + Vector3.new(0, height, 0), width, { Color = color })
	for k = 0, 5 do
		local a = k / 6 * math.pi * 2
		Build.block(model, base + Vector3.new(math.cos(a) * width * 0.45, 0, math.sin(a) * width * 0.45), Vector3.new(0.18, height, 0.18), {
			Color = color:Lerp(Color3.new(0, 0, 0), 0.15),
			CanCollide = false,
		})
	end
	return body
end

local function saguaro(model, rng, color)
	local body = ribbed(model, ORIGIN, 5.5, 2, color)
	for _, side in ipairs({ -1, 1 }) do
		local y = if side < 0 then 2.4 else 3.3
		local elbow = Vector3.new(side * 1.9, y, 0)
		Build.limb(model, Vector3.new(0, y, 0), elbow, 1.3, { Color = color })
		Build.ball(model, elbow, 1.3, { Color = color })
		ribbed(model, elbow, rng:NextNumber(1.8, 2.6), 1.3, color)
	end
	Build.ball(model, Vector3.new(0, 6.4, 0), 0.9, { Color = Color3.fromRGB(255, 110, 170) })
	return body, Vector3.new(0, 3.6, -1)
end

local function barrel(model, rng, color)
	local body = Build.ball(model, Vector3.new(0, 1.7, 0), 3.6, { Color = color })
	for k = 0, 7 do
		local a = k / 8 * math.pi * 2
		Build.part(model, {
			Size = Vector3.new(0.2, 3, 0.2),
			CFrame = CFrame.new(math.cos(a) * 1.7, 1.7, math.sin(a) * 1.7) * CFrame.Angles(0, -a, 0),
			Color = color:Lerp(Color3.new(0, 0, 0), 0.15),
			CanCollide = false,
		})
	end
	for k = 0, 4 do
		local a = k / 5 * math.pi * 2
		Build.ball(model, Vector3.new(math.cos(a) * 0.6, 3.4, math.sin(a) * 0.6), 0.6, { Color = pick(rng, { Color3.fromRGB(255, 205, 50), Color3.fromRGB(255, 110, 170) }) })
	end
	return body, Vector3.new(0, 1.8, -1.75)
end

local function pricklyPear(model, rng, color)
	local function paddle(center, yaw, tilt, size)
		Build.part(model, {
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.5, size, size),
			CFrame = CFrame.new(center) * CFrame.Angles(0, yaw, 0) * CFrame.Angles(0, 0, math.rad(tilt)),
			Color = Build.vary(rng, color, 0.03),
		})
		Build.ball(model, center + Vector3.new(0, size / 2, 0), 0.6, { Color = Color3.fromRGB(255, 80, 120) })
	end
	-- the main paddle faces forward so the face sits on it
	local body = Build.part(model, {
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.6, 3.2, 3.2),
		CFrame = CFrame.new(0, 1.6, 0) * CFrame.Angles(0, math.rad(90), 0),
		Color = color,
	})
	paddle(Vector3.new(1, 3.4, 0), 1.9, -20, 2.4)
	paddle(Vector3.new(-1, 3.2, 0.2), 1.2, 25, 2.2)
	paddle(Vector3.new(0, 4.6, 0.1), 2.9, 5, 2)
	return body, Vector3.new(0, 1.7, -0.35)
end

local function cactus(parent, rng)
	local model = Build.model(parent, "Cactus")
	local kind = pick(rng, { saguaro, barrel, pricklyPear })
	local body, faceAt = kind(model, rng, Build.vary(rng, CACTUS, 0.04))
	Build.face(model, CFrame.new(faceAt), 0.85)
	return model, body
end

-- World 3: ice cubes (clear, with a fish, with a gem, a stack) -------------------------------

local ICE = Color3.fromRGB(150, 225, 255)
local SNOW = Color3.fromRGB(248, 252, 255)

local function cube(model, rng, center, size)
	local cf = CFrame.new(center)
	local body = Build.part(model, {
		Size = Vector3.one * size,
		CFrame = cf,
		Color = Build.vary(rng, ICE, 0.04),
		Material = Enum.Material.Glass,
		Transparency = 0.25,
		Reflectance = 0.05,
	})
	for _, c in ipairs({ { 1, 1 }, { 1, -1 }, { -1, 1 }, { -1, -1 } }) do
		Build.part(model, {
			Size = Vector3.new(0.25, size, 0.25),
			CFrame = cf * CFrame.new(c[1] * size / 2, 0, c[2] * size / 2),
			Color = Color3.fromRGB(225, 248, 255),
			Material = Enum.Material.Glass,
			Transparency = 0.05,
			CanCollide = false,
		})
	end
	Build.part(model, { Size = Vector3.new(size * 0.85, 0.3, size * 0.85), CFrame = cf * CFrame.new(0, size / 2 + 0.1, 0), Color = SNOW, CanCollide = false })
	Build.part(model, { Size = Vector3.new(0.2, size * 0.6, 0.2), CFrame = cf * CFrame.new(size * 0.3, size * 0.05, -size / 2 - 0.02), Color = Color3.new(1, 1, 1), Material = Enum.Material.Neon, CanCollide = false })
	return body, cf
end

local function iceCube(parent, rng)
	local model = Build.model(parent, "Ice Cube")
	local kind = rng:NextInteger(1, 4)
	local body, cf
	if kind == 4 then
		body, cf = cube(model, rng, Vector3.new(0, 1.8, 0), 3.6)
		cube(model, rng, Vector3.new(0.3, 4.5, 0.2), 2)
	else
		body, cf = cube(model, rng, Vector3.new(0, 2, 0), 4)
		if kind == 2 then
			local fish = pick(rng, { Color3.fromRGB(255, 150, 40), Color3.fromRGB(255, 120, 170), Color3.fromRGB(110, 200, 255) })
			local turned = cf * CFrame.Angles(0, math.rad(30), 0)
			Build.part(model, { Size = Vector3.new(0.8, 1, 2), CFrame = turned, Color = fish, CanCollide = false })
			Build.part(model, { Size = Vector3.new(0.2, 0.9, 0.7), CFrame = turned * CFrame.new(0, 0, 1.2), Color = fish, CanCollide = false })
		elseif kind == 3 then
			local gem = pick(rng, { Color3.fromRGB(255, 90, 170), Color3.fromRGB(170, 110, 255), Color3.fromRGB(80, 230, 170) })
			Build.part(model, { Size = Vector3.new(1.2, 1.2, 1.2), CFrame = cf * CFrame.Angles(math.rad(45), 0, math.rad(45)), Color = gem, Material = Enum.Material.Neon, CanCollide = false })
		end
	end
	local size = body.Size.X
	Build.face(model, CFrame.new(body.Position + Vector3.new(0, 0.1 * size, -size / 2 - 0.05)), size / 4)
	return model, body
end

-- World 4: sushi (salmon, tuna, egg, maki), each with a happy face ------------------------------

local function nigiri(model, rng, topping, stripes)
	local rice = Build.part(model, { Name = "Rice", Size = Vector3.new(5.4, 2.4, 3.2), CFrame = CFrame.new(0, 1.2, 0), Color = Color3.fromRGB(252, 252, 248) })
	for _ = 1, 8 do
		Build.ball(model, Vector3.new(rng:NextNumber(-2.6, 2.6), rng:NextNumber(0.4, 2.2), -1.62), 0.35, { Color = Color3.fromRGB(245, 245, 238), CanCollide = false })
	end
	local fish = Build.part(model, { Size = Vector3.new(6, 1, 3.6), CFrame = CFrame.new(0, 2.8, 0), Color = topping })
	if stripes then
		for k = -2, 2 do
			Build.part(model, {
				Size = Vector3.new(0.25, 1.02, 3.62),
				CFrame = fish.CFrame * CFrame.new(k * 1.1, 0, 0) * CFrame.Angles(0, math.rad(15), 0),
				Color = topping:Lerp(Color3.new(1, 1, 1), 0.55),
				CanCollide = false,
			})
		end
	end
	Build.face(model, CFrame.new(0, 1.3, -1.7), 1.1)
	return rice
end

local function sushi(parent, rng)
	local model = Build.model(parent, "Sushi")
	local kind = rng:NextInteger(1, 4)
	local body
	if kind == 1 then
		body = nigiri(model, rng, Color3.fromRGB(255, 130, 80), true) -- salmon
	elseif kind == 2 then
		body = nigiri(model, rng, Color3.fromRGB(235, 70, 90), false) -- tuna
	elseif kind == 3 then
		body = nigiri(model, rng, Color3.fromRGB(255, 215, 70), false) -- egg, with a nori belt
		Build.part(model, { Size = Vector3.new(1.3, 3.6, 3.8), CFrame = CFrame.new(0, 1.9, 0), Color = Color3.fromRGB(45, 80, 60), CanCollide = false })
	else
		body = Build.part(model, {
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(3.4, 5, 5),
			CFrame = CFrame.new(0, 1.7, 0) * CFrame.Angles(0, 0, math.rad(90)), -- a maki roll standing on its end
			Color = Color3.fromRGB(45, 80, 60),
		})
		Build.part(model, { Shape = Enum.PartType.Cylinder, Size = Vector3.new(3.45, 4.1, 4.1), CFrame = body.CFrame, Color = Color3.fromRGB(252, 252, 248) })
		Build.part(model, { Shape = Enum.PartType.Cylinder, Size = Vector3.new(3.5, 1.6, 1.6), CFrame = body.CFrame, Color = pick(rng, { Color3.fromRGB(110, 210, 90), Color3.fromRGB(255, 120, 80) }) })
		Build.face(model, CFrame.new(0, 1.7, -2.55), 1)
	end
	return model, body
end

-- World 5: the boss, the Magma Titan -------------------------------------------------------
-- A big friendly giant of warm dark rock with glowing lava cracks, a crown
-- of rocky horns, little lava drips and a smile. About 14 studs tall.

local ROCK = Color3.fromRGB(110, 86, 80)
local ROCK_LIGHT = Color3.fromRGB(140, 112, 100)
local LAVA = Color3.fromRGB(255, 130, 40)

local function magmaTitan(parent, rng)
	local model = Build.model(parent, "Magma Titan")
	local function block(size, at, rot, color)
		return Build.part(model, { Size = size, CFrame = CFrame.new(at) * (rot or CFrame.new()), Color = color or Build.vary(rng, ROCK, 0.03) })
	end
	local function crack(at, size, rot)
		return Build.part(model, { Size = size, CFrame = CFrame.new(at) * (rot or CFrame.new()), Color = LAVA, Material = Enum.Material.Neon, CanCollide = false })
	end
	-- legs and big feet
	for _, side in ipairs({ -1, 1 }) do
		block(Vector3.new(3.2, 1.6, 4), Vector3.new(side * 2.2, 0.8, -0.3))
		block(Vector3.new(2.6, 3.4, 2.6), Vector3.new(side * 2.2, 3.2, 0), CFrame.Angles(0, math.rad(side * 6), 0))
		crack(Vector3.new(side * 2.2, 3.4, -1.32), Vector3.new(0.3, 1.8, 0.1), CFrame.Angles(0, 0, math.rad(side * 20)))
	end
	-- a big round body
	local body = block(Vector3.new(8, 6.4, 5.4), Vector3.new(0, 7.8, 0))
	block(Vector3.new(8.4, 1.4, 5.8), Vector3.new(0, 5.2, 0), nil, ROCK_LIGHT) -- belt
	-- glowing cracks on the chest and a lava heart
	crack(Vector3.new(-1.8, 8.8, -2.72), Vector3.new(0.35, 2.4, 0.1), CFrame.Angles(0, 0, math.rad(25)))
	crack(Vector3.new(2, 7.4, -2.72), Vector3.new(0.35, 2, 0.1), CFrame.Angles(0, 0, math.rad(-30)))
	crack(Vector3.new(0.4, 6.6, -2.72), Vector3.new(1.4, 0.3, 0.1))
	Build.ball(model, Vector3.new(0, 8, -2.6), 1.4, { Color = LAVA, Material = Enum.Material.Neon, CanCollide = false })
	-- shoulders, long arms and fists
	for _, side in ipairs({ -1, 1 }) do
		block(Vector3.new(3, 2.6, 3), Vector3.new(side * 5.2, 10, 0), CFrame.Angles(0, 0, math.rad(side * -10)), ROCK_LIGHT)
		block(Vector3.new(2.2, 4.6, 2.2), Vector3.new(side * 5.6, 6.8, -0.2), CFrame.Angles(math.rad(-8), 0, math.rad(side * 6)))
		block(Vector3.new(3, 2.6, 3), Vector3.new(side * 5.8, 3.8, -0.6), nil, ROCK_LIGHT)
		crack(Vector3.new(side * 5.8, 3.8, -2.12), Vector3.new(1.6, 0.25, 0.1))
	end
	-- the head with a smile, and a crown of rocky horns with lava tips
	local head = block(Vector3.new(4.6, 3.6, 4), Vector3.new(0, 12.6, -0.4), nil, ROCK_LIGHT)
	for k = -1, 1 do
		local tip = Vector3.new(k * 1.5, 15.1 + (if k == 0 then 0.6 else 0), -0.4)
		block(Vector3.new(0.9, 1.6, 0.9), tip - Vector3.new(0, 0.6, 0), CFrame.Angles(0, math.rad(45), math.rad(k * -15)))
		Build.ball(model, tip + Vector3.new(0, 0.4, 0), 0.6, { Color = LAVA, Material = Enum.Material.Neon, CanCollide = false })
	end
	Build.face(model, CFrame.new(head.Position + Vector3.new(0, -0.2, -2.05)), 2.2)
	-- a warm glow and little embers drifting up
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 150, 80)
	light.Range = 18
	light.Brightness = 1.2
	light.Parent = body
	local embers = Instance.new("ParticleEmitter")
	embers.Color = ColorSequence.new(Color3.fromRGB(255, 190, 90), Color3.fromRGB(255, 100, 40))
	embers.LightEmission = 1
	embers.Size = NumberSequence.new(0.3, 0)
	embers.Lifetime = NumberRange.new(1, 2)
	embers.Speed = NumberRange.new(1.5, 3)
	embers.SpreadAngle = Vector2.new(40, 40)
	embers.Rate = 5
	embers.Parent = body
	return model, body
end

local BUILDERS = { tree, cactus, iceCube, sushi, magmaTitan }

-- Builds world `area`'s living coin into `parent`, with its feet at the
-- origin; the same seed always gives the same look
function Coins.build(area, parent, seed)
	local rng = Random.new(seed)
	local model, body = BUILDERS[area](parent, rng)
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") then
			p.Anchored = true
			p.CanCollide = false -- players and pets walk through them
			p.CanTouch = false
		end
	end
	Build.setPivot(model, body, CFrame.new()) -- the pivot is the feet
	return model
end

return Coins
