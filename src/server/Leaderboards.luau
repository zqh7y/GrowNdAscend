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
		Title = "STRONGEST PETS",
		Color = Color3.fromRGB(255, 110, 90),
		Top = WORLD_ROWS,
		Value = function(data)
			return data.Strongest
		end,
		Text = function(value)
			return Config.formatNumber(value)
		end,
	},
	{
		Id = "Playtime",
		Title = "PLAYTIME",
		Color = Color3.fromRGB(60, 185, 255),
		Top = WORLD_ROWS,
		Value = function(data)
			return math.floor(data.Playtime)
		end,
		Text = formatTime,
	},
	{
		Id = "Rebirths",
		Title = "REBIRTHS",
		Color = Color3.fromRGB(170, 110, 255),
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

local MEDALS = { Color3.fromRGB(255, 200, 40), Color3.fromRGB(185, 195, 215), Color3.fromRGB(230, 145, 85) }
local INK = Color3.fromRGB(45, 50, 80) -- dark blue-grey text, easy to read on white

-- All three boards share this look: a coloured title bar, then 10 rows on a
-- white screen with big, bold text. The screen part is 10 x 13.4 studs.
local function makeWorldBoard(board, screen)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40 -- 400 x 536
	gui.LightInfluence = 0
	gui.Parent = screen

	local header = Instance.new("Frame")
	header.Size = UDim2.new(1, 0, 0, 64)
	header.BackgroundColor3 = board.Color
	header.BorderSizePixel = 0
	header.Parent = gui
	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Position = UDim2.fromOffset(14, 12)
	title.Size = UDim2.new(1, -28, 0, 40)
	title.Font = Enum.Font.GothamBlack
	title.TextScaled = true
	title.TextColor3 = Color3.new(1, 1, 1)
	title.Text = board.Title
	title.Parent = header

	local rows = {}
	for i = 1, WORLD_ROWS do
		local row = Instance.new("Frame")
		row.Position = UDim2.fromOffset(10, 72 + (i - 1) * 46)
		row.Size = UDim2.new(1, -20, 0, 42)
		row.BackgroundColor3 = if i % 2 == 1 then Color3.fromRGB(242, 244, 252) else Color3.new(1, 1, 1)
		row.BorderSizePixel = 0
		row.Visible = false
		row.Parent = gui
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 12)
		corner.Parent = row

		local rank = Instance.new("TextLabel")
		rank.Position = UDim2.fromOffset(6, 6)
		rank.Size = UDim2.fromOffset(30, 30)
		rank.BackgroundColor3 = MEDALS[i] or Color3.new(1, 1, 1)
		rank.BackgroundTransparency = if MEDALS[i] then 0 else 1
		rank.Font = Enum.Font.GothamBlack
		rank.TextScaled = true
		rank.TextColor3 = if MEDALS[i] then Color3.new(1, 1, 1) else Color3.fromRGB(150, 155, 180)
		rank.Text = tostring(i)
		rank.Parent = row
		local round = corner:Clone()
		round.CornerRadius = UDim.new(0.5, 0)
		round.Parent = rank
		local pad = Instance.new("UIPadding")
		pad.PaddingTop = UDim.new(0, 6)
		pad.PaddingBottom = UDim.new(0, 6)
		pad.Parent = rank

		local name = Instance.new("TextLabel")
		name.BackgroundTransparency = 1
		name.Position = UDim2.fromOffset(44, 9)
		name.Size = UDim2.new(1, -170, 0, 24)
		name.Font = Enum.Font.GothamBold
		name.TextScaled = true
		name.TextXAlignment = Enum.TextXAlignment.Left
		name.TextColor3 = INK
		name.Parent = row

		local value = Instance.new("TextLabel")
		value.BackgroundTransparency = 1
		value.AnchorPoint = Vector2.new(1, 0)
		value.Position = UDim2.new(1, -10, 0, 9)
		value.Size = UDim2.fromOffset(118, 24)
		value.Font = Enum.Font.GothamBlack
		value.TextScaled = true
		value.TextXAlignment = Enum.TextXAlignment.Right
		value.TextColor3 = board.Color:Lerp(Color3.new(0, 0, 0), 0.15)
		value.Parent = row

		rows[i] = { Frame = row, Name = name, Value = value }
	end

	-- shown until someone is on the board
	local empty = Instance.new("TextLabel")
	empty.BackgroundTransparency = 1
	empty.Position = UDim2.fromOffset(20, 240)
	empty.Size = UDim2.new(1, -40, 0, 30)
	empty.Font = Enum.Font.GothamBold
	empty.TextScaled = true
	empty.TextColor3 = Color3.fromRGB(160, 165, 190)
	empty.Text = "Be the first!"
	empty.Parent = gui
	board.Empty = empty

	board.Rows = rows
end

local function drawWorldBoard(board, list)
	board.Empty.Visible = #list == 0
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
