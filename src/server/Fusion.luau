-- The pet fusion machine in the Sahara. Put 5 copies of a pet in, wait for
-- the timer (it keeps going while you're offline), then collect the huge
-- version. One fusion at a time.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local PlayerData = require(script.Parent.PlayerData)
local World = require(script.Parent.World)

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local notifyEvent = remotes:WaitForChild("Notify")

local openEvent = Instance.new("RemoteEvent")
openEvent.Name = "FusionOpen" -- server -> client: open the fusion screen
openEvent.Parent = remotes
local startFunction = Instance.new("RemoteFunction")
startFunction.Name = "FuseStart"
startFunction.Parent = remotes
local collectFunction = Instance.new("RemoteFunction")
collectFunction.Name = "FuseCollect"
collectFunction.Parent = remotes

local machine = World.Fusion
local IDLE_COLOR = Color3.fromRGB(255, 90, 170)

machine.Prompt.Triggered:Connect(function(player)
	if PlayerData.get(player) then
		openEvent:FireClient(player)
	end
end)

startFunction.OnServerInvoke = function(player, name)
	local data = PlayerData.get(player)
	local pet = type(name) == "string" and Config.PETS_BY_NAME[name]
	if not data or not pet or data.Fusion then
		return false
	end
	if (data.Pets[name] or 0) < Config.FUSE_COPIES then
		notifyEvent:FireClient(player, "You need " .. Config.FUSE_COPIES .. " " .. name .. "s", "danger")
		return false
	end
	data.Pets[name] -= Config.FUSE_COPIES
	if data.Pets[name] <= 0 then
		-- none left: take it off if it was equipped
		local index = table.find(data.Equipped, name)
		if index then
			table.remove(data.Equipped, index)
		end
	end
	data.Fusion = { Pet = name, Ends = os.time() + Config.fuseTime(pet) }
	PlayerData.sync(player)
	return true
end

collectFunction.OnServerInvoke = function(player)
	local data = PlayerData.get(player)
	if not data or not data.Fusion or os.time() < data.Fusion.Ends then
		return nil
	end
	local name = data.Fusion.Pet
	data.Huges[name] = (data.Huges[name] or 0) + 1
	data.Fusion = nil
	PlayerData.updateStrongest(player)
	PlayerData.sync(player)
	return Config.HUGE_PREFIX .. name
end

-- the machine shows the fusion of the player in this (solo) server
task.spawn(function()
	while true do
		local player = Players:GetPlayers()[1]
		local data = player and PlayerData.get(player)
		local fusion = data and data.Fusion
		if fusion then
			local pet = Config.PETS_BY_NAME[fusion.Pet]
			local total = Config.fuseTime(pet)
			local left = math.max(fusion.Ends - os.time(), 0)
			local progress = 1 - left / total
			machine.Orb.Color = pet.Color
			machine.Light.Color = pet.Color
			machine.Orb.Size = Vector3.one * (3 + progress * 8)
			if left > 0 then
				machine.Status.Text = "Fusing " .. fusion.Pet .. "  ·  " .. string.format("%d:%02d", left // 60, left % 60)
			else
				machine.Status.Text = "HUGE " .. fusion.Pet:upper() .. " READY!"
			end
		else
			machine.Orb.Color = IDLE_COLOR
			machine.Light.Color = IDLE_COLOR
			machine.Orb.Size = Vector3.one * 3
			machine.Status.Text = Config.FUSE_COPIES .. " pets → 1 HUGE pet"
		end
		task.wait(0.5)
	end
end)

return {}
