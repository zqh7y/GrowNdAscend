-- Area 4: Sakura Jungle. Twisted cherry trees (and weeping ones) with
-- falling petals, red maples, bamboo groves, ferns, hydrangeas, azaleas and
-- irises, a stepping-stone path under torii gates, stone lanterns, a koi pond
-- with a red arched bridge and a bamboo water spout, a five-tier pagoda, and
-- Japanese walls (stone base, white plaster, timber, a curved tile roof and
-- round windows). Breakable: sushi with happy faces (salmon, tuna, egg, maki).
-- By the gate in: the Fuse Machine (100 of a pet -> its Huge, 20 Huge -> its
-- Titanic; server/Fuse.luau, client/FuseMachine.luau).
local Build = require(game:GetService("ReplicatedStorage").Shared.Build)
local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local Sakura = {}

Sakura.GROUND = Enum.Material.LeafyGrass

local BLOSSOM = Color3.fromRGB(255, 170, 210)
local BLOSSOM_LIGHT = Color3.fromRGB(255, 215, 235)
local TRUNK = Color3.fromRGB(135, 85, 75)
local TORII = Color3.fromRGB(245, 70, 60)
local CHARCOAL = Color3.fromRGB(70, 72, 95) -- soft, not black
local ROOF = Color3.fromRGB(80, 150, 220) -- sky-blue tiles
local STONE = Color3.fromRGB(215, 215, 225)
local PLASTER = Color3.fromRGB(252, 248, 240)
local TIMBER = Color3.fromRGB(165, 105, 75)
local BAMBOO = Color3.fromRGB(120, 205, 80)
local LEAF = Color3.fromRGB(90, 195, 85)

local function pick(rng, list)
	return list[rng:NextInteger(1, #list)]
end

local function petals(parent, rate)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(Color3.fromRGB(255, 195, 220), Color3.fromRGB(255, 150, 190))
	emitter.Size = NumberSequence.new(0.25)
	emitter.Rate = rate or 4
	emitter.Lifetime = NumberRange.new(5, 7)
	emitter.Speed = NumberRange.new(0.5, 1.5)
	emitter.Acceleration = Vector3.new(1.2, -1.2, 0.4)
	emitter.Rotation = NumberRange.new(0, 360)
	emitter.RotSpeed = NumberRange.new(-90, 90)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Parent = parent
end

-- Trees ---------------------------------------------------------------------------------

-- a trunk that twists in three pieces; returns the top and the joints
local function twistedTrunk(model, rng, base, height, width)
	local points = { base - Vector3.new(0, 0.4, 0) }
	local p = base
	for k = 1, 3 do
		p = p + Vector3.new(rng:NextNumber(-1.2, 1.2), height / 3, rng:NextNumber(-1.2, 1.2))
		table.insert(points, p)
	end
	for k = 1, 3 do
		local w = width * (1 - (k - 1) * 0.22)
		Build.limb(model, points[k], points[k + 1], w, { Color = TRUNK })
		Build.ball(model, points[k + 1], w * 0.95, { Color = TRUNK })
	end
	for k = 1, 3 do
		local a = k / 3 * math.pi * 2 + rng:NextNumber(-0.4, 0.4)
		local dir = Vector3.new(math.cos(a), 0, math.sin(a))
		Build.limb(model, base + Vector3.new(0, width * 0.6, 0), base + dir * width * 1.1 - Vector3.new(0, 0.2, 0), width * 0.4, { Color = TRUNK })
	end
	return points
end

local function sakuraTree(parent, rng, base, s)
	local model = Build.model(parent, "SakuraTree")
	local points = twistedTrunk(model, rng, base, 9 * s, 1.8 * s)
	local top = points[4]
	-- branches from the upper joints, each splitting once, ending in blossoms
	for k = 1, 4 do
		local from = points[if k <= 2 then 3 else 4]
		local a = k / 4 * math.pi * 2 + rng:NextNumber(-0.3, 0.3)
		local mid = from + Vector3.new(math.cos(a) * 3 * s, rng:NextNumber(1, 2) * s, math.sin(a) * 3 * s)
		Build.limb(model, from, mid, 0.7 * s, { Color = TRUNK })
		for j = -1, 1, 2 do
			local b = a + j * 0.5
			local tip = mid + Vector3.new(math.cos(b) * 2 * s, rng:NextNumber(0.8, 1.6) * s, math.sin(b) * 2 * s)
			Build.limb(model, mid, tip, 0.4 * s, { Color = TRUNK })
			Build.leafCluster(model, rng, tip, rng:NextNumber(3.8, 4.8) * s, if rng:NextNumber() < 0.5 then BLOSSOM else BLOSSOM_LIGHT, 2)
		end
	end
	Build.leafCluster(model, rng, top + Vector3.new(0, 2 * s, 0), 6 * s, BLOSSOM)
	petals(model:FindFirstChildWhichIsA("BasePart"), 5)
	return model
end

-- a weeping cherry: strands of blossoms hanging down from a round crown
local function weepingCherry(parent, rng, base, s)
	local model = Build.model(parent, "WeepingCherry")
	local points = twistedTrunk(model, rng, base, 8 * s, 1.5 * s)
	local crown = points[4] + Vector3.new(0, 1.5 * s, 0)
	Build.leafCluster(model, rng, crown, 6 * s, BLOSSOM)
	for k = 0, 7 do
		local a = k / 8 * math.pi * 2
		local start = crown + Vector3.new(math.cos(a) * 3 * s, 0, math.sin(a) * 3 * s)
		for j = 0, 3 do
			Build.ball(model, start - Vector3.new(0, j * 1.1 * s, 0) + Vector3.new(math.cos(a), 0, math.sin(a)) * j * 0.35 * s, (1.3 - j * 0.12) * s, {
				Color = if j % 2 == 0 then BLOSSOM else BLOSSOM_LIGHT,
				CanCollide = false,
			})
		end
	end
	petals(model:FindFirstChildWhichIsA("BasePart"), 5)
	return model
end

local function maple(parent, rng, base, s)
	local model = Build.model(parent, "Maple")
	local points = twistedTrunk(model, rng, base, 7 * s, 1.3 * s)
	local color = pick(rng, { Color3.fromRGB(245, 80, 60), Color3.fromRGB(255, 130, 50), Color3.fromRGB(235, 60, 90) })
	for k = 1, 3 do
		local a = k / 3 * math.pi * 2 + rng:NextNumber(-0.3, 0.3)
		local tip = points[4] + Vector3.new(math.cos(a) * 2.6 * s, rng:NextNumber(0.5, 1.5) * s, math.sin(a) * 2.6 * s)
		Build.limb(model, points[3], tip, 0.5 * s, { Color = TRUNK })
		Build.leafCluster(model, rng, tip, 4.2 * s, color, 2)
	end
	Build.leafCluster(model, rng, points[4] + Vector3.new(0, 1.6 * s, 0), 5.5 * s, color)
	return model
end

local function bambooCluster(parent, rng, base, count)
	local model = Build.model(parent, "Bamboo")
	for i = 1, count do
		local p = base + Vector3.new(rng:NextNumber(-2.5, 2.5), 0, rng:NextNumber(-2.5, 2.5))
		local height = rng:NextNumber(14, 24)
		local lean = Vector3.new(rng:NextNumber(-1.2, 1.2), 0, rng:NextNumber(-1.2, 1.2))
		local color = Build.vary(rng, if i % 4 == 0 then Color3.fromRGB(190, 215, 90) else BAMBOO, 0.05)
		local width = rng:NextNumber(0.7, 1)
		-- segments between the joints, each joint a slightly wider ring
		local segment = 4.5
		local previous = p - Vector3.new(0, 0.3, 0)
		local y = 0
		while y < height do
			y = math.min(y + segment, height)
			local q = p + Vector3.new(0, y, 0) + lean * (y / height) ^ 2
			Build.limb(model, previous, q, width, { Color = color })
			Build.ball(model, q, width * 1.12, { Color = color:Lerp(Color3.new(1, 1, 1), 0.15), CanCollide = false })
			-- leaf sprays from the upper joints
			if y > height - 3 * segment then
				local a = rng:NextNumber(0, math.pi * 2)
				for k = 0, 2 do
					local b = a + k * 0.5
					Build.ghost(Build.part(model, {
						Size = Vector3.new(0.7, 0.12, 2.6),
						CFrame = CFrame.new(q) * CFrame.Angles(0, b, 0) * CFrame.Angles(math.rad(-15 + k * 10), 0, 0) * CFrame.new(0, 0, -1.4),
						Color = Build.vary(rng, LEAF, 0.05),
					}))
				end
			end
			previous = q
		end
	end
	-- a young shoot at the base
	Build.cylinder(model, base + Vector3.new(1.5, 0, -1.5), 1.2, 0.8, { Color = Color3.fromRGB(190, 170, 100) })
	Build.cylinder(model, base + Vector3.new(1.5, 1.2, -1.5), 0.8, 0.5, { Color = Color3.fromRGB(190, 170, 100) })
	return model
end

-- Plants ----------------------------------------------------------------------------------------

local function fern(parent, rng, base)
	local model = Build.model(parent, "Fern")
	for k = 0, 6 do
		local a = k / 7 * math.pi * 2 + rng:NextNumber(-0.2, 0.2)
		Build.part(model, {
			Size = Vector3.new(0.6, 0.1, 2.4),
			CFrame = CFrame.new(base + Vector3.new(0, 0.6, 0)) * CFrame.Angles(0, a, 0) * CFrame.Angles(math.rad(30), 0, 0) * CFrame.new(0, 0, -1.1),
			Color = Build.vary(rng, Color3.fromRGB(80, 190, 90), 0.05),
		})
	end
	for _, p in ipairs(model:GetChildren()) do
		Build.ghost(p)
	end
	return model
end

-- a round bush with flower balls dotted on it (hydrangea: blue/purple, azalea: pink)
local function floweringBush(parent, rng, base, colors)
	local model = Build.model(parent, "FloweringBush")
	local center = base + Vector3.new(0, 1.3, 0)
	Build.leafCluster(model, rng, center, 3.4, LEAF)
	for _ = 1, 7 do
		local a = rng:NextNumber(0, math.pi * 2)
		local up = rng:NextNumber(0, 0.9)
		local dir = Vector3.new(math.cos(a), up, math.sin(a)).Unit
		local color = pick(rng, colors)
		Build.ball(model, center + dir * 1.6, 1, { Color = color })
		Build.ball(model, center + dir * 1.75 + Vector3.new(0, 0.2, 0), 0.6, { Color = color:Lerp(Color3.new(1, 1, 1), 0.3) })
	end
	return model
end

local function iris(parent, rng, base)
	for _ = 1, 3 do
		local p = base + Vector3.new(rng:NextNumber(-0.8, 0.8), 0, rng:NextNumber(-0.8, 0.8))
		Build.ghost(Build.block(parent, p, Vector3.new(0.15, 2, 0.4), { Color = LEAF }))
		for k = 0, 2 do
			Build.ghost(Build.part(parent, {
				Size = Vector3.new(0.35, 0.1, 0.6),
				CFrame = CFrame.new(p + Vector3.new(0, 2, 0)) * CFrame.Angles(0, k / 3 * math.pi * 2, 0) * CFrame.Angles(math.rad(-40), 0, 0) * CFrame.new(0, 0, -0.3),
				Color = Color3.fromRGB(150, 110, 255),
			}))
		end
		Build.ghost(Build.ball(parent, p + Vector3.new(0, 2.1, 0), 0.25, { Color = Color3.fromRGB(255, 215, 60) }))
	end
end

-- Japanese architecture ---------------------------------------------------------------------------

local function torii(parent, x, width)
	local model = Build.model(parent, "Torii")
	for _, z in ipairs({ -width / 2, width / 2 }) do
		Build.cylinder(model, Vector3.new(x, 0, z), 1.4, 2.6, { Color = CHARCOAL }) -- base
		Build.cylinder(model, Vector3.new(x, 1.4, z), 16.4, 1.8, { Color = TORII })
	end
	-- nuki: the tie beam, poking out past the pillars
	Build.block(model, Vector3.new(x, 13.2, 0), Vector3.new(1.1, 1.1, width + 4), { Color = TORII })
	-- plaque in the middle, with the area's name
	Build.block(model, Vector3.new(x, 14.3, 0), Vector3.new(0.9, 3.4, 0.9), { Color = TORII })
	local plaque = Build.block(model, Vector3.new(x, 14.6, 0), Vector3.new(1.3, 2.8, 2.2), { Color = CHARCOAL })
	for _, face in ipairs({ Enum.NormalId.Left, Enum.NormalId.Right }) do
		local gui = Instance.new("SurfaceGui")
		gui.Face = face
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 40
		gui.Parent = plaque
		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Size = UDim2.fromScale(1, 1)
		label.Font = Enum.Font.GothamBlack
		label.TextScaled = true
		label.TextColor3 = Color3.fromRGB(255, 205, 50)
		label.Text = "桜"
		label.Parent = gui
	end
	-- shimaki and kasagi: the two top beams, the upper one curving up at the ends
	Build.block(model, Vector3.new(x, 17.6, 0), Vector3.new(1.8, 1, width + 6), { Color = TORII })
	for k = -3, 3 do
		local z = k * (width + 8) / 7
		local lift = (math.abs(k) / 3) ^ 2 * 1.2
		Build.block(model, Vector3.new(x, 18.6 + lift, z), Vector3.new(2.4, 1, (width + 8) / 7 + 0.3), { Color = CHARCOAL }, 0)
	end
	return model
end

-- tōrō: base, shaft, platform, a light box with windows, a roof with turned-up corners, a finial
local function lantern(parent, base)
	local model = Build.model(parent, "StoneLantern")
	Build.block(model, base, Vector3.new(2.8, 0.7, 2.8), { Color = STONE })
	Build.block(model, base + Vector3.new(0, 0.7, 0), Vector3.new(2.2, 0.3, 2.2), { Color = STONE })
	Build.cylinder(model, base + Vector3.new(0, 1, 0), 2.4, 1, { Color = STONE })
	Build.block(model, base + Vector3.new(0, 3.4, 0), Vector3.new(2.4, 0.5, 2.4), { Color = STONE })
	local light = Build.block(model, base + Vector3.new(0, 3.9, 0), Vector3.new(1.3, 1.5, 1.3), { Color = Color3.fromRGB(255, 215, 140), Material = Enum.Material.Neon })
	for _, c in ipairs({ { 1, 1 }, { 1, -1 }, { -1, 1 }, { -1, -1 } }) do
		Build.block(model, base + Vector3.new(c[1] * 0.8, 3.9, c[2] * 0.8), Vector3.new(0.35, 1.5, 0.35), { Color = STONE }) -- window frame
	end
	local glow = Instance.new("PointLight")
	glow.Color = Color3.fromRGB(255, 190, 120)
	glow.Range = 12
	glow.Brightness = 1.2
	glow.Parent = light
	Build.block(model, base + Vector3.new(0, 5.4, 0), Vector3.new(3.4, 0.5, 3.4), { Color = STONE })
	Build.block(model, base + Vector3.new(0, 5.9, 0), Vector3.new(2.2, 0.5, 2.2), { Color = STONE })
	for _, c in ipairs({ { 1, 1 }, { 1, -1 }, { -1, 1 }, { -1, -1 } }) do
		Build.block(model, base + Vector3.new(c[1] * 1.55, 5.8, c[2] * 1.55), Vector3.new(0.5, 0.5, 0.5), { Color = STONE })
	end
	Build.ball(model, base + Vector3.new(0, 6.8, 0), 0.9, { Color = STONE })
	Build.block(model, base + Vector3.new(0, 7.1, 0), Vector3.new(0.3, 0.6, 0.3), { Color = STONE })
	return model
end

-- Japanese wall: a stone base, white plaster with timber posts and a beam,
-- round windows, and a sloped tile roof with rows of round tiles and a ridge
local function japaneseWall(parent, rng, x0, x1, z)
	local model = Build.model(parent, "JapaneseWall")
	local length = x1 - x0
	local cx = (x0 + x1) / 2
	local out = math.sign(z) -- away from the path
	-- rounded stone base
	local x = x0
	while x < x1 do
		local w = math.min(rng:NextNumber(1.6, 2.6), x1 - x)
		Build.block(model, Vector3.new(x + w / 2, 0, z), Vector3.new(w - 0.15, 1.3, 2.8), { Color = Build.vary(rng, STONE, 0.04) })
		x += w
	end
	Build.block(model, Vector3.new(cx, 1.3, z), Vector3.new(length, 4.6, 2.2), { Color = PLASTER })
	Build.block(model, Vector3.new(cx, 5.4, z), Vector3.new(length, 0.5, 2.3), { Color = TIMBER })
	for px = x0 + 2, x1 - 2, 8 do
		Build.block(model, Vector3.new(px, 1.3, z), Vector3.new(0.6, 4.6, 2.35), { Color = TIMBER })
	end
	-- round windows with a lattice, facing the path
	for px = x0 + 10, x1 - 6, 16 do
		local c = CFrame.new(px, 3.5, z - out * 1.12) * CFrame.Angles(0, math.rad(90), 0)
		Build.part(model, { Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.1, 2.4, 2.4), CFrame = c, Color = TIMBER })
		Build.part(model, { Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.12, 2, 2), CFrame = c, Color = Color3.fromRGB(255, 240, 200) })
		Build.part(model, { Size = Vector3.new(0.14, 2, 0.15), CFrame = c, Color = TIMBER })
		Build.part(model, { Size = Vector3.new(0.14, 0.15, 2), CFrame = c, Color = TIMBER })
	end
	-- tile roof: two slopes, each with rows of round tiles, and a ridge
	for _, s in ipairs({ -1, 1 }) do
		local slope = CFrame.new(cx, 6.5, z + s * 1) * CFrame.Angles(math.rad(s * 28), 0, 0) -- lower on the outside
		Build.part(model, { Size = Vector3.new(length, 0.3, 2.6), CFrame = slope, Color = ROOF })
		for row = -1, 1 do
			Build.part(model, {
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(length, 0.35, 0.35),
				CFrame = slope * CFrame.new(0, 0.22, row * 0.8),
				Color = ROOF:Lerp(Color3.new(1, 1, 1), 0.15),
			})
		end
	end
	Build.part(model, { Shape = Enum.PartType.Cylinder, Size = Vector3.new(length, 0.8, 0.8), CFrame = CFrame.new(cx, 7.2, z), Color = ROOF:Lerp(Color3.new(0, 0, 0), 0.1) })
	return model
end

local function pagoda(parent, base)
	local model = Build.model(parent, "Pagoda")
	Build.block(model, base, Vector3.new(24, 1.6, 24), { Color = STONE }) -- stone platform
	local y = 1.6
	for tier = 0, 4 do
		local w = 18 - tier * 2.6
		-- body with posts and a balcony rail
		Build.block(model, base + Vector3.new(0, y, 0), Vector3.new(w - 5, 5, w - 5), { Color = if tier == 0 then PLASTER else TORII })
		for _, c in ipairs({ { 1, 1 }, { 1, -1 }, { -1, 1 }, { -1, -1 } }) do
			Build.block(model, base + Vector3.new(c[1] * (w - 5) / 2, y, c[2] * (w - 5) / 2), Vector3.new(0.8, 5, 0.8), { Color = if tier == 0 then TORII else PLASTER })
		end
		y += 5
		-- bracket layer, then a wide roof with turned-up corners
		Build.block(model, base + Vector3.new(0, y, 0), Vector3.new(w - 3.5, 0.8, w - 3.5), { Color = Color3.fromRGB(255, 205, 50) })
		y += 0.8
		Build.block(model, base + Vector3.new(0, y, 0), Vector3.new(w, 0.8, w), { Color = ROOF })
		Build.block(model, base + Vector3.new(0, y + 0.8, 0), Vector3.new(w - 2.4, 0.6, w - 2.4), { Color = ROOF:Lerp(Color3.new(1, 1, 1), 0.15) })
		for _, c in ipairs({ { 1, 1 }, { 1, -1 }, { -1, 1 }, { -1, -1 } }) do
			local corner = base + Vector3.new(c[1] * (w / 2 - 0.5), y + 0.8, c[2] * (w / 2 - 0.5))
			Build.part(model, {
				Size = Vector3.new(1, 0.6, 2.2),
				CFrame = CFrame.lookAt(corner, corner + Vector3.new(c[1], 0, c[2])) * CFrame.Angles(math.rad(25), 0, 0),
				Color = ROOF,
			})
			Build.ball(model, corner + Vector3.new(c[1] * 0.8, 0.8, c[2] * 0.8), 0.5, { Color = Color3.fromRGB(255, 205, 50) }) -- little bells
		end
		y += 1.4
	end
	-- sōrin: the spire with rings
	Build.cylinder(model, base + Vector3.new(0, y, 0), 8, 0.6, { Color = Color3.fromRGB(255, 205, 50) })
	for k = 0, 5 do
		Build.cylinder(model, base + Vector3.new(0, y + 1.5 + k * 0.9, 0), 0.25, 1.8 - k * 0.15, { Color = Color3.fromRGB(255, 205, 50) })
	end
	Build.ball(model, base + Vector3.new(0, y + 8.2, 0), 1, { Color = Color3.fromRGB(255, 205, 50) })
	return model
end

-- a koi pond with a rocky rim, lily pads, koi, a red arched bridge, irises
-- and a bamboo water spout (shishi-odoshi)
local function koiPond(parent, rng, center)
	local model = Build.model(parent, "KoiPond")
	local R = 9
	for k = 0, 15 do
		local a = k / 16 * math.pi * 2
		Build.rock(model, rng, center + Vector3.new(math.cos(a) * R, -0.3, math.sin(a) * R), rng:NextNumber(1.8, 2.6), STONE, if k % 3 == 0 then LEAF else nil)
	end
	Build.part(model, {
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.4, R * 2, R * 2),
		CFrame = CFrame.new(center + Vector3.new(0, 0.1, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(70, 175, 200),
		Material = Enum.Material.Glass,
		Transparency = 0.2,
		CanCollide = false,
	})
	for k = 1, 6 do
		local p = center + Vector3.new(rng:NextNumber(-6, 6), 0.2, rng:NextNumber(-6, 6))
		local fish = Build.ghost(Build.part(model, {
			Size = Vector3.new(0.8, 0.3, 1.8),
			CFrame = CFrame.new(p) * CFrame.Angles(0, math.rad(rng:NextNumber(0, 360)), 0),
			Color = if k % 2 == 0 then Color3.fromRGB(255, 130, 40) else Color3.fromRGB(250, 250, 250),
		}))
		Build.ghost(Build.part(model, { Size = Vector3.new(0.5, 0.32, 0.5), CFrame = fish.CFrame * CFrame.new(0, 0.01, 0.2), Color = Color3.fromRGB(230, 60, 40) }))
		Build.ghost(Build.part(model, { Size = Vector3.new(0.9, 0.1, 0.5), CFrame = fish.CFrame * CFrame.new(0, 0, 1.1), Color = fish.Color }))
	end
	for _ = 1, 5 do
		local p = center + Vector3.new(rng:NextNumber(-6, 6), 0.3, rng:NextNumber(-6, 6))
		Build.ghost(Build.cylinder(model, p, 0.1, 1.8, { Color = Color3.fromRGB(80, 170, 80) }))
		if rng:NextNumber() < 0.6 then
			Build.ghost(Build.ball(model, p + Vector3.new(0.3, 0.3, 0), 0.5, { Color = Color3.fromRGB(255, 175, 215) }))
		end
	end
	-- the arched bridge across the middle
	local segments = 9
	for k = 0, segments - 1 do
		local t = (k + 0.5) / segments
		local x = (t - 0.5) * (R * 2 + 2)
		local y = math.sin(t * math.pi) * 2.4 + 0.6
		local slope = math.cos(t * math.pi) * 2.4 * math.pi / (R * 2 + 2)
		local cf = CFrame.new(center + Vector3.new(x, y, 0)) * CFrame.Angles(0, 0, math.atan(slope))
		Build.part(model, { Size = Vector3.new((R * 2 + 2) / segments + 0.15, 0.4, 3.4), CFrame = cf, Color = TORII })
		for _, zz in ipairs({ -1.6, 1.6 }) do
			Build.part(model, { Size = Vector3.new(0.3, 1.2, 0.3), CFrame = cf * CFrame.new(0, 0.8, zz), Color = TORII })
			Build.part(model, { Size = Vector3.new((R * 2 + 2) / segments + 0.15, 0.25, 0.3), CFrame = cf * CFrame.new(0, 1.45, zz), Color = TORII })
		end
	end
	-- irises at the edge and the bamboo spout
	iris(model, rng, center + Vector3.new(-R + 1, 0, R * 0.6))
	iris(model, rng, center + Vector3.new(R * 0.4, 0, R - 1))
	local spout = center + Vector3.new(R + 1.5, 0, -2)
	Build.limb(model, spout, spout + Vector3.new(0, 3.5, 0), 0.9, { Color = BAMBOO })
	Build.limb(model, spout + Vector3.new(0, 3, 0), spout + Vector3.new(-2.8, 2.2, 0), 0.6, { Color = BAMBOO })
	Build.limb(model, spout + Vector3.new(0.8, 0, 0), spout + Vector3.new(0.8, 2.4, 0), 0.6, { Color = BAMBOO })
	local drip = Build.ghost(Build.limb(model, spout + Vector3.new(-2.8, 2.1, 0), spout + Vector3.new(-3, 0.2, 0), 0.25, {
		Color = Color3.fromRGB(150, 220, 255),
		Material = Enum.Material.Glass,
		Transparency = 0.3,
	}))
	drip.Name = "Water"
	return model
end

-- Building the area ----------------------------------------------------------------------------------

-- The Fuse Machine: a little blossom shrine with a glass bubble on top where
-- a glowing core spins inside two rings, a small glass jar of pets on the
-- left going in and a big gold pod on the right coming out, a curved roof,
-- lanterns, and a pink circle in front to step on (the client opens the
-- screen; server/Fuse.luau does the fusing).
local function fuseMachine(parent, at)
	local model = Build.model(parent, "FuseMachine")
	local white = Color3.fromRGB(252, 250, 255)
	local pink = Color3.fromRGB(255, 120, 180)
	local gold = Color3.fromRGB(255, 205, 80)
	-- the stone base with a pink trim
	Build.block(model, at - Vector3.new(0, 0.3, 0), Vector3.new(12, 1, 7), { Color = STONE })
	Build.block(model, at + Vector3.new(0, 0.6, 0), Vector3.new(11, 0.3, 6), { Color = pink })
	-- the body: a round white drum with a pink band
	Build.cylinder(model, at + Vector3.new(0, 0.9, 0), 4.2, 5.2, { Color = white })
	Build.cylinder(model, at + Vector3.new(0, 3, 0), 0.6, 5.5, { Color = pink })
	-- the glass bubble with the core and two rings
	local center = at + Vector3.new(0, 7.2, 0)
	Build.ball(model, center - Vector3.new(0, 2.2, 0), 5, { Color = Color3.fromRGB(255, 225, 240), Material = Enum.Material.Glass, Transparency = 0.55, CanCollide = false })
	local core = Build.ball(model, center - Vector3.new(0, 1.1, 0), 1.6, { Name = "Core", Color = Color3.fromRGB(255, 160, 210), Material = Enum.Material.Neon, CanCollide = false })
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 170, 215)
	light.Range = 14
	light.Brightness = 1.2
	light.Parent = core
	Build.bob(core, 0.35, 1.2)
	for k, tilt in ipairs({ 25, -25 }) do
		local ring = Build.part(model, {
			Name = "Ring",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.18, 3.2, 3.2),
			CFrame = CFrame.new(core.Position) * CFrame.Angles(math.rad(tilt), 0, math.rad(90)),
			Color = if k == 1 then gold else Color3.fromRGB(255, 255, 255),
			Material = Enum.Material.Neon,
			Transparency = 0.2,
			CanCollide = false,
		})
		Build.spin(ring, if k == 1 then 50 else -40, "Y")
	end
	-- a curved roof on four red posts
	for _, dx in ipairs({ -2.9, 2.9 }) do
		for _, dz in ipairs({ -2.3, 2.3 }) do
			Build.block(model, at + Vector3.new(dx, 0.75, dz), Vector3.new(0.5, 8.6, 0.5), { Color = TORII })
		end
	end
	Build.block(model, at + Vector3.new(0, 9.3, 0), Vector3.new(8, 0.5, 6.4), { Color = TORII })
	Build.block(model, at + Vector3.new(0, 9.8, 0), Vector3.new(9.4, 0.6, 7.6), { Color = ROOF })
	Build.block(model, at + Vector3.new(0, 10.4, 0), Vector3.new(6.4, 0.6, 4.8), { Color = ROOF })
	Build.ball(model, at + Vector3.new(0, 11.3, 0), 1.2, { Color = gold, Material = Enum.Material.Neon })
	-- in: a little jar of tiny pets (coloured balls) on the left
	local jar = at + Vector3.new(-4.6, 0.9, -0.5)
	Build.cylinder(model, jar, 3, 2.2, { Color = Color3.fromRGB(230, 245, 255), Material = Enum.Material.Glass, Transparency = 0.45, CanCollide = false })
	Build.cylinder(model, jar + Vector3.new(0, 3, 0), 0.4, 2.5, { Color = pink })
	for k, c in ipairs({ Color3.fromRGB(255, 200, 120), Color3.fromRGB(150, 220, 255), Color3.fromRGB(180, 240, 150), Color3.fromRGB(255, 170, 200) }) do
		Build.ball(model, jar + Vector3.new(((k % 2) - 0.5) * 0.8, 0.5 + k * 0.5, ((k // 2) % 2 - 0.5) * 0.6), 0.75, { Color = c, CanCollide = false })
	end
	Build.cylinder(model, jar + Vector3.new(1.3, 2.4, 0), 0.4, 0.5, { Color = white })
	-- out: a big gold pod with a star on the right
	local pod = at + Vector3.new(4.6, 0.9, -0.5)
	Build.cylinder(model, pod, 1.2, 2.6, { Color = white })
	local podBall = Build.ball(model, pod + Vector3.new(0, 2.4, 0), 2.4, { Name = "Pod", Color = gold, Material = Enum.Material.SmoothPlastic })
	Build.ball(model, podBall.Position + Vector3.new(0, 0, -1.05), 0.6, { Color = Color3.fromRGB(255, 255, 255), Material = Enum.Material.Neon, CanCollide = false })
	-- blossom petals drifting off the roof
	petals(Build.part(model, { Size = Vector3.new(8, 0.2, 6), CFrame = CFrame.new(at + Vector3.new(0, 10, 0)), Transparency = 1, CanCollide = false, CastShadow = false }), 3)
	-- the sign (the client and Fuse.luau write on it)
	local signPart = Build.part(model, { Name = "Sign", Size = Vector3.one, CFrame = CFrame.new(at + Vector3.new(0, 14.2, 0)), Transparency = 1, CanCollide = false, CastShadow = false })
	local sign = Instance.new("BillboardGui")
	sign.Name = "SignGui"
	sign.Size = UDim2.fromScale(14, 3.6)
	sign.MaxDistance = 120
	sign.LightInfluence = 0
	sign.Adornee = signPart
	sign.Parent = signPart
	local function line(text, y, h, color, stroke)
		local l = Instance.new("TextLabel")
		l.BackgroundTransparency = 1
		l.Position = UDim2.fromScale(0, y)
		l.Size = UDim2.fromScale(1, h)
		l.Font = Enum.Font.FredokaOne
		l.TextScaled = true
		l.TextColor3 = color
		l.Text = text
		local st = Instance.new("UIStroke")
		st.Color = stroke
		st.Thickness = 3
		st.Parent = l
		l.Parent = sign
		return l
	end
	line("Fuse Machine", 0, 0.58, Color3.new(1, 1, 1), Color3.fromRGB(190, 60, 120))
	line(Config.FUSE.HugeFrom .. " pets → HUGE  ·  " .. Config.FUSE.TitanicFrom .. " Huge → TITANIC", 0.6, 0.36, Color3.fromRGB(255, 235, 150), Color3.fromRGB(120, 50, 90))
	-- the circle to step on, in front (facing the path)
	local circleAt = at + Vector3.new(0, -0.4, -8)
	Build.cylinder(model, circleAt, 1.2, 8, { Name = "CircleRim", Color = white })
	local circle = Build.cylinder(model, circleAt, 1.35, 7, { Name = "FuseCircle", Color = Color3.fromRGB(255, 170, 210) })
	Build.cylinder(model, circleAt + Vector3.new(0, 1.35, 0), 0.04, 5.6, { Color = Color3.fromRGB(255, 255, 255), Material = Enum.Material.Neon, CanCollide = false })
	Build.cylinder(model, circleAt + Vector3.new(0, 1.37, 0), 0.04, 4.8, { Color = Color3.fromRGB(255, 170, 210), CanCollide = false })
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
	hintText.TextStrokeColor3 = Color3.fromRGB(150, 50, 100)
	hintText.TextStrokeTransparency = 0
	hintText.Text = "Step here to fuse"
	hintText.Parent = hint
	return { Model = model, Circle = circle, Core = core, Sign = signPart }
end

function Sakura.build(ctx)
	local folder, rng, space = ctx.Folder, ctx.Rng, ctx.Space
	local x0, x1, half = ctx.X0, ctx.X1, ctx.Half
	local deco = Build.folder(folder, "Decor")
	local terrain = ctx.Terrain

	-- mossy patches in the grass
	for _ = 1, 8 do
		local c = Vector3.new(rng:NextNumber(x0, x1), -2, rng:NextNumber(-half, half))
		terrain:ReplaceMaterial(Region3.new(c - Vector3.new(5, 2, 4), c + Vector3.new(5, 2, 4)):ExpandToGrid(4), 4, Enum.Material.LeafyGrass, Enum.Material.Grass)
	end

	-- green hills and a bamboo forest beyond the walls, and the pagoda
	for x = x0, x1 + 10, 14 do
		for _, s in ipairs({ -1, 1 }) do
			terrain:FillBall(Vector3.new(x + rng:NextNumber(-4, 4), rng:NextNumber(-10, -5), s * rng:NextNumber(half + 30, half + 55)), rng:NextNumber(16, 24), Enum.Material.LeafyGrass)
		end
	end
	local outside = Build.space()
	local pagodaBase = Vector3.new(x0 + 58, 0, half + 26)
	Build.scale(pagoda(deco, pagodaBase), pagodaBase, 0.8)
	outside:add(pagodaBase, 12)
	for x = x0 + 5, x1 - 5, 11 do
		for _, s in ipairs({ -1, 1 }) do
			local base = Vector3.new(x + rng:NextNumber(-2, 2), 0, s * rng:NextNumber(half + 7, half + 18))
			if outside:free(base, 3) then
				if rng:NextNumber() < 0.7 then
					Build.scale(bambooCluster(deco, rng, base, rng:NextInteger(3, 5)), base, 0.8)
				else
					sakuraTree(deco, rng, base, rng:NextNumber(1, 1.2))
				end
				outside:add(base, 3)
			end
		end
	end

	-- Japanese walls on both sides
	for _, s in ipairs({ -1, 1 }) do
		japaneseWall(deco, rng, x0, x1, s * (half + 3))
	end

	-- a straight stone path down the middle, with torii gates over it
	-- (painted on top so it shows on any floor)
	ctx.World.paintPath(deco, "Path", { Vector3.new(x0, 0, 0), Vector3.new(x1, 0, 0) }, 6, STONE, Color3.fromRGB(175, 172, 190))
	for _, x in ipairs({ x0 + 12, x0 + 55, x1 - 12 }) do
		Build.scale(torii(deco, x, 16), Vector3.new(x, 0, 0), 0.75)
		space:add(Vector3.new(x, 0, 6), 2.5)
		space:add(Vector3.new(x, 0, -6), 2.5)
	end
	for x = x0, x1, 5 do
		space:add(Vector3.new(x, 0, 0), 3.5) -- keep the path free
	end

	-- lanterns lining the path
	for x = x0 + 6, x1 - 6, 22 do
		for _, s in ipairs({ -1, 1 }) do
			local base = Vector3.new(x, 0, s * 6)
			lantern(deco, base)
			space:add(base, 2)
		end
	end

	-- koi pond, scaled down to fit
	local pondCenter = Vector3.new(x0 + 34, 0, -(half - 12))
	Build.scale(koiPond(deco, rng, pondCenter), pondCenter, 0.7)
	table.insert(ctx.World.FloorHoles, { pondCenter.X, pondCenter.Z, 7 })
	space:add(pondCenter, 9)

	-- the Fuse Machine by the gate in, on the right, its circle towards the path
	-- (on the real ground)
	local fuseAt = Vector3.new(x0 + 30, 0, half - 11)
	fuseAt = Vector3.new(fuseAt.X, math.max(ctx.World.groundAt and ctx.World.groundAt(fuseAt.X, fuseAt.Z) or 0, Config.GROUND_Y), fuseAt.Z)
	ctx.World.FuseMachine = fuseMachine(deco, fuseAt)
	space:add(Vector3.new(fuseAt.X, 0, fuseAt.Z), 8)
	space:add(Vector3.new(fuseAt.X, 0, fuseAt.Z - 8), 4.5)

	-- trees along the sides: mostly cherries, some weeping, some maples
	local kinds = { sakuraTree, sakuraTree, sakuraTree, weepingCherry, maple }
	for x = x0 + 6, x1 - 6, 12 do
		for _, s in ipairs({ -1, 1 }) do
			local base = Vector3.new(x + rng:NextNumber(-3, 3), 0, s * rng:NextNumber(half - 5, half - 3))
			if space:free(base, 4) then
				Build.scale(pick(rng, kinds)(deco, rng, base, rng:NextNumber(1, 1.2)), base, 0.75)
				space:add(base, 4)
			end
		end
	end
	for _ = 1, 3 do
		local base = space:find(rng, x0 + 10, x1 - 10, -half + 10, half - 10, 5)
		if base then
			Build.scale(pick(rng, kinds)(deco, rng, base, rng:NextNumber(1.1, 1.3)), base, 0.75)
		end
	end

	ctx.reserveSpots() -- breakables get their room before the small props

	-- bamboo, flowering bushes, ferns and mossy rocks
	for _ = 1, 3 do
		local base = space:find(rng, x0 + 6, x1 - 6, -half + 5, half - 5, 3)
		if base then
			Build.scale(bambooCluster(deco, rng, base, rng:NextInteger(3, 4)), base, 0.7)
		end
	end
	local hydrangea = { Color3.fromRGB(120, 150, 255), Color3.fromRGB(170, 130, 255), Color3.fromRGB(110, 190, 255) }
	local azalea = { Color3.fromRGB(255, 120, 180), Color3.fromRGB(255, 160, 200), Color3.fromRGB(255, 255, 255) }
	for k = 1, 6 do
		local base = space:find(rng, x0 + 4, x1 - 4, -half + 3, half - 3, 2.5)
		if base then
			floweringBush(deco, rng, base, if k % 2 == 0 then hydrangea else azalea)
		end
	end
	for _ = 1, 7 do
		local base = space:find(rng, x0 + 4, x1 - 4, -half + 3, half - 3, 2)
		if base then
			fern(deco, rng, base)
		end
	end
	for _ = 1, 4 do
		local base = space:find(rng, x0 + 6, x1 - 6, -half + 4, half - 4, 2.5)
		if base then
			Build.rock(deco, rng, base, rng:NextNumber(1.6, 2.6), STONE, LEAF)
		end
	end
end

return Sakura
