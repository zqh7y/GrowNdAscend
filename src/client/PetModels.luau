-- Animal models for all 70 animals: friendly futuristic fighters. Every
-- animal has a species row below (its body type, how it moves, and its
-- features) and its own face. Pets also get a tech layer that grows with
-- rarity (wild animals in the ambient life don't):
--   Common      collar with a glowing chest core
--   Uncommon    + a chest plate and a glowing tip on the head
--   Rare        + a back thruster pack with a glow
--   Epic        + shoulder armor, a light
--   Legendary   + a spinning halo and two orbiting orbs
--   Mythic      + energy wings
--   Secret      + everything in shifting rainbow
-- Huge pets get gold trim and sparkles, Titanic pets a crown and a rainbow aura.
--
-- PetModels.build(name, plain) returns:
--   model     pivot at the body's centre, facing -Z
--   animated  glowing/spinning bits { Part, Kind = "pulse"|"spin"|"orbit"|"flap"|"rainbow" }
--   rig       what the Creature system moves: Legs, Wings, Tail, FootY, Move, Speed
--   head      the head's centre (for name tags)
local Build = require(game:GetService("ReplicatedStorage").Shared.Build)
local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local PetModels = {}

local WHITE = Color3.fromRGB(245, 247, 255)
local STEEL = Color3.fromRGB(205, 212, 232)
local INK = Color3.fromRGB(35, 38, 60)
local BLUSH = Color3.fromRGB(255, 150, 180)
local GOLD = Color3.fromRGB(255, 205, 60)
local ORANGE = Color3.fromRGB(255, 160, 50)

-- Species ------------------------------------------------------------------------------------
-- Move: walk | hop | waddle | fly | slither | swim | hover, Speed in studs/second
local SPECIES = {
	-- World 1: Forest
	Dog = { Body = "beast", Move = "walk", Speed = 20, Ears = "flop", Tail = "wag", Muzzle = true, Eyes = "round", Mouth = "tongue" },
	Cat = { Body = "beast", Move = "walk", Speed = 18, Ears = "point", Tail = "long", Eyes = "happy", Mouth = "cat" },
	Bunny = { Body = "beast", Move = "hop", Speed = 16, Ears = "long", Tail = "puff", Eyes = "round", Mouth = "cat" },
	Chick = { Body = "bird", Move = "waddle", Speed = 11, Crest = "tuft", Eyes = "round", Mouth = "beak", Small = true },
	Mouse = { Body = "beast", Move = "walk", Speed = 18, Ears = "round", Tail = "thin", Eyes = "sparkle", Mouth = "smile", Small = true },
	Hamster = { Body = "beast", Move = "walk", Speed = 14, Ears = "round", Tail = "puff", Eyes = "round", Mouth = "cat", Small = true, Chunky = true },
	Duck = { Body = "bird", Move = "waddle", Speed = 11, Eyes = "round", Mouth = "bill" },
	Frog = { Body = "frog", Move = "hop", Speed = 16, Eyes = "big", Mouth = "smile" },
	Piglet = { Body = "beast", Move = "walk", Speed = 15, Ears = "flop", Tail = "thin", Snout = true, Eyes = "happy", Mouth = "smile", Chunky = true },
	Lamb = { Body = "beast", Move = "walk", Speed = 15, Ears = "flop", Tail = "puff", Wool = true, Eyes = "happy", Mouth = "smile" },
	Squirrel = { Body = "beast", Move = "hop", Speed = 18, Ears = "point", Tail = "bushy", Eyes = "sparkle", Mouth = "cat", Small = true },
	Hedgehog = { Body = "beast", Move = "walk", Speed = 12, Ears = "round", Tail = "none", Spikes = true, Eyes = "round", Mouth = "smile", Small = true },
	Fox = { Body = "beast", Move = "walk", Speed = 22, Ears = "point", Tail = "fluffy", Muzzle = true, Eyes = "happy", Mouth = "smile" },
	Raccoon = { Body = "beast", Move = "walk", Speed = 18, Ears = "round", Tail = "ringed", Mask = true, Muzzle = true, Eyes = "round", Mouth = "smile" },
	Deer = { Body = "beast", Move = "walk", Speed = 22, Ears = "point", Tail = "puff", Antlers = "small", Spots = true, Muzzle = true, Eyes = "sparkle", Mouth = "smile" },
	Owl = { Body = "bird", Move = "fly", Speed = 18, Crest = "tufts", Eyes = "big", Mouth = "beak" },
	Bear = { Body = "beast", Move = "walk", Speed = 17, Ears = "round", Tail = "puff", Muzzle = true, Eyes = "round", Mouth = "smile", Chunky = true },
	Wolf = { Body = "beast", Move = "walk", Speed = 24, Ears = "point", Tail = "fluffy", Muzzle = true, Eyes = "sparkle", Mouth = "smile" },
	Parrot = { Body = "bird", Move = "fly", Speed = 20, Crest = "tuft", LongTail = true, Eyes = "sparkle", Mouth = "beak", Rainbow = true },
	Moose = { Body = "beast", Move = "walk", Speed = 18, Ears = "point", Tail = "puff", Antlers = "big", Muzzle = true, Eyes = "round", Mouth = "smile", Chunky = true },
	Unicorn = { Body = "beast", Move = "walk", Speed = 22, Ears = "point", Tail = "fluffy", Horn = true, Mane = "pink", Eyes = "sparkle", Mouth = "smile" },
	["Forest Guardian"] = { Body = "beast", Move = "walk", Speed = 22, Ears = "point", Tail = "fluffy", Antlers = "glow", Mane = "leaf", Star = true, Muzzle = true, Eyes = "sparkle", Mouth = "smile" },
	-- World 2: Sahara
	Camel = { Body = "beast", Move = "walk", Speed = 16, Ears = "round", Tail = "thin", Hump = true, Muzzle = true, Eyes = "happy", Mouth = "smile" },
	Meerkat = { Body = "beast", Move = "walk", Speed = 20, Ears = "round", Tail = "thin", Mask = true, Eyes = "round", Mouth = "smile", Small = true },
	["Fennec Fox"] = { Body = "beast", Move = "walk", Speed = 22, Ears = "big", Tail = "fluffy", Muzzle = true, Eyes = "sparkle", Mouth = "smile", Small = true },
	Lizard = { Body = "beast", Move = "walk", Speed = 20, Ears = "none", Tail = "long", Low = true, Eyes = "round", Mouth = "smile" },
	Tortoise = { Body = "beast", Move = "walk", Speed = 8, Ears = "none", Tail = "none", Shell = true, Eyes = "happy", Mouth = "smile", Low = true },
	Scorpion = { Body = "beast", Move = "walk", Speed = 18, Ears = "none", Tail = "stinger", Pincers = true, Low = true, Eyes = "round", Mouth = "smile" },
	Cobra = { Body = "serpent", Move = "slither", Speed = 14, Hood = true, Eyes = "sparkle", Mouth = "smile" },
	Vulture = { Body = "bird", Move = "fly", Speed = 18, Eyes = "round", Mouth = "beak", BigWings = true },
	Hyena = { Body = "beast", Move = "walk", Speed = 22, Ears = "round", Tail = "fluffy", Spots = true, Muzzle = true, Eyes = "happy", Mouth = "tongue" },
	Cheetah = { Body = "beast", Move = "walk", Speed = 30, Ears = "round", Tail = "long", Spots = true, Muzzle = true, Eyes = "sparkle", Mouth = "cat" },
	Lion = { Body = "beast", Move = "walk", Speed = 22, Ears = "round", Tail = "long", Mane = "gold", Muzzle = true, Eyes = "sparkle", Mouth = "cat" },
	Falcon = { Body = "bird", Move = "fly", Speed = 26, Eyes = "sparkle", Mouth = "beak", BigWings = true },
	["Golden Scarab"] = { Body = "beast", Move = "hover", Speed = 16, Ears = "none", Tail = "none", Shell = true, Wings = true, Low = true, Eyes = "sparkle", Mouth = "smile" },
	["Anubis Jackal"] = { Body = "beast", Move = "walk", Speed = 24, Ears = "big", Tail = "thin", Muzzle = true, Eyes = "sparkle", Mouth = "smile" },
	Griffin = { Body = "bird", Move = "fly", Speed = 22, Crest = "tufts", Eyes = "sparkle", Mouth = "beak", BigWings = true, LionTail = true },
	Sphinx = { Body = "beast", Move = "walk", Speed = 18, Ears = "none", Tail = "long", Headdress = true, Muzzle = true, Eyes = "sparkle", Mouth = "cat" },
	-- World 3: Frozen Peaks
	Penguin = { Body = "bird", Move = "waddle", Speed = 10, Belly = true, Flippers = true, Eyes = "round", Mouth = "beak" },
	["Snow Hare"] = { Body = "beast", Move = "hop", Speed = 18, Ears = "long", Tail = "puff", Eyes = "sparkle", Mouth = "cat" },
	["Arctic Fox"] = { Body = "beast", Move = "walk", Speed = 22, Ears = "point", Tail = "fluffy", Muzzle = true, Eyes = "happy", Mouth = "smile" },
	Seal = { Body = "whale", Move = "waddle", Speed = 9, Flippers = true, Small = true, Eyes = "big", Mouth = "smile" },
	Husky = { Body = "beast", Move = "walk", Speed = 24, Ears = "point", Tail = "fluffy", Mask = true, Muzzle = true, Eyes = "sparkle", Mouth = "tongue" },
	["Snowy Owl"] = { Body = "bird", Move = "fly", Speed = 18, Crest = "tufts", Eyes = "big", Mouth = "beak" },
	Walrus = { Body = "whale", Move = "waddle", Speed = 8, Flippers = true, Tusks = true, Eyes = "happy", Mouth = "smile" },
	Reindeer = { Body = "beast", Move = "walk", Speed = 22, Ears = "point", Tail = "puff", Antlers = "big", RedNose = true, Muzzle = true, Eyes = "round", Mouth = "smile" },
	["Polar Bear"] = { Body = "beast", Move = "walk", Speed = 17, Ears = "round", Tail = "puff", Muzzle = true, Eyes = "round", Mouth = "smile", Chunky = true },
	["Snow Leopard"] = { Body = "beast", Move = "walk", Speed = 26, Ears = "round", Tail = "bushy", Spots = true, Muzzle = true, Eyes = "sparkle", Mouth = "cat" },
	Orca = { Body = "whale", Move = "swim", Speed = 20, Pattern = "orca", Eyes = "happy", Mouth = "smile" },
	Narwhal = { Body = "whale", Move = "swim", Speed = 18, Horn = true, Pattern = "spots", Eyes = "sparkle", Mouth = "smile" },
	Yeti = { Body = "beast", Move = "walk", Speed = 16, Ears = "none", Tail = "none", Wool = true, Chunky = true, Eyes = "happy", Mouth = "tongue" },
	Mammoth = { Body = "beast", Move = "walk", Speed = 14, Ears = "big", Tail = "thin", Trunk = true, Tusks = true, Wool = true, Chunky = true, Eyes = "round", Mouth = "smile" },
	["Ice Phoenix"] = { Body = "bird", Move = "fly", Speed = 24, Crest = "flame", LongTail = true, BigWings = true, Icy = true, Eyes = "sparkle", Mouth = "beak" },
	["Frost Dragon"] = { Body = "beast", Move = "fly", Speed = 24, Ears = "horns", Tail = "spiky", Wings = true, Muzzle = true, Eyes = "sparkle", Mouth = "smile" },
	-- World 4: Sakura Jungle
	Shiba = { Body = "beast", Move = "walk", Speed = 22, Ears = "point", Tail = "curl", Muzzle = true, Eyes = "happy", Mouth = "tongue" },
	["Red Panda"] = { Body = "beast", Move = "walk", Speed = 18, Ears = "round", Tail = "ringed", Mask = true, Muzzle = true, Eyes = "round", Mouth = "cat" },
	Koi = { Body = "whale", Move = "swim", Speed = 16, Pattern = "koi", Small = true, Eyes = "round", Mouth = "smile" },
	Crane = { Body = "bird", Move = "fly", Speed = 20, Crest = "dot", LongLegs = true, BigWings = true, Eyes = "happy", Mouth = "beak" },
	Tanuki = { Body = "beast", Move = "walk", Speed = 17, Ears = "round", Tail = "bushy", Mask = true, Chunky = true, Muzzle = true, Eyes = "round", Mouth = "smile" },
	Panda = { Body = "beast", Move = "walk", Speed = 15, Ears = "round", Tail = "puff", Eyes = "patch", Mouth = "smile", Chunky = true },
	Kitsune = { Body = "beast", Move = "walk", Speed = 24, Ears = "point", Tail = "nine", Muzzle = true, Star = true, Eyes = "happy", Mouth = "smile" },
	Tiger = { Body = "beast", Move = "walk", Speed = 24, Ears = "round", Tail = "long", Stripes = true, Muzzle = true, Eyes = "sparkle", Mouth = "cat" },
	Kirin = { Body = "beast", Move = "walk", Speed = 26, Ears = "point", Tail = "fluffy", Antlers = "gold", Mane = "gold", Muzzle = true, Eyes = "sparkle", Mouth = "smile" },
	Dragon = { Body = "beast", Move = "fly", Speed = 26, Ears = "horns", Tail = "spiky", Wings = true, Muzzle = true, Eyes = "happy", Mouth = "smile" },
	Phoenix = { Body = "bird", Move = "fly", Speed = 26, Crest = "flame", LongTail = true, BigWings = true, Eyes = "sparkle", Mouth = "beak" },
	Kraken = { Body = "kraken", Move = "swim", Speed = 14, Eyes = "big", Mouth = "smile" },
	["Celestial Lion"] = { Body = "beast", Move = "walk", Speed = 26, Ears = "round", Tail = "long", Mane = "gold", Star = true, Muzzle = true, Eyes = "sparkle", Mouth = "cat" },
	["Void Serpent"] = { Body = "serpent", Move = "slither", Speed = 16, Horns = true, Eyes = "sparkle", Mouth = "smile" },
	["Galaxy Whale"] = { Body = "whale", Move = "swim", Speed = 18, Pattern = "galaxy", Eyes = "happy", Mouth = "smile" },
	Glitch = { Body = "glitch", Move = "hover", Speed = 22, Eyes = "pixel", Mouth = "pixel" },
}
PetModels.SPECIES = SPECIES

-- Helpers ------------------------------------------------------------------------------------

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

local function block(model, cframe, size, color, props)
	props = props or {}
	props.Size = size
	props.CFrame = cframe
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
			for _, s2 in ipairs({ -1, 1 }) do
				block(model, CFrame.new(eye + Vector3.new(s2 * r * 0.1, 0, -0.02)) * CFrame.Angles(0, 0, math.rad(s2 * -35)), Vector3.new(r * 0.26, r * 0.08, 0.08), INK)
			end
		elseif eyes == "pixel" then
			block(model, CFrame.new(eye), Vector3.new(r * 0.26, r * 0.26, 0.1), Color3.fromRGB(80, 255, 170), { Material = Enum.Material.Neon })
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
				ball(model, eye + Vector3.new(size * 0.18, -size * 0.2, -size * 0.38), size * 0.18, Color3.new(1, 1, 1))
				ball(model, eye + Vector3.new(0, 0, 0.02), size * 1.15, accent, { Transparency = 0.2 })
			end
		end
		ball(model, front + Vector3.new(side * r * 0.62, -r * 0.18, 0.08), r * 0.26, BLUSH)
	end
	local mouthAt = front + Vector3.new(0, -r * 0.28, -0.02)
	if mouth == "beak" or mouth == "bill" then
		local wide = if mouth == "bill" then 1.5 else 1
		block(model, CFrame.new(mouthAt + Vector3.new(0, 0.05, -r * 0.12)), Vector3.new(r * 0.4 * wide, r * 0.18, r * 0.4 * wide), ORANGE)
		block(model, CFrame.new(mouthAt + Vector3.new(0, -r * 0.1, -r * 0.08)), Vector3.new(r * 0.3 * wide, r * 0.12, r * 0.3 * wide), Color3.fromRGB(245, 140, 40))
	elseif mouth == "pixel" then
		for k = -1, 1 do
			block(model, CFrame.new(mouthAt + Vector3.new(k * r * 0.14, if k == 0 then -r * 0.07 else 0, 0)), Vector3.new(r * 0.14, r * 0.14, 0.1), Color3.fromRGB(80, 255, 170), { Material = Enum.Material.Neon })
		end
	elseif mouth == "cat" then
		for _, side in ipairs({ -1, 1 }) do
			block(model, CFrame.new(mouthAt + Vector3.new(side * r * 0.08, 0, 0)) * CFrame.Angles(0, 0, math.rad(side * 25)), Vector3.new(r * 0.2, r * 0.06, 0.06), INK)
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

-- Bodies ---------------------------------------------------------------------------------------
-- Each builder fills the rig and returns the head centre, head radius, and
-- where the tech parts go (Chest, Back, Neck).

local function newRig(spec)
	return { Legs = {}, Wings = {}, Tail = nil, FootY = -1.1, Move = spec.Move, Speed = spec.Speed }
end

local function beast(model, pet, spec, light, rig)
	local c = pet.Color
	local chunky = if spec.Chunky then 1.12 elseif spec.Small then 0.86 else 1
	local low = if spec.Low then 0.35 else 0
	ball(model, Vector3.new(0, -low, -0.15), 1.9 * chunky, c) -- chest
	ball(model, Vector3.new(0, -0.05 - low, 0.55), 1.7 * chunky, c) -- hips
	ball(model, Vector3.new(0, -0.2 - low, -0.35), 1.35 * chunky, light) -- belly
	-- legs: a leg and a paw each, swinging from the hip (diagonal pairs move together)
	local legLength = if spec.Low then 0.3 else 0.55
	for i, leg in ipairs({ { -0.55, -0.55, 0 }, { 0.55, -0.55, math.pi }, { -0.55, 0.75, math.pi }, { 0.55, 0.75, 0 } }) do
		local hip = Vector3.new(leg[1] * chunky, -0.3 - low, leg[2])
		local foot = hip - Vector3.new(0, legLength, 0)
		local parts = {
			limb(model, hip, foot, 0.45, c),
			ball(model, foot - Vector3.new(0, 0.03, 0.05), 0.5, light),
		}
		table.insert(rig.Legs, { Parts = parts, Hip = hip, Phase = leg[3], Front = i <= 2 })
	end
	rig.FootY = -0.3 - low - legLength - 0.28

	local head = Vector3.new(0, 1.05 - low * 0.6, -0.85 - low * 0.4)
	local r = 0.8 * chunky
	ball(model, head, r * 2, c)
	if spec.Muzzle then
		ball(model, head + Vector3.new(0, -r * 0.3, -r * 0.62), r * 0.8, light)
		ball(model, head + Vector3.new(0, -r * 0.12, -r * 1.02), r * 0.24, if spec.RedNose then Color3.fromRGB(255, 60, 60) else INK)
	end
	if spec.Snout then
		disc(model, head + Vector3.new(0, -r * 0.2, -r * 0.95), r * 0.62, r * 0.35, Vector3.new(0, 0, -1), c:Lerp(BLUSH, 0.4))
		for _, side in ipairs({ -1, 1 }) do
			ball(model, head + Vector3.new(side * r * 0.12, -r * 0.2, -r * 1.12), r * 0.12, INK)
		end
	end
	if spec.Trunk then
		limb(model, head + Vector3.new(0, -r * 0.35, -r * 0.8), head + Vector3.new(0, -r * 1.1, -r * 1.25), r * 0.4, c)
		limb(model, head + Vector3.new(0, -r * 1.1, -r * 1.25), head + Vector3.new(0, -r * 1.35, -r * 1.05), r * 0.32, c)
	end
	if spec.Tusks then
		for _, side in ipairs({ -1, 1 }) do
			limb(model, head + Vector3.new(side * r * 0.35, -r * 0.5, -r * 0.7), head + Vector3.new(side * r * 0.5, -r * 1.1, -r * 1.3), r * 0.18, WHITE)
		end
	end
	if spec.Mask then
		disc(model, head + Vector3.new(0, r * 0.1, -r * 0.7), r * 1.2, 0.1, Vector3.new(0, 0, -1), c:Lerp(INK, 0.55), { Size = Vector3.new(0.1, r * 0.55, r * 1.35) })
	end
	-- ears
	for _, side in ipairs({ -1, 1 }) do
		local base = head + Vector3.new(side * r * 0.55, r * 0.7, 0.05)
		if spec.Ears == "point" or spec.Ears == "big" then
			local big = if spec.Ears == "big" then 1.6 else 1
			block(model, CFrame.new(base + Vector3.new(0, r * 0.25 * big, 0)) * CFrame.Angles(0, 0, math.rad(side * -18)), Vector3.new(r * 0.45 * big, r * 0.75 * big, r * 0.25), c)
			block(model, CFrame.new(base + Vector3.new(0, r * 0.2 * big, -0.02)) * CFrame.Angles(0, 0, math.rad(side * -18)), Vector3.new(r * 0.25 * big, r * 0.45 * big, r * 0.27), BLUSH)
		elseif spec.Ears == "long" then
			limb(model, base, base + Vector3.new(side * r * 0.2, r * 1.5, 0.1), r * 0.42, c)
			limb(model, base + Vector3.new(0, 0.1, -0.05), base + Vector3.new(side * r * 0.2, r * 1.35, 0.05), r * 0.22, BLUSH)
		elseif spec.Ears == "flop" then
			block(model, CFrame.new(base + Vector3.new(side * r * 0.3, -r * 0.35, 0)) * CFrame.Angles(0, 0, math.rad(side * 20)), Vector3.new(r * 0.35, r * 0.9, r * 0.55), c:Lerp(INK, 0.15))
		elseif spec.Ears == "horns" then
			limb(model, base, base + Vector3.new(side * r * 0.25, r * 0.8, r * 0.35), r * 0.25, WHITE)
		elseif spec.Ears == "round" then
			disc(model, base + Vector3.new(0, r * 0.05, 0), r * 0.7, 0.2, Vector3.new(0, 0, -1), if spec.Eyes == "patch" then INK else c)
			disc(model, base + Vector3.new(0, r * 0.05, -0.05), r * 0.42, 0.21, Vector3.new(0, 0, -1), BLUSH)
		end
	end
	-- antlers and horns
	if spec.Antlers then
		local color = if spec.Antlers == "glow" then Color3.fromRGB(120, 255, 170) elseif spec.Antlers == "gold" then GOLD else Color3.fromRGB(215, 175, 120)
		local big = if spec.Antlers == "big" or spec.Antlers == "glow" then 1.5 else 1
		for _, side in ipairs({ -1, 1 }) do
			local base = head + Vector3.new(side * r * 0.35, r * 0.8, 0.1)
			local tip = base + Vector3.new(side * r * 0.6 * big, r * 1.1 * big, 0.2)
			limb(model, base, tip, r * 0.16, color, if spec.Antlers == "glow" then { Material = Enum.Material.Neon } else nil)
			limb(model, base:Lerp(tip, 0.5), base:Lerp(tip, 0.5) + Vector3.new(side * r * 0.35 * big, r * 0.25 * big, -0.2), r * 0.13, color)
		end
	end
	if spec.Horn then
		limb(model, head + Vector3.new(0, r * 0.75, -r * 0.35), head + Vector3.new(0, r * 1.5, -r * 0.65), r * 0.28, GOLD)
	end
	if spec.Headdress then
		for k = 0, 6 do
			block(model, CFrame.new(head + Vector3.new((-3 + k) * r * 0.28, -r * 0.3, r * 0.1)), Vector3.new(r * 0.26, r * 1.6, r * 0.9), if k % 2 == 0 then GOLD else Color3.fromRGB(45, 120, 235))
		end
		block(model, CFrame.new(head + Vector3.new(0, r * 0.55, 0.05)), Vector3.new(r * 1.9, r * 0.6, r * 1.4), Color3.fromRGB(45, 120, 235))
	end
	if spec.Mane then
		local maneColor = if spec.Mane == "gold" then GOLD elseif spec.Mane == "leaf" then Color3.fromRGB(110, 210, 90) else Color3.fromRGB(255, 190, 240)
		for k = 0, 7 do
			local a = k / 8 * math.pi * 2
			ball(model, head + Vector3.new(math.cos(a) * r * 0.95, math.sin(a) * r * 0.95, r * 0.25), r * 0.65, maneColor)
		end
	end
	if spec.Star then
		block(model, CFrame.new(head + Vector3.new(0, r * 0.6, -r * 0.8)) * CFrame.Angles(0, 0, math.rad(45)), Vector3.new(r * 0.35, r * 0.35, 0.1), GOLD, { Material = Enum.Material.Neon })
	end
	-- body markings and coats
	if spec.Stripes then
		for k = -1, 1 do
			block(model, CFrame.new(0, 0.55 - low, k * 0.5 + 0.2), Vector3.new(1.95 * chunky, 0.14, 0.3), INK)
		end
	end
	if spec.Spots then
		for k = 1, 6 do
			local a = k * 1.7
			ball(model, Vector3.new(math.cos(a) * 0.55, 0.6 - low, math.sin(a) * 0.5 + 0.2), 0.3, if pet.Name == "Deer" then WHITE else c:Lerp(INK, 0.55))
		end
	end
	if spec.Wool then
		for k = 1, 8 do
			local a = k / 8 * math.pi * 2
			ball(model, Vector3.new(math.cos(a) * 0.75, 0.45 - low, math.sin(a) * 0.65 + 0.2), 0.9, WHITE:Lerp(c, 0.3))
		end
	end
	if spec.Spikes then
		for k = 1, 10 do
			local a = k / 10 * math.pi
			limb(model, Vector3.new(math.cos(a) * 0.6, 0.3, 0.3 + math.sin(k) * 0.3), Vector3.new(math.cos(a) * 1.05, 0.95 + math.sin(a) * 0.2, 0.5 + math.sin(k) * 0.4), 0.18, c:Lerp(INK, 0.3))
		end
	end
	if spec.Shell then
		ball(model, Vector3.new(0, 0.35 - low, 0.25), 2.2, if pet.Name == "Golden Scarab" then GOLD else Color3.fromRGB(110, 160, 80))
		for k = 0, 3 do
			ball(model, Vector3.new(math.cos(k * 1.57) * 0.5, 1.2 - low, math.sin(k * 1.57) * 0.5 + 0.25), 0.55, if pet.Name == "Golden Scarab" then Color3.fromRGB(255, 230, 120) else Color3.fromRGB(150, 190, 100))
		end
	end
	if spec.Hump then
		ball(model, Vector3.new(0, 0.9, 0.2), 1.3, c)
	end
	if spec.Pincers then
		for _, side in ipairs({ -1, 1 }) do
			limb(model, Vector3.new(side * 0.6, -low, -0.9), Vector3.new(side * 0.9, -low + 0.1, -1.7), 0.3, c)
			ball(model, Vector3.new(side * 0.9, -low + 0.15, -1.85), 0.55, c:Lerp(WHITE, 0.2))
		end
	end
	-- wings (dragons and the scarab)
	if spec.Wings then
		for _, side in ipairs({ -1, 1 }) do
			local shoulder = Vector3.new(side * 0.8, 0.7 - low, 0.1)
			local wing = disc(model, shoulder + Vector3.new(side * 0.8, 0.3, 0.1), 1.8, 0.12, Vector3.new(side, 0.4, 0), c:Lerp(WHITE, 0.25))
			table.insert(rig.Wings, { Parts = { wing }, Shoulder = shoulder, Side = side })
		end
	end
	-- tail
	local tailBase = Vector3.new(0, 0.2 - low, 1.35)
	local tailParts = {}
	if spec.Tail == "fluffy" or spec.Tail == "bushy" or spec.Tail == "ringed" or spec.Tail == "curl" then
		local big = if spec.Tail == "bushy" then 1.4 else 1
		table.insert(tailParts, ball(model, tailBase + Vector3.new(0, 0.35, 0.3), 0.8 * big, c))
		table.insert(tailParts, ball(model, tailBase + Vector3.new(0, 0.75 * big, 0.55), 0.65 * big, if spec.Tail == "ringed" then c:Lerp(INK, 0.5) else light))
		if spec.Tail == "ringed" then
			table.insert(tailParts, ball(model, tailBase + Vector3.new(0, 1.05, 0.7), 0.5, light))
		end
	elseif spec.Tail == "nine" then
		-- a fan of glowing-tipped tails
		for k = -2, 2 do
			local tip = tailBase + Vector3.new(k * 0.4, 1.0 - math.abs(k) * 0.15, 0.7)
			table.insert(tailParts, limb(model, tailBase, tip, 0.35, c))
			table.insert(tailParts, ball(model, tip, 0.45, Color3.fromRGB(255, 140, 200), { Material = Enum.Material.Neon }))
		end
	elseif spec.Tail == "puff" then
		table.insert(tailParts, ball(model, tailBase, 0.6, light))
	elseif spec.Tail == "spiky" then
		table.insert(tailParts, limb(model, tailBase, tailBase + Vector3.new(0, 0.2, 1.1), 0.4, c))
		table.insert(tailParts, block(model, CFrame.new(tailBase + Vector3.new(0, 0.35, 1.15)) * CFrame.Angles(math.rad(45), 0, 0), Vector3.new(0.15, 0.5, 0.5), WHITE))
	elseif spec.Tail == "stinger" then
		local mid = tailBase + Vector3.new(0, 1.0, 0.4)
		table.insert(tailParts, limb(model, tailBase, mid, 0.3, c))
		table.insert(tailParts, limb(model, mid, mid + Vector3.new(0, 0.3, -0.6), 0.25, c))
		table.insert(tailParts, ball(model, mid + Vector3.new(0, 0.3, -0.7), 0.35, Color3.fromRGB(255, 200, 60)))
	elseif spec.Tail ~= "none" then -- long / thin / wag
		local w = if spec.Tail == "thin" then 0.16 else 0.3
		table.insert(tailParts, limb(model, tailBase, tailBase + Vector3.new(0, 0.7, 0.5), w, c))
		table.insert(tailParts, ball(model, tailBase + Vector3.new(0, 0.75, 0.52), w * 1.5, light))
	end
	if #tailParts > 0 then
		rig.Tail = { Parts = tailParts, Base = tailBase }
	end
	return head, r, { Chest = Vector3.new(0, 0.1 - low, -1.05), Back = Vector3.new(0, 0.75 - low, 0.35), Neck = head + Vector3.new(0, -r * 0.75, 0.1) }
end

local function bird(model, pet, spec, light, rig)
	local c = pet.Color
	local s = if spec.Small then 0.85 else 1
	local legLength = if spec.LongLegs then 1.1 else 0.35
	local lift = legLength - 0.35 -- long-legged birds stand taller
	ball(model, Vector3.new(0, lift, 0), 2.1 * s, c)
	ball(model, Vector3.new(0, lift - 0.15, -0.45 * s), 1.45 * s, if spec.Belly then WHITE else light)
	local head = Vector3.new(0, lift + 1.05 * s, -0.35 * s)
	local r = 0.78 * s
	ball(model, head, r * 2, c)
	for _, side in ipairs({ -1, 1 }) do
		-- wings (or flippers), each flapping from its shoulder
		local shoulder = Vector3.new(side * 0.8 * s, lift + 0.35, 0)
		local parts
		if spec.Flippers then
			parts = { block(model, CFrame.new(side * 1.05 * s, lift - 0.05, 0) * CFrame.Angles(0, 0, math.rad(side * 20)), Vector3.new(0.2, 1.1, 0.55), c) }
		else
			local size = if spec.BigWings then 1.9 else 1.35
			local wingColor = if spec.Rainbow then Color3.fromRGB(70, 150, 255) elseif spec.Icy then Color3.fromRGB(190, 240, 255) else c:Lerp(light, 0.3)
			parts = {
				disc(model, Vector3.new(side * (0.7 + size * 0.3) * s, lift + 0.2, 0.1), size * s, 0.16, Vector3.new(side, 0.3, 0), wingColor),
				disc(model, Vector3.new(side * (0.75 + size * 0.35) * s, lift + 0.15, 0.3), size * 0.6 * s, 0.17, Vector3.new(side, 0.3, 0), if spec.Rainbow then Color3.fromRGB(255, 80, 80) else light),
			}
		end
		table.insert(rig.Wings, { Parts = parts, Shoulder = shoulder, Side = side })
		-- legs and feet
		local hip = Vector3.new(side * 0.4 * s, lift - 0.7, -0.1)
		local foot = hip - Vector3.new(0, legLength, 0)
		local legParts = {
			limb(model, hip, foot, 0.14, ORANGE),
			block(model, CFrame.new(foot + Vector3.new(0, 0.02, -0.12)), Vector3.new(0.4, 0.14, 0.55), ORANGE),
		}
		table.insert(rig.Legs, { Parts = legParts, Hip = hip, Phase = if side < 0 then 0 else math.pi, Front = true })
		rig.FootY = foot.Y - 0.09
	end
	if spec.Crest == "tuft" then
		ball(model, head + Vector3.new(0, r * 0.95, 0), r * 0.5, if spec.Rainbow then Color3.fromRGB(255, 220, 60) else light)
	elseif spec.Crest == "dot" then
		ball(model, head + Vector3.new(0, r * 0.85, 0), r * 0.45, Color3.fromRGB(240, 50, 60))
	elseif spec.Crest == "tufts" then
		for _, side in ipairs({ -1, 1 }) do
			block(model, CFrame.new(head + Vector3.new(side * r * 0.55, r * 0.85, 0)) * CFrame.Angles(0, 0, math.rad(side * -25)), Vector3.new(r * 0.3, r * 0.6, r * 0.25), c:Lerp(INK, 0.2))
		end
	elseif spec.Crest == "flame" then
		local flame = if spec.Icy then Color3.fromRGB(150, 230, 255) else Color3.fromRGB(255, 200, 60)
		for k = -1, 1 do
			block(model, CFrame.new(head + Vector3.new(k * 0.22, r * 1.1, 0.1)) * CFrame.Angles(math.rad(-15), 0, math.rad(k * -15)), Vector3.new(0.22, 0.8 - math.abs(k) * 0.25, 0.3), flame, { Material = Enum.Material.Neon })
		end
	end
	-- tail feathers
	local tail = Vector3.new(0, lift + 0.1, 1.05 * s)
	local tailParts = {}
	for k = -1, 1 do
		local length = if spec.LongTail then 1.6 else 0.6
		local color = if spec.LongTail then (if spec.Icy then Color3.fromRGB(150, 230, 255) elseif spec.Rainbow then Color3.fromRGB(255, 80 + k * 60, 80) else Color3.fromRGB(255, 180, 60)) else c
		table.insert(tailParts, block(model, CFrame.new(tail + Vector3.new(k * 0.25, 0.1, length / 2)) * CFrame.Angles(math.rad(20), math.rad(k * 15), 0), Vector3.new(0.25, 0.12, length), color))
	end
	if spec.LionTail then
		table.insert(tailParts, limb(model, tail, tail + Vector3.new(0, 0.6, 0.8), 0.25, c))
		table.insert(tailParts, ball(model, tail + Vector3.new(0, 0.65, 0.85), 0.45, light))
	end
	rig.Tail = { Parts = tailParts, Base = tail }
	return head, r, { Chest = Vector3.new(0, lift + 0.05, -1.05 * s), Back = Vector3.new(0, lift + 0.6, 0.75 * s), Neck = head + Vector3.new(0, -r * 0.8, 0.1) }
end

local function frog(model, pet, spec, light, rig)
	local c = pet.Color
	ball(model, Vector3.new(0, -0.1, 0.1), 2.0, c)
	ball(model, Vector3.new(0, -0.35, -0.3), 1.5, light)
	for i, leg in ipairs({ { -0.75, -0.6, 0 }, { 0.75, -0.6, 0 }, { -0.9, 0.6, 0 }, { 0.9, 0.6, 0 } }) do
		local hip = Vector3.new(leg[1], -0.55, leg[2])
		local foot = hip + Vector3.new(leg[1] * 0.3, -0.35, 0)
		table.insert(rig.Legs, { Parts = { limb(model, hip, foot, 0.4, c), ball(model, foot, 0.55, light) }, Hip = hip, Phase = 0, Front = i <= 2 })
	end
	rig.FootY = -1.15
	local head = Vector3.new(0, 0.55, -0.65)
	-- big eyes sit on top of the head
	for _, side in ipairs({ -1, 1 }) do
		ball(model, head + Vector3.new(side * 0.45, 0.55, 0), 0.75, c)
	end
	return head, 0.75, { Chest = Vector3.new(0, -0.2, -0.95), Back = Vector3.new(0, 0.7, 0.4), Neck = Vector3.new(0, 0.1, -0.2) }
end

local function kraken(model, pet, spec, light, rig)
	local c = pet.Color
	local head = Vector3.new(0, 0.55, 0)
	local r = 1.05
	ball(model, head, r * 2, c)
	ball(model, head + Vector3.new(0, r * 0.55, 0.2), r * 1.4, c:Lerp(WHITE, 0.1))
	for k = 0, 5 do
		local a = k / 6 * math.pi * 2 + math.pi / 6
		local dir = Vector3.new(math.cos(a), 0, math.sin(a))
		local p = head + dir * r * 0.6 - Vector3.new(0, r * 0.7, 0)
		local parts = {}
		for j = 0, 3 do
			local q = p + dir * (j * 0.35) - Vector3.new(0, j * 0.18 - math.max(j - 2, 0) * 0.3, 0)
			table.insert(parts, ball(model, q, 0.55 - j * 0.09, if j % 2 == 0 then c else light))
		end
		table.insert(rig.Legs, { Parts = parts, Hip = p, Phase = k * 1.05, Front = true })
	end
	rig.FootY = -1.1
	return head, r, { Chest = head + Vector3.new(0, -r * 0.35, -r * 0.85), Back = head + Vector3.new(0, r * 0.2, r * 0.9), Neck = head + Vector3.new(0, -r * 0.75, 0) }
end

local function serpent(model, pet, spec, light, rig)
	local c = pet.Color
	-- a body of shrinking segments trailing behind the head, which wave side
	-- to side as it slithers (each segment is a "leg" with its own phase)
	for k = 0, 6 do
		local p = Vector3.new(0, -0.55, 0.3 + k * 0.75)
		local segment = ball(model, p, 1.1 - k * 0.1, if k % 2 == 0 then c else c:Lerp(light, 0.35))
		table.insert(rig.Legs, { Parts = { segment }, Hip = p, Phase = k * 0.9, Segment = k })
	end
	local head = Vector3.new(0, 0.55, -0.4)
	local r = 0.72
	limb(model, Vector3.new(0, -0.5, 0.3), head, 0.8, c)
	ball(model, head, r * 2, c)
	if spec.Hood then
		disc(model, head + Vector3.new(0, -r * 0.3, r * 0.3), r * 2.6, 0.2, Vector3.new(0, 0, -1), c:Lerp(ORANGE, 0.3))
	end
	if spec.Horns then
		for _, side in ipairs({ -1, 1 }) do
			limb(model, head + Vector3.new(side * r * 0.5, r * 0.6, 0.1), head + Vector3.new(side * r * 0.8, r * 1.3, r * 0.5), r * 0.2, Color3.fromRGB(200, 120, 255))
		end
	end
	rig.FootY = -1.1
	return head, r, { Chest = head + Vector3.new(0, -r * 1.05, -0.1), Back = Vector3.new(0, 0.1, 1.0), Neck = head + Vector3.new(0, -r * 0.8, 0.1) }
end

local function whale(model, pet, spec, light, rig)
	local c = pet.Color
	local s = if spec.Small then 0.7 else 1
	ball(model, Vector3.new(0, 0.1, -0.3) * s, 2.1 * s, c)
	ball(model, Vector3.new(0, 0.05, 0.6) * s, 1.7 * s, c)
	ball(model, Vector3.new(0, -0.05, 1.3) * s, 1.1 * s, c)
	ball(model, Vector3.new(0, -0.35, -0.4) * s, 1.6 * s, if spec.Pattern == "orca" then WHITE else light)
	for _, side in ipairs({ -1, 1 }) do
		local fin = block(model, CFrame.new(side * 1.05 * s, -0.35 * s, -0.2 * s) * CFrame.Angles(0, 0, math.rad(side * -25)), Vector3.new(0.9, 0.12, 0.5) * s, c)
		table.insert(rig.Wings, { Parts = { fin }, Shoulder = Vector3.new(side * 0.8, -0.3, -0.2) * s, Side = side, Fin = true })
	end
	local tailParts = {}
	for _, side in ipairs({ -1, 1 }) do
		table.insert(tailParts, block(model, CFrame.new(side * 0.4 * s, 0.1 * s, 1.95 * s) * CFrame.Angles(0, math.rad(side * 30), 0), Vector3.new(0.8, 0.12, 0.45) * s, c))
	end
	rig.Tail = { Parts = tailParts, Base = Vector3.new(0, 0, 1.4) * s, Vertical = true }
	if spec.Pattern == "galaxy" or spec.Pattern == "spots" then
		for k = 1, 7 do
			local a = k * 1.3
			ball(model, Vector3.new(math.cos(a) * 0.7, 0.75 + math.sin(k) * 0.15, math.sin(a) * 0.7 + 0.2) * s, 0.2 * s, if spec.Pattern == "galaxy" then Color3.fromRGB(200, 220, 255) else WHITE, if spec.Pattern == "galaxy" then { Material = Enum.Material.Neon } else nil)
		end
	elseif spec.Pattern == "orca" then
		for _, side in ipairs({ -1, 1 }) do
			ball(model, Vector3.new(side * 0.55, 0.45, -0.75), 0.55, WHITE) -- eye patches
		end
	elseif spec.Pattern == "koi" then
		for k = 1, 3 do
			ball(model, Vector3.new(math.cos(k * 2) * 0.45, 0.55, (k - 2) * 0.45) * s, 0.55 * s, WHITE)
		end
	end
	if spec.Horn then
		limb(model, Vector3.new(0, 0.2, -1.3), Vector3.new(0, 0.5, -2.8), 0.22, Color3.fromRGB(240, 235, 220))
	end
	if spec.Tusks then
		for _, side in ipairs({ -1, 1 }) do
			limb(model, Vector3.new(side * 0.3, -0.35, -1.15) * s, Vector3.new(side * 0.35, -1.0, -1.3) * s, 0.16, WHITE)
		end
	end
	if spec.Flippers then
		rig.FootY = -0.95 * s
	end
	local head = Vector3.new(0, 0.25, -0.55) * s
	return head, 0.95 * s, { Chest = Vector3.new(0, -0.3, -1.25) * s, Back = Vector3.new(0, 1.05, 0.2) * s, Neck = Vector3.new(0, -0.5, -0.6) * s }
end

local function glitch(model, pet, spec, light, rig)
	local body = block(model, CFrame.new(0, -0.1, 0), Vector3.new(1.9, 1.7, 1.9), Color3.fromRGB(30, 40, 70))
	local head = Vector3.new(0, 1.2, -0.3)
	block(model, CFrame.new(head), Vector3.new(1.6, 1.4, 1.5), Color3.fromRGB(40, 55, 95))
	for _, x in ipairs({ -1, 1 }) do
		for _, z in ipairs({ -1, 1 }) do
			block(model, body.CFrame * CFrame.new(x * 0.95, 0, z * 0.95), Vector3.new(0.12, 1.7, 0.12), pet.Color, { Material = Enum.Material.Neon })
		end
	end
	for _, x in ipairs({ -0.5, 0.5 }) do
		local hip = Vector3.new(x, -0.55, 0)
		table.insert(rig.Legs, { Parts = { block(model, CFrame.new(x, -1.0, 0), Vector3.new(0.45, 0.45, 0.45), Color3.fromRGB(40, 55, 95)) }, Hip = hip, Phase = if x < 0 then 0 else math.pi })
		block(model, CFrame.new(x * 1.3, 2.05, -0.3), Vector3.new(0.3, 0.6, 0.3), pet.Color, { Material = Enum.Material.Neon })
	end
	rig.FootY = -1.25
	return head, 0.75, { Chest = Vector3.new(0, 0, -1.0), Back = Vector3.new(0, 0.6, 1.0), Neck = Vector3.new(0, 0.6, -0.3) }
end

local BODIES = { beast = beast, bird = bird, frog = frog, kraken = kraken, serpent = serpent, whale = whale, glitch = glitch }

-- Tech layer ---------------------------------------------------------------------------------

local function tech(model, where, level, accent, animated)
	disc(model, where.Neck, 1.35, 0.22, Vector3.new(0, 1, 0), STEEL, { Material = Enum.Material.Metal })
	for k = 0, 3 do
		local a = k / 4 * math.pi * 2
		ball(model, where.Neck + Vector3.new(math.cos(a) * 0.62, 0, math.sin(a) * 0.62), 0.16, accent, { Material = Enum.Material.Neon })
	end
	disc(model, where.Chest, 0.62, 0.16, Vector3.new(0, 0, -1), WHITE, { Material = Enum.Material.Metal })
	local core = disc(model, where.Chest + Vector3.new(0, 0, -0.05), 0.36, 0.17, Vector3.new(0, 0, -1), accent, { Material = Enum.Material.Neon })
	table.insert(animated, { Part = core, Kind = "pulse" })
	if level >= 2 then
		block(model, CFrame.new(where.Chest + Vector3.new(0, 0, 0.06)), Vector3.new(1.1, 0.7, 0.14), STEEL, { Material = Enum.Material.Metal })
	end
	if level >= 3 then
		block(model, CFrame.new(where.Back), Vector3.new(0.9, 0.7, 0.45), WHITE, { Material = Enum.Material.Metal })
		for _, side in ipairs({ -1, 1 }) do
			limb(model, where.Back + Vector3.new(side * 0.3, -0.1, 0.15), where.Back + Vector3.new(side * 0.3, -0.45, 0.35), 0.28, STEEL, { Material = Enum.Material.Metal })
			local flame = ball(model, where.Back + Vector3.new(side * 0.3, -0.55, 0.42), 0.26, accent, { Material = Enum.Material.Neon })
			table.insert(animated, { Part = flame, Kind = "pulse" })
		end
	end
	if level >= 4 then
		for _, side in ipairs({ -1, 1 }) do
			block(model, CFrame.new(where.Chest + Vector3.new(side * 0.75, 0.45, 0.45)) * CFrame.Angles(0, 0, math.rad(side * -25)), Vector3.new(0.55, 0.22, 0.75), STEEL, { Material = Enum.Material.Metal })
			block(model, CFrame.new(where.Chest + Vector3.new(side * 0.75, 0.57, 0.1)) * CFrame.Angles(0, 0, math.rad(side * -25)), Vector3.new(0.5, 0.06, 0.1), accent, { Material = Enum.Material.Neon })
		end
		local light = Instance.new("PointLight")
		light.Color = accent
		light.Range = 8
		light.Brightness = 1.2
		light.Parent = core
	end
	if level >= 5 then
		local halo = disc(model, where.Neck + Vector3.new(0, 2.2, 0.2), 1.2, 0.08, Vector3.new(0, 1, 0), GOLD, { Material = Enum.Material.Neon, Transparency = 0.15 })
		table.insert(animated, { Part = halo, Kind = "spin", Speed = 2 })
		for k = 0, 1 do
			local orb = ball(model, Vector3.new(math.cos(k * math.pi) * 1.8, 0.6, math.sin(k * math.pi) * 1.8), 0.35, accent, { Material = Enum.Material.Neon })
			table.insert(animated, { Part = orb, Kind = "orbit", Speed = 1.6 })
		end
	end
	if level >= 6 then
		for _, side in ipairs({ -1, 1 }) do
			local wing = block(model, CFrame.new(where.Back + Vector3.new(side * 0.9, 0.5, 0.2)) * CFrame.Angles(math.rad(-20), 0, math.rad(side * -35)), Vector3.new(0.08, 1.2, 2.1), accent, { Material = Enum.Material.Neon, Transparency = 0.45 })
			table.insert(animated, { Part = wing, Kind = "flap", Side = side })
		end
	end
end

-- Building an animal --------------------------------------------------------------------------

-- plain = true builds a wild animal (no tech, no sparkles) for the ambient life
function PetModels.build(name, plain)
	local pet, size = Config.petInfo(name)
	local spec = SPECIES[pet.Name] or SPECIES.Dog
	local rarity = Config.rarity(pet.Odds)
	local level = table.find(Config.RARITIES, rarity) or 1
	local accent = if level >= 7 then Color3.fromRGB(80, 255, 190) else rarity.Color:Lerp(Color3.new(1, 1, 1), 0.15)
	local light = pet.Color:Lerp(Color3.new(1, 1, 1), 0.35)
	local model = Instance.new("Model")
	model.Name = "Pet_" .. name
	local animated = {}
	local rig = newRig(spec)

	local head, r, where = BODIES[spec.Body](model, pet, spec, light, rig)
	face(model, head, r, spec.Eyes, spec.Mouth, accent)
	if not plain then
		tech(model, where, level, accent, animated)
		if level >= 2 then
			ball(model, head + Vector3.new(0, r * 1.02, 0), r * 0.22, accent, { Material = Enum.Material.Neon })
		end
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
			for _, entry in ipairs(animated) do
				if entry.Kind == "pulse" then
					entry.Kind = "rainbow"
				end
			end
		end
	end

	local body = model:FindFirstChildWhichIsA("BasePart")
	body.Name = "Body"
	Build.setPivot(model, body, CFrame.new())

	if not plain and (level >= 5 or size.Index >= 2) then
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
	return model, animated, rig, head
end

return PetModels
