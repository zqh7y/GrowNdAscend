-- Global "Most Rolls" leaderboard. Every server is solo, so this is where
-- players see each other: each player's total rolls go into an
-- OrderedDataStore and the top 50 are sent to the client every minute.
-- Without DataStore access (Studio) it still shows the players in this server.
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerData = require(script.Parent.PlayerData)

local Leaderboard = {}

local TOP = 50
local REFRESH_SECONDS = 60

local remote = Instance.new("RemoteEvent")
remote.Name = "Leaderboard"
remote.Parent = ReplicatedStorage:WaitForChild("Remotes")

local okStore, store = pcall(function()
	return DataStoreService:GetOrderedDataStore("MostRolls_v1")
end)
if not okStore then
	store = nil
end

local written = {} -- [userId] = rolls we last saved
local globalTop = {} -- { { UserId, Rolls } } from the last refresh
local nameCache = {} -- [userId] = name

local function userName(userId)
	local online = Players:GetPlayerByUserId(userId)
	if online then
		return online.DisplayName
	end
	if nameCache[userId] == nil then
		local ok, name = pcall(Players.GetNameFromUserIdAsync, Players, userId)
		nameCache[userId] = if ok then name else "Player"
	end
	return nameCache[userId]
end

local function writeScore(userId, rolls)
	if not store or rolls <= 0 or written[userId] == rolls then
		return
	end
	local ok, err = pcall(store.SetAsync, store, tostring(userId), rolls)
	if ok then
		written[userId] = rolls
	else
		warn("Leaderboard write failed:", err)
	end
end

local function readTop()
	if not store then
		return
	end
	local ok, pages = pcall(store.GetSortedAsync, store, false, TOP)
	if not ok then
		warn("Leaderboard read failed:", pages)
		return
	end
	local top = {}
	for _, entry in ipairs(pages:GetCurrentPage()) do
		local userId = tonumber(entry.key)
		if userId then
			table.insert(top, { UserId = userId, Rolls = entry.value })
		end
	end
	globalTop = top
end

-- The global list with this server's players' live counts mixed in
local function build()
	local byUser = {}
	for _, entry in ipairs(globalTop) do
		byUser[entry.UserId] = entry.Rolls
	end
	for _, player in ipairs(Players:GetPlayers()) do
		local data = PlayerData.get(player)
		if data and data.Rolls > 0 then
			byUser[player.UserId] = math.max(byUser[player.UserId] or 0, data.Rolls)
		end
	end

	local list = {}
	for userId, rolls in pairs(byUser) do
		table.insert(list, { UserId = userId, Rolls = rolls })
	end
	table.sort(list, function(a, b)
		return a.Rolls > b.Rolls
	end)
	for i = #list, TOP + 1, -1 do
		list[i] = nil
	end
	for _, entry in ipairs(list) do
		entry.Name = userName(entry.UserId)
	end
	return list
end

function Leaderboard.send(player)
	remote:FireClient(player, build())
end

task.spawn(function()
	while true do
		for _, player in ipairs(Players:GetPlayers()) do
			local data = PlayerData.get(player)
			if data then
				writeScore(player.UserId, data.Rolls)
			end
		end
		readTop()
		remote:FireAllClients(build())
		task.wait(REFRESH_SECONDS)
	end
end)

PlayerData.onRemoving(function(player, data)
	writeScore(player.UserId, data.Rolls) -- their final count before they go
	written[player.UserId] = nil
end)

return Leaderboard
