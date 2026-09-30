-- The equipped pets, built from parts on the client. With nothing to fight
-- they follow the player in a loose arc; when the server puts them on a
-- living coin (the player's "PetTarget" attribute) they run to it, spread
-- around it, and lunge in with a little hop on every hit. Rarer pets glow,
-- bigger sizes are drawn bigger (Huge: gold sparkles, Titanic: rainbow aura).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Living = require(script.Parent.Living)

local player = Players.LocalPlayer

local Pets = {}

local followers = {} -- [slot] = { Name, Model, Size, Lunge, Hop }

local function part(parent, props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(props) do
		p[k] = v
	end
	p.Parent = parent
	return p
end

local function build(name)
	local pet, size = Config.petInfo(name)
	local rarity = Config.rarity(pet.Odds)
	local rarityIndex = table.find(Config.RARITIES, rarity)
	local model = Instance.new("Model")
	model.Name = "Pet_" .. name

	local light = pet.Color:Lerp(Color3.new(1, 1, 1), 0.3)
	local body = part(model, { Name = "Body", Shape = Enum.PartType.Ball, Size = Vector3.new(1.8, 1.8, 1.8), Color = pet.Color })
	part(model, { Shape = Enum.PartType.Ball, Size = Vector3.new(1.3, 1.3, 1.3), Color = light, CFrame = CFrame.new(0, -0.1, -0.45) }) -- belly
	part(model, { Name = "Head", Shape = Enum.PartType.Ball, Size = Vector3.new(1.45, 1.45, 1.45), Color = pet.Color, CFrame = CFrame.new(0, 1.1, -0.45) })
	for _, x in ipairs({ -0.4, 0.4 }) do
		part(model, { Size = Vector3.new(0.38, 0.62, 0.25), Color = rarity.Color, CFrame = CFrame.new(x, 1.85, -0.4) * CFrame.Angles(0, 0, x > 0 and -0.3 or 0.3) }) -- ears
		part(model, { Shape = Enum.PartType.Ball, Size = Vector3.one * 0.3, Color = Color3.fromRGB(35, 35, 55), CFrame = CFrame.new(x * 0.7, 1.25, -1.1) }) -- eyes
		part(model, { Shape = Enum.PartType.Ball, Size = Vector3.one * 0.1, Color = Color3.new(1, 1, 1), CFrame = CFrame.new(x * 0.7 - 0.05, 1.32, -1.24) }) -- shine
		part(model, { Shape = Enum.PartType.Ball, Size = Vector3.one * 0.26, Color = Color3.fromRGB(255, 150, 180), CFrame = CFrame.new(x * 1.2, 1.0, -1.02) }) -- blush
		part(model, { Shape = Enum.PartType.Ball, Size = Vector3.new(0.6, 0.45, 0.7), Color = light, CFrame = CFrame.new(x * 1.1, -0.75, -0.35) }) -- feet
	end
	part(model, { Shape = Enum.PartType.Ball, Size = Vector3.one * 0.6, Color = light, CFrame = CFrame.new(0, 0.1, 0.95) }) -- tail
	model.PrimaryPart = body

	-- rarer pets glow, very rare ones sparkle
	if rarityIndex >= 4 then
		local glow = Instance.new("PointLight")
		glow.Color = rarity.Color
		glow.Range = 8
		glow.Brightness = 1.4
		glow.Parent = body
	end
	if rarityIndex >= 5 or size.Index >= 2 then
		local sparkles = Instance.new("ParticleEmitter")
		sparkles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		sparkles.Color = if size.Index >= 3
			then ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 90, 90)),
				ColorSequenceKeypoint.new(0.33, Color3.fromRGB(255, 220, 60)),
				ColorSequenceKeypoint.new(0.66, Color3.fromRGB(80, 220, 255)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 100, 255)),
			})
			elseif size.Index == 2 then ColorSequence.new(size.Color)
			else ColorSequence.new(rarity.Color)
		sparkles.Rate = 6 + size.Index * 6
		sparkles.Lifetime = NumberRange.new(0.6, 1.2)
		sparkles.Speed = NumberRange.new(0.5, 2)
		sparkles.SpreadAngle = Vector2.new(180, 180)
		sparkles.Size = NumberSequence.new(0.3, 0)
		sparkles.LightEmission = 1
		sparkles.Parent = body
	end

	-- name tag: size in its colour, then the name in the rarity colour
	local tag = Instance.new("BillboardGui")
	tag.Size = UDim2.fromOffset(180, 26)
	tag.StudsOffsetWorldSpace = Vector3.new(0, 2.6 * size.Scale, 0)
	tag.MaxDistance = 70
	tag.Adornee = body
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
	return model, size
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
			local model, size = build(name)
			followers[slot] = { Name = name, Model = model, Size = size, Lunge = 0, Hop = 0 }
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
			local ring = 3.2 + scale * 1.2
			local around = Vector3.new(math.cos(a), 0, math.sin(a))
			local spot = targetPos + around * ring * (1 - f.Lunge * 0.45)
			local position = Vector3.new(spot.X, targetPos.Y + 0.9 * scale + bob + hop, spot.Z)
			goal = CFrame.lookAt(position, Vector3.new(targetPos.X, position.Y, targetPos.Z))
		else
			-- a loose arc behind the player
			local side = (slot - (count + 1) / 2) * (3.2 + scale)
			local back = 4 + scale * 1.5
			local position = (root.CFrame * CFrame.new(side, 0, back)).Position
			position = Vector3.new(position.X, groundY + 0.9 * scale + bob + hop, position.Z)
			goal = CFrame.lookAt(position, position + root.CFrame.LookVector)
		end
		local current = f.Model:GetPivot()
		local speed = if targetPos then 10 else 7
		f.Model:PivotTo(current:Lerp(goal, math.min(dt * speed, 1)))
	end
end)

return Pets
