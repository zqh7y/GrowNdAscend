-- The upgrade tree: players spend coins on the next level of a branch. What
-- each branch does lives in Config.UPGRADES; this only checks and charges.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local PlayerData = require(script.Parent.PlayerData)

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local notifyEvent = remotes:WaitForChild("Notify")

local buyFunction = Instance.new("RemoteFunction")
buyFunction.Name = "BuyUpgrade"
buyFunction.Parent = remotes

buyFunction.OnServerInvoke = function(player, id)
	local data = PlayerData.get(player)
	if not data or type(id) ~= "string" then
		return false
	end
	local ok, reason = Config.canUpgrade(data, id)
	if not ok then
		notifyEvent:FireClient(player, reason, "danger")
		return false
	end
	local upgrade = Config.UPGRADES_BY_ID[id]
	local level = Config.upgradeLevel(data, id)
	local cost = upgrade.Cost(level)
	if data.Coins < cost then
		notifyEvent:FireClient(player, "You need " .. Config.formatNumber(cost - data.Coins) .. " more coins", "danger")
		return false
	end
	data.Coins -= cost
	data.Upgrades[id] = level + 1
	PlayerData.sync(player)
	notifyEvent:FireClient(player, upgrade.Name .. " level " .. (level + 1) .. "!", "success")
	return true
end

-- The Luck Board: the next level of a row
local boardFunction = Instance.new("RemoteFunction")
boardFunction.Name = "BuyLuck"
boardFunction.Parent = remotes

boardFunction.OnServerInvoke = function(player, id)
	local data = PlayerData.get(player)
	if not data or type(id) ~= "string" then
		return false
	end
	local ok, reason = Config.canBoard(data, id)
	if not ok then
		notifyEvent:FireClient(player, reason, "danger")
		return false
	end
	local item = Config.LUCK_BOARD_BY_ID[id]
	local level = Config.boardLevel(data, id)
	local cost = Config.boardCost(item, level)
	if data.Coins < cost then
		notifyEvent:FireClient(player, "You need " .. Config.formatNumber(cost - data.Coins) .. " more coins", "danger")
		return false
	end
	data.Coins -= cost
	data.LuckBoard = data.LuckBoard or {}
	data.LuckBoard[id] = level + 1
	PlayerData.sync(player)
	return true
end

return {}
