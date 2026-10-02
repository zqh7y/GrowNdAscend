-- Area 2: Sahara. Golden sand with an oasis, pyramids and a sphinx beyond the
-- walls, Cleopatra's temple (a pylon gate with a winged sun disk, lotus
-- columns, painted friezes, obelisks and her statue), the Pet Aura
-- machine, palms, pottery, a camel, sandstone rocks, and high walls of big
-- limestone blocks with raised faces, like the Western Wall. (Its living
-- coins, cactuses, are in shared/Coins.luau.)
local Build = require(game:GetService("ReplicatedStorage").Shared.Build)
local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local Sahara = {}

Sahara.GROUND = Enum.Material.Sand

local LIMESTONE = Color3.fromRGB(250, 228, 180)
local SANDSTONE = Color3.fromRGB(245, 200, 125)
local SANDSTONE_LIGHT = Color3.fromRGB(255, 225, 160)
local GOLD = Color3.fromRGB(255, 205, 50)
local LAPIS = Color3.fromRGB(45, 120, 235)
local TURQUOISE = Color3.fromRGB(40, 200, 200)
local RED = Color3.fromRGB(235, 80, 70)
local WHITE = Color3.fromRGB(252, 250, 245)
local PALM_GREEN = Color3.fromRGB(85, 200, 80)

local function pick(rng, list)
	return list[rng:NextInteger(1, #list)]
end

-- Walls ---------------------------------------------------------------------------------

-- A high wall of big limestone blocks. Each stone has a raised, lighter face
-- with a flat margin around it (the look of the Western Wall), the courses
-- step back slightly as they go up, and little green plants grow from joints.
local function limestoneWall(parent, rng, x0, x1, z)
	local wall = Build.model(parent, "LimestoneWall")
	local inward = -math.sign(z) -- towards the path
	local course = 3.2
	for row = 0, 3 do
		local setback = row * 0.2
		local x = if row == 0 then x0 else x0 - rng:NextNumber(0, 3)
		while x < x1 do
			local length = math.min(rng:NextNumber(3.5, 7), x1 - x)
			local left = math.max(x, x0)
			local width = math.min(x + length, x1) - left
			if width > 0.8 then
				local cx = left + width / 2
				local zFace = z - math.sign(z) * setback
				local stone = Build.block(wall, Vector3.new(cx, row * course, zFace), Vector3.new(width - 0.25, course - 0.25, 3.4), {
					Color = Build.vary(rng, LIMESTONE:Lerp(SANDSTONE, 0.25), 0.03),
				})
				stone.Name = "Stone"
				-- the raised face (small end stones are left plain)
				if width > 1.8 then
					Build.part(wall, {
						Size = Vector3.new(width - 1.1, course - 1.1, 0.25),
						CFrame = CFrame.new(cx, row * course + course / 2, zFace + inward * 1.8),
						Color = Build.vary(rng, LIMESTONE, 0.03),
						CanCollide = false,
					})
				end
				if rng:NextNumber() < 0.12 then
					-- a caper plant growing from the joint
					local p = Vector3.new(left + width, row * course + course - 0.2, zFace + inward * 1.9)
					for _ = 1, 3 do
						Build.ghost(Build.ball(wall, p + Vector3.new(rng:NextNumber(-0.5, 0.5), rng:NextNumber(-0.3, 0.3), 0), rng:NextNumber(0.6, 0.9), {
							Color = Build.vary(rng, Color3.fromRGB(90, 200, 80), 0.04),
						}))
					end
					Build.ghost(Build.ball(wall, p + Vector3.new(0, 0.4, inward * 0.3), 0.35, { Color = Color3.fromRGB(255, 170, 220) }))
				end
			end
			x += length
		end
	end
	-- a flat coping along the top
	Build.block(wall, Vector3.new((x0 + x1) / 2, course * 4, z - math.sign(z) * 0.8), Vector3.new(x1 - x0, 0.6, 3.6), { Color = LIMESTONE })
end

-- Pyramids and the sphinx (background) ---------------------------------------------------------

-- Thin, shrinking layers so it looks smooth from the path, a gold capstone,
-- and an entrance with a gold frame on the side facing the path.
local function pyramid(parent, center, base, facingZ)
	local model = Build.model(parent, "Pyramid")
	local layers = math.floor(base / 3)
	local step = base / (layers + 2)
	for layer = 0, layers - 1 do
		local size = base - layer * step
		Build.block(model, center + Vector3.new(0, layer * 1.5, 0), Vector3.new(size, 1.5, size), {
			Color = if layer % 2 == 0 then SANDSTONE else SANDSTONE:Lerp(SANDSTONE_LIGHT, 0.5),
		})
	end
	local top = center + Vector3.new(0, layers * 1.5, 0)
	local capBase = base - layers * step
	for k = 0, 3 do
		local s = capBase * (1 - k / 4)
		Build.block(model, top + Vector3.new(0, k * 0.9, 0), Vector3.new(s, 0.9, s), { Color = GOLD })
	end
	-- entrance
	local front = center + Vector3.new(0, 0, facingZ * (base / 2 - 2))
	Build.block(model, front, Vector3.new(6, 7, 4), { Color = SANDSTONE_LIGHT })
	Build.block(model, front + Vector3.new(0, 0, facingZ * 2.05), Vector3.new(3, 5, 0.2), { Color = LAPIS })
	Build.block(model, front + Vector3.new(0, 5, facingZ * 2.1), Vector3.new(4.4, 0.8, 0.3), { Color = GOLD })
	for _, x in ipairs({ -1.9, 1.9 }) do
		Build.block(model, front + Vector3.new(x, 0, facingZ * 2.1), Vector3.new(0.6, 5, 0.3), { Color = GOLD })
	end
	return model
end

-- the nemes headdress: blue and gold stripes framing a face
local function nemes(model, head, size, facing)
	for k = 0, 6 do
		local x = (-3 + k) * 0.28 * size
		Build.part(model, {
			Size = Vector3.new(0.26 * size, 1.6 * size, 0.9 * size),
			CFrame = facing * CFrame.new(x, -0.5 * size, 0.1 * size) + head,
			Color = if k % 2 == 0 then GOLD else LAPIS,
		})
	end
	Build.part(model, {
		Size = Vector3.new(1.9 * size, 0.7 * size, 1.4 * size),
		CFrame = facing * CFrame.new(0, 0.45 * size, 0.05 * size) + head,
		Color = LAPIS,
	})
	Build.part(model, {
		Size = Vector3.new(0.25 * size, 0.4 * size, 0.25 * size),
		CFrame = facing * CFrame.new(0, 0.75 * size, -0.62 * size) + head,
		Color = GOLD,
	})
end

local function sphinx(parent, base, facing)
	local model = Build.model(parent, "Sphinx")
	local body = SANDSTONE_LIGHT
	local frame = CFrame.new(base) * facing.Rotation
	Build.part(model, { Size = Vector3.new(7, 2, 18), CFrame = frame * CFrame.new(0, 1, 1), Color = SANDSTONE }) -- plinth
	Build.part(model, { Size = Vector3.new(6, 4.5, 12), CFrame = frame * CFrame.new(0, 4.2, 3), Color = body }) -- body
	Build.ball(model, (frame * CFrame.new(0, 4.3, 8.5)).Position, 5, { Color = body }) -- haunch
	for _, x in ipairs({ -1.8, 1.8 }) do
		Build.part(model, { Size = Vector3.new(1.6, 1.4, 6), CFrame = frame * CFrame.new(x, 2.7, -5), Color = body }) -- paws
		Build.ball(model, (frame * CFrame.new(x, 2.7, -8)).Position, 1.6, { Color = body })
	end
	Build.part(model, { Size = Vector3.new(3.2, 3.6, 3), CFrame = frame * CFrame.new(0, 7.6, -3), Color = body }) -- chest
	local head = (frame * CFrame.new(0, 10.4, -3.4)).Position
	Build.ball(model, head, 2.8, { Color = body })
	nemes(model, head, 1.8, frame.Rotation)
	for _, x in ipairs({ -0.5, 0.5 }) do
		Build.ball(model, (frame * CFrame.new(x, 10.6, -4.7)).Position, 0.4, { Color = Color3.fromRGB(45, 50, 80) })
	end
	return model
end

-- Cleopatra's temple ----------------------------------------------------------------------------

-- a lotus column: banded shaft, a bell-shaped capital that flares out, and an abacus
local function lotusColumn(model, base, height, width)
	Build.cylinder(model, base, 0.6, width * 1.4, { Color = WHITE })
	Build.cylinder(model, base + Vector3.new(0, 0.6, 0), height - 3.2, width, { Color = SANDSTONE_LIGHT })
	for k, color in ipairs({ LAPIS, GOLD, RED }) do
		Build.cylinder(model, base + Vector3.new(0, height - 3.4 - k * 0.45, 0), 0.4, width + 0.12, { Color = color })
	end
	local capital = base + Vector3.new(0, height - 2.6, 0)
	for k = 0, 3 do
		Build.cylinder(model, capital + Vector3.new(0, k * 0.5, 0), 0.5, width * (1 + k * 0.28), {
			Color = if k % 2 == 0 then TURQUOISE else Color3.fromRGB(90, 200, 110),
		})
	end
	Build.block(model, base + Vector3.new(0, height, 0), Vector3.new(width * 1.9, 0.6, width * 1.9), { Color = WHITE })
end

-- a band of little painted blocks, like hieroglyphs
local function frieze(model, rng, center, length, y, facing)
	local colors = { LAPIS, GOLD, RED, TURQUOISE, WHITE }
	local count = math.floor(length / 0.9)
	for k = 0, count - 1 do
		local x = -length / 2 + (k + 0.5) * (length / count)
		Build.part(model, {
			Size = Vector3.new(0.55, rng:NextNumber(0.4, 0.8), 0.15),
			CFrame = facing * CFrame.new(x, 0, 0) + center + Vector3.new(0, y, 0),
			Color = pick(rng, colors),
			CanCollide = false,
		})
	end
end

local function obelisk(model, base, height)
	Build.block(model, base, Vector3.new(3.4, 1.2, 3.4), { Color = WHITE })
	for k = 0, 4 do
		local s = 2.4 - k * 0.2
		Build.block(model, base + Vector3.new(0, 1.2 + k * height / 5, 0), Vector3.new(s, height / 5, s), { Color = SANDSTONE_LIGHT })
	end
	-- carved marks down the front
	for k = 1, 6 do
		Build.block(model, base + Vector3.new(0, 1.2 + k * height / 7, -1.05 + k * 0.03), Vector3.new(0.7, 0.35, 0.2), { Color = if k % 2 == 0 then LAPIS else GOLD })
	end
	for k = 0, 2 do
		local s = 1.4 - k * 0.45
		Build.block(model, base + Vector3.new(0, 1.2 + height + k * 0.5, 0), Vector3.new(s, 0.5, s), { Color = GOLD })
	end
end

local function brazier(model, base)
	Build.cylinder(model, base, 3, 0.5, { Color = GOLD })
	Build.cylinder(model, base + Vector3.new(0, 3, 0), 0.8, 1.8, { Color = GOLD })
	local flame = Build.ball(model, base + Vector3.new(0, 4.1, 0), 1.2, { Color = Color3.fromRGB(255, 150, 40), Material = Enum.Material.Neon })
	local fire = Instance.new("Fire")
	fire.Size = 3
	fire.Heat = 6
	fire.Color = Color3.fromRGB(255, 140, 40)
	fire.SecondaryColor = Color3.fromRGB(255, 220, 90)
	fire.Parent = flame
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 170, 80)
	light.Range = 12
	light.Parent = flame
end

-- Built facing +Z (the statue and the gate open towards the path); it's
-- scaled down afterwards to fit the area.
local function cleopatraTemple(parent, rng, center)
	local model = Build.model(parent, "CleopatraTemple")
	local facing = CFrame.new()

	-- platform with steps up the front
	Build.block(model, center, Vector3.new(40, 1.4, 30), { Color = SANDSTONE })
	Build.block(model, center + Vector3.new(0, 1.4, -1), Vector3.new(38, 1.4, 27), { Color = SANDSTONE_LIGHT })
	for k = 0, 2 do
		Build.block(model, center + Vector3.new(0, k * 0.93, 15 + (2 - k) * 1.2), Vector3.new(12, 0.93, 1.2), { Color = WHITE })
	end
	local floor = center + Vector3.new(0, 2.8, 0)

	-- colonnade: two rows of lotus columns and a painted roof
	for _, x in ipairs({ -13, -6.5, 6.5, 13 }) do
		for _, z in ipairs({ -8, 2 }) do
			lotusColumn(model, floor + Vector3.new(x, 0, z), 14, 2.2)
		end
	end
	local roofY = floor.Y + 14.6
	Build.block(model, Vector3.new(center.X, roofY, center.Z - 3), Vector3.new(34, 1.4, 16), { Color = WHITE })
	-- cavetto cornice: a lip that flares out, blue and gold
	Build.block(model, Vector3.new(center.X, roofY + 1.4, center.Z - 3), Vector3.new(35.5, 0.7, 17.5), { Color = LAPIS })
	Build.block(model, Vector3.new(center.X, roofY + 2.1, center.Z - 3), Vector3.new(36.5, 0.5, 18.5), { Color = GOLD })
	frieze(model, rng, Vector3.new(center.X, roofY, center.Z + 5.1), 33, 0.7, facing)

	-- back wall with painted panels
	Build.block(model, floor + Vector3.new(0, 0, -11.5), Vector3.new(34, 14, 1.2), { Color = SANDSTONE_LIGHT })
	for _, x in ipairs({ -10, 10 }) do
		Build.block(model, floor + Vector3.new(x, 3, -10.8), Vector3.new(6, 8, 0.2), { Color = TURQUOISE })
		Build.block(model, floor + Vector3.new(x, 4, -10.65), Vector3.new(4.4, 6, 0.2), { Color = WHITE })
		Build.ball(model, floor + Vector3.new(x, 8.2, -10.5), 1.4, { Color = RED }) -- sun
		frieze(model, rng, floor + Vector3.new(x, 0, -10.5), 4, 5.5, facing)
	end

	-- pylon gate in front of the steps: two sloping towers and a lintel with a winged sun disk
	for _, side in ipairs({ -1, 1 }) do
		local base = floor + Vector3.new(side * 9, -2.8, 18)
		for k = 0, 5 do
			local w = 8 - k * 0.45
			Build.block(model, base + Vector3.new(side * k * 0.22, k * 3, 0), Vector3.new(w, 3, 4.4 - k * 0.15), {
				Color = if k == 5 then LAPIS else SANDSTONE_LIGHT,
			})
		end
		Build.block(model, base + Vector3.new(side * 1.3, 18, 0), Vector3.new(6, 0.6, 4.4), { Color = GOLD })
		frieze(model, rng, base + Vector3.new(side * 0.6, 0, 2.3), 5, 9, facing)
		frieze(model, rng, base + Vector3.new(side * 0.8, 0, 2.3), 4.5, 12, facing)
		-- a banner hanging down each tower
		Build.block(model, base + Vector3.new(side * 0.6, 3, 2.35), Vector3.new(2, 7, 0.15), { Color = if side < 0 then RED else LAPIS })
		Build.block(model, base + Vector3.new(side * 0.6, 7, 2.45), Vector3.new(1.2, 1.2, 0.1), { Color = GOLD })
	end
	local lintel = floor + Vector3.new(0, 11, 18)
	Build.block(model, lintel, Vector3.new(11, 2.4, 3.6), { Color = SANDSTONE_LIGHT })
	Build.block(model, lintel + Vector3.new(0, 2.4, 0), Vector3.new(11.6, 0.6, 4), { Color = LAPIS })
	-- winged sun disk
	local disk = lintel + Vector3.new(0, 1.2, 1.9)
	Build.ball(model, disk, 1.6, { Color = RED })
	for _, side in ipairs({ -1, 1 }) do
		for k = 0, 2 do
			Build.part(model, {
				Size = Vector3.new(3.4 - k * 0.6, 0.35, 0.2),
				CFrame = CFrame.new(disk + Vector3.new(side * (2.3 - k * 0.3), 0.3 - k * 0.4, 0)) * CFrame.Angles(0, 0, math.rad(side * 8)),
				Color = if k % 2 == 0 then LAPIS else GOLD,
			})
		end
	end

	-- Cleopatra's statue on a pedestal between the columns
	local pedestal = floor + Vector3.new(0, 0, 5)
	Build.block(model, pedestal, Vector3.new(5, 3, 5), { Color = WHITE })
	Build.block(model, pedestal + Vector3.new(0, 3, 0), Vector3.new(5.6, 0.4, 5.6), { Color = GOLD })
	local statueBase = pedestal + Vector3.new(0, 3.4, 0)
	Build.block(model, statueBase, Vector3.new(3.4, 7, 2.4), { Color = WHITE }) -- dress
	Build.block(model, statueBase + Vector3.new(0, 2, 1.25), Vector3.new(0.6, 5, 0.1), { Color = GOLD }) -- sash
	Build.block(model, statueBase + Vector3.new(0, 5.2, 0), Vector3.new(4.6, 1, 2.8), { Color = GOLD }) -- collar
	for k, color in ipairs({ LAPIS, TURQUOISE }) do
		Build.block(model, statueBase + Vector3.new(0, 5.2 - k * 0.3, 0.05), Vector3.new(4.2 - k * 0.5, 0.25, 2.9), { Color = color })
	end
	-- arms crossed holding a crook
	for _, side in ipairs({ -1, 1 }) do
		Build.limb(model, statueBase + Vector3.new(side * 2, 5.4, 0), statueBase + Vector3.new(-side * 0.6, 4.2, 1.4), 0.8, { Color = Color3.fromRGB(225, 175, 130) })
	end
	Build.limb(model, statueBase + Vector3.new(-0.3, 2.5, 1.6), statueBase + Vector3.new(0.4, 6.6, 1.6), 0.3, { Color = GOLD })
	local head = statueBase + Vector3.new(0, 8, 0)
	Build.ball(model, head, 2.4, { Color = Color3.fromRGB(225, 175, 130) })
	nemes(model, head, 1.25, CFrame.Angles(0, math.pi, 0)) -- her face points +Z
	for _, x in ipairs({ -0.45, 0.45 }) do
		Build.ball(model, head + Vector3.new(x, 0.15, 1.05), 0.36, { Color = Color3.fromRGB(40, 45, 75) })
		Build.part(model, { Size = Vector3.new(0.5, 0.08, 0.1), CFrame = CFrame.new(head + Vector3.new(x + 0.12, 0.3, 1.1)), Color = Color3.fromRGB(40, 45, 75) })
	end
	Build.block(model, head + Vector3.new(0, -0.55, 1.1), Vector3.new(0.7, 0.14, 0.1), { Color = Color3.fromRGB(230, 90, 110) }) -- smile

	-- obelisks and fire braziers in front, small sphinxes guarding the steps
	for _, side in ipairs({ -1, 1 }) do
		obelisk(model, center + Vector3.new(side * 17, 0, 13), 12)
		brazier(model, floor + Vector3.new(side * 5, 0, 12))
		local guard = center + Vector3.new(side * 8.5, 0, 22)
		Build.scale(sphinx(model, guard, CFrame.Angles(0, math.pi, 0)), guard, 0.3) -- facing the path
	end
	return model
end

-- The Pet Aura Machine (was the fusion machine) ---------------------------------------------------------------------------------

-- a ring of small segments that the client spins as one piece
local function ring(parent, center, radius, tilt, color, glow)
	local model = Build.model(parent, "Ring")
	local frame = CFrame.new(center) * tilt
	local hub = Build.ghost(Build.part(model, {
		Name = "Hub",
		Size = Vector3.new(0.2, 0.2, 0.2),
		CFrame = frame,
		Transparency = 1,
	}))
	model.PrimaryPart = hub
	local segments = 20
	for k = 0, segments - 1 do
		local a = k / segments * math.pi * 2
		Build.ghost(Build.part(model, {
			Size = Vector3.new(radius * 2 * math.pi / segments + 0.1, 0.5, 0.6),
			CFrame = frame * CFrame.Angles(0, -a, 0) * CFrame.new(0, 0, -radius),
			Color = color,
		}))
		if k % 5 == 0 then
			Build.ghost(Build.part(model, {
				Shape = Enum.PartType.Ball,
				Size = Vector3.one * 1.1,
				CFrame = frame * CFrame.Angles(0, -a, 0) * CFrame.new(0, 0, -radius),
				Color = glow,
			}))
		end
	end
	return model
end

local function fusionMachine(parent, center)
	local model = Build.model(parent, "FusionMachine")
	local white = Color3.fromRGB(245, 245, 255)
	local lilac = Color3.fromRGB(200, 185, 255)
	local pink = Color3.fromRGB(255, 90, 170)
	local cyan = Color3.fromRGB(80, 220, 255)

	-- octagonal base with a step and a glowing trim
	for k = 0, 7 do
		local a = k / 8 * math.pi * 2
		local side = CFrame.new(center) * CFrame.Angles(0, a, 0)
		Build.part(model, { Size = Vector3.new(11.2, 1.2, 4), CFrame = side * CFrame.new(0, 0.6, -12), Color = lilac })
		Build.part(model, { Size = Vector3.new(10, 2.6, 6), CFrame = side * CFrame.new(0, 1.3, -8), Color = white })
		Build.part(model, { Size = Vector3.new(10, 0.3, 0.3), CFrame = side * CFrame.new(0, 2.65, -10.9), Color = pink })
	end
	Build.cylinder(model, center, 2.6, 18, { Color = white })
	Build.cylinder(model, center + Vector3.new(0, 2.6, 0), 0.4, 16, { Color = cyan })
	Build.cylinder(model, center + Vector3.new(0, 3, 0), 1.4, 15, { Color = lilac })

	-- six pillars with glowing tubes, lamps and pipes into the base
	for k = 0, 5 do
		local a = k / 6 * math.pi * 2 + math.pi / 6
		local dir = Vector3.new(math.cos(a), 0, math.sin(a))
		local p = center + dir * 10.5 + Vector3.new(0, 2.6, 0)
		Build.cylinder(model, p, 1, 2.6, { Color = lilac })
		Build.cylinder(model, p + Vector3.new(0, 1, 0), 11, 1.5, { Color = white })
		Build.limb(model, p + Vector3.new(0, 1, 0) - dir * 0.8, p + Vector3.new(0, 11.5, 0) - dir * 0.8, 0.4, { Color = if k % 2 == 0 then pink else cyan })
		for y = 3, 10, 3.5 do
			Build.cylinder(model, p + Vector3.new(0, y, 0), 0.35, 1.8, { Color = lilac })
		end
		local lamp = Build.ball(model, p + Vector3.new(0, 12.8, 0), 2, { Color = if k % 2 == 0 then pink else cyan })
		Build.bob(lamp, 0.3, 1.5)
		-- a pipe arching from the pillar into the dome's base
		local mid = center + dir * 8 + Vector3.new(0, 7, 0)
		Build.limb(model, p + Vector3.new(0, 6, 0), mid, 0.7, { Color = lilac })
		Build.limb(model, mid, center + dir * 6.5 + Vector3.new(0, 4.4, 0), 0.7, { Color = lilac })
		Build.ball(model, mid, 0.9, { Color = white })
	end
	-- top ring joining the pillars
	for k = 0, 5 do
		local a1, a2 = k / 6 * math.pi * 2 + math.pi / 6, (k + 1) / 6 * math.pi * 2 + math.pi / 6
		Build.limb(model, center + Vector3.new(math.cos(a1) * 10.5, 14.6, math.sin(a1) * 10.5), center + Vector3.new(math.cos(a2) * 10.5, 14.6, math.sin(a2) * 10.5), 0.8, { Color = white })
	end

	-- glass dome with the orb inside, and two spinning rings around it
	local domeCenter = center + Vector3.new(0, 8.5, 0)
	Build.ball(model, domeCenter, 12, {
		Color = Color3.fromRGB(190, 225, 255),
		Material = Enum.Material.Glass,
		Transparency = 0.55,
		CastShadow = false,
	})
	local orb = Build.ball(model, domeCenter, 1.8, {
		Name = "Orb",
		Color = pink,
		Material = Enum.Material.Neon,
		CanCollide = false,
	})
	local light = Instance.new("PointLight")
	light.Color = pink
	light.Range = 12
	light.Brightness = 0.6
	light.Parent = orb
	local sparkles = Instance.new("ParticleEmitter")
	sparkles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparkles.Color = ColorSequence.new(Color3.new(1, 1, 1), pink)
	sparkles.Size = NumberSequence.new(0.5, 0)
	sparkles.Lifetime = NumberRange.new(0.8, 1.4)
	sparkles.Speed = NumberRange.new(2, 4)
	sparkles.SpreadAngle = Vector2.new(180, 180)
	sparkles.Rate = 6
	sparkles.LightEmission = 1
	sparkles.Parent = orb
	local rings = {
		Build.spin(ring(model, domeCenter, 8, CFrame.Angles(math.rad(18), 0, 0), white, pink), 25, "Y"),
		Build.spin(ring(model, domeCenter, 9, CFrame.Angles(math.rad(-14), 0, math.rad(12)), lilac, cyan), -18, "Y"),
	}
	-- a column of light that shows when a huge pet is ready
	local beam = Build.ghost(Build.cylinder(model, domeCenter, 60, 4, {
		Name = "Beam",
		Color = Color3.fromRGB(255, 220, 90),
		Material = Enum.Material.Neon,
		Transparency = 1,
	}))

	-- the hopper where pets go in (left) and the glowing pad where the huge comes out (right)
	local hopper = center + Vector3.new(-12, 2.6, -2)
	for k = 0, 3 do
		Build.cylinder(model, hopper + Vector3.new(0, k * 1.1, 0), 1.1, 2.4 + k * 1.1, { Color = if k == 3 then pink else white })
	end
	Build.limb(model, hopper + Vector3.new(0, 2, 0), domeCenter + Vector3.new(-5, -2, -1), 1, { Color = lilac })
	local pad = Build.cylinder(model, center + Vector3.new(12, 2.6, -2), 0.4, 5, { Color = cyan })
	Build.cylinder(model, center + Vector3.new(12, 2.6, -2), 0.3, 6, { Color = white })
	Build.spin(Build.part(model, {
		Size = Vector3.new(3.4, 0.2, 0.5),
		CFrame = CFrame.new(pad.Position + Vector3.new(0, 0.35, 0)),
		Color = white,
		CanCollide = false,
	}), 90, "Y")

	-- console facing the path, with a screen and big friendly buttons
	local consoleCF = CFrame.new(center + Vector3.new(0, 0, -15))
	Build.part(model, { Name = "Console", Size = Vector3.new(7, 3.6, 3), CFrame = consoleCF * CFrame.new(0, 1.8, 0), Color = white })
	Build.part(model, { Size = Vector3.new(7.4, 0.5, 3.6), CFrame = consoleCF * CFrame.new(0, 3.8, 0.2) * CFrame.Angles(math.rad(-20), 0, 0), Color = lilac })
	local screen = Build.part(model, {
		Size = Vector3.new(4.6, 2.2, 0.3),
		CFrame = consoleCF * CFrame.new(0, 5.3, 1) * CFrame.Angles(math.rad(-15), 0, 0),
		Color = Color3.fromRGB(40, 45, 80),
	})
	for k, color in ipairs({ pink, cyan, Color3.fromRGB(255, 205, 50), Color3.fromRGB(90, 220, 120) }) do
		Build.part(model, {
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.3, 0.7, 0.7),
			CFrame = consoleCF * CFrame.new(-2.4 + (k - 1) * 1.6, 4.1, -0.6) * CFrame.Angles(math.rad(-20), 0, 0) * CFrame.Angles(0, 0, math.rad(90)),
			Color = color,
		})
	end
	local screenGui = Instance.new("SurfaceGui")
	screenGui.Face = Enum.NormalId.Front
	screenGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	screenGui.PixelsPerStud = 50
	screenGui.LightInfluence = 0
	screenGui.Parent = screen
	local screenText = Instance.new("TextLabel")
	screenText.BackgroundTransparency = 1
	screenText.Size = UDim2.fromScale(1, 1)
	screenText.Font = Enum.Font.GothamBlack
	screenText.TextScaled = true
	screenText.TextColor3 = cyan
	screenText.Text = "READY"
	screenText.Parent = screenGui
	local pad2 = Instance.new("UIPadding")
	pad2.PaddingTop = UDim.new(0.15, 0)
	pad2.PaddingBottom = UDim.new(0.15, 0)
	pad2.PaddingLeft = UDim.new(0.06, 0)
	pad2.PaddingRight = UDim.new(0.06, 0)
	pad2.Parent = screenText

	-- title and status above the machine
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(320, 90)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 12, 0)
	gui.MaxDistance = 120
	gui.Adornee = orb
	gui.Parent = orb
	for k, name in ipairs({ "Title", "Status" }) do
		local label = Instance.new("TextLabel")
		label.Name = name
		label.BackgroundTransparency = 1
		label.Position = UDim2.fromScale(0, (k - 1) * 0.55)
		label.Size = UDim2.fromScale(1, if k == 1 then 0.55 else 0.45)
		label.Font = Enum.Font.GothamBlack
		label.TextScaled = true
		label.TextColor3 = if k == 1 then Color3.new(1, 1, 1) else Color3.fromRGB(255, 200, 230)
		label.TextStrokeTransparency = 0.4
		label.Text = if k == 1 then "PET AURA MACHINE" else "3 same pets → 1 with an AURA"
		label.Parent = gui
	end

	return {
		Model = model,
		Orb = orb,
		Status = gui.Status,
		Screen = screenText,
		Light = light,
		Sparkles = sparkles,
		Rings = rings,
		Beam = beam,
	}
end

-- Desert props -----------------------------------------------------------------------------------

local function palm(parent, rng, base, s)
	local model = Build.model(parent, "Palm")
	local height = rng:NextNumber(8, 11) * s
	local bend = Vector3.new(rng:NextNumber(-1.5, 1.5), 0, rng:NextNumber(-1.5, 1.5)) * s
	-- a curved trunk of rings getting thinner
	local previous = base - Vector3.new(0, 0.3, 0)
	local segments = 7
	for k = 1, segments do
		local t = k / segments
		local p = base + Vector3.new(0, height * t, 0) + bend * t * t
		Build.limb(model, previous, p, (1.3 - t * 0.4) * s, { Color = if k % 2 == 0 then Color3.fromRGB(195, 140, 90) else Color3.fromRGB(175, 120, 75) })
		Build.ball(model, p, (1.25 - t * 0.4) * s, { Color = Color3.fromRGB(185, 130, 80) })
		previous = p
	end
	local top = previous
	-- fronds: each droops in two pieces
	for k = 1, 8 do
		local yaw = k / 8 * math.pi * 2 + rng:NextNumber(-0.2, 0.2)
		local dir = Vector3.new(math.cos(yaw), 0, math.sin(yaw))
		local mid = top + dir * 2.6 * s + Vector3.new(0, 0.9 * s, 0)
		local tip = top + dir * 5.2 * s - Vector3.new(0, 0.6 * s, 0)
		local color = Build.vary(rng, PALM_GREEN, 0.04)
		for _, seg in ipairs({ { top, mid }, { mid, tip } }) do
			local a, b = seg[1], seg[2]
			Build.part(model, {
				Size = Vector3.new(1.4 * s, 0.2, (b - a).Magnitude + 0.2),
				CFrame = CFrame.lookAt((a + b) / 2, b),
				Color = color,
				CanCollide = false,
			})
		end
	end
	for k = 1, 4 do
		local a = k / 4 * math.pi * 2
		Build.ball(model, top + Vector3.new(math.cos(a) * 0.7 * s, -0.7 * s, math.sin(a) * 0.7 * s), 0.9 * s, { Color = Color3.fromRGB(140, 90, 50) })
	end
	return model
end

local function pot(parent, rng, base)
	local model = Build.model(parent, "Pot")
	local color = pick(rng, { Color3.fromRGB(230, 130, 80), Color3.fromRGB(215, 110, 70), Color3.fromRGB(240, 170, 100) })
	local s = rng:NextNumber(0.8, 1.2)
	Build.cylinder(model, base, 0.3 * s, 1 * s, { Color = color })
	Build.ball(model, base + Vector3.new(0, 1.1 * s, 0), 2.1 * s, { Color = color })
	Build.cylinder(model, base + Vector3.new(0, 1.3 * s, 0), 0.35 * s, 2.15 * s, { Color = pick(rng, { LAPIS, TURQUOISE, WHITE }) })
	Build.cylinder(model, base + Vector3.new(0, 2, 0) * s, 0.9 * s, 0.9 * s, { Color = color })
	Build.cylinder(model, base + Vector3.new(0, 2.8, 0) * s, 0.25 * s, 1.3 * s, { Color = color })
	return model
end

local function camel(parent, base, yaw)
	local model = Build.model(parent, "Camel")
	local frame = CFrame.new(base) * CFrame.Angles(0, yaw, 0)
	local fur = Color3.fromRGB(230, 180, 115)
	local function at(x, y, z)
		return (frame * CFrame.new(x, y, z)).Position
	end
	for _, x in ipairs({ -0.9, 0.9 }) do
		for _, z in ipairs({ -1.6, 1.6 }) do
			Build.limb(model, at(x, 0, z), at(x, 3.4, z), 0.6, { Color = fur })
			Build.ball(model, at(x, 0.2, z), 0.8, { Color = fur:Lerp(Color3.new(0, 0, 0), 0.2) })
		end
	end
	Build.part(model, { Size = Vector3.new(2.6, 2, 5), CFrame = frame * CFrame.new(0, 4.2, 0), Color = fur })
	Build.ball(model, at(0, 5.3, -0.6), 2.2, { Color = fur })
	Build.ball(model, at(0, 5.4, 1), 2, { Color = fur })
	-- a colourful saddle blanket
	Build.part(model, { Size = Vector3.new(2.8, 0.2, 1.4), CFrame = frame * CFrame.new(0, 5.2, 0.2), Color = RED })
	Build.part(model, { Size = Vector3.new(2.9, 0.22, 0.3), CFrame = frame * CFrame.new(0, 5.25, 0.2), Color = GOLD })
	Build.limb(model, at(0, 4.6, -2.3), at(0, 7, -3.4), 0.9, { Color = fur })
	Build.part(model, { Size = Vector3.new(1.2, 1.1, 2), CFrame = frame * CFrame.new(0, 7.3, -3.9), Color = fur })
	for _, x in ipairs({ -0.4, 0.4 }) do
		Build.ball(model, at(x, 7.6, -4.4), 0.3, { Color = Color3.fromRGB(40, 45, 75) })
		Build.ball(model, at(x, 8, -3.4), 0.4, { Color = fur })
	end
	return model
end

-- Building the area -------------------------------------------------------------------------------

-- A friendly little desert snake, coiled up resting on the sand: a body of
-- balls getting thinner to the tail, a round head with big eyes and a smile.
local function snake(parent, at)
	local model = Build.model(parent, "Snake")
	local y = Config.GROUND_Y
	local BODY = Color3.fromRGB(150, 210, 80)
	local SPOT = Color3.fromRGB(250, 200, 60)
	local count = 14
	for k = 0, count - 1 do
		local a = k / count * math.pi * 2.6
		local r = 2.2 - k * 0.1
		local d = 1.5 - k * 0.07
		Build.ball(model, Vector3.new(at.X + math.cos(a) * r, y + d / 2 - 0.1, at.Z + math.sin(a) * r), d, {
			Color = if k % 3 == 1 then SPOT else BODY,
			CanCollide = false,
		})
	end
	-- the head, raised up a little from the start of the coil
	local head = Vector3.new(at.X + 2.4, y + 1.5, at.Z + 0.4)
	Build.ball(model, head - Vector3.new(0.3, 0.7, 0), 1.3, { Color = BODY, CanCollide = false })
	Build.ball(model, head, 1.7, { Color = BODY, CanCollide = false })
	for _, dz in ipairs({ -0.4, 0.4 }) do
		Build.ball(model, head + Vector3.new(0.6, 0.35, dz), 0.6, { Color = Color3.new(1, 1, 1), CanCollide = false })
		Build.ball(model, head + Vector3.new(0.82, 0.38, dz), 0.3, { Color = Color3.fromRGB(40, 40, 60), CanCollide = false })
	end
	Build.part(model, {
		Size = Vector3.new(0.1, 0.12, 0.6),
		CFrame = CFrame.new(head + Vector3.new(0.82, -0.2, 0)),
		Color = Color3.fromRGB(90, 60, 50),
		CanCollide = false,
	})
	return model
end

function Sahara.build(ctx)
	local folder, rng, space = ctx.Folder, ctx.Rng, ctx.Space
	local x0, x1, half = ctx.X0, ctx.X1, ctx.Half
	local deco = Build.folder(folder, "Decor")
	local terrain = ctx.Terrain

	-- rolling dunes and sandstone outcrops behind the walls
	for x = x0, x1, 12 do
		for _, side in ipairs({ -1, 1 }) do
			terrain:FillBall(
				Vector3.new(x + rng:NextNumber(-4, 4), rng:NextNumber(-10, -5), side * rng:NextNumber(half + 32, half + 60)),
				rng:NextNumber(14, 22),
				Enum.Material.Sand
			)
		end
	end
	for _ = 1, 4 do
		local side = if rng:NextNumber() < 0.5 then -1 else 1
		terrain:FillBall(Vector3.new(rng:NextNumber(x0, x1), rng:NextNumber(-2, 1), side * rng:NextNumber(half + 20, half + 45)), rng:NextNumber(4, 7), Enum.Material.Sandstone)
	end

	-- limestone walls on both sides
	for _, side in ipairs({ -1, 1 }) do
		limestoneWall(deco, rng, x0, x1, side * (half + 3))
	end

	-- pyramids and a sphinx beyond the walls
	pyramid(deco, Vector3.new(x0 + 55, 0, half + 42), 56, -1)
	pyramid(deco, Vector3.new(x0 + 18, 0, half + 50), 32, -1)
	pyramid(deco, Vector3.new(x0 + 82, 0, -(half + 46)), 46, 1)
	sphinx(deco, Vector3.new(x0 + 40, 0, -(half + 20)), CFrame.Angles(0, math.rad(180), 0))

	-- an oasis: a little pool with reeds and palms
	local oasis = Vector3.new(x0 + 84, 0, half - 12)
	terrain:FillCylinder(CFrame.new(oasis + Vector3.new(0, -2, 0)), 4, 6.5, Enum.Material.Air)
	terrain:FillCylinder(CFrame.new(oasis + Vector3.new(0, -2.5, 0)), 3, 6, Enum.Material.Water)
	terrain:FillCylinder(CFrame.new(oasis + Vector3.new(0, -4.5, 0)), 1, 7, Enum.Material.Sand)
	for k = 0, 9 do
		local a = k / 10 * math.pi * 2
		local p = oasis + Vector3.new(math.cos(a) * 6.6, 0, math.sin(a) * 6.6)
		if k % 3 == 0 then
			palm(deco, rng, p + Vector3.new(math.cos(a), 0, math.sin(a)) * 1.5, rng:NextNumber(0.8, 1))
		else
			for _ = 1, 3 do
				Build.ghost(Build.block(deco, p + Vector3.new(rng:NextNumber(-0.5, 0.5), 0, rng:NextNumber(-0.5, 0.5)), Vector3.new(0.18, rng:NextNumber(1.5, 2.5), 0.18), {
					Color = Color3.fromRGB(110, 200, 90),
				}))
			end
		end
	end
	space:add(oasis, 9)

	-- Cleopatra's temple on the left, scaled down to fit
	local templeCenter = Vector3.new(x0 + 64, 0, -(half - 14))
	Build.scale(cleopatraTemple(deco, rng, templeCenter), templeCenter, 0.5)
	space:add(templeCenter, 12)
	space:add(templeCenter + Vector3.new(-6, 0, 8), 5)
	space:add(templeCenter + Vector3.new(6, 0, 8), 5)

	-- the fusion machine on the right
	local machineCenter = Vector3.new(x0 + 34, 0, half - 14)
	local machine = fusionMachine(deco, machineCenter)
	Build.scale(machine.Model, machineCenter, 0.55)
	machine.Status.Parent.StudsOffsetWorldSpace = Vector3.new(0, 9, 0)
	ctx.World.Fusion = machine
	space:add(machineCenter, 9)
	space:add(machineCenter + Vector3.new(0, 0, -8.5), 4)
	-- the circle in front of the console: step on it to open the machine
	-- (the client opens and closes the screen; see AuraMachine.luau)
	-- (on the real ground, which sits a little above Y = 0 here, and tall
	-- enough to always show above the sand)
	local circleAt = machineCenter + Vector3.new(0, 0, -14)
	circleAt = Vector3.new(circleAt.X, math.max(ctx.World.groundAt(circleAt.X, circleAt.Z) or 0, Config.GROUND_Y) - 0.4, circleAt.Z)
	Build.cylinder(machine.Model, circleAt, 1.2, 8, { Name = "CircleRim", Color = Color3.fromRGB(250, 250, 255) })
	machine.Circle = Build.cylinder(machine.Model, circleAt, 1.35, 7, { Name = "AuraCircle", Color = Color3.fromRGB(200, 185, 255) })
	Build.cylinder(machine.Model, circleAt + Vector3.new(0, 1.35, 0), 0.04, 5.6, { Color = Color3.fromRGB(255, 120, 190), CanCollide = false })
	Build.cylinder(machine.Model, circleAt + Vector3.new(0, 1.37, 0), 0.04, 4.8, { Color = Color3.fromRGB(200, 185, 255), CanCollide = false })
	local hint = Instance.new("BillboardGui")
	hint.Name = "StepHint"
	hint.Size = UDim2.fromOffset(160, 34)
	hint.StudsOffsetWorldSpace = Vector3.new(0, 3, 0)
	hint.MaxDistance = 45
	hint.Adornee = machine.Circle
	hint.Parent = machine.Circle
	local hintText = Instance.new("TextLabel")
	hintText.BackgroundTransparency = 1
	hintText.Size = UDim2.fromScale(1, 1)
	hintText.Font = Enum.Font.FredokaOne
	hintText.TextScaled = true
	hintText.TextColor3 = Color3.new(1, 1, 1)
	hintText.TextStrokeColor3 = Color3.fromRGB(70, 40, 120)
	hintText.TextStrokeTransparency = 0
	hintText.Text = "Step here to open"
	hintText.Parent = hint
	space:add(circleAt, 5)

	-- a snake's trail: the wavy groove a snake left crossing the sand from
	-- one wall to the other, and the snake itself resting at the end of it
	local trailX = x0 + 48
	local trail = {}
	for z = half - 1, -(half - 6), -1.5 do
		table.insert(trail, Vector3.new(trailX + math.sin(z / 3.5) * 2.6, 0, z))
		space:add(Vector3.new(trailX, 0, z), 3)
	end
	ctx.World.paintPath(deco, "SnakeTrail", trail, 1.8, Color3.fromRGB(214, 158, 88), Color3.fromRGB(236, 186, 112))
	local tail = trail[#trail]
	snake(deco, Vector3.new(tail.X, 0, tail.Z - 1.5))
	space:add(Vector3.new(tail.X, 0, tail.Z - 2), 3.5)

	ctx.reserveSpots() -- breakables get their room before the small props

	-- a camel resting near the path
	local camelSpot = space:find(rng, x0 + 12, x0 + 24, -half + 8, -half + 14, 4)
	if camelSpot then
		camel(deco, camelSpot, math.rad(rng:NextNumber(0, 360)))
	end

	-- palms, pottery and sandstone rocks
	for _ = 1, 4 do
		local base = space:find(rng, x0 + 6, x1 - 6, -half + 4, half - 4, 3)
		if base then
			palm(deco, rng, base, rng:NextNumber(0.9, 1.1))
		end
	end
	for _ = 1, 4 do
		local base = space:find(rng, x0 + 6, x1 - 6, -half + 4, half - 4, 2)
		if base then
			for k = 1, rng:NextInteger(2, 3) do
				pot(deco, rng, base + Vector3.new(k * 1.6 - 3, 0, rng:NextNumber(-0.8, 0.8)))
			end
		end
	end
	for _ = 1, 5 do
		local base = space:find(rng, x0 + 6, x1 - 6, -half + 4, half - 4, 2.5)
		if base then
			Build.rock(deco, rng, base, rng:NextNumber(1.6, 2.8), Color3.fromRGB(235, 175, 110))
		end
	end
end

return Sahara
