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

-- Equipped pets add luck: rarer pets add more (a 1 in 1000 pet is +45%)
function Config.petLuck(pet)
	return math.log10(pet.Odds) * 0.15
end

function Config.luck(equipped, isBonus)
	local luck = 1
	for _, name in ipairs(equipped) do
		local pet = Config.PETS_BY_NAME[name]
		if pet then
			luck += Config.petLuck(pet)
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
