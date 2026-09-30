-- Area 4: Sakura Jungle. Cherry blossom trees with falling petals, bamboo
-- groves, a stone path with torii gates, stone lanterns, a koi pond, a pagoda,
-- and low white Japanese walls with tiled tops on both sides. Breakable: sushi.
local Build = require(script.Parent.Build)

local Sakura = {}

Sakura.GROUND = Enum.Material.LeafyGrass

local BLOSSOM = Color3.fromRGB(255, 175, 205)
local TRUNK = Color3.fromRGB(85, 60, 55)
local TORII = Color3.fromRGB(220, 50, 40)
local ROOF = Color3.fromRGB(55, 58, 70)
local STONE = Color3.fromRGB(150, 150, 145)
local BAMBOO = Color3.fromRGB(125, 175, 70)

local function petals(parent)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(Color3.fromRGB(255, 190, 215), Color3.fromRGB(255, 150, 190))
	emitter.Size = NumberSequence.new(0.25)
	emitter.Rate = 4
	emitter.Lifetime = NumberRange.new(5, 7)
	emitter.Speed = NumberRange.new(0.5, 1.5)
	emitter.Acceleration = Vector3.new(1.2, -1.2, 0.4)
	emitter.Rotation = NumberRange.new(0, 360)
	emitter.RotSpeed = NumberRange.new(-90, 90)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Parent = parent
end

local function sakuraTree(parent, rng, base, scale)
	local model = Build.model(parent, "SakuraTree")
	local height = 8 * scale
	Build.cylinder(model, base, height, 1.8 * scale, { Color = TRUNK, Material = Enum.Material.Wood })
	local top = base + Vector3.new(0, height, 0)
	-- branches reaching out, each ending in a blossom cloud
	for k = 1, 4 do
		local yaw = k / 4 * 360 + rng:NextNumber(-25, 25)
		local dir = CFrame.Angles(0, math.rad(yaw), 0) * CFrame.Angles(math.rad(50), 0, 0) -- tilted upward
		local branchLength = rng:NextNumber(4, 6) * scale
		Build.part(model, {
			Size = Vector3.new(0.8 * scale, 0.8 * scale, branchLength),
			CFrame = CFrame.new(top) * dir * CFrame.new(0, 0, -branchLength / 2),
			Color = TRUNK,
			Material = Enum.Material.Wood,
		})
		local tip = (CFrame.new(top) * dir * CFrame.new(0, 0, -branchLength)).Position
		Build.ball(model, tip, rng:NextNumber(6, 8) * scale, { Color = Build.vary(rng, BLOSSOM, 0.05), Material = Enum.Material.Grass })
	end
	local crown = Build.ball(model, top + Vector3.new(0, 2 * scale, 0), 8 * scale, {
		Color = Build.vary(rng, BLOSSOM, 0.05),
		Material = Enum.Material.Grass,
	})
	petals(crown)
	return model
end

local function bambooCluster(parent, rng, base, count)
	local model = Build.model(parent, "Bamboo")
	for _ = 1, count do
		local p = base + Vector3.new(rng:NextNumber(-3, 3), 0, rng:NextNumber(-3, 3))
		local height = rng:NextNumber(16, 26)
		local lean = CFrame.Angles(math.rad(rng:NextNumber(-5, 5)), 0, math.rad(rng:NextNumber(-5, 5)))
		local color = Build.vary(rng, BAMBOO, 0.06)
		Build.part(model, {
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(height, 0.8, 0.8),
			CFrame = CFrame.new(p) * lean * CFrame.new(0, height / 2, 0) * CFrame.Angles(0, 0, math.rad(90)),
			Color = color,
			Material = Enum.Material.SmoothPlastic,
		})
		-- joints
		for y = 3, height - 1, 3.5 do
			Build.ghost(Build.part(model, {
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(0.25, 0.95, 0.95),
				CFrame = CFrame.new(p) * lean * CFrame.new(0, y, 0) * CFrame.Angles(0, 0, math.rad(90)),
				Color = color:Lerp(Color3.new(0, 0, 0), 0.25),
			}))
		end
		-- leaves at the top
		local top = (CFrame.new(p) * lean * CFrame.new(0, height, 0)).Position
		for k = 1, 3 do
			Build.ghost(Build.wedge(model, CFrame.new(top) * CFrame.Angles(0, math.rad(k * 120 + rng:NextNumber(0, 40)), 0) * CFrame.Angles(math.rad(25), 0, 0) * CFrame.new(0, 0, -1.8), Vector3.new(0.9, 0.15, 3.6), {
				Color = Color3.fromRGB(95, 160, 70),
				Material = Enum.Material.Grass,
			}))
		end
	end
	return model
end

local function torii(parent, x, width)
	local model = Build.model(parent, "Torii")
	for _, z in ipairs({ -width / 2, width / 2 }) do
		Build.cylinder(model, Vector3.new(x, 0, z), 18, 1.8, { Color = TORII })
		Build.cylinder(model, Vector3.new(x, 0, z), 1.2, 2.6, { Color = Color3.fromRGB(30, 30, 35) })
	end
	Build.block(model, Vector3.new(x, 14, 0), Vector3.new(1.2, 1.2, width + 3), { Color = TORII })
	-- top beam, tips curving up
	Build.block(model, Vector3.new(x, 17.5, 0), Vector3.new(2, 1.4, width + 7), { Color = TORII })
	Build.block(model, Vector3.new(x, 18.9, 0), Vector3.new(2.4, 1, width + 8), { Color = Color3.fromRGB(30, 30, 35) })
	for _, s in ipairs({ -1, 1 }) do
		Build.wedge(model, CFrame.new(x, 19.9, s * (width / 2 + 4.5)) * CFrame.Angles(0, if s > 0 then 0 else math.rad(180), 0), Vector3.new(2.4, 1, 2), {
			Color = Color3.fromRGB(30, 30, 35),
		})
	end
	-- plaque in the middle
	Build.block(model, Vector3.new(x, 14.6, 0), Vector3.new(1.4, 3, 2.2), { Color = Color3.fromRGB(30, 30, 35) })
	return model
end

local function lantern(parent, base)
	local model = Build.model(parent, "StoneLantern")
	Build.block(model, base, Vector3.new(2.6, 0.8, 2.6), { Color = STONE, Material = Enum.Material.Slate })
	Build.cylinder(model, base + Vector3.new(0, 0.8, 0), 2.6, 1, { Color = STONE, Material = Enum.Material.Slate })
	local light = Build.block(model, base + Vector3.new(0, 3.4, 0), Vector3.new(2, 1.8, 2), {
		Color = Color3.fromRGB(255, 210, 140),
		Material = Enum.Material.Neon,
	})
	local glow = Instance.new("PointLight")
	glow.Color = Color3.fromRGB(255, 190, 120)
	glow.Range = 12
	glow.Brightness = 1.2
	glow.Parent = light
	Build.wedge(model, CFrame.new(base + Vector3.new(0, 5.8, 0.8)), Vector3.new(3.4, 1.2, 1.6), { Color = STONE, Material = Enum.Material.Slate })
	Build.wedge(model, CFrame.new(base + Vector3.new(0, 5.8, -0.8)) * CFrame.Angles(0, math.rad(180), 0), Vector3.new(3.4, 1.2, 1.6), { Color = STONE, Material = Enum.Material.Slate })
	Build.ball(model, base + Vector3.new(0, 6.7, 0), 0.9, { Color = STONE, Material = Enum.Material.Slate })
end

-- Low white plaster wall with a dark tiled cap and a wooden base
local function japaneseWall(parent, x0, x1, z)
	local model = Build.model(parent, "JapaneseWall")
	local length = x1 - x0
	local cx = (x0 + x1) / 2
	Build.block(model, Vector3.new(cx, 0, z), Vector3.new(length, 1.2, 2.4), { Color = Color3.fromRGB(95, 70, 50), Material = Enum.Material.Wood })
	Build.block(model, Vector3.new(cx, 1.2, z), Vector3.new(length, 4.4, 2), { Color = Color3.fromRGB(245, 240, 230), Material = Enum.Material.Plaster })
	-- dark posts every 12 studs
	for x = x0, x1, 12 do
		Build.block(model, Vector3.new(x, 1.2, z), Vector3.new(0.8, 4.4, 2.2), { Color = Color3.fromRGB(60, 45, 40), Material = Enum.Material.Wood })
	end
	-- tiled cap sloping to both sides
	for _, s in ipairs({ -1, 1 }) do
		Build.wedge(model, CFrame.new(cx, 6.2, z + s * 1) * CFrame.Angles(0, if s > 0 then math.rad(180) else 0, 0), Vector3.new(length, 1, 2.4), {
			Color = ROOF,
			Material = Enum.Material.Slate,
		})
	end
	Build.block(model, Vector3.new(cx, 6.6, z), Vector3.new(length, 0.5, 0.6), { Color = ROOF, Material = Enum.Material.Slate })
end

local function pagoda(parent, base)
	local model = Build.model(parent, "Pagoda")
	local y = 0
	for tier = 0, 3 do
		local w = 22 - tier * 4
		Build.block(model, base + Vector3.new(0, y, 0), Vector3.new(w - 6, 7, w - 6), {
			Color = if tier == 0 then Color3.fromRGB(240, 235, 225) else Color3.fromRGB(200, 60, 45),
			Material = Enum.Material.Plaster,
		})
		y += 7
		-- wide roof with the corners turned up
		Build.block(model, base + Vector3.new(0, y, 0), Vector3.new(w, 1.2, w), { Color = ROOF, Material = Enum.Material.Slate })
		for _, c in ipairs({ { 1, 1 }, { 1, -1 }, { -1, 1 }, { -1, -1 } }) do
			Build.block(model, base + Vector3.new(c[1] * (w / 2 - 0.6), y + 1.2, c[2] * (w / 2 - 0.6)), Vector3.new(1.2, 1, 1.2), { Color = ROOF })
		end
		y += 1.2
	end
	Build.cylinder(model, base + Vector3.new(0, y, 0), 7, 0.6, { Color = Color3.fromRGB(230, 180, 60), Material = Enum.Material.Foil })
end

local function koiPond(parent, rng, center)
	local model = Build.model(parent, "KoiPond")
	-- stone rim, then water
	for k = 0, 17 do
		local a = k / 18 * math.pi * 2
		Build.ball(model, center + Vector3.new(math.cos(a) * 10, 0.2, math.sin(a) * 10), rng:NextNumber(2, 2.8), {
			Color = Build.vary(rng, STONE),
			Material = Enum.Material.Slate,
		})
	end
	Build.part(model, {
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.4, 20, 20),
		CFrame = CFrame.new(center + Vector3.new(0, 0.15, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(60, 150, 170),
		Material = Enum.Material.Glass,
		Transparency = 0.25,
		CanCollide = false,
	})
	-- koi
	for k = 1, 5 do
		local p = center + Vector3.new(rng:NextNumber(-6, 6), 0.2, rng:NextNumber(-6, 6))
		local fish = Build.ghost(Build.part(model, {
			Size = Vector3.new(0.8, 0.3, 1.8),
			CFrame = CFrame.new(p) * CFrame.Angles(0, math.rad(rng:NextNumber(0, 360)), 0),
			Color = if k % 2 == 0 then Color3.fromRGB(255, 130, 40) else Color3.fromRGB(250, 250, 250),
		}))
		Build.ghost(Build.part(model, {
			Size = Vector3.new(0.5, 0.32, 0.5),
			CFrame = fish.CFrame * CFrame.new(0, 0.01, 0.2),
			Color = Color3.fromRGB(230, 60, 40),
		}))
	end
	-- lily pads
	for _ = 1, 4 do
		Build.ghost(Build.cylinder(model, center + Vector3.new(rng:NextNumber(-6, 6), 0.3, rng:NextNumber(-4, 4)), 0.1, 1.8, {
			Color = Color3.fromRGB(80, 160, 70),
		}))
	end
end

function Sakura.build(ctx)
	local folder, rng, space = ctx.Folder, ctx.Rng, ctx.Space
	local x0, x1, half = ctx.X0, ctx.X1, ctx.Half
	local deco = Build.folder(folder, "Decor")
	local terrain = ctx.Terrain

	-- green hills and a bamboo forest beyond the walls
	for x = x0, x1 + 20, 22 do
		for _, s in ipairs({ -1, 1 }) do
			terrain:FillBall(Vector3.new(x + rng:NextNumber(-6, 6), rng:NextNumber(-14, -6), s * rng:NextNumber(half + 55, half + 100)), rng:NextNumber(24, 36), Enum.Material.LeafyGrass)
		end
	end
	for x = x0 + 6, x1 - 6, 11 do
		for _, s in ipairs({ -1, 1 }) do
			bambooCluster(deco, rng, Vector3.new(x + rng:NextNumber(-3, 3), 0, s * rng:NextNumber(half + 9, half + 26)), rng:NextInteger(4, 7))
		end
	end
	pagoda(deco, Vector3.new(x0 + 120, 0, half + 45))

	-- Japanese walls on both sides
	for _, s in ipairs({ -1, 1 }) do
		japaneseWall(deco, x0, x1, s * (half + 3))
	end

	-- stone path down the middle, with torii gates over it
	local path = Build.folder(deco, "Path")
	for x = x0 + 2, x1 - 2, 4.5 do
		Build.block(path, Vector3.new(x, -0.1, rng:NextNumber(-0.4, 0.4)), Vector3.new(4, 0.35, 9), {
			Color = Build.vary(rng, STONE, 0.04),
			Material = Enum.Material.Slate,
			CanCollide = false,
		}, rng:NextNumber(-3, 3))
	end
	for _, x in ipairs({ x0 + 22, x0 + 110, x1 - 22 }) do
		torii(deco, x, 16)
		space:add(Vector3.new(x, 0, 9), 3)
		space:add(Vector3.new(x, 0, -9), 3)
	end
	-- keep the path itself free
	for x = x0, x1, 8 do
		space:add(Vector3.new(x, 0, 0), 6)
	end

	-- lanterns lining the path
	for x = x0 + 14, x1 - 14, 26 do
		for _, s in ipairs({ -1, 1 }) do
			local base = Vector3.new(x, 0, s * 8)
			lantern(deco, base)
			space:add(base, 2.5)
		end
	end

	-- koi pond
	local pondCenter = Vector3.new(x0 + 70, 0, -(half - 20))
	koiPond(deco, rng, pondCenter)
	space:add(pondCenter, 12)

	-- sakura trees and bamboo inside the area
	for x = x0 + 10, x1 - 10, 18 do
		for _, s in ipairs({ -1, 1 }) do
			local base = Vector3.new(x + rng:NextNumber(-5, 5), 0, s * rng:NextNumber(half - 8, half - 4))
			if space:free(base, 6) then
				sakuraTree(deco, rng, base, rng:NextNumber(1, 1.3))
				space:add(base, 6)
			end
		end
	end
	for _ = 1, 6 do
		local base = space:find(rng, x0 + 16, x1 - 16, -half + 16, half - 16, 8)
		if base then
			sakuraTree(deco, rng, base, rng:NextNumber(1.1, 1.4))
		end
	end
	for _ = 1, 6 do
		local base = space:find(rng, x0 + 10, x1 - 10, -half + 8, half - 8, 5)
		if base then
			bambooCluster(deco, rng, base, rng:NextInteger(3, 5))
		end
	end
end

-- Sushi: the Sakura Jungle's breakable (salmon nigiri)
function Sakura.breakable(parent, position, rng)
	local model = Build.model(parent, "Sushi")
	local yaw = CFrame.Angles(0, math.rad(rng:NextNumber(0, 180)), 0)
	local base = CFrame.new(position) * yaw
	local rice = Build.part(model, {
		Name = "Rice",
		Size = Vector3.new(5.4, 2.4, 3.2),
		CFrame = base * CFrame.new(0, 1.2, 0),
		Color = Color3.fromRGB(250, 250, 245),
		Material = Enum.Material.Sand,
	})
	local fish = Build.part(model, {
		Size = Vector3.new(6, 1, 3.6),
		CFrame = base * CFrame.new(0, 2.8, 0),
		Color = Color3.fromRGB(255, 130, 80),
	})
	-- the white stripes on salmon
	for k = -2, 2 do
		Build.part(model, {
			Size = Vector3.new(0.25, 1.02, 3.62),
			CFrame = fish.CFrame * CFrame.new(k * 1.1, 0, 0) * CFrame.Angles(0, math.rad(15), 0),
			Color = Color3.fromRGB(255, 220, 200),
			CanCollide = false,
		})
	end
	-- nori band around the middle
	Build.part(model, {
		Size = Vector3.new(1.4, 3.6, 3.8),
		CFrame = base * CFrame.new(0, 1.9, 0),
		Color = Color3.fromRGB(30, 50, 35),
		CanCollide = false,
	})
	model.PrimaryPart = rice
	return model
end

return Sakura
