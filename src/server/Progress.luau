-- Area gates (pay coins to unlock the next area) and rebirths (reset coins
-- and areas for a permanent coin bonus). Servers are solo, so gates open for
-- the whole server when its player unlocks them.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Security = require(script.Parent.Security)
local PlayerData = require(script.Parent.PlayerData)
local World = require(script.Parent.World)

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local notifyEvent = remotes:WaitForChild("Notify")
local rebirthFunction = Instance.new("RemoteFunction")
rebirthFunction.Name = "Rebirth"
rebirthFunction.Parent = remotes

-- Index milestones: the reward is given once, right here on the server.
-- The claim is marked before the reward is added and it all happens in one
-- go (no yields), so double clicks, rejoins or replays can't pay twice.
local claimFunction = Instance.new("RemoteFunction")
claimFunction.Name = "ClaimMilestone"
claimFunction.Parent = remotes
claimFunction.OnServerInvoke = Security.guard("ClaimMilestone", function(player, id)
	local data = PlayerData.get(player)
	if not data or type(id) ~= "string" then
		return nil
	end
	data.Milestones = data.Milestones or {}
	local ok = Config.canClaimMilestone(data, id)
	if not ok then
		return nil
	end
	local m = Config.MILESTONES_BY_ID[id]
	data.Milestones[id] = true
	data.Coins += m.Coins
	if m.Boost > 1 then
		data.LuckChain = math.min(Config.luckMultiplier(data) * m.Boost, Config.CHAIN_MAX)
	end
	PlayerData.sync(player)
	return { Id = id, Coins = m.Coins, Boost = m.Boost, LuckChain = data.LuckChain }
end, 4)

local function refreshGates(unlocked)
	for i = 2, #Config.AREAS do
		World.setGateOpen(i, i <= unlocked)
	end
end

-- Feeding a gatekeeper opens its gate: the world's price buys the animal's
-- food (World.Gates[i].Keeper's "Food"). It answers in a speech bubble
-- (client/Gatekeeper.luau): with the coins, "Yum!", a short cutscene (the
-- food flies to it, it munches, the wall sinks into the ground) and the gate
-- opens when it's over (Config.GATE_OPEN_DELAY); without, it's still hungry.
local sayEvent = Instance.new("RemoteEvent")
sayEvent.Name = "GatekeeperSay" -- server -> client: (gate index, text, "yes" | "no", food)
sayEvent.Parent = remotes

for i, gate in pairs(World.Gates) do
	gate.Prompt.Triggered:Connect(function(player)
		local data = PlayerData.get(player)
		if not data or data.Unlocked >= i then
			return
		end
		local area = Config.AREAS[i]
		local food = gate.Keeper and gate.Keeper:GetAttribute("Food") or "snack"
		if data.Unlocked < i - 1 then
			sayEvent:FireClient(player, i, "Open the " .. Config.AREAS[i - 1].Name .. " first!", "no", food)
			return
		end
		local cost = Config.areaCost(i)
		if data.Coins < cost then
			sayEvent:FireClient(player, i, string.format("I'm hungry! A %s costs %s coins, you need %s more.",
				string.lower(food), Config.formatNumber(cost), Config.formatNumber(cost - data.Coins)), "no", food)
			return
		end
		data.Coins -= cost
		data.Unlocked = i
		PlayerData.sync(player)
		sayEvent:FireClient(player, i, "Yum! Thank you! Welcome to the " .. area.Name .. "!", "yes", food)
		local function open()
			local now = PlayerData.get(player)
			if now then
				refreshGates(now.Unlocked)
				notifyEvent:FireClient(player, area.Name .. " unlocked!", "success")
			end
		end
		if (Config.GATE_OPEN_DELAY or 0) > 0 then
			task.delay(Config.GATE_OPEN_DELAY, open)
		else
			open()
		end
	end)
end

-- Tutorials the player has seen (client/Tutorial.luau): only known keys,
-- so nothing else can be written into the save
local SEEN_KEYS = { Tutorial = true }
for i = 2, #Config.AREAS do
	SEEN_KEYS["World" .. i] = true
end
local seenFunction = Instance.new("RemoteFunction")
seenFunction.Name = "MarkSeen" -- client -> server: (key) -> true
seenFunction.Parent = remotes
seenFunction.OnServerInvoke = Security.guard("MarkSeen", function(player, key)
	local data = PlayerData.get(player)
	if not data or type(key) ~= "string" or not SEEN_KEYS[key] then
		return false
	end
	data.Seen = data.Seen or {}
	data.Seen[key] = true
	PlayerData.sync(player)
	return true
end, 4)

rebirthFunction.OnServerInvoke = Security.guard("Rebirth", function(player)
	local data = PlayerData.get(player)
	if not data then
		return false
	end
	-- both the coins and the level are needed, and there are 8 rebirths
	local row = Config.nextRebirth(data.Rebirths)
	if not row then
		notifyEvent:FireClient(player, "You've reached the max rebirth (" .. Config.MAX_REBIRTHS .. ")!", "danger")
		return false
	end
	local ok, hasCoins, hasLevel = Config.canRebirth(data)
	if not ok then
		local cost = Config.rebirthCost(data.Rebirths)
		local missing = {}
		if not hasCoins then
			table.insert(missing, Config.formatNumber(cost - data.Coins) .. " more coins")
		end
		if not hasLevel then
			table.insert(missing, "level " .. row.Level .. " (you're level " .. (data.Level or 1) .. ")")
		end
		notifyEvent:FireClient(player, "You need " .. table.concat(missing, " and "), "danger")
		return false
	end
	-- a prestige, not a restart: only the coins reset. Worlds, pets,
	-- upgrades, the Index and the level all stay.
	data.Coins = 0
	data.Rebirths += 1
	PlayerData.sync(player)
	notifyEvent:FireClient(player, string.format("Rebirth %d!  Luck x%.2f  ·  Coins x%d", data.Rebirths, Config.rebirthLuck(data.Rebirths), Config.coinMultiplier(data.Rebirths)), "success")
	return true
end, 2)

local function onLoaded(player)
	local data = PlayerData.get(player)
	if data then
		if Config.RELOCK_AREAS_FOR_TESTING then
			data.Unlocked = Config.startingArea() -- (testing: see Config)
		end
		data.Unlocked = math.max(data.Unlocked, Config.startingArea())
		refreshGates(data.Unlocked)
		PlayerData.sync(player)
	end
end

PlayerData.Loaded.Event:Connect(onLoaded)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onLoaded, player)
end
refreshGates(Config.startingArea())

return {}
