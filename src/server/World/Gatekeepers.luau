-- The gatekeepers: a friendly animal stands beside every gate, on the side
-- you come from, and opens the next world when you ask it (and have the
-- coins; server/Progress.luau decides, client/Gatekeeper.luau shows its
-- speech bubble and its happy hop or head shake). Each world has its own:
--   Sahara         a camel in a little red fez
--   Frozen Peaks   a penguin in a red scarf
--   Sakura Jungle  a red panda with a striped tail
--   Lava Arena     a small friendly dragon with wings and horns
-- Built of round toy-like parts like everything else, about 4 studs tall,
-- facing the way the player walks in from.
local Build = require(game:GetService("ReplicatedStorage").Shared.Build)

local Gatekeepers = {}

local INK = Color3.fromRGB(45, 45, 70)
local WHITE = Color3.fromRGB(252, 250, 245)

local function soft(parent, position, diameter, color, name)
	return Build.ball(parent, position, diameter, { Name = name, Color = color, CanCollide = false })
end

local function limb(parent, frame, from, to, diameter, color)
	return Build.limb(parent, (frame * CFrame.new(from)).Position, (frame * CFrame.new(to)).Position, diameter, { Color = color, CanCollide = false })
end

-- a camel: a sandy body with two humps, a long neck, a red fez with a tassel
local function camel(model, frame)
	local SAND = Color3.fromRGB(226, 178, 112)
	local at = function(x, y, z)
		return (frame * CFrame.new(x, y, z)).Position
	end
	soft(model, at(0, 2.2, 0.4), 2.6, SAND, "Body")
	soft(model, at(0, 3.4, 0.9), 1.3, SAND:Lerp(Color3.new(0, 0, 0), 0.08))
	soft(model, at(0, 3.3, -0.2), 1.2, SAND:Lerp(Color3.new(0, 0, 0), 0.08))
	for _, x in ipairs({ -0.7, 0.7 }) do
		for _, z in ipairs({ -0.4, 1.2 }) do
			limb(model, frame, Vector3.new(x, 1.4, z), Vector3.new(x, 0, z), 0.45, SAND)
		end
	end
	limb(model, frame, Vector3.new(0, 2.6, -0.8), Vector3.new(0, 4, -1.4), 0.7, SAND)
	local head = soft(model, at(0, 4.4, -1.6), 1.4, SAND, "Head")
	soft(model, at(0, 4.2, -2.3), 0.8, SAND:Lerp(WHITE, 0.3)) -- snout
	for _, x in ipairs({ -0.45, 0.45 }) do
		soft(model, at(x, 5, -1.5), 0.35, SAND:Lerp(Color3.new(0, 0, 0), 0.2)) -- ears
	end
	Build.cylinder(model, at(0, 4.9, -1.6), 0.6, 0.8, { Color = Color3.fromRGB(220, 60, 60), CanCollide = false }) -- fez
	Build.ball(model, at(0.35, 5.3, -1.6), 0.25, { Color = Color3.fromRGB(255, 205, 60), CanCollide = false }) -- tassel
	Build.face(model, frame * CFrame.new(0, 4.5, -2.25), 0.75)
	return head
end

-- a penguin: navy with a white belly, an orange beak and feet, a red scarf
local function penguin(model, frame)
	local NAVY = Color3.fromRGB(45, 60, 110)
	local ORANGE = Color3.fromRGB(255, 150, 40)
	local at = function(x, y, z)
		return (frame * CFrame.new(x, y, z)).Position
	end
	soft(model, at(0, 1.5, 0), 2.8, NAVY, "Body")
	soft(model, at(0, 1.4, -0.45), 2.2, WHITE)
	for _, x in ipairs({ -1.4, 1.4 }) do
		Build.part(model, { Size = Vector3.new(0.3, 1.6, 0.8), CFrame = frame * CFrame.new(x, 1.6, 0) * CFrame.Angles(0, 0, math.rad(x > 0 and 20 or -20)), Color = NAVY, CanCollide = false })
	end
	for _, x in ipairs({ -0.5, 0.5 }) do
		Build.part(model, { Size = Vector3.new(0.6, 0.2, 0.9), CFrame = frame * CFrame.new(x, 0.1, -0.5), Color = ORANGE, CanCollide = false })
	end
	-- a red scarf with a hanging end
	Build.part(model, { Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.45, 2.2, 2.2), CFrame = frame * CFrame.new(0, 2.85, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(230, 60, 70), CanCollide = false })
	Build.part(model, { Size = Vector3.new(0.4, 1, 0.15), CFrame = frame * CFrame.new(0.5, 2.3, -1), Color = Color3.fromRGB(230, 60, 70), CanCollide = false })
	local head = soft(model, at(0, 3.6, 0), 2, NAVY, "Head")
	soft(model, at(0, 3.5, -0.5), 1.3, WHITE)
	soft(model, at(0, 3.4, -1.05), 0.45, ORANGE) -- beak
	Build.face(model, frame * CFrame.new(0, 3.75, -0.95), 0.7)
	return head
end

-- a red panda: rusty orange with a white face, dark legs, a striped tail
local function redPanda(model, frame)
	local RUST = Color3.fromRGB(215, 95, 45)
	local DARK = Color3.fromRGB(70, 40, 35)
	local at = function(x, y, z)
		return (frame * CFrame.new(x, y, z)).Position
	end
	soft(model, at(0, 1.5, 0.3), 2.4, RUST, "Body")
	for _, x in ipairs({ -0.6, 0.6 }) do
		for _, z in ipairs({ -0.3, 0.9 }) do
			limb(model, frame, Vector3.new(x, 0.9, z), Vector3.new(x, 0, z), 0.5, DARK)
		end
	end
	-- the striped tail curling up behind
	for k = 0, 5 do
		soft(model, at(0, 1.2 + k * 0.35, 1.6 + math.sin(k / 5 * math.pi) * 0.6), 0.75, if k % 2 == 0 then RUST else Color3.fromRGB(150, 60, 35))
	end
	local head = soft(model, at(0, 3, -0.4), 2, RUST, "Head")
	for _, x in ipairs({ -0.45, 0.45 }) do
		soft(model, at(x, 2.85, -1.1), 0.75, WHITE) -- cheeks
		soft(model, at(x * 1.7, 3.9, -0.3), 0.7, WHITE) -- ears
		soft(model, at(x * 1.7, 3.9, -0.4), 0.45, DARK)
	end
	soft(model, at(0, 2.75, -1.35), 0.3, INK) -- nose
	Build.face(model, frame * CFrame.new(0, 3.15, -1.3), 0.65)
	return head
end

-- a little dragon: warm red with a yellow belly, horns, wings and a tail
local function dragon(model, frame)
	local RED = Color3.fromRGB(230, 80, 60)
	local BELLY = Color3.fromRGB(255, 205, 90)
	local at = function(x, y, z)
		return (frame * CFrame.new(x, y, z)).Position
	end
	soft(model, at(0, 1.7, 0.2), 2.6, RED, "Body")
	soft(model, at(0, 1.6, -0.35), 1.9, BELLY)
	for _, x in ipairs({ -0.7, 0.7 }) do
		limb(model, frame, Vector3.new(x, 1, 0.3), Vector3.new(x, 0, 0.1), 0.6, RED)
		-- wings: two flat triangles up and out
		Build.wedge(model, frame * CFrame.new(x * 1.9, 2.8, 0.6) * CFrame.Angles(0, 0, math.rad(x > 0 and -25 or 25)), Vector3.new(0.15, 1.8, 1.6), { Color = RED:Lerp(Color3.fromRGB(255, 170, 60), 0.4), CanCollide = false })
	end
	for k = 0, 4 do
		soft(model, at(0, 0.6 + k * 0.05, 1.5 + k * 0.5), 0.9 - k * 0.14, RED)
	end
	local head = soft(model, at(0, 3.4, -0.4), 2, RED, "Head")
	soft(model, at(0, 3.1, -1.2), 1, RED:Lerp(BELLY, 0.3)) -- snout
	for _, x in ipairs({ -0.5, 0.5 }) do
		Build.part(model, { Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.8, 0.3, 0.3), CFrame = frame * CFrame.new(x, 4.4, -0.2) * CFrame.Angles(0, 0, math.rad(x > 0 and 70 or 110)), Color = WHITE, CanCollide = false }) -- horns
	end
	Build.face(model, frame * CFrame.new(0, 3.55, -1.3), 0.7)
	return head
end

local KINDS = { camel, penguin, redPanda, dragon }
Gatekeepers.NAMES = { "Camel", "Penguin", "Red Panda", "Dragon" }

-- The gatekeeper of the gate into area `i` (2..5) at `base` on the ground,
-- facing `facing` (a direction). Returns the model and its head (the prompt
-- and the speech bubble hang on it).
function Gatekeepers.build(parent, i, base, facing)
	local k = math.clamp(i - 1, 1, #KINDS)
	local model = Build.model(parent, "Gatekeeper")
	model:SetAttribute("Animal", Gatekeepers.NAMES[k])
	local frame = CFrame.lookAt(base, base + facing)
	local head = KINDS[k](model, frame)
	-- an invisible box to bump into, so it can't be walked through
	Build.part(model, { Name = "Hitbox", Size = Vector3.new(2.6, 4, 2.6), CFrame = frame * CFrame.new(0, 2, 0), Transparency = 1, CastShadow = false })
	return model, head
end

return Gatekeepers
