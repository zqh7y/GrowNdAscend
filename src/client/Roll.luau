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

-- Luck chip -----------------------------------------------------------------------------------
-- A small chip at the top, with the rest of your progress (coins, team,
-- level): your luck where you stand, and how many rolls until the 2x
-- bonus roll. Nothing cluttering the Roll button.

local meter = Ui.glass({
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 160),
	Size = UDim2.fromOffset(0, 28),
	AutomaticSize = Enum.AutomaticSize.X,
	Radius = 14,
	Parent = gui,
}, {
	Ui.new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}),
	Ui.new("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 12) }),
})
local luckIcon = Ui.icon("clover", 16, Ui.SUCCESS, { LayoutOrder = 0, Parent = meter })
local luckText = Ui.new("TextLabel", {
	LayoutOrder = 1,
	AutomaticSize = Enum.AutomaticSize.X,
	Size = UDim2.fromOffset(0, 16),
	TextScaled = false,
	TextSize = 14,
	Parent = meter,
})
local bonusText = Ui.new("TextLabel", {
	LayoutOrder = 2,
	AutomaticSize = Enum.AutomaticSize.X,
	Size = UDim2.fromOffset(0, 16),
	Font = Ui.FONT_MEDIUM,
	TextScaled = false,
	TextSize = 12,
	TextColor3 = Ui.MUTED,
	Parent = meter,
})
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
	luckText.Text = string.format("Luck x%.2f", luck)
	bonusText.Text = if nextIsBonus then "· 2x bonus roll!" else "· 2x in " .. untilBonus
	bonusText.TextColor3 = if nextIsBonus then Ui.GOLD else Ui.MUTED
	meter.Edge.Color = if nextIsBonus then Ui.GOLD else Ui.LINE
	meter.Edge.Thickness = if nextIsBonus then 2 else 1
	for _, d in ipairs(luckIcon:GetDescendants()) do
		if d:IsA("Frame") and d.BackgroundTransparency < 1 then
			d.BackgroundColor3 = if nextIsBonus then Ui.GOLD else Ui.SUCCESS
		end
	end
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
		-- the compact row at the top unless the big hatch is switched on
		-- (a Huge or Titanic always gets its big reveal afterwards)
		local fast = hatchedOnce and (not State.Settings.Reveals or autoRoll or Config.upgradeLevel(data, "AutoHatch") >= 1)
		hatchedOnce = true
		meterScale.Scale = 1.06
		task.delay(0.12, function()
			meterScale.Scale = 1
		end)
		if not State.Settings.FullHatch then
			Hatch.compact(results, fast)
			for _, result in ipairs(results) do
				if result.Size >= 2 then
					Hatch.reveal(result.Pet, result.Size)
					break
				end
			end
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
		local full = State.Settings.FullHatch
		Ui.setStyle(hideButton, if full then "purple" else "glass")
		hideButton.Parent.Caption.Text = if full then "FULL" else "COMPACT"
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

-- Switch between the compact hatch (top of the screen) and the full one
function Roll.toggleHatchMode()
	State.Settings.FullHatch = not State.Settings.FullHatch
	if Hatch.busy() then
		Hatch.skip()
	end
	refreshAuto()
end
Roll.toggleHide = Roll.toggleHatchMode

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
