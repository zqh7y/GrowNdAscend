-- Area 3: Frozen Peaks. Snowy ground with patches of ice, a frozen sea on
-- both sides (cracks, fishing holes, pressure ridges, snow-topped floes,
-- icebergs and penguins), an igloo made of real snow-brick courses, a
-- snowman and a sled, an ice arch with icicles, ice walls, crystal clusters,
-- snow-laden pines, snowy rocks and falling snow. Breakable: ice cubes (a
-- few kinds: clear, with a frozen fish, with a gem, and a stack).
local Build = require(script.Parent.Build)

local Frozen = {}

Frozen.GROUND = Enum.Material.Snow

local ICE = Color3.fromRGB(150, 225, 255)
local ICE_DEEP = Color3.fromRGB(90, 180, 245)
local SNOW = Color3.fromRGB(248, 252, 255)
local SNOW_SHADE = Color3.fromRGB(220, 235, 250)
local NAVY = Color3.fromRGB(45, 60, 110)
local ORANGE = Color3.fromRGB(255, 150, 40)

local function pick(rng, list)
	return list[rng:NextInteger(1, #list)]
end

local function iceProps(rng, transparency)
	return {
		Color = Build.vary(rng, ICE, 0.04),
		Material = Enum.Material.Glass,
		Transparency = transparency or 0.2,
		Reflectance = 0.05,
	}
end

-- icicles hanging down from a point: three shrinking pieces
local function icicle(parent, top, length)
	for k = 0, 2 do
		local w = 0.5 - k * 0.14
		local h = length / 3
		Build.ghost(Build.part(parent, {
			Size = Vector3.new(w, h, w),
			CFrame = CFrame.new(top - Vector3.new(0, h * (k + 0.5), 0)),
			Color = Color3.fromRGB(200, 240, 255),
			Material = Enum.Material.Glass,
			Transparency = 0.15,
		}))
	end
end

-- Trees, rocks, snowmen -------------------------------------------------------------------

local function pine(parent, rng, base, s)
	local model = Build.model(parent, "Pine")
	Build.cylinder(model, base, 3 * s, 1.1 * s, { Color = Color3.fromRGB(160, 105, 70) })
	local green = Build.vary(rng, Color3.fromRGB(55, 170, 115), 0.04)
	local tiers = rng:NextInteger(4, 5)
	for k = 0, tiers - 1 do
		local width = (8.5 - k * 1.6) * s
		local y = (2.2 + k * 2.3) * s
		local p = base + Vector3.new(0, y, 0)
		-- each tier: a wide disc and a narrower one above it, like a cone
		Build.cylinder(model, p, 1.2 * s, width, { Color = green })
		Build.cylinder(model, p + Vector3.new(0, 1.2 * s, 0), 1.2 * s, width * 0.7, { Color = green:Lerp(Color3.new(1, 1, 1), 0.08) })
		-- snow resting on top, and lumps drooping over the edge
		Build.cylinder(model, p + Vector3.new(0, 2.4 * s, 0), 0.35 * s, width * 0.6, { Color = SNOW })
		for j = 0, 3 do
			local a = j / 4 * math.pi * 2 + k
			Build.ball(model, p + Vector3.new(math.cos(a) * width * 0.45, 1.2 * s, math.sin(a) * width * 0.45), 1.1 * s, { Color = SNOW })
		end
	end
	Build.ball(model, base + Vector3.new(0, (2.2 + tiers * 2.3) * s + 0.6 * s, 0), 1.4 * s, { Color = SNOW })
	return model
end

local function snowman(parent, base, yaw)
	local model = Build.model(parent, "Snowman")
	local frame = CFrame.new(base) * CFrame.Angles(0, yaw, 0)
	local function at(x, y, z)
		return (frame * CFrame.new(x, y, z)).Position
	end
	Build.ball(model, at(0, 1.6, 0), 3.6, { Color = SNOW })
	Build.ball(model, at(0, 4.1, 0), 2.7, { Color = SNOW })
	Build.ball(model, at(0, 6.1, 0), 2, { Color = SNOW })
	for _, x in ipairs({ -0.35, 0.35 }) do
		Build.ball(model, at(x, 6.35, -0.9), 0.3, { Color = NAVY }) -- eyes
	end
	Build.limb(model, at(0, 6.05, -0.9), at(0, 5.95, -2), 0.3, { Color = ORANGE }) -- carrot
	for k = -2, 2 do
		Build.ball(model, at(k * 0.25, 5.55 + math.abs(k) * 0.08, -0.9), 0.16, { Color = NAVY }) -- smile
	end
	for k = 0, 2 do
		Build.ball(model, at(0, 3.5 + k * 0.6, -1.3), 0.3, { Color = NAVY }) -- buttons
	end
	-- scarf and hat
	Build.part(model, { Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.5, 2.3, 2.3), CFrame = frame * CFrame.new(0, 5.25, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(240, 70, 80) })
	Build.part(model, { Size = Vector3.new(0.5, 1.4, 0.2), CFrame = frame * CFrame.new(0.6, 4.6, -1.05) * CFrame.Angles(0, 0, math.rad(10)), Color = Color3.fromRGB(240, 70, 80) })
	Build.cylinder(model, at(0, 6.9, 0), 0.2, 2.2, { Color = NAVY })
	Build.cylinder(model, at(0, 7.1, 0), 1.4, 1.4, { Color = NAVY })
	Build.cylinder(model, at(0, 7.2, 0), 0.3, 1.45, { Color = Color3.fromRGB(240, 70, 80) })
	-- stick arms waving
	for _, side in ipairs({ -1, 1 }) do
		Build.limb(model, at(side * 1.1, 4.3, 0), at(side * 2.6, 5.4, 0), 0.22, { Color = Color3.fromRGB(150, 100, 60) })
		Build.limb(model, at(side * 2.2, 5.1, 0), at(side * 2.5, 5.9, 0), 0.15, { Color = Color3.fromRGB(150, 100, 60) })
	end
	return model
end

local function sled(parent, base, yaw)
	local model = Build.model(parent, "Sled")
	local frame = CFrame.new(base) * CFrame.Angles(0, yaw, 0)
	local wood = Color3.fromRGB(215, 130, 80)
	for k = -1, 1 do
		Build.part(model, { Size = Vector3.new(0.8, 0.2, 4.4), CFrame = frame * CFrame.new(k * 0.9, 0.9, 0), Color = wood })
	end
	for _, x in ipairs({ -1.3, 1.3 }) do
		Build.part(model, { Size = Vector3.new(0.2, 0.2, 4.6), CFrame = frame * CFrame.new(x, 0.1, 0), Color = Color3.fromRGB(240, 70, 80) })
		Build.part(model, { Size = Vector3.new(0.2, 0.2, 1.2), CFrame = frame * CFrame.new(x, 0.45, -2.7) * CFrame.Angles(math.rad(-60), 0, 0), Color = Color3.fromRGB(240, 70, 80) })
		for _, z in ipairs({ -1.4, 1.4 }) do
			Build.part(model, { Size = Vector3.new(0.2, 0.8, 0.2), CFrame = frame * CFrame.new(x, 0.5, z), Color = wood })
		end
	end
	-- a present on the sled
	Build.part(model, { Size = Vector3.new(1.6, 1.4, 1.6), CFrame = frame * CFrame.new(0, 1.7, 0.6), Color = Color3.fromRGB(90, 190, 255) })
	Build.part(model, { Size = Vector3.new(1.65, 1.45, 0.3), CFrame = frame * CFrame.new(0, 1.7, 0.6), Color = Color3.fromRGB(255, 205, 50) })
	Build.part(model, { Size = Vector3.new(0.3, 1.45, 1.65), CFrame = frame * CFrame.new(0, 1.7, 0.6), Color = Color3.fromRGB(255, 205, 50) })
	Build.ball(model, (frame * CFrame.new(0, 2.5, 0.6)).Position, 0.5, { Color = Color3.fromRGB(255, 205, 50) })
	return model
end

local function penguin(parent, base, yaw, s)
	local model = Build.model(parent, "Penguin")
	local frame = CFrame.new(base) * CFrame.Angles(0, yaw, 0)
	local function at(x, y, z)
		return (frame * CFrame.new(x * s, y * s, z * s)).Position
	end
	Build.ball(model, at(0, 1.2, 0), 2 * s, { Color = NAVY })
	Build.ball(model, at(0, 1.1, -0.35), 1.55 * s, { Color = SNOW })
	Build.ball(model, at(0, 2.45, 0), 1.35 * s, { Color = NAVY })
	Build.ball(model, at(0, 2.4, -0.3), 0.95 * s, { Color = SNOW })
	for _, x in ipairs({ -0.22, 0.22 }) do
		Build.ball(model, at(x, 2.6, -0.7), 0.22 * s, { Color = Color3.fromRGB(25, 30, 55) })
		Build.part(model, { Size = Vector3.new(0.5, 0.15, 0.7) * s, CFrame = frame * CFrame.new(x * 1.6 * s, 0.1 * s, -0.4 * s), Color = ORANGE }) -- feet
		Build.part(model, {
			Size = Vector3.new(0.2, 1.2, 0.6) * s,
			CFrame = frame * CFrame.new(x * 4.6 * s, 1.3 * s, 0) * CFrame.Angles(0, 0, math.rad(if x > 0 then -20 else 20)),
			Color = NAVY,
		}) -- flippers
	end
	Build.part(model, { Size = Vector3.new(0.3, 0.2, 0.5) * s, CFrame = frame * CFrame.new(0, 2.35 * s, -0.8 * s), Color = ORANGE }) -- beak
	Build.ball(model, at(0.35, 2.3, -0.62), 0.2 * s, { Color = Color3.fromRGB(255, 160, 190) }) -- blush
	Build.ball(model, at(-0.35, 2.3, -0.62), 0.2 * s, { Color = Color3.fromRGB(255, 160, 190) })
	return model
end

-- The igloo ------------------------------------------------------------------------------------

-- A dome of snow bricks laid in courses that get smaller towards the top,
-- with an entrance tunnel facing the path. Built big, scaled down after.
local function igloo(parent, rng, center)
	local model = Build.model(parent, "Igloo")
	local R = 11
	Build.ball(model, center, R * 2 - 1.2, { Color = SNOW_SHADE }) -- fills the gaps between bricks
	local courses = 7
	for k = 0, courses - 1 do
		local phi = math.rad((k + 0.5) * (84 / courses))
		local r, y = R * math.cos(phi), R * math.sin(phi)
		local count = math.max(6, math.floor(2 * math.pi * r / 3.2))
		local offset = if k % 2 == 0 then 0 else math.pi / count -- staggered joints
		for j = 0, count - 1 do
			local a = j / count * math.pi * 2 + offset
			Build.part(model, {
				Size = Vector3.new(2 * math.pi * r / count - 0.25, R * math.rad(84 / courses) - 0.25, 1.2),
				CFrame = CFrame.new(center) * CFrame.Angles(0, a, 0) * CFrame.new(0, y, -r) * CFrame.Angles(phi, 0, 0),
				Color = if rng:NextNumber() < 0.2 then SNOW_SHADE else SNOW,
			})
		end
	end
	Build.ball(model, center + Vector3.new(0, R - 0.4, 0), 3, { Color = SNOW })
	-- entrance tunnel facing the path (towards Z = 0), with a brick arch at the mouth
	local dir = if center.Z > 0 then -1 else 1
	local tunnel = CFrame.new(center + Vector3.new(0, 0, dir * 11)) * CFrame.Angles(0, math.rad(90), 0)
	Build.part(model, { Shape = Enum.PartType.Cylinder, Size = Vector3.new(8, 9, 9), CFrame = tunnel, Color = SNOW })
	for j = 0, 6 do
		local a = j / 6 * math.pi
		Build.part(model, {
			Size = Vector3.new(1.4, 1.4, 1),
			CFrame = CFrame.new(center + Vector3.new(math.cos(a) * 4.5, math.sin(a) * 4.5, dir * 15)) * CFrame.Angles(0, 0, a),
			Color = SNOW_SHADE,
		})
	end
	Build.block(model, center + Vector3.new(0, 0, dir * 15.05), Vector3.new(4.8, 3.9, 0.2), { Color = Color3.fromRGB(90, 160, 230), CanCollide = false })
	-- a warm light glowing inside the doorway
	local glow = Instance.new("PointLight")
	glow.Color = Color3.fromRGB(255, 200, 130)
	glow.Range = 10
	glow.Brightness = 1.5
	glow.Parent = model:FindFirstChildWhichIsA("BasePart")
	return model
end

-- Ice formations ------------------------------------------------------------------------------------

-- a short wall of ice blocks with snow on top and icicles hanging off
local function iceWall(parent, rng, base)
	local model = Build.model(parent, "IceWall")
	local frame = CFrame.new(base) * CFrame.Angles(0, math.rad(rng:NextNumber(0, 180)), 0)
	local length = rng:NextInteger(3, 4)
	for k = 0, length - 1 do
		local rows = rng:NextInteger(1, 3)
		for row = 0, rows - 1 do
			local props = iceProps(rng, 0.15)
			props.Size = Vector3.new(3.8, 2.8, 2.8) - Vector3.new(0.15, 0.15, 0)
			props.CFrame = frame * CFrame.new((k - length / 2) * 4 + (row % 2) * 1, row * 2.8 + 1.4, 0)
				* CFrame.Angles(0, math.rad(rng:NextNumber(-4, 4)), math.rad(rng:NextNumber(-3, 3)))
			local block = Build.part(model, props)
			if row == rows - 1 then
				Build.part(model, {
					Size = Vector3.new(3.6, 0.5, 2.6),
					CFrame = block.CFrame * CFrame.new(0, 1.6, 0),
					Color = SNOW,
					CanCollide = false,
				})
				for j = -1, 1 do
					icicle(model, (block.CFrame * CFrame.new(j * 1.2, 1.3, -1.45)).Position, rng:NextNumber(0.8, 1.6))
				end
			end
		end
	end
	return model
end

-- a cluster of tall crystals in cool colours
local function crystals(parent, rng, base)
	local model = Build.model(parent, "Crystals")
	local tint = pick(rng, { ICE, Color3.fromRGB(170, 200, 255), Color3.fromRGB(200, 180, 255), Color3.fromRGB(130, 240, 230) })
	for _ = 1, rng:NextInteger(4, 6) do
		local height = rng:NextNumber(3, 8)
		local tilt = CFrame.Angles(math.rad(rng:NextNumber(-25, 25)), math.rad(rng:NextNumber(0, 90)), math.rad(rng:NextNumber(-25, 25)))
		local root = CFrame.new(base + Vector3.new(rng:NextNumber(-1.5, 1.5), -0.3, rng:NextNumber(-1.5, 1.5))) * tilt
		local width = rng:NextNumber(1, 1.8)
		Build.part(model, { Size = Vector3.new(width, height, width), CFrame = root * CFrame.new(0, height / 2, 0), Color = tint, Material = Enum.Material.Glass, Transparency = 0.15 })
		-- pointed tip
		Build.part(model, { Size = Vector3.new(width * 0.6, 0.9, width * 0.6), CFrame = root * CFrame.new(0, height + 0.45, 0), Color = tint:Lerp(Color3.new(1, 1, 1), 0.4), Material = Enum.Material.Glass, Transparency = 0.1 })
		Build.part(model, { Size = Vector3.new(width * 0.25, 0.5, width * 0.25), CFrame = root * CFrame.new(0, height + 1.1, 0), Color = Color3.new(1, 1, 1), Material = Enum.Material.Neon })
	end
	Build.cylinder(model, base - Vector3.new(0, 0.2, 0), 0.6, 4.5, { Color = SNOW })
	return model
end

-- an arch of ice with icicles, standing over a snowy spot
local function iceArch(parent, rng, base, yaw)
	local model = Build.model(parent, "IceArch")
	local frame = CFrame.new(base) * CFrame.Angles(0, yaw, 0)
	local r = 5
	for k = 0, 8 do
		local a = k / 8 * math.pi
		local p = frame * CFrame.new(math.cos(a) * r, math.sin(a) * r + 2, 0)
		local props = iceProps(rng, 0.12)
		props.Size = Vector3.new(2.2, 2.2, 2.4)
		props.CFrame = p * CFrame.Angles(0, 0, a)
		Build.part(model, props)
		if k > 0 and k < 8 then
			icicle(model, (p * CFrame.new(0, -1.1, 0)).Position, rng:NextNumber(0.8, 1.8))
		end
	end
	for _, x in ipairs({ -r, r }) do
		local props = iceProps(rng, 0.12)
		props.Size = Vector3.new(2.4, 2.4, 2.6)
		props.CFrame = frame * CFrame.new(x, 1.2, 0)
		Build.part(model, props)
	end
	Build.part(model, { Size = Vector3.new(3, 0.6, 2.8), CFrame = frame * CFrame.new(0, r + 3.4, 0), Color = SNOW, CanCollide = false })
	return model
end

-- The frozen sea ----------------------------------------------------------------------------------

local function iceberg(parent, rng, base)
	local model = Build.model(parent, "Iceberg")
	local size = rng:NextNumber(8, 14)
	-- faceted chunks of blue ice, whiter towards the top, with a snowy cap
	for k = 0, 3 do
		local s = size * (1 - k * 0.22)
		Build.part(model, {
			Size = Vector3.new(s * rng:NextNumber(0.8, 1.1), s * 0.55, s * rng:NextNumber(0.8, 1.1)),
			CFrame = CFrame.new(base + Vector3.new(rng:NextNumber(-1.5, 1.5), -1.5 + k * s * 0.4, rng:NextNumber(-1.5, 1.5)))
				* CFrame.Angles(math.rad(rng:NextNumber(-8, 8)), math.rad(rng:NextNumber(0, 90)), math.rad(rng:NextNumber(-8, 8))),
			Color = ICE_DEEP:Lerp(SNOW, 0.25 + k * 0.2),
		})
	end
	Build.ball(model, base + Vector3.new(0, size * 1.25, 0), size * 0.35, { Color = SNOW })
	return model
end

local function floe(parent, rng, p)
	local model = Build.model(parent, "Floe")
	local size = Vector3.new(rng:NextNumber(4, 9), 0.7, rng:NextNumber(4, 8))
	local cf = CFrame.new(p + Vector3.new(0, 0.3, 0)) * CFrame.Angles(0, math.rad(rng:NextNumber(0, 90)), 0)
	Build.part(model, { Size = size, CFrame = cf, Color = Color3.fromRGB(175, 225, 250) })
	Build.part(model, { Size = size - Vector3.new(1, 0, 1) + Vector3.new(0, 0.1, 0), CFrame = cf * CFrame.new(0, 0.1, 0), Color = SNOW })
	return model
end

-- zigzag cracks in the sea ice, flush with the surface
local function crack(parent, rng, start)
	local p = start
	local yaw = rng:NextNumber(0, math.pi * 2)
	for _ = 1, rng:NextInteger(4, 7) do
		yaw += rng:NextNumber(-0.7, 0.7)
		local length = rng:NextNumber(1.5, 3)
		local q = p + Vector3.new(math.cos(yaw) * length, 0, math.sin(yaw) * length)
		Build.ghost(Build.part(parent, {
			Size = Vector3.new(0.18, 0.05, length + 0.1),
			CFrame = CFrame.lookAt((p + q) / 2, q),
			Color = ICE_DEEP,
		}))
		p = q
	end
end

-- a row of tilted ice slabs pushed up where two sheets of ice meet
local function pressureRidge(parent, rng, start, yaw)
	local dir = Vector3.new(math.cos(yaw), 0, math.sin(yaw))
	for k = 0, rng:NextInteger(5, 8) do
		local p = start + dir * k * 1.6
		Build.part(parent, {
			Size = Vector3.new(rng:NextNumber(1.2, 2), rng:NextNumber(1.2, 2.6), 0.6),
			CFrame = CFrame.lookAt(p, p + dir) * CFrame.Angles(math.rad(rng:NextNumber(-35, 35)), math.rad(90), 0),
			Color = Color3.fromRGB(185, 230, 255):Lerp(SNOW, rng:NextNumber(0, 0.4)),
		})
	end
end

-- Building the area ----------------------------------------------------------------------------------

function Frozen.build(ctx)
	local folder, rng, space = ctx.Folder, ctx.Rng, ctx.Space
	local x0, x1, half, side = ctx.X0, ctx.X1, ctx.Half, ctx.Side
	local deco = Build.folder(folder, "Decor")
	local terrain = ctx.Terrain
	local length = x1 - x0

	-- a few glassy ice patches in the snow
	for _ = 1, 5 do
		local c = Vector3.new(rng:NextNumber(x0 + 8, x1 - 8), -2, rng:NextNumber(-half + 8, half - 8))
		terrain:ReplaceMaterial(Region3.new(c - Vector3.new(5, 2, 4), c + Vector3.new(5, 2, 4)):ExpandToGrid(4), 4, Enum.Material.Snow, Enum.Material.Ice)
	end

	-- the frozen sea: a step down from the snowy shore, then glacier ice with
	-- lighter and darker patches, cracks, fishing holes, ridges, floes,
	-- icebergs and penguins
	for _, s in ipairs({ -1, 1 }) do
		local width = side - (half + 6)
		local cz = s * (half + 6 + width / 2)
		terrain:FillBlock(CFrame.new(x0 + length / 2, -2, cz), Vector3.new(length, 4, width), Enum.Material.Air)
		terrain:FillBlock(CFrame.new(x0 + length / 2, -8, cz), Vector3.new(length, 8, width), Enum.Material.Glacier)
		for _ = 1, 6 do
			local c = Vector3.new(rng:NextNumber(x0, x1), -6, s * rng:NextNumber(half + 10, half + 60))
			terrain:ReplaceMaterial(Region3.new(c - Vector3.new(7, 2, 6), c + Vector3.new(7, 2, 6)):ExpandToGrid(4), 4, Enum.Material.Glacier, Enum.Material.Ice)
		end

		local sea = Build.folder(deco, "FrozenSea")
		for _ = 1, 10 do
			crack(sea, rng, Vector3.new(rng:NextNumber(x0 + 4, x1 - 4), -3.97, s * rng:NextNumber(half + 10, half + 60)))
		end
		for _ = 1, 3 do
			pressureRidge(sea, rng, Vector3.new(rng:NextNumber(x0 + 5, x1 - 20), -4, s * rng:NextNumber(half + 14, half + 55)), rng:NextNumber(-0.5, 0.5))
		end
		for _ = 1, 6 do
			floe(sea, rng, Vector3.new(rng:NextNumber(x0 + 4, x1 - 4), -4, s * rng:NextNumber(half + 12, half + 58)))
		end
		for _ = 1, 2 do
			iceberg(sea, rng, Vector3.new(rng:NextNumber(x0 + 10, x1 - 10), -4, s * rng:NextNumber(half + 25, half + 55)))
		end
		-- a fishing hole with a penguin waiting beside it
		local hole = Vector3.new(rng:NextNumber(x0 + 15, x1 - 15), -4, s * rng:NextNumber(half + 14, half + 22))
		terrain:FillCylinder(CFrame.new(hole + Vector3.new(0, -1.5, 0)), 3, 3, Enum.Material.Water)
		for j = 0, 7 do
			local a = j / 8 * math.pi * 2
			Build.ball(sea, hole + Vector3.new(math.cos(a) * 3.2, 0.1, math.sin(a) * 3.2), 1.1, { Color = SNOW })
		end
		penguin(sea, hole + Vector3.new(4.5, 0, 0), math.rad(90), 1)
		-- a little group of penguins
		local group = Vector3.new(rng:NextNumber(x0 + 10, x1 - 10), -4, s * rng:NextNumber(half + 28, half + 45))
		for j = 1, 4 do
			penguin(sea, group + Vector3.new(rng:NextNumber(-3, 3), 0, rng:NextNumber(-3, 3)), rng:NextNumber(0, math.pi * 2), rng:NextNumber(0.7, 1.1))
		end
	end

	-- snowy banks along the shore
	for x = x0, x1, 10 do
		for _, s in ipairs({ -1, 1 }) do
			terrain:FillBall(Vector3.new(x + rng:NextNumber(-3, 3), -3, s * (half + rng:NextNumber(0, 4))), rng:NextNumber(4, 6), Enum.Material.Snow)
		end
	end

	-- the igloo with a snowman and a sled outside
	local iglooCenter = Vector3.new(x0 + 64, 0, half - 12)
	Build.scale(igloo(deco, rng, iglooCenter), iglooCenter, 0.65)
	space:add(iglooCenter, 8)
	space:add(iglooCenter + Vector3.new(0, 0, -10), 4)
	snowman(deco, iglooCenter + Vector3.new(-9, 0, -4), math.rad(-30))
	sled(deco, iglooCenter + Vector3.new(8.5, 0, -3), math.rad(15))
	space:add(iglooCenter + Vector3.new(-9, 0, -4), 3)
	space:add(iglooCenter + Vector3.new(8.5, 0, -3), 3)

	-- an ice arch on the other side
	local archBase = Vector3.new(x0 + 30, 0, -(half - 9))
	iceArch(deco, rng, archBase, 0)
	space:add(archBase, 7)

	ctx.reserveSpots() -- breakables get their room before the small props

	-- ice walls, crystal clusters, snowy rocks, pines and drifts
	for _ = 1, 3 do
		local base = space:find(rng, x0 + 12, x1 - 12, -half + 8, half - 8, 7)
		if base then
			Build.scale(iceWall(deco, rng, base), base, 0.8)
		end
	end
	for _ = 1, 6 do
		local base = space:find(rng, x0 + 6, x1 - 6, -half + 4, half - 4, 3)
		if base then
			Build.scale(crystals(deco, rng, base), base, rng:NextNumber(0.6, 0.85))
		end
	end
	for _ = 1, 5 do
		local base = space:find(rng, x0 + 6, x1 - 6, -half + 4, half - 4, 2.5)
		if base then
			Build.rock(deco, rng, base, rng:NextNumber(1.6, 2.6), Color3.fromRGB(165, 180, 215), SNOW)
		end
	end
	for x = x0 + 6, x1 - 6, 10 do
		for _, s in ipairs({ -1, 1 }) do
			local base = Vector3.new(x + rng:NextNumber(-3, 3), 0, s * rng:NextNumber(half - 4, half - 2))
			if space:free(base, 3.5) then
				pine(deco, rng, base, rng:NextNumber(0.7, 1))
				space:add(base, 3.5)
			end
		end
	end
	for _ = 1, 5 do
		local base = space:find(rng, x0 + 6, x1 - 6, -half + 6, half - 6, 3)
		if base then
			terrain:FillBall(base + Vector3.new(0, -0.5, 0), rng:NextNumber(2.5, 3.5), Enum.Material.Snow)
		end
	end

	-- falling snow over the whole area
	local sky = Build.ghost(Build.part(deco, {
		Name = "Snowfall",
		Size = Vector3.new(length, 1, half * 2 + 30),
		CFrame = CFrame.new(x0 + length / 2, 45, 0),
		Transparency = 1,
	}))
	local snow = Instance.new("ParticleEmitter")
	snow.Color = ColorSequence.new(Color3.new(1, 1, 1))
	snow.Size = NumberSequence.new(0.3)
	snow.Transparency = NumberSequence.new(0.1)
	snow.Rate = 90
	snow.Lifetime = NumberRange.new(7, 9)
	snow.Speed = NumberRange.new(4, 6)
	snow.SpreadAngle = Vector2.new(20, 20)
	snow.EmissionDirection = Enum.NormalId.Bottom
	snow.Parent = sky
end

-- Ice cubes: the Frozen Peaks' breakables ----------------------------------------------------------

-- a clear cube with bright bevelled edges, a snowy top and a sparkle
local function cube(model, rng, center, size)
	local cf = CFrame.new(center) -- square to its hop direction, so the face sits on the front
	local props = iceProps(rng, 0.25)
	props.Size = Vector3.one * size
	props.CFrame = cf
	local body = Build.part(model, props)
	-- light edges down the four corners
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

function Frozen.breakable(parent, position, rng)
	local model = Build.model(parent, "Ice Cube")
	local kind = rng:NextInteger(1, 4)
	local body, cf
	if kind == 4 then
		-- a stack: a big cube with a smaller one on top
		body, cf = cube(model, rng, position + Vector3.new(0, 1.8, 0), 3.6)
		cube(model, rng, position + Vector3.new(0.3, 4.5, 0.2), 2)
	else
		body, cf = cube(model, rng, position + Vector3.new(0, 2, 0), 4)
		if kind == 2 then
			-- a fish frozen inside
			local fish = pick(rng, { ORANGE, Color3.fromRGB(255, 120, 170), Color3.fromRGB(110, 200, 255) })
			Build.part(model, { Size = Vector3.new(0.8, 1, 2), CFrame = cf * CFrame.Angles(0, math.rad(30), 0), Color = fish, CanCollide = false })
			Build.part(model, { Size = Vector3.new(0.2, 0.9, 0.7), CFrame = cf * CFrame.Angles(0, math.rad(30), 0) * CFrame.new(0, 0, 1.2), Color = fish, CanCollide = false })
			Build.ball(model, (cf * CFrame.Angles(0, math.rad(30), 0) * CFrame.new(0.3, 0.2, -0.6)).Position, 0.25, { Color = NAVY, CanCollide = false })
		elseif kind == 3 then
			-- a glowing gem inside
			local gem = pick(rng, { Color3.fromRGB(255, 90, 170), Color3.fromRGB(170, 110, 255), Color3.fromRGB(80, 230, 170) })
			Build.part(model, { Size = Vector3.new(1.2, 1.2, 1.2), CFrame = cf * CFrame.Angles(math.rad(45), 0, math.rad(45)), Color = gem, Material = Enum.Material.Neon, CanCollide = false })
		end
	end
	-- a face on the front, the way it hops (the model turns as it moves)
	local size = body.Size.X
	Build.face(model, CFrame.new(body.Position + Vector3.new(0, 0.1 * size, -size / 2 - 0.05)), size / 4)
	model.PrimaryPart = body
	return model
end

return Frozen
