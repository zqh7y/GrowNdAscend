-- Global leaderboards. Every server is solo, so these are where players see
-- each other. Each board keeps its stat in an OrderedDataStore, refreshed
-- every minute and mixed with the live values of the player in this server
-- (so they also work in Studio without DataStore access).
--   Rolls:     shown in the TOP panel on the client
--   Strongest, Playtime, Rebirths: the three boards in the Forest
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local PlayerData = require(script.Parent.PlayerData)
local World = require(script.Parent.World)

local Leaderboards = {}

local REFRESH_SECONDS = 60
local WORLD_ROWS = 10

local remote = Instance.new("RemoteEvent")
remote.Name = "Leaderboard" -- server -> client: the Most Rolls list
remote.Parent = ReplicatedStorage:WaitForChild("Remotes")

local function formatTime(seconds)
	local hours = math.floor(seconds / 3600)
	local minutes = math.floor(seconds % 3600 / 60)
	if hours > 0 then
		return hours .. "h " .. minutes .. "m"
	end
	return minutes .. "m"
end

local BOARDS = {
	{
		Id = "Rolls",
		Top = 50,
		Value = function(data)
			return data.Rolls
		end,
	},
	{
		Id = "Strongest",
		Title = "STRONGEST PET",
		Color = Color3.fromRGB(255, 120, 90),
		Top = WORLD_ROWS,
		Value = function(data)
			return data.Strongest
		end,
		Text = function(value)
			return Config.formatNumber(value) .. " power"
		end,
	},
	{
		Id = "Playtime",
		Title = "MOST PLAYTIME",
		Color = Color3.fromRGB(80, 220, 255),
		Top = WORLD_ROWS,
		Value = function(data)
			return math.floor(data.Playtime)
		end,
		Text = formatTime,
	},
	{
		Id = "Rebirths",
		Title = "MOST REBIRTHS",
		Color = Color3.fromRGB(190, 120, 255),
		Top = WORLD_ROWS,
		Value = function(data)
			return data.Rebirths
		end,
		Text = function(value)
			return tostring(value)
		end,
	},
}

for _, board in ipairs(BOARDS) do
	local ok, store = pcall(DataStoreService.GetOrderedDataStore, DataStoreService, "Top" .. board.Id .. "_v1")
	board.Store = if ok then store else nil
	board.Global = {} -- { { UserId, Value } } from the last refresh
	board.Written = {} -- [userId] = value we last saved
end

local nameCache = {}
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

local function write(board, userId, value)
	if not board.Store or value <= 0 or board.Written[userId] == value then
		return
	end
	local ok, err = pcall(board.Store.SetAsync, board.Store, tostring(userId), value)
	if ok then
		board.Written[userId] = value
	else
		warn("Leaderboard write failed:", board.Id, err)
	end
end

local function read(board)
	if not board.Store then
		return
	end
	local ok, pages = pcall(board.Store.GetSortedAsync, board.Store, false, board.Top)
	if not ok then
		warn("Leaderboard read failed:", board.Id, pages)
		return
	end
	local top = {}
	for _, entry in ipairs(pages:GetCurrentPage()) do
		local userId = tonumber(entry.key)
		if userId then
			table.insert(top, { UserId = userId, Value = entry.value })
		end
	end
	board.Global = top
end

-- The global list with the live values of players in this server mixed in
local function build(board)
	local byUser = {}
	for _, entry in ipairs(board.Global) do
		byUser[entry.UserId] = entry.Value
	end
	for _, player in ipairs(Players:GetPlayers()) do
		local data = PlayerData.get(player)
		if data then
			local value = board.Value(data)
			if value > 0 then
				byUser[player.UserId] = math.max(byUser[player.UserId] or 0, value)
			end
		end
	end
	local list = {}
	for userId, value in pairs(byUser) do
		table.insert(list, { UserId = userId, Value = value })
	end
	table.sort(list, function(a, b)
		return a.Value > b.Value
	end)
	for i = #list, board.Top + 1, -1 do
		list[i] = nil
	end
	for _, entry in ipairs(list) do
		entry.Name = userName(entry.UserId)
	end
	return list
end

-- World boards ------------------------------------------------------------------

local MEDALS = { Color3.fromRGB(255, 205, 80), Color3.fromRGB(200, 210, 225), Color3.fromRGB(225, 150, 95) }

local function makeWorldBoard(board, screen)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40 -- 600 x 760
	gui.LightInfluence = 0
	gui.Brightness = 1.4
	gui.Parent = screen

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Position = UDim2.fromOffset(20, 22)
	title.Size = UDim2.new(1, -40, 0, 54)
	title.Font = Enum.Font.GothamBlack
	title.TextScaled = true
	title.TextColor3 = board.Color
	title.Text = board.Title
	title.Parent = gui

	local rows = {}
	for i = 1, WORLD_ROWS do
		local row = Instance.new("Frame")
		row.Position = UDim2.fromOffset(20, 96 + (i - 1) * 64)
		row.Size = UDim2.new(1, -40, 0, 56)
		row.BackgroundColor3 = Color3.fromRGB(36, 40, 72)
		row.BackgroundTransparency = if i % 2 == 1 then 0.2 else 0.6
		row.BorderSizePixel = 0
		row.Visible = false
		row.Parent = gui
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 14)
		corner.Parent = row

		local rank = Instance.new("TextLabel")
		rank.Position = UDim2.fromOffset(10, 10)
		rank.Size = UDim2.fromOffset(36, 36)
		rank.BackgroundColor3 = MEDALS[i] or Color3.new(0, 0, 0)
		rank.BackgroundTransparency = if MEDALS[i] then 0 else 1
		rank.Font = Enum.Font.GothamBold
		rank.TextScaled = true
		rank.TextColor3 = if MEDALS[i] then Color3.fromRGB(20, 20, 35) else Color3.fromRGB(150, 156, 195)
		rank.Text = tostring(i)
		rank.Parent = row
		local round = corner:Clone()
		round.CornerRadius = UDim.new(0.5, 0)
		round.Parent = rank
		local pad = Instance.new("UIPadding")
		pad.PaddingTop = UDim.new(0, 7)
		pad.PaddingBottom = UDim.new(0, 7)
		pad.Parent = rank

		local name = Instance.new("TextLabel")
		name.BackgroundTransparency = 1
		name.Position = UDim2.fromOffset(60, 12)
		name.Size = UDim2.new(1, -250, 0, 32)
		name.Font = Enum.Font.GothamMedium
		name.TextScaled = true
		name.TextXAlignment = Enum.TextXAlignment.Left
		name.TextColor3 = Color3.fromRGB(240, 242, 255)
		name.Parent = row

		local value = Instance.new("TextLabel")
		value.BackgroundTransparency = 1
		value.AnchorPoint = Vector2.new(1, 0)
		value.Position = UDim2.new(1, -14, 0, 12)
		value.Size = UDim2.fromOffset(180, 32)
		value.Font = Enum.Font.GothamBold
		value.TextScaled = true
		value.TextXAlignment = Enum.TextXAlignment.Right
		value.TextColor3 = board.Color
		value.Parent = row

		rows[i] = { Frame = row, Name = name, Value = value }
	end
	board.Rows = rows
end

local function drawWorldBoard(board, list)
	for i, row in ipairs(board.Rows) do
		local entry = list[i]
		row.Frame.Visible = entry ~= nil
		if entry then
			row.Name.Text = entry.Name
			row.Value.Text = board.Text(entry.Value)
		end
	end
end

for _, board in ipairs(BOARDS) do
	local screen = World.Boards[board.Id]
	if screen then
		makeWorldBoard(board, screen)
	end
end

-- Refreshing ----------------------------------------------------------------------

local rollsBoard = BOARDS[1]

local function sendRolls(target, list)
	local entries = {}
	for _, entry in ipairs(list) do
		table.insert(entries, { UserId = entry.UserId, Name = entry.Name, Rolls = entry.Value })
	end
	if target then
		remote:FireClient(target, entries)
	else
		remote:FireAllClients(entries)
	end
end

function Leaderboards.send(player)
	sendRolls(player, build(rollsBoard))
end

local function refresh(readGlobal)
	for _, board in ipairs(BOARDS) do
		if readGlobal then
			for _, player in ipairs(Players:GetPlayers()) do
				local data = PlayerData.get(player)
				if data then
					write(board, player.UserId, board.Value(data))
				end
			end
			read(board)
		end
		local list = build(board)
		if board.Rows then
			drawWorldBoard(board, list)
		else
			sendRolls(nil, list)
		end
	end
end

task.spawn(function()
	local sinceGlobal = math.huge
	while true do
		-- DataStores once a minute; this server's live values every 10s
		sinceGlobal += 10
		local readGlobal = sinceGlobal >= REFRESH_SECONDS
		if readGlobal then
			sinceGlobal = 0
		end
		refresh(readGlobal)
		task.wait(10)
	end
end)

PlayerData.onRemoving(function(player, data)
	for _, board in ipairs(BOARDS) do
		write(board, player.UserId, board.Value(data)) -- their final values before they go
		board.Written[player.UserId] = nil
	end
end)

return Leaderboards
