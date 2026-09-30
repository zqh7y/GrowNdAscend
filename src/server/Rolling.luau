-- Rolling pets and equipping them. The server picks every roll; the client
-- only asks and plays the reveal.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local PlayerData = require(script.Parent.PlayerData)
local Leaderboard = require(script.Parent.Leaderboard)

local remotes = ReplicatedStorage:WaitForChild("Remotes")

local function remote(className, name)
	local r = Instance.new(className)
	r.Name = name
	r.Parent = remotes
	return r
end

local stateEvent = remote("RemoteEvent", "State") -- server -> client: the player's data
local rollFunction = remote("RemoteFunction", "Roll")
local equipFunction = remote("RemoteFunction", "Equip")

local random = Random.new()
local lastRoll = {} -- [player] = os.clock() of their last roll

local function sendState(player)
	local data = PlayerData.get(player)
	if data then
		stateEvent:FireClient(player, {
			Rolls = data.Rolls,
			Pets = data.Pets,
			Equipped = data.Equipped,
			Best = data.Best,
		})
	end
end

local function onLoaded(player)
	if not PlayerData.get(player) then
		return
	end
	sendState(player)
	Leaderboard.send(player)
end

PlayerData.Loaded.Event:Connect(onLoaded)

rollFunction.OnServerInvoke = function(player)
	local data = PlayerData.get(player)
	if not data then
		return nil
	end
	local now = os.clock()
	-- a little slack for network jitter
	if lastRoll[player] and now - lastRoll[player] < Config.ROLL_COOLDOWN * 0.9 then
		return nil
	end
	lastRoll[player] = now

	data.Rolls += 1
	local isBonus = data.Rolls % Config.BONUS_EVERY == 0
	local luck = Config.luck(data.Equipped, isBonus)
	local pet = Config.roll(luck, random)

	data.Pets[pet.Name] = (data.Pets[pet.Name] or 0) + 1
	local best = data.Best and Config.PETS_BY_NAME[data.Best]
	local isNewBest = not best or pet.Odds > best.Odds
	if isNewBest then
		data.Best = pet.Name
	end

	local stats = player:FindFirstChild("leaderstats")
	if stats then
		stats.Rolls.Value = data.Rolls
	end

	sendState(player)
	return {
		Pet = pet.Name,
		Bonus = isBonus,
		Luck = luck,
		NewBest = isNewBest,
		First = data.Pets[pet.Name] == 1,
	}
end

-- Equips the pet, or unequips it if it's already equipped
equipFunction.OnServerInvoke = function(player, name)
	local data = PlayerData.get(player)
	if not data or type(name) ~= "string" or not data.Pets[name] then
		return false
	end
	local index = table.find(data.Equipped, name)
	if index then
		table.remove(data.Equipped, index)
	elseif #data.Equipped < Config.MAX_EQUIPPED then
		table.insert(data.Equipped, name)
	else
		return false
	end
	sendState(player)
	return true
end

Players.PlayerRemoving:Connect(function(player)
	lastRoll[player] = nil
end)

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onLoaded, player)
end

return {}
