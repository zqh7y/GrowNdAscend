-- Pets, rarities, sizes, luck, upgrades, combat and formatting, shared by the
-- server and the client so the UI always shows exactly what the server does.
local Config = {}

-- Shown on screen and in Output, so it's easy to tell which version is running
Config.BUILD = "build 9 (clean UI, new hatch, blocky pets)"

-- Pets -------------------------------------------------------------------------

-- Every animal in the game (the Index has all 70), from most common to
-- rarest. Odds is "1 in Odds"; World is where it lives: you can only roll it
-- once that world is unlocked, and each world's animals cover its own band
-- of rarity (and so of power), which is what the progression is built on.
Config.PETS = {
	-- World 1: Forest
	{ Name = "Dog", Odds = 2, World = 1, Color = Color3.fromRGB(200, 150, 100) },
	{ Name = "Cat", Odds = 3, World = 1, Color = Color3.fromRGB(255, 170, 80) },
	{ Name = "Bunny", Odds = 4, World = 1, Color = Color3.fromRGB(245, 240, 240) },
	{ Name = "Chick", Odds = 5, World = 1, Color = Color3.fromRGB(255, 225, 70) },
	{ Name = "Mouse", Odds = 7, World = 1, Color = Color3.fromRGB(170, 170, 180) },
	{ Name = "Hamster", Odds = 9, World = 1, Color = Color3.fromRGB(240, 190, 120) },
	{ Name = "Duck", Odds = 12, World = 1, Color = Color3.fromRGB(255, 235, 120) },
	{ Name = "Frog", Odds = 16, World = 1, Color = Color3.fromRGB(110, 210, 90) },
	{ Name = "Piglet", Odds = 21, World = 1, Color = Color3.fromRGB(255, 170, 190) },
	{ Name = "Lamb", Odds = 28, World = 1, Color = Color3.fromRGB(250, 248, 240) },
	{ Name = "Squirrel", Odds = 38, World = 1, Color = Color3.fromRGB(205, 120, 60) },
	{ Name = "Hedgehog", Odds = 50, World = 1, Color = Color3.fromRGB(170, 130, 100) },
	{ Name = "Fox", Odds = 70, World = 1, Color = Color3.fromRGB(240, 110, 40) },
	{ Name = "Raccoon", Odds = 90, World = 1, Color = Color3.fromRGB(150, 150, 160) },
	{ Name = "Deer", Odds = 125, World = 1, Color = Color3.fromRGB(200, 140, 90) },
	{ Name = "Owl", Odds = 170, World = 1, Color = Color3.fromRGB(140, 100, 70) },
	{ Name = "Bear", Odds = 225, World = 1, Color = Color3.fromRGB(150, 95, 60) },
	{ Name = "Wolf", Odds = 300, World = 1, Color = Color3.fromRGB(120, 130, 160) },
	{ Name = "Parrot", Odds = 400, World = 1, Color = Color3.fromRGB(70, 200, 110) },
	{ Name = "Moose", Odds = 550, World = 1, Color = Color3.fromRGB(130, 90, 60) },
	{ Name = "Unicorn", Odds = 750, World = 1, Color = Color3.fromRGB(255, 170, 230) },
	{ Name = "Forest Guardian", Odds = 1000, World = 1, Color = Color3.fromRGB(90, 220, 140) },
	-- World 2: Sahara
	{ Name = "Camel", Odds = 1250, World = 2, Color = Color3.fromRGB(230, 180, 115) },
	{ Name = "Meerkat", Odds = 1500, World = 2, Color = Color3.fromRGB(215, 170, 110) },
	{ Name = "Fennec Fox", Odds = 1800, World = 2, Color = Color3.fromRGB(250, 210, 150) },
	{ Name = "Lizard", Odds = 2200, World = 2, Color = Color3.fromRGB(120, 200, 90) },
	{ Name = "Tortoise", Odds = 2600, World = 2, Color = Color3.fromRGB(130, 170, 90) },
	{ Name = "Scorpion", Odds = 3200, World = 2, Color = Color3.fromRGB(230, 110, 60) },
	{ Name = "Cobra", Odds = 3800, World = 2, Color = Color3.fromRGB(200, 170, 60) },
	{ Name = "Vulture", Odds = 4500, World = 2, Color = Color3.fromRGB(120, 100, 110) },
	{ Name = "Hyena", Odds = 5500, World = 2, Color = Color3.fromRGB(200, 170, 120) },
	{ Name = "Cheetah", Odds = 6500, World = 2, Color = Color3.fromRGB(250, 195, 90) },
	{ Name = "Lion", Odds = 8000, World = 2, Color = Color3.fromRGB(240, 175, 70) },
	{ Name = "Falcon", Odds = 9500, World = 2, Color = Color3.fromRGB(150, 120, 100) },
	{ Name = "Golden Scarab", Odds = 11500, World = 2, Color = Color3.fromRGB(255, 200, 50) },
	{ Name = "Anubis Jackal", Odds = 14000, World = 2, Color = Color3.fromRGB(50, 55, 80) },
	{ Name = "Griffin", Odds = 17000, World = 2, Color = Color3.fromRGB(230, 200, 120) },
	{ Name = "Sphinx", Odds = 20000, World = 2, Color = Color3.fromRGB(245, 210, 140) },
	-- World 3: Frozen Peaks
	{ Name = "Penguin", Odds = 25000, World = 3, Color = Color3.fromRGB(60, 80, 120) },
	{ Name = "Snow Hare", Odds = 30000, World = 3, Color = Color3.fromRGB(245, 248, 255) },
	{ Name = "Arctic Fox", Odds = 37000, World = 3, Color = Color3.fromRGB(235, 240, 250) },
	{ Name = "Seal", Odds = 45000, World = 3, Color = Color3.fromRGB(170, 180, 200) },
	{ Name = "Husky", Odds = 55000, World = 3, Color = Color3.fromRGB(150, 160, 180) },
	{ Name = "Snowy Owl", Odds = 67000, World = 3, Color = Color3.fromRGB(248, 250, 255) },
	{ Name = "Walrus", Odds = 82000, World = 3, Color = Color3.fromRGB(180, 130, 100) },
	{ Name = "Reindeer", Odds = 100000, World = 3, Color = Color3.fromRGB(170, 120, 80) },
	{ Name = "Polar Bear", Odds = 120000, World = 3, Color = Color3.fromRGB(250, 250, 245) },
	{ Name = "Snow Leopard", Odds = 150000, World = 3, Color = Color3.fromRGB(230, 232, 240) },
	{ Name = "Orca", Odds = 180000, World = 3, Color = Color3.fromRGB(40, 45, 70) },
	{ Name = "Narwhal", Odds = 220000, World = 3, Color = Color3.fromRGB(150, 180, 220) },
	{ Name = "Yeti", Odds = 270000, World = 3, Color = Color3.fromRGB(235, 245, 255) },
	{ Name = "Mammoth", Odds = 330000, World = 3, Color = Color3.fromRGB(150, 105, 75) },
	{ Name = "Ice Phoenix", Odds = 400000, World = 3, Color = Color3.fromRGB(140, 220, 255) },
	{ Name = "Frost Dragon", Odds = 500000, World = 3, Color = Color3.fromRGB(120, 200, 255) },
	-- World 4: Sakura Jungle
	{ Name = "Shiba", Odds = 600000, World = 4, Color = Color3.fromRGB(235, 160, 90) },
	{ Name = "Red Panda", Odds = 720000, World = 4, Color = Color3.fromRGB(215, 90, 50) },
	{ Name = "Koi", Odds = 870000, World = 4, Color = Color3.fromRGB(255, 140, 60) },
	{ Name = "Crane", Odds = 1050000, World = 4, Color = Color3.fromRGB(250, 250, 250) },
	{ Name = "Tanuki", Odds = 1270000, World = 4, Color = Color3.fromRGB(140, 110, 90) },
	{ Name = "Panda", Odds = 1500000, World = 4, Color = Color3.fromRGB(40, 40, 45) },
	{ Name = "Kitsune", Odds = 1850000, World = 4, Color = Color3.fromRGB(255, 245, 235) },
	{ Name = "Tiger", Odds = 2200000, World = 4, Color = Color3.fromRGB(255, 140, 20) },
	{ Name = "Kirin", Odds = 2700000, World = 4, Color = Color3.fromRGB(255, 210, 120) },
	{ Name = "Dragon", Odds = 3250000, World = 4, Color = Color3.fromRGB(220, 40, 40) },
	{ Name = "Phoenix", Odds = 3900000, World = 4, Color = Color3.fromRGB(255, 120, 20) },
	{ Name = "Kraken", Odds = 4700000, World = 4, Color = Color3.fromRGB(80, 40, 140) },
	{ Name = "Celestial Lion", Odds = 5700000, World = 4, Color = Color3.fromRGB(255, 240, 150) },
	{ Name = "Void Serpent", Odds = 6900000, World = 4, Color = Color3.fromRGB(60, 30, 110) },
	{ Name = "Galaxy Whale", Odds = 8300000, World = 4, Color = Color3.fromRGB(70, 60, 200) },
	{ Name = "Glitch", Odds = 10000000, World = 4, Color = Color3.fromRGB(0, 255, 140) },
}
-- Power grows a little faster than rarity: power = 1M x (odds / 1000)^1.17,
-- so a Dog is ~700, a Tiger 1M, a Galaxy Whale ~3.2B and a Glitch ~48B.
-- (tools/economy/simulate.py checks this curve against the progression targets)
Config.POWER_AT_1000 = 1e6
Config.POWER_CURVE = 1.17

local function roundTo3(n)
	local digits = math.floor(math.log10(n)) - 2
	local unit = 10 ^ math.max(digits, 0)
	return math.floor(n / unit + 0.5) * unit
end

Config.PETS_BY_NAME = {}
for i, pet in ipairs(Config.PETS) do
	pet.Index = i
	pet.Power = roundTo3(Config.POWER_AT_1000 * (pet.Odds / 1000) ^ Config.POWER_CURVE)
	Config.PETS_BY_NAME[pet.Name] = pet
end

-- Rarity tiers by odds (the first tier whose Below is higher than the odds)
Config.RARITIES = {
	{ Name = "Common", Below = 10, Color = Color3.fromRGB(190, 195, 205) },
	{ Name = "Uncommon", Below = 100, Color = Color3.fromRGB(90, 210, 100) },
	{ Name = "Rare", Below = 1000, Color = Color3.fromRGB(70, 150, 255) },
	{ Name = "Epic", Below = 10000, Color = Color3.fromRGB(170, 90, 255) },
	{ Name = "Legendary", Below = 100000, Color = Color3.fromRGB(255, 190, 40) },
	{ Name = "Mythic", Below = 1000000, Color = Color3.fromRGB(255, 70, 110) },
	{ Name = "Secret", Below = math.huge, Color = Color3.fromRGB(0, 255, 180) },
}

function Config.rarity(odds)
	for _, rarity in ipairs(Config.RARITIES) do
		if odds < rarity.Below then
			return rarity
		end
	end
	return Config.RARITIES[#Config.RARITIES]
end

-- Sizes ---------------------------------------------------------------------------

-- Every roll also gets a size. To add a size (Giant, Massive, Colossal...),
-- add a row here in order from smallest to biggest: nothing else hard-codes
-- sizes. Chance is "1 in Chance" before Size Luck; Scale is how big the pet
-- is drawn; Power and Luck multiply the pet's power and the luck it gives.
--
-- The best pet in the game is a Titanic Glitch: 48B x 100 = ~4.8T.
Config.SIZES = {
	{ Name = "Normal", Chance = 1, Scale = 1, Power = 1, Luck = 1, Color = Color3.fromRGB(240, 242, 255) },
	{ Name = "Huge", Chance = 100, Scale = 2, Power = 10, Luck = 2, Color = Color3.fromRGB(255, 205, 60) },
	{ Name = "Titanic", Chance = 1000, Scale = 3.4, Power = 100, Luck = 4, Color = Color3.fromRGB(255, 90, 200) },
}
for i, size in ipairs(Config.SIZES) do
	size.Index = i
	-- "Huge " is put in front of the pet's name ("Huge Tiger"); Normal has none
	size.Prefix = if i == 1 then "" else size.Name .. " "
end

-- The saved/equipped name of a pet of a size: "Tiger", "Huge Tiger", ...
function Config.petName(petName, sizeIndex)
	return Config.SIZES[sizeIndex or 1].Prefix .. petName
end

-- "Titanic Tiger" -> Tiger's info, the Titanic size row
function Config.petInfo(name)
	if type(name) ~= "string" then
		return nil, nil
	end
	for i = #Config.SIZES, 2, -1 do
		local prefix = Config.SIZES[i].Prefix
		if name:sub(1, #prefix) == prefix then
			return Config.PETS_BY_NAME[name:sub(#prefix + 1)], Config.SIZES[i]
		end
	end
	return Config.PETS_BY_NAME[name], Config.SIZES[1]
end

-- Rolls a size, rarest first; sizeLuck multiplies every non-normal chance
function Config.rollSize(sizeLuck, random)
	for i = #Config.SIZES, 2, -1 do
		if random:NextNumber() < sizeLuck / Config.SIZES[i].Chance then
			return i
		end
	end
	return 1
end

-- Power and luck -------------------------------------------------------------------

-- How hard a pet hits (rarer and bigger = stronger)
function Config.petPower(name)
	local pet, size = Config.petInfo(name)
	if not pet then
		return 0
	end
	return pet.Power * size.Power
end

-- Equipped pets add a little luck on top of the Luck upgrade: rarer pets
-- add more (a 1 in 1000 pet is +15%), bigger sizes multiply it
function Config.petLuck(name)
	local pet, size = Config.petInfo(name)
	if not pet then
		return 0
	end
	return math.log10(pet.Odds) * 0.05 * size.Luck
end

-- Rolling --------------------------------------------------------------------------

Config.BONUS_EVERY = 10 -- every 10th roll has bonus luck
Config.BONUS_LUCK = 2
Config.BIG_ROLL = 1000 -- rolls this rare (1 in 1000+), or any big size, get the big reveal
Config.FUSE_COPIES = 5 -- the fusion machine turns 5 of a pet into 1 of the next size

-- Total luck: the Luck upgrade (the big one), times a bonus from the
-- equipped pets, times x1.5 per rebirth, times the world you roll in, times
-- 2 on every 10th roll. `world` is the area the player stands in (nil = 1).
function Config.luck(data, isBonus, world)
	local fromPets = 1
	for _, name in ipairs(data.Equipped) do
		fromPets += Config.petLuck(name)
	end
	local luck = Config.upgradeValue(data, "Luck") * fromPets * Config.rebirthLuck(data.Rebirths or 0)
	luck *= Config.AREAS[math.clamp(world or 1, 1, #Config.AREAS)].Luck
	if isBonus then
		luck *= Config.BONUS_LUCK
	end
	return luck
end

-- Every animal can be hatched in every world, but animals from worlds ahead
-- of the one you're rolling in are much rarer: WORLD_PENALTY times per world
-- ahead (a World 4 animal rolled in World 1 is 25^3 = 15,625x rarer). Never
-- impossible, just a long shot, so the right world matters.
Config.WORLD_PENALTY = 25

-- "1 in N" for an animal when rolling in `world` (before luck)
function Config.worldOdds(pet, world)
	local ahead = math.max(pet.World - (world or #Config.AREAS), 0)
	return pet.Odds * Config.WORLD_PENALTY ^ ahead
end

-- Try the rarest pet first, then the next rarest, and so on. Luck multiplies
-- every pet's chance; if nothing hits you get the most common pet.
function Config.roll(luck, random, world)
	for i = #Config.PETS, 2, -1 do
		local pet = Config.PETS[i]
		if random:NextNumber() < luck / Config.worldOdds(pet, world) then
			return pet
		end
	end
	return Config.PETS[1]
end

-- Seconds the fusion machine takes: rarer pets and bigger sizes take longer
function Config.fuseTime(name)
	local pet, size = Config.petInfo(name)
	return (30 + (pet.Index - 1) * 6) * size.Index
end

-- Upgrades ---------------------------------------------------------------------------

-- The upgrade tree. Each row is one branch; add a row to add a branch. Value
-- gives the effect at a level (level 0 = not bought), Cost the price of the
-- next level, Requires another branch's level before this one can start.
-- Branches are drawn in this order, left to right.
-- Numbers come from tools/economy/simulate.py: with these an active player
-- reaches World 4 in about 40 minutes with ~1B pets.
local function multiplier(value)
	if value < 100 then
		return "x" .. (string.format("%.2f", value):gsub("%.?0+$", ""))
	end
	return "x" .. Config.formatNumber(value)
end

Config.UPGRADES = {
	{
		Id = "Coins",
		Name = "Coins",
		Icon = "coin",
		Color = Color3.fromRGB(255, 200, 50),
		Max = 20,
		Describe = "More coins from everything your pets break",
		Step = "+35% coins",
		Value = function(level)
			return 1.35 ^ level
		end,
		Format = function(value)
			return multiplier(value) .. " coins"
		end,
		Cost = function(level)
			return math.floor(60 * 3.4 ^ level)
		end,
	},
	{
		Id = "Damage",
		Name = "Damage",
		Icon = "sword",
		Color = Color3.fromRGB(255, 95, 95),
		Max = 20,
		Describe = "Your pets hit harder",
		Step = "+35% damage",
		Value = function(level)
			return 1.35 ^ level
		end,
		Format = function(value)
			return multiplier(value) .. " damage"
		end,
		Cost = function(level)
			return math.floor(90 * 3.4 ^ level)
		end,
	},
	{
		Id = "Luck",
		Name = "Luck",
		Icon = "clover",
		Color = Color3.fromRGB(80, 220, 120),
		Max = 25,
		Describe = "Better chance of rare pets",
		Step = "+25% luck",
		Value = function(level)
			return 1.25 ^ level
		end,
		Format = function(value)
			return multiplier(value) .. " luck"
		end,
		Cost = function(level)
			return math.floor(250 * 3.7 ^ level)
		end,
		Requires = { "Coins", 1 },
	},
	{
		Id = "RollSpeed",
		Name = "Roll Speed",
		Icon = "bolt",
		Color = Color3.fromRGB(80, 200, 255),
		Max = 13,
		Describe = "Less waiting between rolls",
		Step = "-0.05s per roll",
		Value = function(level)
			return math.max(0.35, 1 - level * 0.05)
		end,
		Format = function(value)
			return string.format("%.2f", value) .. "s per roll"
		end,
		Cost = function(level)
			return math.floor(120 * 3.6 ^ level)
		end,
	},
	{
		Id = "Rolls",
		Name = "Rolls at Once",
		Icon = "dice",
		Color = Color3.fromRGB(170, 120, 255),
		Max = 4,
		Describe = "Roll more pets with every click",
		Step = "+1 pet per roll",
		Value = function(level)
			return 1 + level
		end,
		Format = function(value)
			return value .. (if value == 1 then " pet" else " pets") .. " per roll"
		end,
		Cost = function(level)
			return math.floor(2e4 * 80 ^ level)
		end,
		Requires = { "RollSpeed", 2 },
	},
	{
		Id = "AutoHatch",
		Name = "Auto Hatch",
		Icon = "loop",
		Color = Color3.fromRGB(60, 210, 200),
		Max = 2,
		-- (auto roll itself is free for everyone)
		Describe = "Smarter hatching: quick hatches, then your best team equips itself",
		Step = "next auto feature",
		Value = function(level)
			return level
		end,
		Format = function(value)
			return ({ [0] = "Off", "Quick hatch", "+ auto-equip best" })[value] or "+ auto-equip best"
		end,
		Cost = function(level)
			return ({ 600, 1e6 })[level + 1] or math.huge
		end,
		Requires = { "RollSpeed", 1 },
	},
	{
		Id = "SizeLuck",
		Name = "Size Luck",
		Icon = "grow",
		Color = Color3.fromRGB(255, 120, 200),
		Max = 15,
		Describe = "Better chance of Huge and Titanic pets",
		Step = "+12% size luck",
		Value = function(level)
			return 1.12 ^ level
		end,
		Format = function(value)
			return multiplier(value) .. " size luck"
		end,
		Cost = function(level)
			return math.floor(1e6 * 4.5 ^ level)
		end,
		Requires = { "Luck", 2 },
	},
	{
		Id = "Slots",
		Name = "Pet Slots",
		Icon = "paw",
		Color = Color3.fromRGB(255, 150, 70),
		Max = 3,
		Describe = "Equip more pets at once",
		Step = "+1 pet equipped",
		Value = function(level)
			return 3 + level
		end,
		Format = function(value)
			return value .. " pets equipped"
		end,
		Cost = function(level)
			return ({ 1e4, 5e7, 2e11 })[level + 1] or math.huge
		end,
		Requires = { "Damage", 2 },
	},
}
Config.UPGRADES_BY_ID = {}
for _, upgrade in ipairs(Config.UPGRADES) do
	Config.UPGRADES_BY_ID[upgrade.Id] = upgrade
end

function Config.upgradeLevel(data, id)
	return (data.Upgrades and data.Upgrades[id]) or 0
end

function Config.upgradeValue(data, id)
	return Config.UPGRADES_BY_ID[id].Value(Config.upgradeLevel(data, id))
end

-- Can this upgrade be bought now? Returns ok, reason
function Config.canUpgrade(data, id)
	local upgrade = Config.UPGRADES_BY_ID[id]
	if not upgrade then
		return false, "Unknown upgrade"
	end
	local level = Config.upgradeLevel(data, id)
	if level >= upgrade.Max then
		return false, "Maxed out!"
	end
	if upgrade.Requires and Config.upgradeLevel(data, upgrade.Requires[1]) < upgrade.Requires[2] then
		local need = Config.UPGRADES_BY_ID[upgrade.Requires[1]]
		return false, "Needs " .. need.Name .. " level " .. upgrade.Requires[2]
	end
	return true, nil
end

-- Things upgrades change -------------------------------------------------------------

function Config.rollCooldown(data)
	return Config.upgradeValue(data, "RollSpeed")
end

function Config.rollsAtOnce(data)
	return Config.upgradeValue(data, "Rolls")
end

function Config.maxEquipped(data)
	return Config.upgradeValue(data, "Slots")
end

function Config.sizeLuck(data)
	return Config.upgradeValue(data, "SizeLuck")
end

-- Combat: pets fight the living coins -------------------------------------------------

Config.PET_HIT_EVERY = 0.6 -- seconds between a pet's hits
Config.PET_SPEED = 45 -- studs per second a pet runs to its target
Config.FIGHT_RADIUS = 40 -- pets go after coins this close to the player

function Config.hitDamage(data, name)
	return Config.petPower(name) * Config.upgradeValue(data, "Damage")
end

-- Everything the team deals per second (shown on the team bar)
function Config.teamDamage(data)
	local total = 0
	for _, name in ipairs(data.Equipped) do
		total += Config.hitDamage(data, name) / Config.PET_HIT_EVERY
	end
	return total
end

-- Living coins wander this far from their home spot (how they jump is in
-- shared/Coins.luau)
Config.WANDER = 8

-- Areas --------------------------------------------------------------------------

-- The map is 4 areas in a straight line along +X. Each is AREA_LENGTH long;
-- players can walk anywhere with |Z| < AREA_HALF_WIDTH.
Config.AREA_LENGTH = 100
Config.AREA_HALF_WIDTH = 35

Config.AREAS = {
	{
		Name = "Forest",
		Luck = 1, -- rolling here multiplies luck
		Cost = 0,
		Color = Color3.fromRGB(110, 210, 90),
		Breakable = { Name = "Tree", Health = 5e3, Coins = 20, Exp = 1 },
	},
	{
		Name = "Sahara",
		Luck = 1.2, -- rolling here multiplies luck
		Cost = 2e4,
		Color = Color3.fromRGB(240, 190, 90),
		Breakable = { Name = "Cactus", Health = 1.2e8, Coins = 600, Exp = 4 },
	},
	{
		Name = "Frozen Peaks",
		Luck = 1.45, -- rolling here multiplies luck
		Cost = 6e6,
		Color = Color3.fromRGB(140, 215, 255),
		Breakable = { Name = "Ice Cube", Health = 3e10, Coins = 4e4, Exp = 15 },
	},
	{
		Name = "Sakura Jungle",
		Luck = 1.75, -- rolling here multiplies luck
		Cost = 3e10,
		Color = Color3.fromRGB(255, 150, 200),
		Breakable = { Name = "Sushi", Health = 1.2e13, Coins = 3e6, Exp = 50 },
	},
}

-- TESTING ONLY: every area costs 0 coins and every gate is open, so all
-- four areas can be walked into right away.
-- BEFORE THE FINAL VERSION set this to false (see CLAUDE.md).
Config.AREAS_FREE_FOR_TESTING = true

function Config.areaCost(i)
	if Config.AREAS_FREE_FOR_TESTING then
		return 0
	end
	return Config.AREAS[i].Cost
end

-- The highest area a player has on join and after a rebirth
function Config.startingArea()
	return if Config.AREAS_FREE_FOR_TESTING then #Config.AREAS else 1
end

-- X where area i starts
function Config.areaStart(i)
	return (i - 1) * Config.AREA_LENGTH
end

-- The area at world position x
function Config.areaAt(x)
	return math.clamp(math.floor(x / Config.AREA_LENGTH) + 1, 1, #Config.AREAS)
end

-- Rebirth -------------------------------------------------------------------------

-- A rebirth is a prestige: it resets your coins only. Worlds you've
-- unlocked, pets, upgrades, the Index and your level all stay. Each one
-- needs the coins AND a player level (levels come from EXP for defeating
-- enemies, see Levels below), and gives, for good: Luck x1.5 and +200%
-- coins. They stack: rebirth 3 is luck x1.5^3 = x3.4 and coins
-- x(1 + 3 x 2) = x7. There are 8 rebirths, each needing much more than the
-- last (balanced with tools/economy/simulate.py).
Config.REBIRTH_LUCK = 1.5 -- luck is multiplied by this per rebirth
Config.REBIRTH_COINS = 2 -- +200% coins per rebirth
Config.REBIRTHS = {
	{ Cost = 5e7, Level = 50 },
	{ Cost = 3e10, Level = 75 },
	{ Cost = 1e12, Level = 110 },
	{ Cost = 3e13, Level = 160 },
	{ Cost = 2e14, Level = 225 },
	{ Cost = 4e14, Level = 310 },
	{ Cost = 7e14, Level = 425 },
	{ Cost = 1.2e15, Level = 575 },
}
Config.MAX_REBIRTHS = #Config.REBIRTHS

-- TESTING ONLY: rebirths cost no coins so they can be tried sooner (the
-- level is still needed, and there are still at most 8).
-- BEFORE THE FINAL VERSION set this to false (see CLAUDE.md).
Config.REBIRTH_FREE_FOR_TESTING = true

-- The next rebirth's row (nil when all 8 are done)
function Config.nextRebirth(rebirths)
	return Config.REBIRTHS[(rebirths or 0) + 1]
end

function Config.rebirthCost(rebirths)
	local row = Config.nextRebirth(rebirths)
	if not row then
		return math.huge
	end
	if Config.REBIRTH_FREE_FOR_TESTING then
		return 0
	end
	return row.Cost
end

-- Can this player rebirth now? Returns ok, hasCoins, hasLevel, reason
function Config.canRebirth(data)
	local row = Config.nextRebirth(data.Rebirths)
	if not row then
		return false, false, false, "Max rebirth reached"
	end
	local hasCoins = data.Coins >= Config.rebirthCost(data.Rebirths)
	local hasLevel = (data.Level or 1) >= row.Level
	local reason = if not hasCoins and not hasLevel then "Needs coins and level " .. row.Level
		elseif not hasCoins then "Needs more coins"
		elseif not hasLevel then "Needs level " .. row.Level
		else nil
	return hasCoins and hasLevel, hasCoins, hasLevel, reason
end

-- Levels -----------------------------------------------------------------------------

-- Every enemy you defeat gives EXP (Config.AREAS[i].Breakable.Exp, more in
-- later worlds). EXP fills your level; each level needs more than the last:
-- LEVEL_BASE x level ^ LEVEL_POWER (level 1 -> 2 needs 8, level 50 -> 51
-- ~2.8K, level 500 -> 501 ~89K). Levels never reset.
Config.LEVEL_BASE = 8
Config.LEVEL_POWER = 1.5

-- EXP needed to go from `level` to the next
function Config.expToNext(level)
	return math.floor(Config.LEVEL_BASE * level ^ Config.LEVEL_POWER)
end

-- Adds EXP to a player's data; returns how many levels they went up
function Config.addExp(data, amount)
	data.Level = data.Level or 1
	data.Exp = (data.Exp or 0) + amount
	local gained = 0
	while data.Exp >= Config.expToNext(data.Level) do
		data.Exp -= Config.expToNext(data.Level)
		data.Level += 1
		gained += 1
	end
	return gained
end

-- Coins x(1 + 2 per rebirth): 1, 3, 5, 7 ... 17 at rebirth 8
function Config.coinMultiplier(rebirths)
	return 1 + rebirths * Config.REBIRTH_COINS
end

-- Luck x1.5 per rebirth: 1, 1.5, 2.25 ... ~25.6 at rebirth 8
function Config.rebirthLuck(rebirths)
	return Config.REBIRTH_LUCK ^ rebirths
end

-- All coin bonuses together: rebirths and the Coins upgrade
function Config.coinGain(data)
	return Config.coinMultiplier(data.Rebirths) * Config.upgradeValue(data, "Coins")
end

-- Formatting -------------------------------------------------------------------

-- The one number format used everywhere in the game (coins, power, costs,
-- odds, EXP, damage, leaderboards): 1K, 1M, 1B, 1T, 1Qd, 1Qn, 1Sx ...
local SUFFIXES = { "", "K", "M", "B", "T", "Qd", "Qn", "Sx", "Sp", "Oc", "No", "Dc", "Ud", "Dd", "Td" }

function Config.formatNumber(n)
	if n < 1000 then
		return tostring(math.floor(n))
	end
	local tier = math.min(math.floor(math.log10(n) / 3), #SUFFIXES - 1)
	local scaled = n / 10 ^ (tier * 3)
	if scaled >= 999.95 and tier + 1 < #SUFFIXES then
		-- would round up to "1000K", show "1M" instead
		tier += 1
		scaled /= 1000
	end
	local text = if scaled < 100 then string.format("%.2f", scaled) else string.format("%.1f", scaled)
	text = text:gsub("%.?0+$", "")
	return text .. SUFFIXES[tier + 1]
end

-- "1 in 1,000,000"
function Config.formatOdds(odds)
	return "1 in " .. Config.formatNumber(odds)
end

return Config
