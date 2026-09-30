-- The equipped pets: built from parts on the client and following the
-- character in a row behind them. Rarer pets glow.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)

local player = Players.LocalPlayer

local Pets = {}

local followers = {} -- { { Name, Model } } in equip order

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

local function build(pet)
	local rarity = Config.rarity(pet.Odds)
	local rarityIndex = table.find(Config.RARITIES, rarity)
	local model = Instance.new("Model")
	model.Name = "Pet_" .. pet.Name

	local body = part(model, { Name = "Body", Shape = Enum.PartType.Ball, Size = Vector3.new(1.8, 1.8, 1.8), Color = pet.Color })
	part(model, { Name = "Head", Shape = Enum.PartType.Ball, Size = Vector3.new(1.4, 1.4, 1.4), Color = pet.Color, CFrame = CFrame.new(0, 1.1, -0.45) })
	for _, x in ipairs({ -0.4, 0.4 }) do
		part(model, { Name = "Ear", Size = Vector3.new(0.35, 0.6, 0.25), Color = rarity.Color, CFrame = CFrame.new(x, 1.85, -0.4) })
		part(model, { Name = "Eye", Shape = Enum.PartType.Ball, Size = Vector3.new(0.28, 0.28, 0.28), Color = Color3.fromRGB(25, 25, 35), CFrame = CFrame.new(x * 0.7, 1.25, -1.08) })
	end
	model.PrimaryPart = body

	-- Epic and rarer glow, Legendary and rarer sparkle
	if rarityIndex >= 4 then
		local light = Instance.new("PointLight")
		light.Color = rarity.Color
		light.Range = 8
		light.Brightness = 1.5
		light.Parent = body
	end
	if rarityIndex >= 5 then
		local sparkles = Instance.new("ParticleEmitter")
		sparkles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		sparkles.Color = ColorSequence.new(rarity.Color)
		sparkles.Rate = 8 + (rarityIndex - 5) * 8
		sparkles.Lifetime = NumberRange.new(0.6, 1.2)
		sparkles.Speed = NumberRange.new(0.5, 2)
		sparkles.SpreadAngle = Vector2.new(180, 180)
		sparkles.Size = NumberSequence.new(0.3, 0)
		sparkles.LightEmission = 1
		sparkles.Parent = body
	end

	local tag = Instance.new("BillboardGui")
	tag.Size = UDim2.fromOffset(160, 26)
	tag.StudsOffsetWorldSpace = Vector3.new(0, 2.6, 0)
	tag.MaxDistance = 60
	tag.Adornee = body
	tag.Parent = model
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.Text = pet.Name
	label.TextColor3 = rarity.Color
	label.TextStrokeTransparency = 0.3
	label.Parent = tag

	model.Parent = workspace
	return model
end

-- equipped is the list of pet names from the server
function Pets.update(equipped)
	-- keep the ones still equipped, remove the rest
	local kept = {}
	for _, follower in ipairs(followers) do
		if table.find(equipped, follower.Name) and not kept[follower.Name] then
			kept[follower.Name] = follower
		else
			follower.Model:Destroy()
		end
	end
	followers = {}
	for _, name in ipairs(equipped) do
		local pet = Config.PETS_BY_NAME[name]
		if pet then
			table.insert(followers, kept[name] or { Name = name, Model = build(pet) })
		end
	end
end

RunService.RenderStepped:Connect(function(dt)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	local t = os.clock()
	local count = #followers
	for i, follower in ipairs(followers) do
		-- spread in an arc behind the player
		local side = (i - (count + 1) / 2) * 3.2
		local bob = math.sin(t * 4 + i) * 0.25
		local goal = root.CFrame * CFrame.new(side, -1.6 + bob, 5)
		local look = CFrame.lookAt(goal.Position, goal.Position + root.CFrame.LookVector)
		local current = follower.Model:GetPivot()
		follower.Model:PivotTo(current:Lerp(look, math.min(dt * 8, 1)))
	end
end)

return Pets
