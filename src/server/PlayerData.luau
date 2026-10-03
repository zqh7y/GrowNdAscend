-- Loads and saves player data. Other server modules change the table from
-- PlayerData.get directly.
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local stateEvent = Instance.new("RemoteEvent")
stateEvent.Name = "State" -- server -> client: the player's data
stateEvent.Parent = ReplicatedStorage:WaitForChild("Remotes")

local store = DataStoreService:GetDataStore("RngData_release1")
local AUTOSAVE_SECONDS = 60

local PlayerData = {}

-- Fires (player) after data loads. (Bindables copy tables, so listeners use
-- PlayerData.get to reach the real data.)
PlayerData.Loaded = Instance.new("BindableEvent")

local DEFAULT = {
	Rolls = 0,
	Pets = {}, -- [pet name with size, e.g. "Huge Tiger"] = how many you have
	Equipped = {}, -- names of the pets following you (they add luck)
	Best = nil, -- name of the rarest pet ever rolled
	BestOdds = 0, -- the rarest pet ever hatched: its "1 in N" counting its size
	Coins = 0,
	Unlocked = 1, -- highest area unlocked
	Rebirths = 0,
	Level = 1, -- from EXP for defeating enemies (never resets)
	Exp = 0, -- EXP towards the next level
	Playtime = 0, -- seconds played
	Upgrades = {}, -- [upgrade id] = level bought in the upgrade tree
	Discovered = {}, -- [animal name] = true once found (the Index)
	Strongest = 0, -- power of the strongest pet ever owned
	LuckChain = 1, -- the luck boost waiting for the next roll (x2, x4 ... x1024)
	Milestones = {}, -- [Index milestone id] = true once its reward is claimed
	Obtained = {}, -- [pet name] = the roll number it was last hatched on (newest first)
	LuckBoard = {}, -- [Luck Board row id] = level bought
	BossUpgrades = {}, -- [Boss Shop upgrade id] = level bought
	PetLevels = {}, -- [pet name] = its level (2..10; missing = 1), from the Pet Upgrades stand
	Seen = {}, -- [tutorial key] = true once shown (the first-time tutorial, each world's tour)
}

local sessionData = {} -- [player] = data while they're in game
local loadFailed = {} -- [player] = true: don't overwrite their save
local removingHooks = {}

-- Marks a pet as found in the Index: its size ("Huge Tiger") and the animal
-- itself ("Tiger", which is what the 100-animal count uses)
function PlayerData.discover(data, name)
	local pet = Config.petInfo(name)
	if pet then
		data.Discovered[pet.Name] = true
		data.Discovered[Config.displayName(name)] = true -- (an aura pet counts as its plain pet)
	end
end

-- The world a player is standing in (for the hatch odds), never above what
-- they've unlocked
function PlayerData.worldOf(player)
	local data = PlayerData.get(player)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local world = if root then Config.areaAt(root.Position.X) else 1
	return math.min(world, if data then data.Unlocked else 1)
end

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
	data.Upgrades = {}
	data.Discovered = {}
	data.Milestones = {}
	data.Obtained = {}
	data.LuckBoard = {}
	data.BossUpgrades = {}
	data.PetLevels = {}
	data.Seen = {}
	if ok and saved then
		for k, v in pairs(saved) do
			data[k] = v
		end
	end
	-- older saves kept huge pets in their own list; now every size lives in Pets
	if data.Huges then
		for name, count in pairs(data.Huges) do
			local key = Config.petName(name, 2)
			data.Pets[key] = (data.Pets[key] or 0) + count
		end
		data.Huges = nil
	end
	-- there are at most 8 rebirths (older saves could have more)
	data.Rebirths = math.min(data.Rebirths or 0, Config.MAX_REBIRTHS)
	-- the Index: everything ever owned counts as discovered (older saves)
	for name in pairs(data.Pets) do
		PlayerData.discover(data, name)
	end
	-- the fusion machine is gone (it's the aura machine now): a fusion still
	-- running gives its 5 pets back
	if type(data.Fusion) == "table" and type(data.Fusion.Pet) == "string" and Config.petInfo(data.Fusion.Pet) then
		data.Pets[data.Fusion.Pet] = (data.Pets[data.Fusion.Pet] or 0) + 5
	end
	data.Fusion = nil

	if type(data.PetLevels) ~= "table" then
		data.PetLevels = {}
	end
	-- older saves: the best pet's own odds
	if type(data.BestOdds) ~= "number" then
		data.BestOdds = 0
	end
	local bestPet = data.Best and Config.PETS_BY_NAME[data.Best]
	if bestPet and data.BestOdds < bestPet.Odds then
		data.BestOdds = bestPet.Odds
	end

	-- shows Rolls, Coins and the rarest pet hatched on the player list
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	local rolls = Instance.new("IntValue")
	rolls.Name = "Rolls"
	rolls.Value = data.Rolls
	rolls.Parent = stats
	local coins = Instance.new("StringValue")
	coins.Name = "Coins"
	coins.Value = Config.formatNumber(data.Coins)
	coins.Parent = stats
	local best = Instance.new("StringValue")
	best.Name = "Best"
	best.Value = PlayerData.bestText(data)
	best.Parent = stats
	stats.Parent = player

	if player.Parent then
		sessionData[player] = data
		PlayerData.Loaded:Fire(player)
	end
end

-- The player list's Best: the rarest pet hatched as "1/964.8M" ("-" if none)
function PlayerData.bestText(data)
	local odds = data.BestOdds or 0
	if odds < 1 then
		return "-"
	end
	return "1/" .. Config.formatNumber(math.floor(odds + 0.5))
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

-- Sends the player's data to their client and updates the player list
function PlayerData.sync(player)
	local data = sessionData[player]
	if not data then
		return
	end
	local stats = player:FindFirstChild("leaderstats")
	if stats then
		stats.Rolls.Value = data.Rolls
		stats.Coins.Value = Config.formatNumber(data.Coins)
		stats.Best.Value = PlayerData.bestText(data)
	end
	stateEvent:FireClient(player, {
		Rolls = data.Rolls,
		Pets = data.Pets,
		Equipped = data.Equipped,
		Best = data.Best,
		Coins = data.Coins,
		Unlocked = data.Unlocked,
		Rebirths = data.Rebirths,
		Level = data.Level,
		Exp = data.Exp,
		Upgrades = data.Upgrades,
		Discovered = data.Discovered,
		LuckChain = data.LuckChain or 1,
		Milestones = data.Milestones or {},
		Obtained = data.Obtained or {},
		LuckBoard = data.LuckBoard or {},
		BossUpgrades = data.BossUpgrades or {},
		PetLevels = data.PetLevels or {},
		Seen = data.Seen or {},
		MegaReady = data.MegaReady,
		MegaMult = data.MegaMult,
		MegaRolls = data.MegaRolls or {},
		Items = data.Items or {},
		ActiveBoosts = data.ActiveBoosts or {},
		BoostReady = data.BoostReady,
		ZoneLuck = data.ZoneLuck,
		ZoneCoins = data.ZoneCoins,
		ServerTime = os.time(),
	})
end

-- Recomputes the strongest pet power (for the leaderboard) after pets change
function PlayerData.updateStrongest(player)
	local data = sessionData[player]
	if not data then
		return
	end
	for name, count in pairs(data.Pets) do
		if count > 0 then
			data.Strongest = math.max(data.Strongest, Config.petPower(name))
		end
	end
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

-- count playtime
task.spawn(function()
	local last = os.clock()
	while true do
		task.wait(5)
		local now = os.clock()
		for _, data in pairs(sessionData) do
			data.Playtime += now - last
		end
		last = now
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
