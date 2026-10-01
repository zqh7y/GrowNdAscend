-- The Pet Aura Machine in the Sahara (it stands where the fusion machine
-- was). Put in Config.AURA_COPIES (3) of the same pet, any size, without an
-- aura, and get 1 of it back holding a random aura weapon (Config.AURAS:
-- chances by weight, each boosts that pet's Damage, Coins and/or Luck).
-- Instant: the client plays the reveal.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local PlayerData = require(script.Parent.PlayerData)
local World = require(script.Parent.World)

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local notifyEvent = remotes:WaitForChild("Notify")

local openEvent = Instance.new("RemoteEvent")
openEvent.Name = "AuraOpen" -- server -> client: open the aura screen
openEvent.Parent = remotes
local fuseFunction = Instance.new("RemoteFunction")
fuseFunction.Name = "AuraFuse" -- client -> server: (pet name) -> { Pet, Aura } or nil
fuseFunction.Parent = remotes

local Aura = {}
local random = Random.new()

-- (for the simulator) swap the random source
function Aura.setRandom(source)
	random = source or Random.new()
end

local machine = World.Fusion
if machine then
	machine.Prompt.ObjectText = "Pet Aura Machine"
	machine.Prompt.ActionText = "Open"
	machine.Prompt.Triggered:Connect(function(player)
		if PlayerData.get(player) then
			openEvent:FireClient(player)
		end
	end)
end

-- Turns 3 copies of a pet into 1 with a random aura
function Aura.fuse(player, name)
	local data = PlayerData.get(player)
	if not data or type(name) ~= "string" or not Config.petInfo(name) or Config.petAura(name) then
		return nil
	end
	if (data.Pets[name] or 0) < Config.AURA_COPIES then
		notifyEvent:FireClient(player, "You need " .. Config.AURA_COPIES .. " " .. name .. " pets", "danger")
		return nil
	end
	data.Pets[name] -= Config.AURA_COPIES
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
	local aura = Config.pickAura(random:NextNumber())
	local result = Config.auraName(name, aura.Id)
	data.Pets[result] = (data.Pets[result] or 0) + 1
	data.Obtained = data.Obtained or {}
	data.Obtained[result] = data.Rolls
	PlayerData.updateStrongest(player)
	PlayerData.sync(player)
	return { Pet = result, Aura = aura.Id }
end

fuseFunction.OnServerInvoke = Aura.fuse

-- The machine's look for the player in this (solo) server: slow rings and
-- a soft orb in the colour of the rarest aura while idle
task.spawn(function()
	if not machine then
		return
	end
	local color = Config.AURAS[#Config.AURAS].Color
	machine.Orb.Color = color
	machine.Light.Color = color
	machine.Orb.Size = Vector3.one * 1.6
	machine.Status.Text = Config.AURA_COPIES .. " same pets → 1 with an AURA"
	machine.Screen.Text = "AURAS"
	machine.Screen.TextColor3 = color
	for k, ring in ipairs(machine.Rings) do
		ring:SetAttribute("SpinSpeed", if k == 1 then 40 else -30)
	end
	machine.Sparkles.Rate = 10
	machine.Sparkles.Color = ColorSequence.new(Color3.new(1, 1, 1), color)
	machine.Beam.Transparency = 1
end)

return Aura
