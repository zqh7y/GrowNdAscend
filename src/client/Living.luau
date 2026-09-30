-- Living coins, the client side: builds a model for every coin the server
-- lists in ReplicatedStorage.LivingCoins (shared/Coins.luau builds it from
-- the coin's seed) and animates it from the coin's data. Each world's coin
-- has its own jump (Coins.STYLES):
--   tree:   crouches, springs straight up staying upright, lands with a squash
--   cactus: a bouncy hop, swaying side to side, with a little double bounce
--   ice:    a low slide with a full spin
--   sushi:  a hop with a somersault
-- All of them breathe while they rest, turn to face where they jump, and
-- flash and shake when a pet hits them. None of this depends on being hit.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Coins = require(ReplicatedStorage.Shared.Coins)

local Living = {}

local NEAR = 160 -- coins further than this from the camera update less often

local visuals = Instance.new("Folder")
visuals.Name = "LivingCoins"
visuals.Parent = Workspace

-- [id] = { Data, Model, Style, Yaw, Scale, Shake, Flash, Highlight, Phase, Position, Bar }
local coins = {}

-- A health bar and the coin's value above it
local function healthBar(model, areaIndex, height)
	local area = Config.AREAS[areaIndex]
	local gui = Instance.new("BillboardGui")
	gui.Name = "HealthBar"
	gui.Size = UDim2.new(4.5, 0, 0.9, 0)
	gui.StudsOffsetWorldSpace = Vector3.new(0, height + 1.4, 0)
	gui.MaxDistance = 70
	gui.Adornee = model.PrimaryPart
	gui.Parent = model
	local back = Instance.new("Frame")
	back.Position = UDim2.fromScale(0, 0.45)
	back.Size = UDim2.fromScale(1, 0.55)
	back.BackgroundColor3 = Color3.fromRGB(20, 22, 40)
	back.BackgroundTransparency = 0.3
	back.BorderSizePixel = 0
	back.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = back
	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = area.Color
	fill.BorderSizePixel = 0
	fill.Parent = back
	corner:Clone().Parent = fill
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 0.42)
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.4
	label.Text = Config.formatNumber(area.Breakable.Coins) .. " coins"
	label.Parent = gui
	return fill
end

local function add(data)
	local id = data:GetAttribute("Id")
	local area = data:GetAttribute("Area")
	if not id or not area or coins[id] then
		return
	end
	local model = Coins.build(area, visuals, data:GetAttribute("Seed") or id)
	local height = model:GetExtentsSize().Y
	local coin = {
		Data = data,
		Model = model,
		Style = Coins.STYLES[area],
		Yaw = math.random() * math.pi * 2,
		Scale = 1,
		Shake = 0,
		Phase = math.random() * 10,
		Position = data:GetAttribute("HopTo"),
		Bar = healthBar(model, area, height),
	}
	coins[id] = coin
	data:GetAttributeChangedSignal("Health"):Connect(function()
		local health, max = data:GetAttribute("Health"), data:GetAttribute("MaxHealth")
		TweenService:Create(coin.Bar, TweenInfo.new(0.12), { Size = UDim2.fromScale(math.clamp(health / max, 0, 1), 1) }):Play()
	end)
end

local function remove(data)
	local id = data:GetAttribute("Id")
	local coin = id and coins[id]
	if coin then
		coin.Model:Destroy()
		coins[id] = nil
	end
end

local folder = ReplicatedStorage:WaitForChild("LivingCoins")
for _, data in ipairs(folder:GetChildren()) do
	add(data)
end
folder.ChildAdded:Connect(add)
folder.ChildRemoved:Connect(remove)

-- Where a coin is right now (its feet), as drawn, or nil if it's gone
function Living.position(id)
	local coin = coins[id]
	return coin and coin.Position
end

function Living.model(id)
	local coin = coins[id]
	return coin and coin.Model
end

-- A pet landed a hit: flash white and shake a little
function Living.hit(id, strength)
	local coin = coins[id]
	if not coin then
		return
	end
	coin.Shake = math.min(coin.Shake + 0.35 * (strength or 1), 0.6)
	if not coin.Highlight then
		local highlight = Instance.new("Highlight")
		highlight.FillColor = Color3.new(1, 1, 1)
		highlight.OutlineTransparency = 1
		highlight.FillTransparency = 1
		highlight.DepthMode = Enum.HighlightDepthMode.Occluded
		highlight.Parent = coin.Model
		coin.Highlight = highlight
	end
	coin.Flash = 1
end

-- Motion ------------------------------------------------------------------------------------

-- For a jump at phase t (0..1, or <0 before / >1 after it), returns the
-- height above the path, how far along the path, the extra rotation, and
-- the uniform scale (squash/stretch), for each style.
local MOTIONS = {}

function MOTIONS.vertical(t, height)
	-- crouch for the first 20%, then spring straight up and come back down
	if t < 0.2 then
		return 0, 0, CFrame.new(), 1 - math.sin(t / 0.2 * math.pi) * 0.1
	end
	local u = (t - 0.2) / 0.8
	return math.sin(u * math.pi) * height, u, CFrame.new(), 1 + math.sin(u * math.pi) * 0.1
end

function MOTIONS.sway(t, height)
	-- a bouncy arc with a side-to-side sway
	local up = math.sin(t * math.pi) * height
	local sway = CFrame.Angles(0, 0, math.sin(t * math.pi * 2) * math.rad(14))
	return up, t, sway, 1 + math.sin(t * math.pi) * 0.06
end

function MOTIONS.skate(t, height)
	-- a low slide that eases out, spinning once around
	local along = 1 - (1 - t) ^ 2
	return math.sin(t * math.pi) * height, along, CFrame.Angles(0, t * math.pi * 2, 0), 1
end

function MOTIONS.flip(t, height)
	-- a hop with a somersault forwards (around the sideways axis)
	local up = math.sin(t * math.pi) * height
	local turn = CFrame.new(0, 1.5, 0) * CFrame.Angles(-t * math.pi * 2, 0, 0) * CFrame.new(0, -1.5, 0)
	return up, t, turn, 1
end

-- after landing: a quick squash that springs back (cactus bounces twice)
local function landing(since, style)
	if since < 0 then
		return 0, 1
	end
	local bounce = 0
	if style.Motion == "sway" and since < 0.35 then
		bounce = math.sin(since / 0.35 * math.pi) * style.Height * 0.25
	end
	return bounce, 1 - math.exp(-since * 9) * math.sin(since * 20) * 0.13
end

RunService.RenderStepped:Connect(function(dt)
	local now = Workspace:GetServerTimeNow()
	local clock = os.clock()
	local cameraPos = Workspace.CurrentCamera.CFrame.Position
	for _, coin in pairs(coins) do
		local data, style = coin.Data, coin.Style
		local from = data:GetAttribute("HopFrom")
		local to = data:GetAttribute("HopTo")
		local start = data:GetAttribute("HopStart") or 0
		local t = (now - start) / style.Air

		local up, along, turn, scale = 0, 1, CFrame.new(), 1
		if t >= 0 and t < 1 then
			up, along, turn, scale = MOTIONS[style.Motion](t, style.Height)
		else
			local bounce, squash = landing((now - start) - style.Air, style)
			up, scale = bounce, squash
		end
		-- the path runs along the ground from one landing to the next
		local ground = from:Lerp(to, math.clamp(along, 0, 1))
		coin.Position = ground

		-- far away coins only update now and then
		coin.Skip = (coin.Skip or 0) + 1
		if (ground - cameraPos).Magnitude > NEAR and coin.Skip % 8 ~= 0 then
			continue
		end

		-- face the way it's jumping
		local direction = to - from
		if direction.Magnitude > 0.1 then
			local goalYaw = math.atan2(-direction.X, -direction.Z)
			local diff = (goalYaw - coin.Yaw + math.pi) % (math.pi * 2) - math.pi
			coin.Yaw += diff * math.min(dt * 8, 1)
		end

		-- breathing and a gentle wobble while resting, shaking when hit
		local resting = t >= 1.6 or t < 0
		local breathe = if resting then math.sin(clock * 3 + coin.Phase) * 0.025 else 0
		local wobble = if resting and style.Motion ~= "skate" then math.sin(clock * 2.2 + coin.Phase) * math.rad(3) else 0
		coin.Shake = math.max(coin.Shake - dt * 2.5, 0)
		local shake = math.sin(clock * 60) * coin.Shake * math.rad(12)
		coin.Model:PivotTo(CFrame.new(ground + Vector3.new(0, up, 0)) * CFrame.Angles(0, coin.Yaw, 0) * turn * CFrame.Angles(0, 0, wobble + shake))

		-- grow in when new, then squash and stretch
		local grow = math.clamp((now - (data:GetAttribute("Born") or 0)) / 0.5, 0.05, 1)
		local size = grow * (scale + breathe)
		if math.abs(size - coin.Scale) > 0.012 then
			coin.Scale = size
			coin.Model:ScaleTo(math.max(size, 0.05))
		end

		if coin.Flash then
			coin.Flash = math.max(coin.Flash - dt * 6, 0)
			coin.Highlight.FillTransparency = 1 - coin.Flash * 0.7
			if coin.Flash == 0 then
				coin.Flash = nil
			end
		end
	end
end)

return Living
