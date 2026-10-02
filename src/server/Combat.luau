-- Automatic pet fighting. Every tick each player's pets pick the living coin
-- nearest to the player (all pets focus the same one), "run" to it, then
-- each pet hits on its own timer for its power x the Damage upgrade. The
-- player never clicks: they build the team, the team does the fighting.
--
-- The client is told which coin the pets are on (the player's "PetTarget"
-- attribute, the coin's Id) and about every hit (PetHits), and animates the
-- pets running, lunging and the damage numbers.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local PlayerData = require(script.Parent.PlayerData)
local Breakables = require(script.Parent.Breakables)

local TICK = 0.1

local hitsEvent = Instance.new("RemoteEvent")
hitsEvent.Name = "PetHits" -- server -> client: (targetId, { { Pet = slot, Damage = n } })
hitsEvent.Parent = ReplicatedStorage:WaitForChild("Remotes")

local random = Random.new()
local fights = {} -- [player] = { Target, Team = equipped list copy, Pets = { [slot] = { NextHit } } }

local function sameTeam(a, b)
	if #a ~= #b then
		return false
	end
	for i = 1, #a do
		if a[i] ~= b[i] then
			return false
		end
	end
	return true
end

-- Current area -> valid targets in that area -> the nearest one. Pets never
-- look at other worlds' targets, however close they are.
local function pickTarget(root, data, current)
	local area = math.min(Config.areaAt(root.Position.X), data.Unlocked)
	-- (in a boss world the pets go for the boss from anywhere in the area,
	-- so you can stay AFK wherever you like there)
	local radius = if Config.AREAS[area].Boss then Config.AREA_LENGTH * 2 else Config.FIGHT_RADIUS
	-- stay on the current one while it's alive, in this area and not too far
	if current and Breakables.alive(current) and current.Area == area and (current.Pos - root.Position).Magnitude <= radius * 1.3 then
		return current
	end
	local best, bestDistance = nil, math.huge
	for _, target in ipairs(Breakables.near(root.Position, radius, area)) do
		local distance = (target.Pos - root.Position).Magnitude
		if distance < bestDistance then
			best, bestDistance = target, distance
		end
	end
	return best
end

local function update(player, now)
	local data = PlayerData.get(player)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local fight = fights[player]
	if not data or not root or #data.Equipped == 0 then
		if fight and fight.Target then
			fight.Target = nil
			player:SetAttribute("PetTarget", 0)
		end
		return
	end
	if not fight or not sameTeam(fight.Team, data.Equipped) then
		fight = { Team = table.clone(data.Equipped), Pets = {} }
		fights[player] = fight
	end

	local target = pickTarget(root, data, fight.Target)
	if target ~= fight.Target then
		fight.Target = target
		player:SetAttribute("PetTarget", if target then target.Id else 0)
		if target then
			-- the pets need a moment to run over; each arrives a little apart
			local travel = (target.Pos - root.Position).Magnitude / Config.PET_SPEED
			for slot = 1, #fight.Team do
				fight.Pets[slot] = { NextHit = now + travel + slot * 0.07 }
			end
		end
	end
	if not target then
		return
	end

	local hits = {}
	local total = 0
	for slot, name in ipairs(fight.Team) do
		local pet = fight.Pets[slot]
		if pet and now >= pet.NextHit then
			local damage = Config.hitDamage(data, name)
			table.insert(hits, { Pet = slot, Damage = damage })
			total += damage
			pet.NextHit = now + Config.PET_HIT_EVERY * random:NextNumber(0.9, 1.1)
		end
	end
	if #hits > 0 then
		hitsEvent:FireClient(player, target.Id, hits)
		if Breakables.damage(target, total, player) then
			fight.Target = nil
			player:SetAttribute("PetTarget", 0)
		end
	end
end

task.spawn(function()
	while true do
		task.wait(TICK)
		local now = os.clock()
		for _, player in ipairs(Players:GetPlayers()) do
			update(player, now)
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	fights[player] = nil
end)

return {}
