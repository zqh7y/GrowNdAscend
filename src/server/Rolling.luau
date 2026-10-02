-- Rolling pets and equipping them. The server picks every roll (pet and
-- size); the client only asks and plays the reveal.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Security = require(script.Parent.Security)
local PlayerData = require(script.Parent.PlayerData)
local World = require(script.Parent.World)
local Leaderboard = require(script.Parent.Leaderboards)

local remotes = ReplicatedStorage:WaitForChild("Remotes")

local function remote(className, name)
	local r = Instance.new(className)
	r.Name = name
	r.Parent = remotes
	return r
end

local rollFunction = remote("RemoteFunction", "Roll")
local equipFunction = remote("RemoteFunction", "Equip")
local equipBestFunction = remote("RemoteFunction", "EquipBest")
local megaFunction = remote("RemoteFunction", "MegaRoll")

local Rolling = {}
local random = Random.new()

-- (for the simulator) swap the random source to script exact outcomes
function Rolling.setRandom(source)
	random = source or Random.new()
end
local lastRoll = {} -- [player] = os.clock() of their last roll

-- gives the player their next Mega Roll (multiplier and when it's ready)
-- (the server clock: unix time, the same one the client counts down with)
local function now()
	return workspace:GetServerTimeNow()
end
local function nextMega(data, wait)
	data.MegaMult = Config.pickMega(random)
	data.MegaReady = now() + wait
end

local function onLoaded(player)
	local data = PlayerData.get(player)
	if not data then
		return
	end
	if type(data.MegaMult) ~= "number" or type(data.MegaReady) ~= "number" then
		nextMega(data, Config.MEGA_ROLL.First)
	elseif data.MegaMult > Config.MEGA_ROLL.Max then
		data.MegaMult = Config.pickMega(random) -- (from before the nerf)
	end
	-- Mega Rolls saved from before the nerf come down to the new top
	for i, m in ipairs(data.MegaRolls or {}) do
		if type(m) == "number" and m > Config.MEGA_ROLL.Max then
			data.MegaRolls[i] = Config.MEGA_ROLL.Max
		end
	end
	PlayerData.updateStrongest(player)
	PlayerData.sync(player)
	Leaderboard.send(player)
end

PlayerData.Loaded.Event:Connect(onLoaded)

-- Equips the best team the player owns (Config.bestTeam: real damage per
-- second, then luck, then coins; copies and slots respected). Returns
-- whether anything changed and the pets that joined.
local function equipBest(data)
	local best = Config.bestTeam(data)
	if Config.sameTeam(best, data.Equipped) then
		return false, {}
	end
	-- the pets that join (copies counted)
	local had = {}
	for _, name in ipairs(data.Equipped) do
		had[name] = (had[name] or 0) + 1
	end
	local added = {}
	for _, name in ipairs(best) do
		if had[name] and had[name] > 0 then
			had[name] -= 1
		else
			table.insert(added, name)
		end
	end
	data.Equipped = best
	return true, added
end

-- How many of this pet are equipped
local function equippedCount(data, name)
	local n = 0
	for _, equipped in ipairs(data.Equipped) do
		if equipped == name then
			n += 1
		end
	end
	return n
end

-- Adds a hatched pet to the player's collection; returns the result for
-- the client (`extra` fields added to it)
local function award(data, outcome, extra)
	local pet, sizeIndex = outcome.Pet, outcome.Size
	local name = Config.petName(pet.Name, sizeIndex)
	local isFirst = not data.Discovered[pet.Name]
	local isFirstOfSize = not data.Discovered[name]
	PlayerData.discover(data, name)
	data.Pets[name] = (data.Pets[name] or 0) + 1
	data.Obtained = data.Obtained or {}
	data.Obtained[name] = data.Rolls -- (for sorting by newest)
	local best = data.Best and Config.PETS_BY_NAME[data.Best]
	if not best or pet.Odds > best.Odds then
		data.Best = pet.Name
	end
	local result = {
		Kind = "Pet",
		Pet = pet.Name,
		Size = sizeIndex,
		Name = name,
		First = isFirst,
		FirstOfSize = isFirstOfSize,
	}
	for k, v in pairs(extra) do
		result[k] = v
	end
	return result
end

rollFunction.OnServerInvoke = Security.guard("Roll", function(player)
	local data = PlayerData.get(player)
	if not data then
		return nil
	end
	local now = os.clock()
	-- a little slack for network jitter
	if lastRoll[player] and now - lastRoll[player] < Config.rollCooldown(data) * 0.85 then
		return nil
	end
	lastRoll[player] = now

	-- the world you roll in changes the odds (every animal is possible anywhere)
	local world = PlayerData.worldOf(player)
	local results = {}
	local sizeLuck = Config.sizeLuck(data)
	-- the luck boost waiting from the last spin applies to every roll of
	-- this spin and is used up by it. Each roll is either a pet or a "x2
	-- LUCK" boost; boosts hatched now multiply into the next spin's boost.
	-- The exact luck of every roll goes back to the client, so the odds it
	-- shows are computed from the very same numbers. All of this happens in
	-- one go (no yields), so rapid rolls can't use a boost twice.
	local multiplier = Config.luckMultiplier(data)
	local boosts = 0
	for _ = 1, Config.rollsAtOnce(data) do
		data.Rolls += 1
		local isBonus = data.Rolls % Config.BONUS_EVERY == 0
		local luck = Config.luck(data, isBonus, world, multiplier)
		local rollSizeLuck = sizeLuck * (if isBonus then Config.BONUS_LUCK else 1)
		local outcome = Config.rollResult(luck, rollSizeLuck, world, random)
		if outcome.Kind == "Boost" then
			boosts += 1
			table.insert(results, {
				Kind = "Boost",
				Name = Config.BOOST.Name,
				Boost = Config.BOOST.Multiplier,
				Bonus = isBonus,
				World = world,
				Luck = luck,
				SizeLuck = rollSizeLuck,
				Multiplier = multiplier,
			})
		else
			table.insert(results, award(data, outcome, {
				Bonus = isBonus,
				World = world,
				Luck = luck,
				SizeLuck = rollSizeLuck,
				Multiplier = multiplier,
			}))
		end
	end
	-- the boost for the next spin: this one's x 2 per boost hatched, or none
	data.LuckChain = Config.nextChain(multiplier, boosts)
	for _, result in ipairs(results) do
		result.NextMultiplier = data.LuckChain
	end

	-- Auto Hatch level 2 keeps the strongest team equipped
	if Config.upgradeLevel(data, "AutoHatch") >= 2 then
		equipBest(data)
	end
	PlayerData.updateStrongest(player)
	PlayerData.sync(player)
	return results
end, 20)

-- The Mega Roll pad: once its timer is done, standing on it claims a Mega
-- Roll (the multiplier shown on the pad) into your Boosts (data.MegaRolls).
-- The pad then gets a new random multiplier and a fresh timer. Returns the
-- multiplier claimed, or nil and why not.
function Rolling.megaRoll(player)
	local data = PlayerData.get(player)
	if not data or type(data.MegaReady) ~= "number" then
		return nil, "loading"
	end
	if now() < data.MegaReady then
		return nil, "not ready"
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local pad = World.MegaPad
	if not root or not pad then
		return nil, "no pad"
	end
	local flat = Vector3.new(root.Position.X - pad.X, 0, root.Position.Z - pad.Z)
	if flat.Magnitude > Config.MEGA_ROLL.Radius + 4 then
		return nil, "too far"
	end
	local mega = data.MegaMult
	data.MegaRolls = data.MegaRolls or {}
	table.insert(data.MegaRolls, mega)
	nextMega(data, Config.MEGA_ROLL.Cooldown)
	PlayerData.sync(player)
	return mega
end

-- Uses one Mega Roll with multiplier `mega` from your Boosts: one roll with
-- that luck (past MAX_LUCK, up to MEGA_ROLL.LuckCap) in the world you stand
-- in; it always gives a pet. Returns the results (like Roll), or nil and why.
function Rolling.useMega(player, mega)
	local data = PlayerData.get(player)
	if not data or type(mega) ~= "number" then
		return nil, "loading"
	end
	local index = table.find(data.MegaRolls or {}, mega)
	if not index then
		return nil, "none"
	end
	local world = PlayerData.worldOf(player)
	local luck = math.min(Config.luck(data, false, world, 1) * mega, Config.MEGA_ROLL.LuckCap)
	local sizeLuck = Config.sizeLuck(data)
	local outcome
	for _ = 1, 50 do
		outcome = Config.rollResult(luck, sizeLuck, world, random)
		if outcome.Kind ~= "Boost" then
			break
		end
	end
	if outcome.Kind == "Boost" then
		return nil, "no pet"
	end
	table.remove(data.MegaRolls, index)
	data.Rolls += 1
	local result = award(data, outcome, {
		World = world,
		Luck = luck,
		SizeLuck = sizeLuck,
		Multiplier = 1,
		Mega = mega,
		NextMultiplier = Config.luckMultiplier(data),
	})
	if Config.upgradeLevel(data, "AutoHatch") >= 2 then
		equipBest(data)
	end
	PlayerData.updateStrongest(player)
	PlayerData.sync(player)
	return { result }
end

megaFunction.OnServerInvoke = Security.guard("MegaRoll", function(player)
	return (Rolling.megaRoll(player))
end, 4)

-- Equips a pet, or unequips it. Several copies of the same pet can be
-- equipped if you own them.
equipFunction.OnServerInvoke = Security.guard("Equip", function(player, name, unequip)
	local data = PlayerData.get(player)
	if not data or type(name) ~= "string" or not Config.petInfo(name) then
		return false
	end
	local index = table.find(data.Equipped, name)
	if unequip then
		if not index then
			return false
		end
		table.remove(data.Equipped, index)
	else
		if equippedCount(data, name) >= (data.Pets[name] or 0) or #data.Equipped >= Config.maxEquipped(data) then
			return false
		end
		table.insert(data.Equipped, name)
	end
	PlayerData.sync(player)
	return true
end, 10)

equipBestFunction.OnServerInvoke = Security.guard("EquipBest", function(player)
	local data = PlayerData.get(player)
	if not data then
		return false
	end
	local changed, added = equipBest(data)
	if changed then
		PlayerData.updateStrongest(player)
	end
	PlayerData.sync(player)
	return { Changed = changed, Added = added, Equipped = table.clone(data.Equipped) }
end, 4)

Players.PlayerRemoving:Connect(function(player)
	lastRoll[player] = nil
end)

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onLoaded, player)
end

return Rolling
