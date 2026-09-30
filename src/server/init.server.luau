-- Server entry point. Remotes are created first so every module can use them.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
remotes.Parent = ReplicatedStorage

require(script.PlayerData)
require(script.Leaderboard)
require(script.Rolling)
