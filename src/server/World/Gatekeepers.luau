-- The gatekeepers: a friendly animal stands beside every gate, on the side
-- you come from, and opens the next world when you ask it (and have the
-- coins; server/Progress.luau decides, client/Gatekeeper.luau shows its
-- speech bubble and its happy hop or head shake). Each world has its own:
--   Sahara         a camel with a patterned saddle blanket and a red fez
--   Frozen Peaks   a penguin in a pom-pom beanie and a striped scarf
--   Sakura Jungle  a red panda with a ringed tail, holding a bamboo stick
--   Lava Arena     a little dragon with back spikes, wings and an ember puff
-- Each stands on a round base in its world's colour with a GATEKEEPER plate,
-- built of round toy-like parts (about 5 studs tall), facing the way players
-- walk in from.
local Build = require(game:GetService("ReplicatedStorage").Shared.Build)

local Gatekeepers = {}

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

-- Helpers in the animal's own frame (-Z is forward, +Y up) ----------------------

local function kit(model, frame)
	local k = {}
	function k.at(x, y, z)
		return (frame * CFrame.new(x, y, z)).Position
	end
	function k.ball(x, y, z, d, color, name)
		return Build.ball(model, k.at(x, y, z), d, { Name = name, Color = color, CanCollide = false })
	end
	function k.limb(a, b, d, color)
		return Build.limb(model, k.at(a.X, a.Y, a.Z), k.at(b.X, b.Y, b.Z), d, { Color = color, CanCollide = false })
	end
	function k.block(cf, size, color, props)
		props = props or {}
		props.Size, props.CFrame, props.Color = size, frame * cf, color
		props.CanCollide = false
		return Build.part(model, props)
	end
	function k.disc(cf, thick, d, color, props)
		props = props or {}
		props.Shape = Enum.PartType.Cylinder
		props.Size, props.CFrame, props.Color = Vector3.new(thick, d, d), frame * cf, color
		props.CanCollide = false
		return Build.part(model, props)
	end
	-- big friendly eyes: a white eye, a dark pupil looking forward, two
	-- sparkles, a soft blush under each and a little smile
	function k.face(x, y, z, size, smile)
		for _, side in ipairs({ -1, 1 }) do
			local ex = x + side * 0.36 * size
			k.ball(ex, y + 0.08 * size, z, 0.5 * size, WHITE)
			k.ball(ex, y + 0.06 * size, z - 0.12 * size, 0.36 * size, INK)
			k.ball(ex - 0.07 * size, y + 0.17 * size, z - 0.26 * size, 0.13 * size, WHITE)
			k.ball(ex + 0.06 * size, y + 0.0, z - 0.27 * size, 0.06 * size, WHITE)
			k.ball(x + side * 0.62 * size, y - 0.25 * size, z + 0.05 * size, 0.34 * size, BLUSH)
		end
		if smile ~= false then
			for s = -1, 1 do
				k.ball(x + s * 0.13 * size, y - 0.3 * size + math.abs(s) * 0.06 * size, z - 0.05 * size, 0.1 * size, INK)
			end
		end
	end
	return k
end

-- The camel ---------------------------------------------------------------------------------
local function camel(model, frame)
	local k = kit(model, frame)
	local SAND = Color3.fromRGB(228, 180, 115)
	local DARK = shade(SAND, 0.25)
	local RED = Color3.fromRGB(215, 55, 65)
	-- body and humps
	k.ball(0, 2.5, 0.4, 2.8, SAND, "Body")
	k.ball(0, 2.3, -0.4, 2.2, SAND)
	k.ball(0, 3.75, 1.05, 1.45, shade(SAND, 0.06))
	k.ball(0, 3.65, -0.15, 1.35, shade(SAND, 0.06))
	-- legs with knees and hooves
	for _, x in ipairs({ -0.75, 0.75 }) do
		for _, z in ipairs({ -0.6, 1.3 }) do
			k.limb(Vector3.new(x, 1.8, z), Vector3.new(x, 0.9, z), 0.5, SAND)
			k.ball(x, 0.9, z, 0.6, shade(SAND, 0.05))
			k.limb(Vector3.new(x, 0.9, z), Vector3.new(x, 0.25, z), 0.45, SAND)
			k.disc(CFrame.new(x, 0.12, z) * CFrame.Angles(0, 0, math.rad(90)), 0.25, 0.6, DARK)
		end
	end
	-- a tufted tail
	k.limb(Vector3.new(0, 2.6, 1.7), Vector3.new(0, 1.7, 2.05), 0.2, SAND)
	k.ball(0, 1.6, 2.1, 0.45, DARK)
	-- the saddle blanket between the humps: red with a gold trim and tassels
	k.block(CFrame.new(0, 3.25, 0.45), Vector3.new(2.95, 0.12, 1.2), RED)
	for _, x in ipairs({ -1.45, 1.45 }) do
		k.block(CFrame.new(x, 2.75, 0.45), Vector3.new(0.12, 1.1, 1.2), RED)
		k.block(CFrame.new(x, 2.2, 0.45), Vector3.new(0.14, 0.12, 1.25), GOLD)
		for _, z in ipairs({ 0, 0.45, 0.9 }) do
			k.ball(x, 2.05, z, 0.22, GOLD)
		end
		k.ball(x * 1.01, 2.75, 0.45, 0.32, GOLD) -- a gold stud
	end
	-- the neck and head
	k.limb(Vector3.new(0, 2.8, -0.9), Vector3.new(0, 4.4, -1.6), 0.85, SAND)
	local head = k.ball(0, 4.75, -1.75, 1.5, SAND, "Head")
	k.ball(0, 4.5, -2.45, 1, tint(SAND, 0.25)) -- muzzle
	for _, x in ipairs({ -0.2, 0.2 }) do
		k.ball(x, 4.6, -2.92, 0.14, INK) -- nostrils
	end
	k.ball(0, 4.22, -2.75, 0.35, shade(SAND, 0.15)) -- chin
	for _, x in ipairs({ -0.55, 0.55 }) do
		k.ball(x, 5.35, -1.55, 0.42, DARK) -- ears
	end
	-- a bridle across the muzzle
	k.disc(CFrame.new(0, 4.55, -2.35) * CFrame.Angles(0, math.rad(90), 0), 0.14, 1.05, RED)
	-- the fez with a gold tassel
	k.disc(CFrame.new(0, 5.45, -1.75) * CFrame.Angles(0, 0, math.rad(90)), 0.7, 0.85, RED)
	k.disc(CFrame.new(0, 5.82, -1.75) * CFrame.Angles(0, 0, math.rad(90)), 0.05, 0.72, shade(RED, 0.2))
	k.limb(Vector3.new(0, 5.82, -1.75), Vector3.new(0.35, 5.6, -1.55), 0.07, GOLD)
	k.ball(0.38, 5.5, -1.52, 0.2, GOLD)
	k.face(0, 4.95, -2.35, 0.8)
	-- long lashes
	for _, x in ipairs({ -0.36, 0.36 }) do
		k.block(CFrame.new(x * 0.8, 5.22, -2.4), Vector3.new(0.32, 0.05, 0.05), INK)
	end
	return head
end

-- The penguin --------------------------------------------------------------------------------
local function penguin(model, frame)
	local k = kit(model, frame)
	local NAVY = Color3.fromRGB(40, 56, 105)
	local ORANGE = Color3.fromRGB(255, 150, 40)
	local SCARF = Color3.fromRGB(230, 60, 75)
	-- body: navy back, white belly with a soft shine
	k.ball(0, 1.75, 0.1, 3.1, NAVY, "Body")
	k.ball(0, 2.1, 0.05, 2.7, NAVY)
	k.ball(0, 1.65, -0.5, 2.5, WHITE)
	k.ball(-0.5, 2.1, -1.55, 0.45, tint(WHITE, 0.5))
	-- flippers, a little open as if waving
	for _, side in ipairs({ -1, 1 }) do
		k.block(CFrame.new(side * 1.55, 1.9, 0.05) * CFrame.Angles(0, 0, math.rad(side * 28)), Vector3.new(0.35, 1.7, 0.85), NAVY)
		k.ball(side * 1.85, 1.2, 0.05, 0.45, NAVY)
	end
	-- feet with three toes each
	for _, x in ipairs({ -0.55, 0.55 }) do
		k.block(CFrame.new(x, 0.12, -0.55), Vector3.new(0.75, 0.22, 1), ORANGE)
		for t = -1, 1 do
			k.ball(x + t * 0.25, 0.14, -1.05, 0.3, ORANGE)
		end
	end
	-- head
	local head = k.ball(0, 4, 0, 2.2, NAVY, "Head")
	k.ball(0, 3.85, -0.55, 1.55, WHITE)
	-- the beak: a top and a bottom
	k.ball(0, 3.7, -1.15, 0.5, ORANGE)
	k.ball(0, 3.55, -1.05, 0.35, shade(ORANGE, 0.15))
	k.face(0, 4.05, -1.0, 0.75, false)
	-- a beanie with a stripe and a pom-pom
	k.ball(0, 4.65, 0, 1.95, SCARF)
	k.disc(CFrame.new(0, 4.4, 0) * CFrame.Angles(0, 0, math.rad(90)), 0.35, 2.2, WHITE)
	k.ball(0, 5.65, 0, 0.65, WHITE)
	-- a striped knitted scarf with fringed ends hanging down the front
	k.disc(CFrame.new(0, 3.05, 0) * CFrame.Angles(0, 0, math.rad(90)), 0.5, 2.55, SCARF)
	k.disc(CFrame.new(0, 3.05, 0) * CFrame.Angles(0, 0, math.rad(90)), 0.16, 2.6, WHITE)
	for s = 0, 2 do
		k.block(CFrame.new(0.6, 2.6 - s * 0.35, -1.25), Vector3.new(0.5, 0.33, 0.14), if s % 2 == 0 then SCARF else WHITE)
	end
	for f = -1, 1 do
		k.block(CFrame.new(0.6 + f * 0.16, 1.95, -1.25), Vector3.new(0.07, 0.3, 0.07), SCARF)
	end
	return head
end

-- The red panda ------------------------------------------------------------------------------
local function redPanda(model, frame)
	local k = kit(model, frame)
	local RUST = Color3.fromRGB(215, 92, 42)
	local DARK = Color3.fromRGB(70, 38, 32)
	local GREEN = Color3.fromRGB(120, 200, 80)
	-- sitting body with a dark tummy
	k.ball(0, 1.6, 0.35, 2.5, RUST, "Body")
	k.ball(0, 1.45, -0.25, 1.7, shade(RUST, 0.35))
	-- back legs sitting, front paws holding a bamboo stick
	for _, side in ipairs({ -1, 1 }) do
		k.ball(side * 0.85, 0.55, -0.25, 1.05, DARK)
		k.ball(side * 0.75, 0.25, -0.75, 0.55, DARK) -- feet
		k.limb(Vector3.new(side * 0.85, 2.15, -0.5), Vector3.new(side * 0.35, 1.65, -1.15), 0.5, DARK)
		k.ball(side * 0.3, 1.62, -1.2, 0.5, DARK) -- paws
	end
	-- the bamboo stick with a joint and a leaf
	k.limb(Vector3.new(0, 0.9, -1.25), Vector3.new(0, 3.1, -1.4), 0.24, GREEN)
	k.disc(CFrame.new(0, 2.2, -1.32) * CFrame.Angles(0, 0, math.rad(90)), 0.08, 0.3, shade(GREEN, 0.2))
	k.block(CFrame.new(0.3, 3, -1.4) * CFrame.Angles(0, 0, math.rad(-35)), Vector3.new(0.6, 0.06, 0.22), GREEN)
	-- the big fluffy ringed tail curling up behind
	for t = 0, 7 do
		local a = t / 7
		k.ball(0.15 * math.sin(a * 3), 0.7 + a * 2.4, 1.6 + math.sin(a * math.pi) * 0.9, 0.95 - a * 0.25, if t % 2 == 0 then RUST else shade(RUST, 0.45))
	end
	-- head: rust with a white muzzle, white eyebrow marks, tear marks
	local head = k.ball(0, 3.25, -0.3, 2.2, RUST, "Head")
	k.ball(0, 3.0, -1.2, 1.05, WHITE)
	k.ball(0, 3.12, -1.68, 0.3, INK) -- nose
	for _, side in ipairs({ -1, 1 }) do
		k.ball(side * 0.75, 3.05, -1.0, 0.75, WHITE) -- cheeks
		k.ball(side * 0.4, 3.85, -1.15, 0.32, WHITE) -- eyebrow marks
		k.ball(side * 0.48, 2.95, -1.35, 0.22, shade(RUST, 0.3)) -- tear marks
		-- ears: rust outside, white tufts inside
		k.ball(side * 0.9, 4.25, -0.25, 0.8, RUST)
		k.ball(side * 0.9, 4.25, -0.5, 0.5, WHITE)
	end
	k.face(0, 3.45, -1.25, 0.7, false)
	for s = -1, 1 do
		k.ball(s * 0.11, 2.78 + math.abs(s) * 0.05, -1.68, 0.09, INK)
	end
	return head
end

-- The dragon ---------------------------------------------------------------------------------
local function dragon(model, frame)
	local k = kit(model, frame)
	local RED = Color3.fromRGB(225, 75, 60)
	local BELLY = Color3.fromRGB(255, 205, 95)
	local WING = Color3.fromRGB(255, 140, 70)
	-- body with a striped belly
	k.ball(0, 1.9, 0.25, 2.8, RED, "Body")
	k.ball(0, 1.75, -0.35, 2.1, BELLY)
	for s = 0, 3 do
		k.disc(CFrame.new(0, 1.15 + s * 0.38, -1.15 + math.abs(s - 1.5) * 0.05) * CFrame.Angles(0, math.rad(90), 0), 0.06, 1.3 - math.abs(s - 1.5) * 0.25, shade(BELLY, 0.18))
	end
	-- legs with three claws
	for _, side in ipairs({ -1, 1 }) do
		k.ball(side * 0.85, 0.65, 0.25, 1.1, RED)
		for c = -1, 1 do
			k.ball(side * 0.85 + c * 0.25, 0.12, -0.25, 0.22, WHITE)
		end
		-- little arms
		k.limb(Vector3.new(side * 0.95, 2.4, -0.6), Vector3.new(side * 0.7, 1.9, -1.15), 0.42, RED)
	end
	-- wings: bones fanning out with a membrane between
	for _, side in ipairs({ -1, 1 }) do
		local root = Vector3.new(side * 0.9, 2.9, 0.9)
		for b = 0, 2 do
			local tip = Vector3.new(side * (2.1 + b * 0.25), 4.2 - b * 0.7, 1.2 + b * 0.25)
			k.limb(root, tip, 0.14, shade(RED, 0.2))
		end
		k.block(CFrame.new(side * 1.75, 3.35, 1.2) * CFrame.Angles(0, 0, math.rad(side * -50)), Vector3.new(0.08, 1.9, 1.1), WING, { Transparency = 0.1 })
	end
	-- spikes down the back and the tail
	for s = 0, 4 do
		k.block(CFrame.new(0, 3.2 - s * 0.35, 1.1 + s * 0.4) * CFrame.Angles(math.rad(45), 0, 0), Vector3.new(0.12, 0.45, 0.45), BELLY)
	end
	for t = 0, 5 do
		k.ball(0, 0.75 - t * 0.04, 1.55 + t * 0.45, 0.85 - t * 0.11, RED)
	end
	k.block(CFrame.new(0, 0.6, 4.1) * CFrame.Angles(math.rad(45), 0, 0), Vector3.new(0.12, 0.5, 0.5), BELLY)
	-- head: snout with nostrils, horns, cheek frills
	local head = k.ball(0, 3.65, -0.35, 2.2, RED, "Head")
	k.ball(0, 3.35, -1.25, 1.25, tint(RED, 0.15))
	for _, side in ipairs({ -1, 1 }) do
		k.ball(side * 0.25, 3.55, -1.83, 0.16, INK) -- nostrils
		k.limb(Vector3.new(side * 0.55, 4.55, -0.2), Vector3.new(side * 0.85, 5.35, 0.25), 0.3, WHITE) -- horns
		k.block(CFrame.new(side * 1.12, 3.6, -0.1) * CFrame.Angles(0, 0, math.rad(side * -20)), Vector3.new(0.08, 0.7, 0.6), BELLY) -- frills
	end
	k.face(0, 3.85, -1.4, 0.7)
	-- a tiny glowing ember puff from the nose
	Build.ball(model, k.at(0.55, 3.75, -2.2), 0.3, { Name = "Ember", Color = Color3.fromRGB(255, 170, 60), Material = Enum.Material.Neon, CanCollide = false })
	Build.ball(model, k.at(0.8, 3.95, -2.35), 0.2, { Color = Color3.fromRGB(255, 220, 120), Material = Enum.Material.Neon, CanCollide = false })
	return head
end

local KINDS = { camel, penguin, redPanda, dragon }
Gatekeepers.NAMES = { "Camel", "Penguin", "Red Panda", "Dragon" }

-- The gatekeeper of the gate into area `i` (2..5) at `base` on the ground,
-- facing `facing` (a direction), on a round base in `color`. Returns the
-- model and its head (the prompt and the speech bubble hang on it).
function Gatekeepers.build(parent, i, base, facing, color)
	local n = math.clamp(i - 1, 1, #KINDS)
	local model = Build.model(parent, "Gatekeeper")
	model:SetAttribute("Animal", Gatekeepers.NAMES[n])
	local frame = CFrame.lookAt(base, base + facing)
	-- the round base and its GATEKEEPER plate
	color = color or Color3.fromRGB(255, 255, 255)
	Build.cylinder(model, base, 0.4, 4.6, { Name = "Base", Color = shade(color, 0.25), CanCollide = false })
	Build.cylinder(model, base + Vector3.new(0, 0.4, 0), 0.12, 4.2, { Color = tint(color, 0.35), CanCollide = false })
	Build.sign(model, frame * CFrame.new(0, 0.3, -2.35), Vector3.new(2.6, 0.45, 0.12), "GATEKEEPER", Color3.new(1, 1, 1), shade(color, 0.35)).CanCollide = false
	-- the animal itself in its own model (pivot on its feet), so the client
	-- can move it (idle bob, hops, head shakes) without its base
	local animal = Build.model(model, "Animal")
	local feet = frame * CFrame.new(0, 0.52, 0)
	local head = KINDS[n](animal, feet)
	Build.setPivot(animal, animal:FindFirstChild("Body") or head, feet)
	-- an invisible box to bump into, so it can't be walked through
	Build.part(model, { Name = "Hitbox", Size = Vector3.new(3.4, 5.5, 3.4), CFrame = frame * CFrame.new(0, 2.75, 0), Transparency = 1, CastShadow = false })
	return model, head
end

return Gatekeepers
