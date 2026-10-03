-- Client entry point: loads every screen and effect, and turns the server's
-- fight messages into visuals (pets lunging, coins flashing, damage numbers,
-- coins bursting out of enemies).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local State = require(script.State)
local Screen = require(script.Screen)
local Effects = require(script.Effects)
local Living = require(script.Living)
local Pets = require(script.Pets)
local CoinDrops = require(script.CoinDrops)
require(script.Motion)
require(script.Ambient) -- birds, critters, butterflies, weather, swaying plants, visitors
require(script.Hud) -- also loads Roll, Inventory, Index, the Upgrade Board and Panels
require(script.AuraMachine) -- the Pet Aura Machine screen (opened at the machine in the Sahara)
require(script.FuseMachine) -- the Fuse Machine screen (opened at the machine in the Sakura Jungle)
require(script.MegaRoll) -- the Mega Roll pad's sign, and claiming it
require(script.Boosts) -- the Inventory's Boosts section, the Boost Machine, boost timers
require(script.Perks) -- the rebirth perk pads' status
require(script.BossBar) -- the boss's health bar in the Lava Arena
require(script.Gatekeeper) -- the gatekeeper animals' speech bubbles and hops
require(script.BossShop) -- the Boss Shop screen (opened at the shop in the Lava Arena)
require(script.Session) -- no reset button, no AFK kick

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

-- coins paid while fighting: a small gold number by the enemy, and a
-- couple of coins popping out of it (CoinDrops: they land around it and
-- come to you when you walk near, or after 10 seconds)
local lastHitDrop = 0
State.remote("FightCoins").OnClientEvent:Connect(function(position, coins)
	Effects.fightCoins(position, coins)
	if os.clock() - lastHitDrop >= 0.3 then
		lastHitDrop = os.clock()
		CoinDrops.drop(position, math.random(1, 2))
	end
end)

-- a break: coins pop out and fly into the counter
State.remote("CoinPop").OnClientEvent:Connect(function(position, coins, area)
	Effects.burst(position, Config.AREAS[area].Color)
	if Config.AREAS[area].Boss then
		-- the boss goes down: a bigger burst
		Effects.burst(position + Vector3.new(0, 5, 0), Color3.fromRGB(255, 200, 80))
		Effects.burst(position + Vector3.new(0, 9, 0), Color3.fromRGB(255, 255, 255))
	end
	Effects.coins(position, coins)
	-- and a shower of coins out of it
	CoinDrops.drop(position, if Config.AREAS[area].Boss then 24 else 8)
end)

State.remote("Notify").OnClientEvent:Connect(Screen.toast)

-- the pets stop chasing when the character respawns
player.CharacterAdded:Connect(function()
	player:SetAttribute("PetTarget", 0)
end)
