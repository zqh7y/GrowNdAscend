-- Pets, rarities, luck and formatting, shared by the server and the client.
local Config = {}

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
Config.PETS_BY_NAME = {}
for i, pet in ipairs(Config.PETS) do
	pet.Index = i
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

-- Rolling --------------------------------------------------------------------

Config.ROLL_COOLDOWN = 1 -- seconds between rolls
Config.BONUS_EVERY = 10 -- every 10th roll has bonus luck
Config.BONUS_LUCK = 2
Config.MAX_EQUIPPED = 3
Config.AUTO_ROLL_AT = 50 -- rolls needed to unlock auto roll
Config.BIG_ROLL = 1000 -- rolls this rare (1 in 1000+) get the big reveal

-- Equipped pets add luck: rarer pets add more (a 1 in 1000 pet is +45%,
-- its huge version twice that). Config.petInfo is defined further down.
function Config.petLuck(pet)
	return math.log10(pet.Odds) * 0.15
end

function Config.luck(equipped, isBonus)
	local luck = 1
	for _, name in ipairs(equipped) do
		local pet, huge = Config.petInfo(name)
		if pet then
			luck += Config.petLuck(pet) * (if huge then 2 else 1)
		end
	end
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

-- Pet power and huge pets ------------------------------------------------------

Config.HUGE_PREFIX = "Huge "
Config.HUGE_POWER = 10 -- huge pets are 10x stronger
Config.FUSE_COPIES = 5 -- copies of a pet the fusion machine needs for a huge

-- "Huge Tiger" -> Tiger's info, true
function Config.petInfo(name)
	if type(name) ~= "string" then
		return nil, false
	end
	if name:sub(1, #Config.HUGE_PREFIX) == Config.HUGE_PREFIX then
		return Config.PETS_BY_NAME[name:sub(#Config.HUGE_PREFIX + 1)], true
	end
	return Config.PETS_BY_NAME[name], false
end

-- How hard a pet hits breakables (rarer = stronger)
function Config.petPower(name)
	local pet, huge = Config.petInfo(name)
	if not pet then
		return 0
	end
	local power = math.max(1, math.floor(math.sqrt(pet.Odds)))
	return if huge then power * Config.HUGE_POWER else power
end

-- Damage per hit: 1 plus the power of every equipped pet
function Config.hitDamage(equipped)
	local damage = 1
	for _, name in ipairs(equipped) do
		damage += Config.petPower(name)
	end
	return damage
end

-- Seconds the fusion machine takes: rarer pets take longer
function Config.fuseTime(pet)
	return 30 + (pet.Index - 1) * 20
end

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
		Breakable = { Name = "Small Tree", Health = 12, Coins = 3 },
	},
	{
		Name = "Sahara",
		Cost = 300,
		Color = Color3.fromRGB(240, 190, 90),
		Breakable = { Name = "Cactus", Health = 150, Coins = 25 },
	},
	{
		Name = "Frozen Peaks",
		Cost = 6000,
		Color = Color3.fromRGB(140, 215, 255),
		Breakable = { Name = "Ice Cube", Health = 1500, Coins = 200 },
	},
	{
		Name = "Sakura Jungle",
		Cost = 100000,
		Color = Color3.fromRGB(255, 150, 200),
		Breakable = { Name = "Sushi", Health = 15000, Coins = 1800 },
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
	return 1e6 * (rebirths + 1)
end

function Config.coinMultiplier(rebirths)
	return 1 + rebirths * Config.REBIRTH_BONUS
end

-- Formatting -------------------------------------------------------------------

local SUFFIXES = { "", "K", "M", "B", "T" }

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
