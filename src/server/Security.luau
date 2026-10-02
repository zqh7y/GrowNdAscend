-- Server-side protection. The client can be changed by an exploiter, so the
-- server never trusts it: every remote already checks its arguments (types,
-- ownership, coins, distances, cooldowns) and the server decides every roll,
-- hit and reward. This module adds two more guards:
--   Security.guard(name, handler, perSecond)  wraps a RemoteFunction handler
--       with a per-player rate limit: calls past `perSecond` (counted over
--       one second) are dropped, so a script spamming Equip or BuyUpgrade
--       can't flood the server. Bad calls never error out to the caller.
--   The zone guard: a character found inside a world that player hasn't
--   unlocked (flying or teleporting past a gate), below the map or above the
--   sky lid is put back at the start of their last unlocked world.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local Security = {}

Security.RateLimits = true -- (the simulator turns these off while it calls remotes back to back,
Security.ZoneGuard = true -- and moves the player around; item 129 tests both)
Security.Dropped = 0 -- calls dropped by the rate limit (for the simulator)
Security.Returned = 0 -- characters put back by the zone guard

local calls = {} -- [player] = { [name] = { Start, Count } }

function Security.allow(player, name, perSecond)
	if not Security.RateLimits then
		return true
	end
	local mine = calls[player]
	if not mine then
		mine = {}
		calls[player] = mine
	end
	local entry = mine[name]
	local now = os.clock()
	if not entry or now - entry.Start >= 1 then
		mine[name] = { Start = now, Count = 1 }
		return true
	end
	entry.Count += 1
	if entry.Count > perSecond then
		Security.Dropped += 1
		return false
	end
	return true
end

function Security.guard(name, handler, perSecond)
	return function(player, ...)
		if not Security.allow(player, name, perSecond or 10) then
			return nil
		end
		local ok, a, b, c = pcall(handler, player, ...)
		if not ok then
			warn("[Security] " .. name .. " from " .. player.Name .. ": " .. tostring(a))
			return nil
		end
		return a, b, c
	end
end

-- The zone guard ------------------------------------------------------------------------------

-- set by init (they need World and PlayerData, which load after this)
Security.PlayerData = nil
Security.World = nil
local LID = 128 -- (the invisible lid over the map is at ~130)

-- true if this position is somewhere the player may not be
function Security.outOfBounds(data, position)
	local unlocked = math.clamp(data.Unlocked or 1, 1, #Config.AREAS)
	if unlocked < #Config.AREAS and position.X > Config.areaStart(unlocked + 1) + 2 then
		return true
	end
	return position.Y < -40 or position.Y > LID
end

function Security.check(player)
	local PlayerData, World = Security.PlayerData, Security.World
	local data = PlayerData and PlayerData.get(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not data or not root or not World then
		return false
	end
	if Security.outOfBounds(data, root.Position) then
		local spawn = World.Spawns[math.clamp(data.Unlocked or 1, 1, #Config.AREAS)]
		if spawn then
			character:PivotTo(spawn)
			root.AssemblyLinearVelocity = Vector3.zero
			Security.Returned += 1
			return true
		end
	end
	return false
end

task.spawn(function()
	while true do
		task.wait(0.5)
		if Security.ZoneGuard then
			for _, player in ipairs(Players:GetPlayers()) do
				pcall(Security.check, player)
			end
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	calls[player] = nil
end)

return Security
