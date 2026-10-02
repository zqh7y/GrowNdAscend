-- The Fuse Machine in the Sakura Jungle: Config.FUSE.HugeFrom (100) of a
-- Normal pet become 1 Huge of that pet, and Config.FUSE.TitanicFrom (20)
-- Huge become 1 Titanic of it (Config.fuseResult). Aura pets can't go in.
-- Equipped copies that went in come off your team. The client opens the
-- screen at the machine's circle and plays the reveal (FuseMachine.luau).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local PlayerData = require(script.Parent.PlayerData)

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local notifyEvent = remotes:WaitForChild("Notify")

local fuseFunction = Instance.new("RemoteFunction")
fuseFunction.Name = "Fuse" -- client -> server: (pet name) -> the new pet's name, or nil
fuseFunction.Parent = remotes

local Fuse = {}

-- Fuses `name`: returns the pet you got, or nil (and a message for the player)
function Fuse.fuse(player, name)
	local data = PlayerData.get(player)
	if not data or type(name) ~= "string" then
		return nil
	end
	local result, copies = Config.fuseResult(name)
	if not result then
		return nil
	end
	if (data.Pets[name] or 0) < copies then
		notifyEvent:FireClient(player, string.format("You need %d %s to fuse", copies, name), "danger")
		return nil
	end
	data.Pets[name] -= copies
	if data.Pets[name] <= 0 then
		data.Pets[name] = nil
	end
	-- take off equipped copies that went into the machine
	local left, equipped = data.Pets[name] or 0, 0
	for i = #data.Equipped, 1, -1 do
		if data.Equipped[i] == name then
			equipped += 1
			if equipped > left then
				table.remove(data.Equipped, i)
			end
		end
	end
	data.Pets[result] = (data.Pets[result] or 0) + 1
	PlayerData.discover(data, result)
	data.Obtained = data.Obtained or {}
	data.Obtained[result] = data.Rolls
	PlayerData.updateStrongest(player)
	PlayerData.sync(player)
	return result
end

fuseFunction.OnServerInvoke = Fuse.fuse

return Fuse
