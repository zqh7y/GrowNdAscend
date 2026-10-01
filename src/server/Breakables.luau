-- Living coins: the server side. The server keeps only each coin's data
-- (where it is, its health, when it jumps next); the client builds and
-- animates the models (client/Living.luau) from that data. So a coin moves
-- the same whether or not a pet is on it, and nothing depends on which parts
-- of the map have streamed in.
--
-- Each coin is a Configuration in ReplicatedStorage.LivingCoins with:
--   Id, Area, Seed (its look), Home, Health, MaxHealth, Born
--   HopFrom, HopTo, HopStart (server time of its latest jump)
-- Coins rest, jump, land and rest again: every jump is scheduled on the
-- server clock (workspace:GetServerTimeNow()), with a rest after landing.
-- Every position is on the measured ground (World.groundAt).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Coins = require(ReplicatedStorage.Shared.Coins)
local PlayerData = require(script.Parent.PlayerData)
local World = require(script.Parent.World)

local Breakables = {}

local PER_AREA = 5 -- living coins in each area at once
local RESPAWN_SECONDS = 3
local SPACING = 7 -- a new coin never appears closer than this to another

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local levelEvent = Instance.new("RemoteEvent")
levelEvent.Name = "LevelUp" -- server -> client: (new level) when a player levels up
levelEvent.Parent = remotes

local coinEvent = Instance.new("RemoteEvent")
coinEvent.Name = "CoinPop" -- server -> client: (position, coins, area) when one breaks
coinEvent.Parent = remotes

local folder = Instance.new("Folder")
folder.Name = "LivingCoins"
folder.Parent = ReplicatedStorage

local random = Random.new()

-- [id] = { Id, Area, Spot, Home, Pos, Health, MaxHealth, NextHop, Data }
Breakables.Targets = {}
local nextId = 0
local taken = {} -- [area index] = { [spot index] = true }
local pending = {} -- [area index] = targets waiting to respawn

local function now()
	return workspace:GetServerTimeNow()
end

-- Spawning ---------------------------------------------------------------------------

-- The free spot furthest from every living coin in the area (at least
-- SPACING away), so the coins spread over the whole area and the pets have
-- to move between them. A little randomness keeps it from being predictable.
local function freeSpot(areaIndex)
	local best, bestScore = nil, -math.huge
	for index, spot in ipairs(World.Areas[areaIndex].Spots) do
		if not taken[areaIndex][index] then
			local nearest = math.huge
			for _, target in pairs(Breakables.Targets) do
				if target.Area == areaIndex then
					nearest = math.min(nearest, (target.Pos - spot).Magnitude, (target.Home - spot).Magnitude)
				end
			end
			if nearest >= SPACING then
				local score = math.min(nearest, 60) + random:NextNumber(0, 12)
				if score > bestScore then
					best, bestScore = index, score
				end
			end
		end
	end
	return best
end

local function alive(areaIndex)
	local n = 0
	for _, target in pairs(Breakables.Targets) do
		if target.Area == areaIndex then
			n += 1
		end
	end
	return n
end

local function spawnOne(areaIndex)
	local spot = freeSpot(areaIndex)
	if not spot then
		-- everything is busy; the watchdog below tries again shortly
		return
	end
	taken[areaIndex][spot] = true
	local home = World.Areas[areaIndex].Spots[spot]
	local area = Config.AREAS[areaIndex]
	local style = Coins.STYLES[areaIndex]

	nextId += 1
	local data = Instance.new("Configuration")
	data.Name = tostring(nextId)
	local target = {
		Id = nextId,
		Area = areaIndex,
		Spot = spot,
		Home = home,
		Pos = home,
		Health = area.Breakable.Health,
		MaxHealth = area.Breakable.Health,
		NextHop = now() + random:NextNumber(style.Rest[1], style.Rest[2]),
		Data = data,
	}
	data:SetAttribute("Id", target.Id)
	data:SetAttribute("Area", areaIndex)
	data:SetAttribute("Seed", random:NextInteger(1, 1e9))
	data:SetAttribute("Home", home)
	data:SetAttribute("Health", target.Health)
	data:SetAttribute("MaxHealth", target.MaxHealth)
	data:SetAttribute("HopFrom", home)
	data:SetAttribute("HopTo", home)
	data:SetAttribute("HopStart", 0)
	data:SetAttribute("Born", now())
	data.Parent = folder
	Breakables.Targets[target.Id] = target
end

-- Jumping ------------------------------------------------------------------------------

-- Where to land next: a style-sized jump that drifts back towards home when
-- it has wandered off, stays in the area, and lands on flat ground. Returns
-- nil if no good landing was found (it just waits and tries again).
local function nextSpot(target)
	local style = Coins.STYLES[target.Area]
	local x0 = Config.areaStart(target.Area)
	local half = Config.AREA_HALF_WIDTH
	local toHome = target.Home - target.Pos
	for _ = 1, 6 do
		local distance = random:NextNumber(style.Distance[1], style.Distance[2])
		local a = random:NextNumber(0, math.pi * 2)
		local dir = Vector3.new(math.cos(a), 0, math.sin(a))
		if toHome.Magnitude > Config.WANDER * 0.6 then
			dir = (Vector3.new(toHome.X, 0, toHome.Z).Unit + dir * 0.5).Unit
		end
		local x = math.clamp(target.Pos.X + dir.X * distance, x0 + 5, x0 + Config.AREA_LENGTH - 5)
		local z = math.clamp(target.Pos.Z + dir.Z * distance, -half + 4, half - 4)
		if World.flatGround(x, z, 1.5) then
			return Vector3.new(x, World.groundAt(x, z), z)
		end
	end
	return nil
end

task.spawn(function()
	while true do
		task.wait(0.2)
		local t = now()
		for _, target in pairs(Breakables.Targets) do
			if t >= target.NextHop then
				local style = Coins.STYLES[target.Area]
				local to = nextSpot(target)
				if to then
					target.Data:SetAttribute("HopFrom", target.Pos)
					target.Data:SetAttribute("HopTo", to)
					target.Data:SetAttribute("HopStart", t)
					target.Pos = to
				end
				-- rest after landing before the next jump
				target.NextHop = t + style.Air + random:NextNumber(style.Rest[1], style.Rest[2])
			end
		end
	end
end)

-- Damage ---------------------------------------------------------------------------------

-- Living coins within `radius` of `position` in areas up to `unlocked`
-- (only the targets of one area: pets fight in the world the player is in)
function Breakables.near(position, radius, area)
	local list = {}
	for _, target in pairs(Breakables.Targets) do
		if target.Area == area and (target.Pos - position).Magnitude <= radius then
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
		target.Data:SetAttribute("Health", target.Health)
		return false
	end

	-- broken: reward the player, then a new one a little later
	local area = Config.AREAS[target.Area]
	local data = PlayerData.get(player)
	local coins = 0
	if data then
		coins = math.floor(area.Breakable.Coins * Config.coinGain(data))
		data.Coins += coins
		-- and EXP: stronger enemies in later worlds give more
		if Config.addExp(data, area.Breakable.Exp) > 0 then
			levelEvent:FireClient(player, data.Level)
		end
		PlayerData.sync(player)
	end
	coinEvent:FireClient(player, target.Pos + Vector3.new(0, 2.5, 0), coins, target.Area)
	Breakables.Targets[target.Id] = nil
	target.Data:Destroy()
	taken[target.Area][target.Spot] = nil
	pending[target.Area] += 1
	task.delay(RESPAWN_SECONDS, function()
		pending[target.Area] -= 1
		spawnOne(target.Area)
	end)
	return true
end

for i in ipairs(World.Areas) do
	taken[i] = {}
	pending[i] = 0
	for _ = 1, PER_AREA do
		spawnOne(i)
	end
end

-- Say what's there (in Studio's Output), so it's easy to check every world
-- has its targets
for i, area in ipairs(World.Areas) do
	local where = {}
	for _, target in pairs(Breakables.Targets) do
		if target.Area == i then
			table.insert(where, string.format("(%d, %.1f, %d)", target.Home.X, target.Home.Y, target.Home.Z))
		end
	end
	print(string.format("[Targets] %s: %d %s alive (%d spots) at %s", Config.AREAS[i].Name, alive(i), Config.AREAS[i].Breakable.Name, #area.Spots, table.concat(where, " ")))
end

-- Watchdog: every world always gets back to PER_AREA targets, whatever happens
task.spawn(function()
	while true do
		task.wait(2)
		for i in ipairs(World.Areas) do
			for _ = 1, PER_AREA - alive(i) - pending[i] do
				spawnOne(i)
			end
		end
	end
end)

-- How many targets are alive in an area
function Breakables.count(areaIndex)
	return alive(areaIndex)
end

return Breakables
