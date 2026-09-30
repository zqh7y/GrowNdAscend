-- Area 1: Forest. Grass, round cartoon trees, flowers, flat grass, a fountain
-- on each side, hills around the sides and back, and the three leaderboards
-- side by side on one stage. Breakable: small trees.
local Build = require(script.Parent.Build)

local Forest = {}

Forest.GROUND = Enum.Material.Grass

local TRUNK = Color3.fromRGB(165, 105, 65)
local LEAVES = Color3.fromRGB(90, 200, 75)
local GRASS = Color3.fromRGB(80, 175, 60)
local FLOWER_COLORS = {
	Color3.fromRGB(255, 110, 170),
	Color3.fromRGB(255, 215, 50),
	Color3.fromRGB(255, 255, 255),
	Color3.fromRGB(175, 120, 255),
	Color3.fromRGB(255, 140, 70),
	Color3.fromRGB(90, 190, 255),
}

-- the three leaderboard ids, left to right
Forest.BOARDS = {
	{ Id = "Strongest", Color = Color3.fromRGB(255, 110, 90) },
	{ Id = "Playtime", Color = Color3.fromRGB(60, 185, 255) },
	{ Id = "Rebirths", Color = Color3.fromRGB(170, 110, 255) },
}

local function tree(parent, rng, base, scale)
	local model = Build.model(parent, "Tree")
	local height = 6 * scale
	Build.cylinder(model, base, height, 1.6 * scale, { Color = TRUNK })
	local top = base + Vector3.new(0, height + 1, 0)
	Build.ball(model, top, 7 * scale, { Color = Build.vary(rng, LEAVES, 0.04) })
	for _ = 1, 3 do
		local offset = Vector3.new(rng:NextNumber(-2.2, 2.2), rng:NextNumber(-1.2, 1.2), rng:NextNumber(-2.2, 2.2)) * scale
		Build.ball(model, top + offset, rng:NextNumber(4.5, 5.5) * scale, { Color = Build.vary(rng, LEAVES, 0.04) })
	end
	return model
end

local function flower(parent, rng, base)
	local color = FLOWER_COLORS[rng:NextInteger(1, #FLOWER_COLORS)]
	local height = rng:NextNumber(0.7, 1.2)
	Build.ghost(Build.block(parent, base, Vector3.new(0.16, height, 0.16), { Color = Color3.fromRGB(70, 170, 60) }))
	local head = base + Vector3.new(0, height, 0)
	for k = 0, 4 do
		local a = k / 5 * math.pi * 2
		Build.ghost(Build.ball(parent, head + Vector3.new(math.cos(a) * 0.28, 0, math.sin(a) * 0.28), 0.42, { Color = color }))
	end
	Build.ghost(Build.ball(parent, head + Vector3.new(0, 0.05, 0), 0.34, { Color = Color3.fromRGB(255, 205, 50) }))
end

local function fountain(parent, center)
	local model = Build.model(parent, "Fountain")
	local stone = Color3.fromRGB(245, 245, 255)
	local trim = Color3.fromRGB(120, 200, 255)
	local water = { Color = Color3.fromRGB(80, 190, 255), Material = Enum.Material.Glass, Transparency = 0.3, CanCollide = false }
	Build.cylinder(model, center, 1.6, 13, { Color = stone })
	Build.cylinder(model, center + Vector3.new(0, 1.6, 0), 0.25, 13.3, { Color = trim })
	Build.cylinder(model, center + Vector3.new(0, 1.6, 0), 0.2, 11.5, water)
	Build.cylinder(model, center + Vector3.new(0, 1.6, 0), 4, 1.8, { Color = stone })
	Build.cylinder(model, center + Vector3.new(0, 5.6, 0), 0.9, 6, { Color = stone })
	Build.cylinder(model, center + Vector3.new(0, 6.5, 0), 0.2, 5.2, water)
	Build.cylinder(model, center + Vector3.new(0, 6.5, 0), 2, 0.9, { Color = stone })
	local spout = Build.ball(model, center + Vector3.new(0, 8.8, 0), 1.2, { Color = trim })

	local spray = Instance.new("ParticleEmitter")
	spray.Color = ColorSequence.new(Color3.fromRGB(180, 230, 255))
	spray.Transparency = NumberSequence.new(0.1, 1)
	spray.Size = NumberSequence.new(0.3, 0.12)
	spray.Rate = 50
	spray.Lifetime = NumberRange.new(0.8, 1.1)
	spray.Speed = NumberRange.new(7, 9)
	spray.SpreadAngle = Vector2.new(20, 20)
	spray.Acceleration = Vector3.new(0, -22, 0)
	spray.EmissionDirection = Enum.NormalId.Top
	spray.Parent = spout
	return model
end

-- The three leaderboards next to each other on one stage, facing the path.
-- Fills World.Boards with each board's screen part.
local function leaderboardStage(parent, world, center)
	local model = Build.model(parent, "Leaderboards")
	local facing = CFrame.lookAt(center, Vector3.new(center.X, center.Y, 0)) -- screens face the middle
	local WIDTH, GAP = 11, 1.2
	local total = #Forest.BOARDS * WIDTH + (#Forest.BOARDS - 1) * GAP

	-- stage with a colourful trim
	Build.part(model, { Size = Vector3.new(total + 4, 1, 6), CFrame = facing * CFrame.new(0, 0.5, 0), Color = Color3.fromRGB(250, 250, 255) })
	Build.part(model, { Size = Vector3.new(total + 4.2, 0.3, 6.2), CFrame = facing * CFrame.new(0, 1.05, 0), Color = Color3.fromRGB(255, 205, 60) })

	for i, board in ipairs(Forest.BOARDS) do
		local x = -total / 2 + WIDTH / 2 + (i - 1) * (WIDTH + GAP)
		-- white frame, coloured cap, screen
		Build.part(model, { Size = Vector3.new(WIDTH, 14.4, 0.8), CFrame = facing * CFrame.new(x, 8.4, 0.2), Color = Color3.fromRGB(250, 250, 255) })
		Build.part(model, { Size = Vector3.new(WIDTH, 1.2, 1.2), CFrame = facing * CFrame.new(x, 16.2, 0.2), Color = board.Color })
		world.Boards[board.Id] = Build.part(model, {
			Name = "Screen_" .. board.Id,
			Size = Vector3.new(WIDTH - 1, 13.4, 0.2),
			CFrame = facing * CFrame.new(x, 8.4, -0.3),
			Color = Color3.fromRGB(255, 255, 255),
		})
	end

	-- one shared header above all three
	Build.sign(model, facing * CFrame.new(0, 18.6, 0.2), Vector3.new(16, 2.6, 0.6), "LEADERBOARDS", Color3.new(1, 1, 1), Color3.fromRGB(255, 150, 60))
	return total
end

function Forest.build(ctx)
	local folder, rng, space = ctx.Folder, ctx.Rng, ctx.Space
	local x0, x1, half = ctx.X0, ctx.X1, ctx.Half
	local deco = Build.folder(folder, "Decor")
	local terrain = ctx.Terrain

	-- soft round hills along both sides and behind the start
	for x = x0 - 10, x1 + 6, 14 do
		for _, side in ipairs({ -1, 1 }) do
			terrain:FillBall(Vector3.new(x + rng:NextNumber(-5, 5), rng:NextNumber(-9, -3), side * rng:NextNumber(half + 26, half + 50)), rng:NextNumber(16, 24), Enum.Material.Grass)
		end
	end
	for z = -ctx.Side, ctx.Side, 16 do
		terrain:FillBall(Vector3.new(x0 - rng:NextNumber(12, 20), rng:NextNumber(-6, 0), z), rng:NextNumber(16, 22), Enum.Material.Grass)
	end

	-- leaderboards: one group on the left side, near the spawn
	local stageCenter = Vector3.new(x0 + 30, 0, -(half - 5))
	local stageWidth = leaderboardStage(deco, ctx.World, stageCenter)
	for dx = -stageWidth / 2, stageWidth / 2, 6 do
		space:add(stageCenter + Vector3.new(dx, 0, 0), 5)
	end

	-- a fountain on each side
	for _, f in ipairs({ { X = 72, Side = -1 }, { X = 42, Side = 1 } }) do
		local center = Vector3.new(x0 + f.X, 0, f.Side * (half - 9))
		fountain(deco, center)
		space:add(center, 8)
	end

	-- trees: a row along each side, and a forest outside the walls
	for x = x0 + 5, x1 - 5, 9 do
		for _, side in ipairs({ -1, 1 }) do
			local base = Vector3.new(x + rng:NextNumber(-2, 2), 0, side * rng:NextNumber(half - 4, half - 2))
			if space:free(base, 3.5) then
				tree(deco, rng, base, rng:NextNumber(0.9, 1.2))
				space:add(base, 3.5)
			end
			tree(deco, rng, Vector3.new(x + rng:NextNumber(-3, 3), 0, side * rng:NextNumber(half + 5, half + 22)), rng:NextNumber(1, 1.5))
		end
	end
	for _ = 1, 3 do
		local base = space:find(rng, x0 + 14, x1 - 14, -half + 14, half - 14, 5)
		if base then
			tree(deco, rng, base, rng:NextNumber(0.9, 1.1))
		end
	end

	-- flowers and flat grass (players walk over them)
	local small = Build.folder(deco, "FlowersAndGrass")
	for _ = 1, 70 do
		local base = Vector3.new(rng:NextNumber(x0 + 2, x1 - 2), 0, rng:NextNumber(-half + 2, half - 2))
		if space:free(base, 0.8) then
			flower(small, rng, base)
		end
	end
	for _ = 1, 220 do
		local base = Vector3.new(rng:NextNumber(x0 + 1, x1 - 1), 0, rng:NextNumber(-half + 1, half - 1))
		if space:free(base, 0.8) then
			Build.flatGrass(small, rng, base, GRASS)
		end
	end

	-- a few round pebbles
	for _ = 1, 6 do
		local base = space:find(rng, x0 + 8, x1 - 8, -half + 6, half - 6, 2)
		if base then
			Build.ball(deco, base, rng:NextNumber(1.6, 2.4), { Color = Build.vary(rng, Color3.fromRGB(190, 195, 210), 0.04) })
		end
	end
end

-- Small tree: the Forest's breakable
function Forest.breakable(parent, position, rng)
	local model = Build.model(parent, "Small Tree")
	local trunk = Build.cylinder(model, position, 2.4, 0.8, { Color = TRUNK })
	local top = position + Vector3.new(0, 3.6, 0)
	Build.ball(model, top, 3.6, { Color = Build.vary(rng, LEAVES, 0.04) })
	Build.ball(model, top + Vector3.new(0.7, 0.7, 0.2), 2.4, { Color = Build.vary(rng, LEAVES, 0.04) })
	-- shiny red apples, so they read as "worth something"
	for _, offset in ipairs({ Vector3.new(1.3, -0.5, 1.1), Vector3.new(-1.2, 0.2, 1) }) do
		Build.ball(model, top + offset, 0.7, { Color = Color3.fromRGB(240, 50, 60) })
	end
	model.PrimaryPart = trunk
	return model
end

return Forest
