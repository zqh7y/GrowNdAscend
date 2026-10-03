-- The gatekeepers' answers (server/Progress.luau decides): a speech bubble
-- over the animal's head for a few seconds, and a little act: two happy
-- hops when it opens the gate for you, a head shake when you can't go yet.
-- (Moving the animal here is only on your screen; the server's copy stays.)
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Effects = require(script.Parent.Effects)

local Gatekeeper = {}

Gatekeeper.Last = nil -- (for the simulator) { Gate, Text, Mood }

local function keeperOf(i)
	local map = workspace:FindFirstChild("Map")
	local gate = map and map:FindFirstChild("Gate" .. i)
	return gate and gate:FindFirstChild("Gatekeeper")
end

-- the animal (without its base and plate): what moves
local function animalOf(i)
	local keeper = keeperOf(i)
	return keeper and keeper:FindFirstChild("Animal")
end

local bubbles = {} -- [gate index] = the bubble now showing
local busy = {} -- [gate index] = true while it hops or shakes
local homes = {} -- [gate index] = where the animal stands (its server pivot)

local placed = {} -- [gate index] = where we last put it
local function homeOf(i, animal)
	-- (if the server moved it since, e.g. lifting the gate onto the ground,
	-- that's its new home)
	local now = animal:GetPivot()
	if not homes[i] or (placed[i] and (now.Position - placed[i].Position).Magnitude > 0.05) then
		homes[i] = now
	end
	return homes[i]
end
local function place(i, animal, cf)
	placed[i] = cf
	animal:PivotTo(cf)
end

local function bubble(keeper, i, text, mood)
	local head = keeper:FindFirstChild("Head", true)
	if not head then
		return nil
	end
	if bubbles[i] then
		bubbles[i]:Destroy()
	end
	local gui = Instance.new("BillboardGui")
	gui.Name = "SpeechBubble"
	gui.Adornee = head
	gui.Size = UDim2.fromOffset(240, 70)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 3, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 80
	local box = Instance.new("Frame")
	box.Size = UDim2.new(1, 0, 1, -12)
	box.BackgroundColor3 = Color3.new(1, 1, 1)
	box.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 16)
	corner.Parent = box
	local stroke = Instance.new("UIStroke")
	stroke.Color = if mood == "yes" then Color3.fromRGB(46, 196, 120) else Color3.fromRGB(240, 82, 96)
	stroke.Thickness = 3
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = box
	-- the little tail pointing down at the animal
	local tail = Instance.new("Frame")
	tail.AnchorPoint = Vector2.new(0.5, 0.5)
	tail.Position = UDim2.new(0.5, 0, 1, -12)
	tail.Size = UDim2.fromOffset(16, 16)
	tail.Rotation = 45
	tail.BackgroundColor3 = Color3.new(1, 1, 1)
	tail.ZIndex = 0
	tail.Parent = gui
	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(40, 40, 70)
	label.Text = text
	label.Parent = box
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft, padding.PaddingRight = UDim.new(0, 10), UDim.new(0, 10)
	padding.PaddingTop, padding.PaddingBottom = UDim.new(0, 6), UDim.new(0, 6)
	padding.Parent = box
	gui.Parent = head
	bubbles[i] = gui
	task.delay(3.5, function()
		if bubbles[i] == gui then
			bubbles[i] = nil
			gui:Destroy()
		end
	end)
	return gui
end

-- a few quick moves of the whole animal (smoothly, step by step), then
-- back where it was
local function act(animal, i, moves)
	if busy[i] then
		return
	end
	busy[i] = true
	local home = homeOf(i, animal)
	task.spawn(function()
		local from = CFrame.new()
		for _, move in ipairs(moves) do
			local steps = math.max(1, math.floor(move[2] * 30))
			for k = 1, steps do
				local t = k / steps
				t = t * t * (3 - 2 * t)
				place(i, animal, home * from:Lerp(move[1], t))
				task.wait(1 / 30)
			end
			from = move[1]
		end
		place(i, animal, home)
		busy[i] = false
	end)
end

function Gatekeeper.say(i, text, mood)
	Gatekeeper.Last = { Gate = i, Text = text, Mood = mood }
	local keeper = keeperOf(i)
	if not keeper then
		return
	end
	Gatekeeper.Last.Bubble = bubble(keeper, i, text, mood)
	local animal = animalOf(i)
	if not animal then
		return
	end
	if mood == "yes" then
		local up = CFrame.new(0, 1.6, 0)
		act(animal, i, { { up, 0.18 }, { CFrame.new(), 0.16 }, { up, 0.18 }, { CFrame.new(), 0.16 } })
		Effects.play("Coin", 1.3, 0.05)
	else
		local left, right = CFrame.Angles(0, math.rad(18), 0), CFrame.Angles(0, math.rad(-18), 0)
		act(animal, i, { { left, 0.1 }, { right, 0.14 }, { left, 0.14 }, { CFrame.new(), 0.1 } })
	end
end

-- Idle: a slow breathing bob and now and then a little look around, so
-- the animals feel alive (each a little out of step with the others)
Gatekeeper.IDLE = true
local clock = 0
game:GetService("RunService").Heartbeat:Connect(function(dt)
	if not Gatekeeper.IDLE then
		return
	end
	clock += dt
	for i = 2, 8 do
		if not keeperOf(i) then
			break
		end
		local animal = animalOf(i)
		if animal and not busy[i] then
			local home = homeOf(i, animal)
			local bob = 0.08 * math.sin(clock * 2.2 + i)
			local look = math.rad(10) * math.sin(clock * 0.45 + i * 1.7) ^ 3
			place(i, animal, home * CFrame.new(0, bob, 0) * CFrame.Angles(0, look, 0))
		end
	end
end)

ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("GatekeeperSay").OnClientEvent:Connect(Gatekeeper.say)

return Gatekeeper
