-- Server entry point. Remotes are created first so every module can use them.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)

-- nobody spawns until the map exists (there's no baseplate to land on)
Players.CharacterAutoLoads = false

local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
remotes.Parent = ReplicatedStorage

local notify = Instance.new("RemoteEvent")
notify.Name = "Notify" -- server -> client: (text, style) toast messages
notify.Parent = remotes

-- the place template's flat Baseplate isn't part of the game (the map has
-- its own terrain): remove it so it doesn't stick out around the worlds
local baseplate = workspace:FindFirstChild("Baseplate")
if baseplate and baseplate:IsA("BasePart") then
	baseplate:Destroy()
end

-- keep the camera close: players can't scroll out far over the map
game:GetService("StarterPlayer").CameraMaxZoomDistance = Config.MAX_ZOOM
for _, player in ipairs(Players:GetPlayers()) do
	player.CameraMaxZoomDistance = Config.MAX_ZOOM
end

require(script.PlayerData)
require(script.World) -- builds the map

Players.CharacterAutoLoads = true
for _, player in ipairs(Players:GetPlayers()) do
	if not player.Character then
		task.spawn(player.LoadCharacter, player)
	end
end

require(script.Leaderboards)
require(script.Rolling)
require(script.Breakables)
require(script.Combat)
require(script.Upgrades)
require(script.Progress)
require(script.Aura) -- the Pet Aura Machine (Sahara)
require(script.BoostZones) -- random Luck / Coins circles on the map
require(script.Items) -- boost items, the Boost Machine, teleporting
