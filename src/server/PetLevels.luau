-- Pet levels: the Pet Upgrades stand by the spawn in the Forest shows your
-- pets on three podiums with an UPGRADE button under each. Upgrading a pet
-- (every copy of that kind and size) costs coins and raises its level, up to
-- Config.PET_LEVEL_MAX; what a level does lives in Config (petStat,
-- levelPower). This only checks and charges. The stand is client/PetUpgrader.luau.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Security = require(script.Parent.Security)
local PlayerData = require(script.Parent.PlayerData)

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local notifyEvent = remotes:WaitForChild("Notify")

local upgradeFunction = Instance.new("RemoteFunction")
upgradeFunction.Name = "UpgradePet" -- client -> server: (pet name) -> the new level, or false
upgradeFunction.Parent = remotes

local PetLevels = {}

function PetLevels.upgrade(player, name)
	local data = PlayerData.get(player)
	if not data or type(name) ~= "string" or #name > 100 or not Config.petInfo(name) then
		return false
	end
	if (data.Pets[name] or 0) <= 0 then
		notifyEvent:FireClient(player, "You don't have that pet", "danger")
		return false
	end
	local level = Config.petLevel(data, name)
	if level >= Config.PET_LEVEL_MAX then
		notifyEvent:FireClient(player, Config.displayName(name) .. " is already max level!", "danger")
		return false
	end
	local cost = Config.petLevelCost(name, level)
	if data.Coins < cost then
		notifyEvent:FireClient(player, "You need " .. Config.formatNumber(cost - data.Coins) .. " more coins", "danger")
		return false
	end
	data.Coins -= cost
	data.PetLevels = data.PetLevels or {}
	data.PetLevels[name] = level + 1
	PlayerData.sync(player)
	notifyEvent:FireClient(player, Config.displayName(name) .. " is now level " .. (level + 1) .. "!", "success")
	return level + 1
end

upgradeFunction.OnServerInvoke = Security.guard("UpgradePet", PetLevels.upgrade, 8)

return PetLevels
