-- Area 1: Forest. Grass, trees, flowers, grass tufts, a fountain on each side,
-- hills around the sides and back, and the three leaderboards. Breakable:
-- small trees.
local Build = require(script.Parent.Build)

local Forest = {}

Forest.GROUND = Enum.Material.Grass

local TRUNK = Color3.fromRGB(120, 80, 50)
local LEAVES = Color3.fromRGB(80, 170, 70)
local FLOWER_COLORS = {
	Color3.fromRGB(255, 120, 170),
	Color3.fromRGB(255, 220, 70),
	Color3.fromRGB(250, 250, 255),
	Color3.fromRGB(180, 120, 255),
	Color3.fromRGB(255, 140, 80),
}

local function tree(parent, rng, base, scale)
	local model = Build.model(parent, "Tree")
	local height = 10 * scale
	Build.cylinder(model, base, height, 2.2 * scale, { Color = TRUNK, Material = Enum.Material.Wood })
	local top = base + Vector3.new(0, height, 0)
	Build.ball(model, top, 10 * scale, { Color = Build.vary(rng, LEAVES), Material = Enum.Material.Grass })
	for _ = 1, 3 do
		local offset = Vector3.new(rng:NextNumber(-3, 3), rng:NextNumber(-2, 1.5), rng:NextNumber(-3, 3)) * scale
		Build.ball(model, top + offset, rng:NextNumber(6, 8) * scale, { Color = Build.vary(rng, LEAVES), Material = Enum.Material.Grass })
	end
	return model
end

local function flower(parent, rng, base)
	local color = FLOWER_COLORS[rng:NextInteger(1, #FLOWER_COLORS)]
	local height = rng:NextNumber(0.8, 1.6)
	Build.ghost(Build.block(parent, base, Vector3.new(0.18, height, 0.18), { Color = Color3.fromRGB(70, 150, 60) }))
	local head = base + Vector3.new(0, height, 0)
	for k = 0, 4 do
		local a = k / 5 * math.pi * 2
		Build.ghost(Build.ball(parent, head + Vector3.new(math.cos(a) * 0.3, 0, math.sin(a) * 0.3), 0.45, { Color = color }))
	end
	Build.ghost(Build.ball(parent, head + Vector3.new(0, 0.05, 0), 0.35, { Color = Color3.fromRGB(255, 210, 60) }))
end

-- a clump of flat grass blades
local function tuft(parent, rng, base)
	local color = Build.vary(rng, Color3.fromRGB(100, 185, 70), 0.08)
	for k = 1, 3 do
		local height = rng:NextNumber(0.9, 1.8)
		Build.ghost(Build.wedge(
			parent,
			CFrame.new(base + Vector3.new(0, height / 2, 0)) * CFrame.Angles(math.rad(rng:NextNumber(-12, 12)), math.rad(k * 60 + rng:NextNumber(-20, 20)), 0),
			Vector3.new(0.05, height, 0.5),
			{ Color = color, Material = Enum.Material.Grass }
		))
	end
end

local function fountain(parent, center)
	local model = Build.model(parent, "Fountain")
	local marble = Color3.fromRGB(235, 235, 240)
	local water = { Color = Color3.fromRGB(80, 180, 255), Material = Enum.Material.Glass, Transparency = 0.35, CanCollide = false }
	Build.cylinder(model, center, 2.2, 20, { Color = marble, Material = Enum.Material.Marble })
	Build.cylinder(model, center + Vector3.new(0, 2.2, 0), 0.3, 18, water)
	Build.cylinder(model, center + Vector3.new(0, 2.2, 0), 6, 2.5, { Color = marble, Material = Enum.Material.Marble })
	Build.cylinder(model, center + Vector3.new(0, 8, 0), 1.2, 9, { Color = marble, Material = Enum.Material.Marble })
	Build.cylinder(model, center + Vector3.new(0, 9.2, 0), 0.25, 8, water)
	Build.cylinder(model, center + Vector3.new(0, 9.2, 0), 3, 1.2, { Color = marble, Material = Enum.Material.Marble })
	local spout = Build.ball(model, center + Vector3.new(0, 12.6, 0), 1.6, { Color = marble, Material = Enum.Material.Marble })

	local spray = Instance.new("ParticleEmitter")
	spray.Color = ColorSequence.new(Color3.fromRGB(170, 225, 255))
	spray.Transparency = NumberSequence.new(0.2, 1)
	spray.Size = NumberSequence.new(0.35, 0.15)
	spray.Rate = 60
	spray.Lifetime = NumberRange.new(1, 1.4)
	spray.Speed = NumberRange.new(9, 12)
	spray.SpreadAngle = Vector2.new(22, 22)
	spray.Acceleration = Vector3.new(0, -22, 0)
	spray.EmissionDirection = Enum.NormalId.Top
	spray.Parent = spout
	return model
end

-- a leaderboard stand facing the middle of the path; returns the screen part
local function board(parent, base, id, color)
	local model = Build.model(parent, "Leaderboard_" .. id)
	local facing = CFrame.lookAt(base, Vector3.new(base.X, base.Y, 0))
	local frame = Color3.fromRGB(40, 43, 68)
	for _, x in ipairs({ -8, 8 }) do
		Build.part(model, { Size = Vector3.new(1.2, 22, 1.2), CFrame = facing * CFrame.new(x, 11, 0), Color = frame })
	end
	local screen = Build.part(model, {
		Name = "Screen",
		Size = Vector3.new(15, 19, 0.6),
		CFrame = facing * CFrame.new(0, 12.5, 0),
		Color = Color3.fromRGB(18, 20, 38),
	})
	Build.part(model, {
		Size = Vector3.new(17, 0.8, 1.6),
		CFrame = facing * CFrame.new(0, 22.4, 0),
		Color = color,
		Material = Enum.Material.Neon,
	})
	return screen
end

function Forest.build(ctx)
	local folder, rng, space = ctx.Folder, ctx.Rng, ctx.Space
	local x0, x1, half = ctx.X0, ctx.X1, ctx.Half
	local deco = Build.folder(folder, "Decor")
	local terrain = ctx.Terrain

	-- hills along both sides and behind the start
	for x = x0 - 20, x1 + 10, 22 do
		for _, side in ipairs({ -1, 1 }) do
			local r = rng:NextNumber(24, 40)
			terrain:FillBall(Vector3.new(x + rng:NextNumber(-8, 8), rng:NextNumber(-12, -4), side * rng:NextNumber(half + 50, half + 95)), r, Enum.Material.Grass)
		end
	end
	for z = -ctx.Side, ctx.Side, 24 do
		terrain:FillBall(Vector3.new(x0 - rng:NextNumber(18, 34), rng:NextNumber(-8, 2), z), rng:NextNumber(24, 36), Enum.Material.Grass)
	end

	-- fountains on the sides
	for _, side in ipairs({ -1, 1 }) do
		local center = Vector3.new(x0 + 100, 0, side * (half - 14))
		fountain(deco, center)
		space:add(center, 13)
	end

	-- leaderboards along the sides
	local boards = {
		{ Id = "Strongest", X = 45, Side = -1, Color = Color3.fromRGB(255, 120, 90) },
		{ Id = "Playtime", X = 45, Side = 1, Color = Color3.fromRGB(80, 220, 255) },
		{ Id = "Rebirths", X = 155, Side = -1, Color = Color3.fromRGB(190, 120, 255) },
	}
	for _, b in ipairs(boards) do
		local base = Vector3.new(x0 + b.X, 0, b.Side * (half - 6))
		ctx.World.Boards[b.Id] = board(deco, base, b.Id, b.Color)
		space:add(base, 11)
	end

	-- big trees: a row just inside each side, and a forest outside the walls
	for x = x0 + 8, x1 - 8, 14 do
		for _, side in ipairs({ -1, 1 }) do
			local base = Vector3.new(x + rng:NextNumber(-4, 4), 0, side * rng:NextNumber(half - 7, half - 3))
			if space:free(base, 5) then
				tree(deco, rng, base, rng:NextNumber(1, 1.4))
				space:add(base, 5)
			end
			tree(deco, rng, Vector3.new(x + rng:NextNumber(-6, 6), 0, side * rng:NextNumber(half + 6, half + 40)), rng:NextNumber(1.1, 1.8))
		end
	end
	-- a few trees in the middle too
	for _ = 1, 6 do
		local base = space:find(rng, x0 + 20, x1 - 20, -half + 20, half - 20, 7)
		if base then
			tree(deco, rng, base, rng:NextNumber(1, 1.3))
		end
	end

	-- flowers and grass tufts everywhere (players walk through them)
	local small = Build.folder(deco, "FlowersAndGrass")
	for _ = 1, 140 do
		local base = Vector3.new(rng:NextNumber(x0 + 2, x1 - 2), 0, rng:NextNumber(-half + 2, half - 2))
		if space:free(base, 1) then
			flower(small, rng, base)
		end
	end
	for _ = 1, 320 do
		local base = Vector3.new(rng:NextNumber(x0 + 2, x1 - 2), 0, rng:NextNumber(-half - 30, half + 30))
		if space:free(base, 1) then
			tuft(small, rng, base)
		end
	end

	-- rocks
	for _ = 1, 10 do
		local base = space:find(rng, x0 + 10, x1 - 10, -half + 8, half - 8, 3)
		if base then
			Build.block(deco, base, Vector3.new(rng:NextNumber(3, 5), rng:NextNumber(1.6, 2.6), rng:NextNumber(3, 5)), {
				Color = Build.vary(rng, Color3.fromRGB(140, 140, 150)),
				Material = Enum.Material.Slate,
			}, rng:NextNumber(0, 90))
		end
	end
end

-- Small tree: the Forest's breakable
function Forest.breakable(parent, position, rng)
	local model = Build.model(parent, "Small Tree")
	local trunk = Build.cylinder(model, position, 3.2, 1, { Color = TRUNK, Material = Enum.Material.Wood })
	local top = position + Vector3.new(0, 4.6, 0)
	Build.ball(model, top, 4.6, { Color = Build.vary(rng, LEAVES), Material = Enum.Material.Grass })
	Build.ball(model, top + Vector3.new(0.9, 0.9, 0.3), 3, { Color = Build.vary(rng, LEAVES), Material = Enum.Material.Grass })
	-- a couple of red apples, so they read as "worth something"
	for _, offset in ipairs({ Vector3.new(1.6, -0.6, 1.4), Vector3.new(-1.5, 0.2, 1.3) }) do
		Build.ball(model, top + offset, 0.8, { Color = Color3.fromRGB(230, 50, 50) })
	end
	model.PrimaryPart = trunk
	return model
end

return Forest
