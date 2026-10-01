-- Animal models for all 70 animals: chunky, blocky collectibles. Every
-- animal is built from soft rounded blocks (a big head on a compact body,
-- short sturdy legs) and has its own silhouette, face, fur and markings
-- (see SPECIES). The faces are layered: glossy eyes with an iris and two
-- highlights, cheeks, a nose and a mouth with its own shape. Paws have toes,
-- chests have layered fur.
--
-- Pets also wear accessories that grow with rarity (wild animals in the
-- ambient life don't):
--   Common      a leather collar with studs and a round gold tag
--   Uncommon    + a bandana in the rarity colour
--   Rare        + a little adventure satchel
--   Epic        + a cape with gold trim (instead of the satchel)
--   Legendary   + a gem on the collar and two gold stars circling the pet
--   Mythic      + soft feathered wings
--   Secret      + rainbow gem and trim
-- Huge pets: a gold collar, gold paw cuffs, a gold badge and gold sparkles.
-- Titanic pets are collector's trophies: a jewelled crown, a gold chest plate
-- with a big gem, a royal cape with an ermine edge, gold cuffs, a warm glow
-- and rainbow sparkles.
--
-- PetModels.build(name, plain) returns:
--   model     pivot at the body's centre, facing -Z
--   animated  moving bits { Part, Kind = "pulse"|"spin"|"orbit"|"flap"|"rainbow" }
--   rig       what the Creature system moves: Legs, Wings, Tail, FootY, Move, Speed
--   head      the head's centre (for name tags)
local Build = require(game:GetService("ReplicatedStorage").Shared.Build)
local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local PetModels = {}

local WHITE = Color3.fromRGB(250, 250, 252)
local INK = Color3.fromRGB(38, 38, 54)
local BLUSH = Color3.fromRGB(255, 150, 172)
local PAD = Color3.fromRGB(255, 176, 190)
local GOLD = Color3.fromRGB(255, 200, 70)
local GOLD_DEEP = Color3.fromRGB(226, 152, 40)
local IVORY = Color3.fromRGB(246, 236, 214)
local ORANGE = Color3.fromRGB(255, 165, 60)
local VELVET = Color3.fromRGB(176, 30, 60)
local LEATHER = Color3.fromRGB(150, 96, 60)

local SMOOTH = Enum.Material.SmoothPlastic
local METAL = Enum.Material.Metal
local GLASS = Enum.Material.Glass
local FABRIC = Enum.Material.Fabric
local NEON = Enum.Material.Neon

-- Species ------------------------------------------------------------------------------------
-- Move: walk | hop | waddle | fly | slither | swim | hover, Speed in studs/second
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
	Mammoth = { Body = "beast", Move = "walk", Speed = 14, Ears = "flop", Tail = "thin", Trunk = true, Tusks = true, Wool = true, Chunky = true, Eyes = "round", Mouth = "smile" },
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
PetModels.SPECIES = SPECIES

-- Helpers ------------------------------------------------------------------------------------

local function part(model, props, className)
	local p = Instance.new(className or "Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = SMOOTH
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(props) do
		p[k] = v
	end
	p.Parent = model
	return p
end

local function V(x, y, z)
	return Vector3.new(x, y, z)
end

-- a plain block at a CFrame (or a position)
local function box(model, at, size, color, props)
	local p = props and table.clone(props) or {}
	p.Size = size
	p.CFrame = if typeof(at) == "Vector3" then CFrame.new(at) else at
	p.Color = color
	return part(model, p)
end

-- a chunky block with soft bevelled edges (three overlapping blocks);
-- returns the main block and all three
local function chunk(model, at, size, color, bevel, props)
	local cf = if typeof(at) == "Vector3" then CFrame.new(at) else at
	local b = math.min(bevel or 0.15, size.X / 4, size.Y / 4, size.Z / 4) * 2
	local main = box(model, cf, V(size.X - b, size.Y - b, size.Z), color, props)
	local wide = box(model, cf, V(size.X, size.Y - b, size.Z - b), color, props)
	local tall = box(model, cf, V(size.X - b, size.Y, size.Z - b), color, props)
	return main, { main, wide, tall }
end

-- a square beam from a to b
local function beam(model, a, b, width, color, props)
	local length = (b - a).Magnitude
	return box(model, CFrame.lookAt((a + b) / 2, b), V(width, width, length), color, props)
end

-- a round disc facing `normal` (tags, gems)
local function disc(model, center, diameter, thickness, normal, color, props)
	local p = props and table.clone(props) or {}
	p.Shape = Enum.PartType.Cylinder
	p.Size = V(thickness, diameter, diameter)
	p.CFrame = CFrame.lookAt(center, center + normal) * CFrame.Angles(0, math.rad(90), 0)
	p.Color = color
	return part(model, p)
end

local function append(list, more)
	for _, p in ipairs(more) do
		table.insert(list, p)
	end
	return list
end

-- Faces ---------------------------------------------------------------------------------------
-- A face sits on a flat front (facing -Z). `u` is the face's size unit.

local function eye(model, p, u, kind, iris, side)
	if kind == "happy" then
		-- closed, smiling eyes: a little arch
		for _, s2 in ipairs({ -1, 1 }) do
			box(model, CFrame.new(p + V(s2 * u * 0.075, -u * 0.02, -0.02)) * CFrame.Angles(0, 0, math.rad(s2 * -38)), V(u * 0.21, u * 0.075, 0.05), INK)
		end
		return
	elseif kind == "pixel" then
		box(model, p + V(0, 0, -0.02), V(u * 0.26, u * 0.26, 0.05), iris, { Material = NEON })
		return
	end
	local k = if kind == "big" then 1.3 else 1
	local w, h = u * 0.3 * k, u * 0.4 * k
	if kind == "patch" then
		-- panda: a tilted dark patch with a small glossy eye inside
		box(model, CFrame.new(p + V(side * u * 0.03, -u * 0.05, -0.01)) * CFrame.Angles(0, 0, math.rad(side * -22)), V(u * 0.46, u * 0.58, 0.04), INK)
		w, h = w * 0.62, h * 0.62
		box(model, p + V(0, 0, -0.03), V(w * 1.3, h * 1.25, 0.04), WHITE)
		p += V(0, 0, -0.015)
	end
	box(model, p + V(0, 0, -0.02), V(w, h, 0.05), INK)
	box(model, p + V(0, -h * 0.24, -0.035), V(w * 0.78, h * 0.3, 0.04), iris)
	box(model, p + V(-w * 0.2, h * 0.2, -0.05), V(w * 0.38, w * 0.38, 0.04), WHITE)
	box(model, p + V(w * 0.22, -h * 0.06, -0.05), V(w * 0.17, w * 0.17, 0.04), WHITE)
	if kind == "sparkle" or kind == "big" then
		box(model, CFrame.new(p + V(w * 0.2, h * 0.3, -0.05)) * CFrame.Angles(0, 0, math.rad(45)), V(w * 0.15, w * 0.15, 0.04), WHITE)
		-- lashes
		box(model, CFrame.new(p + V(side * w * 0.55, h * 0.42, -0.02)) * CFrame.Angles(0, 0, math.rad(side * -35)), V(w * 0.32, u * 0.05, 0.04), INK)
	end
end

local function eyes(model, f, u, kind, iris, spread, lift, darkFace)
	for _, side in ipairs({ -1, 1 }) do
		local p = f + V(side * u * (spread or 0.42), u * (lift or 0.14), 0)
		if darkFace and kind ~= "patch" then
			-- a soft light ring so the eyes read on a dark face
			box(model, p + V(0, if kind == "happy" then -u * 0.02 else 0, -0.008), if kind == "happy" then V(u * 0.32, u * 0.16, 0.03) else V(u * 0.38, u * 0.48, 0.03) * (if kind == "big" then 1.3 else 1), Color3.fromRGB(235, 238, 250))
		end
		eye(model, p, u, kind, iris, side)
	end
end

local function cheeks(model, f, u, spread)
	for _, side in ipairs({ -1, 1 }) do
		box(model, f + V(side * u * (spread or 0.6), -u * 0.2, -0.015), V(u * 0.24, u * 0.11, 0.04), BLUSH)
	end
end

-- the mouth at point m (on the surface); hasNose: a nose is already there
local function mouth(model, m, u, kind, hasNose, accent)
	if kind == "beak" or kind == "bill" then
		local wide = if kind == "bill" then 1.55 else 1
		local flat = if kind == "bill" then 0.75 else 1
		box(model, m + V(0, u * 0.04, -u * 0.15), V(u * 0.36 * wide, u * 0.16 * flat, u * 0.32), ORANGE)
		box(model, m + V(0, -u * 0.08, -u * 0.1), V(u * 0.28 * wide, u * 0.1 * flat, u * 0.22), Color3.fromRGB(236, 128, 40))
		for _, side in ipairs({ -1, 1 }) do
			box(model, m + V(side * u * 0.07 * wide, u * 0.1, -u * 0.22), V(u * 0.04, u * 0.03, u * 0.06), Color3.fromRGB(190, 100, 30))
		end
		return
	elseif kind == "pixel" then
		for k = -1, 1 do
			box(model, m + V(k * u * 0.13, if k == 0 then -u * 0.06 else 0, -0.02), V(u * 0.12, u * 0.12, 0.05), accent, { Material = NEON })
		end
		return
	end
	if not hasNose then
		box(model, m + V(0, u * 0.08, -0.02), V(u * 0.14, u * 0.08, 0.05), Color3.fromRGB(240, 120, 140))
	end
	if kind == "cat" then
		for _, side in ipairs({ -1, 1 }) do
			box(model, CFrame.new(m + V(side * u * 0.06, -u * 0.02, -0.02)) * CFrame.Angles(0, 0, math.rad(side * 28)), V(u * 0.14, u * 0.045, 0.05), INK)
		end
	else
		box(model, m + V(0, -u * 0.04, -0.02), V(u * 0.15, u * 0.05, 0.05), INK)
		for _, side in ipairs({ -1, 1 }) do
			box(model, m + V(side * u * 0.09, -u * 0.01, -0.02), V(u * 0.045, u * 0.08, 0.05), INK)
		end
		if kind == "tongue" then
			box(model, m + V(0, -u * 0.1, -0.035), V(u * 0.12, u * 0.11, 0.05), Color3.fromRGB(255, 110, 140))
		end
	end
end

local function luminance(c)
	return c.R * 0.3 + c.G * 0.59 + c.B * 0.11
end

local function face(model, f, u, spec, accent, mouthAt, hasNose, faceColor)
	local iris = if spec.Eyes == "sparkle" or spec.Eyes == "big" then accent else Color3.fromRGB(92, 98, 140)
	eyes(model, f, u, spec.Eyes, if spec.Eyes == "pixel" then accent else iris, nil, nil, faceColor ~= nil and luminance(faceColor) < 0.3)
	cheeks(model, f, u)
	mouth(model, mouthAt or (f + V(0, -u * 0.24, 0)), u, spec.Mouth, hasNose, accent)
end

-- Bodies ---------------------------------------------------------------------------------------
-- Each builder fills the rig and returns the head centre and `where`: the
-- spots the accessories use (Collar, CollarSize, Chest, Back, BackSize, Crown).

local function newRig(spec)
	return { Legs = {}, Wings = {}, Tail = nil, FootY = -1.1, Move = spec.Move, Speed = spec.Speed }
end

-- toes on the front of a paw
local function toes(model, pawFront, width, height, color)
	local parts = {}
	for _, x in ipairs({ -1, 1 }) do
		table.insert(parts, box(model, pawFront + V(x * width * 0.17, 0, -0.01), V(0.035, height * 0.7, 0.04), color))
	end
	return parts
end

local function earPoint(model, base, side, s, c, inner, tip, big)
	local cf = CFrame.new(base) * CFrame.Angles(0, 0, math.rad(side * -14))
	box(model, cf * CFrame.new(0, 0.12 * s * big, 0), V(0.5, 0.28, 0.24) * s * big, c)
	box(model, cf * CFrame.new(0, 0.35 * s * big, 0), V(0.36, 0.22, 0.2) * s * big, c)
	box(model, cf * CFrame.new(0, 0.52 * s * big, 0), V(0.2, 0.16, 0.16) * s * big, tip)
	box(model, cf * CFrame.new(0, 0.2 * s * big, -0.11 * s * big), V(0.28, 0.24, 0.04) * s * big, inner)
	box(model, cf * CFrame.new(0, 0.38 * s * big, -0.09 * s * big), V(0.16, 0.16, 0.04) * s * big, inner)
	-- a fluffy tuft at the base of the ear
	box(model, cf * CFrame.new(0, 0.1 * s * big, -0.14 * s * big), V(0.18, 0.14, 0.04) * s * big, WHITE:Lerp(c, 0.4))
end

local function beast(ctx)
	local model, spec, rig = ctx.Model, ctx.Spec, ctx.Rig
	local c, light, dark = ctx.Color, ctx.Light, ctx.Dark
	local s = if spec.Chunky then 1.12 elseif spec.Small then 0.88 else 1
	local low = if spec.Low then 0.3 else 0
	local legColor = c
	if spec.Eyes == "patch" then -- panda: a white coat, black legs and shoulders
		c, light, dark, legColor = WHITE, Color3.fromRGB(236, 238, 244), INK, INK
	end
	local bodyY = -0.05 - low
	local bodyZ = 0.25 * s
	local bodySize = V(1.55, 1.2, if spec.Low then 2.3 else 1.85) * s
	chunk(model, V(0, bodyY, bodyZ), bodySize, c, 0.2 * s)
	local chestZ = bodyZ - bodySize.Z / 2
	if legColor ~= c then
		box(model, V(0, bodyY + 0.1 * s, bodyZ - 0.1 * s), V(bodySize.X + 0.04, 0.5 * s, 0.6 * s), legColor)
	end
	-- layered chest fur and a light belly
	box(model, V(0, bodyY - 0.02 * s, chestZ - 0.03), V(0.86, 0.7, 0.1) * s, light)
	for _, side in ipairs({ -1, 1 }) do
		box(model, CFrame.new(side * 0.17 * s, bodyY - 0.38 * s, chestZ - 0.06) * CFrame.Angles(0, 0, math.rad(side * -16)), V(0.3, 0.28, 0.08) * s, light)
	end
	box(model, V(0, bodyY - 0.26 * s, chestZ - 0.08), V(0.24, 0.24, 0.08) * s, WHITE:Lerp(light, 0.5))
	box(model, V(0, bodyY - bodySize.Y / 2 + 0.03, bodyZ), V(bodySize.X * 0.7, 0.08, bodySize.Z * 0.72), light)

	-- legs: a leg and a paw with toes, swinging from the hip (diagonal pairs together)
	local legLength = (if spec.Low then 0.18 else 0.3) * s
	local hipY = bodyY - bodySize.Y / 2 + 0.12 * s
	local xs = 0.47 * s
	local zf, zb = chestZ + 0.4 * s, bodyZ + bodySize.Z / 2 - 0.4 * s
	local footY = 0
	for i, leg in ipairs({ { -xs, zf, 0 }, { xs, zf, math.pi }, { -xs, zb, math.pi }, { xs, zb, 0 } }) do
		local hip = V(leg[1], hipY, leg[2])
		local legH = legLength + 0.12 * s
		local parts = { box(model, hip - V(0, legH / 2, 0), V(0.42, legH, 0.42) * s, legColor) }
		local pawSize = V(0.52, 0.2, 0.58) * s
		local paw = hip - V(0, legH + pawSize.Y / 2 - 0.04 * s, 0.05 * s)
		table.insert(parts, box(model, paw, pawSize, if legColor ~= c then legColor:Lerp(WHITE, 0.15) else light))
		append(parts, toes(model, paw - V(0, 0, pawSize.Z / 2), pawSize.X, pawSize.Y, light:Lerp(INK, 0.35)))
		if ctx.Trim then
			table.insert(parts, box(model, paw + V(0, pawSize.Y / 2 + 0.06 * s, 0.05 * s), V(0.5, 0.12, 0.5) * s, ctx.Trim, { Material = METAL }))
		end
		footY = paw.Y - pawSize.Y / 2
		table.insert(rig.Legs, { Parts = parts, Hip = hip, Phase = leg[3], Front = i <= 2 })
	end
	rig.FootY = footY

	-- head: big and chunky, with a tuft of fur on top
	local headSize = V(1.8, 1.55, 1.5) * s
	local head = V(0, bodyY + bodySize.Y / 2 + headSize.Y / 2 - 0.2 * s, -0.5 * s - low * 0.5)
	chunk(model, head, headSize, c, 0.2 * s)
	local top = head.Y + headSize.Y / 2
	box(model, CFrame.new(0.12 * s, top + 0.04 * s, head.Z - 0.2 * s) * CFrame.Angles(0, 0, math.rad(-20)), V(0.3, 0.2, 0.3) * s, c)
	box(model, CFrame.new(-0.12 * s, top + 0.02 * s, head.Z - 0.28 * s) * CFrame.Angles(0, 0, math.rad(18)), V(0.22, 0.16, 0.24) * s, dark)
	local front = head.Z - headSize.Z / 2
	local u = 0.95 * s
	local f = V(0, head.Y, front)
	-- cheek fluff on the sides of the head
	if spec.Ears == "point" or spec.Ears == "big" or spec.Mane then
		for _, side in ipairs({ -1, 1 }) do
			box(model, CFrame.new(side * (headSize.X / 2 + 0.04 * s), head.Y - 0.3 * s, head.Z - 0.2 * s) * CFrame.Angles(0, 0, math.rad(side * 25)), V(0.18, 0.32, 0.5) * s, light)
		end
	end

	local mouthAt, hasNose
	if spec.Muzzle then
		local mz = front - 0.14 * s
		chunk(model, V(0, head.Y - 0.36 * s, mz), V(0.84, 0.48, 0.36) * s, light, 0.08 * s)
		box(model, V(0, head.Y - 0.21 * s, mz - 0.2 * s), V(0.3, 0.17, 0.1) * s, if spec.RedNose then Color3.fromRGB(255, 60, 70) else INK)
		box(model, V(-0.06 * s, head.Y - 0.17 * s, mz - 0.25 * s), V(0.08, 0.05, 0.03) * s, WHITE)
		-- whisker dots
		for _, side in ipairs({ -1, 1 }) do
			for k = 0, 1 do
				box(model, V(side * (0.22 + k * 0.1) * s, head.Y - 0.36 * s + k * 0.05 * s, mz - 0.19 * s), V(0.04, 0.04, 0.03) * s, light:Lerp(INK, 0.45))
			end
		end
		mouthAt, hasNose = V(0, head.Y - 0.42 * s, mz - 0.18 * s), true
	elseif spec.Snout then
		local snout = V(0, head.Y - 0.3 * s, front - 0.12 * s)
		chunk(model, snout, V(0.6, 0.42, 0.26) * s, c:Lerp(PAD, 0.5), 0.06 * s)
		for _, side in ipairs({ -1, 1 }) do
			box(model, snout + V(side * 0.12 * s, 0, -0.14 * s), V(0.1, 0.16, 0.03) * s, Color3.fromRGB(190, 90, 110))
		end
		mouthAt, hasNose = V(0, head.Y - 0.56 * s, front), true
	end
	if spec.Mask then
		box(model, V(0, head.Y + 0.13 * u, front - 0.012), V(headSize.X * 0.9, 0.48 * u, 0.04), c:Lerp(INK, 0.6))
	end
	face(model, f, u, spec, ctx.Accent, mouthAt, hasNose, c)
	if spec.Trunk then
		local p = V(0, head.Y - 0.25 * s, front)
		for k = 0, 3 do
			local w = (0.42 - k * 0.06) * s
			p += V(0, -0.22 * s, -(if k < 2 then 0.12 else 0.02) * s)
			box(model, p, V(w, 0.26 * s, w), if k == 3 then light else c:Lerp(INK, 0.12 + k * 0.04))
		end
	end
	if spec.Tusks then
		for _, side in ipairs({ -1, 1 }) do
			local a = V(side * 0.32 * s, head.Y - 0.45 * s, front - 0.05)
			beam(model, a, a + V(side * 0.12, -0.35, -0.4) * s, 0.16 * s, IVORY)
			beam(model, a + V(side * 0.12, -0.35, -0.4) * s, a + V(side * 0.1, -0.3, -0.62) * s, 0.12 * s, IVORY)
		end
	end

	-- ears
	for _, side in ipairs({ -1, 1 }) do
		local base = V(side * 0.55 * s, top - 0.04 * s, head.Z + 0.1 * s)
		if spec.Ears == "point" or spec.Ears == "big" then
			earPoint(model, base, side, s, c, PAD, dark, if spec.Ears == "big" then 1.6 else 1)
		elseif spec.Ears == "round" then
			local inner = if spec.Eyes == "patch" then INK else c
			chunk(model, base + V(0, 0.18 * s, 0), V(0.56, 0.5, 0.24) * s, inner, 0.08 * s)
			box(model, base + V(0, 0.16 * s, -0.12 * s), V(0.32, 0.28, 0.04) * s, if spec.Eyes == "patch" then Color3.fromRGB(70, 70, 90) else PAD)
		elseif spec.Ears == "long" then
			local cf = CFrame.new(base + V(side * -0.1 * s, 0, 0)) * CFrame.Angles(math.rad(10), 0, math.rad(side * -8))
			box(model, cf * CFrame.new(0, 0.62 * s, 0), V(0.36, 1.25, 0.22) * s, c)
			box(model, cf * CFrame.new(0, 0.58 * s, -0.11 * s), V(0.18, 0.95, 0.04) * s, PAD)
			box(model, cf * CFrame.new(0, 1.28 * s, 0), V(0.3, 0.12, 0.18) * s, dark)
		elseif spec.Ears == "flop" then
			local cf = CFrame.new(side * (headSize.X / 2 + 0.06 * s), head.Y + 0.25 * s, head.Z + 0.05 * s) * CFrame.Angles(0, 0, math.rad(side * 14))
			box(model, cf * CFrame.new(0, -0.3 * s, 0), V(0.22, 0.85, 0.58) * s, dark)
			box(model, cf * CFrame.new(0, -0.7 * s, 0), V(0.2, 0.12, 0.46) * s, dark:Lerp(INK, 0.2))
		elseif spec.Ears == "horns" then
			local a = base + V(0, 0.05 * s, 0.05 * s)
			local b = a + V(side * 0.2, 0.45, 0.25) * s
			beam(model, a, b, 0.26 * s, IVORY)
			beam(model, b, b + V(side * 0.05, 0.3, 0.3) * s, 0.16 * s, IVORY:Lerp(Color3.fromRGB(180, 200, 255), 0.3))
		end
	end

	-- antlers, horns, headdress, mane, star
	if spec.Antlers then
		local color = if spec.Antlers == "glow" then Color3.fromRGB(150, 240, 170) elseif spec.Antlers == "gold" then GOLD else Color3.fromRGB(205, 160, 110)
		local props = if spec.Antlers == "gold" then { Material = METAL } else nil
		local big = if spec.Antlers == "big" or spec.Antlers == "glow" then 1.45 else 1
		for _, side in ipairs({ -1, 1 }) do
			local a = V(side * 0.32 * s, top, head.Z + 0.05 * s)
			local b = a + V(side * 0.35, 0.55, 0.1) * s * big
			local cTip = b + V(side * 0.25, 0.4, 0.05) * s * big
			beam(model, a, b, 0.16 * s, color, props)
			beam(model, b, cTip, 0.13 * s, color, props)
			beam(model, b, b + V(side * -0.05, 0.38, -0.2) * s * big, 0.11 * s, color, props)
			beam(model, a:Lerp(b, 0.5), a:Lerp(b, 0.5) + V(side * 0.32, 0.15, -0.12) * s * big, 0.1 * s, color, props)
			if spec.Antlers == "glow" then
				box(model, CFrame.new(cTip) * CFrame.Angles(0, 0, math.rad(45)), V(0.16, 0.16, 0.06) * s, Color3.fromRGB(255, 160, 200))
			end
		end
	end
	if spec.Horn then
		local base = V(0, top - 0.04 * s, head.Z - 0.3 * s)
		local cf = CFrame.lookAt(base, base + V(0, 1, -0.35))
		for k = 0, 3 do
			local w = (0.26 - k * 0.05) * s
			box(model, cf * CFrame.new(0, 0, -(k + 0.5) * 0.2 * s) * CFrame.Angles(0, 0, math.rad(k * 30)), V(w, w, 0.22 * s), if k % 2 == 0 then GOLD else Color3.fromRGB(255, 236, 160), { Material = METAL })
		end
	end
	if spec.Headdress then
		local blue, half = Color3.fromRGB(45, 110, 225), headSize.X / 2
		chunk(model, V(0, top + 0.05 * s, head.Z + 0.05 * s), V(headSize.X + 0.12 * s, 0.3 * s, headSize.Z + 0.08 * s), blue, 0.08 * s)
		for k = -2, 2 do
			box(model, V(k * 0.34 * s, top + 0.21 * s, head.Z + 0.05 * s), V(0.14 * s, 0.04, headSize.Z + 0.06 * s), GOLD, { Material = METAL })
		end
		for _, side in ipairs({ -1, 1 }) do
			for k = 0, 3 do
				box(model, V(side * (half + 0.08 * s), head.Y + 0.35 * s - k * 0.3 * s, head.Z + 0.05 * s), V(0.14, 0.3, 0.9) * s, if k % 2 == 0 then blue else GOLD, if k % 2 == 1 then { Material = METAL } else nil)
			end
		end
		box(model, V(0, top - 0.12 * s, front - 0.04), V(0.2, 0.26, 0.08) * s, GOLD, { Material = METAL })
		box(model, V(0, top - 0.04 * s, front - 0.09), V(0.08, 0.08, 0.05) * s, Color3.fromRGB(60, 200, 255), { Material = GLASS })
	end
	if spec.Mane then
		local outer = if spec.Mane == "gold" then GOLD_DEEP elseif spec.Mane == "leaf" then Color3.fromRGB(70, 170, 80) else Color3.fromRGB(230, 150, 230)
		local inner = if spec.Mane == "gold" then GOLD elseif spec.Mane == "leaf" then Color3.fromRGB(130, 220, 110) else Color3.fromRGB(255, 200, 245)
		for k = 0, 11 do
			local a = k / 12 * math.pi * 2
			local cf = CFrame.new(head + V(math.cos(a) * 0.98 * s, math.sin(a) * 0.86 * s, 0.25 * s)) * CFrame.Angles(0, 0, a + math.rad(45))
			box(model, cf, V(0.5, 0.5, 0.5) * s, if k % 2 == 0 then outer else inner)
		end
		if spec.Mane == "leaf" then
			for _, side in ipairs({ -1, 1 }) do
				box(model, CFrame.new(side * 0.45 * s, top + 0.12 * s, head.Z + 0.2 * s) * CFrame.Angles(0, 0, math.rad(side * -40)), V(0.34, 0.1, 0.22) * s, inner)
			end
		end
	end
	if spec.Star then
		for _, a in ipairs({ 0, 45 }) do
			box(model, CFrame.new(0, head.Y + 0.55 * u, front - 0.03) * CFrame.Angles(0, 0, math.rad(a)), V(0.2, 0.2, 0.05) * s, GOLD, { Material = METAL })
		end
	end

	-- coats and markings
	local backY = bodyY + bodySize.Y / 2
	if spec.Stripes then
		for k = -1, 1 do
			local z = bodyZ + k * 0.45 * s
			box(model, V(0, backY + 0.01, z), V(bodySize.X * 0.7, 0.04, 0.16 * s), INK)
			for _, side in ipairs({ -1, 1 }) do
				box(model, CFrame.new(side * (bodySize.X / 2 + 0.01), backY - 0.3 * s, z) * CFrame.Angles(math.rad(12), 0, 0), V(0.04, 0.5 * s, 0.14 * s), INK)
			end
		end
		for k = -1, 1 do
			box(model, V(k * 0.22 * s, head.Y + 0.6 * s, front - 0.012), V(0.08, 0.22 - math.abs(k) * 0.06, 0.04) * s, INK)
		end
	end
	if spec.Spots then
		local spot = if ctx.Name == "Deer" then WHITE else c:Lerp(INK, 0.55)
		for k = 1, 7 do
			local a = k * 2.1
			box(model, V(math.cos(a) * 0.45 * s, backY + 0.01, bodyZ + math.sin(a) * 0.6 * s), V(0.2, 0.04, 0.2) * s, spot)
		end
		for _, side in ipairs({ -1, 1 }) do
			for k = 0, 1 do
				box(model, V(side * (bodySize.X / 2 + 0.01), bodyY + 0.15 * s - k * 0.3 * s, bodyZ + (k - 0.3) * 0.5 * s), V(0.04, 0.18, 0.18) * s, spot)
			end
		end
	end
	if spec.Wool then
		local wool = WHITE:Lerp(c, 0.25)
		local spots = { { -0.5, 0.2, -0.3 }, { 0.5, 0.2, -0.3 }, { 0, 0.4, 0 }, { -0.5, 0.15, 0.5 }, { 0.5, 0.15, 0.5 }, { 0, 0.35, 0.65 }, { -0.62, -0.2, 0.1 }, { 0.62, -0.2, 0.1 } }
		for _, o in ipairs(spots) do
			chunk(model, V(o[1] * s, backY + o[2] * s - 0.2 * s, bodyZ + o[3] * s), V(0.68, 0.6, 0.68) * s, wool, 0.12 * s)
		end
		chunk(model, V(0, top + 0.12 * s, head.Z + 0.05 * s), V(0.8, 0.36, 0.7) * s, wool, 0.1 * s)
	end
	if spec.Spikes then
		for row = 0, 2 do
			for k = -2, 2 do
				local p = V(k * 0.3 * s, backY + 0.08 * s - math.abs(k) * 0.05 * s, bodyZ + (row - 0.8) * 0.48 * s)
				local cf = CFrame.new(p) * CFrame.Angles(math.rad(-30), 0, math.rad(k * -14))
				box(model, cf * CFrame.new(0, 0.1 * s, 0), V(0.2, 0.3, 0.2) * s, dark)
				box(model, cf * CFrame.new(0, 0.3 * s, 0), V(0.1, 0.16, 0.1) * s, light)
			end
		end
	end
	if spec.Shell then
		local scarab = ctx.Name == "Golden Scarab"
		local shellColor = if scarab then GOLD else Color3.fromRGB(110, 165, 85)
		local plate = if scarab then Color3.fromRGB(255, 232, 130) else Color3.fromRGB(160, 200, 105)
		local props = if scarab then { Material = METAL } else nil
		chunk(model, V(0, backY + 0.1 * s, bodyZ), V(bodySize.X + 0.3 * s, 0.75 * s, bodySize.Z * 0.92), shellColor, 0.25 * s, props)
		box(model, V(0, backY - 0.25 * s, bodyZ), V(bodySize.X + 0.36 * s, 0.12 * s, bodySize.Z * 0.95), shellColor:Lerp(INK, 0.3), props)
		for x = -1, 1, 2 do
			for z = -1, 1, 2 do
				box(model, V(x * 0.36 * s, backY + 0.49 * s, bodyZ + z * 0.42 * s), V(0.58, 0.04, 0.68) * s, plate, props)
			end
		end
		if scarab then
			box(model, CFrame.new(0, backY + 0.53 * s, bodyZ) * CFrame.Angles(0, math.rad(45), 0), V(0.3, 0.08, 0.3) * s, Color3.fromRGB(40, 140, 255), { Material = GLASS })
		end
	end
	if spec.Hump then
		chunk(model, V(0, backY + 0.25 * s, bodyZ + 0.1 * s), V(0.95, 0.7, 0.95) * s, c, 0.22 * s)
		box(model, V(0, backY + 0.61 * s, bodyZ + 0.1 * s), V(0.5, 0.04, 0.5) * s, dark)
	end
	if spec.Pincers then
		for _, side in ipairs({ -1, 1 }) do
			local a = V(side * 0.6 * s, bodyY, chestZ + 0.1)
			local b = a + V(side * 0.35, 0.1, -0.7) * s
			beam(model, a, b, 0.24 * s, c)
			box(model, CFrame.new(b + V(side * 0.1 * s, 0.1 * s, -0.22 * s)) * CFrame.Angles(0, math.rad(side * 15), 0), V(0.22, 0.2, 0.5) * s, light)
			box(model, CFrame.new(b + V(side * -0.08 * s, 0.05 * s, -0.2 * s)) * CFrame.Angles(0, math.rad(side * -20), 0), V(0.16, 0.16, 0.4) * s, light)
		end
	end
	-- wings (dragons and the scarab)
	if spec.Wings then
		local scarab = ctx.Name == "Golden Scarab"
		for _, side in ipairs({ -1, 1 }) do
			local shoulder = V(side * 0.7 * s, backY - 0.05 * s, bodyZ - 0.2 * s)
			local parts
			if scarab then
				parts = { box(model, CFrame.new(shoulder + V(side * 0.45 * s, 0.3 * s, 0.35 * s)) * CFrame.Angles(0, 0, math.rad(side * -30)), V(0.06, 0.6, 1.3) * s, Color3.fromRGB(200, 235, 255), { Material = GLASS, Transparency = 0.35 }) }
			else
				local tip = shoulder + V(side * 1.3, 0.55, 0.25) * s
				parts = { beam(model, shoulder, tip, 0.16 * s, dark) }
				for k = 0, 2 do
					local along = shoulder:Lerp(tip, 0.3 + k * 0.32)
					table.insert(parts, box(model, CFrame.new(along + V(0, -0.25 * s, 0.2 * s)) * CFrame.Angles(0, 0, math.rad(side * -22)), V(0.42, 0.06, 0.9 - k * 0.2) * s, light:Lerp(ctx.Accent, 0.15)))
				end
			end
			table.insert(rig.Wings, { Parts = parts, Shoulder = shoulder, Side = side })
		end
	end

	-- tail
	local tailBase = V(0, bodyY + 0.2 * s, bodyZ + bodySize.Z / 2 - 0.05 * s)
	local tail = {}
	if spec.Tail == "fluffy" or spec.Tail == "bushy" or spec.Tail == "ringed" then
		local big = if spec.Tail == "bushy" then 1.35 else 1
		local steps = { { 0, 0.22, 0.22, 0.42 }, { 0, 0.58, 0.42, 0.56 }, { 0, 0.94, 0.5, 0.5 }, { 0, 1.22, 0.46, 0.36 } }
		for k, o in ipairs(steps) do
			local color = if spec.Tail == "ringed" then (if k % 2 == 0 then c:Lerp(INK, 0.55) else c) elseif k == #steps then light else c
			local _, parts = chunk(model, tailBase + V(o[1], o[2] * big, o[3]) * s, V(o[4], o[4], o[4]) * s * big, color, 0.06 * s)
			append(tail, parts)
		end
	elseif spec.Tail == "curl" then
		for k, o in ipairs({ { 0.25, 0.15, 0.4 }, { 0.6, 0.15, 0.42 }, { 0.82, -0.15, 0.38 }, { 0.72, -0.42, 0.3 } }) do
			table.insert(tail, box(model, tailBase + V(0, o[1], o[2]) * s, V(o[3], o[3], o[3]) * s, if k == 4 then light else c))
		end
	elseif spec.Tail == "nine" then
		for k = -2, 2 do
			local a = tailBase + V(0, 0.15, 0.15) * s
			local b = a + V(k * 0.32, 0.85 - math.abs(k) * 0.12, 0.45) * s
			table.insert(tail, beam(model, a, b, 0.3 * s, c))
			table.insert(tail, box(model, b + V(0, 0.08, 0.05) * s, V(0.34, 0.34, 0.34) * s, Color3.fromRGB(255, 225, 240)))
		end
	elseif spec.Tail == "puff" then
		local _, parts = chunk(model, tailBase + V(0, 0.05, 0.12) * s, V(0.45, 0.45, 0.4) * s, light, 0.1 * s)
		append(tail, parts)
	elseif spec.Tail == "spiky" then
		local a, b, d = tailBase, tailBase + V(0, 0.1, 0.7) * s, tailBase + V(0, 0.3, 1.25) * s
		table.insert(tail, beam(model, a, b, 0.38 * s, c))
		table.insert(tail, beam(model, b, d, 0.28 * s, c))
		for k = 0, 2 do
			local p = a:Lerp(d, 0.2 + k * 0.33)
			table.insert(tail, box(model, CFrame.new(p + V(0, 0.2 * s, 0)) * CFrame.Angles(math.rad(45), 0, 0), V(0.08, 0.22, 0.22) * s, IVORY))
		end
		table.insert(tail, box(model, CFrame.new(d + V(0, 0, 0.12 * s)) * CFrame.Angles(math.rad(45), 0, 0), V(0.1, 0.36, 0.36) * s, light))
	elseif spec.Tail == "stinger" then
		local a, b, d = tailBase, tailBase + V(0, 0.75, 0.45) * s, tailBase + V(0, 1.25, 0.05) * s
		table.insert(tail, beam(model, a, b, 0.3 * s, c))
		table.insert(tail, beam(model, b, d, 0.26 * s, c))
		table.insert(tail, box(model, CFrame.new(d + V(0, 0.05, -0.18) * s) * CFrame.Angles(math.rad(-50), 0, 0), V(0.22, 0.22, 0.36) * s, Color3.fromRGB(255, 196, 60)))
	elseif spec.Tail ~= "none" then -- long / thin / wag
		local w = (if spec.Tail == "thin" then 0.14 else 0.24) * s
		local a, b, d = tailBase, tailBase + V(0, 0.35, 0.45) * s, tailBase + V(0, 0.85, 0.55) * s
		table.insert(tail, beam(model, a, b, w, c))
		table.insert(tail, beam(model, b, d, w, c))
		table.insert(tail, box(model, d, V(w * 1.4, w * 1.4, w * 1.4), if spec.Tail == "thin" then dark else light))
	end
	if #tail > 0 then
		rig.Tail = { Parts = tail, Base = tailBase }
	end
	return head, {
		Collar = CFrame.new(0, head.Y - headSize.Y / 2 - 0.04 * s, chestZ + 0.25 * s),
		CollarSize = V(bodySize.X + 0.08, 0.16 * s, 0.7 * s),
		Chest = V(0, head.Y - headSize.Y / 2 - 0.16 * s, chestZ - 0.12 * s),
		Back = V(0, backY, bodyZ + 0.15 * s),
		BackSize = V(bodySize.X, 0, bodySize.Z * 0.8),
		Crown = V(0, top + (if spec.Ears == "long" then 0.05 else 0) * s, head.Z),
		Scale = s,
	}
end

local function bird(ctx)
	local model, spec, rig = ctx.Model, ctx.Spec, ctx.Rig
	local c, light, dark = ctx.Color, ctx.Light, ctx.Dark
	local s = if spec.Small then 0.85 else 1
	local legLength = (if spec.LongLegs then 1.0 else 0.3) * s
	local bodyY = legLength - 0.3 * s
	local bodySize = V(1.5, 1.35, 1.5) * s
	local bodyZ = 0.1 * s
	chunk(model, V(0, bodyY, bodyZ), bodySize, c, 0.24 * s)
	local chestZ = bodyZ - bodySize.Z / 2
	local belly = if spec.Belly then WHITE else light
	chunk(model, V(0, bodyY - 0.12 * s, chestZ - 0.04), V(1.0, 0.95, 0.12) * s, belly, 0.04)
	-- chest feathers in layers
	for k = 0, 2 do
		box(model, CFrame.new((k - 1) * 0.26 * s, bodyY + 0.3 * s - math.abs(k - 1) * 0.06 * s, chestZ - 0.09) * CFrame.Angles(0, 0, math.rad(45)), V(0.22, 0.22, 0.05) * s, belly:Lerp(WHITE, 0.3))
	end

	local headSize = V(1.4, 1.3, 1.3) * s
	local head = V(0, bodyY + bodySize.Y / 2 + headSize.Y / 2 - 0.25 * s, -0.2 * s)
	chunk(model, head, headSize, c, 0.16 * s)
	local top = head.Y + headSize.Y / 2
	local front = head.Z - headSize.Z / 2
	local u = 0.78 * s
	local f = V(0, head.Y + 0.02 * s, front)
	if spec.Crest == "tufts" then -- owls and griffins: a soft facial disc
		box(model, V(0, head.Y + 0.08 * s, front - 0.01), V(headSize.X * 0.86, 0.68 * s, 0.03), WHITE:Lerp(c, 0.45))
	end
	if spec.Belly then -- penguins: a white face
		box(model, V(0, head.Y - 0.12 * s, front - 0.01), V(headSize.X * 0.7, 0.62 * s, 0.03), WHITE)
	end
	face(model, f, u, spec, ctx.Accent, f + V(0, -0.2 * u, 0), true, if spec.Belly then WHITE else c)

	-- wings (or flippers), flapping from the shoulder
	for _, side in ipairs({ -1, 1 }) do
		local shoulder = V(side * bodySize.X / 2, bodyY + 0.3 * s, bodyZ - 0.05 * s)
		local parts = {}
		if spec.Flippers then
			table.insert(parts, box(model, CFrame.new(side * (bodySize.X / 2 + 0.07 * s), bodyY - 0.1 * s, bodyZ) * CFrame.Angles(0, 0, math.rad(side * 16)), V(0.15, 0.95, 0.55) * s, c))
		else
			local big = if spec.BigWings then 1.3 else 1
			local wingColor = if spec.Rainbow then Color3.fromRGB(60, 140, 255) elseif spec.Icy then Color3.fromRGB(190, 236, 255) else c
			local mid = if spec.Rainbow then Color3.fromRGB(255, 210, 50) elseif spec.Icy then Color3.fromRGB(150, 215, 255) else c:Lerp(light, 0.4)
			local tip = if spec.Rainbow then Color3.fromRGB(255, 70, 80) elseif spec.Icy then WHITE else dark
			local x = side * (bodySize.X / 2 + 0.07 * s)
			table.insert(parts, box(model, V(x, bodyY + 0.12 * s, bodyZ + 0.05 * s), V(0.16, 0.78 * big, 0.9 * big) * s, wingColor))
			table.insert(parts, box(model, V(x + side * 0.02, bodyY - 0.12 * s * big, bodyZ + 0.25 * s * big), V(0.14, 0.42, 0.85) * s * big, mid))
			table.insert(parts, box(model, V(x + side * 0.03, bodyY - 0.3 * s * big, bodyZ + 0.45 * s * big), V(0.12, 0.24, 0.7) * s * big, tip))
		end
		table.insert(rig.Wings, { Parts = parts, Shoulder = shoulder, Side = side })
		-- legs and three-toed feet
		local hip = V(side * 0.35 * s, bodyY - bodySize.Y / 2 + 0.05 * s, bodyZ)
		local legH = legLength + 0.08 * s
		local foot = hip - V(0, legH, 0)
		local legParts = { box(model, hip - V(0, legH / 2, 0), V(0.13, legH, 0.13) * s, ORANGE) }
		for k = -1, 1 do
			table.insert(legParts, box(model, CFrame.new(foot + V(0, 0.04 * s, 0)) * CFrame.Angles(0, math.rad(k * 28), 0) * CFrame.new(0, 0, -0.15 * s), V(0.1, 0.08, 0.32) * s, ORANGE))
		end
		if ctx.Trim then
			table.insert(legParts, box(model, hip - V(0, legH * 0.55, 0), V(0.2, 0.1, 0.2) * s, ctx.Trim, { Material = METAL }))
		end
		table.insert(rig.Legs, { Parts = legParts, Hip = hip, Phase = if side < 0 then 0 else math.pi, Front = true })
		rig.FootY = foot.Y
	end
	if spec.Crest == "tuft" then
		local tuftColor = if spec.Rainbow then Color3.fromRGB(255, 210, 50) else light
		for k = 0, 2 do
			box(model, CFrame.new(0, top + 0.1 * s + k * 0.08 * s, head.Z + (k - 1) * 0.15 * s) * CFrame.Angles(math.rad(-20 + k * 20), 0, 0), V(0.14, 0.32 - k * 0.06, 0.12) * s, tuftColor)
		end
	elseif spec.Crest == "dot" then
		box(model, V(0, top + 0.02 * s, head.Z), V(0.5, 0.08, 0.5) * s, Color3.fromRGB(235, 50, 60))
	elseif spec.Crest == "tufts" then
		for _, side in ipairs({ -1, 1 }) do
			box(model, CFrame.new(side * 0.5 * s, top + 0.12 * s, head.Z) * CFrame.Angles(0, 0, math.rad(side * -25)), V(0.24, 0.42, 0.22) * s, dark)
		end
	elseif spec.Crest == "flame" then
		local flame = if spec.Icy then Color3.fromRGB(160, 230, 255) else Color3.fromRGB(255, 196, 60)
		local core = if spec.Icy then WHITE else Color3.fromRGB(255, 120, 60)
		for k = -1, 1 do
			local cf = CFrame.new(k * 0.22 * s, top + 0.25 * s, head.Z + 0.1 * s) * CFrame.Angles(math.rad(-15), 0, math.rad(k * -18))
			box(model, cf, V(0.2, 0.6 - math.abs(k) * 0.2, 0.24) * s, flame)
			box(model, cf * CFrame.new(0, -0.08 * s, -0.04 * s), V(0.1, 0.3 - math.abs(k) * 0.1, 0.2) * s, core)
		end
	end
	-- tail feathers
	local tailBase = V(0, bodyY + 0.05 * s, bodyZ + bodySize.Z / 2 - 0.1 * s)
	local tail = {}
	for k = -1, 1 do
		local length = (if spec.LongTail then 1.5 else 0.55) * s
		local color = if spec.LongTail then (if spec.Icy then Color3.fromRGB(160, 230, 255) elseif spec.Rainbow then Color3.fromRGB(255, 90 + k * 60, 80) else Color3.fromRGB(255, 176, 60)) else dark
		local cf = CFrame.new(tailBase) * CFrame.Angles(math.rad(18), math.rad(k * 16), 0) * CFrame.new(0, 0, length / 2)
		table.insert(tail, box(model, cf, V(0.24 * s, 0.1 * s, length), color))
		if spec.LongTail then
			table.insert(tail, box(model, cf * CFrame.new(0, 0.01, length / 2 - 0.1 * s), V(0.3 * s, 0.11 * s, 0.24 * s), WHITE:Lerp(color, 0.4)))
		end
	end
	if spec.LionTail then
		local a, b = tailBase, tailBase + V(0, 0.55, 0.75) * s
		table.insert(tail, beam(model, a, b, 0.22 * s, c))
		table.insert(tail, box(model, b, V(0.38, 0.38, 0.38) * s, dark))
	end
	rig.Tail = { Parts = tail, Base = tailBase }
	return head, {
		Collar = CFrame.new(0, head.Y - headSize.Y / 2 - 0.02 * s, chestZ + 0.3 * s),
		CollarSize = V(bodySize.X * 0.9, 0.16 * s, 0.84 * s),
		Chest = V(0, head.Y - headSize.Y / 2 - 0.14 * s, chestZ - 0.14 * s),
		Back = V(0, bodyY + bodySize.Y / 2, bodyZ + 0.25 * s),
		BackSize = V(bodySize.X * 0.9, 0, bodySize.Z * 0.6),
		Crown = V(0, top, head.Z),
		Scale = s,
	}
end

local function frog(ctx)
	local model, spec, rig = ctx.Model, ctx.Spec, ctx.Rig
	local c, light, dark = ctx.Color, ctx.Light, ctx.Dark
	chunk(model, V(0, -0.15, 0.1), V(2.0, 1.1, 1.8), c, 0.3)
	box(model, V(0, -0.3, -0.81), V(1.4, 0.6, 0.06), light)
	-- spots on the back
	for k, o in ipairs({ { -0.45, 0.3 }, { 0.5, 0.55 }, { 0.1, 0.0 }, { -0.2, 0.7 } }) do
		box(model, V(o[1], 0.41, o[2]), V(0.26, 0.04, 0.26) * (if k % 2 == 0 then 0.8 else 1), dark)
	end
	-- the eyes sit on two bumps on top
	local bumps = {}
	for _, side in ipairs({ -1, 1 }) do
		local bump = V(side * 0.5, 0.6, -0.5)
		chunk(model, bump, V(0.66, 0.6, 0.6), c, 0.14)
		table.insert(bumps, bump)
		local f = bump + V(0, 0, -0.3)
		eye(model, f + V(0, 0.02, 0), 0.9, spec.Eyes, Color3.fromRGB(255, 196, 60), side)
		box(model, V(side * 0.72, 0.1, -0.815), V(0.26, 0.12, 0.04), BLUSH)
	end
	-- a wide happy smile across the front
	box(model, V(0, -0.06, -0.825), V(0.9, 0.06, 0.05), INK)
	for _, side in ipairs({ -1, 1 }) do
		box(model, CFrame.new(side * 0.47, -0.02, -0.825) * CFrame.Angles(0, 0, math.rad(side * 30)), V(0.12, 0.06, 0.05), INK)
	end
	-- legs: little front legs, big folded back legs with webbed feet
	local footY = 0
	for i, leg in ipairs({ { -0.6, -0.5, 0, false }, { 0.6, -0.5, 0, false }, { -0.95, 0.5, 0, true }, { 0.95, 0.5, 0, true } }) do
		local hip = V(leg[1], -0.55, leg[2])
		local parts
		if leg[4] then
			local _, haunch = chunk(model, hip + V(0, 0.15, 0.05), V(0.5, 0.6, 0.85), c, 0.12)
			parts = haunch
			table.insert(parts, box(model, hip + V(leg[1] * 0.12, -0.18, -0.25), V(0.55, 0.12, 0.6), light))
		else
			parts = { box(model, hip + V(0, -0.1, 0), V(0.3, 0.3, 0.3), c), box(model, hip + V(0, -0.24, -0.12), V(0.42, 0.12, 0.44), light) }
		end
		if ctx.Trim then
			table.insert(parts, box(model, hip + V(0, 0.02, 0), V(0.36, 0.1, 0.36), ctx.Trim, { Material = METAL }))
		end
		footY = math.min(footY, hip.Y - 0.3)
		table.insert(rig.Legs, { Parts = parts, Hip = hip, Phase = 0, Front = i <= 2 })
	end
	rig.FootY = footY
	local head = V(0, 0.3, -0.4)
	return head, {
		Collar = CFrame.new(0, -0.45, -0.25),
		CollarSize = V(2.06, 0.14, 1.2),
		Chest = V(0, -0.56, -0.88),
		Back = V(0, 0.4, 0.3),
		BackSize = V(1.6, 0, 1.2),
		Crown = V(0, 0.9, -0.5),
		Scale = 1,
	}
end

local function kraken(ctx)
	local model, spec, rig = ctx.Model, ctx.Spec, ctx.Rig
	local c, light = ctx.Color, ctx.Light
	local head = V(0, 0.6, 0)
	local headSize = V(1.8, 1.9, 1.7)
	chunk(model, head, headSize, c, 0.32)
	chunk(model, head + V(0, 1.05, 0.15), V(1.4, 0.55, 1.3), c, 0.22)
	for k, o in ipairs({ { -0.4, 1.33, 0.1 }, { 0.35, 1.33, 0.45 }, { 0.15, 1.33, -0.2 } }) do
		box(model, head + V(o[1], o[2], o[3]), V(0.24, 0.04, 0.24) * (if k == 2 then 0.8 else 1), light)
	end
	local front = head.Z - headSize.Z / 2
	face(model, V(0, head.Y - 0.05, front), 0.95, spec, ctx.Accent, nil, nil, c)
	-- six tentacles, each a chain of shrinking blocks with suckers
	local footY = 0
	for k = 0, 5 do
		local a = k / 6 * math.pi * 2 + math.pi / 6
		local dir = V(math.cos(a), 0, math.sin(a))
		local hip = head + dir * 0.55 - V(0, 0.85, 0)
		local parts = {}
		for j = 0, 3 do
			local w = 0.5 - j * 0.08
			local p = hip + dir * (j * 0.3) - V(0, j * 0.1 - math.max(j - 2, 0) * 0.25, 0)
			table.insert(parts, box(model, p, V(w, w, w), if j % 2 == 0 then c else c:Lerp(light, 0.4)))
			table.insert(parts, box(model, p + V(0, -w / 2 - 0.01, 0), V(w * 0.45, 0.04, w * 0.45), light))
			footY = math.min(footY, p.Y - w / 2 - 0.03)
		end
		table.insert(rig.Legs, { Parts = parts, Hip = hip, Phase = k * 1.05, Front = true })
	end
	rig.FootY = footY
	return head, {
		Collar = CFrame.new(0, head.Y - 0.8, 0),
		CollarSize = V(headSize.X + 0.06, 0.18, headSize.Z + 0.06),
		Chest = V(0, head.Y - 0.9, front - 0.04),
		Back = head + V(0, 1.32, 0.3),
		BackSize = V(1.2, 0, 0.8),
		Crown = head + V(0, 1.32, 0.15),
		Scale = 1,
	}
end

local function serpent(ctx)
	local model, spec, rig = ctx.Model, ctx.Spec, ctx.Rig
	local c, light, dark = ctx.Color, ctx.Light, ctx.Dark
	-- a body of shrinking blocks trailing behind the head, waving side to
	-- side as it slithers (each segment is a "leg" with its own phase)
	local footY = 0
	for k = 0, 6 do
		local w = 0.95 - k * 0.09
		local p = V(0, -0.65 + w / 2 - 0.45, 0.3 + k * 0.62)
		local _, parts = chunk(model, p, V(w, w, 0.7), if k % 2 == 0 then c else c:Lerp(dark, 0.4), 0.12)
		table.insert(parts, box(model, p + V(0, -w / 2 + 0.02, 0), V(w * 0.7, 0.06, 0.6), light))
		if k == 6 then
			table.insert(parts, box(model, p + V(0, 0, 0.45), V(w * 0.6, w * 0.6, 0.3), dark))
		end
		footY = math.min(footY, p.Y - w / 2)
		table.insert(rig.Legs, { Parts = parts, Hip = p, Phase = k * 0.9, Segment = k })
	end
	rig.FootY = footY
	local head = V(0, 0.5, -0.4)
	local headSize = V(1.3, 1.05, 1.3)
	beam(model, V(0, -0.6, 0.25), head, 0.75, c)
	box(model, V(0, -0.1, -0.15), V(0.5, 0.9, 0.06), light)
	chunk(model, head, headSize, c, 0.22)
	local front = head.Z - headSize.Z / 2
	if spec.Hood then
		local hood = c:Lerp(ORANGE, 0.25)
		for k, w in ipairs({ 1.3, 1.9, 2.1, 1.8, 1.2 }) do
			local y = head.Y + 0.45 - k * 0.3
			box(model, V(0, y, head.Z + 0.5), V(w, 0.32, 0.14), hood)
			box(model, V(0, y, head.Z + 0.42), V(w * 0.62, 0.32, 0.04), light)
		end
		for _, side in ipairs({ -1, 1 }) do
			box(model, V(side * 0.72, head.Y - 0.3, head.Z + 0.42), V(0.22, 0.22, 0.05), INK)
			box(model, V(side * 0.72, head.Y - 0.3, head.Z + 0.39), V(0.1, 0.1, 0.04), WHITE)
		end
	end
	if spec.Horns then
		for _, side in ipairs({ -1, 1 }) do
			local a = head + V(side * 0.42, 0.45, 0.2)
			local b = a + V(side * 0.25, 0.5, 0.35)
			beam(model, a, b, 0.2, Color3.fromRGB(190, 120, 255))
			beam(model, b, b + V(side * 0.05, 0.3, 0.3), 0.12, Color3.fromRGB(240, 210, 255))
		end
	end
	local u = 0.78
	face(model, V(0, head.Y, front), u, spec, ctx.Accent, nil, nil, c)
	-- a little forked tongue
	box(model, V(0, head.Y - 0.34, front - 0.12), V(0.08, 0.04, 0.24), Color3.fromRGB(255, 90, 120))
	for _, side in ipairs({ -1, 1 }) do
		box(model, CFrame.new(side * 0.05, head.Y - 0.34, front - 0.27) * CFrame.Angles(0, math.rad(side * 30), 0), V(0.05, 0.04, 0.1), Color3.fromRGB(255, 90, 120))
	end
	return head, {
		Collar = CFrame.new(0, -0.05, -0.08),
		CollarSize = V(0.9, 0.16, 0.9),
		Chest = V(0, -0.16, -0.58),
		Back = V(0, -0.1, 1.1),
		BackSize = V(0.8, 0, 1.0),
		Crown = V(0, head.Y + headSize.Y / 2, head.Z),
		Scale = 1,
	}
end

local function whale(ctx)
	local model, spec, rig = ctx.Model, ctx.Spec, ctx.Rig
	local c, light, dark = ctx.Color, ctx.Light, ctx.Dark
	local s = if spec.Small then 0.7 else 1
	local bodySize = V(1.9, 1.6, 2.0) * s
	local bodyC = V(0, 0.1, -0.2) * s
	chunk(model, bodyC, bodySize, c, 0.25 * s)
	chunk(model, V(0, 0.05, 1.0) * s, V(1.5, 1.3, 1.2) * s, c, 0.26 * s)
	chunk(model, V(0, 0, 1.75) * s, V(0.9, 0.8, 0.8) * s, c, 0.18 * s)
	local bellyColor = if spec.Pattern == "orca" then WHITE else light
	box(model, V(0, 0.1 - bodySize.Y / 2 + 0.02 * s, -0.2 * s), V(bodySize.X * 0.72, 0.06, bodySize.Z * 0.85), bellyColor)
	local front = bodyC.Z - bodySize.Z / 2
	box(model, V(0, -0.25 * s, front - 0.01), V(1.2 * s, 0.4 * s, 0.04), bellyColor)
	if spec.Pattern ~= "koi" and spec.Pattern ~= "galaxy" then
		for k = -1, 1 do
			box(model, V(k * 0.22 * s, -0.27 * s, front - 0.035), V(0.05 * s, 0.3 * s, 0.03), bellyColor:Lerp(INK, 0.15))
		end
	end
	-- fins and the tail flukes
	for _, side in ipairs({ -1, 1 }) do
		local fin = box(model, CFrame.new(side * (bodySize.X / 2 + 0.3 * s), -0.3 * s, -0.25 * s) * CFrame.Angles(0, math.rad(side * -15), math.rad(side * -25)), V(0.7, 0.12, 0.45) * s, dark)
		table.insert(rig.Wings, { Parts = { fin }, Shoulder = V(side * bodySize.X / 2, -0.25 * s, -0.25 * s), Side = side, Fin = true })
	end
	local tail = {}
	for _, side in ipairs({ -1, 1 }) do
		table.insert(tail, box(model, CFrame.new(side * 0.42 * s, 0.05 * s, 2.25 * s) * CFrame.Angles(0, math.rad(side * 28), 0), V(0.8, 0.12, 0.45) * s, dark))
	end
	rig.Tail = { Parts = tail, Base = V(0, 0, 1.4) * s, Vertical = true }
	-- the blowhole
	box(model, V(0, 0.1 * s + bodySize.Y / 2 + 0.01, 0.1 * s), V(0.24, 0.04, 0.12) * s, dark)
	if spec.Pattern == "galaxy" then
		for k = 1, 9 do
			local a = k * 1.3
			box(model, CFrame.new(V(math.cos(a) * 0.65, 0.92, math.sin(a) * 0.75 + 0.2) * s) * CFrame.Angles(0, math.rad(45), 0), V(0.12, 0.04, 0.12) * s * (if k % 3 == 0 then 1.6 else 1), if k % 3 == 0 then Color3.fromRGB(255, 220, 140) else Color3.fromRGB(210, 225, 255), { Material = NEON })
		end
		box(model, V(0, 0.91 * s, 0.4 * s), V(1.2, 0.03, 0.4) * s, Color3.fromRGB(150, 110, 230))
	elseif spec.Pattern == "spots" then
		for k = 1, 7 do
			local a = k * 1.7
			box(model, V(math.cos(a) * 0.6, 0.91, math.sin(a) * 0.7) * s, V(0.18, 0.04, 0.18) * s, WHITE:Lerp(c, 0.3))
		end
	elseif spec.Pattern == "orca" then
		for _, side in ipairs({ -1, 1 }) do
			box(model, V(side * (bodySize.X / 2 + 0.01), 0.35 * s, -0.75 * s), V(0.04, 0.32, 0.55) * s, WHITE)
		end
		box(model, CFrame.new(0, 1.0 * s, 0.35 * s) * CFrame.Angles(math.rad(-30), 0, 0), V(0.14, 0.7, 0.5) * s, c)
	elseif spec.Pattern == "koi" then
		for k, o in ipairs({ { -0.3, 0.95, -0.3 }, { 0.35, 0.85, 0.6 }, { 0, 0.75, 1.5 } }) do
			box(model, V(o[1], o[2] * 0.97, o[3]) * s, V(0.6, 0.05, 0.6) * s * (if k == 3 then 0.7 else 1), WHITE)
		end
		for _, side in ipairs({ -1, 1 }) do
			beam(model, V(side * 0.35, -0.25, front / s - 0.02) * s, V(side * 0.6, -0.55, front / s - 0.3) * s, 0.06 * s, light)
		end
		box(model, V(0, 0.75 * s, 0.6 * s), V(0.1, 0.4, 1.4) * s, dark)
	end
	if spec.Horn then
		local base = V(0, 0.45 * s, front - 0.02)
		local cf = CFrame.lookAt(base, base + V(0, 0.25, -1))
		for k = 0, 4 do
			local w = (0.24 - k * 0.04) * s
			box(model, cf * CFrame.new(0, 0, -(k + 0.5) * 0.3 * s) * CFrame.Angles(0, 0, math.rad(k * 30)), V(w, w, 0.32 * s), if k % 2 == 0 then IVORY else WHITE)
		end
	end
	if spec.Tusks then
		for _, side in ipairs({ -1, 1 }) do
			local a = V(side * 0.3 * s, -0.3 * s, front - 0.05)
			beam(model, a, a + V(side * 0.05, -0.75, -0.08) * s, 0.15 * s, IVORY)
		end
		chunk(model, V(0, -0.15 * s, front - 0.12 * s), V(0.9, 0.36, 0.24) * s, light, 0.08 * s)
	end
	if spec.Flippers then
		rig.FootY = 0.1 * s - bodySize.Y / 2
	end
	local u = 0.9 * s
	local f = V(0, 0.28 * s, front)
	face(model, f, u, spec, ctx.Accent, if spec.Tusks then f + V(0, -0.4 * u, -0.25 * s) else nil, nil, c)
	local head = V(0, 0.3 * s, -0.6 * s)
	return head, {
		Collar = CFrame.new(V(0, 0.1, 0.6) * s),
		CollarSize = V(1.86, 1.56, 0.22) * s,
		Chest = V(0, -0.32 * s, front - 0.05),
		Back = V(0, 0.1 * s + bodySize.Y / 2, 0.2 * s),
		BackSize = V(1.4 * s, 0, 1.2 * s),
		Crown = V(0, 0.1 * s + bodySize.Y / 2, -0.55 * s),
		Scale = s,
	}
end

local function glitch(ctx)
	local model, spec, rig = ctx.Model, ctx.Spec, ctx.Rig
	local navy, screen = Color3.fromRGB(34, 44, 78), Color3.fromRGB(18, 22, 40)
	chunk(model, V(0, -0.05, 0.1), V(1.7, 1.5, 1.7), navy, 0.2)
	local head = V(0, 1.2, -0.2)
	chunk(model, head, V(1.7, 1.45, 1.5), Color3.fromRGB(44, 58, 100), 0.22)
	local front = head.Z - 0.75
	box(model, V(0, head.Y, front - 0.01), V(1.35, 1.05, 0.04), screen)
	face(model, V(0, head.Y + 0.02, front - 0.02), 0.95, spec, ctx.Accent)
	-- glowing seams along the edges
	for _, x in ipairs({ -1, 1 }) do
		box(model, V(x * 0.86, -0.05, -0.76), V(0.06, 1.1, 0.06), ctx.Color, { Material = NEON })
		box(model, V(x * 0.86, head.Y, front + 0.02), V(0.06, 1.0, 0.06), ctx.Color, { Material = NEON })
	end
	-- an antenna and a few loose pixels
	beam(model, head + V(0.3, 0.72, 0), head + V(0.42, 1.15, 0.05), 0.08, Color3.fromRGB(120, 140, 190))
	box(model, head + V(0.42, 1.2, 0.05), V(0.2, 0.2, 0.2), ctx.Color, { Material = NEON })
	for k = 0, 3 do
		local a = k / 4 * math.pi * 2
		local bit = box(model, V(math.cos(a) * 1.5, 0.5 + (k % 2) * 0.6, math.sin(a) * 1.5), V(0.18, 0.18, 0.18), if k % 2 == 0 then ctx.Color else Color3.fromRGB(255, 120, 220), { Material = NEON })
		table.insert(ctx.Animated, { Part = bit, Kind = "orbit", Speed = 1.2 })
	end
	local footY = 0
	for _, x in ipairs({ -0.45, 0.45 }) do
		local hip = V(x, -0.6, 0.1)
		local parts = { box(model, V(x, -0.95, 0.1), V(0.45, 0.45, 0.5), navy), box(model, V(x, -1.2, 0.02), V(0.52, 0.12, 0.62), Color3.fromRGB(60, 76, 130)) }
		if ctx.Trim then
			table.insert(parts, box(model, V(x, -0.82, 0.1), V(0.5, 0.1, 0.55), ctx.Trim, { Material = METAL }))
		end
		footY = -1.26
		table.insert(rig.Legs, { Parts = parts, Hip = hip, Phase = if x < 0 then 0 else math.pi })
	end
	rig.FootY = footY
	return head, {
		Collar = CFrame.new(0, 0.55, -0.15),
		CollarSize = V(1.76, 0.16, 1.2),
		Chest = V(0, 0.42, -0.78),
		Back = V(0, 0.7, 0.4),
		BackSize = V(1.4, 0, 1.0),
		Crown = V(0, head.Y + 0.72, head.Z),
		Scale = 1,
	}
end

local BODIES = { beast = beast, bird = bird, frog = frog, kraken = kraken, serpent = serpent, whale = whale, glitch = glitch }

-- Accessories -----------------------------------------------------------------------------------

local function crown(model, at, s, animated)
	local r = 0.42 * s
	for k = 0, 3 do
		local a = k / 4 * math.pi * 2
		box(model, CFrame.new(at + V(math.cos(a) * r, 0.12 * s, math.sin(a) * r)) * CFrame.Angles(0, -a + math.pi / 2, 0), V(0.62 * s, 0.24 * s, 0.1 * s), GOLD, { Material = METAL })
	end
	for k = 0, 4 do
		local a = k / 5 * math.pi * 2 - math.pi / 2
		local p = at + V(math.cos(a) * r, 0.34 * s, math.sin(a) * r)
		box(model, p, V(0.14, 0.26, 0.14) * s, GOLD, { Material = METAL })
		local gem = box(model, CFrame.new(p + V(0, 0.2 * s, 0)) * CFrame.Angles(0, math.rad(45), math.rad(45)), V(0.14, 0.14, 0.14) * s, Color3.fromRGB(255, 90, 200), { Material = GLASS })
		table.insert(animated, { Part = gem, Kind = "rainbow" })
	end
	-- the big front jewel
	box(model, CFrame.new(at + V(0, 0.14 * s, -r - 0.07 * s)) * CFrame.Angles(0, 0, math.rad(45)), V(0.2, 0.2, 0.08) * s, Color3.fromRGB(80, 170, 255), { Material = GLASS })
end

local function cape(model, where, color, edge, ermine)
	local back, size = where.Back, where.BackSize
	local s = where.Scale
	local cf = CFrame.new(back + V(0, 0.05 * s, 0)) * CFrame.Angles(math.rad(-8), 0, 0)
	box(model, cf, V(size.X * 0.92, 0.06 * s, size.Z), color, { Material = FABRIC })
	-- it drapes down over the sides a little
	for _, side in ipairs({ -1, 1 }) do
		box(model, cf * CFrame.new(side * size.X * 0.46, -0.18 * s, 0), V(0.06 * s, 0.36 * s, size.Z * 0.95), color, { Material = FABRIC })
	end
	box(model, cf * CFrame.new(0, 0.01, size.Z / 2), V(size.X * 0.94, 0.08 * s, 0.1 * s), edge, if ermine then nil else { Material = METAL })
	if ermine then
		for k = -2, 2 do
			box(model, cf * CFrame.new(k * size.X * 0.18, 0.06 * s, size.Z / 2), V(0.06, 0.03, 0.08) * s, INK)
		end
	end
end

-- what a pet wears, by rarity level (1 common .. 7 secret) and size
local function dress(ctx, where, level, sizeIndex)
	local model, animated = ctx.Model, ctx.Animated
	local s = where.Scale
	local rarity = ctx.RarityColor
	local gold = sizeIndex >= 2
	-- the collar: leather with studs (gold for Huge and Titanic)
	local collarColor = if gold then GOLD else rarity:Lerp(INK, 0.35)
	box(model, where.Collar, where.CollarSize, collarColor, { Material = if gold then METAL else SMOOTH })
	local collarFront = where.Collar.Position + V(0, 0, -where.CollarSize.Z / 2)
	for k = -2, 2 do
		if k ~= 0 then
			box(model, collarFront + V(k * where.CollarSize.X * 0.18, 0, -0.03), V(0.07, 0.07, 0.05) * s, if gold then WHITE else GOLD, { Material = METAL })
		end
	end
	local chest = where.Chest
	if level >= 2 then
		-- a bandana tied under the collar
		box(model, CFrame.new(chest + V(0, 0.06 * s, 0.02)) * CFrame.Angles(0, 0, math.rad(45)), V(0.42, 0.42, 0.05) * s, rarity, { Material = FABRIC })
		for _, o in ipairs({ { -0.08, 0.02 }, { 0.09, -0.06 } }) do
			box(model, chest + V(o[1] * s, o[2] * s, -0.01), V(0.05, 0.05, 0.03) * s, WHITE)
		end
	end
	-- the tag: gold, or a gem for legendary and up
	local tagAt = chest + V(0, -0.06 * s, -0.06)
	if level >= 5 then
		box(model, CFrame.new(tagAt) * CFrame.Angles(0, 0, math.rad(45)), V(0.26, 0.26, 0.06) * s, GOLD, { Material = METAL })
		local gem = box(model, CFrame.new(tagAt + V(0, 0, -0.04)) * CFrame.Angles(0, 0, math.rad(45)), V(0.17, 0.17, 0.06) * s, rarity, { Material = GLASS })
		if level >= 7 then
			table.insert(animated, { Part = gem, Kind = "rainbow" })
		end
	else
		disc(model, tagAt, 0.26 * s, 0.05, V(0, 0, -1), GOLD, { Material = METAL })
		box(model, tagAt + V(0, 0, -0.035), V(0.08, 0.08, 0.02) * s, GOLD_DEEP)
	end
	-- back: a satchel (rare), a cape (epic and up), a royal cape (titanic);
	-- only animals with a back to wear them on
	local hasBack = ctx.Spec.Body == "beast" or ctx.Spec.Body == "bird" or ctx.Spec.Body == "glitch"
	if not hasBack then
		-- sea creatures and snakes get a little gold ribbon on top instead
		if level >= 3 or sizeIndex >= 3 then
			box(model, CFrame.new(where.Back + V(0, 0.03, 0)) * CFrame.Angles(0, math.rad(45), 0), V(0.3, 0.06, 0.3) * s, if sizeIndex >= 3 then VELVET else rarity, { Material = FABRIC })
			box(model, where.Back + V(0, 0.07, 0), V(0.14, 0.1, 0.14) * s, GOLD, { Material = METAL })
		end
	elseif sizeIndex >= 3 then
		cape(model, where, VELVET, WHITE, true)
	elseif level >= 4 then
		cape(model, where, rarity:Lerp(INK, 0.15), GOLD, false)
	elseif level >= 3 then
		local p = where.Back + V(0, 0.2 * s, 0)
		chunk(model, p, V(0.62, 0.4, 0.5) * s, LEATHER, 0.06 * s)
		box(model, p + V(0, 0.16 * s, -0.05 * s), V(0.66, 0.1, 0.45) * s, LEATHER:Lerp(WHITE, 0.2))
		box(model, p + V(0, 0.06 * s, -0.26 * s), V(0.1, 0.1, 0.04) * s, GOLD, { Material = METAL })
		box(model, where.Back + V(0, 0.02, -0.25 * s), V(where.BackSize.X + 0.04, 0.06 * s, 0.12 * s), LEATHER)
	end
	if level >= 5 then
		-- two gold stars circling the pet
		for k = 0, 1 do
			local a = k * math.pi
			local star = box(model, CFrame.new(math.cos(a) * 1.7, where.Crown.Y * 0.8, math.sin(a) * 1.7) * CFrame.Angles(0, 0, math.rad(45)), V(0.24, 0.24, 0.08), GOLD, { Material = METAL })
			table.insert(animated, { Part = star, Kind = "orbit", Speed = 1.4 })
		end
	end
	if level >= 6 and #ctx.Rig.Wings == 0 and (ctx.Spec.Body == "beast" or ctx.Spec.Body == "glitch") then
		-- soft feathered wings
		for _, side in ipairs({ -1, 1 }) do
			for k = 0, 2 do
				local p = where.Back + V(side * (where.BackSize.X * 0.4 + 0.25 * s + k * 0.12 * s), 0.35 * s - k * 0.12 * s, -0.1 * s + k * 0.22 * s)
				local feather = box(model, CFrame.new(p) * CFrame.Angles(math.rad(-15), 0, math.rad(side * (-35 + k * 12))), V(0.12, 0.7 - k * 0.12, 0.34) * s, WHITE:Lerp(rarity, 0.12 + k * 0.08))
				table.insert(animated, { Part = feather, Kind = "flap", Side = side })
			end
		end
	end
	if sizeIndex == 2 then
		-- a gold star badge on the chest
		for _, a in ipairs({ 0, 45 }) do
			box(model, CFrame.new(chest + V(0.3 * s, 0.14 * s, -0.04)) * CFrame.Angles(0, 0, math.rad(a)), V(0.14, 0.14, 0.04) * s, GOLD, { Material = METAL })
		end
	end
	if sizeIndex >= 3 then
		crown(model, where.Crown, s, animated)
		-- a gold chest plate with a big gem
		box(model, chest + V(0, 0.1 * s, -0.02), V(0.6, 0.36, 0.06) * s, GOLD, { Material = METAL })
		box(model, CFrame.new(chest + V(0, 0.1 * s, -0.07)) * CFrame.Angles(0, 0, math.rad(45)), V(0.2, 0.2, 0.06) * s, Color3.fromRGB(255, 60, 120), { Material = GLASS })
	end
	if level >= 7 then
		for _, entry in ipairs(animated) do
			if entry.Kind == "pulse" then
				entry.Kind = "rainbow"
			end
		end
	end
end

-- Building an animal --------------------------------------------------------------------------

-- plain = true builds a wild animal (no accessories, no sparkles) for the
-- ambient life and the hatch silhouettes
-- The aura (Pet Aura Machine): mini bees flying in a circle around the pet
-- in the aura's colour (rarer auras: more bees, rainbow bees, glowing
-- bees). Each bee's parts are "orbit" pieces, so Creature circles them
-- around the pet while it moves.
local BEE_COUNT = { 2, 2, 2, 3, 3, 4 } -- by aura rank (Config.AURAS order)
local RAINBOW = { Color3.fromRGB(255, 90, 90), Color3.fromRGB(255, 200, 60), Color3.fromRGB(90, 220, 120), Color3.fromRGB(90, 160, 255) }
local function auraBees(ctx, head, aura)
	local model = ctx.Model
	local rank = table.find(Config.AURAS, aura) or 1
	local count = BEE_COUNT[rank] or 2
	local s = if rank >= 6 then 1.3 elseif rank >= 4 then 1.12 else 1
	local radius = 1.5 + math.abs(head.Y) * 0.35 + math.abs(head.Z) * 0.3
	for k = 1, count do
		local phi = (k - 1) / count * math.pi * 2
		local centre = V(math.cos(phi) * radius, head.Y + 0.15 + (k % 2) * 0.35, -math.sin(phi) * radius)
		-- facing the way the orbit carries it
		local forward = V(-math.sin(phi), 0, -math.cos(phi))
		local cf = CFrame.lookAt(centre, centre + forward)
		local colour = if aura.Id == "rainbow" then RAINBOW[(k - 1) % #RAINBOW + 1] else aura.Color
		local glow = rank >= 4
		local pieces = {}
		local function ball(offset, diameter, color, material)
			local p = part(model, {
				Name = "AuraBee",
				Shape = Enum.PartType.Ball,
				Size = V(diameter, diameter, diameter) * s,
				CFrame = cf * CFrame.new(offset * s),
				Color = color,
				Material = material or SMOOTH,
			})
			table.insert(pieces, p)
			return p
		end
		local body = ball(V(0, 0, 0), 0.38, colour, if glow then NEON else SMOOTH)
		ball(V(0, 0, 0.26), 0.34, colour) -- the striped back half
		ball(V(0, 0.02, -0.26), 0.26, INK) -- the head
		for _, z in ipairs({ 0.2, 0.32 }) do
			local band = part(model, {
				Name = "AuraBee",
				Shape = Enum.PartType.Cylinder,
				Size = V(0.05, 0.35, 0.35) * s,
				CFrame = cf * CFrame.new(V(0, 0, z) * s) * CFrame.Angles(0, math.rad(90), 0),
				Color = INK,
			})
			table.insert(pieces, band)
		end
		for _, side in ipairs({ -1, 1 }) do
			local wing = part(model, {
				Name = "AuraBee",
				Size = V(0.32, 0.03, 0.2) * s,
				CFrame = cf * CFrame.new(V(side * 0.2, 0.22, 0.02) * s) * CFrame.Angles(0, 0, side * 0.45),
				Color = WHITE,
				Transparency = 0.35,
			})
			table.insert(pieces, wing)
		end
		for _, piece in ipairs(pieces) do
			table.insert(ctx.Animated, { Part = piece, Kind = "orbit", Speed = 2.4 })
		end
		if glow then
			local light = Instance.new("PointLight")
			light.Color = colour
			light.Range = 5
			light.Brightness = 1
			light.Parent = body
		end
		if rank >= 5 then
			local sparks = Instance.new("ParticleEmitter")
			sparks.Texture = "rbxasset://textures/particles/sparkles_main.dds"
			sparks.Color = ColorSequence.new(colour, WHITE)
			sparks.Rate = 6
			sparks.Lifetime = NumberRange.new(0.3, 0.6)
			sparks.Speed = NumberRange.new(0.2, 0.6)
			sparks.Size = NumberSequence.new(0.15, 0)
			sparks.LightEmission = 0.8
			sparks.Parent = body
		end
	end
end

function PetModels.build(name, plain)
	local pet, size = Config.petInfo(name)
	local spec = SPECIES[pet.Name] or SPECIES.Dog
	local rarity = Config.rarity(pet.Odds)
	local level = table.find(Config.RARITIES, rarity) or 1
	local model = Instance.new("Model")
	model.Name = "Pet_" .. name
	local ctx = {
		Model = model,
		Name = pet.Name,
		Spec = spec,
		Rig = newRig(spec),
		Animated = {},
		Color = pet.Color,
		Light = pet.Color:Lerp(WHITE, 0.45),
		Dark = pet.Color:Lerp(INK, 0.3),
		Accent = if level >= 7 then Color3.fromRGB(80, 230, 190) else rarity.Color,
		RarityColor = rarity.Color,
		Trim = if not plain and size.Index >= 2 then GOLD else nil,
	}

	local head, where = BODIES[spec.Body](ctx)
	if not plain then
		dress(ctx, where, level, size.Index)
		local aura = Config.petAura(name)
		if aura then
			auraBees(ctx, head, aura)
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
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 120, 120)),
				ColorSequenceKeypoint.new(0.33, Color3.fromRGB(255, 220, 90)),
				ColorSequenceKeypoint.new(0.66, Color3.fromRGB(110, 210, 255)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 140, 255)),
			})
			elseif size.Index == 2 then ColorSequence.new(GOLD)
			else ColorSequence.new(rarity.Color)
		sparkles.Rate = 3 + size.Index * 4 + math.max(level - 4, 0) * 2
		sparkles.Lifetime = NumberRange.new(0.6, 1.2)
		sparkles.Speed = NumberRange.new(0.4, 1.5)
		sparkles.SpreadAngle = Vector2.new(180, 180)
		sparkles.Size = NumberSequence.new(0.25, 0)
		sparkles.LightEmission = 0.6
		sparkles.Parent = body
		if size.Index >= 3 then
			local glow = Instance.new("PointLight")
			glow.Color = Color3.fromRGB(255, 220, 160)
			glow.Range = 10
			glow.Brightness = 0.8
			glow.Parent = body
		end
	end
	return model, ctx.Animated, ctx.Rig, head
end

return PetModels
