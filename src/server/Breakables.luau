-- Living coins: trees, cactuses, ice cubes and sushi that hop around their
-- area. The server keeps each one's real position and health and decides
-- when it hops; the client plays the hop (see client/Living.luau), so the
-- motion is smooth. Pets fight them automatically (Combat.luau); when one
-- breaks the player gets coins and a new one grows somewhere else.
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local PlayerData = require(script.Parent.PlayerData)
local World = require(script.Parent.World)

local Breakables = {}

local PER_AREA = 9 -- living coins in each area at once
local RESPAWN_SECONDS = 3

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local coinEvent = Instance.new("RemoteEvent")
coinEvent.Name = "CoinPop" -- server -> client: (position, coins, area) when one breaks
coinEvent.Parent = remotes

local random = Random.new()

-- [id] = { Id, Model, Area, Spot, Home, Pos, Health, MaxHealth, NextHop, Bar }
Breakables.Targets = {}
local nextId = 0
local taken = {} -- [area index] = { [spot index] = true }

local function healthBar(model, area, height)
	local gui = Instance.new("BillboardGui")
	gui.Name = "HealthBar"
	gui.Size = UDim2.new(4.5, 0, 0.9, 0)
	gui.StudsOffsetWorldSpace = Vector3.new(0, height + 1.4, 0)
	gui.MaxDistance = 70
	gui.Adornee = model.PrimaryPart
	gui.Parent = model

	local back = Instance.new("Frame")
	back.Name = "Back"
	back.Position = UDim2.fromScale(0, 0.45)
	back.Size = UDim2.fromScale(1, 0.55)
	back.BackgroundColor3 = Color3.fromRGB(20, 22, 40)
	back.BackgroundTransparency = 0.3
	back.BorderSizePixel = 0
	back.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = back
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.new(1, 1, 1)
	stroke.Transparency = 0.4
	stroke.Thickness = 1.5
	stroke.Parent = back

	local bar = Instance.new("Frame")
	bar.Name = "Fill"
	bar.Size = UDim2.fromScale(1, 1)
	bar.BackgroundColor3 = area.Color
	bar.BorderSizePixel = 0
	bar.Parent = back
	corner:Clone().Parent = bar

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 0.42)
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.4
	label.Text = Config.formatNumber(area.Breakable.Coins) .. " coins"
	label.Parent = gui
	return bar
end

local function burst(position, color)
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.Transparency = 1
	anchor.Size = Vector3.new(1, 1, 1)
	anchor.CFrame = CFrame.new(position)
	anchor.Parent = workspace
	for _, spec in ipairs({ { color, 26, 0.7 }, { Color3.fromRGB(255, 215, 60), 14, 0.5 } }) do
		local emitter = Instance.new("ParticleEmitter")
		emitter.Color = ColorSequence.new(spec[1])
		emitter.Size = NumberSequence.new(spec[3], 0)
		emitter.Lifetime = NumberRange.new(0.5, 0.9)
		emitter.Speed = NumberRange.new(10, 20)
		emitter.SpreadAngle = Vector2.new(180, 180)
		emitter.Acceleration = Vector3.new(0, -30, 0)
		emitter.Rate = 0
		emitter.Parent = anchor
		emitter:Emit(spec[2])
	end
	task.delay(1.2, function()
		anchor:Destroy()
	end)
end

-- Spawning --------------------------------------------------------------------------

local function spawnOne(areaIndex)
	local areaWorld = World.Areas[areaIndex]
	local free = {}
	for index in ipairs(areaWorld.Spots) do
		if not taken[areaIndex][index] then
			table.insert(free, index)
		end
	end
	if #free == 0 then
		return
	end
	local spot = free[random:NextInteger(1, #free)]
	taken[areaIndex][spot] = true
	local home = areaWorld.Spots[spot]

	local area = Config.AREAS[areaIndex]
	local model = areaWorld.Module.breakable(areaWorld.Breakables, home, random)
	model.WorldPivot = CFrame.new(home) -- everything is placed relative to its feet
	nextId += 1
	local target = {
		Id = nextId,
		Model = model,
		Area = areaIndex,
		Spot = spot,
		Home = home,
		Pos = home,
		Health = area.Breakable.Health,
		MaxHealth = area.Breakable.Health,
		NextHop = os.clock() + random:NextNumber(0.3, 1.2),
	}
	target.Bar = healthBar(model, area, model:GetExtentsSize().Y)
	model:SetAttribute("Id", target.Id)
	model:SetAttribute("Area", areaIndex)
	model:SetAttribute("Health", target.Health)
	model:SetAttribute("MaxHealth", target.MaxHealth)
	model:SetAttribute("HopFrom", home)
	model:SetAttribute("HopTo", home)
	model:SetAttribute("HopStart", 0)
	model:SetAttribute("Born", workspace:GetServerTimeNow()) -- the client grows it in
	CollectionService:AddTag(model, "Living")
	Breakables.Targets[target.Id] = target
end

-- Hopping ---------------------------------------------------------------------------

-- the next spot to hop to: about 5 studs away, drifting back towards home
-- if it has wandered off, and never outside the area
local function nextSpot(target)
	local x0 = Config.areaStart(target.Area)
	local half = Config.AREA_HALF_WIDTH
	local distance = random:NextNumber(Config.HOP_DISTANCE[1], Config.HOP_DISTANCE[2])
	local a = random:NextNumber(0, math.pi * 2)
	local dir = Vector3.new(math.cos(a), 0, math.sin(a))
	local toHome = target.Home - target.Pos
	if toHome.Magnitude > Config.WANDER * 0.6 then
		dir = (toHome.Unit + dir * 0.5).Unit
	end
	local p = target.Pos + dir * distance
	return Vector3.new(
		math.clamp(p.X, x0 + 5, x0 + Config.AREA_LENGTH - 5),
		target.Home.Y,
		math.clamp(p.Z, -half + 4, half - 4)
	)
end

task.spawn(function()
	while true do
		task.wait(0.1)
		local now = os.clock()
		for _, target in pairs(Breakables.Targets) do
			if now >= target.NextHop then
				local to = nextSpot(target)
				target.Model:SetAttribute("HopFrom", target.Pos)
				target.Model:SetAttribute("HopTo", to)
				target.Model:SetAttribute("HopStart", workspace:GetServerTimeNow())
				target.Pos = to
				target.NextHop = now + Config.HOP_TIME + random:NextNumber(Config.HOP_EVERY[1], Config.HOP_EVERY[2])
			end
		end
	end
end)

-- Damage ------------------------------------------------------------------------------

-- Living coins within `radius` of `position` in areas up to `unlocked`
function Breakables.near(position, radius, unlocked)
	local list = {}
	for _, target in pairs(Breakables.Targets) do
		if target.Area <= unlocked and (target.Pos - position).Magnitude <= radius then
			table.insert(list, target)
		end
	end
	return list
end

function Breakables.alive(target)
	return Breakables.Targets[target.Id] == target
end

-- Deals damage for `player`; returns true if it broke
function Breakables.damage(target, amount, player)
	if not Breakables.alive(target) then
		return false
	end
	target.Health -= amount
	if target.Health > 0 then
		target.Model:SetAttribute("Health", target.Health)
		TweenService:Create(target.Bar, TweenInfo.new(0.12), {
			Size = UDim2.fromScale(target.Health / target.MaxHealth, 1),
		}):Play()
		return false
	end

	-- broken: reward, effects, and a new one a little later
	local area = Config.AREAS[target.Area]
	local data = PlayerData.get(player)
	local coins = 0
	if data then
		coins = math.floor(area.Breakable.Coins * Config.coinGain(data))
		data.Coins += coins
		PlayerData.sync(player)
	end
	local position = target.Pos + Vector3.new(0, 2.5, 0)
	coinEvent:FireClient(player, position, coins, target.Area)
	burst(position, area.Color)
	Breakables.Targets[target.Id] = nil
	target.Model:Destroy()
	taken[target.Area][target.Spot] = nil
	task.delay(RESPAWN_SECONDS, spawnOne, target.Area)
	return true
end

for i, areaWorld in ipairs(World.Areas) do
	areaWorld.Breakables = Instance.new("Folder")
	areaWorld.Breakables.Name = "LivingCoins"
	areaWorld.Breakables.Parent = areaWorld.Folder
	taken[i] = {}
	for _ = 1, math.min(PER_AREA, #areaWorld.Spots) do
		spawnOne(i)
	end
end

return Breakables
