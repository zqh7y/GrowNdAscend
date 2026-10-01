-- The equipped pets. Each one is an animal (PetModels) that moves like one
-- (Creature): dogs and cats trot along with their legs going, bunnies hop,
-- birds fly with flapping wings, fish swim in the air, snakes slither.
-- With nothing to fight they follow the player in a loose group, each at its
-- own species speed (falling behind makes them run to catch up); idle, they
-- wag, breathe and look around. When the server puts them on a living coin
-- (the player's "PetTarget" attribute) they run to it, spread around it,
-- face it and lunge in on every hit. Big pets keep further back and to the
-- side, so they never park between the camera and the player.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Creature = require(script.Parent.Creature)
local Effects = require(script.Parent.Effects)
local Living = require(script.Parent.Living)
local PetModels = require(script.Parent.PetModels)

local player = Players.LocalPlayer

local Pets = {}

local folder = Instance.new("Folder")
folder.Name = "Pets"
folder.Parent = workspace

local followers = {} -- [slot] = { Name, Model, Size, Creature }

local function build(name)
	local pet, size = Config.petInfo(name)
	local rarity = Config.rarity(pet.Odds)
	local model, animated, rig, head = PetModels.build(name)
	-- this pet's own Speed stat
	rig.Speed *= Config.petStat(name, "Speed")

	-- name tag: the size in its colour, then the name in the rarity colour
	local tag = Instance.new("BillboardGui")
	tag.Size = UDim2.fromOffset(190, 26)
	tag.StudsOffsetWorldSpace = Vector3.new(0, (head.Y + 1.6) * size.Scale, 0)
	tag.MaxDistance = 70
	tag.Adornee = model.PrimaryPart
	tag.Parent = model
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.RichText = true
	label.Text = if size.Index > 1
		then string.format('<font color="#%s">%s</font> %s', size.Color:ToHex(), size.Name, pet.Name)
		else pet.Name
	label.TextColor3 = rarity.Color
	label.TextStrokeTransparency = 0.3
	label.Parent = tag

	model.Parent = folder
	if size.Scale ~= 1 then
		model:ScaleTo(size.Scale)
	end
	return model, size, Creature.new(model, rig, size.Scale, animated)
end

local function root()
	return player.Character and player.Character:FindFirstChild("HumanoidRootPart")
end

-- equipped is the list of pet names from the server
function Pets.update(equipped)
	for slot = #followers, 1, -1 do
		local f = followers[slot]
		if f and equipped[slot] ~= f.Name then
			local pet = Config.petInfo(f.Name)
			Effects.burst(f.Creature.Position + Vector3.new(0, 1.5 * f.Size.Scale, 0), if pet then pet.Color else Color3.new(1, 1, 1))
			f.Model:Destroy()
			followers[slot] = nil
		end
	end
	local r = root()
	for slot, name in ipairs(equipped) do
		if not followers[slot] and Config.petInfo(name) then
			local model, size, creature = build(name)
			-- appear just behind the player
			if r then
				creature:teleport((r.CFrame * CFrame.new((slot % 3 - 1) * 3, -3, 4)).Position)
			end
			followers[slot] = { Name = name, Model = model, Size = size, Creature = creature }
			if r then
				-- a soft poof as it joins
				Effects.burst(creature.Position + Vector3.new(0, 1.5 * size.Scale, 0), Config.petInfo(name).Color)
			end
		end
	end
end

-- A pet hit something: lunge forward with a hop
function Pets.lunge(slot)
	local f = followers[slot]
	if f then
		f.Creature:lunge()
	end
end

-- The size row of the pet in a slot (for damage number colours)
function Pets.size(slot)
	local f = followers[slot]
	return f and f.Size.Index or 1
end

RunService.RenderStepped:Connect(function(dt)
	local r = root()
	if not r then
		return
	end
	local t = os.clock()
	local targetId = player:GetAttribute("PetTarget") or 0
	local targetPos = targetId ~= 0 and Living.position(targetId)
	local feetY = r.Position.Y - 3
	local count = #followers
	for slot = 1, count do
		local f = followers[slot]
		if not f then
			continue
		end
		local c = f.Creature
		local scale = f.Size.Scale
		local goal
		if targetPos then
			-- spread around the coin, facing it
			local a = (slot / math.max(count, 1)) * math.pi * 2 + slot * 0.3
			local ring = 3.2 + scale * 1.6
			goal = targetPos + Vector3.new(math.cos(a), 0, math.sin(a)) * ring
			c:face(targetPos)
		else
			-- a loose group behind the player; big pets further out to the side
			local side = (slot - (count + 1) / 2) * (3.2 + scale * 1.3)
			if scale > 1.5 then
				side += (if slot % 2 == 0 then 1 else -1) * scale * 1.5
			end
			local back = 4 + scale * 2 + (slot % 2) * 1.5
			goal = (r.CFrame * CFrame.new(side, -3, back)).Position
			c:face(nil)
		end
		local distance = (Vector3.new(goal.X - c.Position.X, 0, goal.Z - c.Position.Z)).Magnitude
		if distance > 90 then
			c:teleport(goal) -- far behind (a teleport, a rebirth): just appear
			distance = 0
		end
		-- run to catch up when falling behind (up to the fighting speed)
		local topSpeed = math.max(Config.PET_SPEED / math.max(c.BaseSpeed, 1), 2)
		c:moveTo(goal, math.clamp(1 + (distance - 6) / 8, 1, topSpeed))
		-- if no ground was found (over a gap), stay at the player's height
		if math.abs(c.GroundY - feetY) > 30 then
			c.GroundY = feetY
		end
		c:step(dt, t)
	end
end)

return Pets
