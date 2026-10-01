-- Rolling pets and equipping them. The server picks every roll (pet and
-- size); the client only asks and plays the reveal.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local PlayerData = require(script.Parent.PlayerData)
local Leaderboard = require(script.Parent.Leaderboards)

local remotes = ReplicatedStorage:WaitForChild("Remotes")

local function remote(className, name)
	local r = Instance.new(className)
	r.Name = name
	r.Parent = remotes
	return r
end

local rollFunction = remote("RemoteFunction", "Roll")
local equipFunction = remote("RemoteFunction", "Equip")
local equipBestFunction = remote("RemoteFunction", "EquipBest")

local random = Random.new()
local lastRoll = {} -- [player] = os.clock() of their last roll

local function onLoaded(player)
	if not PlayerData.get(player) then
		return
	end
	PlayerData.updateStrongest(player)
	PlayerData.sync(player)
	Leaderboard.send(player)
end

PlayerData.Loaded.Event:Connect(onLoaded)

-- Equips the strongest pets the player owns, as many as they have slots for
local function equipBest(data)
	local owned = {}
	for name, count in pairs(data.Pets) do
		for _ = 1, math.min(count, Config.maxEquipped(data)) do
			table.insert(owned, name)
		end
	end
	table.sort(owned, function(a, b)
		return Config.petPower(a) > Config.petPower(b)
	end)
	data.Equipped = {}
	for i = 1, math.min(#owned, Config.maxEquipped(data)) do
		table.insert(data.Equipped, owned[i])
	end
end

-- How many of this pet are equipped
local function equippedCount(data, name)
	local n = 0
	for _, equipped in ipairs(data.Equipped) do
		if equipped == name then
			n += 1
		end
	end
	return n
end

rollFunction.OnServerInvoke = function(player)
	local data = PlayerData.get(player)
	if not data then
		return nil
	end
	local now = os.clock()
	-- a little slack for network jitter
	if lastRoll[player] and now - lastRoll[player] < Config.rollCooldown(data) * 0.85 then
		return nil
	end
	lastRoll[player] = now

	-- the world you roll in changes the odds (every animal is possible anywhere)
	local world = PlayerData.worldOf(player)
	local results = {}
	local sizeLuck = Config.sizeLuck(data)
	-- the luck chain multiplier earned by the last spin applies to this one
	-- (Config.luck reads it); the exact luck of every roll goes back to the
	-- client, so the odds it shows are computed from the very same numbers
	local multiplier = Config.luckMultiplier(data)
	for _ = 1, Config.rollsAtOnce(data) do
		data.Rolls += 1
		local isBonus = data.Rolls % Config.BONUS_EVERY == 0
		local luck = Config.luck(data, isBonus, world)
		local rollSizeLuck = sizeLuck * (if isBonus then Config.BONUS_LUCK else 1)
		local pet = Config.roll(luck, random, world)
		local sizeIndex = Config.rollSize(rollSizeLuck, random)
		local name = Config.petName(pet.Name, sizeIndex)

		local isFirst = not data.Discovered[pet.Name]
		local isFirstOfSize = not data.Discovered[name]
		PlayerData.discover(data, name)
		data.Pets[name] = (data.Pets[name] or 0) + 1
		local best = data.Best and Config.PETS_BY_NAME[data.Best]
		if not best or pet.Odds > best.Odds then
			data.Best = pet.Name
		end
		table.insert(results, {
			Pet = pet.Name,
			Size = sizeIndex,
			Name = name,
			Bonus = isBonus,
			First = isFirst,
			FirstOfSize = isFirstOfSize,
			World = world,
			Luck = luck,
			SizeLuck = rollSizeLuck,
			Multiplier = multiplier,
		})
	end
	-- then this spin decides the next spin's multiplier
	data.LuckChain = Config.nextChain(multiplier, random)
	for _, result in ipairs(results) do
		result.NextMultiplier = data.LuckChain
	end

	-- Auto Hatch level 2 keeps the strongest team equipped
	if Config.upgradeLevel(data, "AutoHatch") >= 2 then
		equipBest(data)
	end
	PlayerData.updateStrongest(player)
	PlayerData.sync(player)
	return results
end

-- Equips a pet, or unequips it. Several copies of the same pet can be
-- equipped if you own them.
equipFunction.OnServerInvoke = function(player, name, unequip)
	local data = PlayerData.get(player)
	if not data or type(name) ~= "string" or not Config.petInfo(name) then
		return false
	end
	local index = table.find(data.Equipped, name)
	if unequip then
		if not index then
			return false
		end
		table.remove(data.Equipped, index)
	else
		if equippedCount(data, name) >= (data.Pets[name] or 0) or #data.Equipped >= Config.maxEquipped(data) then
			return false
		end
		table.insert(data.Equipped, name)
	end
	PlayerData.sync(player)
	return true
end

equipBestFunction.OnServerInvoke = function(player)
	local data = PlayerData.get(player)
	if not data then
		return false
	end
	equipBest(data)
	PlayerData.sync(player)
	return true
end

Players.PlayerRemoving:Connect(function(player)
	lastRoll[player] = nil
end)

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onLoaded, player)
end

return {}
