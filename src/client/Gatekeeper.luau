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

-- The feeding cutscene ------------------------------------------------------------------------
-- The camera swings over to frame the animal and its wall; the food flies
-- from you into its mouth; it munches with hearts popping out and hops;
-- the wall glows, shakes and sinks into the ground in a burst of sparkles;
-- the camera comes back (about 3.5 s, Config.GATE_OPEN_DELAY: the server
-- opens the gate as it ends). Everything here is only on your screen.

local FOOD_LOOKS = {
	Watermelon = function(model)
		local rind = Instance.new("Part")
		rind.Shape = Enum.PartType.Cylinder
		rind.Size = Vector3.new(0.5, 2.2, 2.2)
		rind.Color = Color3.fromRGB(80, 180, 70)
		rind.Parent = model
		local flesh = rind:Clone()
		flesh.Size = Vector3.new(0.55, 1.8, 1.8)
		flesh.Color = Color3.fromRGB(255, 90, 100)
		flesh.Parent = model
		for k = -1, 1 do
			local seed = Instance.new("Part")
			seed.Shape = Enum.PartType.Ball
			seed.Size = Vector3.new(0.15, 0.15, 0.15)
			seed.Color = Color3.fromRGB(40, 30, 30)
			seed.CFrame = CFrame.new(0.3, k * 0.4, 0.2)
			seed.Parent = model
		end
		return rind
	end,
	Fish = function(model)
		local body = Instance.new("Part")
		body.Shape = Enum.PartType.Ball
		body.Size = Vector3.new(1.8, 1, 1)
		body.Color = Color3.fromRGB(120, 190, 255)
		body.Parent = model
		local belly = body:Clone()
		belly.Size = Vector3.new(1.4, 0.7, 0.8)
		belly.CFrame = CFrame.new(0, -0.15, 0)
		belly.Color = Color3.fromRGB(230, 245, 255)
		belly.Parent = model
		local tail = Instance.new("Part")
		tail.Shape = Enum.PartType.Ball
		tail.Size = Vector3.new(0.4, 1, 0.15)
		tail.CFrame = CFrame.new(1, 0, 0)
		tail.Color = Color3.fromRGB(90, 160, 240)
		tail.Parent = model
		local eye = Instance.new("Part")
		eye.Shape = Enum.PartType.Ball
		eye.Size = Vector3.new(0.2, 0.2, 0.2)
		eye.CFrame = CFrame.new(-0.6, 0.15, -0.35)
		eye.Color = Color3.fromRGB(30, 30, 50)
		eye.Parent = model
		return body
	end,
	Apple = function(model)
		local apple = Instance.new("Part")
		apple.Shape = Enum.PartType.Ball
		apple.Size = Vector3.new(1.4, 1.4, 1.4)
		apple.Color = Color3.fromRGB(235, 50, 60)
		apple.Parent = model
		local stem = Instance.new("Part")
		stem.Size = Vector3.new(0.1, 0.4, 0.1)
		stem.CFrame = CFrame.new(0, 0.8, 0)
		stem.Color = Color3.fromRGB(110, 70, 40)
		stem.Parent = model
		local leaf = Instance.new("Part")
		leaf.Size = Vector3.new(0.5, 0.05, 0.25)
		leaf.CFrame = CFrame.new(0.25, 0.85, 0) * CFrame.Angles(0, 0, math.rad(-20))
		leaf.Color = Color3.fromRGB(90, 200, 80)
		leaf.Parent = model
		return apple
	end,
	["Chili Pepper"] = function(model)
		local chili = Instance.new("Part")
		chili.Shape = Enum.PartType.Cylinder
		chili.Size = Vector3.new(1.8, 0.6, 0.6)
		chili.Color = Color3.fromRGB(230, 40, 40)
		chili.Parent = model
		local tip = Instance.new("Part")
		tip.Shape = Enum.PartType.Ball
		tip.Size = Vector3.new(0.6, 0.6, 0.6)
		tip.CFrame = CFrame.new(0.9, 0, 0)
		tip.Color = Color3.fromRGB(230, 40, 40)
		tip.Parent = model
		local cap = Instance.new("Part")
		cap.Shape = Enum.PartType.Cylinder
		cap.Size = Vector3.new(0.3, 0.7, 0.7)
		cap.CFrame = CFrame.new(-0.95, 0, 0)
		cap.Color = Color3.fromRGB(80, 170, 60)
		cap.Parent = model
		return chili
	end,
}

local function foodModel(name)
	local model = Instance.new("Model")
	model.Name = "Food"
	local main = (FOOD_LOOKS[name] or FOOD_LOOKS.Apple)(model)
	for _, p in ipairs(model:GetChildren()) do
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.Material = Enum.Material.SmoothPlastic
	end
	model.PrimaryPart = main
	model.Parent = workspace
	return model
end

-- small glowing bits that fly out and fade (hearts for the animal, sparkles
-- for the wall)
local function burst(at, color, count, speed)
	for _ = 1, count do
		local p = Instance.new("Part")
		p.Shape = Enum.PartType.Ball
		p.Size = Vector3.new(0.5, 0.5, 0.5)
		p.Color = color
		p.Material = Enum.Material.Neon
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CFrame = CFrame.new(at)
		p.Parent = workspace
		local dir = Vector3.new(math.random() - 0.5, math.random() * 0.8 + 0.4, math.random() - 0.5).Unit
		task.spawn(function()
			for k = 1, 24 do
				local t = k / 24
				p.CFrame = CFrame.new(at + dir * speed * t + Vector3.new(0, t * 2, 0))
				p.Transparency = t
				task.wait(1 / 30)
			end
			p:Destroy()
		end)
	end
end

Gatekeeper.CutsceneRunning = false
function Gatekeeper.cutscene(i, food)
	local keeper = keeperOf(i)
	local gate = keeper and keeper.Parent
	local barrier = gate and gate:FindFirstChild("Barrier")
	local head = keeper and keeper:FindFirstChild("Head", true)
	if not (barrier and head) or Gatekeeper.CutsceneRunning then
		return
	end
	Gatekeeper.CutsceneRunning = true
	local player = game:GetService("Players").LocalPlayer
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local camera = workspace.CurrentCamera
	local savedType = camera.CameraType
	-- the shot: from the player's side, framing the animal and the wall
	local k, b = head.Position, barrier.Position
	local focus = k:Lerp(b, 0.45)
	local shot = CFrame.lookAt(Vector3.new(b.X - 30, focus.Y + 9, (k.Z + b.Z) / 2 + 4), focus)
	camera.CameraType = Enum.CameraType.Scriptable
	local from = camera.CFrame
	for s = 1, 15 do
		camera.CFrame = from:Lerp(shot, smooth(s / 15))
		task.wait(1 / 30)
	end
	-- the food flies from you into the animal's mouth
	local start = (root and root.Position or k + Vector3.new(-8, 0, 0)) + Vector3.new(0, 2.5, 0)
	local snack = foodModel(food)
	for s = 1, 18 do
		local t = s / 18
		snack:PivotTo(CFrame.new(start:Lerp(k, t) + Vector3.new(0, math.sin(t * math.pi) * 5, 0)) * CFrame.Angles(0, t * 8, t * 4))
		task.wait(1 / 30)
	end
	snack:Destroy()
	-- munch munch, hearts, then the happy hops
	local rig = rigOf(i)
	if rig then
		rig.Act, rig.ActAt = "yes", clock
	end
	burst(k + Vector3.new(0, 1.5, 0), Color3.fromRGB(255, 120, 170), 8, 5)
	Effects.play("Coin", 1.3, 0.05)
	task.wait(1.1)
	-- the wall glows, shakes and sinks into the ground in a burst of sparkles
	local home = barrier.CFrame
	local color = barrier.Color
	for _, face in ipairs(barrier:GetChildren()) do
		if face:IsA("SurfaceGui") then
			face.Enabled = false
		end
	end
	for s = 1, 12 do
		barrier.Color = color:Lerp(Color3.new(1, 1, 1), s / 12)
		barrier.CFrame = home * CFrame.new((math.random() - 0.5) * 0.4, 0, (math.random() - 0.5) * 0.4)
		task.wait(1 / 30)
	end
	burst(Vector3.new(b.X, home.Position.Y - barrier.Size.Y / 2 + 1, b.Z), Color3.fromRGB(255, 230, 120), 18, 10)
	for s = 1, 24 do
		local t = smooth(s / 24)
		barrier.CFrame = home * CFrame.new(0, -barrier.Size.Y * t, 0)
		for _, rail in ipairs(barrier:GetChildren()) do
			if rail:IsA("BasePart") then
				rail.Transparency = t
			end
		end
		task.wait(1 / 30)
	end
	task.wait(0.4)
	-- the camera comes back
	local back = root and CFrame.lookAt(root.Position + Vector3.new(-12, 8, 0), root.Position) or from
	for s = 1, 12 do
		camera.CFrame = shot:Lerp(back, smooth(s / 12))
		task.wait(1 / 30)
	end
	camera.CameraType = if savedType == Enum.CameraType.Scriptable then Enum.CameraType.Custom else savedType
	Gatekeeper.CutsceneRunning = false
	-- once the server has opened the gate, put the (now invisible) wall back
	-- where it belongs, for when it's shut again
	task.delay(2, function()
		barrier.CFrame = home
		barrier.Color = color
	end)
end

function Gatekeeper.say(i, text, mood, food)
	Gatekeeper.Last = { Gate = i, Text = text, Mood = mood, Food = food }
	local keeper = keeperOf(i)
	if not keeper then
		return
	end
	Gatekeeper.Last.Bubble = bubble(keeper, i, text, mood)
	if mood == "yes" then
		Gatekeeper.Last.Cutscene = true
		task.spawn(Gatekeeper.cutscene, i, food)
	else
		local rig = rigOf(i)
		if rig then
			rig.Act, rig.ActAt = mood, clock
		end
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
