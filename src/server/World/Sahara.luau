-- Area 2: Sahara. Sand, dunes, pyramids, Cleopatra's temple, the pet fusion
-- machine, and high walls of big limestone blocks (like the Western Wall) on
-- both sides. Breakable: cactuses.
local Build = require(script.Parent.Build)

local Sahara = {}

Sahara.GROUND = Enum.Material.Sand

local LIMESTONE = Color3.fromRGB(222, 205, 170)
local SANDSTONE = Color3.fromRGB(215, 175, 115)
local GOLD = Color3.fromRGB(245, 195, 60)
local LAPIS = Color3.fromRGB(35, 70, 170)
local CACTUS = Color3.fromRGB(80, 160, 80)

-- High wall of big, slightly uneven limestone blocks, with little plants
-- growing from the joints
local function limestoneWall(parent, rng, x0, x1, z)
	local wall = Build.model(parent, "LimestoneWall")
	local course = 4.2
	for row = 0, 5 do
		local inset = row * 0.25 -- each course sits a little further back
		local x = x0 + rng:NextNumber(0, 5)
		if row == 0 then
			x = x0
		end
		while x < x1 do
			local length = math.min(rng:NextNumber(6, 13), x1 - x)
			local block = Build.block(
				wall,
				Vector3.new(x + length / 2, row * course, z + math.sign(z) * inset),
				Vector3.new(length - 0.25, course - 0.25, 5),
				{ Color = Build.vary(rng, LIMESTONE, 0.05), Material = Enum.Material.Limestone }
			)
			block.Name = "Stone"
			if rng:NextNumber() < 0.08 then
				-- a tuft of green in the joint, facing the path
				Build.ghost(Build.ball(wall, Vector3.new(x + length, row * course + course, z - math.sign(z) * 2.4), rng:NextNumber(1, 1.8), {
					Color = Build.vary(rng, Color3.fromRGB(95, 140, 70)),
					Material = Enum.Material.Grass,
				}))
			end
			x += length
		end
	end
	-- fill the corners before the first stones' offsets
	Build.block(wall, Vector3.new(x0 + 3, 0, z), Vector3.new(6, course * 6, 4.8), { Color = LIMESTONE, Material = Enum.Material.Limestone })
end

local function pyramid(parent, center, base, layers)
	local model = Build.model(parent, "Pyramid")
	local step = base / (layers + 1)
	local height = 5
	for layer = 0, layers - 1 do
		local size = base - layer * step
		Build.block(model, center + Vector3.new(0, layer * height, 0), Vector3.new(size, height, size), {
			Color = SANDSTONE:Lerp(Color3.fromRGB(240, 210, 150), layer / layers),
			Material = Enum.Material.Sandstone,
		})
	end
	Build.block(model, center + Vector3.new(0, layers * height, 0), Vector3.new(step, height, step), {
		Color = GOLD,
		Material = Enum.Material.Foil,
	})
	return model
end

local function palm(parent, rng, base)
	local model = Build.model(parent, "Palm")
	local height = rng:NextNumber(12, 17)
	local lean = CFrame.Angles(math.rad(rng:NextNumber(-8, 8)), 0, math.rad(rng:NextNumber(-8, 8)))
	local trunk = Build.part(model, {
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(height, 1.6, 1.6),
		CFrame = CFrame.new(base) * lean * CFrame.new(0, height / 2, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(150, 110, 70),
		Material = Enum.Material.Wood,
	})
	local top = (CFrame.new(base) * lean * CFrame.new(0, height, 0)).Position
	for k = 1, 7 do
		local yaw = k / 7 * 360
		Build.wedge(model, CFrame.new(top) * CFrame.Angles(0, math.rad(yaw), 0) * CFrame.Angles(math.rad(-20), 0, 0) * CFrame.new(0, 0, -4), Vector3.new(1.8, 0.4, 8), {
			Color = Build.vary(rng, Color3.fromRGB(70, 150, 60)),
			Material = Enum.Material.Grass,
		})
	end
	Build.ball(model, top, 1.8, { Color = Color3.fromRGB(110, 80, 40) })
	return trunk
end

local function obelisk(parent, base)
	Build.block(parent, base, Vector3.new(3, 16, 3), { Color = SANDSTONE, Material = Enum.Material.Sandstone })
	Build.block(parent, base + Vector3.new(0, 16, 0), Vector3.new(2, 2, 2), { Color = GOLD, Material = Enum.Material.Foil })
end

-- Cleopatra's temple: a stepped platform, gold-topped columns, a striped
-- roof, and her statue at the front with the blue and gold headdress
local function cleopatraTemple(parent, center)
	local model = Build.model(parent, "CleopatraTemple")
	-- steps
	for k = 0, 2 do
		Build.block(model, center + Vector3.new(0, k * 1, 0), Vector3.new(40 - k * 4, 1, 30 - k * 4), {
			Color = LIMESTONE,
			Material = Enum.Material.Limestone,
		})
	end
	local floor = center + Vector3.new(0, 3, 0)
	-- columns
	for _, x in ipairs({ -14, -7, 0, 7, 14 }) do
		for _, z in ipairs({ -9, 9 }) do
			local base = floor + Vector3.new(x, 0, z)
			Build.cylinder(model, base, 16, 2.6, { Color = Color3.fromRGB(235, 220, 190), Material = Enum.Material.Limestone })
			Build.cylinder(model, base + Vector3.new(0, 16, 0), 1.4, 3.6, { Color = GOLD, Material = Enum.Material.Foil })
		end
	end
	-- roof with blue and gold stripes
	local roofY = floor.Y + 17.4
	Build.block(model, Vector3.new(center.X, roofY, center.Z), Vector3.new(34, 2.4, 24), { Color = Color3.fromRGB(235, 220, 190), Material = Enum.Material.Limestone })
	for k = 0, 5 do
		Build.block(model, Vector3.new(center.X, roofY + 2.4, center.Z - 10 + k * 4), Vector3.new(34, 1, 2), {
			Color = if k % 2 == 0 then LAPIS else GOLD,
			Material = if k % 2 == 0 then Enum.Material.SmoothPlastic else Enum.Material.Foil,
		})
	end

	-- Cleopatra's statue on a pedestal in front (facing the path, +Z side)
	local front = floor + Vector3.new(0, 0, 13)
	Build.block(model, front - Vector3.new(0, 3, 0), Vector3.new(6, 5, 6), { Color = Color3.fromRGB(235, 220, 190), Material = Enum.Material.Marble })
	local statueBase = front + Vector3.new(0, 2, 0)
	Build.block(model, statueBase, Vector3.new(3.4, 7, 2.4), { Color = Color3.fromRGB(245, 245, 240), Material = Enum.Material.Marble }) -- dress
	Build.block(model, statueBase + Vector3.new(0, 5, 0), Vector3.new(4.4, 1, 2.6), { Color = GOLD, Material = Enum.Material.Foil }) -- collar
	local head = statueBase + Vector3.new(0, 8, 0)
	Build.ball(model, head, 2.4, { Color = Color3.fromRGB(200, 150, 105) })
	-- headdress: gold and blue stripes falling to the shoulders
	for k = 0, 4 do
		Build.block(model, head + Vector3.new(-1.3 + k * 0.65, -2.4, -0.4), Vector3.new(0.6, 3.6, 1.2), {
			Color = if k % 2 == 0 then GOLD else LAPIS,
			Material = if k % 2 == 0 then Enum.Material.Foil else Enum.Material.SmoothPlastic,
		})
	end
	Build.block(model, head + Vector3.new(0, 0.6, -0.2), Vector3.new(3, 1.2, 2.8), { Color = LAPIS })
	Build.block(model, head + Vector3.new(0, 1.2, 1.05), Vector3.new(0.5, 0.9, 0.5), { Color = GOLD, Material = Enum.Material.Foil }) -- cobra
	-- obelisks either side
	obelisk(model, floor + Vector3.new(-17, 0, 12))
	obelisk(model, floor + Vector3.new(17, 0, 12))
	return model
end

-- The fusion machine: a metal base, a glass dome with a glowing orb that
-- shows the fusion's progress, neon rings and a console with the prompt
local function fusionMachine(parent, center)
	local model = Build.model(parent, "FusionMachine")
	local metal = Color3.fromRGB(60, 64, 88)
	local glow = Color3.fromRGB(255, 90, 170)
	Build.cylinder(model, center, 3, 26, { Color = metal, Material = Enum.Material.DiamondPlate })
	Build.cylinder(model, center + Vector3.new(0, 3, 0), 0.6, 24, { Color = glow, Material = Enum.Material.Neon })
	Build.cylinder(model, center + Vector3.new(0, 3.6, 0), 2, 20, { Color = metal, Material = Enum.Material.Metal })
	-- pillars around the dome
	for k = 0, 5 do
		local a = k / 6 * math.pi * 2
		local p = center + Vector3.new(math.cos(a) * 11, 5.6, math.sin(a) * 11)
		Build.cylinder(model, p, 12, 1.6, { Color = metal, Material = Enum.Material.Metal })
		Build.ball(model, p + Vector3.new(0, 12, 0), 2.2, { Color = glow, Material = Enum.Material.Neon })
	end
	-- glass dome and the orb inside
	Build.ball(model, center + Vector3.new(0, 9, 0), 17, {
		Color = Color3.fromRGB(180, 220, 255),
		Material = Enum.Material.Glass,
		Transparency = 0.6,
		CastShadow = false,
	})
	local orb = Build.ball(model, center + Vector3.new(0, 10, 0), 3, {
		Name = "Orb",
		Color = glow,
		Material = Enum.Material.Neon,
		CanCollide = false,
	})
	local light = Instance.new("PointLight")
	light.Color = glow
	light.Range = 24
	light.Brightness = 2
	light.Parent = orb
	-- ring on top
	Build.part(model, {
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(1, 22, 22),
		CFrame = CFrame.new(center + Vector3.new(0, 18, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = metal,
		Material = Enum.Material.Metal,
	})
	-- console facing the path
	local console = Build.block(model, center + Vector3.new(0, 0, -16), Vector3.new(6, 4, 3), { Name = "Console", Color = metal, Material = Enum.Material.Metal })
	Build.block(model, center + Vector3.new(0, 4, -16), Vector3.new(5, 0.4, 2.4), { Color = glow, Material = Enum.Material.Neon })

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Fuse Pets"
	prompt.ObjectText = "Fusion Machine"
	prompt.HoldDuration = 0.2
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = console

	-- title and status above the machine
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(320, 90)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 24, 0)
	gui.MaxDistance = 150
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
		label.Text = if k == 1 then "PET FUSION" else "5 pets → 1 HUGE pet"
		label.Parent = gui
	end

	return { Model = model, Orb = orb, Prompt = prompt, Status = gui.Status, Light = light }
end

function Sahara.build(ctx)
	local folder, rng, space = ctx.Folder, ctx.Rng, ctx.Space
	local x0, x1, half = ctx.X0, ctx.X1, ctx.Half
	local deco = Build.folder(folder, "Decor")
	local terrain = ctx.Terrain

	-- dunes behind the walls
	for x = x0, x1, 18 do
		for _, side in ipairs({ -1, 1 }) do
			terrain:FillBall(
				Vector3.new(x + rng:NextNumber(-6, 6), rng:NextNumber(-14, -6), side * rng:NextNumber(half + 60, half + 110)),
				rng:NextNumber(22, 34),
				Enum.Material.Sand
			)
		end
	end

	-- walls on both sides
	for _, side in ipairs({ -1, 1 }) do
		limestoneWall(deco, rng, x0, x1, side * (half + 4))
	end

	-- pyramids beyond the right wall (tall enough to see over it)
	pyramid(deco, Vector3.new(x0 + 110, 0, half + 70), 100, 13)
	pyramid(deco, Vector3.new(x0 + 40, 0, half + 95), 60, 8)
	pyramid(deco, Vector3.new(x0 + 170, 0, -(half + 85)), 70, 9)

	-- Cleopatra's temple (left) and the fusion machine (right)
	local templeCenter = Vector3.new(x0 + 140, 0, -(half - 22))
	cleopatraTemple(deco, templeCenter)
	space:add(templeCenter, 24)
	space:add(templeCenter + Vector3.new(0, 0, 14), 8)

	local machineCenter = Vector3.new(x0 + 75, 0, half - 30)
	ctx.World.Fusion = fusionMachine(deco, machineCenter)
	space:add(machineCenter, 17)
	space:add(machineCenter + Vector3.new(0, 0, -16), 6)

	-- palms and rocks
	for _ = 1, 12 do
		local base = space:find(rng, x0 + 8, x1 - 8, -half + 5, half - 5, 4)
		if base then
			palm(deco, rng, base)
		end
	end
	for _ = 1, 14 do
		local base = space:find(rng, x0 + 8, x1 - 8, -half + 5, half - 5, 3)
		if base then
			Build.ball(deco, base + Vector3.new(0, 0.3, 0), rng:NextNumber(2, 3.5), {
				Color = Build.vary(rng, Color3.fromRGB(195, 150, 100)),
				Material = Enum.Material.Sandstone,
			})
		end
	end
end

-- Cactus: the Sahara's breakable
function Sahara.breakable(parent, position, rng)
	local model = Build.model(parent, "Cactus")
	local color = Build.vary(rng, CACTUS)
	local props = function()
		return { Color = color, Material = Enum.Material.Grass }
	end
	local body = Build.cylinder(model, position, 7, 2.2, props())
	Build.ball(model, position + Vector3.new(0, 7, 0), 2.2, props())
	-- arms: out, then up
	for _, side in ipairs({ -1, 1 }) do
		local y = if side < 0 then 2.8 else 3.8
		local armBase = position + Vector3.new(side * 1.9, y, 0)
		Build.part(model, {
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(2, 1.4, 1.4),
			CFrame = CFrame.new(position + Vector3.new(side * 1, y, 0)),
			Color = color,
			Material = Enum.Material.Grass,
		})
		Build.cylinder(model, armBase, 2.6, 1.4, props())
		Build.ball(model, armBase + Vector3.new(0, 2.6, 0), 1.4, props())
	end
	-- a pink flower on top
	Build.ball(model, position + Vector3.new(0, 8.1, 0), 0.9, { Color = Color3.fromRGB(255, 110, 170) })
	model.PrimaryPart = body
	return model
end

return Sahara
