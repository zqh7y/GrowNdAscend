-- Server entry point. Remotes are created first so every module can use them.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- nobody spawns until the map exists (there's no baseplate to land on)
Players.CharacterAutoLoads = false

local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
remotes.Parent = ReplicatedStorage

local notify = Instance.new("RemoteEvent")
notify.Name = "Notify" -- server -> client: (text, style) toast messages
notify.Parent = remotes

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
