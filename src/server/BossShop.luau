-- The Boss Shop in the Lava Arena: upgrades that only work on bosses (Boss
-- Damage, Boss Coins, Boss EXP, Boss Crits), bought with coins. What each
-- does lives in Config.BOSS_UPGRADES (used in Combat and Breakables); this
-- only checks and charges. The client screen is client/BossShop.luau.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Security = require(script.Parent.Security)
local PlayerData = require(script.Parent.PlayerData)

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local notifyEvent = remotes:WaitForChild("Notify")

local buyFunction = Instance.new("RemoteFunction")
buyFunction.Name = "BuyBossUpgrade" -- client -> server: (upgrade id) -> true if bought
buyFunction.Parent = remotes

local BossShop = {}

function BossShop.buy(player, id)
	local data = PlayerData.get(player)
	if not data or type(id) ~= "string" then
		return false
	end
	local ok, reason = Config.canBossUpgrade(data, id)
	if not ok then
		notifyEvent:FireClient(player, reason, "danger")
		return false
	end
	local def = Config.BOSS_UPGRADES_BY_ID[id]
	local level = Config.bossUpgradeLevel(data, id)
	local cost = def.Cost(level)
	if data.Coins < cost then
		notifyEvent:FireClient(player, "You need " .. Config.formatNumber(cost - data.Coins) .. " more coins", "danger")
		return false
	end
	data.Coins -= cost
	data.BossUpgrades = data.BossUpgrades or {}
	data.BossUpgrades[id] = level + 1
	PlayerData.sync(player)
	notifyEvent:FireClient(player, def.Name .. " level " .. (level + 1) .. "!", "success")
	return true
end

buyFunction.OnServerInvoke = Security.guard("BuyBossUpgrade", BossShop.buy, 8)

return BossShop
