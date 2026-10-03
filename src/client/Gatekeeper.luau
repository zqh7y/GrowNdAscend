-- The gatekeepers come alive (server/World/Gatekeepers.luau builds them,
-- server/Progress.luau decides their answers). On your screen only:
--   idle    a slow breathing bob, the head looking around and tilting, the
--           eyes blinking now and then, and each animal's own moves: the
--           camel swishes its tail, the penguin flaps its flippers, the red
--           panda sways its big tail and lifts its bamboo for a nibble, the
--           dragon flaps its wings and wags its tail
--   yes     a speech bubble ("Sure! Welcome to ...!"), two happy hops and a nod
--   no      a speech bubble ("Sorry! You need ...") and a head shake
-- The moving parts are the animal's sub-models (Neck, Tail, WingL/R,
-- FlipperL/R, Arms), turned about their joints; the eyelids are the parts
-- named "Lid", shown for a blink.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Effects = require(script.Parent.Effects)

local Gatekeeper = {}

Gatekeeper.Last = nil -- (for the simulator) { Gate, Text, Mood, Bubble }
Gatekeeper.IDLE = true

local function keeperOf(i)
	local map = workspace:FindFirstChild("Map")
	local gate = map and map:FindFirstChild("Gate" .. i)
	return gate and gate:FindFirstChild("Gatekeeper")
end

-- Speech bubble ----------------------------------------------------------------------------

local bubbles = {} -- [gate index] = the bubble now showing

local function bubble(keeper, i, text, mood)
	local head = keeper:FindFirstChild("Head", true)
	if not (head and head:IsA("BasePart")) then
		return nil
	end
	if bubbles[i] then
		bubbles[i]:Destroy()
	end
	local gui = Instance.new("BillboardGui")
	gui.Name = "SpeechBubble"
	gui.Adornee = head
	gui.Size = UDim2.fromOffset(260, 76)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 5, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 90
	local box = Instance.new("Frame")
	box.Size = UDim2.new(1, 0, 1, -12)
	box.BackgroundColor3 = Color3.new(1, 1, 1)
	box.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 18)
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
	padding.PaddingLeft, padding.PaddingRight = UDim.new(0, 12), UDim.new(0, 12)
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

-- Rig: where everything rests --------------------------------------------------------------

local rigs = {} -- [gate index] = { Animal, Home, Placed, Parts = { [name] = { Model, Rest } }, Lids, Act, ActAt }
local MOVING = { "Neck", "Tail", "WingL", "WingR", "FlipperL", "FlipperR", "Arms" }

local function rigOf(i)
	local keeper = keeperOf(i)
	local animal = keeper and keeper:FindFirstChild("Animal")
	if not animal then
		return nil
	end
	local rig = rigs[i]
	if not rig or rig.Animal ~= animal then
		rig = { Animal = animal, Parts = {}, Lids = {} }
		local home = animal:GetPivot()
		for _, name in ipairs(MOVING) do
			local part = animal:FindFirstChild(name, true)
			if part and part:IsA("Model") then
				rig.Parts[name] = { Model = part, Rest = home:Inverse() * part:GetPivot() }
			end
		end
		for _, d in ipairs(animal:GetDescendants()) do
			if d:IsA("BasePart") and d.Name == "Lid" then
				table.insert(rig.Lids, d)
			end
		end
		rig.Home = home
		rigs[i] = rig
	end
	-- (if the server moved it since, e.g. lifting the gate onto the ground,
	-- that's its new home)
	local now = animal:GetPivot()
	if rig.Placed and (now.Position - rig.Placed.Position).Magnitude > 0.05 then
		rig.Home = now
	end
	return rig
end

-- The moves --------------------------------------------------------------------------------

local function smooth(t)
	t = math.clamp(t, 0, 1)
	return t * t * (3 - 2 * t)
end

-- how far into an act we are (0..1 per hop / shake), nil when there's none
local ACT_TIME = { yes = 1.1, no = 0.8 }

local clock = 0
local function pose(i, rig)
	local t = clock + i * 1.7
	local body = CFrame.new(0, 0.12 * math.sin(t * 2.2), 0)
	local neck = CFrame.Angles(math.rad(4) * math.sin(t * 1.3), math.rad(14) * math.sin(t * 0.45) ^ 3, math.rad(5) * math.sin(t * 0.7))
	local act = rig.Act and (clock - rig.ActAt) / ACT_TIME[rig.Act]
	if act and act >= 1 then
		rig.Act, act = nil, nil
	end
	if act and rig.Act == "yes" then
		-- two hops and a nod
		local hop = math.abs(math.sin(act * math.pi * 2)) * 2.2
		body = CFrame.new(0, hop, 0)
		neck = CFrame.Angles(math.rad(-18) * math.sin(act * math.pi * 4), 0, 0)
	elseif act and rig.Act == "no" then
		-- a head shake, slowing down
		neck = CFrame.Angles(0, math.rad(28) * math.sin(act * math.pi * 6) * (1 - act), 0)
	end
	local moves = {
		Neck = neck,
		Tail = CFrame.Angles(0, math.rad(22) * math.sin(t * 3), 0),
		WingL = CFrame.Angles(0, 0, math.rad(-22) * (0.5 + 0.5 * math.sin(t * 3.2))),
		WingR = CFrame.Angles(0, 0, math.rad(22) * (0.5 + 0.5 * math.sin(t * 3.2))),
		FlipperL = CFrame.Angles(0, 0, math.rad(-18) * (0.5 + 0.5 * math.sin(t * 2.6))),
		FlipperR = CFrame.Angles(0, 0, math.rad(18) * (0.5 + 0.5 * math.sin(t * 2.6 + 0.6))),
		-- (a nibble every few seconds: the arms lift the bamboo to the mouth)
		Arms = CFrame.Angles(math.rad(22) * smooth(math.max(0, math.sin(t * 0.9)) ^ 6 * 1.5), 0, 0),
	}
	if act and rig.Act == "yes" then
		moves.Tail = CFrame.Angles(0, math.rad(35) * math.sin(clock * 14), 0)
		moves.WingL = CFrame.Angles(0, 0, math.rad(-40) * math.abs(math.sin(clock * 10)))
		moves.WingR = CFrame.Angles(0, 0, math.rad(40) * math.abs(math.sin(clock * 10)))
		moves.FlipperL = CFrame.Angles(0, 0, math.rad(-45) * math.abs(math.sin(clock * 10)))
		moves.FlipperR = CFrame.Angles(0, 0, math.rad(45) * math.abs(math.sin(clock * 10)))
	end
	return body, moves
end

local function update(i, rig)
	local body, moves = pose(i, rig)
	local cf = rig.Home * body
	rig.Placed = cf
	rig.Animal:PivotTo(cf)
	for name, part in pairs(rig.Parts) do
		part.Model:PivotTo(cf * part.Rest * (moves[name] or CFrame.new()))
	end
	-- a blink every few seconds (each animal at its own time)
	local blink = ((clock + i * 0.9) % 3.6) < 0.13
	for _, lid in ipairs(rig.Lids) do
		lid.Transparency = if blink then 0 else 1
	end
end

function Gatekeeper.say(i, text, mood)
	Gatekeeper.Last = { Gate = i, Text = text, Mood = mood }
	local keeper = keeperOf(i)
	if not keeper then
		return
	end
	Gatekeeper.Last.Bubble = bubble(keeper, i, text, mood)
	local rig = rigOf(i)
	if rig then
		rig.Act, rig.ActAt = mood, clock
	end
	if mood == "yes" then
		Effects.play("Coin", 1.3, 0.05)
	end
end

game:GetService("RunService").Heartbeat:Connect(function(dt)
	clock += dt
	if not Gatekeeper.IDLE then
		return
	end
	for i = 2, 8 do
		if not keeperOf(i) then
			break
		end
		local rig = rigOf(i)
		if rig then
			update(i, rig)
		end
	end
end)

-- (for the simulator: one frame of every gatekeeper's animation)
function Gatekeeper.step(dt)
	clock += dt or 1 / 30
	for i = 2, 8 do
		local rig = keeperOf(i) and rigOf(i)
		if rig then
			update(i, rig)
		end
	end
	return rigs
end

ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("GatekeeperSay").OnClientEvent:Connect(Gatekeeper.say)

return Gatekeeper
