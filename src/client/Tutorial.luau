-- Tutorials (each shown once per player; the server remembers them in
-- data.Seen through the MarkSeen remote):
--   The first-time tutorial: a friendly guide card at the bottom of the
--   screen with a bouncing arrow at what to use (a button on screen, or a
--   thing in the world). Each step goes on by itself when you do it, or with
--   NEXT; SKIP ends it.
--     1 tap the AUTO dice to roll pets     (goes on when you've rolled)
--     2 open your Inventory, Equip Best    (goes on when a pet is equipped)
--     3 your pets fight: walk near enemies (goes on when you earn coins)
--     4 the Upgrade Board                  (NEXT)
--     5 feed the gatekeeper to open a new world (NEXT, the end)
--   A world tour: the first time you walk into a world after the Forest the
--   camera flies to each of its machines with a caption for a few seconds,
--   then comes back (SKIP stops it).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local Screen = require(script.Parent.Screen)
local State = require(script.Parent.State)
local Ui = require(script.Parent.Ui)

local Tutorial = {}

local markSeen = State.remote("MarkSeen")
local player = Players.LocalPlayer

Tutorial.Running = nil -- "Tutorial" or "World<n>" while one is showing
Tutorial.Step = 0
Tutorial.Shots = nil -- (for the simulator: the world tour's stops)

local function seen(key)
	local data = State.Data
	return data and data.Seen and data.Seen[key] == true
end

local function remember(key)
	-- (asked of the server; the client copy is set too so it's never shown twice)
	local data = State.Data
	if data then
		data.Seen = data.Seen or {}
		data.Seen[key] = true
	end
	task.spawn(function()
		pcall(function()
			markSeen:InvokeServer(key)
		end)
	end)
end

-- The guide card --------------------------------------------------------------------------------

local card = Ui.glass({
	Name = "TutorialCard",
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -24),
	Size = UDim2.fromOffset(520, 118),
	Radius = 22,
	Visible = false,
	ZIndex = 50,
	Parent = Screen.Gui,
}, { Ui.padding(14) })
Tutorial.Card = card
Ui.stroke(Color3.fromRGB(255, 200, 60), 3, 0).Parent = card
local count = Ui.new("TextLabel", {
	Name = "Count",
	Size = UDim2.new(1, 0, 0, 16),
	Font = Ui.FONT_TITLE,
	TextScaled = false,
	TextSize = 13,
	TextColor3 = Color3.fromRGB(230, 150, 20),
	TextXAlignment = Enum.TextXAlignment.Left,
	Text = "",
	ZIndex = 51,
	Parent = card,
})
local title = Ui.chunky({
	Name = "Title",
	Position = UDim2.fromOffset(0, 16),
	Size = UDim2.new(1, -130, 0, 30),
	TextSize = 26,
	Text = "",
	TextXAlignment = Enum.TextXAlignment.Left,
	Outline = 2.5,
	ZIndex = 51,
	Parent = card,
})
local body = Ui.new("TextLabel", {
	Name = "Body",
	Position = UDim2.fromOffset(0, 50),
	Size = UDim2.new(1, -130, 0, 40),
	Font = Ui.FONT_MEDIUM,
	TextScaled = false,
	TextWrapped = true,
	TextSize = 16,
	TextColor3 = Ui.TEXT,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	Text = "",
	ZIndex = 51,
	Parent = card,
})
local nextButton = Ui.button({
	Name = "Next",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, 0, 0, 8),
	Size = UDim2.fromOffset(118, 44),
	Text = "NEXT",
	TextSize = 18,
	ZIndex = 52,
	Parent = card,
}, function()
	if Tutorial.OnNext then
		Tutorial.OnNext()
	end
end, "gold")
Tutorial.NextButton = nextButton
local skipButton = Ui.button({
	Name = "Skip",
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, 0, 1, 0),
	Size = UDim2.fromOffset(118, 32),
	Text = "SKIP",
	TextSize = 14,
	ZIndex = 52,
	Parent = card,
}, function()
	if Tutorial.OnSkip then
		Tutorial.OnSkip()
	end
end, "glass")
Tutorial.SkipButton = skipButton

local function show(step, total, heading, text)
	count.Text = if total > 0 then string.format("STEP %d / %d", step, total) else "NEW WORLD"
	title.Text = heading
	body.Text = text
	card.Visible = true
end

-- The pointing arrow: on a button on screen, or over a thing in the world ------------------------

local screenArrow = Ui.chunky({
	Name = "TutorialArrow",
	AnchorPoint = Vector2.new(0.5, 1),
	Size = UDim2.fromOffset(60, 60),
	TextSize = 56,
	Text = "▼",
	Colors = { Color3.fromRGB(255, 230, 90), Color3.fromRGB(255, 160, 30) },
	Outline = 3,
	Visible = false,
	ZIndex = 60,
	Parent = Screen.Gui,
})
local worldArrow = Instance.new("BillboardGui")
worldArrow.Name = "TutorialWorldArrow"
worldArrow.Size = UDim2.fromOffset(90, 90)
worldArrow.AlwaysOnTop = true
worldArrow.Enabled = false
local worldLabel = Instance.new("TextLabel")
worldLabel.BackgroundTransparency = 1
worldLabel.Size = UDim2.fromScale(1, 1)
worldLabel.Font = Enum.Font.FredokaOne
worldLabel.TextScaled = true
worldLabel.Text = "▼"
worldLabel.TextColor3 = Color3.fromRGB(255, 210, 60)
worldLabel.TextStrokeColor3 = Color3.fromRGB(60, 40, 20)
worldLabel.TextStrokeTransparency = 0
worldLabel.Parent = worldArrow
worldArrow.Parent = player:WaitForChild("PlayerGui")

local pointAt = nil -- a GuiObject or a BasePart (or nil)
local function point(target)
	pointAt = target
	screenArrow.Visible = false
	worldArrow.Enabled = false
	if typeof(target) == "Instance" and target:IsA("BasePart") then
		worldArrow.Adornee = target
		worldArrow.StudsOffsetWorldSpace = Vector3.new(0, target.Size.Y / 2 + 6, 0)
		worldArrow.Enabled = true
	elseif typeof(target) == "Instance" and target:IsA("GuiObject") then
		screenArrow.Visible = true
	end
end
Tutorial.point = point

local bounce = 0
RunService.Heartbeat:Connect(function(dt)
	bounce += dt
	local lift = math.abs(math.sin(bounce * 4)) * 14
	if screenArrow.Visible and typeof(pointAt) == "Instance" and pointAt:IsA("GuiObject") then
		local at = pointAt.AbsolutePosition + Vector2.new(pointAt.AbsoluteSize.X / 2, 0)
		local inset = Screen.Gui.AbsolutePosition
		screenArrow.Position = UDim2.fromOffset(at.X - inset.X, at.Y - inset.Y - 4 - lift)
	end
	if worldArrow.Enabled then
		worldArrow.ExtentsOffsetWorldSpace = Vector3.new(0, lift / 14, 0)
	end
end)

local function hide()
	card.Visible = false
	point(nil)
	Tutorial.OnNext, Tutorial.OnSkip = nil, nil
end

-- What the steps point at --------------------------------------------------------------------

local function find(root, name)
	return root and root:FindFirstChild(name, true)
end
local function map()
	return workspace:FindFirstChild("Map")
end

-- The first-time tutorial --------------------------------------------------------------------------

Tutorial.STEPS = {
	{
		Title = "Roll for pets!",
		Text = "Tap the AUTO dice to keep rolling pets. Rarer pets are stronger!",
		Target = function()
			return find(Screen.Controls, "AutoButton")
		end,
		Done = function(data, start)
			return (data.Rolls or 0) > (start.Rolls or 0)
		end,
	},
	{
		Title = "Equip your pets",
		Text = "Open your Inventory and press Equip Best: your pets follow you and help.",
		Target = function()
			local nav = require(script.Parent.Hud).NavButtons
			return nav and nav.Inventory
		end,
		Done = function(data)
			return #(data.Equipped or {}) > 0
		end,
	},
	{
		Title = "Your pets fight for you",
		Text = "Walk near the trees: your pets break them for coins and EXP.",
		Done = function(data, start)
			return (data.Coins or 0) > (start.Coins or 0)
		end,
	},
	{
		Title = "Get stronger",
		Text = "Spend your coins at the Upgrade Board: more damage, coins and luck.",
		Target = function()
			return find(find(map(), "UpgradeBoard"), "Screen")
		end,
	},
	{
		Title = "Open new worlds",
		Text = "Feed the gatekeeper by the wall to open the next world. Have fun!",
		Target = function()
			local gate = map() and map():FindFirstChild("Gate2")
			return gate and gate:FindFirstChild("Head", true)
		end,
	},
}

function Tutorial.runIntro()
	if Tutorial.Running then
		return
	end
	Tutorial.Running = "Tutorial"
	local finished = false
	local function finish()
		if finished then
			return
		end
		finished = true
		hide()
		remember("Tutorial")
		Tutorial.Running = nil
	end
	Tutorial.OnSkip = finish
	local function go(n)
		if finished then
			return
		end
		local step = Tutorial.STEPS[n]
		if not step then
			finish()
			return
		end
		Tutorial.Step = n
		local start = table.clone(State.Data or {})
		show(n, #Tutorial.STEPS, step.Title, step.Text)
		Ui.setText(nextButton, if n == #Tutorial.STEPS then "DONE" else "NEXT")
		point(step.Target and step.Target())
		local moved = false
		local function advance()
			if moved or finished or Tutorial.Step ~= n then
				return
			end
			moved = true
			go(n + 1)
		end
		Tutorial.OnNext = advance
		-- (goes on by itself once you've done it)
		if step.Done then
			task.spawn(function()
				while not moved and not finished and Tutorial.Step == n do
					local data = State.Data
					if data and step.Done(data, start) then
						task.wait(0.6)
						advance()
						break
					end
					task.wait(0.3)
				end
			end)
		end
	end
	go(1)
end

-- A new world's tour ----------------------------------------------------------------------------

local function bossSpot()
	return Vector3.new(Config.areaStart(Config.bossArea()) + 56, Config.GROUND_Y + 6, 0)
end

-- the stops of each world's tour: { what, caption, where (a part, or a position) }
Tutorial.TOURS = {
	[2] = {
		{ "Pet Aura Machine", "Step on its purple pad to give a pet an aura: a big boost to one of its stats!", function() return find(map(), "AuraCircle") end },
		{ "Mega Roll", "A huge-luck roll waits here every 20 minutes. Step on the pad to claim it!", function() return find(find(map(), "MegaRoll"), "Pad") end },
	},
	[3] = {
		{ "Boost Machine", "Step on its blue pad for a free Luck or Coins boost, every 5 minutes!", function() return find(map(), "BoostCircle") end },
	},
	[4] = {
		{ "Fuse Machine", "Fuse 100 of a pet into a HUGE one, and 20 Huge into a TITANIC!", function() return find(map(), "FuseCircle") end },
	},
	[5] = {
		{ "The Magma Titan", "A giant boss! Your pets fight it from anywhere in this world. Great for AFK!", bossSpot },
		{ "Boss Shop", "Spend coins on upgrades that only work on bosses: damage, coins, EXP and crits.", function() return find(map(), "BossShopCircle") end },
	},
}

Tutorial.TOUR_STOP = 3 -- seconds at each stop

function Tutorial.runWorld(i)
	local tour = Tutorial.TOURS[i]
	if Tutorial.Running or not tour then
		return
	end
	Tutorial.Running = "World" .. i
	remember("World" .. i)
	local camera = workspace.CurrentCamera
	local saved = camera.CameraType
	local stopped = false
	Tutorial.OnSkip = function()
		stopped = true
	end
	Tutorial.OnNext = function()
		stopped = true
	end
	Ui.setText(nextButton, "OK")
	Tutorial.Shots = {}
	camera.CameraType = Enum.CameraType.Scriptable
	local from = camera.CFrame
	for n, stop in ipairs(tour) do
		if stopped then
			break
		end
		local where = stop[3]()
		local at = if typeof(where) == "Vector3" then where elseif where then where.Position else nil
		if at then
			show(0, 0, stop[1], stop[2])
			count.Text = string.format("%s  ·  %d / %d", string.upper(Config.AREAS[i].Name), n, #tour)
			local side = if at.Z > 1 then -1 elseif at.Z < -1 then 1 else 1
			local shot = CFrame.lookAt(at + Vector3.new(-12, 9, side * 14), at + Vector3.new(0, 1.5, 0))
			table.insert(Tutorial.Shots, { Name = stop[1], At = at })
			local before = camera.CFrame
			for s = 1, 18 do
				local t = s / 18
				camera.CFrame = before:Lerp(shot, t * t * (3 - 2 * t))
				task.wait(1 / 30)
			end
			local waited = 0
			while waited < Tutorial.TOUR_STOP and not stopped do
				waited += task.wait(0.1)
			end
		end
	end
	-- back to the player
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local back = if root then CFrame.lookAt(root.Position + Vector3.new(-12, 8, 0), root.Position) else from
	local before = camera.CFrame
	for s = 1, 12 do
		local t = s / 12
		camera.CFrame = before:Lerp(back, t * t * (3 - 2 * t))
		task.wait(1 / 30)
	end
	camera.CameraType = if saved == Enum.CameraType.Scriptable then Enum.CameraType.Custom else saved
	hide()
	Tutorial.Running = nil
end

-- When to show them --------------------------------------------------------------------------------

Tutorial.ENABLED = true -- (the simulator turns the automatic start off and runs them itself)
local started = false
local since = 0
RunService.Heartbeat:Connect(function(dt)
	since += dt
	if since < 0.5 or not Tutorial.ENABLED then
		return
	end
	since = 0
	local data = State.Data
	if not data or Tutorial.Running then
		return
	end
	-- the first-time tutorial, a few seconds after joining
	if not seen("Tutorial") then
		if not started then
			started = true
			task.delay(4, function()
				if Tutorial.ENABLED and not seen("Tutorial") then
					Tutorial.runIntro()
				end
			end)
		end
		return
	end
	-- a new world's tour, the first time you walk in
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if root and Screen.current() == nil and not require(script.Parent.Gatekeeper).CutsceneRunning then
		local area = Config.areaAt(root.Position.X)
		if area >= 2 and area <= (data.Unlocked or 1) and not seen("World" .. area) and Tutorial.TOURS[area] then
			task.spawn(Tutorial.runWorld, area)
		end
	end
end)

return Tutorial
