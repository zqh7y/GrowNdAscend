-- Rolling: the Roll button's action (the server picks the pets, then the
-- hatch show plays: Hatch.luau), the luck chip, and auto roll (an upgrade).
-- Pressing Roll while a hatch is playing skips ahead instead of rolling
-- again, so rolling fast never breaks the show.
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
local rollButton, autoButton -- set by the HUD

-- Luck chip ------------------------------------------------------------------------------

-- sits above the Roll and Auto buttons on the right
local luckChip = Ui.glass({
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -16, 1, -226),
	Size = UDim2.fromOffset(0, 28),
	AutomaticSize = Enum.AutomaticSize.X,
	Radius = 14,
	Parent = gui,
}, {
	Ui.new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}),
	Ui.new("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) }),
})
local luckIcon = Ui.icon("clover", 14, Ui.SUCCESS, { LayoutOrder = 0, Parent = luckChip })
local luckText = Ui.new("TextLabel", {
	LayoutOrder = 1,
	AutomaticSize = Enum.AutomaticSize.X,
	Size = UDim2.fromOffset(0, 16),
	Font = Ui.FONT_MEDIUM,
	TextScaled = false,
	TextSize = 13,
	Parent = luckChip,
})

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
	luckText.Text = string.format("x%.2f LUCK  ·  %s", luck, Config.AREAS[world].Name) .. "  ·  " .. (if nextIsBonus then "BONUS ROLL NEXT!" else "bonus in " .. untilBonus)
	luckText.TextColor3 = if nextIsBonus then Ui.GOLD else Ui.TEXT
	for _, d in ipairs(luckIcon:GetDescendants()) do
		if d:IsA("Frame") and d.BackgroundTransparency < 1 then
			d.BackgroundColor3 = if nextIsBonus then Ui.GOLD else Ui.SUCCESS
		end
	end
	luckChip.Edge.Color = if nextIsBonus then Ui.GOLD else Color3.new(1, 1, 1)
	luckChip.Edge.Transparency = if nextIsBonus then 0.2 else 0.82
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
		-- the full show the first time and when rolling by hand; a quicker
		-- one when grinding (auto roll, Auto Hatch 2, or the setting off)
		local fast = hatchedOnce and (not State.Settings.Reveals or autoRoll or Config.upgradeLevel(data, "AutoHatch") >= 2)
		hatchedOnce = true
		Hatch.play(results, fast, results[1].World or world)
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
	local data = State.Data
	if not autoButton or not data then
		return
	end
	local unlocked = Config.upgradeLevel(data, "AutoHatch") >= 1
	if not unlocked then
		autoRoll = false
	end
	Ui.setStyle(autoButton, if not unlocked then "disabled" elseif autoRoll then "success" else "glass")
	Ui.setIcon(autoButton, if unlocked then "loop" else "lock")
	autoButton.Parent.Caption.Text = if not unlocked then "Auto" elseif autoRoll then "Auto ON" else "Auto"
end

function Roll.autoOn()
	return autoRoll
end

function Roll.toggleAuto()
	local data = State.Data
	if not data then
		return
	end
	if Config.upgradeLevel(data, "AutoHatch") < 1 then
		Screen.toast("Unlock Auto Hatch in the upgrade tree!", "danger")
		return
	end
	autoRoll = not autoRoll
	refreshAuto()
end

-- the HUD gives us its dock buttons
function Roll.bindButtons(roll, auto)
	rollButton, autoButton = roll, auto
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
