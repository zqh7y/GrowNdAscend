-- The player's pet: built from parts on the client, follows the character,
-- grows with its power and changes colour when it evolves.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)

local player = Players.LocalPlayer

local Pet = {}

local model, body, head, light, sparkles, tag
local scale, targetScale = 1, 1
local bounce = 0
local formIndex = 0

local function part(props)
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
	return p
end

local function build()
	model = Instance.new("Model")
	model.Name = "MyPet"

	body = part({ Name = "Body", Shape = Enum.PartType.Ball, Size = Vector3.new(2.4, 2.4, 2.4), CFrame = CFrame.new(0, 0, 0), Parent = model })
	head = part({ Name = "Head", Shape = Enum.PartType.Ball, Size = Vector3.new(1.9, 1.9, 1.9), CFrame = CFrame.new(0, 1.5, -0.6), Parent = model })
	for _, x in ipairs({ -0.55, 0.55 }) do
		part({ Name = "Ear", Size = Vector3.new(0.45, 0.8, 0.3), CFrame = CFrame.new(x, 2.5, -0.5) * CFrame.Angles(0, 0, x > 0 and -0.35 or 0.35), Parent = model })
		part({ Name = "Eye", Shape = Enum.PartType.Ball, Size = Vector3.new(0.38, 0.38, 0.38), Color = Color3.fromRGB(25, 25, 35), CFrame = CFrame.new(x * 0.7, 1.7, -1.45), Parent = model })
		part({ Name = "Foot", Shape = Enum.PartType.Ball, Size = Vector3.new(0.8, 0.6, 0.9), CFrame = CFrame.new(x * 1.3, -1.05, -0.4), Parent = model })
	end
	part({ Name = "Tail", Shape = Enum.PartType.Ball, Size = Vector3.new(0.7, 0.7, 0.7), CFrame = CFrame.new(0, 0.2, 1.3), Parent = model })
	model.PrimaryPart = body

	light = Instance.new("PointLight")
	light.Range = 10
	light.Brightness = 1.2
	light.Parent = body

	sparkles = Instance.new("ParticleEmitter")
	sparkles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparkles.Rate = 0
	sparkles.Lifetime = NumberRange.new(0.8, 1.4)
	sparkles.Speed = NumberRange.new(1, 3)
	sparkles.SpreadAngle = Vector2.new(180, 180)
	sparkles.Size = NumberSequence.new(0.4, 0)
	sparkles.LightEmission = 1
	sparkles.Parent = body

	tag = Instance.new("BillboardGui")
	tag.Size = UDim2.fromOffset(220, 60)
	tag.StudsOffsetWorldSpace = Vector3.new(0, 3.2, 0)
	tag.AlwaysOnTop = true
	tag.MaxDistance = 120
	tag.Adornee = head
	tag.Parent = model
	for i, name in ipairs({ "FormName", "PowerText" }) do
		local l = Instance.new("TextLabel")
		l.Name = name
		l.BackgroundTransparency = 1
		l.Size = UDim2.new(1, 0, 0.5, 0)
		l.Position = UDim2.fromScale(0, (i - 1) * 0.5)
		l.Font = Enum.Font.FredokaOne
		l.TextScaled = true
		l.TextColor3 = if i == 1 then Color3.new(1, 1, 1) else Color3.fromRGB(255, 225, 90)
		l.TextStrokeTransparency = 0.3
		l.Parent = tag
	end

	model.Parent = workspace
end

local function setForm(index)
	if index == formIndex then
		return
	end
	formIndex = index
	local form = Config.FORMS[index]
	for _, p in ipairs(model:GetChildren()) do
		if p:IsA("BasePart") and p.Name ~= "Eye" then
			p.Color = if p.Name == "Ear" or p.Name == "Tail" or p.Name == "Foot" then form.Glow else form.Color
			p.Material = if index >= 6 then Enum.Material.Neon else Enum.Material.SmoothPlastic
		end
	end
	light.Color = form.Glow
	light.Brightness = 0.6 + index * 0.3
	sparkles.Color = ColorSequence.new(form.Glow)
	sparkles.Rate = if index >= 3 then (index - 2) * 6 else 0
	tag.FormName.Text = form.Name
end

-- state is the data table the server sends
function Pet.update(state)
	if not model then
		build()
	end
	local form, index = Config.form(state.Ascensions)
	setForm(index)
	local power = Config.petPower(state)
	targetScale = Config.petScale(power, index)
	tag.PowerText.Text = "💪 " .. Config.formatNumber(power)
	tag.StudsOffsetWorldSpace = Vector3.new(0, 1.8 + 1.4 * scale, 0)
	return form
end

-- a little hop when the player taps
function Pet.bounce()
	bounce = 1
end

-- big celebration when the pet evolves
function Pet.evolve()
	if not body then
		return
	end
	sparkles:Emit(60)
	local ring = part({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.2, 2, 2),
		CFrame = body.CFrame * CFrame.Angles(0, 0, math.rad(90)),
		Color = light.Color,
		Material = Enum.Material.Neon,
		Transparency = 0.2,
		Parent = workspace,
	})
	TweenService:Create(ring, TweenInfo.new(0.9, Enum.EasingStyle.Quad), { Size = Vector3.new(0.2, 40, 40), Transparency = 1 }):Play()
	task.delay(1, function()
		ring:Destroy()
	end)
end

RunService.RenderStepped:Connect(function(dt)
	if not model then
		return
	end
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end

	-- grow smoothly toward the target size
	if math.abs(scale - targetScale) > 0.001 then
		scale += (targetScale - scale) * math.min(dt * 3, 1)
		model:ScaleTo(scale)
	end

	bounce = math.max(bounce - dt * 4, 0)
	local t = os.clock()
	local hop = math.sin(bounce * math.pi) * 1.2 * scale
	local bob = math.sin(t * 3) * 0.15 * scale
	local offset = Vector3.new(3 + scale * 1.3, 1.2 * scale - 1.5 + bob + hop, 3 + scale * 1.2)
	local goal = root.CFrame * CFrame.new(offset)
	local look = CFrame.lookAt(goal.Position, goal.Position + root.CFrame.LookVector)
	local current = model:GetPivot()
	model:PivotTo(current:Lerp(look, math.min(dt * 8, 1)))
end)

return Pet
