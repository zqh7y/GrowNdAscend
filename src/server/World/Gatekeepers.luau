-- The gatekeepers: a big friendly animal stands beside every gate, on the
-- side you come from, and opens the next world when you ask it (and have
-- the coins; server/Progress.luau decides, client/Gatekeeper.luau shows its
-- speech bubble and makes it move). Each world has its own:
--   Sahara         a camel with a patterned saddle blanket and a red fez
--   Frozen Peaks   a penguin in a pom-pom beanie and a striped scarf
--   Sakura Jungle  a red panda with a ringed tail, holding a bamboo stick
--   Lava Arena     a little dragon with back spikes, wings and an ember puff
-- About 9-10 studs tall on a round base in its world's colour with a
-- GATEKEEPER plate, built of smooth rounded parts. The parts that move are
-- in their own models with their pivot on the joint (Neck, Tail, WingL/R,
-- FlipperL/R, Arms) and the eyelids are parts named "Lid" (hidden until a
-- blink), so the client can animate them.
local Build = require(game:GetService("ReplicatedStorage").Shared.Build)

local Gatekeepers = {}

Gatekeepers.SCALE = 1.9 -- (the animals are drawn about 5 studs tall, then scaled)

local INK = Color3.fromRGB(40, 38, 60)
local WHITE = Color3.fromRGB(252, 250, 245)
local BLUSH = Color3.fromRGB(255, 150, 175)
local GOLD = Color3.fromRGB(255, 205, 70)

local function shade(color, amount)
	return color:Lerp(Color3.new(0, 0, 0), amount)
end
local function tint(color, amount)
	return color:Lerp(Color3.new(1, 1, 1), amount)
end

-- Drawing helpers in the animal's own frame (-Z forward, +Y up), every
-- position and size times S. `container` is the model the parts go in.
local function kit(container, frame, S)
	local k = { Model = container }
	local function place(cf)
		return frame * (CFrame.new(cf.Position * S) * cf.Rotation)
	end
	function k.at(x, y, z)
		return (frame * CFrame.new(x * S, y * S, z * S)).Position
	end
	function k.ball(x, y, z, d, color, name)
		return Build.ball(container, k.at(x, y, z), d * S, { Name = name, Color = color, CanCollide = false })
	end
	function k.limb(a, b, d, color)
		return Build.limb(container, k.at(a.X, a.Y, a.Z), k.at(b.X, b.Y, b.Z), d * S, { Color = color, CanCollide = false })
	end
	function k.block(cf, size, color, props)
		props = props or {}
		props.Size, props.CFrame, props.Color = size * S, place(cf), color
		props.CanCollide = false
		return Build.part(container, props)
	end
	function k.disc(cf, thick, d, color, props)
		props = props or {}
		props.Shape = Enum.PartType.Cylinder
		props.Size, props.CFrame, props.Color = Vector3.new(thick, d, d) * S, place(cf), color
		props.CanCollide = false
		return Build.part(container, props)
	end
	-- a moving part: its own model with its pivot on the joint
	function k.group(name, jx, jy, jz)
		local model = Build.model(container, name)
		local g = kit(model, frame, S)
		function g.done()
			local first = model:FindFirstChildWhichIsA("BasePart")
			if first then
				Build.setPivot(model, first, frame * CFrame.new(jx * S, jy * S, jz * S))
			end
			return model
		end
		return g
	end
	-- big friendly eyes: a white eye, a dark pupil, two sparkles, an eyelid
	-- in the skin colour (hidden until a blink), a blush and a little smile
	function k.face(x, y, z, size, skin, smile)
		for _, side in ipairs({ -1, 1 }) do
			local ex = x + side * 0.36 * size
			k.ball(ex, y + 0.08 * size, z, 0.52 * size, WHITE)
			k.ball(ex, y + 0.06 * size, z - 0.13 * size, 0.38 * size, INK)
			k.ball(ex, y + 0.06 * size, z - 0.2 * size, 0.2 * size, shade(INK, 0.4))
			k.ball(ex - 0.08 * size, y + 0.18 * size, z - 0.28 * size, 0.14 * size, WHITE)
			k.ball(ex + 0.06 * size, y - 0.01 * size, z - 0.29 * size, 0.07 * size, WHITE)
			local lid = k.ball(ex, y + 0.08 * size, z - 0.02 * size, 0.56 * size, skin, "Lid")
			lid.Transparency = 1
			k.ball(x + side * 0.64 * size, y - 0.26 * size, z + 0.05 * size, 0.36 * size, BLUSH)
		end
		if smile ~= false then
			for s = -2, 2 do
				k.ball(x + s * 0.08 * size, y - 0.3 * size + (s * s) * 0.018 * size, z - 0.04 * size, 0.08 * size, INK)
			end
		end
	end
	return k
end

-- The camel ---------------------------------------------------------------------------------
local function camel(k)
	local SAND = Color3.fromRGB(228, 180, 115)
	local DARK = shade(SAND, 0.25)
	local RED = Color3.fromRGB(215, 55, 65)
	-- body: a few overlapping rounds for a smooth barrel shape, and the humps
	k.ball(0, 2.5, 0.4, 2.8, SAND, "Body")
	k.ball(0, 2.35, -0.45, 2.3, SAND)
	k.ball(0, 2.4, 1.15, 2.2, SAND)
	k.ball(0, 1.9, 0.4, 2.2, tint(SAND, 0.12)) -- a lighter tummy
	k.ball(0, 3.75, 1.05, 1.5, shade(SAND, 0.05))
	k.ball(0, 4.15, 1.05, 0.9, shade(SAND, 0.05))
	k.ball(0, 3.65, -0.15, 1.4, shade(SAND, 0.05))
	k.ball(0, 4.05, -0.15, 0.85, shade(SAND, 0.05))
	-- legs with knees and two-toed hooves
	for _, x in ipairs({ -0.75, 0.75 }) do
		for _, z in ipairs({ -0.6, 1.4 }) do
			k.limb(Vector3.new(x, 1.9, z), Vector3.new(x, 0.95, z), 0.55, SAND)
			k.ball(x, 0.95, z, 0.62, shade(SAND, 0.05))
			k.limb(Vector3.new(x, 0.95, z), Vector3.new(x, 0.25, z), 0.46, SAND)
			for _, t in ipairs({ -0.12, 0.12 }) do
				k.ball(x + t, 0.14, z - 0.12, 0.34, DARK)
			end
		end
	end
	-- the saddle blanket between the humps: red with a gold trim, studs and tassels
	k.block(CFrame.new(0, 3.3, 0.45), Vector3.new(2.95, 0.12, 1.25), RED)
	for _, x in ipairs({ -1.45, 1.45 }) do
		k.block(CFrame.new(x, 2.8, 0.45), Vector3.new(0.12, 1.1, 1.25), RED)
		k.block(CFrame.new(x * 1.01, 2.8, 0.45), Vector3.new(0.13, 0.12, 1.28), GOLD)
		k.block(CFrame.new(x * 1.01, 2.25, 0.45), Vector3.new(0.14, 0.12, 1.3), GOLD)
		for _, z in ipairs({ -0.05, 0.45, 0.95 }) do
			k.ball(x * 1.02, 2.08, z, 0.22, GOLD)
			k.ball(x * 1.03, 2.55, z, 0.14, GOLD)
		end
	end
	-- the neck (in the body), the head on it
	k.limb(Vector3.new(0, 2.8, -0.9), Vector3.new(0, 4.4, -1.55), 0.9, SAND)
	k.ball(0, 3.6, -1.3, 0.95, SAND)
	local h = k.group("Neck", 0, 4.4, -1.55)
	local head = h.ball(0, 4.75, -1.75, 1.55, SAND, "Head")
	h.ball(0, 4.95, -1.55, 1.2, SAND)
	h.ball(0, 4.5, -2.45, 1.05, tint(SAND, 0.25)) -- muzzle
	h.ball(0, 4.3, -2.6, 0.75, tint(SAND, 0.2))
	for _, x in ipairs({ -0.2, 0.2 }) do
		h.ball(x, 4.62, -2.95, 0.15, INK) -- nostrils
	end
	h.ball(0, 4.15, -2.7, 0.4, shade(SAND, 0.15)) -- chin
	for _, x in ipairs({ -0.58, 0.58 }) do
		h.ball(x, 5.35, -1.5, 0.45, DARK) -- ears
		h.ball(x, 5.35, -1.62, 0.25, tint(SAND, 0.3))
	end
	-- a bridle across the muzzle with gold rings
	h.disc(CFrame.new(0, 4.55, -2.32) * CFrame.Angles(0, math.rad(90), 0), 0.14, 1.1, RED)
	for _, x in ipairs({ -0.55, 0.55 }) do
		h.ball(x, 4.55, -2.32, 0.2, GOLD)
	end
	-- the fez with a gold tassel
	h.disc(CFrame.new(0, 5.47, -1.7) * CFrame.Angles(0, 0, math.rad(90)), 0.72, 0.88, RED)
	h.disc(CFrame.new(0, 5.84, -1.7) * CFrame.Angles(0, 0, math.rad(90)), 0.05, 0.74, shade(RED, 0.2))
	h.limb(Vector3.new(0, 5.84, -1.7), Vector3.new(0.38, 5.58, -1.5), 0.07, GOLD)
	h.ball(0.42, 5.48, -1.48, 0.22, GOLD)
	h.face(0, 4.98, -2.38, 0.8, SAND)
	for _, x in ipairs({ -0.29, 0.29 }) do
		for l = -1, 1 do
			h.block(CFrame.new(x + l * 0.08, 5.27, -2.42) * CFrame.Angles(0, 0, math.rad(l * 25)), Vector3.new(0.04, 0.16, 0.04), INK) -- lashes
		end
	end
	h.done()
	-- a tufted tail
	local t = k.group("Tail", 0, 2.7, 1.75)
	t.limb(Vector3.new(0, 2.7, 1.75), Vector3.new(0, 1.75, 2.1), 0.22, SAND)
	t.ball(0, 1.65, 2.15, 0.5, DARK)
	t.ball(0, 1.45, 2.2, 0.38, DARK)
	t.done()
	return head
end

-- The penguin --------------------------------------------------------------------------------
local function penguin(k)
	local NAVY = Color3.fromRGB(40, 56, 105)
	local ORANGE = Color3.fromRGB(255, 150, 40)
	local SCARF = Color3.fromRGB(230, 60, 75)
	-- body: navy back, a white belly with a soft shine
	k.ball(0, 1.75, 0.1, 3.1, NAVY, "Body")
	k.ball(0, 2.15, 0.05, 2.75, NAVY)
	k.ball(0, 1.3, 0.1, 2.9, NAVY)
	k.ball(0, 1.65, -0.5, 2.55, WHITE)
	k.ball(0, 1.25, -0.4, 2.4, WHITE)
	k.ball(-0.5, 2.15, -1.6, 0.45, tint(WHITE, 0.5))
	-- a little tail behind
	k.block(CFrame.new(0, 0.6, 1.5) * CFrame.Angles(math.rad(-30), 0, 0), Vector3.new(0.8, 0.12, 0.6), NAVY)
	-- feet with three toes each
	for _, x in ipairs({ -0.55, 0.55 }) do
		k.block(CFrame.new(x, 0.12, -0.55), Vector3.new(0.8, 0.22, 1), ORANGE)
		for t = -1, 1 do
			k.ball(x + t * 0.26, 0.14, -1.07, 0.32, ORANGE)
		end
	end
	-- a striped knitted scarf with fringed ends hanging down the front
	k.disc(CFrame.new(0, 3.05, 0) * CFrame.Angles(0, 0, math.rad(90)), 0.5, 2.6, SCARF)
	k.disc(CFrame.new(0, 3.05, 0) * CFrame.Angles(0, 0, math.rad(90)), 0.16, 2.65, WHITE)
	k.ball(0.6, 3.0, -1.15, 0.5, SCARF) -- the knot
	for s = 0, 3 do
		k.block(CFrame.new(0.62, 2.62 - s * 0.32, -1.27) * CFrame.Angles(math.rad(-6), 0, 0), Vector3.new(0.52, 0.3, 0.14), if s % 2 == 0 then SCARF else WHITE)
	end
	for f = -1, 1 do
		k.block(CFrame.new(0.62 + f * 0.17, 1.27, -1.3), Vector3.new(0.07, 0.3, 0.07), SCARF)
	end
	-- flippers (they flap)
	for _, side in ipairs({ -1, 1 }) do
		local f = k.group(if side < 0 then "FlipperL" else "FlipperR", side * 1.3, 2.6, 0.05)
		f.block(CFrame.new(side * 1.55, 1.95, 0.05) * CFrame.Angles(0, 0, math.rad(side * 24)), Vector3.new(0.35, 1.7, 0.85), NAVY)
		f.ball(side * 1.82, 1.25, 0.05, 0.5, NAVY)
		f.done()
	end
	-- the head (it turns and nods)
	local h = k.group("Neck", 0, 3.2, 0)
	local head = h.ball(0, 4.05, 0, 2.25, NAVY, "Head")
	h.ball(0, 3.9, -0.55, 1.6, WHITE)
	h.ball(0, 3.72, -1.15, 0.52, ORANGE) -- beak
	h.ball(0, 3.58, -1.05, 0.38, shade(ORANGE, 0.15))
	h.ball(0, 3.8, -1.32, 0.18, tint(ORANGE, 0.4))
	h.face(0, 4.1, -1.02, 0.75, NAVY, false)
	-- the beanie: a stripe, a fold and a pom-pom
	h.ball(0, 4.68, 0, 2, SCARF)
	h.disc(CFrame.new(0, 4.42, 0) * CFrame.Angles(0, 0, math.rad(90)), 0.38, 2.25, WHITE)
	h.disc(CFrame.new(0, 4.95, 0) * CFrame.Angles(0, 0, math.rad(90)), 0.14, 1.85, WHITE)
	h.ball(0, 5.7, 0, 0.7, WHITE)
	h.ball(0.15, 5.85, -0.1, 0.35, tint(WHITE, 0.5))
	h.done()
	return head
end

-- The red panda ------------------------------------------------------------------------------
local function redPanda(k)
	local RUST = Color3.fromRGB(215, 92, 42)
	local DARK = Color3.fromRGB(70, 38, 32)
	local GREEN = Color3.fromRGB(120, 200, 80)
	-- sitting body with a dark tummy
	k.ball(0, 1.6, 0.35, 2.55, RUST, "Body")
	k.ball(0, 1.2, 0.4, 2.4, RUST)
	k.ball(0, 1.45, -0.25, 1.75, shade(RUST, 0.35))
	-- back legs sitting, feet with pads
	for _, side in ipairs({ -1, 1 }) do
		k.ball(side * 0.88, 0.58, -0.2, 1.1, DARK)
		k.ball(side * 0.78, 0.25, -0.78, 0.6, DARK)
		k.ball(side * 0.78, 0.25, -1.05, 0.26, shade(DARK, 0.3))
	end
	-- the arms holding a bamboo stick (they lift it for a nibble)
	local a = k.group("Arms", 0, 2.15, -0.5)
	for _, side in ipairs({ -1, 1 }) do
		a.limb(Vector3.new(side * 0.85, 2.15, -0.5), Vector3.new(side * 0.35, 1.65, -1.15), 0.52, DARK)
		a.ball(side * 0.3, 1.62, -1.2, 0.52, DARK)
	end
	a.limb(Vector3.new(0, 0.9, -1.27), Vector3.new(0, 3.15, -1.42), 0.26, GREEN)
	for _, y in ipairs({ 1.5, 2.3 }) do
		a.disc(CFrame.new(0, y, -1.32) * CFrame.Angles(0, 0, math.rad(90)), 0.08, 0.32, shade(GREEN, 0.2))
	end
	a.block(CFrame.new(0.32, 3.05, -1.42) * CFrame.Angles(0, 0, math.rad(-35)), Vector3.new(0.65, 0.06, 0.24), GREEN)
	a.block(CFrame.new(-0.28, 2.9, -1.4) * CFrame.Angles(0, 0, math.rad(30)), Vector3.new(0.55, 0.06, 0.2), shade(GREEN, 0.1))
	a.done()
	-- the big fluffy ringed tail curling up behind (it sways)
	local t = k.group("Tail", 0, 0.8, 1.3)
	for r = 0, 9 do
		local u = r / 9
		t.ball(0.18 * math.sin(u * 3), 0.7 + u * 2.6, 1.6 + math.sin(u * math.pi) * 0.95, 1 - u * 0.28, if r % 2 == 0 then RUST else shade(RUST, 0.45))
	end
	t.done()
	-- the head: rust with a white muzzle, eyebrow and tear marks, fluffy ears
	local h = k.group("Neck", 0, 2.4, -0.3)
	local head = h.ball(0, 3.25, -0.3, 2.3, RUST, "Head")
	h.ball(0, 3.0, -1.18, 1.1, WHITE)
	h.ball(0, 3.14, -1.68, 0.32, INK) -- nose
	h.ball(0.05, 3.2, -1.82, 0.1, tint(INK, 0.5))
	for _, side in ipairs({ -1, 1 }) do
		h.ball(side * 0.78, 3.05, -1.0, 0.8, WHITE) -- cheeks
		h.ball(side * 1.05, 2.95, -0.75, 0.5, WHITE) -- cheek fluff
		h.ball(side * 0.42, 3.88, -1.12, 0.34, WHITE) -- eyebrow marks
		h.ball(side * 0.5, 2.95, -1.36, 0.24, shade(RUST, 0.3)) -- tear marks
		h.ball(side * 0.92, 4.25, -0.25, 0.85, RUST) -- ears
		h.ball(side * 0.92, 4.25, -0.5, 0.55, WHITE)
		h.ball(side * 0.95, 4.6, -0.3, 0.3, WHITE) -- ear tufts
	end
	h.face(0, 3.45, -1.25, 0.7, RUST, false)
	for s = -1, 1 do
		h.ball(s * 0.11, 2.78 + math.abs(s) * 0.05, -1.68, 0.09, INK)
	end
	h.done()
	return head
end

-- The dragon ---------------------------------------------------------------------------------
local function dragon(k)
	local RED = Color3.fromRGB(225, 75, 60)
	local BELLY = Color3.fromRGB(255, 205, 95)
	local WING = Color3.fromRGB(255, 140, 70)
	-- body with a striped belly
	k.ball(0, 1.9, 0.25, 2.85, RED, "Body")
	k.ball(0, 1.45, 0.3, 2.6, RED)
	k.ball(0, 1.75, -0.35, 2.15, BELLY)
	for s = 0, 3 do
		k.disc(CFrame.new(0, 1.15 + s * 0.38, -1.17 + math.abs(s - 1.5) * 0.05) * CFrame.Angles(0, math.rad(90), 0), 0.06, 1.3 - math.abs(s - 1.5) * 0.25, shade(BELLY, 0.18))
	end
	-- legs with three claws, little arms
	for _, side in ipairs({ -1, 1 }) do
		k.ball(side * 0.88, 0.68, 0.25, 1.15, RED)
		for c = -1, 1 do
			k.ball(side * 0.88 + c * 0.26, 0.12, -0.28, 0.24, WHITE)
		end
		k.limb(Vector3.new(side * 0.95, 2.4, -0.6), Vector3.new(side * 0.7, 1.9, -1.15), 0.44, RED)
		k.ball(side * 0.68, 1.88, -1.2, 0.4, RED)
	end
	-- spikes down the back
	for s = 0, 4 do
		k.block(CFrame.new(0, 3.2 - s * 0.35, 1.1 + s * 0.4) * CFrame.Angles(math.rad(45), 0, 0), Vector3.new(0.12, 0.48, 0.48), BELLY)
	end
	-- wings (they flap): bones fanning out with a membrane between
	for _, side in ipairs({ -1, 1 }) do
		local w = k.group(if side < 0 then "WingL" else "WingR", side * 0.9, 2.9, 0.9)
		local root = Vector3.new(side * 0.9, 2.9, 0.9)
		for b = 0, 2 do
			w.limb(root, Vector3.new(side * (2.15 + b * 0.25), 4.3 - b * 0.7, 1.2 + b * 0.25), 0.15, shade(RED, 0.2))
		end
		w.block(CFrame.new(side * 1.75, 3.4, 1.2) * CFrame.Angles(0, 0, math.rad(side * -50)), Vector3.new(0.08, 1.95, 1.15), WING)
		w.block(CFrame.new(side * 1.95, 3.0, 1.35) * CFrame.Angles(0, 0, math.rad(side * -70)), Vector3.new(0.07, 1.4, 0.9), tint(WING, 0.15))
		w.done()
	end
	-- the tail (it wags) with a spike at the end
	local t = k.group("Tail", 0, 0.8, 1.4)
	for s = 0, 5 do
		t.ball(0, 0.78 - s * 0.04, 1.55 + s * 0.45, 0.88 - s * 0.11, RED)
	end
	t.block(CFrame.new(0, 0.6, 4.15) * CFrame.Angles(math.rad(45), 0, 0), Vector3.new(0.12, 0.55, 0.55), BELLY)
	t.done()
	-- the head: snout with nostrils, horns, cheek frills, an ember puff
	local h = k.group("Neck", 0, 2.9, -0.3)
	local head = h.ball(0, 3.65, -0.35, 2.25, RED, "Head")
	h.ball(0, 3.35, -1.25, 1.3, tint(RED, 0.15))
	h.ball(0, 3.1, -1.3, 0.9, tint(RED, 0.25))
	for _, side in ipairs({ -1, 1 }) do
		h.ball(side * 0.26, 3.55, -1.86, 0.17, INK) -- nostrils
		h.limb(Vector3.new(side * 0.55, 4.55, -0.2), Vector3.new(side * 0.85, 5.4, 0.28), 0.32, WHITE) -- horns
		h.ball(side * 0.86, 5.42, 0.3, 0.2, WHITE)
		h.block(CFrame.new(side * 1.14, 3.6, -0.1) * CFrame.Angles(0, 0, math.rad(side * -20)), Vector3.new(0.08, 0.75, 0.62), BELLY) -- frills
	end
	h.face(0, 3.88, -1.42, 0.7, RED)
	Build.ball(h.Model, h.at(0.55, 3.75, -2.2), 0.3 * Gatekeepers.SCALE, { Name = "Ember", Color = Color3.fromRGB(255, 170, 60), Material = Enum.Material.Neon, CanCollide = false })
	Build.ball(h.Model, h.at(0.8, 3.95, -2.35), 0.2 * Gatekeepers.SCALE, { Color = Color3.fromRGB(255, 220, 120), Material = Enum.Material.Neon, CanCollide = false })
	h.done()
	return head
end

local KINDS = { camel, penguin, redPanda, dragon }
Gatekeepers.NAMES = { "Camel", "Penguin", "Red Panda", "Dragon" }
-- what each one eats: the world's price is paid as its food
Gatekeepers.FOODS = { "Watermelon", "Fish", "Apple", "Chili Pepper" }

function Gatekeepers.food(i)
	return Gatekeepers.FOODS[math.clamp(i - 1, 1, #Gatekeepers.FOODS)]
end

-- The gatekeeper of the gate into area `i` (2..5) at `base` on the ground,
-- facing `facing` (a direction), on a round base in `color`. Returns the
-- model and its head (the prompt and the speech bubble hang on it).
function Gatekeepers.build(parent, i, base, facing, color)
	local S = Gatekeepers.SCALE
	local n = math.clamp(i - 1, 1, #KINDS)
	local model = Build.model(parent, "Gatekeeper")
	model:SetAttribute("Animal", Gatekeepers.NAMES[n])
	model:SetAttribute("Food", Gatekeepers.FOODS[n])
	local frame = CFrame.lookAt(base, base + facing)
	-- the round base and its GATEKEEPER plate
	color = color or Color3.fromRGB(255, 255, 255)
	Build.cylinder(model, base, 0.5, 4.8 * S, { Name = "Base", Color = shade(color, 0.25), CanCollide = false })
	Build.cylinder(model, base + Vector3.new(0, 0.5, 0), 0.14, 4.4 * S, { Color = tint(color, 0.35), CanCollide = false })
	local plate = Build.sign(model, frame * CFrame.new(0, 0.4, -2.45 * S), Vector3.new(2.8 * S, 0.6, 0.15), "GATEKEEPER", Color3.new(1, 1, 1), shade(color, 0.35))
	plate.CanCollide = false
	-- the animal itself in its own model (pivot on its feet), so the client
	-- can move it without its base
	local animal = Build.model(model, "Animal")
	local feet = frame * CFrame.new(0, 0.64, 0)
	local head = KINDS[n](kit(animal, feet, S))
	Build.setPivot(animal, animal:FindFirstChild("Body") or head, feet)
	-- an invisible box to bump into, so it can't be walked through
	Build.part(model, { Name = "Hitbox", Size = Vector3.new(3.6 * S, 5.5 * S, 3.6 * S), CFrame = frame * CFrame.new(0, 2.75 * S, 0), Transparency = 1, CastShadow = false })
	return model, head
end

return Gatekeepers
