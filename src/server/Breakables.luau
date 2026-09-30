-- Coin breakables: small trees, cactuses, ice cubes and sushi. Players tap one
-- to hit it (their equipped pets add damage); when it breaks they get coins
-- and a new one grows back somewhere else in the area.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local PlayerData = require(script.Parent.PlayerData)
local World = require(script.Parent.World)

local PER_AREA = 14 -- breakables alive in each area at once
local RESPAWN_SECONDS = 4
local MAX_HITS_PER_SECOND = 12
local MAX_DISTANCE = 70

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local coinEvent = Instance.new("RemoteEvent")
coinEvent.Name = "CoinPop" -- server -> client: (position, coins) when something breaks
coinEvent.Parent = remotes
local notifyEvent = remotes:WaitForChild("Notify")

local random = Random.new()
local hitWindow = {} -- [player] = { Start, Count }
local lastLockedNotice = {} -- [player] = os.clock(), so the "locked" message doesn't spam

local function healthBar(model, area, height)
	local gui = Instance.new("BillboardGui")
	gui.Name = "HealthBar"
	gui.Size = UDim2.new(6, 0, 1.1, 0)
	gui.StudsOffsetWorldSpace = Vector3.new(0, height + 1.2, 0)
	gui.MaxDistance = 60
	gui.Adornee = model.PrimaryPart
	gui.Parent = model

	local back = Instance.new("Frame")
	back.Name = "Back"
	back.Position = UDim2.fromScale(0, 0.45)
	back.Size = UDim2.fromScale(1, 0.55)
	back.BackgroundColor3 = Color3.fromRGB(20, 22, 40)
	back.BackgroundTransparency = 0.2
	back.BorderSizePixel = 0
	back.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = back

	local fill = corner:Clone()
	local bar = Instance.new("Frame")
	bar.Name = "Fill"
	bar.Size = UDim2.fromScale(1, 1)
	bar.BackgroundColor3 = area.Color
	bar.BorderSizePixel = 0
	bar.Parent = back
	fill.Parent = bar

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 0.42)
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.4
	label.Text = area.Breakable.Name .. "  ·  " .. Config.formatNumber(area.Breakable.Coins) .. " coins"
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
	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(color)
	emitter.Size = NumberSequence.new(0.6, 0)
	emitter.Lifetime = NumberRange.new(0.5, 0.9)
	emitter.Speed = NumberRange.new(10, 18)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Acceleration = Vector3.new(0, -30, 0)
	emitter.Rate = 0
	emitter.Parent = anchor
	emitter:Emit(24)
	task.delay(1.2, function()
		anchor:Destroy()
	end)
end

-- Spawning ----------------------------------------------------------------------

local taken = {} -- [area index] = { [spot index] = true }
local spawnOne

local function breakIt(model, areaIndex, spotIndex, player)
	local area = Config.AREAS[areaIndex]
	local data = PlayerData.get(player)
	local coins = math.floor(area.Breakable.Coins * Config.coinMultiplier(data.Rebirths))
	data.Coins += coins
	PlayerData.sync(player)

	local position = model:GetPivot().Position + Vector3.new(0, 3, 0)
	coinEvent:FireClient(player, position, coins)
	burst(position, area.Color)
	model:Destroy()
	taken[areaIndex][spotIndex] = nil
	task.delay(RESPAWN_SECONDS, spawnOne, areaIndex)
end

local function hit(player, model, areaIndex, spotIndex)
	local data = PlayerData.get(player)
	if not data or not model.Parent then
		return
	end
	if data.Unlocked < areaIndex then
		local now = os.clock()
		if not lastLockedNotice[player] or now - lastLockedNotice[player] > 2 then
			lastLockedNotice[player] = now
			notifyEvent:FireClient(player, "Unlock " .. Config.AREAS[areaIndex].Name .. " first!", "danger")
		end
		return
	end

	-- not too fast, not too far
	local now = os.clock()
	local window = hitWindow[player]
	if not window or now - window.Start >= 1 then
		window = { Start = now, Count = 0 }
		hitWindow[player] = window
	end
	window.Count += 1
	if window.Count > MAX_HITS_PER_SECOND then
		return
	end
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root or (root.Position - model:GetPivot().Position).Magnitude > MAX_DISTANCE then
		return
	end

	local health = model:GetAttribute("Health") - Config.hitDamage(data.Equipped)
	if health <= 0 then
		breakIt(model, areaIndex, spotIndex, player)
		return
	end
	model:SetAttribute("Health", health)
	local bar = model.HealthBar.Back.Fill
	TweenService:Create(bar, TweenInfo.new(0.12), {
		Size = UDim2.fromScale(health / model:GetAttribute("MaxHealth"), 1),
	}):Play()
	-- a little squish so every hit feels like it landed
	model:ScaleTo(0.9)
	task.delay(0.07, function()
		if model.Parent then
			model:ScaleTo(1)
		end
	end)
end

function spawnOne(areaIndex)
	local areaWorld = World.Areas[areaIndex]
	local spots = areaWorld.Spots
	local free = {}
	for index in ipairs(spots) do
		if not taken[areaIndex][index] then
			table.insert(free, index)
		end
	end
	if #free == 0 then
		return
	end
	local spotIndex = free[random:NextInteger(1, #free)]
	taken[areaIndex][spotIndex] = true

	local area = Config.AREAS[areaIndex]
	local model = areaWorld.Module.breakable(areaWorld.Breakables, spots[spotIndex], random)
	model.WorldPivot = CFrame.new(spots[spotIndex]) -- scale from the ground up
	model:SetAttribute("Health", area.Breakable.Health)
	model:SetAttribute("MaxHealth", area.Breakable.Health)
	healthBar(model, area, model:GetExtentsSize().Y)

	local click = Instance.new("ClickDetector")
	click.MaxActivationDistance = MAX_DISTANCE
	click.Parent = model
	click.MouseClick:Connect(function(player)
		hit(player, model, areaIndex, spotIndex)
	end)

	-- grow in
	model:ScaleTo(0.2)
	for k = 1, 8 do
		task.delay(k * 0.03, function()
			if model.Parent then
				model:ScaleTo(0.2 + 0.8 * k / 8)
			end
		end)
	end
end

for i, areaWorld in ipairs(World.Areas) do
	areaWorld.Breakables = Instance.new("Folder")
	areaWorld.Breakables.Name = "Breakables"
	areaWorld.Breakables.Parent = areaWorld.Folder
	taken[i] = {}
	for _ = 1, math.min(PER_AREA, #areaWorld.Spots) do
		spawnOne(i)
	end
end

Players.PlayerRemoving:Connect(function(player)
	hitWindow[player] = nil
	lastLockedNotice[player] = nil
end)

return {}
