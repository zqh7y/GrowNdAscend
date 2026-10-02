-- Builds the map when the server starts: four areas in a straight line along
-- +X (Forest -> Sahara -> Frozen Peaks -> Sakura Jungle), terrain ground and
-- side scenery, invisible walls along both sides, and a gate between areas.
-- Other modules read the pieces they need from World (gates, breakable
-- spots, leaderboard boards, the fusion machine).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Build = require(ReplicatedStorage.Shared.Build)

local World = {}

local LENGTH = Config.AREA_LENGTH
local HALF = Config.AREA_HALF_WIDTH
local TOTAL = LENGTH * #Config.AREAS
local SIDE = 110 -- how far the scenery reaches to each side

local AREA_MODULES = { script.Forest, script.Sahara, script.Frozen, script.Sakura, script.Arena }

local map = Build.folder(workspace, "Map")
local terrain = workspace.Terrain

World.Areas = {} -- [i] = { Folder, Spots = { Vector3 }, Module }
World.Gates = {} -- [i] = { Barrier, Sign, Button } for the gate into area i (i >= 2)
World.Boards = {} -- [board id] = screen part (set by the Forest)
World.UpgradeBoard = nil -- the Upgrade Board's screen part (first area)
World.Fusion = nil -- the fusion machine (set by the Sahara)
World.SPAWN = Vector3.new(10, 4, 0)
World.Spawns = {} -- [i] = CFrame on the ground at the start of area i, facing +X

-- Height of the walkable terrain at (x, z), found by casting a ray down onto
-- the terrain (not onto props), or nil if there's no ground there
local groundRay = RaycastParams.new()
groundRay.FilterType = Enum.RaycastFilterType.Include
groundRay.FilterDescendantsInstances = { workspace.Terrain }
function World.groundAt(x, z)
	local hit = workspace:Raycast(Vector3.new(x, 200, z), Vector3.new(0, -400, 0), groundRay)
	return if hit then hit.Position.Y else nil
end

-- True if the ground around (x, z) is flat and at walking height (not on a
-- drift, a hill's edge or in a pond)
-- (flat compared with the ground's own height there: Roblox's terrain
-- surface doesn't come out at exactly Y = 0, so never assume it does)
function World.flatGround(x, z, radius)
	local center = World.groundAt(x, z)
	if not center then
		return false
	end
	for _, offset in ipairs({ { radius, 0 }, { -radius, 0 }, { 0, radius }, { 0, -radius } }) do
		local y = World.groundAt(x + offset[1], z + offset[2])
		if not y or math.abs(y - center) > 0.6 then
			return false
		end
	end
	return true
end

-- Paths painted on the ground ----------------------------------------------------------
-- A flat band through `points` (Vector3s, only X and Z are used) lying just
-- on top of the ground (and on top of the cartoon floor), `width` wide, with
-- round joints so bends are smooth and an optional darker edge. It doesn't
-- collide, isn't hit by rays (so coins and spots still find the real ground)
-- and casts no shadow. Returns the folder.
World.Paths = {} -- name -> folder (for the simulator)
World.PATH_LIFT = 0.3 -- studs above the ground (and the cartoon floor) it lies
function World.paintPath(parent, name, points, width, color, edge)
	local folder = Build.folder(parent, name)
	local function flat(props)
		props.CanCollide = false
		props.CastShadow = false
		local part = Build.part(folder, props)
		part.CanQuery = false
		part.CanTouch = false
		return part
	end
	local function band(w, top, c)
		for k, p in ipairs(points) do
			flat({
				Name = "PathJoint",
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(0.1, w, w),
				CFrame = CFrame.new(p.X, top - 0.05, p.Z) * CFrame.Angles(0, 0, math.rad(90)),
				Color = c,
			})
			local q = points[k + 1]
			if q then
				local dx, dz = q.X - p.X, q.Z - p.Z
				local length = math.sqrt(dx * dx + dz * dz)
				flat({
					Name = "PathPiece",
					Size = Vector3.new(length, 0.1, w),
					CFrame = CFrame.new((p.X + q.X) / 2, top - 0.05, (p.Z + q.Z) / 2) * CFrame.Angles(0, -math.atan2(dz, dx), 0),
					Color = c,
				})
			end
		end
	end
	-- just above the highest ground under it (the terrain can come out a
	-- little above Config.GROUND_Y), so the ground never covers it
	local top = Config.GROUND_Y
	for _, p in ipairs(points) do
		local y = World.groundAt(p.X, p.Z)
		if y and y < Config.GROUND_Y + 1.5 then
			top = math.max(top, y)
		end
	end
	top += World.PATH_LIFT
	if edge then
		band(width + 1, top - 0.02, edge)
	end
	band(width, top, color)
	folder:SetAttribute("Top", top)
	World.Paths[name] = folder
	World.PathPoints[folder] = points
	return folder
end

-- Once the whole map is built (every hill, drift and the clearing of the
-- walkable strip done), each path is measured again and moved, with
-- everything inside its folder (edges, cracks, the snake), to lie
-- PATH_LIFT above the highest ground under it. (Measured while its own
-- world was being built, the ground could still change after.)
World.PathPoints = {} -- folder -> its points
function World.settlePaths()
	for folder, points in pairs(World.PathPoints) do
		local inner = false
		local up = folder.Parent
		while up do
			if World.PathPoints[up] then
				inner = true -- moves with the path it lies on
				break
			end
			up = up.Parent
		end
		if not inner then
			local ground = Config.GROUND_Y
			for _, p in ipairs(points) do
				local y = World.groundAt(p.X, p.Z)
				if y and y < Config.GROUND_Y + 3 then
					ground = math.max(ground, y)
				end
			end
			local delta = ground + World.PATH_LIFT - (folder:GetAttribute("Top") or ground + World.PATH_LIFT)
			if math.abs(delta) > 0.001 then
				for _, d in ipairs(folder:GetDescendants()) do
					if d:IsA("BasePart") then
						d.CFrame += Vector3.new(0, delta, 0)
					end
				end
				folder:SetAttribute("Top", ground + World.PATH_LIFT)
			end
		end
	end
end

-- Lighting and terrain colours ------------------------------------------------------

-- bright, sunny and a little extra colourful, like a toy world
local Lighting = game:GetService("Lighting")
Lighting.ClockTime = 13
Lighting.Brightness = 3
Lighting.Ambient = Color3.fromRGB(120, 120, 140)
Lighting.OutdoorAmbient = Color3.fromRGB(170, 170, 190)
Lighting.EnvironmentDiffuseScale = 0.8
Lighting.EnvironmentSpecularScale = 0.3
Lighting.ShadowSoftness = 0.6
local atmosphere = Instance.new("Atmosphere")
atmosphere.Density = 0.18
atmosphere.Haze = 0.4
atmosphere.Glare = 0
atmosphere.Color = Color3.fromRGB(215, 235, 255)
atmosphere.Decay = Color3.fromRGB(170, 210, 255)
atmosphere.Parent = Lighting
local colour = Instance.new("ColorCorrectionEffect")
colour.Saturation = 0.18
colour.Brightness = 0.03
colour.Contrast = 0.05
colour.Parent = Lighting
local bloom = Instance.new("BloomEffect")
bloom.Intensity = 0.4
bloom.Size = 20
bloom.Threshold = 1.4
bloom.Parent = Lighting

-- terrain in bright, cartoon colours
terrain:SetMaterialColor(Enum.Material.Grass, Color3.fromRGB(110, 210, 80))
terrain:SetMaterialColor(Enum.Material.LeafyGrass, Color3.fromRGB(125, 215, 105))
terrain:SetMaterialColor(Enum.Material.Sand, Color3.fromRGB(255, 220, 140))
terrain:SetMaterialColor(Enum.Material.Snow, Color3.fromRGB(245, 250, 255))
terrain:SetMaterialColor(Enum.Material.Glacier, Color3.fromRGB(150, 220, 255))
terrain:SetMaterialColor(Enum.Material.Ice, Color3.fromRGB(185, 235, 255))
terrain:SetMaterialColor(Enum.Material.Ground, Color3.fromRGB(225, 180, 115)) -- dirt paths
terrain:SetMaterialColor(Enum.Material.Sandstone, Color3.fromRGB(240, 185, 115))
terrain:SetMaterialColor(Enum.Material.Pavement, Color3.fromRGB(220, 220, 230))
terrain:SetMaterialColor(Enum.Material.Basalt, Color3.fromRGB(120, 98, 92)) -- the Lava Arena's warm volcanic rock
terrain:SetMaterialColor(Enum.Material.CrackedLava, Color3.fromRGB(255, 120, 50))

-- Invisible walls ----------------------------------------------------------------------

local walls = Build.folder(map, "InvisibleWalls")
local function invisibleWall(center, size)
	Build.part(walls, {
		Name = "InvisibleWall",
		Size = size,
		CFrame = CFrame.new(center),
		Transparency = 1,
		CastShadow = false,
		CanQuery = false,
	})
end
for _, side in ipairs({ -1, 1 }) do
	invisibleWall(Vector3.new(TOTAL / 2, 60, side * (HALF + 2)), Vector3.new(TOTAL + 8, 140, 4))
end
invisibleWall(Vector3.new(-2, 60, 0), Vector3.new(4, 140, HALF * 2 + 8))
invisibleWall(Vector3.new(TOTAL + 2, 60, 0), Vector3.new(4, 140, HALF * 2 + 8))
-- a lid, so nobody jumps over the walls from a hill or a tall prop
invisibleWall(Vector3.new(TOTAL / 2, 132, 0), Vector3.new(TOTAL + 8, 4, HALF * 2 + 8))

-- Spawn -----------------------------------------------------------------------------

local spawn = Instance.new("SpawnLocation")
spawn.Name = "Spawn"
spawn.Anchored = true
spawn.Size = Vector3.new(9, 1, 9)
spawn.CFrame = CFrame.new(World.SPAWN.X, 0.5, 0) * CFrame.Angles(0, math.rad(-90), 0) -- facing +X
spawn.Material = Enum.Material.SmoothPlastic
spawn.Color = Color3.fromRGB(255, 120, 150)
spawn.Duration = 0
spawn.Neutral = true
spawn.Parent = map
local spawnDecal = spawn:FindFirstChildOfClass("Decal")
if spawnDecal then
	spawnDecal:Destroy()
end

-- Gates between areas ----------------------------------------------------------------

-- One side of a gate's wall: just the price, in big chunky gold numbers with
-- a dark outline, and a gold coin beside it. Drawn with a SurfaceGui so it
-- is crisp up close.
local function gateFace(barrier, face, area, i)
	local dark = area.Color:Lerp(Color3.new(0, 0, 0), 0.55)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "PriceFace"
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 20
	gui.LightInfluence = 0
	gui.MaxDistance = 250
	gui.Parent = barrier

	local function label(props)
		local l = Instance.new("TextLabel")
		l.BackgroundTransparency = 1
		l.Font = Enum.Font.FredokaOne
		l.TextScaled = true
		l.TextColor3 = Color3.new(1, 1, 1)
		l.AnchorPoint = Vector2.new(0.5, 0.5)
		for k, v in pairs(props) do
			l[k] = v
		end
		local stroke = Instance.new("UIStroke")
		stroke.Color = dark
		stroke.Thickness = props.Name == "Price" and 7 or 5
		stroke.LineJoinMode = Enum.LineJoinMode.Round
		stroke.Parent = l
		l.Parent = gui
		return l
	end
	local function round(frame, radius)
		local c = Instance.new("UICorner")
		c.CornerRadius = radius
		c.Parent = frame
	end

	-- the price: a gold coin and the number, big
	local row = Instance.new("Frame")
	row.Name = "PriceRow"
	row.BackgroundTransparency = 1
	row.AnchorPoint = Vector2.new(0.5, 0.5)
	row.Position = UDim2.fromScale(0.5, 0.5)
	row.Size = UDim2.fromScale(0.95, 0.5)
	row.Parent = gui
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0, 16)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = row
	local coin = Instance.new("Frame")
	coin.Name = "Coin"
	coin.LayoutOrder = 1
	coin.BackgroundColor3 = Color3.fromRGB(255, 200, 40)
	coin.Size = UDim2.fromOffset(110, 110)
	round(coin, UDim.new(0.5, 0))
	local rim = Instance.new("UIStroke")
	rim.Color = Color3.fromRGB(200, 120, 10)
	rim.Thickness = 8
	rim.Parent = coin
	local shine = Instance.new("Frame")
	shine.BackgroundColor3 = Color3.fromRGB(255, 240, 160)
	shine.AnchorPoint = Vector2.new(0.5, 0.5)
	shine.Position = UDim2.fromScale(0.5, 0.5)
	shine.Size = UDim2.fromScale(0.5, 0.5)
	round(shine, UDim.new(0.5, 0))
	shine.Parent = coin
	coin.Parent = row
	local cost = Config.AREA_COST_FOR_TESTING or area.Cost
	local price = label({ Name = "Price", Text = Config.formatNumber(cost), AnchorPoint = Vector2.new(0, 0.5), LayoutOrder = 2,
		AutomaticSize = Enum.AutomaticSize.X, TextScaled = false, TextSize = 120, Size = UDim2.fromOffset(0, 124),
		TextColor3 = Color3.fromRGB(255, 226, 90) })
	price.Parent = row

	return gui
end

-- The end of the last world: a friendly wall across the path with a big
-- "See you in the next update!" sign (both pillars like the gates, a
-- smiley, little stars) so players know there's more coming.
local function buildEndWall()
	local last = Config.AREAS[#Config.AREAS]
	local x = TOTAL - 1.5
	local model = Build.model(map, "EndWall")
	local white = Color3.fromRGB(250, 250, 255)
	local g = Config.GROUND_Y
	for _, side in ipairs({ -1, 1 }) do
		Build.block(model, Vector3.new(x, 0, side * (HALF - 2.5)), Vector3.new(5, 22, 5), { Color = white })
		Build.block(model, Vector3.new(x, 22, side * (HALF - 2.5)), Vector3.new(6.5, 2, 6.5), { Color = last.Color })
		Build.ball(model, Vector3.new(x, 25, side * (HALF - 2.5)), 3.4, { Color = Color3.fromRGB(255, 220, 90), Material = Enum.Material.Neon })
	end
	local wall = Build.part(model, {
		Name = "Wall",
		Size = Vector3.new(1.2, 19, HALF * 2 - 10),
		CFrame = CFrame.new(x, g + 9.5, 0),
		Color = Color3.fromRGB(110, 170, 255),
		Material = Enum.Material.SmoothPlastic,
	})
	for _, y in ipairs({ g, g + 19 }) do
		Build.part(model, { Size = Vector3.new(1.8, 1.2, HALF * 2 - 10), CFrame = CFrame.new(x, y, 0), Color = white, CanCollide = false })
	end
	-- the message on the side you come from (-X)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "Message"
	gui.Face = Enum.NormalId.Left
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 20
	gui.LightInfluence = 0
	gui.MaxDistance = 300
	gui.Parent = wall
	local back = Instance.new("Frame")
	back.Size = UDim2.fromScale(1, 1)
	back.BackgroundColor3 = Color3.new(1, 1, 1)
	back.Parent = gui
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 90
	gradient.Color = ColorSequence.new(Color3.fromRGB(140, 200, 255), Color3.fromRGB(200, 150, 255))
	gradient.Parent = back
	local dark = Color3.fromRGB(60, 50, 130)
	local function label(text, y, h, color)
		local l = Instance.new("TextLabel")
		l.BackgroundTransparency = 1
		l.AnchorPoint = Vector2.new(0.5, 0.5)
		l.Position = UDim2.fromScale(0.5, y)
		l.Size = UDim2.fromScale(0.85, h)
		l.Font = Enum.Font.FredokaOne
		l.TextScaled = true
		l.TextColor3 = color
		l.Text = text
		local stroke = Instance.new("UIStroke")
		stroke.Color = dark
		stroke.Thickness = 6
		stroke.LineJoinMode = Enum.LineJoinMode.Round
		stroke.Parent = l
		l.Parent = gui
		return l
	end
	-- a big smiley: a yellow circle with eyes and a smile
	local face = Instance.new("Frame")
	face.AnchorPoint = Vector2.new(0.5, 0.5)
	face.Position = UDim2.fromScale(0.5, 0.24)
	face.Size = UDim2.fromScale(0.3, 0.3)
	face.BackgroundColor3 = Color3.fromRGB(255, 214, 70)
	face.Parent = gui
	local ratio = Instance.new("UIAspectRatioConstraint")
	ratio.AspectRatio = 1
	ratio.Parent = face
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = face
	local rim = Instance.new("UIStroke")
	rim.Color = dark
	rim.Thickness = 8
	rim.Parent = face
	for _, ex in ipairs({ 0.33, 0.67 }) do
		local eye = Instance.new("Frame")
		eye.AnchorPoint = Vector2.new(0.5, 0.5)
		eye.Position = UDim2.fromScale(ex, 0.38)
		eye.Size = UDim2.fromScale(0.12, 0.2)
		eye.BackgroundColor3 = dark
		eye.Parent = face
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0.5, 0)
		c.Parent = eye
	end
	-- the smile: a dark rounded mouth with its top half covered in yellow
	local mouth = Instance.new("Frame")
	mouth.AnchorPoint = Vector2.new(0.5, 0.5)
	mouth.Position = UDim2.fromScale(0.5, 0.64)
	mouth.Size = UDim2.fromScale(0.52, 0.3)
	mouth.BackgroundColor3 = dark
	mouth.Parent = face
	local mc = Instance.new("UICorner")
	mc.CornerRadius = UDim.new(0.5, 0)
	mc.Parent = mouth
	local cover = Instance.new("Frame")
	cover.AnchorPoint = Vector2.new(0.5, 1)
	cover.Position = UDim2.fromScale(0.5, 0.64)
	cover.Size = UDim2.fromScale(0.6, 0.18)
	cover.BorderSizePixel = 0
	cover.BackgroundColor3 = Color3.fromRGB(255, 214, 70)
	cover.ZIndex = 2
	cover.Parent = face
	label("SEE YOU IN THE NEXT UPDATE!", 0.55, 0.17, Color3.new(1, 1, 1))
	label("More worlds and pets are coming soon ⭐", 0.72, 0.09, Color3.fromRGB(255, 240, 160))
	label("Thanks for playing!", 0.86, 0.08, Color3.new(1, 1, 1))
	-- sparkles drifting off the wall
	local sparkles = Instance.new("ParticleEmitter")
	sparkles.Color = ColorSequence.new(Color3.fromRGB(255, 240, 160), Color3.fromRGB(200, 170, 255))
	sparkles.LightEmission = 1
	sparkles.Size = NumberSequence.new(0.4, 0)
	sparkles.Lifetime = NumberRange.new(2, 3)
	sparkles.Rate = 8
	sparkles.Speed = NumberRange.new(1, 2.5)
	sparkles.EmissionDirection = Enum.NormalId.Left
	sparkles.SpreadAngle = Vector2.new(40, 40)
	sparkles.Parent = wall
	World.EndWall = wall
	return model
end

-- the locked wall is see-through: 0.2 opacity
World.GATE_TRANSPARENCY = 0.8

local function buildGate(i)
	local area = Config.AREAS[i]
	local x = Config.areaStart(i)
	local gate = Build.model(map, "Gate" .. i)
	local white = Color3.fromRGB(250, 250, 255)

	for _, side in ipairs({ -1, 1 }) do
		Build.block(gate, Vector3.new(x, 0, side * (HALF - 2.5)), Vector3.new(5, 20, 5), { Color = white })
		Build.block(gate, Vector3.new(x, 20, side * (HALF - 2.5)), Vector3.new(6.5, 2, 6.5), { Color = area.Color })
		Build.ball(gate, Vector3.new(x, 23, side * (HALF - 2.5)), 3.4, { Color = area.Color, Material = Enum.Material.Neon })
	end
	Build.block(gate, Vector3.new(x, 17, 0), Vector3.new(4, 3, HALF * 2 - 4), { Color = white })

	-- the wall itself: see-through coloured glass (0.2 opacity), with white
	-- rails and the price and a coin on both sides
	local barrier = Build.part(gate, {
		Name = "Barrier",
		Size = Vector3.new(1, 15, HALF * 2 - 10),
		CFrame = CFrame.new(x, Config.GROUND_Y + 7.5, 0),
		Color = area.Color,
		Material = Enum.Material.Glass,
		Reflectance = 0.15,
		Transparency = World.GATE_TRANSPARENCY,
		CastShadow = false,
	})
	for _, y in ipairs({ Config.GROUND_Y, Config.GROUND_Y + 15 }) do
		Build.part(barrier, {
			Name = "Rail",
			Size = Vector3.new(1.6, 1.2, HALF * 2 - 10),
			CFrame = CFrame.new(x, y, 0),
			Color = white,
			CanCollide = false,
		})
	end
	-- an invisible wall from the ground up to the lid while it's locked, so
	-- nobody gets over by climbing onto the gate or jumping from a tree
	local blocker = Build.part(gate, {
		Name = "Blocker",
		Size = Vector3.new(2, 140, HALF * 2 + 8),
		CFrame = CFrame.new(x, 60, 0),
		Transparency = 1,
		CastShadow = false,
		CanQuery = false,
	})
	local faces = {}
	for _, face in ipairs({ Enum.NormalId.Left, Enum.NormalId.Right }) do
		table.insert(faces, gateFace(barrier, face, area, i))
	end
	local sign = Build.sign(
		gate,
		CFrame.new(x, 23.5, 0) * CFrame.Angles(0, math.rad(90), 0),
		Vector3.new(34, 6, 0.8),
		area.Name:upper() .. "  ·  " .. Config.areaCostText(i),
		Color3.new(1, 1, 1),
		area.Color:Lerp(Color3.new(0, 0, 0), 0.15)
	)

	-- the button players walk up to (on the side they come from)
	local button = Build.cylinder(gate, Vector3.new(x - 6, 0, 0), 1, 7, {
		Name = "UnlockButton",
		Color = area.Color,
		Material = Enum.Material.Neon,
	})
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Unlock " .. area.Name
	prompt.ObjectText = string.lower(Config.areaCostText(i))
	prompt.HoldDuration = 0.3
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = button

	World.Gates[i] = { Barrier = barrier, Blocker = blocker, Sign = sign, Button = button, Prompt = prompt, Faces = faces }
end

-- Opens (or closes) the gate into area i
function World.setGateOpen(i, open)
	local gate = World.Gates[i]
	if not gate then
		return
	end
	local area = Config.AREAS[i]
	gate.Barrier.CanCollide = not open
	gate.Blocker.CanCollide = not open
	gate.Barrier.Transparency = if open then 1 else World.GATE_TRANSPARENCY
	for _, rail in ipairs(gate.Barrier:GetChildren()) do
		if rail.Name == "Rail" then
			rail.Transparency = if open then 1 else 0
		end
	end
	for _, face in ipairs(gate.Faces) do
		face.Enabled = not open
	end
	gate.Prompt.Enabled = not open
	gate.Button.Transparency = if open then 1 else 0
	Build.setSignText(gate.Sign, if open
		then area.Name:upper()
		else area.Name:upper() .. "  ·  " .. Config.areaCostText(i))
end

-- The Mega Roll pad (Sahara) ----------------------------------------------------------
-- A round pale-blue pad with a glowing ring, a pile of big white dice with
-- navy pips, potion bottles around it and a second little pile of dice
-- beside it. The client hangs the sign over it ("x50,000 Roll!" and the
-- timer) and claims the roll when you step on it once it's ready.

local PIP_PATTERNS = {
	{ { 0, 0 } },
	{ { -1, -1 }, { 1, 1 } },
	{ { -1, -1 }, { 0, 0 }, { 1, 1 } },
	{ { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 } },
	{ { -1, -1 }, { 1, -1 }, { 0, 0 }, { -1, 1 }, { 1, 1 } },
	{ { -1, -1 }, { 1, -1 }, { -1, 0 }, { 1, 0 }, { -1, 1 }, { 1, 1 } },
}
local DIE_WHITE = Color3.fromRGB(236, 243, 255)
local PIP_NAVY = Color3.fromRGB(22, 34, 92)

-- one die of `size` studs at `cf` (its centre), pips on every side
local function die(parent, cf, size)
	local model = Build.model(parent, "Die")
	Build.part(model, { Size = Vector3.new(size, size, size), CFrame = cf, Color = DIE_WHITE })
	local half, spread, pip = size / 2, size * 0.26, size * 0.2
	-- each face: where its centre is and how a pip (a flat cylinder along X) turns to lie on it
	local faces = {
		{ N = 1, At = function(a, b) return CFrame.new(0, half, 0) * CFrame.new(a, 0, b) * CFrame.Angles(0, 0, math.rad(90)) end },
		{ N = 6, At = function(a, b) return CFrame.new(0, -half, 0) * CFrame.new(a, 0, b) * CFrame.Angles(0, 0, math.rad(90)) end },
		{ N = 2, At = function(a, b) return CFrame.new(half, 0, 0) * CFrame.new(0, a, b) end },
		{ N = 5, At = function(a, b) return CFrame.new(-half, 0, 0) * CFrame.new(0, a, b) end },
		{ N = 3, At = function(a, b) return CFrame.new(0, 0, half) * CFrame.new(a, b, 0) * CFrame.Angles(0, math.rad(90), 0) end },
		{ N = 4, At = function(a, b) return CFrame.new(0, 0, -half) * CFrame.new(a, b, 0) * CFrame.Angles(0, math.rad(90), 0) end },
	}
	for _, face in ipairs(faces) do
		for _, p in ipairs(PIP_PATTERNS[face.N]) do
			Build.part(model, {
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(0.12, pip, pip),
				CFrame = cf * face.At(p[1] * spread, p[2] * spread),
				Color = PIP_NAVY,
				CanCollide = false,
				CastShadow = false,
			})
		end
	end
	return model
end

-- a little potion bottle standing at `base`
local function potion(parent, base, liquid, tilt)
	local model = Build.model(parent, "Potion")
	local cf = CFrame.new(base) * CFrame.Angles(0, tilt, math.rad(8) * math.sin(tilt * 3))
	local up = CFrame.Angles(0, 0, math.rad(90))
	Build.part(model, { Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.6, 1.3, 1.3), CFrame = cf * CFrame.new(0, 0.8, 0) * up,
		Color = Color3.fromRGB(220, 240, 255), Material = Enum.Material.Glass, Transparency = 0.45, CanCollide = false })
	Build.part(model, { Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.1, 1.1, 1.1), CFrame = cf * CFrame.new(0, 0.6, 0) * up,
		Color = liquid, Material = Enum.Material.Neon, CanCollide = false })
	Build.part(model, { Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.6, 0.55, 0.55), CFrame = cf * CFrame.new(0, 1.85, 0) * up,
		Color = Color3.fromRGB(220, 240, 255), Material = Enum.Material.Glass, Transparency = 0.45, CanCollide = false })
	Build.part(model, { Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.45, 0.6, 0.6), CFrame = cf * CFrame.new(0, 2.3, 0) * up,
		Color = Color3.fromRGB(176, 120, 70), CanCollide = false })
end

function World.buildMegaRoll(center)
	local model = Build.model(map, "MegaRoll")
	local r = Config.MEGA_ROLL.Radius
	-- stand on the real ground (the sand isn't exactly at Y = 0)
	center = Vector3.new(center.X, math.max(World.groundAt(center.X, center.Z) or 0, Config.GROUND_Y) - 0.3, center.Z)
	-- the pad: a white rim, the pale blue top and a glowing ring on it
	Build.cylinder(model, center, 1, r * 2 + 1.2, { Name = "Rim", Color = Color3.fromRGB(250, 252, 255) })
	local pad = Build.cylinder(model, center, 1.3, r * 2, { Name = "Pad", Color = Color3.fromRGB(184, 210, 255) })
	Build.cylinder(model, center + Vector3.new(0, 1.3, 0), 0.06, r * 2 - 2.5, { Name = "Ring", Color = Color3.fromRGB(255, 236, 150), Material = Enum.Material.Neon, CanCollide = false })
	Build.cylinder(model, center + Vector3.new(0, 1.32, 0), 0.06, r * 2 - 3.3, { Color = Color3.fromRGB(184, 210, 255), CanCollide = false })
	local top = center.Y + 1.3
	-- the big pile at the back of the pad: three dice and one on top
	local back = center + Vector3.new(2.5, top - center.Y, -3)
	local s = 3.4
	die(model, CFrame.new(back + Vector3.new(-s * 0.55, s / 2, 0)) * CFrame.Angles(0, math.rad(12), 0), s)
	die(model, CFrame.new(back + Vector3.new(s * 0.55, s / 2, 0.3)) * CFrame.Angles(0, math.rad(-20), 0), s)
	die(model, CFrame.new(back + Vector3.new(0, s / 2, -s * 0.9)) * CFrame.Angles(0, math.rad(35), 0), s)
	die(model, CFrame.new(back + Vector3.new(0, s * 1.5, -0.3)) * CFrame.Angles(0, math.rad(-8), 0), s)
	-- potions around it
	local colours = { Color3.fromRGB(80, 220, 120), Color3.fromRGB(255, 90, 120), Color3.fromRGB(255, 220, 60), Color3.fromRGB(80, 120, 255), Color3.fromRGB(255, 140, 60) }
	for k, at in ipairs({ { -3.5, 0.5 }, { -2.6, 2.2 }, { 4.6, 1.6 }, { 5.6, -0.4 }, { 3.4, 2.6 } }) do
		potion(model, Vector3.new(back.X + at[1], top, back.Z + at[2]), colours[k], k * 1.3)
	end
	-- a small pile beside the pad
	local side = center + Vector3.new(-r - 3.5, 0, -1)
	local t = 2.6
	die(model, CFrame.new(side + Vector3.new(-t * 0.55, t / 2, 0)) * CFrame.Angles(0, math.rad(25), 0), t)
	die(model, CFrame.new(side + Vector3.new(t * 0.55, t / 2, 0.4)) * CFrame.Angles(0, math.rad(-10), 0), t)
	die(model, CFrame.new(side + Vector3.new(0, t * 1.5, 0.2)) * CFrame.Angles(0, math.rad(40), 0), t)
	-- where the sign hangs (the client puts the text there)
	Build.part(model, { Name = "Sign", Size = Vector3.new(1, 1, 1), CFrame = CFrame.new(back + Vector3.new(0, s * 2 + 4.5, 0)), Transparency = 1, CanCollide = false, CastShadow = false })
	-- soft sparkles rising from the pad
	local sparkles = Instance.new("ParticleEmitter")
	sparkles.Color = ColorSequence.new(Color3.fromRGB(255, 246, 190))
	sparkles.LightEmission = 1
	sparkles.Size = NumberSequence.new(0.35, 0)
	sparkles.Lifetime = NumberRange.new(1.5, 2.5)
	sparkles.Rate = 6
	sparkles.Speed = NumberRange.new(1.5, 3)
	sparkles.SpreadAngle = Vector2.new(25, 25)
	sparkles.EmissionDirection = Enum.NormalId.Top
	sparkles.Parent = pad
	World.MegaPad = Vector3.new(center.X, top, center.Z)
	return model
end

-- Rebirth perk pads ---------------------------------------------------------------------
-- One in each world (Config.PERKS): a round pedestal in the perk's colour
-- (gold coins, green luck, red damage, purple EXP) with a glowing ring, a
-- glowing bubble floating over it and a friendly white sign that always
-- faces you: a big icon, the perk's name, what it gives in a coloured pill
-- and, at the bottom, the status the client fills in ("Need 2 rebirths"
-- with a lock and a 0/2 bar, or a green "Owned"). Nothing is spent: it's
-- yours as soon as you have the rebirths.
local PERK_ICONS = { Coins = "💰", Luck = "🍀", Damage = "⚔️", Exp = "⭐" }
World.PERK_COLORS = {
	Coins = Color3.fromRGB(255, 186, 40),
	Luck = Color3.fromRGB(56, 196, 110),
	Damage = Color3.fromRGB(240, 84, 96),
	Exp = Color3.fromRGB(150, 100, 255),
}

function World.buildPerkPad(index, perk)
	local folder = map:FindFirstChild("Perks") or Build.folder(map, "Perks")
	local model = Build.model(folder, "PerkPad" .. index)
	model:SetAttribute("PerkIndex", index)
	local color = World.PERK_COLORS[perk.Stat] or Color3.fromRGB(255, 186, 40)
	local light = color:Lerp(Color3.new(1, 1, 1), 0.45)
	local x0 = Config.areaStart(perk.Area)
	local at = Vector3.new(x0 + perk.At[1], Config.GROUND_Y, perk.At[2])
	-- the pedestal: white base, a step in the perk's colour, a glowing ring, a soft top
	local function disc(y, height, diameter, props)
		local part = Build.part(model, props)
		part.Shape = Enum.PartType.Cylinder
		part.Size = Vector3.new(height, diameter, diameter)
		part.CFrame = CFrame.new(at + Vector3.new(0, y + height / 2, 0)) * CFrame.Angles(0, 0, math.rad(90))
		return part
	end
	local base = disc(-0.2, 0.6, 10, { Name = "Base", Color = Color3.fromRGB(250, 251, 255) })
	disc(0.4, 0.45, 8.6, { Color = color })
	disc(0.85, 0.08, 7.4, { Color = light, Material = Enum.Material.Neon, CanCollide = false })
	disc(0.87, 0.08, 6.6, { Color = Color3.fromRGB(255, 255, 255), CanCollide = false })
	local top = at + Vector3.new(0, 0.95, 0)

	-- the bubble: a glowing core in a glassy shell, bobbing over the pad
	local core = Build.part(model, {
		Name = "Orb",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(1.7, 1.7, 1.7),
		CFrame = CFrame.new(top + Vector3.new(0, 3.2, 0)),
		Color = light,
		Material = Enum.Material.Neon,
		CanCollide = false,
	})
	local shell = Build.part(model, {
		Name = "Shell",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(2.7, 2.7, 2.7),
		CFrame = core.CFrame,
		Color = color,
		Material = Enum.Material.Glass,
		Transparency = 0.55,
		CanCollide = false,
	})
	for _, part in ipairs({ core, shell }) do
		Build.bob(part, 0.4, 0.8)
	end
	local glow = Instance.new("PointLight")
	glow.Color = light
	glow.Range = 12
	glow.Brightness = 1
	glow.Parent = core
	local sparkles = Instance.new("ParticleEmitter")
	sparkles.Color = ColorSequence.new(light)
	sparkles.LightEmission = 1
	sparkles.Size = NumberSequence.new(0.3, 0)
	sparkles.Lifetime = NumberRange.new(1, 1.8)
	sparkles.Rate = 5
	sparkles.Speed = NumberRange.new(1, 2)
	sparkles.SpreadAngle = Vector2.new(180, 180)
	sparkles.Parent = core

	-- the sign: a white card over the bubble, always facing you
	local gui = Instance.new("BillboardGui")
	gui.Name = "Status"
	gui.Size = UDim2.fromScale(7.6, 4.4)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 4.6, 0)
	gui.MaxDistance = 70
	gui.LightInfluence = 0
	gui.Adornee = core
	gui.Parent = model
	local function new(class, props, parent)
		local o = Instance.new(class)
		for k, v in pairs(props) do
			o[k] = v
		end
		o.Parent = parent or gui
		return o
	end
	local function round(o, r)
		new("UICorner", { CornerRadius = UDim.new(r, 0) }, o)
		return o
	end
	local dark = Color3.fromRGB(46, 50, 80)
	local card = round(new("Frame", { Name = "Card", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1) }), 0.16)
	new("UIStroke", { Color = color, Thickness = 3 }, card)
	-- the icon in a coloured circle
	local iconBack = round(new("Frame", { Name = "IconBack", Position = UDim2.fromScale(0.05, 0.08), Size = UDim2.fromScale(0.27, 0.47), BackgroundColor3 = light, ZIndex = 2 }), 0.5)
	new("UIAspectRatioConstraint", { AspectRatio = 1 }, iconBack)
	new("TextLabel", { Name = "Icon", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Text = PERK_ICONS[perk.Stat] or "✨", TextScaled = true, Font = Enum.Font.FredokaOne, ZIndex = 3 }, iconBack)
	-- name and what it gives
	new("TextLabel", {
		Name = "PerkName",
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.36, 0.08),
		Size = UDim2.fromScale(0.6, 0.24),
		Text = perk.Name,
		TextColor3 = dark,
		TextScaled = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = Enum.Font.FredokaOne,
		ZIndex = 2,
	})
	local gives = round(new("Frame", { Name = "Gives", Position = UDim2.fromScale(0.36, 0.35), Size = UDim2.fromScale(0.44, 0.2), BackgroundColor3 = color, ZIndex = 2 }), 0.5)
	new("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.08, 0.1),
		Size = UDim2.fromScale(0.84, 0.8),
		Text = Config.perkText(perk),
		TextColor3 = Color3.new(1, 1, 1),
		TextScaled = true,
		Font = Enum.Font.FredokaOne,
		ZIndex = 3,
	}, gives)
	-- the status pill and the rebirths bar (the client fills them in)
	round(new("Frame", { Name = "Pill", Position = UDim2.fromScale(0.05, 0.62), Size = UDim2.fromScale(0.9, 0.2), BackgroundColor3 = Color3.fromRGB(236, 239, 247), ZIndex = 2 }), 0.5)
	new("TextLabel", {
		Name = "Text",
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.1, 0.64),
		Size = UDim2.fromScale(0.8, 0.16),
		Text = "🔒 Need " .. perk.Rebirths .. (if perk.Rebirths == 1 then " rebirth" else " rebirths"),
		TextColor3 = dark,
		TextScaled = true,
		Font = Enum.Font.FredokaOne,
		ZIndex = 3,
	})
	local bar = round(new("Frame", { Name = "Bar", Position = UDim2.fromScale(0.12, 0.86), Size = UDim2.fromScale(0.76, 0.07), BackgroundColor3 = Color3.fromRGB(226, 230, 240), ZIndex = 2 }), 0.5)
	round(new("Frame", { Name = "Fill", Size = UDim2.fromScale(0, 1), BackgroundColor3 = color, ZIndex = 3 }, bar), 0.5)
	base:SetAttribute("PerkColor", color)
	return model
end

-- The Upgrade Board --------------------------------------------------------------------
-- A big stand like an incremental game's upgrade wall: a white frame with
-- a green cap and an "UPGRADES" sign, clovers on top and a screen part the
-- client draws every upgrade on (sections on the left, rows with BUY
-- buttons you click right there). It replaced the upgrade tree screen.
local GREEN = Color3.fromRGB(46, 196, 120)
function World.buildUpgradeBoard(center)
	local model = Build.model(map, "UpgradeBoard")
	local facing = CFrame.lookAt(center, Vector3.new(center.X, center.Y, 0))
	local WIDTH, HEIGHT = 20, 15
	local white = Color3.fromRGB(250, 250, 255)
	-- a raised stage to stand it on (tall enough to show above the grass)
	local STAGE = 2.4
	local lift = STAGE - 1.2 -- (the frame below was laid out for a 1.2 stage)
	Build.part(model, { Name = "Stage", Size = Vector3.new(WIDTH + 4, STAGE - 0.3, 7), CFrame = facing * CFrame.new(0, (STAGE - 0.3) / 2, 0), Color = white })
	Build.part(model, { Size = Vector3.new(WIDTH + 4.2, 0.3, 7.2), CFrame = facing * CFrame.new(0, STAGE - 0.15, 0), Color = GREEN })
	-- wide stairs up to it from the path side (each step 0.6 high, green
	-- edges), and a green carpet from the path to the bottom step
	for k = 1, 3 do
		local top = STAGE - k * 0.6
		local z = -3.5 - (k - 0.5) * 1.2
		Build.part(model, { Name = "Stair" .. k, Size = Vector3.new(WIDTH + 2, top, 1.2), CFrame = facing * CFrame.new(0, top / 2, z), Color = white })
		Build.part(model, { Size = Vector3.new(WIDTH + 2.1, 0.1, 0.3), CFrame = facing * CFrame.new(0, top + 0.05, z - 0.45), Color = GREEN })
	end
	Build.part(model, { Name = "Carpet", Size = Vector3.new(6, 0.12, 10), CFrame = facing * CFrame.new(0, 0.06, -12.1), Color = GREEN, Material = Enum.Material.Fabric })
	-- the frame, the cap, the posts
	Build.part(model, { Size = Vector3.new(WIDTH + 1, HEIGHT + 1, 0.8), CFrame = facing * CFrame.new(0, lift + 1.2 + (HEIGHT + 1) / 2, 0.2), Color = white })
	Build.part(model, { Size = Vector3.new(WIDTH + 1.4, 1.2, 1.2), CFrame = facing * CFrame.new(0, lift + 1.8 + HEIGHT + 0.6, 0.2), Color = GREEN })
	for _, x in ipairs({ -WIDTH / 2 - 1, WIDTH / 2 + 1 }) do
		Build.part(model, { Size = Vector3.new(0.8, HEIGHT + 5 + lift, 0.8), CFrame = facing * CFrame.new(x, (HEIGHT + 5 + lift) / 2 + 1, 0.2), Color = white })
		Build.ball(model, (facing * CFrame.new(x, lift + HEIGHT + 6.2, 0.2)).Position, 1.3, { Color = GREEN, Material = Enum.Material.Neon })
	end
	Build.sign(model, facing * CFrame.new(0, lift + HEIGHT + 4.2, 0.2), Vector3.new(14, 2.8, 0.6), "UPGRADES", Color3.new(1, 1, 1), GREEN)
	-- three big clovers on top
	for k = -1, 1 do
		local at = facing * CFrame.new(k * 6.5, lift + HEIGHT + 7.2, 0.2)
		for _, o in ipairs({ { -0.5, 0.5 }, { 0.5, 0.5 }, { -0.5, -0.5 }, { 0.5, -0.5 } }) do
			Build.ball(model, (at * CFrame.new(o[1], o[2], 0)).Position, 1.1, { Color = GREEN })
		end
	end
	local screen = Build.part(model, {
		Name = "Screen",
		Size = Vector3.new(WIDTH, HEIGHT, 0.2),
		CFrame = facing * CFrame.new(0, lift + 1.8 + HEIGHT / 2, -0.3),
		Color = Color3.fromRGB(255, 255, 255),
	})
	return screen
end

-- Areas -------------------------------------------------------------------------------

for i, area in ipairs(Config.AREAS) do
	local module = require(AREA_MODULES[i])
	local x0 = Config.areaStart(i)
	local folder = Build.folder(map, "Area" .. i .. "_" .. area.Name:gsub(" ", ""))
	local rng = Random.new(1000 + i) -- same layout every time
	local space = Build.space()

	-- ground: the playable strip and the scenery on both sides
	terrain:FillBlock(CFrame.new(x0 + LENGTH / 2, -6, 0), Vector3.new(LENGTH, 12, SIDE * 2), module.GROUND)

	-- keep the gate paths and the spawn clear (a character that spawns inside
	-- something gets pushed up on top of it)
	space:add(Vector3.new(x0, 0, 0), 9)
	space:add(Vector3.new(x0 + LENGTH, 0, 0), 9)
	space:add(Vector3.new(x0 + 10, 0, 0), 9)

	-- spots for this area's breakables, away from the decorations. Areas call
	-- ctx.reserveSpots() after their big props and before the small ones, so
	-- flowers and rocks never crowd the play space out.
	local spots = {}
	local function reserveSpots()
		if #spots > 0 then
			return
		end
		for _ = 1, 90 do
			local p = space:find(rng, x0 + 7, x0 + LENGTH - 7, -HALF + 6, HALF - 6, 3.5)
			if p then
				table.insert(spots, p)
			end
			if #spots >= 24 then
				break
			end
		end
	end

	-- this world's rebirth perk pad (kept clear of props)
	for k, perk in ipairs(Config.PERKS) do
		if perk.Area == i then
			space:add(Vector3.new(x0 + perk.At[1], 0, perk.At[2]), 6.5)
			World.buildPerkPad(k, perk)
		end
	end

	-- the Upgrade Board stands in the first area, on the right of the path
	-- near the spawn (the leaderboards are on the left), facing the middle
	if i == 1 then
		local center = Vector3.new(x0 + 22, Config.GROUND_Y, HALF - 9) -- (back from the edge, on the real ground)
		World.UpgradeBoard = World.buildUpgradeBoard(center)
		for dx = -12, 12, 6 do
			space:add(center + Vector3.new(dx, 0, 0), 5.5)
			-- and the stairs and the carpet in front, kept clear
			space:add(center + Vector3.new(dx, 0, -7), 4.5)
		end
		space:add(center + Vector3.new(0, 0, -13), 5)
	end

	-- the Mega Roll pad stands in the Sahara, on the open sand just past the
	-- gate (the -Z side, across from the Pet Aura Machine)
	if i == 2 then
		local megaAt = Vector3.new(x0 + 17, 0, -(HALF - 13))
		World.buildMegaRoll(megaAt)
		space:add(megaAt, Config.MEGA_ROLL.Radius + 2)
		space:add(megaAt + Vector3.new(-Config.MEGA_ROLL.Radius - 3.5, 0, -1), 3.5)
	end

	local ctx = {
		reserveSpots = reserveSpots,
		Folder = folder,
		X0 = x0,
		X1 = x0 + LENGTH,
		Half = HALF,
		Side = SIDE,
		Rng = rng,
		Space = space,
		Terrain = terrain,
		World = World,
	}
	module.build(ctx)

	reserveSpots() -- in case the area didn't
	World.Areas[i] = { Folder = folder, Spots = spots, Module = module, Space = space, BossSpot = ctx.BossSpot }

	if i >= 2 then
		buildGate(i)
	end
	if i == #Config.AREAS then
		buildEndWall()
	end
end

-- The playable strip is flat ground at Y = 0: clear any terrain that ended up
-- above it (the edges of hills, drifts and banks), so nothing can bury a
-- living coin or push the player up when they spawn. New areas get this for free.
terrain:FillBlock(CFrame.new(TOTAL / 2, 30, 0), Vector3.new(TOTAL + 8, 60, HALF * 2), Enum.Material.Air)
-- (and now the ground is final: lift the paths onto it)
World.settlePaths()

-- Breakable spots were picked before the small props and some terrain; keep
-- only the ones on flat ground and set them to its real height
-- only the ones on flat ground and set them to its real height. If too few
-- pass (terrain can come out slightly bumpy), the rest are kept on whatever
-- ground is there, so every area always has enough spots for its targets.
for i, area in ipairs(World.Areas) do
	local valid, rest, total = {}, {}, #area.Spots
	for _, spot in ipairs(area.Spots) do
		if World.flatGround(spot.X, spot.Z, 2.5) then
			table.insert(valid, Vector3.new(spot.X, World.groundAt(spot.X, spot.Z), spot.Z))
		else
			table.insert(rest, Vector3.new(spot.X, World.groundAt(spot.X, spot.Z) or 0, spot.Z))
		end
	end
	local MIN_SPOTS = 12
	for _, spot in ipairs(rest) do
		if #valid >= MIN_SPOTS then
			break
		end
		table.insert(valid, spot)
	end
	-- last resort: a line of spots down the middle of the area
	local x0 = Config.areaStart(i)
	for k = 1, MIN_SPOTS - #valid do
		local x, z = x0 + 12 + (k - 1) * 7, (if k % 2 == 0 then 8 else -8)
		table.insert(valid, Vector3.new(x, World.groundAt(x, z) or 0, z))
	end
	if #rest > 0 then
		warn(string.format("[World] %s: %d of %d target spots were on uneven ground", Config.AREAS[i].Name, #rest, total))
	end
	area.Spots = valid
end

-- a spawn point on the ground at the start of every area
for i = 1, #Config.AREAS do
	local x = Config.areaStart(i) + 10
	local y = World.groundAt(x, 0) or 0
	World.Spawns[i] = CFrame.new(x, y + 3, 0) * CFrame.Angles(0, math.rad(-90), 0)
end
-- the spawn pad sits on the measured ground
spawn.CFrame = CFrame.new(World.SPAWN.X, (World.groundAt(World.SPAWN.X, 0) or 0) + 0.5, 0) * CFrame.Angles(0, math.rad(-90), 0)

-- the far end: a wall of hills so the map doesn't just stop
-- (they start behind the end walls, so they never reach into the playable strip)
terrain:FillBlock(CFrame.new(TOTAL + 32, 6, 0), Vector3.new(48, 24, SIDE * 2), Enum.Material.LeafyGrass)
terrain:FillBlock(CFrame.new(-32, 6, 0), Vector3.new(48, 24, SIDE * 2), Enum.Material.Grass)

-- Landing on the spawn pad -----------------------------------------------------------
-- When something stands on the pad (another player, a pet, an enemy),
-- Roblox lifts a new character above it, sometimes all the way onto the
-- invisible lid over the map. So every new character is put on the pad
-- itself, and anyone who ends up above the play space (on the lid or
-- falling off) is brought back to the pad.
local Players = game:GetService("Players")
local LID_Y = 110 -- above every hill and prop, below the lid (Y 132)

local function placeOnPad(character)
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local lift = (if humanoid then humanoid.HipHeight else 2) + root.Size.Y / 2 + 0.5
	character:PivotTo(CFrame.new(spawn.Position + Vector3.new(0, spawn.Size.Y / 2 + lift, 0)) * spawn.CFrame.Rotation)
	root.AssemblyLinearVelocity = Vector3.zero
end
World.placeOnPad = placeOnPad

local function watch(player)
	player.CharacterAdded:Connect(function(character)
		-- wait for the body to be assembled, then set it on the pad
		for _ = 1, 50 do
			if character:FindFirstChild("HumanoidRootPart") then
				break
			end
			task.wait(0.1)
		end
		task.wait()
		if character.Parent then
			placeOnPad(character)
		end
	end)
end
Players.PlayerAdded:Connect(watch)
for _, player in ipairs(Players:GetPlayers()) do
	watch(player)
end
task.spawn(function()
	while true do
		task.wait(1)
		for _, player in ipairs(Players:GetPlayers()) do
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if root and (root.Position.Y > LID_Y or root.Position.Y < -40) then
				placeOnPad(character)
			end
		end
	end
end)

return World
