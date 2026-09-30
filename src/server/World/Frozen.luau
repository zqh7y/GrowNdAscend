-- Area 3: Frozen Peaks. Snow ground, a frozen sea on both sides with ice
-- floes and icebergs, an igloo, ice walls and crystal formations, snowy pines
-- and falling snow. Breakable: ice cubes.
local Build = require(script.Parent.Build)

local Frozen = {}

Frozen.GROUND = Enum.Material.Snow

local ICE = Color3.fromRGB(170, 225, 250)
local SNOW = Color3.fromRGB(245, 250, 255)

local function iceProps(rng, transparency)
	return {
		Color = Build.vary(rng, ICE, 0.05),
		Material = Enum.Material.Ice,
		Transparency = transparency or 0.15,
		Reflectance = 0.05,
	}
end

local function pine(parent, rng, base, scale)
	local model = Build.model(parent, "Pine")
	Build.cylinder(model, base, 3 * scale, 1.2 * scale, { Color = Color3.fromRGB(95, 65, 45), Material = Enum.Material.Wood })
	local green = Build.vary(rng, Color3.fromRGB(40, 95, 70))
	for k = 0, 3 do
		local width = (8 - k * 1.8) * scale
		local y = (2.5 + k * 2.6) * scale
		Build.cylinder(model, base + Vector3.new(0, y, 0), 2.6 * scale, width, { Color = green, Material = Enum.Material.Grass })
		-- snow on each layer
		Build.cylinder(model, base + Vector3.new(0, y + 2.6 * scale, 0), 0.4 * scale, width * 0.8, { Color = SNOW, Material = Enum.Material.Snow })
	end
end

local function igloo(parent, center)
	local model = Build.model(parent, "Igloo")
	Build.ball(model, center, 22, { Color = SNOW, Material = Enum.Material.Snow })
	-- rings suggesting snow bricks
	for k = 1, 3 do
		local y = k * 2.6
		local r = math.sqrt(11 ^ 2 - y ^ 2) * 2 + 0.2
		Build.part(model, {
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.3, r, r),
			CFrame = CFrame.new(center + Vector3.new(0, y, 0)) * CFrame.Angles(0, 0, math.rad(90)),
			Color = Color3.fromRGB(215, 230, 245),
			Material = Enum.Material.Snow,
			CanCollide = false,
		})
	end
	-- entrance tunnel facing the path (toward Z = 0) and a dark doorway
	local dir = if center.Z > 0 then -1 else 1
	Build.part(model, {
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(8, 9, 9),
		CFrame = CFrame.new(center + Vector3.new(0, 0, dir * 11)) * CFrame.Angles(0, math.rad(90), 0),
		Color = SNOW,
		Material = Enum.Material.Snow,
	})
	Build.block(model, center + Vector3.new(0, 0, dir * 15.05), Vector3.new(4.5, 3.8, 0.2), { Color = Color3.fromRGB(25, 30, 45), CanCollide = false })
	return model
end

-- a short wall of ice blocks
local function iceWall(parent, rng, base)
	local model = Build.model(parent, "IceWall")
	local yaw = rng:NextNumber(0, 180)
	local length = rng:NextInteger(3, 5)
	local frame = CFrame.new(base) * CFrame.Angles(0, math.rad(yaw), 0)
	for k = 0, length - 1 do
		for row = 0, rng:NextInteger(1, 2) do
			local size = Vector3.new(4, 3, 3)
			local offset = Vector3.new((k - length / 2) * 4 + (row % 2) * 2, row * 3 + 1.5, 0)
			if k + row % 2 < length then
				local props = iceProps(rng, 0.2)
				props.Size = size - Vector3.new(0.15, 0.15, 0)
				props.CFrame = frame * CFrame.new(offset)
				Build.part(model, props)
			end
		end
	end
	return model
end

-- a cluster of tall ice crystals
local function crystals(parent, rng, base)
	local model = Build.model(parent, "Crystals")
	for _ = 1, rng:NextInteger(3, 5) do
		local height = rng:NextNumber(4, 10)
		local props = iceProps(rng, 0.25)
		props.Material = Enum.Material.Glass
		props.Size = Vector3.new(1.6, height, 1.6)
		props.CFrame = CFrame.new(base + Vector3.new(rng:NextNumber(-2, 2), height / 2 - 0.5, rng:NextNumber(-2, 2)))
			* CFrame.Angles(math.rad(rng:NextNumber(-20, 20)), math.rad(rng:NextNumber(0, 90)), math.rad(rng:NextNumber(-20, 20)))
		Build.part(model, props)
	end
	return model
end

local function iceberg(parent, rng, base)
	local model = Build.model(parent, "Iceberg")
	local size = rng:NextNumber(8, 16)
	for k = 0, 2 do
		local s = size * (1 - k * 0.3)
		local props = iceProps(rng, 0)
		props.Color = SNOW:Lerp(ICE, rng:NextNumber(0.2, 0.6))
		props.Material = Enum.Material.Glacier
		props.Size = Vector3.new(s * rng:NextNumber(0.8, 1.2), s * 0.7, s * rng:NextNumber(0.8, 1.2))
		props.CFrame = CFrame.new(base + Vector3.new(rng:NextNumber(-2, 2), -2 + k * s * 0.45, rng:NextNumber(-2, 2)))
			* CFrame.Angles(0, math.rad(rng:NextNumber(0, 90)), math.rad(rng:NextNumber(-10, 10)))
		Build.part(model, props)
	end
	return model
end

function Frozen.build(ctx)
	local folder, rng, space = ctx.Folder, ctx.Rng, ctx.Space
	local x0, x1, half, side = ctx.X0, ctx.X1, ctx.Half, ctx.Side
	local deco = Build.folder(folder, "Decor")
	local terrain = ctx.Terrain
	local length = x1 - x0

	-- the frozen sea: a step down from the snowy shore, then flat glacier ice
	for _, s in ipairs({ -1, 1 }) do
		local width = side - (half + 8)
		local cz = s * (half + 8 + width / 2)
		terrain:FillBlock(CFrame.new(x0 + length / 2, -2, cz), Vector3.new(length, 4, width), Enum.Material.Air)
		terrain:FillBlock(CFrame.new(x0 + length / 2, -8, cz), Vector3.new(length, 8, width), Enum.Material.Glacier)
		-- ice floes and icebergs on the sea
		for _ = 1, 16 do
			local p = Vector3.new(rng:NextNumber(x0 + 5, x1 - 5), -4, s * rng:NextNumber(half + 16, side - 10))
			local props = iceProps(rng, 0.1)
			props.Size = Vector3.new(rng:NextNumber(6, 14), 0.6, rng:NextNumber(6, 14))
			props.CFrame = CFrame.new(p + Vector3.new(0, 0.3, 0)) * CFrame.Angles(0, math.rad(rng:NextNumber(0, 90)), 0)
			Build.part(deco, props)
		end
		for _ = 1, 4 do
			iceberg(deco, rng, Vector3.new(rng:NextNumber(x0 + 10, x1 - 10), -4, s * rng:NextNumber(half + 30, side - 20)))
		end
	end

	-- snowy mounds along the shore
	for x = x0, x1, 16 do
		for _, s in ipairs({ -1, 1 }) do
			terrain:FillBall(Vector3.new(x + rng:NextNumber(-5, 5), -3, s * (half + rng:NextNumber(0, 6))), rng:NextNumber(5, 8), Enum.Material.Snow)
		end
	end

	-- the igloo
	local iglooCenter = Vector3.new(x0 + 120, 0, half - 22)
	igloo(deco, iglooCenter)
	space:add(iglooCenter, 13)
	space:add(iglooCenter + Vector3.new(0, 0, -15), 6)

	-- ice walls, crystal clusters and pines scattered around
	for _ = 1, 8 do
		local base = space:find(rng, x0 + 16, x1 - 16, -half + 10, half - 10, 10)
		if base then
			iceWall(deco, rng, base)
		end
	end
	for _ = 1, 10 do
		local base = space:find(rng, x0 + 10, x1 - 10, -half + 6, half - 6, 4)
		if base then
			crystals(deco, rng, base)
		end
	end
	for x = x0 + 10, x1 - 10, 20 do
		for _, s in ipairs({ -1, 1 }) do
			local base = Vector3.new(x + rng:NextNumber(-5, 5), 0, s * rng:NextNumber(half - 6, half - 3))
			if space:free(base, 5) then
				pine(deco, rng, base, rng:NextNumber(0.9, 1.3))
				space:add(base, 5)
			end
		end
	end
	for _ = 1, 8 do
		local base = space:find(rng, x0 + 10, x1 - 10, -half + 8, half - 8, 4)
		if base then
			terrain:FillBall(base, rng:NextNumber(3, 5), Enum.Material.Snow)
		end
	end

	-- falling snow over the whole area
	local sky = Build.ghost(Build.part(deco, {
		Name = "Snowfall",
		Size = Vector3.new(length, 1, half * 2 + 60),
		CFrame = CFrame.new(x0 + length / 2, 60, 0),
		Transparency = 1,
	}))
	local snow = Instance.new("ParticleEmitter")
	snow.Color = ColorSequence.new(Color3.new(1, 1, 1))
	snow.Size = NumberSequence.new(0.35)
	snow.Transparency = NumberSequence.new(0.1)
	snow.Rate = 160
	snow.Lifetime = NumberRange.new(9, 12)
	snow.Speed = NumberRange.new(4, 7)
	snow.SpreadAngle = Vector2.new(20, 20)
	snow.EmissionDirection = Enum.NormalId.Bottom
	snow.Parent = sky
end

-- Ice cube: the Frozen Peaks' breakable
function Frozen.breakable(parent, position, rng)
	local model = Build.model(parent, "Ice Cube")
	local props = iceProps(rng, 0.25)
	props.Material = Enum.Material.Glass
	props.Name = "Cube"
	props.Size = Vector3.new(5, 5, 5)
	props.CFrame = CFrame.new(position + Vector3.new(0, 2.5, 0)) * CFrame.Angles(0, math.rad(rng:NextNumber(0, 90)), 0)
	local cube = Build.part(model, props)
	-- frosty core and a bright highlight
	Build.part(model, {
		Size = Vector3.new(3, 3, 3),
		CFrame = cube.CFrame,
		Color = SNOW,
		Material = Enum.Material.Snow,
		Transparency = 0.3,
		CanCollide = false,
	})
	Build.part(model, {
		Size = Vector3.new(0.3, 3.2, 0.3),
		CFrame = cube.CFrame * CFrame.new(1.8, 0.4, -2.45),
		Color = Color3.new(1, 1, 1),
		Material = Enum.Material.Neon,
		CanCollide = false,
	})
	model.PrimaryPart = cube
	return model
end

return Frozen
