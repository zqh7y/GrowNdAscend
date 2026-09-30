-- Ambient life: the little things that make each world feel alive. Birds
-- fly across the sky and land on treetops, butterflies and bees drift
-- between flowers, small wild animals wander and cross the paths, leaves and
-- petals fall, bamboo and flowers sway in the wind, snow falls and ice
-- cracks, sand blows across the desert, fireflies glow in the jungle, and
-- now and then someone walks past or stops at the fountain.
--
-- Everything is client-side and made to stay light:
--   * only the world the player is in is alive (the others are empty)
--   * every kind of thing has a small cap (see WORLDS), plus MAX_ANIMALS overall
--   * things appear out of view (behind the camera or far away) and are
--     removed once they're far away or the player has moved to another world
--   * far animals are animated less often; swaying only happens close by
--   * the world takes breaks: lively stretches alternate with calm ones in
--     which there's much less going on, so it never gets noisy
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local Config = require(ReplicatedStorage.Shared.Config)
local Creature = require(script.Parent.Creature)
local PetModels = require(script.Parent.PetModels)
local State = require(script.Parent.State)

local Ambient = {}

local player = Players.LocalPlayer
local random = Random.new()

-- The worlds ---------------------------------------------------------------------------------

local LEAF_COLORS = { Color3.fromRGB(120, 200, 80), Color3.fromRGB(160, 215, 90), Color3.fromRGB(240, 180, 70), Color3.fromRGB(230, 120, 60) }
local PETAL_COLORS = { Color3.fromRGB(255, 190, 215), Color3.fromRGB(255, 165, 200), Color3.fromRGB(255, 225, 235) }
local WING_COLORS = { Color3.fromRGB(255, 170, 60), Color3.fromRGB(120, 190, 255), Color3.fromRGB(255, 240, 120), Color3.fromRGB(240, 130, 220), Color3.fromRGB(255, 255, 255) }

Ambient.WORLDS = {
	{ -- Forest: birds between the trees, butterflies and bees on the flowers,
		-- bunnies and squirrels, falling leaves, flowers in the breeze
		Birds = { "Parrot", "Owl", "Chick" }, BirdCap = 3, FlyBy = 0.45,
		Perches = { "Oak", "Birch", "FruitTree", "Poplar" },
		Critters = { "Bunny", "Squirrel", "Hedgehog", "Mouse", "Duck", "Frog" }, CritterCap = 3,
		Butterflies = 4, Bees = 2, Flowers = { "FlowerPatch" },
		Falling = { Colors = LEAF_COLORS, Size = Vector3.new(0.5, 0.05, 0.35), Cap = 8 },
		Sway = { "FlowerPatch", "Bush" },
		Chirps = true, NpcSpot = "Fountain",
		Light = { Tint = Color3.fromRGB(255, 252, 242), Air = Color3.fromRGB(215, 235, 255), Density = 0.18, Haze = 0.4, Clock = 13 },
	},
	{ -- Sahara: birds circling far above and landing on palms, meerkats and
		-- lizards, sand blowing in the wind
		Birds = { "Vulture", "Falcon" }, BirdCap = 2, FlyBy = 0.2, Circle = true,
		Perches = { "Palm" },
		Critters = { "Meerkat", "Lizard", "Fennec Fox", "Scorpion", "Tortoise" }, CritterCap = 3,
		Sand = true, Wind = true,
		Light = { Tint = Color3.fromRGB(255, 242, 220), Air = Color3.fromRGB(255, 228, 190), Density = 0.24, Haze = 1.2, Clock = 13.5 },
	},
	{ -- Frozen Peaks: penguins and seals on the frozen sea, birds over the
		-- ice, arctic hares and foxes, snow, wind and cracking ice
		Birds = { "Snowy Owl" }, BirdCap = 2, FlyBy = 1, SeaBirds = true,
		Critters = { "Snow Hare", "Arctic Fox", "Penguin" }, CritterCap = 2,
		SeaCritters = { "Penguin", "Penguin", "Seal", "Walrus" }, SeaCap = 3,
		Snow = true, Wind = true, IceCracks = true,
		Light = { Tint = Color3.fromRGB(236, 246, 255), Air = Color3.fromRGB(225, 240, 255), Density = 0.3, Haze = 1, Clock = 12.5 },
	},
	{ -- Sakura Jungle (the most alive): birds between the sakura trees,
		-- butterflies, fireflies, red pandas and tanukis crossing the paths,
		-- bamboo swaying, petals and leaves falling
		Birds = { "Crane", "Parrot", "Chick" }, BirdCap = 4, FlyBy = 0.35,
		Perches = { "SakuraTree", "WeepingCherry", "Maple" },
		Critters = { "Red Panda", "Tanuki", "Bunny", "Squirrel", "Frog", "Duck" }, CritterCap = 4, Crossing = true,
		Butterflies = 6, Bees = 0, Flowers = { "FloweringBush", "Fern" },
		Falling = { Colors = PETAL_COLORS, Size = Vector3.new(0.4, 0.05, 0.4), Cap = 14, Leaves = true },
		Fireflies = true,
		Sway = { "Bamboo", "FloweringBush", "Fern" },
		Chirps = true,
		Light = { Tint = Color3.fromRGB(255, 244, 248), Air = Color3.fromRGB(255, 225, 238), Density = 0.2, Haze = 0.8, Clock = 15.5 },
	},
}

local MAX_ANIMALS = 12 -- birds + critters + people alive at once, in every world
local NPC_CAP = 1
local SWAY_RANGE = 45
local SWAY_CAP = 24
local DESPAWN_RANGE = 95

-- Sounds (built-in Roblox sounds, so nothing needs uploading; swap any id for
-- a Creator Store sound to change it). LOOPS are optional background beds for
-- each world: put a Creator Store ambience id there ("rbxassetid://...") and
-- it plays quietly while you're in that world.
Ambient.SOUNDS = {
	Chirp = "rbxasset://sounds/electronicpingshort.wav",
	Crack = "rbxasset://sounds/snap.mp3",
	Wind = "rbxasset://sounds/swoosh.wav",
}
Ambient.LOOPS = { "", "", "", "" }

-- State ----------------------------------------------------------------------------------------

local folder = Instance.new("Folder")
folder.Name = "Ambient"
folder.Parent = workspace

local current = 0 -- the world the player is in (0 until known)
local entities = {} -- every living thing: { Kind, Area, Creature?, Update, Remove, Position() }
local fallers = {} -- falling leaves and petals
local swayers = {} -- [area] = { { Model, Base, Bottom, Phase, Amount, Moved } }
local perches = {} -- [area] = { { Position, Taken } }
local flowers = {} -- [area] = { Vector3 }
local seaParts = {} -- the frozen sea's pieces (for ice cracks)
local scanned = {} -- [area] = os.clock() of the last scan
local activity = 1 -- 1 lively, lower in the calm stretches
local calmUntil, lively = 0, 0
local gust = 0 -- the wind, 0..1

-- for the simulator: the most animals alive at once, and how often things happened
Ambient.Stats = { Peak = 0, Swaying = 0, Landings = 0, Cracks = 0, Chirps = 0, Kinds = {} }

local function root()
	return player.Character and player.Character:FindFirstChild("HumanoidRootPart")
end

local function areaAt(x)
	for i = #Config.AREAS, 1, -1 do
		if x >= Config.areaStart(i) then
			return i
		end
	end
	return 1
end

local function areaFolder(i)
	local map = workspace:FindFirstChild("Map")
	return map and map:FindFirstChild("Area" .. i .. "_" .. (Config.AREAS[i].Name:gsub(" ", "")))
end

-- Not on screen: behind the camera, or far away
local function hidden(position)
	local camera = workspace.CurrentCamera
	local r = root()
	if r and (position - r.Position).Magnitude > 70 then
		return true
	end
	if not camera then
		return true
	end
	local toPoint = position - camera.CFrame.Position
	return camera.CFrame.LookVector:Dot(toPoint.Unit) < 0.1
end

local function count(kind)
	local n = 0
	for _, e in ipairs(entities) do
		if kind == nil or e.Kind == kind then
			n += 1
		end
	end
	return n
end

local function animals()
	local n = 0
	for _, e in ipairs(entities) do
		if e.Creature then
			n += 1
		end
	end
	return n
end

-- A point on the ground in world `area`, `near` a position, between min and
-- max studs away, preferably out of view
local function groundPoint(area, near, minDistance, maxDistance)
	local x0 = Config.areaStart(area)
	local best
	for try = 1, 8 do
		local a = random:NextNumber(0, math.pi * 2)
		local d = random:NextNumber(minDistance, maxDistance)
		local x = math.clamp(near.X + math.cos(a) * d, x0 + 6, x0 + Config.AREA_LENGTH - 6)
		local z = math.clamp(near.Z + math.sin(a) * d, -Config.AREA_HALF_WIDTH + 4, Config.AREA_HALF_WIDTH - 4)
		local y = Creature.ground(x, z, near.Y + 10)
		if y then
			best = Vector3.new(x, y, z)
			if hidden(best) or try == 8 then
				return best
			end
		end
	end
	return best
end

-- Sounds -----------------------------------------------------------------------------------------

local function sound(name, at, pitch, volume)
	if not State.Settings.Sounds then
		return
	end
	local holder = Instance.new("Attachment")
	holder.Position = at
	holder.Parent = workspace.Terrain
	local s = Instance.new("Sound")
	s.SoundId = Ambient.SOUNDS[name]
	s.PlaybackSpeed = pitch
	s.Volume = volume
	s.RollOffMaxDistance = 90
	s.RollOffMinDistance = 8
	s.Parent = holder
	s:Play()
	task.delay(2.5, function()
		holder:Destroy()
	end)
end

-- a little bird call: two or three quick high notes
local function chirp(at)
	Ambient.Stats.Chirps += 1
	local notes = random:NextInteger(2, 3)
	local base = random:NextNumber(2.6, 3.4)
	for k = 0, notes - 1 do
		task.delay(k * random:NextNumber(0.09, 0.14), sound, "Chirp", at, base + (if k % 2 == 0 then 0 else 0.35), 0.1)
	end
end

local loop = Instance.new("Sound")
loop.Name = "AmbientLoop"
loop.Looped = true
loop.Volume = 0.25
loop.Parent = SoundService

-- Scanning the map ---------------------------------------------------------------------------------

-- Finds the treetops, flowers, swaying plants and the sea in a world (again
-- now and then, since parts of the map may stream in later)
local function scan(area)
	if scanned[area] and os.clock() - scanned[area] < 15 then
		return
	end
	scanned[area] = os.clock()
	local world = Ambient.WORLDS[area]
	local where = areaFolder(area)
	if not where then
		return
	end
	local perchNames, flowerNames, swayNames = {}, {}, {}
	for _, n in ipairs(world.Perches or {}) do perchNames[n] = true end
	for _, n in ipairs(world.Flowers or {}) do flowerNames[n] = true end
	for _, n in ipairs(world.Sway or {}) do swayNames[n] = true end
	local oldPerches = perches[area] or {}
	perches[area], flowers[area], swayers[area] = {}, {}, swayers[area] or {}
	local known = {}
	for _, s in ipairs(swayers[area]) do
		known[s.Model] = true
	end
	for _, d in ipairs(where:GetDescendants()) do
		if d:IsA("Model") and (perchNames[d.Name] or flowerNames[d.Name] or swayNames[d.Name]) and d:FindFirstChildWhichIsA("BasePart", true) then
			local cf, size = d:GetBoundingBox()
			if perchNames[d.Name] then
				local top = cf.Position + Vector3.new(random:NextNumber(-0.3, 0.3) * size.X, size.Y / 2 - 0.4, random:NextNumber(-0.3, 0.3) * size.Z)
				table.insert(perches[area], { Position = top, Taken = false })
			end
			if flowerNames[d.Name] then
				table.insert(flowers[area], cf.Position - Vector3.new(0, size.Y / 2, 0))
			end
			if swayNames[d.Name] and not known[d] then
				table.insert(swayers[area], {
					Model = d,
					Base = d:GetPivot(),
					Bottom = cf.Position - Vector3.new(0, size.Y / 2, 0),
					Phase = random:NextNumber(0, 10),
					-- tall things sway less at the base but more at the top
					Amount = if d.Name == "Bamboo" then 0.03 else 0.06,
				})
			end
		elseif d.Name == "FrozenSea" and area == 3 then
			seaParts = {}
			for _, p in ipairs(d:GetDescendants()) do
				if p:IsA("BasePart") then
					table.insert(seaParts, p)
				end
			end
		end
	end
	-- birds sitting on a treetop keep it
	for _, old in ipairs(oldPerches) do
		if old.Taken then
			table.insert(perches[area], old)
		end
	end
end

-- Animals ---------------------------------------------------------------------------------------

local function animal(name, scale)
	local model, animated, rig = PetModels.build(name, true)
	model.Name = "Wild_" .. name
	model.Parent = folder
	if scale ~= 1 then
		model:ScaleTo(scale)
	end
	return model, Creature.new(model, rig, scale, animated)
end

local function add(e)
	table.insert(entities, e)
	Ambient.Stats.Kinds[e.Kind] = (Ambient.Stats.Kinds[e.Kind] or 0) + 1
	if e.Model then
		e.Model:SetAttribute("Area", e.Area)
	end
	Ambient.Stats.Peak = math.max(Ambient.Stats.Peak, animals())
	return e
end

-- A small animal wandering about: walk somewhere, stop and look around,
-- walk on; after a while it wanders off. `crossing` animals start at one
-- side of the path and cross it first.
local function spawnCritter(area, list, sea)
	local r = root()
	local world = Ambient.WORLDS[area]
	local name = list[random:NextInteger(1, #list)]
	local start
	local half = Config.AREA_HALF_WIDTH
	local band -- where it stays: {ZMin, ZMax}
	if sea then
		local side = if random:NextNumber() < 0.5 then -1 else 1
		band = { side * (half + 10), side * (half + 30) }
		local x = math.clamp(r.Position.X + random:NextNumber(-35, 35), Config.areaStart(area) + 4, Config.areaStart(area) + Config.AREA_LENGTH - 4)
		local z = random:NextNumber(math.min(band[1], band[2]), math.max(band[1], band[2]))
		local y = Creature.ground(x, z, 0)
		start = y and Vector3.new(x, y, z)
	else
		start = groundPoint(area, r.Position, 22, 45)
	end
	if not start then
		return
	end
	local model, c = animal(name, random:NextNumber(0.45, 0.6))
	c:teleport(start)
	c.Yaw = random:NextNumber(0, math.pi * 2)
	local e = { Kind = "critter", Area = area, Creature = c, Model = model }
	local pause = random:NextNumber(0.5, 2)
	local life = random:NextNumber(45, 90)
	if world.Crossing and not sea and random:NextNumber() < 0.5 then
		-- start at the edge of the path and cross it
		local side = if random:NextNumber() < 0.5 then -1 else 1
		local x = math.clamp(r.Position.X + random:NextNumber(-18, 18), Config.areaStart(area) + 6, Config.areaStart(area) + Config.AREA_LENGTH - 6)
		local y = Creature.ground(x, side * (half - 4), r.Position.Y + 10)
		if y then
			c:teleport(Vector3.new(x, y, side * (half - 4)))
			c:moveTo(Vector3.new(x + random:NextNumber(-8, 8), 0, -side * random:NextNumber(5, half - 6)), 0.55)
			pause = 0
		end
	end
	function e.Update(dt)
		life -= dt
		local goal = c.Goal
		local arrived = not goal or (Vector3.new(goal.X - c.Position.X, 0, goal.Z - c.Position.Z)).Magnitude < 1
		if arrived then
			c:moveTo(nil)
			pause -= dt
			if pause <= 0 then
				-- off somewhere nearby, now and then in a little dash
				local a = random:NextNumber(0, math.pi * 2)
				local d = random:NextNumber(5, 14)
				local x = math.clamp(c.Position.X + math.cos(a) * d, Config.areaStart(area) + 5, Config.areaStart(area) + Config.AREA_LENGTH - 5)
				local z = c.Position.Z + math.sin(a) * d
				if band then
					z = math.clamp(z, math.min(band[1], band[2]), math.max(band[1], band[2]))
				else
					z = math.clamp(z, -half + 4, half - 4)
				end
				if life < 0 then
					-- time to go: wander away from the player
					local away = (c.Position - r.Position) * Vector3.new(1, 0, 1)
					away = if away.Magnitude > 0.1 then away.Unit else Vector3.new(1, 0, 0)
					x = math.clamp(c.Position.X + away.X * 30, Config.areaStart(area) + 5, Config.areaStart(area) + Config.AREA_LENGTH - 5)
				end
				c:moveTo(Vector3.new(x, 0, z), if random:NextNumber() < 0.15 then 0.9 else random:NextNumber(0.3, 0.5))
				pause = random:NextNumber(2, 6)
			end
		end
		return life < -30 -- gone for good after a while (if out of view)
	end
	return add(e)
end

-- Birds: a fly-by across the sky, a flight to a treetop to sit a while, or
-- (in the desert) slow circles high above
local function spawnBird(area)
	local r = root()
	local world = Ambient.WORLDS[area]
	local name = world.Birds[random:NextInteger(1, #world.Birds)]
	local model, c = animal(name, random:NextNumber(0.4, 0.55))
	if PetModels.SPECIES[name].Move ~= "fly" then
		-- small birds that can't really fly (chicks) are carried by the same flight code
		c.Move = "fly"
		c.Height = 4
	end
	c.BaseSpeed = 20
	local e = { Kind = "bird", Area = area, Creature = c, Model = model }
	local p = r.Position
	local mode
	local list = perches[area] or {}
	local freePerches = {}
	for _, perch in ipairs(list) do
		if not perch.Taken and (perch.Position - p).Magnitude < 50 then
			table.insert(freePerches, perch)
		end
	end
	if world.Circle and random:NextNumber() < 0.5 then
		mode = "circle"
	elseif #freePerches > 0 and random:NextNumber() > world.FlyBy then
		mode = "perch"
	else
		mode = "flyby"
	end

	-- come in from far away, out of view
	local a = random:NextNumber(0, math.pi * 2)
	local from = p + Vector3.new(math.cos(a) * 75, 0, math.sin(a) * 75)
	if world.SeaBirds and mode == "flyby" then
		local side = if random:NextNumber() < 0.5 then -1 else 1
		from = Vector3.new(p.X - 80, 0, side * random:NextNumber(45, 70))
	end
	c.Height = random:NextNumber(14, 22)
	c:teleport(from)
	local perch, stay = nil, 0
	local circleCenter, circleRadius = nil, 0
	local life = random:NextNumber(35, 60)
	local exit
	local function leave()
		local b = random:NextNumber(0, math.pi * 2)
		exit = p + Vector3.new(math.cos(b) * 110, 0, math.sin(b) * 110)
		c.Landed, c.FixedGround = false, nil
		c.Height = random:NextNumber(14, 22)
		c:moveTo(exit, 1.2)
		if perch then
			perch.Taken = false
			perch = nil
		end
	end
	if mode == "perch" then
		perch = freePerches[random:NextInteger(1, #freePerches)]
		perch.Taken = true
		c:moveTo(perch.Position, 1)
	elseif mode == "circle" then
		circleCenter = p + Vector3.new(random:NextNumber(-30, 30), 0, random:NextNumber(-30, 30))
		circleRadius = random:NextNumber(20, 35)
		c.Height = random:NextNumber(28, 40)
		c.BaseSpeed = 14
	else
		-- straight across, passing near the player
		local target = p + Vector3.new(random:NextNumber(-15, 15), 0, random:NextNumber(-15, 15))
		exit = target + (target - from) * Vector3.new(1, 0, 1)
		if world.SeaBirds then
			c.Height = random:NextNumber(7, 12)
			exit = Vector3.new(from.X + 170, 0, from.Z + random:NextNumber(-10, 10))
		end
		c:moveTo(exit, 1.3)
	end

	function e.Update(dt, t)
		life -= dt
		if exit then
			return (Vector3.new(exit.X - c.Position.X, 0, exit.Z - c.Position.Z)).Magnitude < 4
		end
		if mode == "circle" then
			local angle = t * 0.12 + e.Seed
			c:moveTo(circleCenter + Vector3.new(math.cos(angle), 0, math.sin(angle)) * circleRadius, 1)
			if life < 0 then
				leave()
			end
		elseif perch then
			local flat = Vector3.new(perch.Position.X - c.Position.X, 0, perch.Position.Z - c.Position.Z).Magnitude
			if not c.Landed and flat < 1.5 then
				-- touch down on the treetop, fold the wings
				c.FixedGround = perch.Position.Y
				c.Landed = true
				Ambient.Stats.Landings += 1
				c:moveTo(nil)
				stay = random:NextNumber(6, 16)
				if world.Chirps then
					chirp(perch.Position)
				end
			elseif c.Landed then
				stay -= dt
				if world.Chirps and random:NextNumber() < dt * 0.04 * activity then
					chirp(perch.Position)
				end
				if stay <= 0 then
					-- off again: to another tree now and then, or away
					local others = {}
					for _, other in ipairs(perches[area] or {}) do
						if not other.Taken and other ~= perch and (other.Position - perch.Position).Magnitude < 40 then
							table.insert(others, other)
						end
					end
					if #others > 0 and life > 0 then
						perch.Taken = false
						perch = others[random:NextInteger(1, #others)]
						perch.Taken = true
						c.Landed, c.FixedGround = false, nil
						c.Height = 8
						c:moveTo(perch.Position, 0.8)
					else
						leave()
					end
				end
			end
		end
		return false
	end
	e.Seed = random:NextNumber(0, 10)
	function e.Removed()
		if perch then
			perch.Taken = false
		end
	end
	return add(e)
end

-- People ---------------------------------------------------------------------------------------------

local SKIN = { Color3.fromRGB(255, 220, 185), Color3.fromRGB(235, 185, 140), Color3.fromRGB(190, 135, 95), Color3.fromRGB(125, 85, 60) }
local SHIRTS = { Color3.fromRGB(255, 120, 120), Color3.fromRGB(100, 170, 255), Color3.fromRGB(120, 210, 140), Color3.fromRGB(255, 200, 90), Color3.fromRGB(190, 140, 255) }
local PANTS = { Color3.fromRGB(60, 70, 110), Color3.fromRGB(90, 70, 60), Color3.fromRGB(50, 55, 60), Color3.fromRGB(120, 140, 170) }
local HAIR = { Color3.fromRGB(60, 40, 30), Color3.fromRGB(230, 190, 110), Color3.fromRGB(30, 30, 35), Color3.fromRGB(180, 90, 50) }

local function pick(list)
	return list[random:NextInteger(1, #list)]
end

-- A friendly blocky visitor, built at the origin with a walking rig
local function person()
	local model = Instance.new("Model")
	model.Name = "Visitor"
	local function block(cf, size, color)
		local p = Instance.new("Part")
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Material = Enum.Material.SmoothPlastic
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.CFrame = cf
		p.Size = size
		p.Color = color
		p.Parent = model
		return p
	end
	local skin, shirt, pants, hair = pick(SKIN), pick(SHIRTS), pick(PANTS), pick(HAIR)
	local torso = block(CFrame.new(0, 0, 0), Vector3.new(2, 2, 1), shirt)
	block(CFrame.new(0, 1.6, 0), Vector3.new(1.2, 1.2, 1.2), skin)
	block(CFrame.new(0, 2.25, 0.08), Vector3.new(1.3, 0.3, 1.3), hair)
	block(CFrame.new(0, 1.8, 0.45), Vector3.new(1.3, 0.8, 0.4), hair)
	for _, side in ipairs({ -1, 1 }) do
		block(CFrame.new(side * 0.28, 1.7, -0.61), Vector3.new(0.16, 0.24, 0.05), Color3.fromRGB(35, 38, 60))
	end
	block(CFrame.new(0, 1.35, -0.61), Vector3.new(0.4, 0.08, 0.05), Color3.fromRGB(35, 38, 60))
	local rig = { Legs = {}, Wings = {}, FootY = -3, Move = "walk", Speed = 8 }
	for _, side in ipairs({ -1, 1 }) do
		local leg = block(CFrame.new(side * 0.5, -2, 0), Vector3.new(0.95, 2, 0.95), pants)
		table.insert(rig.Legs, { Parts = { leg }, Hip = Vector3.new(side * 0.5, -1, 0), Phase = if side < 0 then 0 else math.pi })
		local arm = block(CFrame.new(side * 1.5, -0.1, 0), Vector3.new(0.9, 1.9, 0.9), if random:NextNumber() < 0.5 then shirt else skin)
		table.insert(rig.Legs, { Parts = { arm }, Hip = Vector3.new(side * 1.5, 0.8, 0), Phase = if side < 0 then math.pi else 0 })
	end
	model.PrimaryPart = torso
	model.WorldPivot = CFrame.new()
	return model, rig
end

-- Someone out for a walk: strolls between spots, stops to look around, and
-- in the forest sometimes stands by the fountain for a while
local function spawnPerson(area)
	local r = root()
	local start = groundPoint(area, r.Position, 35, 55)
	if not start then
		return
	end
	local model, rig = person()
	model.Parent = folder
	local scale = random:NextNumber(0.8, 0.95)
	model:ScaleTo(scale)
	local c = Creature.new(model, rig, scale, {})
	c:teleport(start)
	local e = { Kind = "person", Area = area, Creature = c, Model = model }
	local world = Ambient.WORLDS[area]
	local spot
	if world.NpcSpot then
		local where = areaFolder(area)
		local thing = where and where:FindFirstChild(world.NpcSpot, true)
		if thing and thing:IsA("Model") and thing:FindFirstChildWhichIsA("BasePart", true) then
			local cf, size = thing:GetBoundingBox()
			spot = { Center = cf.Position, Radius = math.max(size.X, size.Z) / 2 + 2 }
		end
	end
	local pause, life = 0, random:NextNumber(50, 90)
	local half = Config.AREA_HALF_WIDTH
	function e.Update(dt)
		life -= dt
		local goal = c.Goal
		if goal and (Vector3.new(goal.X - c.Position.X, 0, goal.Z - c.Position.Z)).Magnitude > 1 then
			return false
		end
		c:moveTo(nil)
		pause -= dt
		if pause > 0 then
			return false
		end
		if life < 0 then
			return true -- (removed once out of view)
		end
		if spot and random:NextNumber() < 0.4 then
			-- stand at the fountain, looking at it
			local a = random:NextNumber(0, math.pi * 2)
			c:moveTo(spot.Center + Vector3.new(math.cos(a), 0, math.sin(a)) * spot.Radius, 0.45)
			c:face(spot.Center)
			pause = random:NextNumber(8, 15)
		else
			local a = random:NextNumber(0, math.pi * 2)
			local d = random:NextNumber(8, 20)
			local x = math.clamp(c.Position.X + math.cos(a) * d, Config.areaStart(area) + 6, Config.areaStart(area) + Config.AREA_LENGTH - 6)
			local z = math.clamp(c.Position.Z + math.sin(a) * d, -half + 5, half - 5)
			c:moveTo(Vector3.new(x, 0, z), 0.45)
			c:face(nil)
			pause = random:NextNumber(2, 7)
		end
		return false
	end
	return add(e)
end

-- Butterflies and bees ------------------------------------------------------------------------------

local function spawnFlyer(area, bee)
	local r = root()
	local list = flowers[area] or {}
	local home
	if #list > 0 then
		local near = {}
		for _, f in ipairs(list) do
			if (f - r.Position).Magnitude < 40 then
				table.insert(near, f)
			end
		end
		home = if #near > 0 then near[random:NextInteger(1, #near)] else nil
	end
	home = home or groundPoint(area, r.Position, 8, 30)
	if not home then
		return
	end
	local color = if bee then Color3.fromRGB(255, 205, 50) else pick(WING_COLORS)
	local size = if bee then 0.45 else random:NextNumber(0.7, 1)
	local function piece(s, c, transparency)
		local p = Instance.new("Part")
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Material = Enum.Material.SmoothPlastic
		p.Size = s
		p.Color = c
		p.Transparency = transparency or 0
		p.Parent = folder
		return p
	end
	local body = piece(Vector3.new(0.12, 0.12, 0.45) * size * (if bee then 1.6 else 1), if bee then Color3.fromRGB(40, 35, 30) else Color3.fromRGB(60, 45, 70))
	local wingColor = if bee then Color3.fromRGB(230, 245, 255) else color
	local left = piece(Vector3.new(0.55, 0.03, 0.5) * size, wingColor, if bee then 0.4 else 0)
	local right = piece(Vector3.new(0.55, 0.03, 0.5) * size, wingColor, if bee then 0.4 else 0)
	local parts = { body, left, right }
	local cframes = table.create(3)
	local seed = random:NextNumber(0, 100)
	local life = random:NextNumber(30, 70)
	local target = home
	local position = home + Vector3.new(0, 1.5, 0)
	local heading = 0
	local e = { Kind = if bee then "bee" else "butterfly", Area = area }
	function e.Position()
		return position
	end
	function e.Update(dt, t)
		life -= dt
		-- move to a new flower now and then
		if random:NextNumber() < dt * 0.08 and #list > 0 then
			local nextFlower = list[random:NextInteger(1, #list)]
			if (nextFlower - home).Magnitude < 25 then
				target = nextFlower
			end
		end
		home = home:Lerp(target, math.min(dt * 0.4, 1))
		local speed = if bee then 1.6 else 0.8
		local wander = Vector3.new(
			math.sin(t * 0.7 * speed + seed) * 2.5 + math.sin(t * 1.9 * speed + seed * 2) * 0.8,
			1.3 + math.sin(t * 1.1 * speed + seed) * 0.7 + (if life < 0 then -life * 3 else 0),
			math.cos(t * 0.6 * speed + seed) * 2.5 + math.cos(t * 1.7 * speed) * 0.8
		)
		local nextPosition = home + wander
		local move = nextPosition - position
		if move.Magnitude > 0.001 then
			heading = math.atan2(-move.X, -move.Z)
		end
		position = nextPosition
		local flap = math.sin(t * (if bee then 45 else 16) + seed) * (if bee then 0.5 else 1.1)
		local base = CFrame.new(position) * CFrame.Angles(0, heading, 0)
		local w = 0.3 * size
		cframes[1] = base
		cframes[2] = base * CFrame.Angles(0, 0, flap) * CFrame.new(-w, 0, 0)
		cframes[3] = base * CFrame.Angles(0, 0, -flap) * CFrame.new(w, 0, 0)
		workspace:BulkMoveTo(parts, cframes, Enum.BulkMoveMode.FireCFrameChanged)
		return life < -4 -- flown up and away
	end
	function e.Remove()
		for _, p in ipairs(parts) do
			p:Destroy()
		end
	end
	return add(e)
end

-- Falling leaves and petals ----------------------------------------------------------------------

local fallParts, fallFrames = {}, {}

local function spawnFaller(area)
	local world = Ambient.WORLDS[area]
	local r = root()
	local a = random:NextNumber(0, math.pi * 2)
	local d = random:NextNumber(3, 28)
	local x, z = r.Position.X + math.cos(a) * d, r.Position.Z + math.sin(a) * d
	local ground = Creature.ground(x, z, r.Position.Y + 10) or (r.Position.Y - 3)
	local leaf = world.Falling.Leaves and random:NextNumber() < 0.3
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.SmoothPlastic
	p.Size = if leaf then Vector3.new(0.5, 0.05, 0.35) else world.Falling.Size
	p.Color = if leaf then pick(LEAF_COLORS) else pick(world.Falling.Colors)
	p.Parent = folder
	table.insert(fallers, {
		Part = p,
		Origin = Vector3.new(x, ground + random:NextNumber(12, 18), z),
		Ground = ground,
		Age = 0,
		Fall = random:NextNumber(1.4, 2.2),
		Seed = random:NextNumber(0, 10),
		Rest = 0,
		Area = area,
	})
end

local function updateFallers(dt)
	table.clear(fallParts)
	table.clear(fallFrames)
	for i = #fallers, 1, -1 do
		local f = fallers[i]
		f.Age += dt
		local y = f.Origin.Y - f.Age * f.Fall
		if y <= f.Ground + 0.03 then
			-- lying on the ground a moment, then gone
			f.Rest += dt
			if f.Rest > 3 or f.Area ~= current then
				f.Part:Destroy()
				table.remove(fallers, i)
			end
		else
			local age, s = f.Age, f.Seed
			local drift = Vector3.new(math.sin(age * 1.4 + s) * 1.2 + age * 0.5 * (0.5 + gust), 0, math.cos(age * 1.1 + s) * 0.8 + age * 0.25)
			local position = Vector3.new(f.Origin.X, y, f.Origin.Z) + drift
			table.insert(fallParts, f.Part)
			table.insert(fallFrames, CFrame.new(position) * CFrame.Angles(math.sin(age * 2 + s) * 0.9, age * 1.3, math.cos(age * 1.7 + s) * 0.6))
		end
	end
	if #fallParts > 0 then
		workspace:BulkMoveTo(fallParts, fallFrames, Enum.BulkMoveMode.FireCFrameChanged)
	end
end

-- Weather: snow, blowing sand, fireflies (particles on parts that follow the player) -------------

local function emitterPart(name, size)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Transparency = 1
	p.Size = size
	p.Parent = folder
	local e = Instance.new("ParticleEmitter")
	e.Rate = 0
	e.Parent = p
	return p, e
end

local SOFT = "rbxasset://textures/particles/smoke_main.dds"
local SPARKLE = "rbxasset://textures/particles/sparkles_main.dds"

local snowPart, snow = emitterPart("Snow", Vector3.new(120, 1, 120))
snow.Texture = SOFT
snow.Color = ColorSequence.new(Color3.new(1, 1, 1))
snow.Size = NumberSequence.new(0.35)
snow.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.1, 0.1), NumberSequenceKeypoint.new(0.9, 0.1), NumberSequenceKeypoint.new(1, 1) })
snow.Lifetime = NumberRange.new(7, 9)
snow.Speed = NumberRange.new(3, 4.5)
snow.EmissionDirection = Enum.NormalId.Bottom
snow.SpreadAngle = Vector2.new(15, 15)
snow.RotSpeed = NumberRange.new(-40, 40)

local sandPart, sand = emitterPart("Sand", Vector3.new(4, 3, 90))
sand.Texture = SOFT
sand.Color = ColorSequence.new(Color3.fromRGB(245, 215, 150))
sand.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.8), NumberSequenceKeypoint.new(1, 2.4) })
sand.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.72), NumberSequenceKeypoint.new(1, 1) })
sand.Lifetime = NumberRange.new(4, 6)
sand.Speed = NumberRange.new(10, 16)
sand.EmissionDirection = Enum.NormalId.Right
sand.SpreadAngle = Vector2.new(4, 12)
sand.Acceleration = Vector3.new(0, 0.6, 0)

local firefliesPart, fireflies = emitterPart("Fireflies", Vector3.new(60, 4, 60))
fireflies.Texture = SPARKLE
fireflies.Color = ColorSequence.new(Color3.fromRGB(210, 255, 120))
fireflies.LightEmission = 1
fireflies.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.3, 0.35), NumberSequenceKeypoint.new(0.7, 0.35), NumberSequenceKeypoint.new(1, 0) })
fireflies.Lifetime = NumberRange.new(3, 5)
fireflies.Speed = NumberRange.new(0.2, 0.7)
fireflies.SpreadAngle = Vector2.new(180, 180)
fireflies.Acceleration = Vector3.new(0, 0.15, 0)

-- Ice cracks: a short crack of light on the frozen sea, with a crack sound
local function iceCrack()
	local r = root()
	local near = {}
	for _, p in ipairs(seaParts) do
		if p.Parent and (p.Position - r.Position).Magnitude < 60 and p.Size.X > 1 then
			table.insert(near, p)
		end
	end
	if #near == 0 then
		return
	end
	local base = near[random:NextInteger(1, #near)]
	local at = Vector3.new(base.Position.X + random:NextNumber(-4, 4), base.Position.Y + base.Size.Y / 2 + 0.03, base.Position.Z + random:NextNumber(-4, 4))
	local pieces = {}
	local point, angle = at, random:NextNumber(0, math.pi * 2)
	for _ = 1, random:NextInteger(3, 5) do
		angle += random:NextNumber(-0.8, 0.8)
		local length = random:NextNumber(1.2, 2.6)
		local nextPoint = point + Vector3.new(math.cos(angle), 0, math.sin(angle)) * length
		local p = Instance.new("Part")
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Material = Enum.Material.Neon
		p.Color = Color3.fromRGB(200, 240, 255)
		p.Size = Vector3.new(0.12, 0.04, length)
		p.CFrame = CFrame.lookAt((point + nextPoint) / 2, nextPoint)
		p.Parent = folder
		table.insert(pieces, p)
		TweenService:Create(p, TweenInfo.new(2.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Transparency = 1 }):Play()
		point = nextPoint
	end
	sound("Crack", at, random:NextNumber(0.5, 0.7), 0.25)
	Ambient.Stats.Cracks += 1
	task.delay(2.6, function()
		for _, p in ipairs(pieces) do
			p:Destroy()
		end
	end)
end

-- Lighting --------------------------------------------------------------------------------------------

local function applyLighting(area)
	local light = Ambient.WORLDS[area].Light
	local info = TweenInfo.new(3, Enum.EasingStyle.Sine)
	TweenService:Create(Lighting, info, { ClockTime = light.Clock }):Play()
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	if atmosphere then
		TweenService:Create(atmosphere, info, { Color = light.Air, Density = light.Density, Haze = light.Haze }):Play()
	end
	local tint = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
	if tint then
		TweenService:Create(tint, info, { TintColor = light.Tint }):Play()
	end
end

-- Entering a world ----------------------------------------------------------------------------------

local function enter(area)
	current = area
	scan(area)
	applyLighting(area)
	local id = Ambient.LOOPS[area]
	loop:Stop()
	if id and id ~= "" and State.Settings.Sounds then
		loop.SoundId = id
		loop:Play()
	end
	-- plants in other worlds go back to standing still
	for other, list in pairs(swayers) do
		if other ~= area then
			for _, s in ipairs(list) do
				if s.Moved and s.Model.Parent then
					s.Model:PivotTo(s.Base)
					s.Moved = false
				end
			end
		end
	end
end

-- The loop ------------------------------------------------------------------------------------------

local function removeAt(i)
	local e = entities[i]
	if e.Removed then
		e.Removed()
	end
	if e.Remove then
		e.Remove()
	elseif e.Model then
		e.Model:Destroy()
	end
	table.remove(entities, i)
end

local function position(e)
	if e.Creature then
		return e.Creature.Pivot and e.Creature.Pivot.Position or e.Creature.Position
	end
	return e.Position()
end

local spawnClock = 0
local swayClock = 0
local soundClock = 5

local function spawnTick(dt, t)
	local world = Ambient.WORLDS[current]
	-- lively and calm stretches
	if t > calmUntil and t > lively then
		if random:NextNumber() < 0.5 then
			calmUntil = t + random:NextNumber(20, 35)
			lively = calmUntil + random:NextNumber(40, 70)
		else
			lively = t + random:NextNumber(40, 70)
		end
	end
	local target = if t < calmUntil then 0.35 else 1
	activity += (target - activity) * math.min(dt * 0.5, 1)
	scan(current)

	local function cap(n)
		return math.floor(n * activity + 0.5)
	end
	local roomForAnimals = animals() < MAX_ANIMALS
	local function maybe(chance)
		return random:NextNumber() < chance
	end
	if roomForAnimals and world.Birds and count("bird") < cap(world.BirdCap) and maybe(0.12) then
		spawnBird(current)
	end
	if roomForAnimals and world.Critters and count("critter") < cap(world.CritterCap) + cap(world.SeaCap or 0) and maybe(0.2) then
		local seaCount = 0
		for _, e in ipairs(entities) do
			if e.Kind == "critter" and e.Sea then
				seaCount += 1
			end
		end
		if world.SeaCritters and seaCount < cap(world.SeaCap) and maybe(0.6) then
			local e = spawnCritter(current, world.SeaCritters, true)
			if e then
				e.Sea = true
			end
		else
			spawnCritter(current, world.Critters, false)
		end
	end
	if world.Butterflies and count("butterfly") < cap(world.Butterflies) and maybe(0.3) then
		spawnFlyer(current, false)
	end
	if world.Bees and world.Bees > 0 and count("bee") < cap(world.Bees) and maybe(0.2) then
		spawnFlyer(current, true)
	end
	-- people are rare: one every couple of minutes or so
	if roomForAnimals and count("person") < NPC_CAP and maybe(0.004 * activity) then
		spawnPerson(current)
	end
	if world.Falling and #fallers < cap(world.Falling.Cap) and maybe(0.6) then
		spawnFaller(current)
	end
end

local function updateWeather(r, t)
	local world = Ambient.WORLDS[current]
	-- the wind comes in gusts
	gust = math.clamp(math.sin(t * 0.21) * 0.5 + math.sin(t * 0.53 + 1) * 0.3 + 0.3, 0, 1)
	local feet = r.Position - Vector3.new(0, 3, 0)
	snowPart.CFrame = CFrame.new(feet + Vector3.new(0, 30, 0))
	snow.Rate = if world.Snow then 35 * (0.5 + activity * 0.5) else 0
	snow.Acceleration = Vector3.new(1.5 + gust * 3, 0, 0.6)
	sandPart.CFrame = CFrame.new(feet + Vector3.new(-40, 1.2, 0))
	sand.Rate = if world.Sand then 12 * gust * activity else 0
	firefliesPart.CFrame = CFrame.new(feet + Vector3.new(0, 2.5, 0))
	fireflies.Rate = if world.Fireflies then 5 * (0.4 + activity * 0.6) else 0
end

local function updateSway(r, t)
	local list = swayers[current]
	if not list then
		return
	end
	local moved = 0
	for _, s in ipairs(list) do
		local near = s.Model.Parent and (s.Bottom - r.Position).Magnitude < SWAY_RANGE
		if near and moved < SWAY_CAP then
			moved += 1
			local wind = math.sin(t * 1.3 + s.Phase) * 0.6 + math.sin(t * 2.9 + s.Phase * 1.7) * 0.25 + gust * 0.8
			local ax = wind * s.Amount * 0.4
			local az = -wind * s.Amount
			local pivot = CFrame.new(s.Bottom) * CFrame.Angles(ax, 0, az) * CFrame.new(-s.Bottom) * s.Base
			s.Model:PivotTo(pivot)
			s.Moved = true
		elseif s.Moved and s.Model.Parent then
			s.Model:PivotTo(s.Base)
			s.Moved = false
		end
	end
	Ambient.Stats.Swaying = moved
end

local function updateSounds(dt, r)
	local world = Ambient.WORLDS[current]
	soundClock -= dt
	if soundClock > 0 then
		return
	end
	soundClock = random:NextNumber(4, 9) / math.max(activity, 0.3)
	if world.Chirps and random:NextNumber() < 0.35 then
		-- a bird somewhere in the trees
		local a = random:NextNumber(0, math.pi * 2)
		chirp(r.Position + Vector3.new(math.cos(a) * 25, 8, math.sin(a) * 25))
	end
	if world.Wind and gust > 0.6 and random:NextNumber() < 0.5 then
		sound("Wind", r.Position + Vector3.new(-20, 4, 0), random:NextNumber(0.45, 0.6), 0.12)
	end
	if world.IceCracks and random:NextNumber() < 0.45 then
		iceCrack()
	end
end

local frame = 0

function Ambient.step(dt)
	local r = root()
	if not r then
		return
	end
	local t = os.clock()
	frame += 1
	local area = areaAt(r.Position.X)
	if area ~= current then
		enter(area)
	end

	spawnClock -= dt
	if spawnClock <= 0 then
		spawnClock = 0.5
		spawnTick(0.5, t)
	end

	-- update everything; far things less often; remove what's gone
	for i = #entities, 1, -1 do
		local e = entities[i]
		local p = position(e)
		local distance = (p - r.Position).Magnitude
		local done = false
		if e.Area ~= current or distance > DESPAWN_RANGE then
			done = hidden(p) or distance > DESPAWN_RANGE
		end
		if not done then
			e.Skip = (e.Skip or 0) + dt
			if distance < 45 or frame % 2 == 0 then
				local step = e.Skip
				e.Skip = 0
				done = e.Update(step, t) and hidden(p)
				if e.Creature then
					e.Creature:step(step, t)
				end
			end
		end
		if done then
			removeAt(i)
		end
	end

	updateFallers(dt)
	updateWeather(r, t)
	swayClock -= dt
	if swayClock <= 0 then
		swayClock = 1 / 15
		updateSway(r, t)
	end
	updateSounds(dt, r)
end

function Ambient.count()
	return #entities, #fallers
end

RunService.RenderStepped:Connect(Ambient.step)

return Ambient
