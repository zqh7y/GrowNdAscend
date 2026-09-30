-- Pet models: friendly futuristic fighters. Every pet has its own shape
-- (a species row below) and face, and a tech layer that grows with rarity:
--   Common      collar with a glowing chest core
--   Uncommon    + a chest plate and glowing ear/crest tips
--   Rare        + a back thruster pack with a glow
--   Epic        + shoulder armor, glowing stripes, a light
--   Legendary   + a spinning halo and two orbiting orbs
--   Mythic      + energy wings
--   Secret      + everything in shifting rainbow
-- Huge pets get gold trim and sparkles, Titanic pets a rainbow aura and a
-- crown. PetModels.build returns the model (pivot at the body's centre, feet
-- about 1 stud below) and a list of parts to animate (see client/Pets.luau).
local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local PetModels = {}

local WHITE = Color3.fromRGB(245, 247, 255)
local STEEL = Color3.fromRGB(205, 212, 232)
local INK = Color3.fromRGB(35, 38, 60)
local BLUSH = Color3.fromRGB(255, 150, 180)
local GOLD = Color3.fromRGB(255, 205, 60)

-- Species: body type, ears, tail, face and extras
local SPECIES = {
	Dog = { Body = "beast", Ears = "flop", Tail = "wag", Muzzle = true, Eyes = "round", Mouth = "tongue" },
	Cat = { Body = "beast", Ears = "point", Tail = "long", Eyes = "happy", Mouth = "cat" },
	Bunny = { Body = "beast", Ears = "long", Tail = "puff", Eyes = "round", Mouth = "cat" },
	Chick = { Body = "bird", Crest = "tuft", Eyes = "round", Mouth = "beak" },
	Mouse = { Body = "beast", Ears = "round", Tail = "thin", Eyes = "sparkle", Mouth = "smile", Small = true },
	Fox = { Body = "beast", Ears = "point", Tail = "fluffy", Muzzle = true, Eyes = "happy", Mouth = "smile" },
	Panda = { Body = "beast", Ears = "round", Tail = "puff", Eyes = "patch", Mouth = "smile", Chunky = true },
	Penguin = { Body = "bird", Eyes = "round", Mouth = "beak", Belly = true, Flippers = true },
	Owl = { Body = "bird", Crest = "tufts", Eyes = "big", Mouth = "beak" },
	Wolf = { Body = "beast", Ears = "point", Tail = "fluffy", Muzzle = true, Eyes = "sparkle", Mouth = "smile" },
	Tiger = { Body = "beast", Ears = "round", Tail = "long", Stripes = true, Muzzle = true, Eyes = "sparkle", Mouth = "cat" },
	Unicorn = { Body = "beast", Ears = "point", Tail = "fluffy", Horn = true, Mane = true, Eyes = "sparkle", Mouth = "smile" },
	Dragon = { Body = "beast", Ears = "horns", Tail = "spiky", Wings = true, Muzzle = true, Eyes = "happy", Mouth = "smile" },
	Phoenix = { Body = "bird", Crest = "flame", Eyes = "sparkle", Mouth = "beak", LongTail = true, Wings = true },
	Kraken = { Body = "kraken", Eyes = "big", Mouth = "smile" },
	Griffin = { Body = "bird", Crest = "tufts", Eyes = "sparkle", Mouth = "beak", Wings = true, LionTail = true },
	["Celestial Lion"] = { Body = "beast", Ears = "round", Tail = "long", Mane = true, Muzzle = true, Star = true, Eyes = "sparkle", Mouth = "cat" },
	["Void Serpent"] = { Body = "serpent", Eyes = "sparkle", Mouth = "smile" },
	["Galaxy Whale"] = { Body = "whale", Eyes = "happy", Mouth = "smile" },
	Glitch = { Body = "glitch", Eyes = "pixel", Mouth = "pixel" },
}

-- Building helpers --------------------------------------------------------------------------

local function newModel(name)
	local model = Instance.new("Model")
	model.Name = "Pet_" .. name
	return model
end

local function part(model, props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(props) do
		p[k] = v
	end
	p.Parent = model
	return p
end

local function ball(model, position, size, color, props)
	props = props or {}
	props.Shape = Enum.PartType.Ball
	props.Size = Vector3.one * size
	props.CFrame = CFrame.new(position)
	props.Color = color
	return part(model, props)
end

-- a cylinder between two points
local function limb(model, a, b, width, color, props)
	props = props or {}
	props.Shape = Enum.PartType.Cylinder
	props.Size = Vector3.new((b - a).Magnitude, width, width)
	props.CFrame = CFrame.lookAt((a + b) / 2, b) * CFrame.Angles(0, math.rad(90), 0)
	props.Color = color
	return part(model, props)
end

-- a flat disc facing `normal` (wings, ears, rings)
local function disc(model, center, diameter, thickness, normal, color, props)
	props = props or {}
	props.Shape = Enum.PartType.Cylinder
	props.Size = Vector3.new(thickness, diameter, diameter)
	props.CFrame = CFrame.lookAt(center, center + normal) * CFrame.Angles(0, math.rad(90), 0)
	props.Color = color
	return part(model, props)
end

-- Faces ---------------------------------------------------------------------------------------

-- `head` is the head's centre, `r` its radius; the face looks along -Z
local function face(model, head, r, eyes, mouth, accent)
	local front = head + Vector3.new(0, 0, -r * 0.92)
	for _, side in ipairs({ -1, 1 }) do
		local eye = front + Vector3.new(side * r * 0.4, r * 0.12, 0)
		if eyes == "happy" then
			-- closed happy eyes: little upside-down Vs
			for _, s2 in ipairs({ -1, 1 }) do
				part(model, {
					Size = Vector3.new(r * 0.26, r * 0.08, 0.08),
					CFrame = CFrame.new(eye + Vector3.new(s2 * r * 0.1, 0, -0.02)) * CFrame.Angles(0, 0, math.rad(s2 * -35)),
					Color = INK,
				})
			end
		elseif eyes == "pixel" then
			part(model, { Size = Vector3.new(r * 0.26, r * 0.26, 0.1), CFrame = CFrame.new(eye), Color = Color3.fromRGB(80, 255, 170), Material = Enum.Material.Neon })
		else
			local size = if eyes == "big" then r * 0.5 elseif eyes == "patch" then r * 0.3 else r * 0.36
			if eyes == "patch" then
				ball(model, eye + Vector3.new(side * r * 0.04, -r * 0.03, 0.05), r * 0.55, INK)
			end
			ball(model, eye, size, if eyes == "patch" then Color3.new(1, 1, 1) else INK)
			if eyes == "patch" then
				ball(model, eye + Vector3.new(0, 0, -size * 0.3), size * 0.6, INK)
			end
			ball(model, eye + Vector3.new(-size * 0.2, size * 0.22, -size * 0.35), size * 0.35, Color3.new(1, 1, 1))
			if eyes == "sparkle" or eyes == "big" then
				-- a coloured ring and a second shine: extra shiny eyes
				ball(model, eye + Vector3.new(size * 0.18, -size * 0.2, -size * 0.38), size * 0.18, Color3.new(1, 1, 1))
				ball(model, eye + Vector3.new(0, 0, 0.02), size * 1.15, accent, { Transparency = 0.2 })
			end
		end
		ball(model, front + Vector3.new(side * r * 0.62, -r * 0.18, 0.08), r * 0.26, BLUSH)
	end
	local mouthAt = front + Vector3.new(0, -r * 0.28, -0.02)
	if mouth == "beak" then
		part(model, { Size = Vector3.new(r * 0.4, r * 0.18, r * 0.4), CFrame = CFrame.new(mouthAt + Vector3.new(0, 0.05, -r * 0.12)), Color = Color3.fromRGB(255, 170, 50) })
		part(model, { Size = Vector3.new(r * 0.3, r * 0.12, r * 0.3), CFrame = CFrame.new(mouthAt + Vector3.new(0, -r * 0.1, -r * 0.08)), Color = Color3.fromRGB(245, 140, 40) })
	elseif mouth == "pixel" then
		for k = -1, 1 do
			part(model, { Size = Vector3.new(r * 0.14, r * 0.14, 0.1), CFrame = CFrame.new(mouthAt + Vector3.new(k * r * 0.14, if k == 0 then -r * 0.07 else 0, 0)), Color = Color3.fromRGB(80, 255, 170), Material = Enum.Material.Neon })
		end
	elseif mouth == "cat" then
		-- a little "w"
		for _, side in ipairs({ -1, 1 }) do
			part(model, { Size = Vector3.new(r * 0.2, r * 0.06, 0.06), CFrame = CFrame.new(mouthAt + Vector3.new(side * r * 0.08, 0, 0)) * CFrame.Angles(0, 0, math.rad(side * 25)), Color = INK })
		end
	else
		for k = -1, 1 do
			ball(model, mouthAt + Vector3.new(k * r * 0.12, math.abs(k) * r * 0.05, 0), r * 0.09, INK)
		end
		if mouth == "tongue" then
			ball(model, mouthAt + Vector3.new(0, -r * 0.1, 0.02), r * 0.16, Color3.fromRGB(255, 110, 140))
		end
	end
end

-- Bodies -------------------------------------------------------------------------------------

-- Each body builder returns the head centre, head radius, and where the tech
-- parts go (Chest, Back, Neck), so the tech layer fits every shape.

local function beast(model, pet, spec, light)
	local c = pet.Color
	local chunky = if spec.Chunky then 1.12 elseif spec.Small then 0.88 else 1
	ball(model, Vector3.new(0, 0, -0.15), 1.9 * chunky, c) -- chest
	ball(model, Vector3.new(0, -0.05, 0.55), 1.7 * chunky, c) -- hips
	ball(model, Vector3.new(0, -0.2, -0.35), 1.35 * chunky, light) -- belly
	-- legs with paws
	for _, x in ipairs({ -0.55, 0.55 }) do
		for _, z in ipairs({ -0.55, 0.75 }) do
			limb(model, Vector3.new(x, -0.3, z), Vector3.new(x, -0.85, z), 0.45, c)
			ball(model, Vector3.new(x, -0.88, z - 0.05), 0.5, light)
		end
	end
	local head = Vector3.new(0, 1.05, -0.85)
	local r = 0.8 * chunky
	ball(model, head, r * 2, c)
	if spec.Muzzle then
		ball(model, head + Vector3.new(0, -r * 0.3, -r * 0.62), r * 0.8, light)
		ball(model, head + Vector3.new(0, -r * 0.12, -r * 1.02), r * 0.24, INK) -- nose
	end
	-- ears
	for _, side in ipairs({ -1, 1 }) do
		local base = head + Vector3.new(side * r * 0.55, r * 0.7, 0.05)
		if spec.Ears == "point" then
			part(model, { Size = Vector3.new(r * 0.45, r * 0.75, r * 0.25), CFrame = CFrame.new(base + Vector3.new(0, r * 0.25, 0)) * CFrame.Angles(0, 0, math.rad(side * -18)), Color = c })
			part(model, { Size = Vector3.new(r * 0.25, r * 0.45, r * 0.27), CFrame = CFrame.new(base + Vector3.new(0, r * 0.2, -0.02)) * CFrame.Angles(0, 0, math.rad(side * -18)), Color = BLUSH })
		elseif spec.Ears == "long" then
			limb(model, base, base + Vector3.new(side * r * 0.2, r * 1.5, 0.1), r * 0.42, c)
			limb(model, base + Vector3.new(0, 0.1, -0.05), base + Vector3.new(side * r * 0.2, r * 1.35, 0.05), r * 0.22, BLUSH)
		elseif spec.Ears == "flop" then
			part(model, { Size = Vector3.new(r * 0.35, r * 0.9, r * 0.55), CFrame = CFrame.new(base + Vector3.new(side * r * 0.3, -r * 0.35, 0)) * CFrame.Angles(0, 0, math.rad(side * 20)), Color = c:Lerp(INK, 0.15) })
		elseif spec.Ears == "horns" then
			limb(model, base, base + Vector3.new(side * r * 0.25, r * 0.8, r * 0.35), r * 0.25, WHITE)
		else -- round
			disc(model, base + Vector3.new(0, r * 0.05, 0), r * 0.7, 0.2, Vector3.new(0, 0, -1), if spec.Eyes == "patch" then INK else c)
			disc(model, base + Vector3.new(0, r * 0.05, -0.05), r * 0.42, 0.21, Vector3.new(0, 0, -1), BLUSH)
		end
	end
	-- tail
	local tailBase = Vector3.new(0, 0.2, 1.35)
	if spec.Tail == "fluffy" then
		ball(model, tailBase + Vector3.new(0, 0.35, 0.3), 0.8, c)
		ball(model, tailBase + Vector3.new(0, 0.75, 0.55), 0.65, light)
	elseif spec.Tail == "puff" then
		ball(model, tailBase, 0.6, light)
	elseif spec.Tail == "spiky" then
		limb(model, tailBase, tailBase + Vector3.new(0, 0.2, 1.1), 0.4, c)
		part(model, { Size = Vector3.new(0.15, 0.5, 0.5), CFrame = CFrame.new(tailBase + Vector3.new(0, 0.35, 1.15)) * CFrame.Angles(math.rad(45), 0, 0), Color = WHITE })
	else -- long / thin / wag
		local w = if spec.Tail == "thin" then 0.16 else 0.3
		limb(model, tailBase, tailBase + Vector3.new(0, 0.7, 0.5), w, c)
		ball(model, tailBase + Vector3.new(0, 0.75, 0.52), w * 1.5, light)
	end
	if spec.Stripes then
		for k = -1, 1 do
			part(model, { Size = Vector3.new(1.95, 0.14, 0.3), CFrame = CFrame.new(0, 0.55, k * 0.5 + 0.2) * CFrame.Angles(0, 0, 0), Color = INK })
		end
	end
	if spec.Horn then
		limb(model, head + Vector3.new(0, r * 0.75, -r * 0.35), head + Vector3.new(0, r * 1.5, -r * 0.65), r * 0.28, GOLD)
	end
	if spec.Mane then
		for k = 0, 7 do
			local a = k / 8 * math.pi * 2
			ball(model, head + Vector3.new(math.cos(a) * r * 0.95, math.sin(a) * r * 0.95, r * 0.25), r * 0.65, if spec.Star then GOLD else Color3.fromRGB(255, 190, 240))
		end
	end
	if spec.Star then
		part(model, { Size = Vector3.new(r * 0.35, r * 0.35, 0.1), CFrame = CFrame.new(head + Vector3.new(0, r * 0.6, -r * 0.8)) * CFrame.Angles(0, 0, math.rad(45)), Color = GOLD, Material = Enum.Material.Neon })
	end
	if spec.Wings then
		for _, side in ipairs({ -1, 1 }) do
			disc(model, Vector3.new(side * 1.1, 0.8, 0.2), 1.6, 0.12, Vector3.new(side, 0.4, 0), c:Lerp(WHITE, 0.2))
		end
	end
	return head, r, { Chest = Vector3.new(0, 0.1, -1.05), Back = Vector3.new(0, 0.75, 0.35), Neck = head + Vector3.new(0, -r * 0.75, 0.1) }
end

local function bird(model, pet, spec, light)
	local c = pet.Color
	ball(model, Vector3.new(0, 0, 0), 2.1, c)
	ball(model, Vector3.new(0, -0.15, -0.45), 1.45, if spec.Belly then WHITE else light)
	local head = Vector3.new(0, 1.05, -0.35)
	local r = 0.78
	ball(model, head, r * 2, c)
	for _, side in ipairs({ -1, 1 }) do
		-- wings (or flippers) at the sides
		if spec.Flippers then
			part(model, { Size = Vector3.new(0.2, 1.1, 0.55), CFrame = CFrame.new(side * 1.05, -0.05, 0) * CFrame.Angles(0, 0, math.rad(side * 20)), Color = c })
		else
			disc(model, Vector3.new(side * 1.0, 0.1, 0.1), 1.3, 0.16, Vector3.new(side, 0.2, 0), c:Lerp(light, 0.3))
			disc(model, Vector3.new(side * 1.06, 0.05, 0.25), 0.8, 0.17, Vector3.new(side, 0.2, 0), light)
		end
		part(model, { Size = Vector3.new(0.4, 0.15, 0.55), CFrame = CFrame.new(side * 0.4, -1.0, -0.15), Color = Color3.fromRGB(255, 160, 50) }) -- feet
	end
	if spec.Wings then
		for _, side in ipairs({ -1, 1 }) do
			disc(model, Vector3.new(side * 1.3, 0.8, 0.35), 1.9, 0.12, Vector3.new(side, 0.6, 0.2), light)
		end
	end
	-- crest on top
	if spec.Crest == "tuft" then
		ball(model, head + Vector3.new(0, r * 0.95, 0), r * 0.5, light)
	elseif spec.Crest == "tufts" then
		for _, side in ipairs({ -1, 1 }) do
			part(model, { Size = Vector3.new(r * 0.3, r * 0.6, r * 0.25), CFrame = CFrame.new(head + Vector3.new(side * r * 0.55, r * 0.85, 0)) * CFrame.Angles(0, 0, math.rad(side * -25)), Color = c:Lerp(INK, 0.2) })
		end
	elseif spec.Crest == "flame" then
		for k = -1, 1 do
			part(model, { Size = Vector3.new(0.22, 0.8 - math.abs(k) * 0.25, 0.3), CFrame = CFrame.new(head + Vector3.new(k * 0.22, r * 1.1, 0.1)) * CFrame.Angles(math.rad(-15), 0, math.rad(k * -15)), Color = Color3.fromRGB(255, 200, 60), Material = Enum.Material.Neon })
		end
	end
	-- tail feathers
	local tail = Vector3.new(0, 0.1, 1.05)
	for k = -1, 1 do
		local length = if spec.LongTail then 1.6 else 0.6
		part(model, { Size = Vector3.new(0.25, 0.12, length), CFrame = CFrame.new(tail + Vector3.new(k * 0.25, 0.1, length / 2)) * CFrame.Angles(math.rad(20), math.rad(k * 15), 0), Color = if spec.LongTail then Color3.fromRGB(255, 180, 60) else c })
	end
	if spec.LionTail then
		limb(model, tail, tail + Vector3.new(0, 0.6, 0.8), 0.25, c)
		ball(model, tail + Vector3.new(0, 0.65, 0.85), 0.45, light)
	end
	return head, r, { Chest = Vector3.new(0, 0.05, -1.05), Back = Vector3.new(0, 0.6, 0.75), Neck = head + Vector3.new(0, -r * 0.8, 0.1) }
end

local function kraken(model, pet, spec, light)
	local c = pet.Color
	local head = Vector3.new(0, 0.55, 0)
	local r = 1.05
	ball(model, head, r * 2, c)
	ball(model, head + Vector3.new(0, r * 0.55, 0.2), r * 1.4, c:Lerp(WHITE, 0.1)) -- dome
	for k = 0, 5 do
		local a = k / 6 * math.pi * 2 + math.pi / 6
		local dir = Vector3.new(math.cos(a), 0, math.sin(a))
		local p = head + dir * r * 0.6 - Vector3.new(0, r * 0.7, 0)
		for j = 0, 3 do
			local q = p + dir * (j * 0.35) - Vector3.new(0, j * 0.18 - math.max(j - 2, 0) * 0.3, 0)
			ball(model, q, 0.55 - j * 0.09, if j % 2 == 0 then c else light)
		end
	end
	return head, r, { Chest = head + Vector3.new(0, -r * 0.35, -r * 0.85), Back = head + Vector3.new(0, r * 0.2, r * 0.9), Neck = head + Vector3.new(0, -r * 0.75, 0) }
end

local function serpent(model, pet, spec, light)
	local c = pet.Color
	-- a coiled body of shrinking segments, the head rising at the front
	local previous
	for k = 0, 7 do
		local a = k * 0.8
		local p = Vector3.new(math.cos(a) * (1.0 - k * 0.06), -0.6 + k * 0.08, math.sin(a) * (1.0 - k * 0.06) + 0.3)
		ball(model, p, 1.05 - k * 0.06, if k % 2 == 0 then c else c:Lerp(light, 0.35))
		if previous then
			limb(model, previous, p, 0.8 - k * 0.05, c)
		end
		previous = p
	end
	local head = Vector3.new(0, 1.0, -0.6)
	local r = 0.72
	limb(model, Vector3.new(0.9, -0.5, 0.3), head, 0.8, c)
	ball(model, head, r * 2, c)
	for _, side in ipairs({ -1, 1 }) do
		limb(model, head + Vector3.new(side * r * 0.5, r * 0.6, 0.1), head + Vector3.new(side * r * 0.8, r * 1.3, r * 0.5), r * 0.2, Color3.fromRGB(200, 120, 255))
	end
	return head, r, { Chest = head + Vector3.new(0, -r * 1.1, -0.1), Back = Vector3.new(0, 0.2, 0.9), Neck = head + Vector3.new(0, -r * 0.8, 0.1) }
end

local function whale(model, pet, spec, light)
	local c = pet.Color
	ball(model, Vector3.new(0, 0.1, -0.3), 2.1, c)
	ball(model, Vector3.new(0, 0.05, 0.6), 1.7, c)
	ball(model, Vector3.new(0, -0.05, 1.3), 1.1, c)
	ball(model, Vector3.new(0, -0.35, -0.4), 1.6, light) -- belly
	for _, side in ipairs({ -1, 1 }) do
		part(model, { Size = Vector3.new(0.9, 0.12, 0.5), CFrame = CFrame.new(side * 1.05, -0.35, -0.2) * CFrame.Angles(0, 0, math.rad(side * -25)), Color = c }) -- fins
		part(model, { Size = Vector3.new(0.8, 0.12, 0.45), CFrame = CFrame.new(side * 0.4, 0.1, 1.95) * CFrame.Angles(0, math.rad(side * 30), 0), Color = c }) -- flukes
	end
	-- galaxy spots
	for k = 1, 7 do
		local a = k * 1.3
		ball(model, Vector3.new(math.cos(a) * 0.7, 0.75 + math.sin(k) * 0.15, math.sin(a) * 0.7 + 0.2), 0.2, Color3.fromRGB(200, 220, 255), { Material = Enum.Material.Neon })
	end
	local head = Vector3.new(0, 0.25, -0.55)
	return head, 0.95, { Chest = Vector3.new(0, -0.3, -1.25), Back = Vector3.new(0, 1.05, 0.2), Neck = Vector3.new(0, -0.5, -0.6) }
end

local function glitch(model, pet, spec, light)
	-- a friendly creature made of cubes, with glowing edges and loose pixels
	local body = part(model, { Size = Vector3.new(1.9, 1.7, 1.9), CFrame = CFrame.new(0, -0.1, 0), Color = Color3.fromRGB(30, 40, 70) })
	local head = Vector3.new(0, 1.2, -0.3)
	part(model, { Size = Vector3.new(1.6, 1.4, 1.5), CFrame = CFrame.new(head), Color = Color3.fromRGB(40, 55, 95) })
	for _, p in ipairs({ body }) do
		for _, x in ipairs({ -1, 1 }) do
			for _, z in ipairs({ -1, 1 }) do
				part(model, { Size = Vector3.new(0.12, p.Size.Y, 0.12), CFrame = p.CFrame * CFrame.new(x * p.Size.X / 2, 0, z * p.Size.Z / 2), Color = pet.Color, Material = Enum.Material.Neon })
			end
		end
	end
	for _, x in ipairs({ -0.5, 0.5 }) do
		part(model, { Size = Vector3.new(0.45, 0.45, 0.45), CFrame = CFrame.new(x, -1.0, 0), Color = Color3.fromRGB(40, 55, 95) })
		part(model, { Size = Vector3.new(0.3, 0.6, 0.3), CFrame = CFrame.new(x * 1.3, 2.05, -0.3), Color = pet.Color, Material = Enum.Material.Neon }) -- antennae
	end
	return head, 0.75, { Chest = Vector3.new(0, 0, -1.0), Back = Vector3.new(0, 0.6, 1.0), Neck = Vector3.new(0, 0.6, -0.3) }
end

local BODIES = { beast = beast, bird = bird, kraken = kraken, serpent = serpent, whale = whale, glitch = glitch }

-- Tech layer ---------------------------------------------------------------------------------

local function tech(model, where, level, accent, animated)
	-- collar ring and glowing chest core (every pet)
	disc(model, where.Neck, 1.35, 0.22, Vector3.new(0, 1, 0), STEEL, { Material = Enum.Material.Metal })
	for k = 0, 3 do
		local a = k / 4 * math.pi * 2
		ball(model, where.Neck + Vector3.new(math.cos(a) * 0.62, 0, math.sin(a) * 0.62), 0.16, accent, { Material = Enum.Material.Neon })
	end
	disc(model, where.Chest, 0.62, 0.16, Vector3.new(0, 0, -1), WHITE, { Material = Enum.Material.Metal })
	local core = disc(model, where.Chest + Vector3.new(0, 0, -0.05), 0.36, 0.17, Vector3.new(0, 0, -1), accent, { Material = Enum.Material.Neon })
	table.insert(animated, { Part = core, Kind = "pulse" })

	if level >= 2 then
		-- a chest plate around the core
		part(model, { Size = Vector3.new(1.1, 0.7, 0.14), CFrame = CFrame.new(where.Chest + Vector3.new(0, 0, 0.06)), Color = STEEL, Material = Enum.Material.Metal })
	end
	if level >= 3 then
		-- a thruster pack on the back with a glowing nozzle
		part(model, { Size = Vector3.new(0.9, 0.7, 0.45), CFrame = CFrame.new(where.Back), Color = WHITE, Material = Enum.Material.Metal })
		for _, side in ipairs({ -1, 1 }) do
			limb(model, where.Back + Vector3.new(side * 0.3, -0.1, 0.15), where.Back + Vector3.new(side * 0.3, -0.45, 0.35), 0.28, STEEL, { Material = Enum.Material.Metal })
			local flame = ball(model, where.Back + Vector3.new(side * 0.3, -0.55, 0.42), 0.26, accent, { Material = Enum.Material.Neon })
			table.insert(animated, { Part = flame, Kind = "pulse" })
		end
	end
	if level >= 4 then
		-- shoulder armor and a light
		for _, side in ipairs({ -1, 1 }) do
			part(model, { Size = Vector3.new(0.55, 0.22, 0.75), CFrame = CFrame.new(where.Chest + Vector3.new(side * 0.75, 0.45, 0.45)) * CFrame.Angles(0, 0, math.rad(side * -25)), Color = STEEL, Material = Enum.Material.Metal })
			part(model, { Size = Vector3.new(0.5, 0.06, 0.1), CFrame = CFrame.new(where.Chest + Vector3.new(side * 0.75, 0.57, 0.1)) * CFrame.Angles(0, 0, math.rad(side * -25)), Color = accent, Material = Enum.Material.Neon })
		end
		local light = Instance.new("PointLight")
		light.Color = accent
		light.Range = 8
		light.Brightness = 1.2
		light.Parent = core
	end
	if level >= 5 then
		-- a spinning halo and two orbiting orbs
		local halo = disc(model, where.Neck + Vector3.new(0, 2.2, 0.2), 1.2, 0.08, Vector3.new(0, 1, 0), GOLD, { Material = Enum.Material.Neon, Transparency = 0.15 })
		table.insert(animated, { Part = halo, Kind = "spin", Speed = 2 })
		for k = 0, 1 do
			local orb = ball(model, Vector3.new(math.cos(k * math.pi) * 1.8, 0.6, math.sin(k * math.pi) * 1.8), 0.35, accent, { Material = Enum.Material.Neon })
			table.insert(animated, { Part = orb, Kind = "orbit", Speed = 1.6 })
		end
	end
	if level >= 6 then
		-- energy wings
		for _, side in ipairs({ -1, 1 }) do
			local wing = part(model, {
				Size = Vector3.new(0.08, 1.2, 2.1),
				CFrame = CFrame.new(where.Back + Vector3.new(side * 0.9, 0.5, 0.2)) * CFrame.Angles(math.rad(-20), 0, math.rad(side * -35)),
				Color = accent,
				Material = Enum.Material.Neon,
				Transparency = 0.45,
			})
			table.insert(animated, { Part = wing, Kind = "flap", Side = side })
		end
	end
end

-- Building a pet -----------------------------------------------------------------------------

-- Returns the model (not parented, not yet scaled) and a list of animated
-- parts { Part, Kind = "pulse" | "spin" | "orbit" | "flap" | "rainbow" }
function PetModels.build(name)
	local pet, size = Config.petInfo(name)
	local spec = SPECIES[pet.Name] or SPECIES.Dog
	local rarity = Config.rarity(pet.Odds)
	local level = table.find(Config.RARITIES, rarity) or 1
	local accent = if level >= 7 then Color3.fromRGB(80, 255, 190) else rarity.Color:Lerp(Color3.new(1, 1, 1), 0.15)
	local light = pet.Color:Lerp(Color3.new(1, 1, 1), 0.35)
	local model = newModel(name)
	local animated = {}

	local head, r, where = BODIES[spec.Body](model, pet, spec, light)
	face(model, head, r, spec.Eyes, spec.Mouth, accent)
	tech(model, where, level, accent, animated)

	-- glowing tips on ears/crest for uncommon and up: a small neon dot on top of the head
	if level >= 2 then
		ball(model, head + Vector3.new(0, r * 1.02, 0), r * 0.22, accent, { Material = Enum.Material.Neon })
	end
	-- sizes: Huge gets gold trim, Titanic a crown and a rainbow aura
	if size.Index >= 2 then
		disc(model, where.Neck + Vector3.new(0, -0.05, 0), 1.5, 0.1, Vector3.new(0, 1, 0), GOLD, { Material = Enum.Material.Neon })
	end
	if size.Index >= 3 then
		local crown = head + Vector3.new(0, r * 1.05, 0)
		disc(model, crown, r * 0.9, 0.25, Vector3.new(0, 1, 0), GOLD, { Material = Enum.Material.Metal })
		for k = 0, 4 do
			local a = k / 5 * math.pi * 2
			local tip = ball(model, crown + Vector3.new(math.cos(a) * r * 0.4, 0.25, math.sin(a) * r * 0.4), 0.2, Color3.fromRGB(255, 90, 200), { Material = Enum.Material.Neon })
			table.insert(animated, { Part = tip, Kind = "rainbow" })
		end
	end
	if level >= 7 then
		-- secret pets shimmer through the rainbow
		for _, entry in ipairs(animated) do
			if entry.Kind == "pulse" then
				entry.Kind = "rainbow"
			end
		end
	end

	-- the body's centre is the pivot
	local body = model:FindFirstChildWhichIsA("BasePart")
	body.Name = "Body"
	model.PrimaryPart = body
	model.WorldPivot = CFrame.new()

	-- sparkles and aura
	if level >= 5 or size.Index >= 2 then
		local sparkles = Instance.new("ParticleEmitter")
		sparkles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		sparkles.Color = if size.Index >= 3 or level >= 7
			then ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 90, 90)),
				ColorSequenceKeypoint.new(0.33, Color3.fromRGB(255, 220, 60)),
				ColorSequenceKeypoint.new(0.66, Color3.fromRGB(80, 220, 255)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 100, 255)),
			})
			elseif size.Index == 2 then ColorSequence.new(GOLD)
			else ColorSequence.new(accent)
		sparkles.Rate = 5 + size.Index * 5 + math.max(level - 4, 0) * 3
		sparkles.Lifetime = NumberRange.new(0.6, 1.2)
		sparkles.Speed = NumberRange.new(0.5, 2)
		sparkles.SpreadAngle = Vector2.new(180, 180)
		sparkles.Size = NumberSequence.new(0.3, 0)
		sparkles.LightEmission = 1
		sparkles.Parent = body
	end
	return model, animated, head
end

return PetModels
