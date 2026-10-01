-- Pets, rarities, sizes, luck, upgrades, combat and formatting, shared by the
-- server and the client so the UI always shows exactly what the server does.
local Config = {}

-- Shown on screen and in Output, so it's easy to tell which version is running
Config.BUILD = "build 29 (aura bees instead of weapons)"

-- Pets -------------------------------------------------------------------------

-- Every animal in the game (the Index has all 70), from most common to
-- rarest. Odds is "1 in Odds"; World is where it lives: you can only roll it
-- once that world is unlocked, and each world's animals cover its own band
-- of rarity (and so of power), which is what the progression is built on.
Config.PETS = {
	-- World 1: Forest
	{ Name = "Dog", Odds = 2, World = 1, Color = Color3.fromRGB(200, 150, 100), Stats = { Speed = 1, Luck = 1.02, Coins = 1, Damage = 1, Exp = 1 } },
	{ Name = "Cat", Odds = 3, World = 1, Color = Color3.fromRGB(255, 170, 80), Stats = { Speed = 0.9, Luck = 1.02, Coins = 1, Damage = 1, Exp = 1.01 } },
	{ Name = "Bunny", Odds = 4, World = 1, Color = Color3.fromRGB(245, 240, 240), Stats = { Speed = 0.8, Luck = 1.1, Coins = 1.01, Damage = 1, Exp = 1.01 } },
	{ Name = "Chick", Odds = 5, World = 1, Color = Color3.fromRGB(255, 225, 70), Stats = { Speed = 0.55, Luck = 1.03, Coins = 1.01, Damage = 1.01, Exp = 1.01 } },
	{ Name = "Mouse", Odds = 7, World = 1, Color = Color3.fromRGB(170, 170, 180), Stats = { Speed = 0.9, Luck = 1.04, Coins = 1.01, Damage = 1.01, Exp = 1.01 } },
	{ Name = "Hamster", Odds = 9, World = 1, Color = Color3.fromRGB(240, 190, 120), Stats = { Speed = 0.7, Luck = 1.05, Coins = 1.09, Damage = 1.01, Exp = 1.01 } },
	{ Name = "Duck", Odds = 12, World = 1, Color = Color3.fromRGB(255, 235, 120), Stats = { Speed = 0.55, Luck = 1.05, Coins = 1.01, Damage = 1.01, Exp = 1.1 } },
	{ Name = "Frog", Odds = 16, World = 1, Color = Color3.fromRGB(110, 210, 90), Stats = { Speed = 0.8, Luck = 1.06, Coins = 1.01, Damage = 1.01, Exp = 1.02 } },
	{ Name = "Piglet", Odds = 21, World = 1, Color = Color3.fromRGB(255, 170, 190), Stats = { Speed = 0.75, Luck = 1.07, Coins = 1.1, Damage = 1.01, Exp = 1.02 } },
	{ Name = "Lamb", Odds = 28, World = 1, Color = Color3.fromRGB(250, 248, 240), Stats = { Speed = 0.75, Luck = 1.07, Coins = 1.01, Damage = 1.01, Exp = 1.11 } },
	{ Name = "Squirrel", Odds = 38, World = 1, Color = Color3.fromRGB(205, 120, 60), Stats = { Speed = 0.9, Luck = 1.08, Coins = 1.11, Damage = 1.01, Exp = 1.02 } },
	{ Name = "Hedgehog", Odds = 50, World = 1, Color = Color3.fromRGB(170, 130, 100), Stats = { Speed = 0.6, Luck = 1.08, Coins = 1.02, Damage = 1.01, Exp = 1.03 } },
	{ Name = "Fox", Odds = 70, World = 1, Color = Color3.fromRGB(240, 110, 40), Stats = { Speed = 1.1, Luck = 1.19, Coins = 1.02, Damage = 1.01, Exp = 1.03 } },
	{ Name = "Raccoon", Odds = 90, World = 1, Color = Color3.fromRGB(150, 150, 160), Stats = { Speed = 0.9, Luck = 1.1, Coins = 1.12, Damage = 1.02, Exp = 1.03 } },
	{ Name = "Deer", Odds = 125, World = 1, Color = Color3.fromRGB(200, 140, 90), Stats = { Speed = 1.1, Luck = 1.1, Coins = 1.02, Damage = 1.02, Exp = 1.03 } },
	{ Name = "Owl", Odds = 170, World = 1, Color = Color3.fromRGB(140, 100, 70), Stats = { Speed = 0.9, Luck = 1.11, Coins = 1.02, Damage = 1.02, Exp = 1.14 } },
	{ Name = "Bear", Odds = 225, World = 1, Color = Color3.fromRGB(150, 95, 60), Stats = { Speed = 0.85, Luck = 1.12, Coins = 1.02, Damage = 1.13, Exp = 1.04 } },
	{ Name = "Wolf", Odds = 300, World = 1, Color = Color3.fromRGB(120, 130, 160), Stats = { Speed = 1.2, Luck = 1.12, Coins = 1.02, Damage = 1.13, Exp = 1.04 } },
	{ Name = "Parrot", Odds = 400, World = 1, Color = Color3.fromRGB(70, 200, 110), Stats = { Speed = 1, Luck = 1.24, Coins = 1.03, Damage = 1.02, Exp = 1.04 } },
	{ Name = "Moose", Odds = 550, World = 1, Color = Color3.fromRGB(130, 90, 60), Stats = { Speed = 0.9, Luck = 1.14, Coins = 1.03, Damage = 1.14, Exp = 1.04 } },
	{ Name = "Unicorn", Odds = 750, World = 1, Color = Color3.fromRGB(255, 170, 230), Stats = { Speed = 1.1, Luck = 1.26, Coins = 1.03, Damage = 1.02, Exp = 1.04 } },
	{ Name = "Forest Guardian", Odds = 1000, World = 1, Color = Color3.fromRGB(90, 220, 140), Stats = { Speed = 1.1, Luck = 1.27, Coins = 1.03, Damage = 1.02, Exp = 1.04 } },
	-- World 2: Sahara
	{ Name = "Camel", Odds = 1250, World = 2, Color = Color3.fromRGB(230, 180, 115), Stats = { Speed = 0.8, Luck = 1.15, Coins = 1.15, Damage = 1.02, Exp = 1.05 } },
	{ Name = "Meerkat", Odds = 1500, World = 2, Color = Color3.fromRGB(215, 170, 110), Stats = { Speed = 1, Luck = 1.16, Coins = 1.16, Damage = 1.03, Exp = 1.05 } },
	{ Name = "Fennec Fox", Odds = 1800, World = 2, Color = Color3.fromRGB(250, 210, 150), Stats = { Speed = 1.1, Luck = 1.16, Coins = 1.03, Damage = 1.03, Exp = 1.05 } },
	{ Name = "Lizard", Odds = 2200, World = 2, Color = Color3.fromRGB(120, 200, 90), Stats = { Speed = 1, Luck = 1.17, Coins = 1.03, Damage = 1.03, Exp = 1.05 } },
	{ Name = "Tortoise", Odds = 2600, World = 2, Color = Color3.fromRGB(130, 170, 90), Stats = { Speed = 0.4, Luck = 1.17, Coins = 1.03, Damage = 1.03, Exp = 1.18 } },
	{ Name = "Scorpion", Odds = 3200, World = 2, Color = Color3.fromRGB(230, 110, 60), Stats = { Speed = 0.9, Luck = 1.18, Coins = 1.04, Damage = 1.16, Exp = 1.05 } },
	{ Name = "Cobra", Odds = 3800, World = 2, Color = Color3.fromRGB(200, 170, 60), Stats = { Speed = 0.7, Luck = 1.18, Coins = 1.04, Damage = 1.16, Exp = 1.05 } },
	{ Name = "Vulture", Odds = 4500, World = 2, Color = Color3.fromRGB(120, 100, 110), Stats = { Speed = 0.9, Luck = 1.18, Coins = 1.04, Damage = 1.03, Exp = 1.05 } },
	{ Name = "Hyena", Odds = 5500, World = 2, Color = Color3.fromRGB(200, 170, 120), Stats = { Speed = 1.1, Luck = 1.19, Coins = 1.04, Damage = 1.16, Exp = 1.06 } },
	{ Name = "Cheetah", Odds = 6500, World = 2, Color = Color3.fromRGB(250, 195, 90), Stats = { Speed = 1.5, Luck = 1.19, Coins = 1.04, Damage = 1.03, Exp = 1.06 } },
	{ Name = "Lion", Odds = 8000, World = 2, Color = Color3.fromRGB(240, 175, 70), Stats = { Speed = 1.1, Luck = 1.2, Coins = 1.18, Damage = 1.03, Exp = 1.06 } },
	{ Name = "Falcon", Odds = 9500, World = 2, Color = Color3.fromRGB(150, 120, 100), Stats = { Speed = 1.3, Luck = 1.2, Coins = 1.04, Damage = 1.03, Exp = 1.06 } },
	{ Name = "Golden Scarab", Odds = 11500, World = 2, Color = Color3.fromRGB(255, 200, 50), Stats = { Speed = 0.8, Luck = 1.34, Coins = 1.04, Damage = 1.03, Exp = 1.06 } },
	{ Name = "Anubis Jackal", Odds = 14000, World = 2, Color = Color3.fromRGB(50, 55, 80), Stats = { Speed = 1.2, Luck = 1.21, Coins = 1.04, Damage = 1.03, Exp = 1.21 } },
	{ Name = "Griffin", Odds = 17000, World = 2, Color = Color3.fromRGB(230, 200, 120), Stats = { Speed = 1.1, Luck = 1.21, Coins = 1.04, Damage = 1.03, Exp = 1.21 } },
	{ Name = "Sphinx", Odds = 20000, World = 2, Color = Color3.fromRGB(245, 210, 140), Stats = { Speed = 0.9, Luck = 1.22, Coins = 1.04, Damage = 1.03, Exp = 1.21 } },
	-- World 3: Frozen Peaks
	{ Name = "Penguin", Odds = 25000, World = 3, Color = Color3.fromRGB(60, 80, 120), Stats = { Speed = 0.5, Luck = 1.22, Coins = 1.04, Damage = 1.04, Exp = 1.07 } },
	{ Name = "Snow Hare", Odds = 30000, World = 3, Color = Color3.fromRGB(245, 248, 255), Stats = { Speed = 0.9, Luck = 1.37, Coins = 1.04, Damage = 1.04, Exp = 1.07 } },
	{ Name = "Arctic Fox", Odds = 37000, World = 3, Color = Color3.fromRGB(235, 240, 250), Stats = { Speed = 1.1, Luck = 1.23, Coins = 1.05, Damage = 1.04, Exp = 1.07 } },
	{ Name = "Seal", Odds = 45000, World = 3, Color = Color3.fromRGB(170, 180, 200), Stats = { Speed = 0.45, Luck = 1.23, Coins = 1.05, Damage = 1.04, Exp = 1.22 } },
	{ Name = "Husky", Odds = 55000, World = 3, Color = Color3.fromRGB(150, 160, 180), Stats = { Speed = 1.2, Luck = 1.24, Coins = 1.05, Damage = 1.04, Exp = 1.07 } },
	{ Name = "Snowy Owl", Odds = 67000, World = 3, Color = Color3.fromRGB(248, 250, 255), Stats = { Speed = 0.9, Luck = 1.24, Coins = 1.05, Damage = 1.04, Exp = 1.23 } },
	{ Name = "Walrus", Odds = 82000, World = 3, Color = Color3.fromRGB(180, 130, 100), Stats = { Speed = 0.4, Luck = 1.25, Coins = 1.05, Damage = 1.2, Exp = 1.07 } },
	{ Name = "Reindeer", Odds = 100000, World = 3, Color = Color3.fromRGB(170, 120, 80), Stats = { Speed = 1.1, Luck = 1.25, Coins = 1.05, Damage = 1.04, Exp = 1.23 } },
	{ Name = "Polar Bear", Odds = 120000, World = 3, Color = Color3.fromRGB(250, 250, 245), Stats = { Speed = 0.85, Luck = 1.25, Coins = 1.05, Damage = 1.2, Exp = 1.08 } },
	{ Name = "Snow Leopard", Odds = 150000, World = 3, Color = Color3.fromRGB(230, 232, 240), Stats = { Speed = 1.3, Luck = 1.26, Coins = 1.05, Damage = 1.04, Exp = 1.08 } },
	{ Name = "Orca", Odds = 180000, World = 3, Color = Color3.fromRGB(40, 45, 70), Stats = { Speed = 1, Luck = 1.26, Coins = 1.05, Damage = 1.21, Exp = 1.08 } },
	{ Name = "Narwhal", Odds = 220000, World = 3, Color = Color3.fromRGB(150, 180, 220), Stats = { Speed = 0.9, Luck = 1.27, Coins = 1.05, Damage = 1.04, Exp = 1.25 } },
	{ Name = "Yeti", Odds = 270000, World = 3, Color = Color3.fromRGB(235, 245, 255), Stats = { Speed = 0.8, Luck = 1.27, Coins = 1.05, Damage = 1.21, Exp = 1.08 } },
	{ Name = "Mammoth", Odds = 330000, World = 3, Color = Color3.fromRGB(150, 105, 75), Stats = { Speed = 0.7, Luck = 1.28, Coins = 1.23, Damage = 1.04, Exp = 1.08 } },
	{ Name = "Ice Phoenix", Odds = 400000, World = 3, Color = Color3.fromRGB(140, 220, 255), Stats = { Speed = 1.2, Luck = 1.28, Coins = 1.06, Damage = 1.04, Exp = 1.08 } },
	{ Name = "Frost Dragon", Odds = 500000, World = 3, Color = Color3.fromRGB(120, 200, 255), Stats = { Speed = 1.2, Luck = 1.28, Coins = 1.06, Damage = 1.22, Exp = 1.09 } },
	-- World 4: Sakura Jungle
	{ Name = "Shiba", Odds = 600000, World = 4, Color = Color3.fromRGB(235, 160, 90), Stats = { Speed = 1.1, Luck = 1.29, Coins = 1.06, Damage = 1.05, Exp = 1.09 } },
	{ Name = "Red Panda", Odds = 720000, World = 4, Color = Color3.fromRGB(215, 90, 50), Stats = { Speed = 0.9, Luck = 1.29, Coins = 1.24, Damage = 1.05, Exp = 1.09 } },
	{ Name = "Koi", Odds = 870000, World = 4, Color = Color3.fromRGB(255, 140, 60), Stats = { Speed = 0.8, Luck = 1.48, Coins = 1.06, Damage = 1.05, Exp = 1.09 } },
	{ Name = "Crane", Odds = 1050000, World = 4, Color = Color3.fromRGB(250, 250, 250), Stats = { Speed = 1, Luck = 1.3, Coins = 1.06, Damage = 1.05, Exp = 1.27 } },
	{ Name = "Tanuki", Odds = 1270000, World = 4, Color = Color3.fromRGB(140, 110, 90), Stats = { Speed = 0.85, Luck = 1.31, Coins = 1.24, Damage = 1.05, Exp = 1.09 } },
	{ Name = "Panda", Odds = 1500000, World = 4, Color = Color3.fromRGB(40, 40, 45), Stats = { Speed = 0.75, Luck = 1.31, Coins = 1.06, Damage = 1.05, Exp = 1.28 } },
	{ Name = "Kitsune", Odds = 1850000, World = 4, Color = Color3.fromRGB(255, 245, 235), Stats = { Speed = 1.2, Luck = 1.5, Coins = 1.06, Damage = 1.05, Exp = 1.09 } },
	{ Name = "Tiger", Odds = 2200000, World = 4, Color = Color3.fromRGB(255, 140, 20), Stats = { Speed = 1.2, Luck = 1.32, Coins = 1.06, Damage = 1.24, Exp = 1.1 } },
	{ Name = "Kirin", Odds = 2700000, World = 4, Color = Color3.fromRGB(255, 210, 120), Stats = { Speed = 1.3, Luck = 1.32, Coins = 1.06, Damage = 1.05, Exp = 1.1 } },
	{ Name = "Dragon", Odds = 3250000, World = 4, Color = Color3.fromRGB(220, 40, 40), Stats = { Speed = 1.3, Luck = 1.33, Coins = 1.07, Damage = 1.24, Exp = 1.1 } },
	{ Name = "Phoenix", Odds = 3900000, World = 4, Color = Color3.fromRGB(255, 120, 20), Stats = { Speed = 1.3, Luck = 1.52, Coins = 1.07, Damage = 1.05, Exp = 1.1 } },
	{ Name = "Kraken", Odds = 4700000, World = 4, Color = Color3.fromRGB(80, 40, 140), Stats = { Speed = 0.7, Luck = 1.33, Coins = 1.07, Damage = 1.25, Exp = 1.1 } },
	{ Name = "Celestial Lion", Odds = 5700000, World = 4, Color = Color3.fromRGB(255, 240, 150), Stats = { Speed = 1.3, Luck = 1.53, Coins = 1.07, Damage = 1.05, Exp = 1.1 } },
	{ Name = "Void Serpent", Odds = 6900000, World = 4, Color = Color3.fromRGB(60, 30, 110), Stats = { Speed = 0.8, Luck = 1.34, Coins = 1.07, Damage = 1.25, Exp = 1.1 } },
	{ Name = "Galaxy Whale", Odds = 8300000, World = 4, Color = Color3.fromRGB(70, 60, 200), Stats = { Speed = 0.9, Luck = 1.35, Coins = 1.27, Damage = 1.06, Exp = 1.1 } },
	{ Name = "Glitch", Odds = 10000000, World = 4, Color = Color3.fromRGB(0, 255, 140), Stats = { Speed = 1.1, Luck = 1.55, Coins = 1.07, Damage = 1.06, Exp = 1.1 } },
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

-- Auras (the Pet Aura Machine in the Sahara) ---------------------------------------
-- Put in 3 of the same pet (any size, no aura yet) and get 1 of it back
-- with a random aura: mini bees flying around it in the aura's colour. Each
-- aura multiplies that pet's Damage, Coins and/or Luck stats. Weight is the
-- chance out of 100. An aura pet's saved name is "<pet name>|<aura id>"
-- ("Huge Tiger|plasma"); Config.petInfo ignores the aura part. (The ids
-- are from when auras were weapons; they stay so saves keep working.)
Config.AURA_COPIES = 3
Config.AURAS = {
	{ Id = "blaster", Name = "Worker Bees", Weight = 45, Color = Color3.fromRGB(90, 170, 255), Boosts = { Damage = 1.3 } },
	{ Id = "coin", Name = "Honey Bees", Weight = 25, Color = Color3.fromRGB(255, 196, 40), Boosts = { Coins = 1.4 } },
	{ Id = "clover", Name = "Clover Bees", Weight = 15, Color = Color3.fromRGB(70, 210, 110), Boosts = { Luck = 1.4 } },
	{ Id = "plasma", Name = "Plasma Bees", Weight = 9, Color = Color3.fromRGB(170, 90, 255), Boosts = { Damage = 1.8, Coins = 1.2 } },
	{ Id = "rainbow", Name = "Rainbow Bees", Weight = 5, Color = Color3.fromRGB(255, 90, 170), Boosts = { Damage = 1.6, Coins = 1.6, Luck = 1.6 } },
	{ Id = "cosmic", Name = "Cosmic Bees", Weight = 1, Color = Color3.fromRGB(40, 240, 230), Boosts = { Damage = 3, Coins = 2.5, Luck = 2.5 } },
}
Config.AURAS_BY_ID = {}
for _, aura in ipairs(Config.AURAS) do
	Config.AURAS_BY_ID[aura.Id] = aura
end

-- "Huge Tiger|plasma" -> "Huge Tiger", the Plasma Rifle row (nil if none)
function Config.splitAura(name)
	if type(name) ~= "string" then
		return name, nil
	end
	local base, id = string.match(name, "^(.-)|(.+)$")
	if not base then
		return name, nil
	end
	return base, Config.AURAS_BY_ID[id]
end

function Config.petAura(name)
	return (select(2, Config.splitAura(name)))
end

-- The saved name of a pet holding an aura
function Config.auraName(name, auraId)
	return (Config.splitAura(name)) .. "|" .. auraId
end

-- What players read: "Huge Tiger" (the aura is shown as its own tag)
function Config.displayName(name)
	return (Config.splitAura(name))
end

-- "Huge Tiger (Plasma Rifle)"
function Config.fullName(name)
	local base, aura = Config.splitAura(name)
	return if aura then base .. " (" .. aura.Name .. ")" else base
end

-- Picks an aura by weight; `roll` is a number in [0, 1)
function Config.pickAura(roll)
	local total = 0
	for _, aura in ipairs(Config.AURAS) do
		total += aura.Weight
	end
	local at = roll * total
	for _, aura in ipairs(Config.AURAS) do
		at -= aura.Weight
		if at < 0 then
			return aura
		end
	end
	return Config.AURAS[1]
end

-- "Titanic Tiger" -> Tiger's info, the Titanic size row (an aura part,
-- "|plasma", is ignored)
function Config.petInfo(name)
	if type(name) ~= "string" then
		return nil, nil
	end
	local plain: string = (Config.splitAura(name)) :: string
	for i = #Config.SIZES, 2, -1 do
		local prefix = Config.SIZES[i].Prefix
		if plain:sub(1, #prefix) == prefix then
			return Config.PETS_BY_NAME[plain:sub(#prefix + 1)], Config.SIZES[i]
		end
	end
	return Config.PETS_BY_NAME[plain], Config.SIZES[1]
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

-- Pet stats -------------------------------------------------------------------------
-- Every pet has its own five multipliers (its row in PETS, `Stats`):
--   Speed   how fast that pet moves
--   Luck    adds to the team's pet luck (see Config.luck)
--   Coins   adds to the team's coin bonus
--   Damage  multiplies that pet's own hits
--   Exp     adds to the team's EXP bonus
-- Huge and Titanic sizes multiply the bonus part (x2 / x4 of `value - 1`),
-- except Speed. Team bonuses ADD UP before multiplying:
--   team stat = 1 + sum over equipped pets of (pet stat - 1)
-- so a 1.1x and a 1.3x pet make 1.4x, not 1.43x.
Config.STATS = { "Speed", "Luck", "Coins", "Damage", "Exp" }
Config.STAT_LABELS = { Speed = "Speed", Luck = "Luck", Coins = "Coins", Damage = "Damage", Exp = "EXP" }

-- make sure every pet has every stat, as a sensible number
for _, pet: any in ipairs(Config.PETS :: { any }) do
	pet.Stats = pet.Stats or {}
	for _, stat in ipairs(Config.STATS) do
		local value = pet.Stats[stat]
		if type(value) ~= "number" or value ~= value then
			value = 1
		end
		pet.Stats[stat] = math.clamp(value, if stat == "Speed" then 0.25 else 1, 100)
	end
end

-- One pet's multiplier for a stat ("Huge Fox", "Luck" -> 1.54)
function Config.petStat(name, stat)
	local pet, size = Config.petInfo(name)
	if not pet then
		return 1
	end
	local value = pet.Stats[stat] or 1
	if stat == "Speed" then
		return value
	end
	value = 1 + (value - 1) * size.Luck
	-- an aura multiplies the stats it boosts
	local aura = Config.petAura(name)
	if aura and aura.Boosts[stat] then
		value *= aura.Boosts[stat]
	end
	return value
end

-- The team's multiplier for a stat: 1 + the bonuses of the EQUIPPED pets added up
function Config.teamStat(data, stat)
	local total = 1
	for _, name in ipairs(data.Equipped or {}) do
		total += Config.petStat(name, stat) - 1
	end
	return total
end

-- (kept for older callers) the luck bonus one pet adds
function Config.petLuck(name)
	return Config.petStat(name, "Luck") - 1
end

-- Rolling --------------------------------------------------------------------------

Config.BONUS_EVERY = 10 -- every 10th roll has bonus luck
Config.BONUS_LUCK = 2
Config.BIG_ROLL = 1000 -- rolls this rare (1 in 1000+), or any big size, get the big reveal

-- Luck boosts: every roll can come out as a "x2 LUCK" instead of a pet
-- (BOOST_CHANCE, not changed by luck). A boost applies to the NEXT roll
-- (spin) and is used up by it. Boosts stack by multiplying: hatch x2 -> the
-- next roll has x2; hatch another x2 during that roll -> the next has x4,
-- then x8 ... up to x1024. A roll without a boost leaves nothing waiting.
-- The server keeps the waiting boost in data.LuckChain (saved, so it
-- survives a rejoin) and Config.luck applies it, so the roll, the odds shown
-- in the spin and the luck chip all use the same value.
Config.BOOST_CHANCE = 1 / 12
Config.BOOST = { Name = "x2 LUCK", Multiplier = 2 }
Config.CHAIN_CHANCE = Config.BOOST_CHANCE
Config.CHAIN_MAX = 1024
-- Total luck never goes above this, so no pet is ever certain (the rarest
-- animal stays at 1 in 10 or worse even with every multiplier stacked)
Config.MAX_LUCK = 1e6

-- The multiplier for the coming spin (always a power of two, 1..1024)
function Config.luckMultiplier(data)
	local chain = data.LuckChain
	if type(chain) ~= "number" or chain < 1 or chain ~= chain then
		return 1
	end
	return math.min(2 ^ math.floor(math.log(chain, 2) + 1e-9), Config.CHAIN_MAX)
end

-- The boost waiting after a spin that used `current` and hatched `boosts`
-- x2 boosts: current x 2^boosts (capped), or 1 if it hatched none
function Config.nextChain(current, boosts)
	if type(boosts) ~= "number" then
		-- (old form: a random source) one try at a boost
		boosts = if boosts:NextNumber() < Config.BOOST_CHANCE then 1 else 0
	end
	if boosts <= 0 then
		return 1
	end
	return math.min(current * Config.BOOST.Multiplier ^ boosts, Config.CHAIN_MAX)
end

-- Total luck:
--   existing luck = Luck upgrade x rebirths (x1.5 each) x the world you roll
--                   in x 2 on every 10th roll x the luck boost for this roll
--   final luck    = existing luck x pet luck, where
--   pet luck      = 1 + sum over equipped pets of (pet Luck - 1)
-- e.g. pets of 1.1x and 1.3x -> 1.4x; with existing luck x5 -> x7.
-- `world` is the area the player stands in (nil = 1); `multiplier` is the
-- luck boost (nil = the one waiting in data.LuckChain). Capped at MAX_LUCK.
function Config.petLuckTotal(data)
	return Config.teamStat(data, "Luck")
end

function Config.luck(data, isBonus, world, multiplier)
	local fromPets = Config.petLuckTotal(data)
	local luck = Config.upgradeValue(data, "Luck") * fromPets * Config.rebirthLuck(data.Rebirths or 0)
	luck *= Config.AREAS[math.clamp(world or 1, 1, #Config.AREAS)].Luck
	if isBonus then
		luck *= Config.BONUS_LUCK
	end
	luck *= multiplier or Config.luckMultiplier(data)
	return math.min(luck, Config.MAX_LUCK)
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

-- No single step of a roll is ever certain: a step hits at most 99% of the
-- time. Without this, enough luck would make one pet certain and every pet
-- after it (including later-world pets in earlier worlds) impossible. With
-- it, every animal always has a real, non-zero chance in every world.
Config.MAX_HIT = 0.99

-- the chance one step of the roll hits this pet
function Config.hitChance(pet, luck, world)
	return math.clamp(luck / Config.worldOdds(pet, world), 0, Config.MAX_HIT)
end

-- Try the rarest pet first, then the next rarest, and so on. Luck multiplies
-- every pet's chance; if nothing hits you get the most common pet.
function Config.roll(luck, random, world)
	for i = #Config.PETS, 2, -1 do
		local pet = Config.PETS[i]
		if random:NextNumber() < Config.hitChance(pet, luck, world) then
			return pet
		end
	end
	return Config.PETS[1]
end

-- The exact chance (0..1) of every animal on one roll with this luck in this
-- world. It follows Config.roll step by step: the rarest animal is tried
-- first, and each one only gets its turn if every rarer one missed. These
-- are the numbers shown on the pets while hatching, so they always match
-- what the server actually rolls.
local chanceCache, cached = {}, 0
function Config.petChances(luck, world)
	local key = string.format("%.9g|%d", luck, world or 0)
	local known = chanceCache[key]
	if known then
		return known
	end
	local chances, remaining = {}, 1
	for i = #Config.PETS, 2, -1 do
		local pet = Config.PETS[i]
		local hit = Config.hitChance(pet, luck, world)
		chances[pet.Name] = remaining * hit
		remaining *= 1 - hit
	end
	chances[Config.PETS[1].Name] = remaining
	cached += 1
	if cached > 200 then
		table.clear(chanceCache)
		cached = 1
	end
	chanceCache[key] = chances
	return chances
end

-- The exact chance of each size (index -> 0..1), following Config.rollSize
function Config.sizeChances(sizeLuck)
	local chances, remaining = {}, 1
	for i = #Config.SIZES, 2, -1 do
		local hit = math.clamp(sizeLuck / Config.SIZES[i].Chance, 0, 1)
		chances[i] = remaining * hit
		remaining *= 1 - hit
	end
	chances[1] = remaining
	return chances
end

-- The exact chance of getting exactly this pet in this size ("Huge Tiger"),
-- or the luck boost (Config.BOOST.Name), on one roll with this luck, size
-- luck and world (following Config.rollResult step by step)
function Config.chanceOf(name, luck, sizeLuck, world)
	if name == Config.BOOST.Name then
		return Config.BOOST_CHANCE
	end
	local pet, size = Config.petInfo(name)
	if not pet then
		return 0
	end
	return (1 - Config.BOOST_CHANCE) * Config.petChances(luck, world)[pet.Name] * Config.sizeChances(sizeLuck)[size.Index]
end

-- A chance as "1 in N" ("1 in 2.5", "1 in 500", "1 in 12.5K", "1 in 1.1M")
-- How rare a pet is on its own ("1 in N" before any luck), counting its
-- size: a Huge Fox is a Fox's odds x the Huge chance
function Config.oddsOf(name)
	local pet, size = Config.petInfo(name)
	if not pet then
		return 0
	end
	return pet.Odds * size.Chance
end

-- Odds as the short "1/430K" form used on pet tiles
function Config.shortOdds(odds)
	if not odds or odds <= 0 or odds ~= odds then
		return "-"
	end
	return "1/" .. Config.formatNumber(odds)
end

function Config.formatChance(chance)
	if not chance or chance <= 0 or chance ~= chance then
		return "not possible"
	end
	local odds = 1 / chance
	if odds < 100 then
		local text = string.format("%.1f", odds):gsub("%.0$", "")
		return "1 in " .. text
	end
	return "1 in " .. Config.formatNumber(math.floor(odds + 0.5))
end

-- One roll, the way the server does it: first a chance at a luck boost,
-- otherwise a pet (Config.roll) and its size (Config.rollSize). Returns
-- { Kind = "Boost" } or { Kind = "Pet", Pet = <pet row>, Size = <index> }.
function Config.rollResult(luck, sizeLuck, world, random)
	if random:NextNumber() < Config.BOOST_CHANCE then
		return { Kind = "Boost" }
	end
	local pet = Config.roll(luck, random, world)
	return { Kind = "Pet", Pet = pet, Size = Config.rollSize(sizeLuck, random) }
end

-- Index milestones ----------------------------------------------------------------------
-- Surprise rewards for discovering animals. Size is the Index category
-- (1 Normal, 2 Huge, 3 Titanic), Count how many of it you've found. Coins
-- are paid once; Boost multiplies the luck boost waiting for your next roll
-- (like hatching x2 LUCK boosts). Claimed ids are saved in data.Milestones,
-- so each one can only ever be claimed once. Coin amounts are a few minutes
-- of income at the point most players reach them (tools/economy/simulate.py).
Config.MILESTONES = {
	{ Id = "n5", Size = 1, Count = 5, Coins = 100, Boost = 1 },
	{ Id = "n10", Size = 1, Count = 10, Coins = 300, Boost = 2 },
	{ Id = "n15", Size = 1, Count = 15, Coins = 600, Boost = 1 },
	{ Id = "n20", Size = 1, Count = 20, Coins = 1e3, Boost = 2 },
	{ Id = "n25", Size = 1, Count = 25, Coins = 1e5, Boost = 1 },
	{ Id = "n30", Size = 1, Count = 30, Coins = 2e5, Boost = 4 },
	{ Id = "n40", Size = 1, Count = 40, Coins = 7.5e5, Boost = 1 },
	{ Id = "n50", Size = 1, Count = 50, Coins = 1.5e8, Boost = 8 },
	{ Id = "n60", Size = 1, Count = 60, Coins = 1e9, Boost = 1 },
	{ Id = "n70", Size = 1, Count = 70, Coins = 1e12, Boost = 16 },
	{ Id = "h1", Size = 2, Count = 1, Coins = 800, Boost = 2 },
	{ Id = "h5", Size = 2, Count = 5, Coins = 1.5e3, Boost = 1 },
	{ Id = "h15", Size = 2, Count = 15, Coins = 3e5, Boost = 4 },
	{ Id = "t1", Size = 3, Count = 1, Coins = 2e3, Boost = 4 },
	{ Id = "t5", Size = 3, Count = 5, Coins = 5e5, Boost = 1 },
}

Config.MILESTONES_BY_ID = {}
for _, m in ipairs(Config.MILESTONES) do
	Config.MILESTONES_BY_ID[m.Id] = m
end

-- How many animals of a size (1 Normal, 2 Huge, 3 Titanic) are discovered
function Config.discoveredCount(data, sizeIndex)
	local n = 0
	for _, pet in ipairs(Config.PETS) do
		if data.Discovered and data.Discovered[Config.petName(pet.Name, sizeIndex)] then
			n += 1
		end
	end
	return n
end

-- Can this milestone be claimed now? (true) or (false, why)
function Config.canClaimMilestone(data, id)
	local m = Config.MILESTONES_BY_ID[id]
	if not m then
		return false, "Unknown reward"
	elseif data.Milestones and data.Milestones[id] then
		return false, "Already claimed"
	elseif Config.discoveredCount(data, m.Size) < m.Count then
		return false, "Not reached yet"
	end
	return true
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

-- One hit of a pet: its power x the Damage upgrade x its own Damage stat
function Config.hitDamage(data, name)
	return Config.petPower(name) * Config.upgradeValue(data, "Damage") * Config.petStat(name, "Damage")
end

-- One equipped pet's damage per second
function Config.petDps(data, name)
	return Config.hitDamage(data, name) / Config.PET_HIT_EVERY
end

-- The best team you can equip: as many pets as you have slots for, chosen
-- by what they really add to the team. Each pet's damage is its own (power
-- x the Damage upgrade x its own Damage stat), so the strongest team is the
-- pets with the most damage per second (NOT just the highest power: a pet
-- with a better Damage stat can beat a slightly stronger one). Ties go to
-- the bigger luck bonus, then the bigger coin bonus. Copies count up to
-- how many you own; pets you don't own are never picked.
function Config.bestTeam(data)
	local slots = Config.maxEquipped(data)
	local copies = {}
	for name, count in pairs(data.Pets or {}) do
		if type(count) == "number" and count > 0 and Config.petInfo(name) then
			for _ = 1, math.min(count, slots) do
				table.insert(copies, name)
			end
		end
	end
	local dps, luck, coins = {}, {}, {}
	for _, name in ipairs(copies) do
		dps[name] = dps[name] or Config.petDps(data, name)
		luck[name] = luck[name] or Config.petStat(name, "Luck")
		coins[name] = coins[name] or Config.petStat(name, "Coins")
	end
	table.sort(copies, function(a, b)
		if dps[a] ~= dps[b] then
			return dps[a] > dps[b]
		elseif luck[a] ~= luck[b] then
			return luck[a] > luck[b]
		elseif coins[a] ~= coins[b] then
			return coins[a] > coins[b]
		end
		return a < b
	end)
	local team = {}
	for i = 1, math.min(#copies, slots) do
		team[i] = copies[i]
	end
	return team
end

-- true if two pet lists hold the same pets (order doesn't matter)
function Config.sameTeam(a, b)
	if #a ~= #b then
		return false
	end
	local counts = {}
	for _, name in ipairs(a) do
		counts[name] = (counts[name] or 0) + 1
	end
	for _, name in ipairs(b) do
		if not counts[name] or counts[name] == 0 then
			return false
		end
		counts[name] -= 1
	end
	return true
end

-- Each equipped pet's share of the team's damage, as whole percents that
-- add up to exactly 100 (largest remainders get the rounding); all zeros
-- when the team deals nothing. Returns { { Name, Dps, Percent }, ... } in
-- slot order.
function Config.teamShares(data)
	local shares, total = {}, 0
	for _, name in ipairs(data.Equipped or {}) do
		local dps = Config.petDps(data, name)
		total += dps
		table.insert(shares, { Name = name, Dps = dps, Percent = 0 })
	end
	if total <= 0 or total ~= total then
		return shares, 0
	end
	local used, order = 0, {}
	for i, share in ipairs(shares) do
		local exact = share.Dps / total * 100
		share.Percent = math.floor(exact)
		share.Rest = exact - share.Percent
		used += share.Percent
		order[i] = i
	end
	table.sort(order, function(a, b)
		return shares[a].Rest > shares[b].Rest
	end)
	for k = 1, 100 - used do
		local share = shares[order[(k - 1) % #order + 1]]
		share.Percent += 1
	end
	return shares, total
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
		Cost = 2.5e4,
		Color = Color3.fromRGB(240, 190, 90),
		Breakable = { Name = "Cactus", Health = 1.2e8, Coins = 600, Exp = 4 },
	},
	{
		Name = "Frozen Peaks",
		Luck = 1.45, -- rolling here multiplies luck
		Cost = 1.2e7,
		Color = Color3.fromRGB(140, 215, 255),
		Breakable = { Name = "Ice Cube", Health = 3e10, Coins = 4e4, Exp = 15 },
	},
	{
		Name = "Sakura Jungle",
		Luck = 1.75, -- rolling here multiplies luck
		Cost = 1.3e11,
		Color = Color3.fromRGB(255, 150, 200),
		Breakable = { Name = "Sushi", Health = 1.2e13, Coins = 3e6, Exp = 50 },
	},
}

-- TESTING ONLY (temporary): every area unlock costs this many coins (0)
-- instead of its real Cost. The gates, borders, signs and unlock buttons
-- all work as normal: areas start locked and you unlock them at the gate,
-- you just pay nothing. BEFORE THE FINAL VERSION set this to nil so the
-- real costs (25K / 12M / 130B) apply (see CLAUDE.md).
Config.AREA_COST_FOR_TESTING = 0
-- TESTING ONLY (temporary): every join starts with only World 1 unlocked,
-- even if the save has more (older test builds opened every area), so the
-- locked gates can be looked at. BEFORE THE FINAL VERSION set this to false.
Config.RELOCK_AREAS_FOR_TESTING = true

function Config.areaCost(i)
	if Config.AREA_COST_FOR_TESTING then
		return Config.AREA_COST_FOR_TESTING
	end
	return Config.AREAS[i].Cost
end

-- What the gate says the unlock costs
function Config.areaCostText(i)
	if Config.AREA_COST_FOR_TESTING then
		return Config.formatNumber(Config.AREA_COST_FOR_TESTING) .. " COINS (TEST)"
	end
	return Config.formatNumber(Config.AREAS[i].Cost) .. " COINS"
end

-- The highest area a player has on join and after a rebirth
function Config.startingArea()
	return 1
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
-- x(1 + 3 x 2) = x7. There are 8 rebirths: the first after about 10
-- minutes of play, the 8th after about 3 hours (balanced with
-- tools/economy/simulate.py).
Config.REBIRTH_LUCK = 1.5 -- luck is multiplied by this per rebirth
Config.REBIRTH_COINS = 2 -- +200% coins per rebirth
Config.REBIRTHS = {
	{ Cost = 1.2e4, Level = 16 },
	{ Cost = 3e6, Level = 34 },
	{ Cost = 3e9, Level = 52 },
	{ Cost = 1.5e10, Level = 64 },
	{ Cost = 4e10, Level = 70 },
	{ Cost = 7.5e10, Level = 75 },
	{ Cost = 1e13, Level = 82 },
	{ Cost = 4e13, Level = 88 },
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
-- Level 1 -> 2 needs LEVEL_BASE (10) EXP, and every level needs
-- LEVEL_GROWTH (1.1x) as much as the one before: 10, 11, 12.1, 13.3, ...
-- (level 50 -> 51 ~1.07K, level 100 -> 101 ~125K). Levels never reset.
Config.LEVEL_BASE = 10
Config.LEVEL_GROWTH = 1.1

-- EXP needed to go from `level` to the next (rounded to a whole number)
function Config.expToNext(level)
	return math.floor(Config.LEVEL_BASE * Config.LEVEL_GROWTH ^ (level - 1) + 0.5)
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

-- All coin bonuses together: rebirths, the Coins upgrade and the equipped
-- pets' Coins stats (added up)
function Config.coinGain(data)
	return Config.coinMultiplier(data.Rebirths) * Config.upgradeValue(data, "Coins") * Config.teamStat(data, "Coins")
end

-- EXP bonus: the equipped pets' EXP stats (added up)
function Config.expGain(data)
	return Config.teamStat(data, "Exp")
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
	if scaled >= 1000 then
		-- past the last suffix: short scientific form, never a long digit string
		return string.format("%.2fe%d", n / 10 ^ math.floor(math.log10(n)), math.floor(math.log10(n)))
	end
	local text = if scaled < 100 then string.format("%.2f", scaled) else string.format("%.1f", scaled)
	text = text:gsub("%.?0+$", "")
	return text .. SUFFIXES[tier + 1]
end

-- A multiplier as "1.25x" (up to two decimals, no trailing zeros)
function Config.formatStat(value)
	if value >= 1000 then
		return Config.formatNumber(value) .. "x"
	end
	local text = string.format(if value >= 100 then "%.0f" elseif value >= 10 then "%.1f" else "%.2f", value)
	text = text:gsub("(%..-)0+$", "%1"):gsub("%.$", "")
	return text .. "x"
end

-- "1 in 1,000,000"
function Config.formatOdds(odds)
	return "1 in " .. Config.formatNumber(odds)
end

return Config
