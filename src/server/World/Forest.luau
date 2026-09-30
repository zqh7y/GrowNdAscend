-- Area 1: Forest. A sunny meadow with a dirt path, four kinds of tall
-- detailed trees, flower patches, berry bushes, mushrooms, mossy rocks,
-- fallen logs, a fountain on each side, hills with a cottage and a windmill
-- behind them, and the three leaderboards side by side. The green terrain is
-- the grass (no separate grass pieces). Breakable: small trees.
local Build = require(script.Parent.Build)

local Forest = {}

Forest.GROUND = Enum.Material.Grass

local BARK = Color3.fromRGB(160, 100, 60)
local LEAF_GREENS = {
	Color3.fromRGB(95, 200, 75),
	Color3.fromRGB(125, 210, 70),
	Color3.fromRGB(70, 185, 95),
}
local STONE = Color3.fromRGB(200, 205, 220)
local MOSS = Color3.fromRGB(110, 195, 80)
local WHITE = Color3.fromRGB(250, 250, 255)

-- the three leaderboard ids, left to right
Forest.BOARDS = {
	{ Id = "Strongest", Color = Color3.fromRGB(255, 110, 90) },
	{ Id = "Playtime", Color = Color3.fromRGB(60, 185, 255) },
	{ Id = "Rebirths", Color = Color3.fromRGB(170, 110, 255) },
}

local function pick(rng, list)
	return list[rng:NextInteger(1, #list)]
end

local function ghostAll(model)
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") then
			Build.ghost(p)
		end
	end
	return model
end

-- Trees ---------------------------------------------------------------------------

-- trunk in two slightly bent pieces, with a knot, root flares and a joint ball
local function trunk(model, rng, base, height, width, color)
	local lean = Vector3.new(rng:NextNumber(-0.6, 0.6), 0, rng:NextNumber(-0.6, 0.6))
	local mid = base + Vector3.new(0, height * 0.55, 0) + lean
	local top = mid + Vector3.new(0, height * 0.45, 0) + lean * 0.6
	Build.limb(model, base - Vector3.new(0, 0.5, 0), mid, width, { Color = color })
	Build.ball(model, mid, width * 0.92, { Color = color })
	Build.limb(model, mid, top, width * 0.72, { Color = color })
	-- roots spreading into the ground
	for k = 1, 4 do
		local a = k / 4 * math.pi * 2 + rng:NextNumber(-0.3, 0.3)
		local dir = Vector3.new(math.cos(a), 0, math.sin(a))
		Build.limb(model, base + dir * width * 0.2 + Vector3.new(0, width * 0.55, 0), base + dir * width * 1.1 - Vector3.new(0, 0.15, 0), width * 0.38, { Color = color })
	end
	-- a knot
	local knotAngle = rng:NextNumber(0, math.pi * 2)
	Build.ball(model, base + Vector3.new(math.cos(knotAngle) * width * 0.45, height * 0.3, math.sin(knotAngle) * width * 0.45), width * 0.35, {
		Color = color:Lerp(Color3.new(0, 0, 0), 0.2),
	})
	return mid, top
end

-- a branch from `from` reaching out and up, ending in a leaf cluster
local function branch(model, rng, from, length, width, color, leafColor, leafSize)
	local a = rng:NextNumber(0, math.pi * 2)
	local tip = from + Vector3.new(math.cos(a) * length, length * rng:NextNumber(0.5, 0.8), math.sin(a) * length)
	Build.limb(model, from, tip, width, { Color = color })
	Build.leafCluster(model, rng, tip, leafSize, leafColor)
	return tip
end

local function oak(parent, rng, base, s)
	local model = Build.model(parent, "Oak")
	local leaves = pick(rng, LEAF_GREENS)
	local _, top = trunk(model, rng, base, rng:NextNumber(8, 10) * s, 2 * s, BARK)
	for _ = 1, 3 do
		local from = base:Lerp(top, rng:NextNumber(0.6, 0.85))
		branch(model, rng, from, rng:NextNumber(3, 4) * s, 0.7 * s, BARK, leaves, rng:NextNumber(5, 6.5) * s)
	end
	Build.leafCluster(model, rng, top + Vector3.new(0, 2 * s, 0), 8.5 * s, leaves)
	return model
end

local function birch(parent, rng, base, s)
	local model = Build.model(parent, "Birch")
	local height = rng:NextNumber(12, 15) * s
	local top = base + Vector3.new(rng:NextNumber(-0.5, 0.5), height, rng:NextNumber(-0.5, 0.5))
	Build.limb(model, base - Vector3.new(0, 0.5, 0), top, 1.1 * s, { Color = WHITE })
	-- the dark marks birch bark has
	for _ = 1, 7 do
		local y = rng:NextNumber(0.5, 0.85) * height
		local a = rng:NextNumber(0, math.pi * 2)
		local p = base:Lerp(top, y / height)
		Build.part(model, {
			Size = Vector3.new(0.5 * s, 0.14 * s, 0.2),
			CFrame = CFrame.new(p) * CFrame.Angles(0, a, 0) * CFrame.new(0, 0, -0.5 * s),
			Color = Color3.fromRGB(80, 80, 95),
			CanCollide = false,
		})
	end
	local leaves = Color3.fromRGB(165, 220, 85)
	for k = 1, 3 do
		local p = base:Lerp(top, 0.55 + k * 0.15) + Vector3.new(rng:NextNumber(-1.5, 1.5) * s, 0, rng:NextNumber(-1.5, 1.5) * s)
		Build.limb(model, base:Lerp(top, 0.5 + k * 0.12), p, 0.4 * s, { Color = WHITE })
		Build.leafCluster(model, rng, p, rng:NextNumber(4.2, 5.2) * s, leaves)
	end
	Build.leafCluster(model, rng, top + Vector3.new(0, 1 * s, 0), 4.5 * s, leaves)
	return model
end

local function fruitTree(parent, rng, base, s)
	local model = Build.model(parent, "FruitTree")
	local leaves = Color3.fromRGB(85, 195, 70)
	local fruit = pick(rng, { Color3.fromRGB(255, 70, 70), Color3.fromRGB(255, 160, 40), Color3.fromRGB(255, 220, 60) })
	local _, top = trunk(model, rng, base, rng:NextNumber(6, 7.5) * s, 1.6 * s, BARK)
	for _ = 1, 2 do
		branch(model, rng, base:Lerp(top, 0.8), 2.5 * s, 0.55 * s, BARK, leaves, 5 * s)
	end
	local crown = top + Vector3.new(0, 2.2 * s, 0)
	local size = 8 * s
	Build.leafCluster(model, rng, crown, size, leaves)
	-- fruit dotted over the crown
	for _ = 1, 9 do
		local a = rng:NextNumber(0, math.pi * 2)
		local up = rng:NextNumber(-0.3, 0.7)
		local dir = Vector3.new(math.cos(a) * math.sqrt(1 - up * up), up, math.sin(a) * math.sqrt(1 - up * up))
		Build.ball(model, crown + dir * size * 0.5, 0.8 * s, { Color = fruit })
	end
	return model
end

local function poplar(parent, rng, base, s)
	local model = Build.model(parent, "Poplar")
	local leaves = Color3.fromRGB(60, 175, 100)
	Build.limb(model, base - Vector3.new(0, 0.5, 0), base + Vector3.new(0, 4 * s, 0), 1.2 * s, { Color = BARK })
	local y = 3.5 * s
	for _, size in ipairs({ 6, 5.6, 5, 4.2, 3.2 }) do
		Build.leafCluster(model, rng, base + Vector3.new(rng:NextNumber(-0.3, 0.3), y + size * s * 0.4, rng:NextNumber(-0.3, 0.3)), size * s, leaves)
		y += size * s * 0.62
	end
	return model
end

local TREES = { oak, oak, birch, fruitTree, poplar }

local function randomTree(parent, rng, base, s)
	return pick(rng, TREES)(parent, rng, base, s)
end

-- Flowers, bushes, mushrooms, logs -------------------------------------------------------

local PETAL_COLORS = {
	Color3.fromRGB(255, 110, 170),
	Color3.fromRGB(255, 255, 255),
	Color3.fromRGB(175, 120, 255),
	Color3.fromRGB(255, 140, 70),
	Color3.fromRGB(255, 80, 90),
	Color3.fromRGB(255, 215, 60),
}
local STEM = Color3.fromRGB(70, 170, 60)

local function stem(model, rng, base, height)
	Build.block(model, base, Vector3.new(0.14, height, 0.14), { Color = STEM })
	for _, side in ipairs({ -1, 1 }) do
		Build.part(model, {
			Size = Vector3.new(0.08, 0.12, 0.55),
			CFrame = CFrame.new(base + Vector3.new(0, height * 0.3, 0)) * CFrame.Angles(0, math.rad(rng:NextNumber(0, 180)), 0)
				* CFrame.Angles(math.rad(side * 35), 0, 0) * CFrame.new(0, 0, side * 0.25),
			Color = STEM:Lerp(Color3.new(1, 1, 1), 0.1),
		})
	end
	return base + Vector3.new(0, height, 0)
end

local function daisy(model, rng, base, color)
	local head = stem(model, rng, base, rng:NextNumber(0.8, 1.2))
	for k = 0, 5 do
		Build.part(model, {
			Size = Vector3.new(0.16, 0.06, 0.42),
			CFrame = CFrame.new(head) * CFrame.Angles(0, k / 6 * math.pi * 2, 0) * CFrame.new(0, 0, -0.26) * CFrame.Angles(math.rad(12), 0, 0),
			Color = color,
		})
	end
	Build.ball(model, head + Vector3.new(0, 0.04, 0), 0.26, { Color = Color3.fromRGB(255, 200, 40) })
end

local function tulip(model, rng, base, color)
	local head = stem(model, rng, base, rng:NextNumber(1, 1.4))
	for k = 0, 2 do
		Build.part(model, {
			Size = Vector3.new(0.3, 0.55, 0.1),
			CFrame = CFrame.new(head) * CFrame.Angles(0, k / 3 * math.pi * 2, 0) * CFrame.new(0, 0.2, -0.13) * CFrame.Angles(math.rad(-12), 0, 0),
			Color = color,
		})
	end
	Build.ball(model, head + Vector3.new(0, 0.1, 0), 0.3, { Color = color:Lerp(Color3.new(1, 1, 1), 0.2) })
end

local function bluebell(model, rng, base)
	local top = stem(model, rng, base, rng:NextNumber(1, 1.3))
	for k = 0, 2 do
		Build.ball(model, top - Vector3.new(0, k * 0.28, 0) + Vector3.new(0.18 * (k % 2 == 0 and 1 or -1), 0, 0), 0.26, {
			Color = Color3.fromRGB(110, 150, 255),
		})
	end
end

local function sunflower(model, rng, base)
	local head = stem(model, rng, base, rng:NextNumber(2, 2.6))
	local face = CFrame.new(head) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0) * CFrame.Angles(math.rad(70), 0, 0)
	for k = 0, 7 do
		Build.part(model, {
			Size = Vector3.new(0.26, 0.06, 0.5),
			CFrame = face * CFrame.Angles(0, k / 8 * math.pi * 2, 0) * CFrame.new(0, 0, -0.45),
			Color = Color3.fromRGB(255, 205, 40),
		})
	end
	Build.part(model, {
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.16, 0.6, 0.6),
		CFrame = face * CFrame.Angles(0, 0, math.rad(90)) * CFrame.new(0.05, 0, 0),
		Color = Color3.fromRGB(150, 90, 40),
	})
end

-- a patch of 6-9 flowers of one or two kinds
local function flowerPatch(parent, rng, center)
	local model = Build.model(parent, "FlowerPatch")
	local kinds = { daisy, tulip, bluebell, sunflower }
	local a, b = pick(rng, kinds), pick(rng, kinds)
	local colorA, colorB = pick(rng, PETAL_COLORS), pick(rng, PETAL_COLORS)
	for k = 1, rng:NextInteger(5, 7) do
		local p = center + Vector3.new(rng:NextNumber(-2, 2), 0, rng:NextNumber(-2, 2))
		local kind, color = if k % 3 == 0 then b else a, if k % 3 == 0 then colorB else colorA
		kind(model, rng, p, color)
	end
	return ghostAll(model)
end

local function bush(parent, rng, base, s)
	local model = Build.model(parent, "Bush")
	local green = pick(rng, LEAF_GREENS)
	Build.leafCluster(model, rng, base + Vector3.new(0, 1.1 * s, 0), 3.2 * s, green)
	Build.leafCluster(model, rng, base + Vector3.new(1.2 * s, 0.8 * s, 0.4 * s), 2.4 * s, green)
	-- berries or little flowers dotted on the outside
	local dot = pick(rng, { Color3.fromRGB(255, 60, 90), Color3.fromRGB(90, 110, 255), Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 150, 200) })
	for _ = 1, 8 do
		local a = rng:NextNumber(0, math.pi * 2)
		local up = rng:NextNumber(0, 0.8)
		Build.ball(model, base + Vector3.new(0, 1.1 * s, 0) + Vector3.new(math.cos(a), up, math.sin(a)).Unit * 1.6 * s, 0.38 * s, { Color = dot })
	end
	return model
end

local function mushroom(parent, rng, base, s)
	local model = Build.model(parent, "Mushroom")
	local cap = pick(rng, { Color3.fromRGB(255, 70, 70), Color3.fromRGB(255, 140, 60), Color3.fromRGB(190, 110, 255) })
	Build.cylinder(model, base, 0.8 * s, 0.5 * s, { Color = Color3.fromRGB(250, 245, 230) })
	Build.cylinder(model, base + Vector3.new(0, 0.75 * s, 0), 0.25 * s, 1.5 * s, { Color = cap })
	Build.ball(model, base + Vector3.new(0, 0.85 * s, 0), 1.3 * s, { Color = cap })
	for k = 0, 4 do
		local a = k / 5 * math.pi * 2
		Build.ball(model, base + Vector3.new(math.cos(a) * 0.45 * s, 1.25 * s, math.sin(a) * 0.45 * s), 0.3 * s, { Color = WHITE })
	end
	Build.ball(model, base + Vector3.new(0, 1.5 * s, 0), 0.32 * s, { Color = WHITE })
	return ghostAll(model)
end

local function mushroomRing(parent, rng, center)
	for _ = 1, rng:NextInteger(2, 4) do
		mushroom(parent, rng, center + Vector3.new(rng:NextNumber(-1.4, 1.4), 0, rng:NextNumber(-1.4, 1.4)), rng:NextNumber(0.6, 1.1))
	end
end

local function log(parent, rng, center)
	local model = Build.model(parent, "Log")
	local yaw = rng:NextNumber(0, math.pi)
	local dir = Vector3.new(math.cos(yaw), 0, math.sin(yaw))
	local a, b = center - dir * 3 + Vector3.new(0, 0.7, 0), center + dir * 3 + Vector3.new(0, 0.7, 0)
	Build.limb(model, a, b, 1.5, { Color = BARK })
	-- light cut ends with rings
	for _, p in ipairs({ a, b }) do
		local out = (p - center).Unit
		Build.limb(model, p, p + out * 0.08, 1.4, { Color = Color3.fromRGB(240, 200, 145) })
		Build.limb(model, p + out * 0.05, p + out * 0.1, 0.8, { Color = Color3.fromRGB(215, 165, 110) })
	end
	-- moss and a little mushroom on top
	Build.ball(model, center + Vector3.new(0, 1.35, 0) + dir * 0.8, 0.9, { Color = MOSS })
	Build.ball(model, center + Vector3.new(0, 1.3, 0) - dir * 1.4, 0.7, { Color = MOSS })
	mushroom(model, rng, center + Vector3.new(0, 1.3, 0) - dir * 0.3, 0.55)
	-- a branch stub
	Build.limb(model, center + Vector3.new(0, 0.9, 0) + dir * 1.5, center + Vector3.new(0, 2, 0) + dir * 2 + Vector3.new(0.3, 0, 0.3), 0.4, { Color = BARK })
	return model
end

-- Fountain ------------------------------------------------------------------------------

local function fountain(parent, rng, center)
	local model = Build.model(parent, "Fountain")
	local cream = Color3.fromRGB(250, 245, 235)
	local trim = Color3.fromRGB(110, 195, 255)
	local water = { Color = Color3.fromRGB(80, 195, 255), Material = Enum.Material.Glass, Transparency = 0.3, CanCollide = false }

	-- paved circle around it
	Build.cylinder(model, center - Vector3.new(0, 0.05, 0), 0.2, 17, { Color = Color3.fromRGB(235, 225, 210) })
	Build.cylinder(model, center - Vector3.new(0, 0.04, 0), 0.22, 15.4, { Color = Color3.fromRGB(245, 238, 225) })

	-- eight-sided basin: wall pieces with caps and balls on the corners
	local R = 6
	for k = 0, 7 do
		local a = k / 8 * math.pi * 2
		local side = CFrame.new(center + Vector3.new(math.cos(a) * R, 0, math.sin(a) * R)) * CFrame.Angles(0, -a + math.pi / 2, 0)
		Build.part(model, { Size = Vector3.new(5, 1.6, 0.9), CFrame = side * CFrame.new(0, 0.8, 0), Color = cream })
		Build.part(model, { Size = Vector3.new(5.2, 0.35, 1.3), CFrame = side * CFrame.new(0, 1.75, 0), Color = trim })
		local corner = center + Vector3.new(math.cos(a + math.pi / 8) * (R + 0.2), 0, math.sin(a + math.pi / 8) * (R + 0.2))
		Build.cylinder(model, corner, 2.2, 0.9, { Color = cream })
		Build.ball(model, corner + Vector3.new(0, 2.5, 0), 0.8, { Color = trim })
	end
	Build.cylinder(model, center, 1.3, R * 2, water)
	-- lily pads with flowers
	for _ = 1, 4 do
		local a, r = rng:NextNumber(0, math.pi * 2), rng:NextNumber(2.5, 4.5)
		local p = center + Vector3.new(math.cos(a) * r, 1.32, math.sin(a) * r)
		Build.ghost(Build.cylinder(model, p, 0.08, 1.4, { Color = Color3.fromRGB(80, 190, 90) }))
		Build.ghost(Build.ball(model, p + Vector3.new(0.2, 0.15, 0), 0.35, { Color = Color3.fromRGB(255, 150, 200) }))
	end

	-- column with fluting, bowls with scalloped rims, a finial on top
	Build.cylinder(model, center, 4.2, 1.8, { Color = cream })
	for k = 0, 5 do
		local a = k / 6 * math.pi * 2
		Build.block(model, center + Vector3.new(math.cos(a) * 0.85, 0.4, math.sin(a) * 0.85), Vector3.new(0.25, 3.4, 0.25), { Color = trim })
	end
	local function bowl(y, diameter)
		local base = center + Vector3.new(0, y, 0)
		Build.cylinder(model, base - Vector3.new(0, 0.5, 0), 0.5, diameter * 0.6, { Color = cream })
		Build.cylinder(model, base, 0.8, diameter, { Color = cream })
		Build.cylinder(model, base + Vector3.new(0, 0.5, 0), 0.35, diameter - 0.8, water)
		local balls = math.floor(diameter * 1.6)
		for k = 0, balls - 1 do
			local a = k / balls * math.pi * 2
			Build.ball(model, base + Vector3.new(math.cos(a) * diameter / 2, 0.8, math.sin(a) * diameter / 2), 0.42, { Color = trim })
		end
		-- four streams falling from the rim
		for k = 0, 3 do
			local a = k / 4 * math.pi * 2 + math.pi / 4
			local lip = base + Vector3.new(math.cos(a) * (diameter / 2 + 0.2), 0.5, math.sin(a) * (diameter / 2 + 0.2))
			Build.limb(model, lip, Vector3.new(lip.X, center.Y + 1.3, lip.Z), 0.3, water)
		end
		return base
	end
	bowl(4.2, 6)
	Build.cylinder(model, center + Vector3.new(0, 5, 0), 2.4, 1, { Color = cream })
	bowl(7.4, 3.4)
	Build.cylinder(model, center + Vector3.new(0, 8.2, 0), 1, 0.6, { Color = cream })
	local finial = Build.ball(model, center + Vector3.new(0, 9.5, 0), 1, { Color = trim })

	local spray = Instance.new("ParticleEmitter")
	spray.Color = ColorSequence.new(Color3.fromRGB(190, 235, 255))
	spray.Transparency = NumberSequence.new(0.1, 1)
	spray.Size = NumberSequence.new(0.28, 0.1)
	spray.Rate = 45
	spray.Lifetime = NumberRange.new(0.8, 1)
	spray.Speed = NumberRange.new(6, 8)
	spray.SpreadAngle = Vector2.new(18, 18)
	spray.Acceleration = Vector3.new(0, -22, 0)
	spray.EmissionDirection = Enum.NormalId.Top
	spray.Parent = finial
	local sparkle = Instance.new("ParticleEmitter")
	sparkle.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparkle.Color = ColorSequence.new(Color3.new(1, 1, 1))
	sparkle.Size = NumberSequence.new(0.3, 0)
	sparkle.Rate = 5
	sparkle.Lifetime = NumberRange.new(0.6, 1)
	sparkle.Speed = NumberRange.new(0.5)
	sparkle.SpreadAngle = Vector2.new(180, 180)
	sparkle.Parent = finial
	return model
end

-- Background buildings ---------------------------------------------------------------------

local function cottage(parent, base, facingZ)
	local model = Build.model(parent, "Cottage")
	local frame = CFrame.lookAt(base, base + Vector3.new(0, 0, facingZ))
	local wall = Color3.fromRGB(255, 245, 225)
	local beam = Color3.fromRGB(170, 110, 70)
	local roof = Color3.fromRGB(240, 90, 80)
	local function at(x, y, z)
		return frame * CFrame.new(x, y, z)
	end
	Build.part(model, { Size = Vector3.new(12, 1, 9), CFrame = at(0, 0.5, 0), Color = Color3.fromRGB(190, 190, 205) }) -- foundation
	Build.part(model, { Size = Vector3.new(11, 7, 8), CFrame = at(0, 4.5, 0), Color = wall })
	-- timber frame
	for _, x in ipairs({ -5.5, -1.8, 1.8, 5.5 }) do
		Build.part(model, { Size = Vector3.new(0.5, 7, 0.3), CFrame = at(x, 4.5, -4.05), Color = beam })
	end
	Build.part(model, { Size = Vector3.new(11.2, 0.5, 0.3), CFrame = at(0, 7.9, -4.05), Color = beam })
	Build.part(model, { Size = Vector3.new(11.2, 0.5, 0.3), CFrame = at(0, 1.2, -4.05), Color = beam })
	-- gable roof: two slopes and a ridge, with overhang
	for _, side in ipairs({ -1, 1 }) do
		Build.part(model, {
			Size = Vector3.new(13, 0.6, 6.4),
			CFrame = at(0, 10, side * 2.4) * CFrame.Angles(math.rad(side * 35), 0, 0),
			Color = roof,
		})
		-- triangle gable ends
		Build.wedge(model, at(side * 5.3, 9.5, -2) * CFrame.Angles(0, math.rad(180), 0), Vector3.new(0.4, 3, 4), { Color = wall })
		Build.wedge(model, at(side * 5.3, 9.5, 2), Vector3.new(0.4, 3, 4), { Color = wall })
	end
	Build.part(model, { Size = Vector3.new(13.2, 0.7, 0.7), CFrame = at(0, 11.95, 0), Color = roof:Lerp(Color3.new(0, 0, 0), 0.15) })
	-- door, windows with flower boxes, chimney with smoke
	Build.part(model, { Size = Vector3.new(2.4, 4, 0.3), CFrame = at(0, 3, -4.1), Color = Color3.fromRGB(90, 160, 255) })
	Build.ball(model, (at(0.8, 3, -4.3)).Position, 0.3, { Color = Color3.fromRGB(255, 205, 50) })
	for _, x in ipairs({ -3.6, 3.6 }) do
		Build.part(model, { Size = Vector3.new(2.2, 2, 0.2), CFrame = at(x, 4.6, -4.1), Color = Color3.fromRGB(170, 225, 255), Material = Enum.Material.Glass, Transparency = 0.1 })
		Build.part(model, { Size = Vector3.new(2.6, 0.3, 0.35), CFrame = at(x, 5.7, -4.15), Color = WHITE })
		Build.part(model, { Size = Vector3.new(0.2, 2, 0.3), CFrame = at(x, 4.6, -4.15), Color = WHITE })
		Build.part(model, { Size = Vector3.new(2.6, 0.6, 0.8), CFrame = at(x, 3.3, -4.4), Color = beam })
		for k = -1, 1 do
			Build.ball(model, (at(x + k * 0.7, 3.8, -4.4)).Position, 0.5, { Color = pick(Random.new(k + 5), PETAL_COLORS) })
		end
	end
	local chimney = Build.part(model, { Size = Vector3.new(1.6, 4, 1.6), CFrame = at(3.5, 11.5, 1.5), Color = Color3.fromRGB(230, 120, 100) })
	local smoke = Instance.new("ParticleEmitter")
	smoke.Color = ColorSequence.new(Color3.new(1, 1, 1))
	smoke.Transparency = NumberSequence.new(0.3, 1)
	smoke.Size = NumberSequence.new(0.8, 2.4)
	smoke.Rate = 3
	smoke.Lifetime = NumberRange.new(3, 4)
	smoke.Speed = NumberRange.new(1.5, 2.5)
	smoke.SpreadAngle = Vector2.new(10, 10)
	smoke.EmissionDirection = Enum.NormalId.Top
	smoke.Parent = chimney
	return model
end

local function windmill(parent, base, facingZ)
	local model = Build.model(parent, "Windmill")
	local white = Color3.fromRGB(252, 250, 245)
	local red = Color3.fromRGB(240, 90, 80)
	-- tapered tower in three sections with red bands
	local y = 0
	for k, d in ipairs({ 9, 7.6, 6.2 }) do
		Build.cylinder(model, base + Vector3.new(0, y, 0), 6, d, { Color = white })
		Build.cylinder(model, base + Vector3.new(0, y + 5.6, 0), 0.6, d + 0.3, { Color = red })
		if k == 1 then
			Build.block(model, base + Vector3.new(0, 0, facingZ * (d / 2 - 0.2)), Vector3.new(2.4, 3.8, 0.4), { Color = Color3.fromRGB(90, 160, 255) })
		end
		y += 6
	end
	Build.ball(model, base + Vector3.new(0, y + 0.8, 0), 6.8, { Color = red })
	-- the sails spin around the hub, facing the path
	local hub = CFrame.lookAt(base + Vector3.new(0, y + 0.5, facingZ * 3.6), base + Vector3.new(0, y + 0.5, facingZ * 10))
	Build.part(model, { Shape = Enum.PartType.Ball, Size = Vector3.one * 1.6, CFrame = hub, Color = Color3.fromRGB(255, 205, 50) })
	for k = 0, 1 do
		local sail = Build.part(model, {
			Size = Vector3.new(2.2, 20, 0.25),
			CFrame = hub * CFrame.new(0, 0, -0.4) * CFrame.Angles(0, 0, math.rad(k * 90)),
			Color = Color3.fromRGB(255, 240, 210),
			CanCollide = false,
		})
		Build.spin(sail, 40, "Z")
	end
	return model
end

-- Leaderboards -------------------------------------------------------------------------------

-- The three leaderboards next to each other on one stage, facing the path.
-- Fills World.Boards with each board's screen part.
local function leaderboardStage(parent, world, center)
	local model = Build.model(parent, "Leaderboards")
	local facing = CFrame.lookAt(center, Vector3.new(center.X, center.Y, 0)) -- screens face the middle
	local WIDTH, GAP = 11, 1.2
	local total = #Forest.BOARDS * WIDTH + (#Forest.BOARDS - 1) * GAP

	-- stage with steps and a colourful trim
	Build.part(model, { Size = Vector3.new(total + 4, 1, 6), CFrame = facing * CFrame.new(0, 0.5, 0), Color = WHITE })
	Build.part(model, { Size = Vector3.new(total + 4.2, 0.3, 6.2), CFrame = facing * CFrame.new(0, 1.05, 0), Color = Color3.fromRGB(255, 205, 60) })
	Build.part(model, { Size = Vector3.new(total, 0.5, 1.4), CFrame = facing * CFrame.new(0, 0.25, -3.6), Color = WHITE })

	for i, board in ipairs(Forest.BOARDS) do
		local x = -total / 2 + WIDTH / 2 + (i - 1) * (WIDTH + GAP)
		-- white frame, coloured cap with a light, screen
		Build.part(model, { Size = Vector3.new(WIDTH, 14.4, 0.8), CFrame = facing * CFrame.new(x, 8.4, 0.2), Color = WHITE })
		Build.part(model, { Size = Vector3.new(WIDTH, 1.2, 1.2), CFrame = facing * CFrame.new(x, 16.2, 0.2), Color = board.Color })
		Build.ball(model, (facing * CFrame.new(x, 17.2, 0.2)).Position, 1, { Color = board.Color, Material = Enum.Material.Neon })
		world.Boards[board.Id] = Build.part(model, {
			Name = "Screen_" .. board.Id,
			Size = Vector3.new(WIDTH - 1, 13.4, 0.2),
			CFrame = facing * CFrame.new(x, 8.4, -0.3),
			Color = Color3.fromRGB(255, 255, 255),
		})
	end
	-- posts holding up one shared header above all three
	for _, x in ipairs({ -total / 2 - 1, total / 2 + 1 }) do
		Build.part(model, { Size = Vector3.new(0.8, 19, 0.8), CFrame = facing * CFrame.new(x, 10, 0.2), Color = WHITE })
		Build.ball(model, (facing * CFrame.new(x, 19.8, 0.2)).Position, 1.2, { Color = Color3.fromRGB(255, 150, 60) })
	end
	Build.sign(model, facing * CFrame.new(0, 18.8, 0.2), Vector3.new(18, 2.8, 0.6), "LEADERBOARDS", Color3.new(1, 1, 1), Color3.fromRGB(255, 150, 60))
	-- flower boxes along the front
	local rng = Random.new(7)
	for _, x in ipairs({ -total / 2 + 3, 0, total / 2 - 3 }) do
		Build.part(model, { Size = Vector3.new(4, 0.8, 1), CFrame = facing * CFrame.new(x, 1.6, -2.4), Color = Color3.fromRGB(170, 110, 70) })
		for k = -1, 1 do
			Build.ball(model, (facing * CFrame.new(x + k * 1.2, 2.2, -2.4)).Position, 0.7, { Color = pick(rng, PETAL_COLORS) })
		end
	end
	return total
end

-- Building the area --------------------------------------------------------------------------------

function Forest.build(ctx)
	local folder, rng, space = ctx.Folder, ctx.Rng, ctx.Space
	local x0, x1, half = ctx.X0, ctx.X1, ctx.Half
	local deco = Build.folder(folder, "Decor")
	local terrain = ctx.Terrain

	-- lighter green patches and a winding dirt path in the terrain itself
	for _ = 1, 10 do
		local c = Vector3.new(rng:NextNumber(x0, x1), -2, rng:NextNumber(-half, half))
		terrain:ReplaceMaterial(Region3.new(c - Vector3.new(6, 2, 5), c + Vector3.new(6, 2, 5)):ExpandToGrid(4), 4, Enum.Material.Grass, Enum.Material.LeafyGrass)
	end
	for x = x0, x1 - 4, 4 do
		local z = math.sin((x - x0) / 16) * 5
		terrain:ReplaceMaterial(Region3.new(Vector3.new(x, -4, z - 4), Vector3.new(x + 4, 0, z + 4)):ExpandToGrid(4), 4, Enum.Material.Grass, Enum.Material.Ground)
		terrain:ReplaceMaterial(Region3.new(Vector3.new(x, -4, z - 4), Vector3.new(x + 4, 0, z + 4)):ExpandToGrid(4), 4, Enum.Material.LeafyGrass, Enum.Material.Ground)
		space:add(Vector3.new(x + 2, 0, z), 2.5)
	end

	-- soft round hills along both sides and behind the start
	for x = x0 - 10, x1 + 6, 14 do
		for _, side in ipairs({ -1, 1 }) do
			terrain:FillBall(Vector3.new(x + rng:NextNumber(-5, 5), rng:NextNumber(-9, -3), side * rng:NextNumber(half + 30, half + 52)), rng:NextNumber(16, 24), Enum.Material.Grass)
		end
	end
	for z = -ctx.Side, ctx.Side, 16 do
		terrain:FillBall(Vector3.new(x0 - rng:NextNumber(12, 20), rng:NextNumber(-6, 0), z), rng:NextNumber(16, 22), Enum.Material.Grass)
	end

	-- background: a cottage on the right, a windmill on the left
	cottage(deco, Vector3.new(x0 + 64, 0, half + 12), -1)
	windmill(deco, Vector3.new(x0 + 82, 0, -(half + 14)), 1)
	local outside = Build.space()
	outside:add(Vector3.new(x0 + 64, 0, half + 12), 10)
	outside:add(Vector3.new(x0 + 82, 0, -(half + 14)), 8)

	-- leaderboards: one group on the left side, near the spawn
	local stageCenter = Vector3.new(x0 + 30, 0, -(half - 5))
	local stageWidth = leaderboardStage(deco, ctx.World, stageCenter)
	for dx = -stageWidth / 2, stageWidth / 2, 6 do
		space:add(stageCenter + Vector3.new(dx, 0, 0), 5.5)
	end

	-- a fountain on each side
	for _, f in ipairs({ { X = 74, Side = -1 }, { X = 44, Side = 1 } }) do
		local center = Vector3.new(x0 + f.X, 0, f.Side * (half - 10))
		fountain(deco, rng, center)
		space:add(center, 9)
	end

	-- tall trees: a row along each side, and more beyond the walls and on the hills
	for x = x0 + 5, x1 - 5, 10 do
		for _, side in ipairs({ -1, 1 }) do
			local base = Vector3.new(x + rng:NextNumber(-2, 2), 0, side * rng:NextNumber(half - 4, half - 2))
			if space:free(base, 4) then
				randomTree(deco, rng, base, rng:NextNumber(0.95, 1.2))
				space:add(base, 4)
			end
			local far = Vector3.new(x + rng:NextNumber(-3, 3), 0, side * rng:NextNumber(half + 5, half + 24))
			if outside:free(far, 4) then
				randomTree(deco, rng, far, rng:NextNumber(1.1, 1.5))
				outside:add(far, 4)
			end
		end
	end
	for _ = 1, 3 do
		local base = space:find(rng, x0 + 14, x1 - 14, -half + 14, half - 14, 5)
		if base then
			randomTree(deco, rng, base, rng:NextNumber(1, 1.15))
		end
	end

	ctx.reserveSpots() -- breakables get their room before the small props

	-- bushes, flower patches, mushrooms, logs and mossy rocks
	for _ = 1, 8 do
		local base = space:find(rng, x0 + 4, x1 - 4, -half + 3, half - 3, 2.5)
		if base then
			bush(deco, rng, base, rng:NextNumber(0.8, 1.1))
		end
	end
	for _ = 1, 10 do
		local base = space:find(rng, x0 + 4, x1 - 4, -half + 3, half - 3, 2.5)
		if base then
			flowerPatch(deco, rng, base)
		end
	end
	for _ = 1, 5 do
		local base = space:find(rng, x0 + 4, x1 - 4, -half + 3, half - 3, 2)
		if base then
			mushroomRing(deco, rng, base)
		end
	end
	for _ = 1, 2 do
		local base = space:find(rng, x0 + 10, x1 - 10, -half + 6, half - 6, 4)
		if base then
			log(deco, rng, base)
		end
	end
	for _ = 1, 6 do
		local base = space:find(rng, x0 + 6, x1 - 6, -half + 4, half - 4, 2.5)
		if base then
			Build.rock(deco, rng, base, rng:NextNumber(1.6, 2.6), STONE, MOSS)
		end
	end
end

-- Small tree: the Forest's breakable (a few different looks)
function Forest.breakable(parent, position, rng)
	local model = Build.model(parent, "Small Tree")
	local leaves = pick(rng, LEAF_GREENS)
	local trunkPart = Build.cylinder(model, position, 2.4, 0.8, { Color = BARK })
	Build.cylinder(model, position, 0.4, 1.3, { Color = BARK }) -- root flare
	local top = position + Vector3.new(0, 3.6, 0)
	Build.leafCluster(model, rng, top, 3.6, leaves)
	-- apples, oranges or cherries so it reads as "worth something"
	local fruit = pick(rng, { Color3.fromRGB(240, 50, 60), Color3.fromRGB(255, 150, 40), Color3.fromRGB(255, 80, 140) })
	for k = 1, 4 do
		local a = k / 4 * math.pi * 2 + rng:NextNumber(-0.4, 0.4)
		Build.ball(model, top + Vector3.new(math.cos(a) * 1.6, rng:NextNumber(-0.6, 0.6), math.sin(a) * 1.6), 0.6, { Color = fruit })
	end
	model.PrimaryPart = trunkPart
	return model
end

return Forest
