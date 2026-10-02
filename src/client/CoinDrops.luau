-- Coins that burst out of enemies: a few gold coins fly out in arcs when a
-- pet hits an enemy (a couple, a few times a second at most) and a shower
-- when it breaks (more for the boss). They land on the ground around it,
-- spin and bob; walk near them and they fly to you. Anything still lying
-- there after 10 seconds flies to you on its own, and there are never more
-- than MAX on the ground (the oldest go first), so nothing piles up and
-- lags. (The coins themselves are already paid by the server; these are
-- the show.)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Ground = require(script.Parent.Ground)
local Effects = require(script.Parent.Effects)

local CoinDrops = {}

CoinDrops.MAX = 80 -- coins on the ground at once
CoinDrops.LIFETIME = 10 -- seconds before a coin comes to you on its own
CoinDrops.MAGNET = 9 -- studs: closer than this and it flies to you
local FLIGHT = 0.55 -- seconds of the arc out of the enemy
local GATHER = 0.3 -- seconds of the flight to you

local GOLD = Color3.fromRGB(255, 200, 50)
local player = Players.LocalPlayer

local folder = Instance.new("Folder")
folder.Name = "CoinDrops"
folder.Parent = Workspace

local live = {} -- { Part, From, To, Height, Born, State, StartedAt, GatherFrom, Spin }
CoinDrops.Live = live
CoinDrops.Collected = 0 -- (for the simulator)

local function newCoin()
	local p = Instance.new("Part")
	p.Name = "DropCoin"
	p.Shape = Enum.PartType.Cylinder
	p.Size = Vector3.new(0.3, 1.5, 1.5)
	p.Color = GOLD
	p.Material = Enum.Material.SmoothPlastic
	p.Reflectance = 0.15
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Parent = folder
	return p
end

local function root()
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart")
end

local function collect(coin)
	if coin.State ~= "gather" then
		coin.State = "gather"
		coin.StartedAt = os.clock()
		coin.GatherFrom = coin.Part.Position
	end
end

-- Throws `count` coins out of `position` (returns their records)
function CoinDrops.drop(position, count)
	local made = {}
	for _ = 1, count do
		-- too many on the ground: the oldest comes to you now
		local resting = 0
		for _, coin in ipairs(live) do
			if coin.State ~= "gather" then
				resting += 1
			end
		end
		if resting >= CoinDrops.MAX then
			for _, coin in ipairs(live) do
				if coin.State ~= "gather" then
					collect(coin)
					break
				end
			end
		end
		local angle = math.random() * math.pi * 2
		local reach = 3 + math.random() * 5
		local to = position + Vector3.new(math.cos(angle) * reach, 0, math.sin(angle) * reach)
		local y = Ground.at(to.X, to.Z, position.Y + 20, 80)
		to = Vector3.new(to.X, (y or position.Y) + 0.8, to.Z)
		local coin = {
			Part = newCoin(),
			From = position + Vector3.new(0, 1.5, 0),
			To = to,
			Height = 4 + math.random() * 3,
			Born = os.clock(),
			StartedAt = os.clock(),
			State = "fly",
			Spin = math.random() * math.pi * 2,
		}
		table.insert(live, coin)
		table.insert(made, coin)
	end
	return made
end

-- Every coin flies to you right now (for the simulator and rebirths)
function CoinDrops.collectAll()
	for _, coin in ipairs(live) do
		collect(coin)
	end
end

local lastDing = 0
function CoinDrops.step()
	local now = os.clock()
	local r = root()
	local me = r and r.Position
	for i = #live, 1, -1 do
		local coin = live[i]
		local t = now - coin.StartedAt
		coin.Spin += 0.08
		local turn = CFrame.Angles(0, coin.Spin, math.rad(90))
		if coin.State == "fly" then
			local k = math.min(t / FLIGHT, 1)
			local p = coin.From:Lerp(coin.To, k) + Vector3.new(0, 4 * coin.Height * k * (1 - k), 0)
			coin.Part.CFrame = CFrame.new(p) * turn
			if k >= 1 then
				coin.State = "rest"
				coin.StartedAt = now
			end
		elseif coin.State == "rest" then
			coin.Part.CFrame = CFrame.new(coin.To + Vector3.new(0, 0.25 * math.sin(t * 3), 0)) * turn
			local near = me and Vector3.new(me.X - coin.To.X, 0, me.Z - coin.To.Z).Magnitude <= CoinDrops.MAGNET
			if near or now - coin.Born >= CoinDrops.LIFETIME then
				collect(coin)
			end
		end
		if coin.State == "gather" then
			local k = math.min((now - coin.StartedAt) / GATHER, 1)
			local goal = me or coin.GatherFrom
			coin.Part.CFrame = CFrame.new(coin.GatherFrom:Lerp(goal, k * k)) * turn
			if k >= 1 or not me then
				coin.Part:Destroy()
				coin.State = "collected"
				table.remove(live, i)
				CoinDrops.Collected += 1
				Effects.CoinLanded:Fire()
				if now - lastDing > 0.06 then
					lastDing = now
					Effects.play("Coin", 1.1 + math.random() * 0.3, 0.03)
				end
			end
		end
	end
end

RunService.Heartbeat:Connect(CoinDrops.step)

return CoinDrops
