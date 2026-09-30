-- The equipped pets (models from PetModels). With nothing to fight they
-- follow the player in a loose arc; when the server puts them on a living
-- coin (the player's "PetTarget" attribute) they run to it, spread around
-- it, and lunge in with a little hop on every hit. Their glowing parts
-- pulse, halos spin, orbs orbit and energy wings flap. Big pets keep further
-- back and to the side, so they never park between the camera and the player.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Living = require(script.Parent.Living)
local PetModels = require(script.Parent.PetModels)

local player = Players.LocalPlayer

local Pets = {}

local followers = {} -- [slot] = { Name, Model, Size, Lunge, Hop, Animated }

local function build(name)
	local pet, size = Config.petInfo(name)
	local rarity = Config.rarity(pet.Odds)
	local model, animated, head = PetModels.build(name)

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

	model.Parent = workspace
	if size.Scale ~= 1 then
		model:ScaleTo(size.Scale)
	end
	-- remember where the animated parts sit relative to the pivot
	local pivot = model:GetPivot()
	for i, entry in ipairs(animated) do
		entry.Offset = pivot:ToObjectSpace(entry.Part.CFrame)
		entry.Phase = i * 0.7
	end
	return model, size, animated
end

-- equipped is the list of pet names from the server
function Pets.update(equipped)
	for slot = #followers, 1, -1 do
		local f = followers[slot]
		if equipped[slot] ~= f.Name then
			f.Model:Destroy()
			followers[slot] = nil
		end
	end
	for slot, name in ipairs(equipped) do
		if not followers[slot] and Config.petInfo(name) then
			local model, size, animated = build(name)
			followers[slot] = { Name = name, Model = model, Size = size, Lunge = 0, Hop = 0, Animated = animated }
		end
	end
end

-- A pet hit something: lunge forward with a hop
function Pets.lunge(slot)
	local f = followers[slot]
	if f then
		f.Lunge = 1
		f.Hop = 1
	end
end

-- The size row of the pet in a slot (for damage number colours)
function Pets.size(slot)
	local f = followers[slot]
	return f and f.Size.Index or 1
end

local function animate(f, pivot, t)
	for _, entry in ipairs(f.Animated) do
		local p = entry.Part
		if entry.Kind == "pulse" then
			p.Transparency = 0.15 + (math.sin(t * 4 + entry.Phase) * 0.5 + 0.5) * 0.35
		elseif entry.Kind == "rainbow" then
			p.Color = Color3.fromHSV((t * 0.25 + entry.Phase * 0.1) % 1, 0.6, 1)
		elseif entry.Kind == "spin" then
			p.CFrame = pivot * entry.Offset * CFrame.Angles(t * entry.Speed, 0, 0)
		elseif entry.Kind == "orbit" then
			p.CFrame = pivot * CFrame.Angles(0, t * entry.Speed, 0) * entry.Offset
		elseif entry.Kind == "flap" then
			p.CFrame = pivot * entry.Offset * CFrame.Angles(0, 0, math.sin(t * 5) * 0.25 * entry.Side)
		end
	end
end

RunService.RenderStepped:Connect(function(dt)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	local t = os.clock()
	local targetId = player:GetAttribute("PetTarget") or 0
	local targetPos = targetId ~= 0 and Living.position(targetId)
	local count = #followers
	for slot = 1, count do
		local f = followers[slot]
		if not f then
			continue
		end
		local scale = f.Size.Scale
		f.Lunge = math.max(f.Lunge - dt * 5, 0)
		f.Hop = math.max(f.Hop - dt * 4, 0)
		local hop = math.sin(f.Hop * math.pi) * 1.2 * math.sqrt(scale)
		local groundY = root.Position.Y - 3 -- the character's feet
		local bob = math.sin(t * 5 + slot) * 0.15
		local goal
		if targetPos then
			-- spread around the coin, facing it, and lunge in on each hit
			local a = (slot / math.max(count, 1)) * math.pi * 2 + slot * 0.3
			local ring = 3.2 + scale * 1.6
			local around = Vector3.new(math.cos(a), 0, math.sin(a))
			local spot = targetPos + around * ring * (1 - f.Lunge * 0.4)
			local position = Vector3.new(spot.X, targetPos.Y + 1.05 * scale + bob + hop, spot.Z)
			goal = CFrame.lookAt(position, Vector3.new(targetPos.X, position.Y, targetPos.Z))
		else
			-- a loose arc behind the player; big pets further out to the side
			local side = (slot - (count + 1) / 2) * (3.2 + scale * 1.3)
			if scale > 1.5 then
				side += (if slot % 2 == 0 then 1 else -1) * scale * 1.5
			end
			local back = 4 + scale * 2
			local position = (root.CFrame * CFrame.new(side, 0, back)).Position
			position = Vector3.new(position.X, groundY + 1.05 * scale + bob + hop, position.Z)
			goal = CFrame.lookAt(position, position + root.CFrame.LookVector)
		end
		local current = f.Model:GetPivot()
		local speed = if targetPos then 10 else 7
		local pivot = current:Lerp(goal, math.min(dt * speed, 1))
		f.Model:PivotTo(pivot)
		animate(f, pivot, t)
	end
end)

return Pets
