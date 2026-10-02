-- Boosts and getting around:
--   UseItem(kind, value)  uses something from the Inventory's Boosts:
--       ("MegaRoll", multiplier)  one Mega Roll (Rolling.useMega) -> results
--       ("Boost", itemId)         a boost item (Config.ITEMS): the stat is
--                                 multiplied until its time runs out; using
--                                 another of the same stat adds its time
--   BoostClaim()  the Boost Machine in the Frozen Peaks: standing on its
--       circle with the timer done gives a random boost item (by Weight)
--   Teleport(area)  to the start of any world you've unlocked
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Security = require(script.Parent.Security)
local PlayerData = require(script.Parent.PlayerData)
local Rolling = require(script.Parent.Rolling)
local World = require(script.Parent.World)

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local notifyEvent = remotes:WaitForChild("Notify")

local function remote(name)
	local r = Instance.new("RemoteFunction")
	r.Name = name
	r.Parent = remotes
	return r
end
local useFunction = remote("UseItem")
local claimFunction = remote("BoostClaim")
local teleportFunction = remote("Teleport")

local Items = {}
local random = Random.new()

local function now()
	return workspace:GetServerTimeNow()
end

-- (for the simulator) swap the random source
function Items.setRandom(source)
	random = source or Random.new()
end

-- Turns on boost item `id` (one is taken from your Boosts). Returns the
-- active boost { Value, Ends }, or nil and why not.
function Items.useBoost(player, id)
	local data = PlayerData.get(player)
	local item = Config.ITEMS_BY_ID[id]
	if not data or not item then
		return nil, "unknown"
	end
	data.Items = data.Items or {}
	if (data.Items[id] or 0) <= 0 then
		return nil, "none"
	end
	data.Items[id] -= 1
	if data.Items[id] <= 0 then
		data.Items[id] = nil
	end
	data.ActiveBoosts = data.ActiveBoosts or {}
	local active = data.ActiveBoosts[item.Stat]
	local t = now()
	if active and active.Ends > t then
		active.Ends += item.Seconds
		active.Value = math.max(active.Value, item.Value)
	else
		active = { Value = item.Value, Ends = t + item.Seconds }
		data.ActiveBoosts[item.Stat] = active
	end
	PlayerData.sync(player)
	return active
end

useFunction.OnServerInvoke = Security.guard("UseItem", function(player, kind, value)
	if kind == "MegaRoll" then
		return (Rolling.useMega(player, value))
	elseif kind == "Boost" and type(value) == "string" then
		return (Items.useBoost(player, value))
	end
	return nil
end, 10)

-- a random boost item, by weight
local function pickItem()
	local total = 0
	for _, item in ipairs(Config.ITEMS) do
		total += item.Weight
	end
	local r = random:NextNumber() * total
	for _, item in ipairs(Config.ITEMS) do
		r -= item.Weight
		if r <= 0 then
			return item
		end
	end
	return Config.ITEMS[1]
end

-- The Boost Machine: returns the item id given, or nil and why not
function Items.claimBoost(player)
	local data = PlayerData.get(player)
	if not data or type(data.BoostReady) ~= "number" then
		return nil, "loading"
	end
	if now() < data.BoostReady then
		return nil, "not ready"
	end
	local machine = World.BoostMachine
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not machine or not root then
		return nil, "no machine"
	end
	local c = machine.Circle.Position
	if Vector3.new(root.Position.X - c.X, 0, root.Position.Z - c.Z).Magnitude > Config.BOOST_MACHINE.Radius + 3 then
		return nil, "too far"
	end
	local item = pickItem()
	data.Items = data.Items or {}
	data.Items[item.Id] = (data.Items[item.Id] or 0) + 1
	data.BoostReady = now() + Config.BOOST_MACHINE.Cooldown
	PlayerData.sync(player)
	notifyEvent:FireClient(player, item.Name .. " boost added to your Inventory!", "success")
	return item.Id
end

claimFunction.OnServerInvoke = Security.guard("BoostClaim", function(player)
	return (Items.claimBoost(player))
end, 4)

-- Teleports to the start of world `area` (if it's unlocked)
function Items.teleport(player, area)
	local data = PlayerData.get(player)
	if not data or type(area) ~= "number" or not Config.AREAS[area] then
		return false
	end
	if area > data.Unlocked then
		notifyEvent:FireClient(player, "Unlock " .. Config.AREAS[area].Name .. " first!", "danger")
		return false
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or (humanoid and humanoid.Health <= 0) then
		return false
	end
	character:PivotTo(World.Spawns[area])
	root.AssemblyLinearVelocity = Vector3.zero
	return true
end

teleportFunction.OnServerInvoke = Security.guard("Teleport", function(player, area)
	return Items.teleport(player, area)
end, 2)

-- the Boost Machine's first gift comes a minute after joining
PlayerData.Loaded.Event:Connect(function(player)
	local data = PlayerData.get(player)
	if data and type(data.BoostReady) ~= "number" then
		data.BoostReady = now() + Config.BOOST_MACHINE.First
		PlayerData.sync(player)
	end
end)

return Items
