-- The incremental loop: energy from taps and trainers, buying, ascending and
-- offline earnings. The server owns every number; the client only asks.
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
local offlineEvent = remote("RemoteEvent", "Offline") -- server -> client: { Seconds, Gain }
local tapEvent = remote("RemoteEvent", "Tap")
local buyFunction = remote("RemoteFunction", "Buy")
local ascendFunction = remote("RemoteFunction", "Ascend")

local TICK = 0.5

local tapWindow = {} -- [player] = { Start = os.clock(), Count = n }

local function sendState(player)
	local data = PlayerData.get(player)
	if not data then
		return
	end
	stateEvent:FireClient(player, {
		Energy = data.Energy,
		RunEarned = data.RunEarned,
		TotalEarned = data.TotalEarned,
		Trainers = data.Trainers,
		TapLevel = data.TapLevel,
		Stars = data.Stars,
		Ascensions = data.Ascensions,
		BestPower = data.BestPower,
	})
end

local function earn(data, amount)
	if amount <= 0 or amount ~= amount then
		return
	end
	data.Energy += amount
	data.RunEarned += amount
	data.TotalEarned += amount
	data.BestPower = math.max(data.BestPower, Config.petPower(data))
end

local welcomed = {} -- [player] = true once offline earnings were given

local function onLoaded(player)
	local data = PlayerData.get(player)
	if not data or welcomed[player] then
		return
	end
	welcomed[player] = true
	-- offline earnings: the trainers kept working while they were away
	if data.LastOnline then
		local away = math.clamp(os.time() - data.LastOnline, 0, Config.OFFLINE_MAX)
		local gain = Config.perSecond(data) * away * Config.OFFLINE_RATE
		if away >= 60 and gain > 0 then
			earn(data, gain)
			offlineEvent:FireClient(player, { Seconds = away, Gain = gain })
		end
	end
	sendState(player)
	Leaderboard.send(player)
end

PlayerData.Loaded.Event:Connect(onLoaded)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onLoaded, player)
end

tapEvent.OnServerEvent:Connect(function(player)
	local data = PlayerData.get(player)
	if not data then
		return
	end
	local now = os.clock()
	local window = tapWindow[player]
	if not window or now - window.Start >= 1 then
		window = { Start = now, Count = 0 }
		tapWindow[player] = window
	end
	window.Count += 1
	if window.Count > Config.MAX_TAPS_PER_SECOND then
		return -- autoclicker speed, ignore
	end
	data.Taps += 1
	earn(data, Config.tapValue(data))
end)

buyFunction.OnServerInvoke = function(player, kind, id, amount)
	local data = PlayerData.get(player)
	if not data then
		return false
	end

	if kind == "Tap" then
		local cost = Config.tapCost(data.TapLevel)
		if data.Energy < cost then
			return false
		end
		data.Energy -= cost
		data.TapLevel += 1
	elseif kind == "Trainer" then
		local trainer = type(id) == "string" and Config.TRAINERS_BY_ID[id]
		if not trainer then
			return false
		end
		local limit = if amount == "Max" then 1000 elseif amount == 10 then 10 else 1
		local owned = data.Trainers[trainer.Id] or 0
		local count, total = Config.trainerBulk(trainer, owned, data.Energy, limit)
		-- x10 only buys if all 10 are affordable
		if count == 0 or (amount == 10 and count < 10) then
			return false
		end
		data.Energy -= total
		data.Trainers[trainer.Id] = owned + count
	else
		return false
	end

	sendState(player)
	return true
end

ascendFunction.OnServerInvoke = function(player)
	local data = PlayerData.get(player)
	if not data then
		return nil
	end
	local gain = Config.starsFor(data.RunEarned)
	if gain <= 0 then
		return nil
	end
	data.Stars += gain
	data.Ascensions += 1
	data.Energy = 0
	data.RunEarned = 0
	data.Trainers = {}
	data.TapLevel = 0
	sendState(player)
	return { Stars = gain, Form = Config.form(data.Ascensions).Name }
end

Players.PlayerRemoving:Connect(function(player)
	tapWindow[player] = nil
	welcomed[player] = nil
end)

-- trainers earn every tick
task.spawn(function()
	local last = os.clock()
	while true do
		task.wait(TICK)
		local now = os.clock()
		local dt = now - last
		last = now
		for _, player in ipairs(Players:GetPlayers()) do
			local data = PlayerData.get(player)
			if data then
				earn(data, Config.perSecond(data) * dt)
				sendState(player)
			end
		end
	end
end)

return {}
