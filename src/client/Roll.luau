-- Rolling: the Roll button's action (the server picks the pets, then the
-- hatch plays: Hatch.luau), the luck meter, auto roll (free for everyone)
-- and hiding the hatches (results then slide in as small cards at the side,
-- so you can grind without the animation). Pressing Roll while a hatch is
-- playing skips ahead instead of rolling again, so rolling fast never
-- breaks it.
local Players = game:GetService("Players")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local Ui = require(script.Parent.Ui)
local Screen = require(script.Parent.Screen)
local State = require(script.Parent.State)
local Hatch = require(script.Parent.Hatch)

local Roll = {}

local rollFunction = State.remote("Roll")
local gui = Screen.Gui

local rolling = false
local autoRoll = false
local rollButton, autoButton, hideButton -- set by the HUD

-- Luck meter --------------------------------------------------------------------------------
-- Above the Roll button: your luck and where you are, and 10 segments that
-- fill with every roll; the 10th roll is a BONUS roll with double luck.

local meter = Ui.glass({
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -16, 1, -282),
	Size = UDim2.fromOffset(236, 50),
	Radius = 6,
	Parent = gui,
}, { Ui.padding(8) })
Ui.accentLine(meter, Ui.CYAN)
local luckIcon = Ui.icon("clover", 14, Ui.SUCCESS, { Position = UDim2.fromOffset(0, 0), Parent = meter })
local luckText = Ui.new("TextLabel", {
	Position = UDim2.fromOffset(20, 0),
	Size = UDim2.new(1, -20, 0, 14),
	Font = Ui.FONT_MEDIUM,
	TextScaled = false,
	TextSize = 12,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = meter,
})
local bonusSegments = {}
local segmentRow = Ui.new("Frame", {
	Position = UDim2.fromOffset(0, 22),
	Size = UDim2.new(1, 0, 0, 12),
	BackgroundTransparency = 1,
	Parent = meter,
}, {
	Ui.new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 3),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}),
})
for i = 1, Config.BONUS_EVERY do
	bonusSegments[i] = Ui.new("Frame", {
		LayoutOrder = i,
		Size = UDim2.new(1 / Config.BONUS_EVERY, -3, 1, 0),
		BackgroundColor3 = Ui.GLASS_LIGHT,
		Parent = segmentRow,
	}, { Ui.corner(2) })
end
local meterScale = Ui.new("UIScale", { Parent = meter })

-- The world the player stands in (it changes the odds), never above unlocked
local function currentWorld(data)
	local character = Players.LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local world = if root then Config.areaAt(root.Position.X) else 1
	return math.min(world, data.Unlocked or 1)
end
Roll.currentWorld = currentWorld

local shownWorld = 0
local function refreshLuck()
	local data = State.Data
	if not data then
		return
	end
	local untilBonus = Config.BONUS_EVERY - data.Rolls % Config.BONUS_EVERY
	local nextIsBonus = untilBonus == 1
	local world = currentWorld(data)
	shownWorld = world
	local luck = Config.luck(data, nextIsBonus, world)
	luckText.Text = if nextIsBonus
		then string.format("2x BONUS ROLL READY  ·  x%.2f LUCK", luck)
		else string.format("x%.2f LUCK  ·  %s  ·  bonus in %d", luck, string.upper(Config.AREAS[world].Name), untilBonus)
	luckText.TextColor3 = if nextIsBonus then Ui.GOLD else Ui.TEXT
	for _, d in ipairs(luckIcon:GetDescendants()) do
		if d:IsA("Frame") and d.BackgroundTransparency < 1 then
			d.BackgroundColor3 = if nextIsBonus then Ui.GOLD else Ui.SUCCESS
		end
	end
	-- the segments fill up towards the bonus roll
	local filled = Config.BONUS_EVERY - untilBonus + 1
	for i, segment in ipairs(bonusSegments) do
		segment.BackgroundColor3 = if nextIsBonus then Ui.GOLD elseif i < filled then Ui.CYAN:Lerp(Ui.VIOLET, i / Config.BONUS_EVERY) else Ui.GLASS_LIGHT
	end
	meter.Edge.Color = if nextIsBonus then Ui.GOLD else Ui.LINE
	meter.Edge.Transparency = if nextIsBonus then 0 else 0.35
end

-- Rolling --------------------------------------------------------------------------------

local function setRollLabel(text)
	if rollButton then
		rollButton.Parent.Caption.Text = text
	end
end

local hatchedOnce = false

function Roll.roll()
	local data = State.Data
	if Hatch.busy() then
		Hatch.skip() -- pressing Roll during the show skips ahead
		return
	end
	if rolling or not data then
		return
	end
	rolling = true
	setRollLabel("Rolling")
	local started = os.clock()
	local world = currentWorld(data)
	local discoveredBefore = table.clone(data.Discovered or {})
	local ok, results = pcall(rollFunction.InvokeServer, rollFunction)
	if ok and type(results) == "table" and #results > 0 then
		-- the full hatch the first time and when rolling by hand; a quicker
		-- one when grinding (auto roll, Auto Hatch 1, or the setting off);
		-- hidden hatches just slide the results in at the side
		local fast = hatchedOnce and (not State.Settings.Reveals or autoRoll or Config.upgradeLevel(data, "AutoHatch") >= 1)
		hatchedOnce = true
		meterScale.Scale = 1.06
		task.delay(0.12, function()
			meterScale.Scale = 1
		end)
		if State.Settings.HideHatch then
			Hatch.feed(results)
		else
			Hatch.play(results, fast, results[1].World or world)
		end
		local discovered = discoveredBefore
		for _, result in ipairs(results) do
			if result.First and not discovered[result.Pet] then
				discovered[result.Pet] = true
				local n = 0
				for _ in pairs(discovered) do
					n += 1
				end
				Screen.toast(string.format("New animal discovered: %s!  (%d / %d)", result.Pet, n, #Config.PETS), "success")
			end
		end
	end
	-- wait out the cooldown
	local left = Config.rollCooldown(State.Data) - (os.clock() - started)
	if left > 0 then
		task.wait(left)
	end
	setRollLabel("Roll")
	rolling = false
end

local function refreshAuto()
	if autoButton then
		Ui.setStyle(autoButton, if autoRoll then "success" else "glass")
		autoButton.Parent.Caption.Text = if autoRoll then "AUTO ON" else "AUTO"
	end
	if hideButton then
		local hidden = State.Settings.HideHatch
		Ui.setStyle(hideButton, if hidden then "purple" else "glass")
		hideButton.Parent.Caption.Text = if hidden then "HIDDEN" else "SHOW"
	end
end

function Roll.autoOn()
	return autoRoll
end

-- Auto roll: free for everyone
function Roll.toggleAuto()
	autoRoll = not autoRoll
	refreshAuto()
end

-- Hide the hatch animation (results slide in at the side instead)
function Roll.toggleHide()
	State.Settings.HideHatch = not State.Settings.HideHatch
	if State.Settings.HideHatch and Hatch.busy() then
		Hatch.skip()
	end
	refreshAuto()
end

-- the HUD gives us its dock buttons
function Roll.bindButtons(roll, auto, hide)
	rollButton, autoButton, hideButton = roll, auto, hide
	refreshAuto()
end

task.spawn(function()
	while true do
		if autoRoll and not rolling then
			Roll.roll()
		else
			task.wait(0.1)
		end
	end
end)

-- The full hatch reveal on its own (no strip)
function Roll.bigReveal(petName, sizeIndex)
	Hatch.reveal(petName, sizeIndex)
end

-- walking into another world changes the odds: keep the luck chip current
task.spawn(function()
	while true do
		task.wait(0.5)
		local data = State.Data
		if data and currentWorld(data) ~= shownWorld then
			refreshLuck()
		end
	end
end)

State.watch(function()
	refreshLuck()
	refreshAuto()
end)

return Roll
