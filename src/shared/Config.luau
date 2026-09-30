-- Game numbers and formulas, shared by the server and the client so the UI
-- always shows exactly what the server will do.
local Config = {}

-- Trainers earn energy every second. Each one costs 15% more than the last,
-- and every 25 owned doubles that trainer's output.
Config.TRAINERS = {
	{ Id = "Bowl", Name = "Treat Bowl", Icon = "🥣", Cost = 15, Rate = 0.5 },
	{ Id = "Toy", Name = "Squeaky Toy", Icon = "🧸", Cost = 100, Rate = 3 },
	{ Id = "Wheel", Name = "Hamster Wheel", Icon = "🎡", Cost = 1100, Rate = 20 },
	{ Id = "Dojo", Name = "Training Dojo", Icon = "🥋", Cost = 12000, Rate = 110 },
	{ Id = "Farm", Name = "Protein Farm", Icon = "🌾", Cost = 130000, Rate = 700 },
	{ Id = "Gym", Name = "Gym Tower", Icon = "🏋️", Cost = 1.4e6, Rate = 4500 },
	{ Id = "Spring", Name = "Mana Spring", Icon = "⛲", Cost = 2e7, Rate = 30000 },
	{ Id = "Forge", Name = "Star Forge", Icon = "🌟", Cost = 3.3e8, Rate = 200000 },
	{ Id = "Rift", Name = "Void Rift", Icon = "🌀", Cost = 5.1e9, Rate = 1.4e6 },
	{ Id = "Nexus", Name = "Cosmic Nexus", Icon = "🪐", Cost = 7.5e10, Rate = 1e7 },
}
Config.TRAINERS_BY_ID = {}
for _, trainer in ipairs(Config.TRAINERS) do
	Config.TRAINERS_BY_ID[trainer.Id] = trainer
end

Config.COST_GROWTH = 1.15
Config.MILESTONE = 25 -- every 25 of a trainer doubles its output

-- Tap upgrade: more energy per tap, plus a share of your energy per second
Config.TAP_COST = 50
Config.TAP_COST_GROWTH = 2.2

-- Ascending resets energy, trainers and taps for Stars. Each star is +10%
-- energy and pet power forever, and the pet evolves into its next form.
Config.ASCEND_MIN = 1e6 -- energy earned this run needed to ascend
Config.STAR_BONUS = 0.1

-- Pet forms, unlocked by how many times you've ascended
Config.FORMS = {
	{ Ascensions = 0, Name = "Sprout Pup", Color = Color3.fromRGB(140, 220, 120), Glow = Color3.fromRGB(200, 255, 170) },
	{ Ascensions = 1, Name = "Fluffball", Color = Color3.fromRGB(255, 190, 120), Glow = Color3.fromRGB(255, 230, 170) },
	{ Ascensions = 2, Name = "Brawler", Color = Color3.fromRGB(235, 95, 85), Glow = Color3.fromRGB(255, 170, 120) },
	{ Ascensions = 3, Name = "Guardian", Color = Color3.fromRGB(80, 150, 255), Glow = Color3.fromRGB(160, 210, 255) },
	{ Ascensions = 5, Name = "Titan", Color = Color3.fromRGB(150, 90, 230), Glow = Color3.fromRGB(210, 160, 255) },
	{ Ascensions = 8, Name = "Celestial", Color = Color3.fromRGB(255, 225, 90), Glow = Color3.fromRGB(255, 250, 200) },
	{ Ascensions = 12, Name = "Cosmic Beast", Color = Color3.fromRGB(40, 30, 90), Glow = Color3.fromRGB(120, 230, 255) },
	{ Ascensions = 20, Name = "Godbeast", Color = Color3.fromRGB(255, 255, 255), Glow = Color3.fromRGB(255, 120, 220) },
}

-- Offline earnings: half speed, up to 8 hours
Config.OFFLINE_RATE = 0.5
Config.OFFLINE_MAX = 8 * 60 * 60

Config.MAX_TAPS_PER_SECOND = 20

-- Formulas -------------------------------------------------------------------

function Config.trainerCost(trainer, owned)
	return math.floor(trainer.Cost * Config.COST_GROWTH ^ owned)
end

-- Total cost of buying `amount` more, and how many you can afford with
-- `energy` (up to `limit`)
function Config.trainerBulk(trainer, owned, energy, limit)
	local count, total = 0, 0
	while count < limit do
		local cost = Config.trainerCost(trainer, owned + count)
		if total + cost > energy then
			break
		end
		total += cost
		count += 1
	end
	return count, total
end

function Config.starMultiplier(stars)
	return 1 + stars * Config.STAR_BONUS
end

function Config.trainerRate(trainer, owned, stars)
	if owned <= 0 then
		return 0
	end
	local milestones = math.floor(owned / Config.MILESTONE)
	return trainer.Rate * owned * 2 ^ milestones * Config.starMultiplier(stars)
end

function Config.perSecond(data)
	local total = 0
	for _, trainer in ipairs(Config.TRAINERS) do
		total += Config.trainerRate(trainer, data.Trainers[trainer.Id] or 0, data.Stars)
	end
	return total
end

function Config.tapCost(level)
	return math.floor(Config.TAP_COST * Config.TAP_COST_GROWTH ^ level)
end

function Config.tapValue(data)
	local level = data.TapLevel
	local base = (1 + level) ^ 1.5 * Config.starMultiplier(data.Stars)
	return base + Config.perSecond(data) * 0.02 * level
end

-- The pet's power grows with the energy earned this run, boosted by stars
function Config.petPower(data)
	return math.floor(data.RunEarned ^ 0.75 * Config.starMultiplier(data.Stars))
end

function Config.starsFor(runEarned)
	if runEarned < Config.ASCEND_MIN then
		return 0
	end
	return math.floor(10 * (runEarned / Config.ASCEND_MIN) ^ 0.3)
end

function Config.form(ascensions)
	local current, index = Config.FORMS[1], 1
	for i, form in ipairs(Config.FORMS) do
		if ascensions >= form.Ascensions then
			current, index = form, i
		end
	end
	return current, index
end

-- How big the pet is drawn: grows with power, and a bit per form
function Config.petScale(power, formIndex)
	local grow = 1 + math.log10(power + 1) * 0.18 + (formIndex - 1) * 0.15
	return math.min(grow, 7)
end

-- Leaderboard: OrderedDataStores only hold integers, so power is stored as
-- log10(power) * 10000 and decoded back for display.
function Config.encodePower(power)
	if power < 1 then
		return 0
	end
	return math.floor(math.log10(power) * 10000)
end

function Config.decodePower(value)
	return 10 ^ (value / 10000)
end

-- Number formatting ------------------------------------------------------------

local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc" }

function Config.formatNumber(n)
	if n ~= n then
		return "0"
	end
	if n < 1000 then
		if n < 10 and n ~= math.floor(n) then
			return string.format("%.1f", n)
		end
		return tostring(math.floor(n))
	end
	local tier = math.floor(math.log10(n) / 3)
	if tier >= #SUFFIXES then
		return string.format("%.2fe%d", n / 10 ^ math.floor(math.log10(n)), math.floor(math.log10(n)))
	end
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

function Config.formatTime(seconds)
	seconds = math.floor(seconds)
	local h, m = math.floor(seconds / 3600), math.floor(seconds % 3600 / 60)
	if h > 0 then
		return string.format("%dh %dm", h, m)
	elseif m > 0 then
		return string.format("%dm %ds", m, seconds % 60)
	end
	return seconds .. "s"
end

return Config
