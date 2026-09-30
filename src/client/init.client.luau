-- Client entry point: loads every screen and effect, and turns the server's
-- fight messages into visuals (pets lunging, coins flashing, damage numbers,
-- coins flying into the counter).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local State = require(script.State)
local Screen = require(script.Screen)
local Effects = require(script.Effects)
local Living = require(script.Living)
local Pets = require(script.Pets)
require(script.Motion)
require(script.Ambient) -- birds, critters, butterflies, weather, swaying plants, visitors
require(script.Hud) -- also loads Roll, Inventory, Index, UpgradeTree and Panels

local player = Players.LocalPlayer

-- the equipped pets follow the data
State.watch(function()
	Pets.update(State.Data.Equipped)
end)

-- a hit: the pet lunges, the coin flashes and shakes, a damage number pops
State.remote("PetHits").OnClientEvent:Connect(function(targetId, hits)
	local position = Living.position(targetId)
	for _, hit in ipairs(hits) do
		Pets.lunge(hit.Pet)
		if position then
			Effects.damage(position + Vector3.new(0, 3, 0), hit.Damage, Pets.size(hit.Pet))
		end
	end
	Living.hit(targetId, math.min(#hits, 3) / 2)
	Effects.play("Hit", 0.9 + math.random() * 0.3, 0.08)
end)

-- a break: coins pop out and fly into the counter
State.remote("CoinPop").OnClientEvent:Connect(function(position, coins, area)
	Effects.burst(position, Config.AREAS[area].Color)
	Effects.coins(position, coins)
end)

State.remote("Notify").OnClientEvent:Connect(Screen.toast)

-- the pets stop chasing when the character respawns
player.CharacterAdded:Connect(function()
	player:SetAttribute("PetTarget", 0)
end)
