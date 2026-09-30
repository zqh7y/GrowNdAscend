-- Pets, rarities, sizes, luck, upgrades, combat and formatting, shared by the
-- server and the client so the UI always shows exactly what the server does.
local Config = {}

-- Pets -------------------------------------------------------------------------

-- Every pet you can roll, from most common to rarest. Odds is "1 in Odds".
Config.PETS = {
	{ Name = "Dog", Odds = 2, Color = Color3.fromRGB(200, 150, 100) },
	{ Name = "Cat", Odds = 3, Color = Color3.fromRGB(255, 170, 80) },
	{ Name = "Bunny", Odds = 5, Color = Color3.fromRGB(245, 240, 240) },
	{ Name = "Chick", Odds = 8, Color = Color3.fromRGB(255, 225, 70) },
	{ Name = "Mouse", Odds = 12, Color = Color3.fromRGB(170, 170, 180) },
	{ Name = "Fox", Odds = 25, Color = Color3.fromRGB(240, 110, 40) },
	{ Name = "Panda", Odds = 50, Color = Color3.fromRGB(40, 40, 45) },
	{ Name = "Penguin", Odds = 100, Color = Color3.fromRGB(60, 80, 120) },
	{ Name = "Owl", Odds = 250, Color = Color3.fromRGB(140, 100, 70) },
	{ Name = "Wolf", Odds = 500, Color = Color3.fromRGB(120, 130, 160) },
	{ Name = "Tiger", Odds = 1000, Color = Color3.fromRGB(255, 140, 20) },
	{ Name = "Unicorn", Odds = 2500, Color = Color3.fromRGB(255, 170, 230) },
	{ Name = "Dragon", Odds = 5000, Color = Color3.fromRGB(220, 40, 40) },
	{ Name = "Phoenix", Odds = 10000, Color = Color3.fromRGB(255, 120, 20) },
	{ Name = "Kraken", Odds = 25000, Color = Color3.fromRGB(80, 40, 140) },
	{ Name = "Griffin", Odds = 50000, Color = Color3.fromRGB(230, 200, 120) },
	{ Name = "Celestial Lion", Odds = 100000, Color = Color3.fromRGB(255, 240, 150) },
	{ Name = "Void Serpent", Odds = 250000, Color = Color3.fromRGB(30, 10, 50) },
	{ Name = "Galaxy Whale", Odds = 1000000, Color = Color3.fromRGB(70, 60, 200) },
	{ Name = "Glitch", Odds = 10000000, Color = Color3.fromRGB(0, 255, 140) },
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
-- equipped pets, times 2 on every 10th roll
function Config.luck(data, isBonus)
	local fromPets = 1
	for _, name in ipairs(data.Equipped) do
		fromPets += Config.petLuck(name)
	end
	local luck = Config.upgradeValue(data, "Luck") * fromPets
	if isBonus then
		luck *= Config.BONUS_LUCK
	end
	return luck
end

-- Try the rarest pet first, then the next rarest, and so on. Luck multiplies
-- every pet's chance; if nothing hits you get the most common pet.
function Config.roll(luck, random)
	for i = #Config.PETS, 2, -1 do
		local pet = Config.PETS[i]
		if random:NextNumber() < luck / pet.Odds then
			return pet
		end
	end
	return Config.PETS[1]
end

-- Seconds the fusion machine takes: rarer pets and bigger sizes take longer
function Config.fuseTime(name)
	local pet, size = Config.petInfo(name)
	return (30 + (pet.Index - 1) * 20) * size.Index
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
			return math.floor(40 * 3.1 ^ level)
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
			return math.floor(60 * 3.1 ^ level)
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
			return math.floor(150 * 3.4 ^ level)
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
			return math.floor(80 * 3.3 ^ level)
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
			return math.floor(3000 * 60 ^ level)
		end,
		Requires = { "RollSpeed", 2 },
	},
	{
		Id = "AutoHatch",
		Name = "Auto Hatch",
		Icon = "loop",
		Color = Color3.fromRGB(60, 210, 200),
		Max = 3,
		Describe = "Rolls for you: unlock, then quick reveals, then auto-equip best",
		Step = "next auto feature",
		Value = function(level)
			return level
		end,
		Format = function(value)
			return ({ [0] = "Locked", "Auto roll", "+ quick reveals", "+ auto-equip best" })[value]
		end,
		Cost = function(level)
			return ({ 400, 2e5, 5e7 })[level + 1] or math.huge
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
			return math.floor(1e5 * 4 ^ level)
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
			return ({ 2000, 5e6, 5e9 })[level + 1] or math.huge
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
		Cost = 0,
		Color = Color3.fromRGB(110, 210, 90),
		Breakable = { Name = "Tree", Health = 5e3, Coins = 20 },
	},
	{
		Name = "Sahara",
		Cost = 4e3,
		Color = Color3.fromRGB(240, 190, 90),
		Breakable = { Name = "Cactus", Health = 6e7, Coins = 400 },
	},
	{
		Name = "Frozen Peaks",
		Cost = 6e5,
		Color = Color3.fromRGB(140, 215, 255),
		Breakable = { Name = "Ice Cube", Health = 4e9, Coins = 2.5e4 },
	},
	{
		Name = "Sakura Jungle",
		Cost = 2.2e8,
		Color = Color3.fromRGB(255, 150, 200),
		Breakable = { Name = "Sushi", Health = 2.5e11, Coins = 1.5e6 },
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

-- Rebirth -------------------------------------------------------------------------

Config.REBIRTH_BONUS = 0.5 -- +50% coins per rebirth

-- TESTING ONLY: rebirth costs nothing so it can be tried right away.
-- BEFORE THE FINAL VERSION set this to false (see CLAUDE.md).
Config.REBIRTH_FREE_FOR_TESTING = true

function Config.rebirthCost(rebirths)
	if Config.REBIRTH_FREE_FOR_TESTING then
		return 0
	end
	return 2e10 * 5 ^ rebirths -- about 10 minutes of World 4 coins at first
end

function Config.coinMultiplier(rebirths)
	return 1 + rebirths * Config.REBIRTH_BONUS
end

-- All coin bonuses together: rebirths and the Coins upgrade
function Config.coinGain(data)
	return Config.coinMultiplier(data.Rebirths) * Config.upgradeValue(data, "Coins")
end

-- Formatting -------------------------------------------------------------------

local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi" }

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
	local digits = tostring(math.floor(odds))
	local withCommas = digits:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
	return "1 in " .. withCommas
end

return Config
