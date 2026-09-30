-- Area gates (pay coins to unlock the next area) and rebirths (reset coins
-- and areas for a permanent coin bonus). Servers are solo, so gates open for
-- the whole server when its player unlocks them.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local PlayerData = require(script.Parent.PlayerData)
local World = require(script.Parent.World)

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local notifyEvent = remotes:WaitForChild("Notify")
local rebirthFunction = Instance.new("RemoteFunction")
rebirthFunction.Name = "Rebirth"
rebirthFunction.Parent = remotes

local function refreshGates(unlocked)
	for i = 2, #Config.AREAS do
		World.setGateOpen(i, i <= unlocked)
	end
end

for i, gate in pairs(World.Gates) do
	gate.Prompt.Triggered:Connect(function(player)
		local data = PlayerData.get(player)
		if not data or data.Unlocked >= i then
			return
		end
		local area = Config.AREAS[i]
		if data.Unlocked < i - 1 then
			notifyEvent:FireClient(player, "Unlock " .. Config.AREAS[i - 1].Name .. " first!", "danger")
			return
		end
		local cost = Config.areaCost(i)
		if data.Coins < cost then
			notifyEvent:FireClient(player, "You need " .. Config.formatNumber(cost - data.Coins) .. " more coins", "danger")
			return
		end
		data.Coins -= cost
		data.Unlocked = i
		refreshGates(data.Unlocked)
		PlayerData.sync(player)
		notifyEvent:FireClient(player, area.Name .. " unlocked!", "success")
	end)
end

rebirthFunction.OnServerInvoke = function(player)
	local data = PlayerData.get(player)
	if not data then
		return false
	end
	-- both the coins and the animal are needed, and there are 8 rebirths
	local row = Config.nextRebirth(data.Rebirths)
	if not row then
		notifyEvent:FireClient(player, "You've reached the max rebirth (" .. Config.MAX_REBIRTHS .. ")!", "danger")
		return false
	end
	local ok, hasCoins, hasPet = Config.canRebirth(data)
	if not ok then
		local cost = Config.rebirthCost(data.Rebirths)
		local missing = {}
		if not hasCoins then
			table.insert(missing, Config.formatNumber(cost - data.Coins) .. " more coins")
		end
		if not hasPet then
			table.insert(missing, "a " .. row.Pet)
		end
		notifyEvent:FireClient(player, "You need " .. table.concat(missing, " and "), "danger")
		return false
	end
	data.Coins = 0
	data.Unlocked = Config.startingArea()
	data.Rebirths += 1
	refreshGates(data.Unlocked)
	PlayerData.sync(player)
	-- back to the start
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if root then
		root.CFrame = World.Spawns[1]
	end
	notifyEvent:FireClient(player, string.format("Rebirth %d!  Luck x%.2f  ·  Coins x%d", data.Rebirths, Config.rebirthLuck(data.Rebirths), Config.coinMultiplier(data.Rebirths)), "success")
	return true
end

local function onLoaded(player)
	local data = PlayerData.get(player)
	if data then
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
