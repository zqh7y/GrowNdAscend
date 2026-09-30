-- Loads and saves player data. Other server modules change the table from
-- PlayerData.get directly.
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local store = DataStoreService:GetDataStore("RngData_v1")
local AUTOSAVE_SECONDS = 60

local PlayerData = {}

-- Fires (player) after data loads. (Bindables copy tables, so listeners use
-- PlayerData.get to reach the real data.)
PlayerData.Loaded = Instance.new("BindableEvent")

local DEFAULT = {
	Rolls = 0,
	Pets = {}, -- [pet name] = how many you've rolled
	Equipped = {}, -- names of the pets following you (they add luck)
	Best = nil, -- name of the rarest pet ever rolled
}

local sessionData = {} -- [player] = data while they're in game
local loadFailed = {} -- [player] = true: don't overwrite their save
local removingHooks = {}

local function load(player)
	local ok, saved = pcall(function()
		return store:GetAsync("user_" .. player.UserId)
	end)
	if not ok then
		warn("Load failed for", player.Name, saved)
		loadFailed[player] = true
	end

	local data = table.clone(DEFAULT)
	data.Pets = {}
	data.Equipped = {}
	if ok and saved then
		for k, v in pairs(saved) do
			data[k] = v
		end
	end

	-- shows Rolls on the player list
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	local rolls = Instance.new("IntValue")
	rolls.Name = "Rolls"
	rolls.Value = data.Rolls
	rolls.Parent = stats
	stats.Parent = player

	if player.Parent then
		sessionData[player] = data
		PlayerData.Loaded:Fire(player)
	end
end

local function save(player)
	local data = sessionData[player]
	if not data or loadFailed[player] then
		return
	end
	local ok, err = pcall(function()
		store:SetAsync("user_" .. player.UserId, data)
	end)
	if not ok then
		warn("Save failed for", player.Name, err)
	end
end

function PlayerData.get(player)
	return sessionData[player]
end

-- Runs fn(player, data) when a player leaves, before their data is dropped
function PlayerData.onRemoving(fn)
	table.insert(removingHooks, fn)
end

Players.PlayerAdded:Connect(load)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(load, player)
end

Players.PlayerRemoving:Connect(function(player)
	local data = sessionData[player]
	if data then
		for _, fn in ipairs(removingHooks) do
			task.spawn(fn, player, data)
		end
	end
	save(player)
	sessionData[player] = nil
	loadFailed[player] = nil
end)

game:BindToClose(function()
	local threads = {}
	for player in pairs(sessionData) do
		table.insert(threads, task.spawn(save, player))
	end
	-- give the saves a few seconds to finish
	local start = os.clock()
	while os.clock() - start < 5 do
		local busy = false
		for _, thread in ipairs(threads) do
			if coroutine.status(thread) ~= "dead" then
				busy = true
			end
		end
		if not busy then
			break
		end
		task.wait(0.1)
	end
end)

task.spawn(function()
	while true do
		task.wait(AUTOSAVE_SECONDS)
		for player in pairs(sessionData) do
			task.spawn(save, player)
		end
	end
end)

return PlayerData
