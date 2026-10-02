-- Area 5: Lava Arena, the boss world. A round stone arena on warm volcanic
-- rock: a sandy fighting floor, a ring of stone walls with stands, torches
-- and orange banners, an entrance arch facing the gate, little lava pools
-- outside the ring, smoking volcanoes beyond the walls, and the Boss Shop
-- (upgrades for bosses only). One giant boss (the Magma Titan, shared/Coins.luau)
-- stomps around the middle; pets hit it from anywhere in the area, so you
-- can sit back and let them fight.
local Build = require(game:GetService("ReplicatedStorage").Shared.Build)
local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local Arena = {}

Arena.GROUND = Enum.Material.Basalt -- (coloured warm dark rock in World)

local STONE = Color3.fromRGB(205, 180, 150)
local STONE_DARK = Color3.fromRGB(150, 125, 105)
local BANNER = Color3.fromRGB(255, 120, 60)
local GOLD = Color3.fromRGB(255, 200, 70)
local RADIUS = 22 -- the fighting floor

-- a torch on a post with a small flame and a warm light
local function torch(parent, base, height)
	local model = Build.model(parent, "Torch")
	Build.cylinder(model, base, height, 0.5, { Color = Color3.fromRGB(110, 80, 60) })
	Build.cylinder(model, base + Vector3.new(0, height, 0), 0.5, 1.1, { Color = STONE_DARK })
	local flame = Build.ball(model, base + Vector3.new(0, height + 0.9, 0), 0.9, { Color = Color3.fromRGB(255, 160, 50), Material = Enum.Material.Neon, CanCollide = false })
	Build.bob(flame, 0.12, 3)
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 170, 90)
	light.Range = 12
	light.Brightness = 0.9
	light.Parent = flame
	return model
end

-- a banner hanging from a pole
local function banner(parent, base, facing)
	local model = Build.model(parent, "Banner")
	Build.cylinder(model, base, 9, 0.35, { Color = Color3.fromRGB(110, 80, 60) })
	Build.ball(model, base + Vector3.new(0, 9.2, 0), 0.6, { Color = GOLD })
	local cf = CFrame.new(base + Vector3.new(0, 6.6, 0)) * CFrame.Angles(0, facing, 0) * CFrame.new(0, 0, -0.3)
	Build.part(model, { Size = Vector3.new(2.6, 4, 0.15), CFrame = cf, Color = BANNER, CanCollide = false })
	Build.part(model, { Size = Vector3.new(2.6, 0.35, 0.18), CFrame = cf * CFrame.new(0, 1.9, 0), Color = GOLD, CanCollide = false })
	Build.wedge(model, cf * CFrame.new(0, -2.4, 0) * CFrame.Angles(0, 0, math.rad(180)), Vector3.new(0.15, 0.8, 2.6), { Color = BANNER, CanCollide = false })
	return model
end

-- a volcano far away: a terrain cone, a glowing crater and smoke
local function volcano(parent, terrain, base, height)
	for k = 0, 5 do
		local r = height * (0.9 - k * 0.14)
		terrain:FillBall(base + Vector3.new(0, k * height * 0.16 - height * 0.15, 0), r, Enum.Material.Basalt)
	end
	local top = base + Vector3.new(0, height * 0.7, 0)
	terrain:FillBall(top + Vector3.new(0, 2, 0), height * 0.12, Enum.Material.CrackedLava)
	local smoke = Build.part(parent, { Name = "Smoke", Size = Vector3.new(6, 1, 6), CFrame = CFrame.new(top + Vector3.new(0, height * 0.1, 0)), Transparency = 1, CanCollide = false, CastShadow = false })
	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(Color3.fromRGB(150, 140, 140), Color3.fromRGB(220, 215, 215))
	emitter.Size = NumberSequence.new(6, 16)
	emitter.Transparency = NumberSequence.new(0.4, 1)
	emitter.Lifetime = NumberRange.new(6, 9)
	emitter.Speed = NumberRange.new(3, 5)
	emitter.SpreadAngle = Vector2.new(15, 15)
	emitter.Rate = 2
	emitter.Parent = smoke
end

-- The Boss Shop (where the AFK spot was): a market stall with an orange
-- roof and a striped awning, a wooden counter with what it sells on it (a
-- sword for Boss Damage, a stack of coins for Boss Coins, a purple star for
-- Boss EXP, a lightning bolt for Boss Crits), a "BOSS SHOP" sign, and a
-- circle in front to step on (the client opens the shop: BossShop.luau).
local WOOD = Color3.fromRGB(170, 115, 75)
local WOOD_DARK = Color3.fromRGB(120, 80, 55)
local function bossShop(parent, at)
	local model = Build.model(parent, "BossShop")
	Build.block(model, at - Vector3.new(0, 0.3, 0), Vector3.new(14, 0.5, 9), { Color = STONE })
	-- posts, roof and a striped awning along the front
	for _, dx in ipairs({ -6, 6 }) do
		for _, dz in ipairs({ -4, 4 }) do
			Build.cylinder(model, at + Vector3.new(dx, 0, dz), 7, 0.5, { Color = Color3.fromRGB(110, 80, 60) })
		end
	end
	Build.part(model, { Size = Vector3.new(14, 0.4, 10), CFrame = CFrame.new(at + Vector3.new(0, 7.2, 0)), Color = BANNER, CanCollide = false })
	for k = 0, 6 do
		Build.part(model, {
			Size = Vector3.new(2, 1, 0.2),
			CFrame = CFrame.new(at + Vector3.new(-6 + k * 2, 6.5, -5)),
			Color = if k % 2 == 0 then Color3.fromRGB(255, 250, 240) else BANNER,
			CanCollide = false,
		})
	end
	-- the back wall and the counter
	Build.block(model, at + Vector3.new(0, 0, 4), Vector3.new(12, 6.5, 0.4), { Color = WOOD_DARK })
	Build.block(model, at + Vector3.new(0, 0, -1.5), Vector3.new(11, 2.8, 2), { Color = WOOD })
	Build.block(model, at + Vector3.new(0, 2.8, -1.5), Vector3.new(11.6, 0.3, 2.4), { Color = WOOD_DARK })
	local top = at + Vector3.new(0, 3.1, -1.5)
	-- a sword standing in a little stand
	Build.block(model, top + Vector3.new(-4, 0, 0), Vector3.new(1.2, 0.4, 1.2), { Color = STONE_DARK, CanCollide = false })
	Build.block(model, top + Vector3.new(-4, 0.4, 0), Vector3.new(0.35, 2.4, 0.12), { Color = Color3.fromRGB(225, 235, 250), CanCollide = false })
	Build.block(model, top + Vector3.new(-4, 2.0, 0), Vector3.new(1.2, 0.25, 0.25), { Color = GOLD, CanCollide = false })
	Build.block(model, top + Vector3.new(-4, 2.25, 0), Vector3.new(0.25, 0.7, 0.25), { Color = Color3.fromRGB(140, 60, 50), CanCollide = false })
	-- a stack of gold coins
	for k = 0, 3 do
		Build.cylinder(model, top + Vector3.new(-1.4 + (k % 2) * 0.1, k * 0.3, 0), 0.28, 1.4, { Color = GOLD, CanCollide = false })
	end
	-- a glowing purple star (a ball with points)
	local star = Build.ball(model, top + Vector3.new(1.4, 0.9, 0), 1.1, { Color = Color3.fromRGB(170, 130, 255), Material = Enum.Material.Neon, CanCollide = false })
	Build.spin(star, 40)
	-- a lightning bolt
	Build.part(model, { Size = Vector3.new(0.3, 1.2, 0.3), CFrame = CFrame.new(top + Vector3.new(4, 1.4, 0)) * CFrame.Angles(0, 0, math.rad(25)), Color = Color3.fromRGB(255, 200, 40), Material = Enum.Material.Neon, CanCollide = false })
	Build.part(model, { Size = Vector3.new(0.3, 1.2, 0.3), CFrame = CFrame.new(top + Vector3.new(4.2, 0.5, 0)) * CFrame.Angles(0, 0, math.rad(-25)), Color = Color3.fromRGB(255, 200, 40), Material = Enum.Material.Neon, CanCollide = false })
	Build.sign(model, CFrame.new(at + Vector3.new(0, 9, -4.6)), Vector3.new(10, 2.2, 0.4), "BOSS SHOP", Color3.new(1, 1, 1), Color3.fromRGB(70, 60, 60))
	-- the circle to step on, in front of the counter
	local circleAt = at + Vector3.new(0, -0.4, -8.5)
	Build.cylinder(model, circleAt, 1.2, 8, { Name = "CircleRim", Color = Color3.fromRGB(255, 250, 240) })
	local circle = Build.cylinder(model, circleAt, 1.35, 7, { Name = "BossShopCircle", Color = BANNER })
	Build.cylinder(model, circleAt + Vector3.new(0, 1.35, 0), 0.04, 5.6, { Color = Color3.fromRGB(255, 220, 120), Material = Enum.Material.Neon, CanCollide = false })
	Build.cylinder(model, circleAt + Vector3.new(0, 1.37, 0), 0.04, 4.8, { Color = BANNER, CanCollide = false })
	local hint = Instance.new("BillboardGui")
	hint.Name = "StepHint"
	hint.Size = UDim2.fromOffset(160, 34)
	hint.StudsOffsetWorldSpace = Vector3.new(0, 3, 0)
	hint.MaxDistance = 45
	hint.Adornee = circle
	hint.Parent = circle
	local hintText = Instance.new("TextLabel")
	hintText.BackgroundTransparency = 1
	hintText.Size = UDim2.fromScale(1, 1)
	hintText.Font = Enum.Font.FredokaOne
	hintText.TextScaled = true
	hintText.TextColor3 = Color3.new(1, 1, 1)
	hintText.TextStrokeColor3 = Color3.fromRGB(150, 60, 30)
	hintText.TextStrokeTransparency = 0
	hintText.Text = "Step here to shop"
	hintText.Parent = hint
	return { Model = model, Circle = circle }
end

function Arena.build(ctx)
	local folder, rng, space, terrain = ctx.Folder, ctx.Rng, ctx.Space, ctx.Terrain
	local x0, x1, half, side = ctx.X0, ctx.X1, ctx.Half, ctx.Side
	local deco = Build.folder(folder, "Decor")
	local ground = Config.GROUND_Y
	local center = Vector3.new(x0 + 56, ground, 0)
	ctx.BossSpot = center

	-- the sandy fighting floor in the volcanic rock
	terrain:FillCylinder(CFrame.new(center.X, -2, center.Z), 4, RADIUS, Enum.Material.Sandstone)
	space:add(center, RADIUS)

	-- the ring wall with stands behind it, broken by the entrance (towards
	-- the gate) and an opening at the back
	local segments = 28
	for k = 0, segments - 1 do
		local a = k / segments * math.pi * 2
		local dir = Vector3.new(math.cos(a), 0, math.sin(a))
		local opening = math.abs(math.cos(a) + 1) < 0.08 or math.abs(math.cos(a) - 1) < 0.05
		if not opening then
			local p = center + dir * (RADIUS + 1.5)
			local yaw = math.atan2(-dir.X, -dir.Z)
			local width = 2 * math.pi * (RADIUS + 1.5) / segments + 0.3
			Build.part(deco, { Size = Vector3.new(width, 4.5, 1.6), CFrame = CFrame.new(p + Vector3.new(0, 2.25, 0)) * CFrame.Angles(0, yaw, 0), Color = Build.vary(rng, STONE, 0.03) })
			Build.part(deco, { Size = Vector3.new(width, 0.5, 2), CFrame = CFrame.new(p + Vector3.new(0, 4.7, 0)) * CFrame.Angles(0, yaw, 0), Color = STONE_DARK })
			-- three rows of stands rising behind the wall
			for row = 1, 3 do
				local q = center + dir * (RADIUS + 2.5 + row * 2)
				if math.abs(q.Z) < half - 1 then
					Build.part(deco, { Size = Vector3.new(width + row * 0.5, 4.5 + row * 1.6, 2), CFrame = CFrame.new(q + Vector3.new(0, (4.5 + row * 1.6) / 2, 0)) * CFrame.Angles(0, yaw, 0), Color = Build.vary(rng, if row % 2 == 0 then STONE else STONE_DARK, 0.03) })
				end
			end
			if k % 4 == 0 then
				torch(deco, p + Vector3.new(0, 5, 0), 2)
			end
		end
	end
	-- the entrance arch and banners either side
	local gateAt = center - Vector3.new(RADIUS + 1.5, 0, 0)
	for _, s in ipairs({ -1, 1 }) do
		Build.block(deco, gateAt + Vector3.new(0, 0, s * 4.5), Vector3.new(2.4, 10, 2.4), { Color = STONE })
		banner(deco, gateAt + Vector3.new(-3, 0, s * 6.5), math.rad(-90))
	end
	Build.block(deco, gateAt + Vector3.new(0, 10, 0), Vector3.new(3, 2, 11.4), { Color = STONE_DARK })
	Build.sign(deco, CFrame.new(gateAt + Vector3.new(-1.6, 12.8, 0)) * CFrame.Angles(0, math.rad(90), 0), Vector3.new(12, 2.6, 0.5), "BOSS ARENA", Color3.new(1, 1, 1), BANNER)
	for x = x0 + 2, gateAt.X - 3, 4 do
		space:add(Vector3.new(x, 0, 0), 4)
	end

	-- the Boss Shop by the entrance (where the AFK spot was)
	local shopAt = Vector3.new(x0 + 18, ground, half - 10)
	ctx.World.BossShop = bossShop(deco, shopAt)
	space:add(shopAt, 8)
	space:add(shopAt + Vector3.new(0, 0, -8.5), 5)

	-- small lava pools and rocks outside the ring
	for _ = 1, 5 do
		local p = space:find(rng, x0 + 8, x1 - 8, -half + 6, half - 6, 4)
		if p then
			terrain:FillCylinder(CFrame.new(p.X, -1, p.Z), 2, rng:NextNumber(2.5, 3.5), Enum.Material.CrackedLava)
		end
	end
	for _ = 1, 6 do
		local p = space:find(rng, x0 + 6, x1 - 6, -half + 4, half - 4, 3)
		if p then
			Build.rock(deco, rng, p + Vector3.new(0, ground, 0), rng:NextNumber(2, 3.5), Color3.fromRGB(120, 100, 95))
		end
	end

	-- smoking volcanoes beyond the walls
	volcano(deco, terrain, Vector3.new(x0 + 30, 0, half + 70), 50)
	volcano(deco, terrain, Vector3.new(x0 + 80, 0, -(half + 80)), 64)
	for x = x0, x1, 14 do
		for _, s in ipairs({ -1, 1 }) do
			terrain:FillBall(Vector3.new(x + rng:NextNumber(-4, 4), rng:NextNumber(-8, -3), s * rng:NextNumber(half + 26, side - 10)), rng:NextNumber(12, 18), Enum.Material.Basalt)
		end
	end

	ctx.reserveSpots()
end

return Arena
