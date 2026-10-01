-- Rolling: the Roll button's action (the server picks the results, then the
-- hatch plays: Hatch.luau), the luck pill (next to the coins), the luck
-- boost badge (next to the Roll button), auto roll (free for everyone) and
-- the compact/full hatch switch. Pressing Roll while a hatch is
-- playing skips ahead instead of rolling again, so rolling fast never
-- breaks it.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local Ui = require(script.Parent.Ui)
local Screen = require(script.Parent.Screen)
local State = require(script.Parent.State)
local Hatch = require(script.Parent.Hatch)
local Effects = require(script.Parent.Effects)

local Roll = {}

local rollFunction = State.remote("Roll")
local gui = Screen.Gui

local rolling = false
local autoRoll = false
local rollButton, autoButton -- set by Roll.buildControls

-- Luck pill -----------------------------------------------------------------------------------
-- Your effective luck where you stand ("🍀 ×7.4"), as a compact pill that
-- the HUD puts next to the coins. Hover (or tap) it for the breakdown. It
-- updates as soon as your data changes (equipping pets, boosts, rebirths)
-- and when you walk into another world.

local function times(value)
	return "×" .. Config.formatStat(value):sub(1, -2)
end

local meter = Ui.new("TextButton", {
	Name = "LuckPill",
	LayoutOrder = 3,
	Size = UDim2.fromOffset(0, 34),
	AutomaticSize = Enum.AutomaticSize.X,
	BackgroundColor3 = Color3.fromRGB(234, 249, 239),
	AutoButtonColor = false,
	Text = "",
}, {
	Ui.corner(17),
	Ui.new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}),
	Ui.new("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 12) }),
})
Roll.LuckPill = meter
local meterEdge = Ui.stroke(Color3.fromRGB(170, 226, 190), 1.5, 0)
meterEdge.Parent = meter
local luckIcon = Ui.icon("clover", 18, Ui.SUCCESS, { LayoutOrder = 0, Parent = meter })
local luckText = Ui.new("TextLabel", {
	Name = "Value",
	LayoutOrder = 1,
	AutomaticSize = Enum.AutomaticSize.X,
	Size = UDim2.fromOffset(0, 20),
	Font = Ui.FONT_DISPLAY,
	TextScaled = false,
	TextWrapped = false,
	TextSize = 20,
	TextColor3 = Color3.fromRGB(30, 140, 80),
	Parent = meter,
})
local meterScale = Ui.new("UIScale", { Parent = meter })

-- the breakdown, under the pill while hovered
local details = Ui.glass({
	Name = "LuckDetails",
	AnchorPoint = Vector2.new(0.5, 0),
	Size = UDim2.fromOffset(250, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	Radius = 14,
	Visible = false,
	ZIndex = 60,
	Parent = gui,
}, {
	Ui.new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }),
	Ui.padding(12),
})
Roll.LuckDetails = details
local detailRows = {}
local function detailRow(order, name)
	local row = Ui.new("Frame", { LayoutOrder = order, Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, ZIndex = 61, Parent = details })
	Ui.new("TextLabel", {
		Size = UDim2.new(0.65, 0, 1, 0),
		Font = if order == 99 then Ui.FONT else Ui.FONT_MEDIUM,
		TextScaled = false,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = if order == 99 then Ui.INK else Ui.MUTED,
		Text = name,
		ZIndex = 61,
		Parent = row,
	})
	detailRows[order] = Ui.new("TextLabel", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.new(0.35, 0, 1, 0),
		Font = Ui.FONT,
		TextScaled = false,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextColor3 = Ui.INK,
		ZIndex = 61,
		Parent = row,
	})
end
detailRow(1, "Luck upgrade")
detailRow(2, "Equipped pets")
detailRow(3, "Rebirths")
detailRow(4, "This world")
detailRow(5, "Luck boost (next roll)")
detailRow(6, "Bonus roll")
Ui.new("Frame", { LayoutOrder = 98, Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = Ui.LINE, ZIndex = 61, Parent = details })
detailRow(99, "Next roll")
local function placeDetails()
	local at = meter.AbsolutePosition
	local size = meter.AbsoluteSize
	if at and size then
		local scale = gui:FindFirstChildOfClass("UIScale")
		local s = if scale then scale.Scale else 1
		details.Position = UDim2.fromOffset((at.X + size.X / 2) / s, (at.Y + size.Y + 8) / s)
	end
end
meter.MouseEnter:Connect(function()
	placeDetails()
	details.Visible = true
end)
meter.MouseLeave:Connect(function()
	details.Visible = false
end)
meter.Activated:Connect(function()
	placeDetails()
	details.Visible = not details.Visible
end)

-- The world the player stands in (it changes the odds), never above unlocked
local function currentWorld(data)
	local character = Players.LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local world = if root then Config.areaAt(root.Position.X) else 1
	return math.min(world, data.Unlocked or 1)
end
Roll.currentWorld = currentWorld

local shownWorld, shownLuck = 0, nil
Roll.ShownLuck = nil -- (for the simulator) the luck the pill shows
local function refreshLuck()
	local data = State.Data
	if not data then
		return
	end
	local untilBonus = Config.BONUS_EVERY - data.Rolls % Config.BONUS_EVERY
	local nextIsBonus = untilBonus == 1
	local world = currentWorld(data)
	shownWorld = world
	-- exactly what the next roll uses (the same function the server rolls with)
	local luck = Config.luck(data, nextIsBonus, world)
	luckText.Text = if luck < 1000 then times(luck) else "×" .. Config.formatNumber(luck)
	Roll.ShownLuck = luck
	detailRows[1].Text = times(Config.upgradeValue(data, "Luck"))
	detailRows[2].Text = times(Config.petLuckTotal(data))
	detailRows[3].Text = times(Config.rebirthLuck(data.Rebirths or 0))
	detailRows[4].Text = times(Config.AREAS[math.clamp(world, 1, #Config.AREAS)].Luck)
	detailRows[5].Text = "×" .. Config.luckMultiplier(data)
	detailRows[6].Text = if nextIsBonus then "×" .. Config.BONUS_LUCK .. " now" else "×" .. Config.BONUS_LUCK .. " in " .. untilBonus
	detailRows[99].Text = luckText.Text
	-- a gold edge when the next roll is the bonus roll
	meterEdge.Color = if nextIsBonus then Ui.GOLD else Color3.fromRGB(170, 226, 190)
	meterEdge.Thickness = if nextIsBonus then 2 else 1.5
	for _, d in ipairs(luckIcon:GetDescendants()) do
		if d:IsA("Frame") and d.BackgroundTransparency < 1 then
			d.BackgroundColor3 = if nextIsBonus then Ui.GOLD else Ui.SUCCESS
		end
	end
	-- a soft pop when it changes
	if shownLuck and math.abs(luck - shownLuck) > 1e-9 then
		meterScale.Scale = if luck > shownLuck then 1.12 else 0.94
		TweenService:Create(meterScale, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	end
	shownLuck = luck
end

-- Boost badge ---------------------------------------------------------------------------------
-- A small clover badge next to the Roll button: "×8". Green and filled when
-- the roll in progress is using the boost (active), white with a gold edge
-- when it's saved for your next roll (waiting), hidden when there's none.
-- It pops when the boost grows and shrinks away when it's used up.

local badge = Ui.new("Frame", {
	Name = "BoostBadge",
	AnchorPoint = Vector2.new(1, 0.5),
	Size = UDim2.fromOffset(74, 34),
	BackgroundColor3 = Ui.WHITE,
	Visible = false,
}, {
	Ui.corner(17),
	Ui.new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 5),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}),
})
Roll.BoostBadge = badge
local badgeEdge = Ui.stroke(Ui.GOLD, 2, 0)
badgeEdge.Parent = badge
local badgeIcon = Ui.icon("clover", 16, Ui.GOLD, { LayoutOrder = 0, Parent = badge })
local badgeText = Ui.new("TextLabel", {
	LayoutOrder = 1,
	Size = UDim2.fromOffset(40, 20),
	Font = Ui.FONT_DISPLAY,
	TextScaled = false,
	TextWrapped = false,
	TextSize = 18,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = badge,
})
local badgeScale = Ui.new("UIScale", { Parent = badge })
Roll.BadgeState = "none"
local badgeMultiplier = 1

local function paintIcon(color)
	for _, d in ipairs(badgeIcon:GetDescendants()) do
		if d:IsA("Frame") and d.BackgroundTransparency < 1 then
			d.BackgroundColor3 = color
		end
	end
end

local function setBadge(state, multiplier)
	local previous, before = Roll.BadgeState, badgeMultiplier
	Roll.BadgeState, badgeMultiplier = state, multiplier
	if state == "none" then
		if badge.Visible then
			-- used up: shrink away
			TweenService:Create(badgeScale, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.In), { Scale = 0.6 }):Play()
			task.delay(0.2, function()
				if Roll.BadgeState == "none" then
					badge.Visible = false
				end
			end)
		end
		return
	end
	badgeText.Text = "×" .. multiplier
	local active = state == "active"
	badge.BackgroundColor3 = if active then Ui.SUCCESS else Ui.WHITE
	badgeEdge.Color = if active then Color3.fromRGB(36, 168, 100) else Ui.GOLD
	badgeText.TextColor3 = if active then Ui.WHITE else Color3.fromRGB(200, 140, 20)
	paintIcon(if active then Ui.WHITE else Ui.GOLD)
	if not badge.Visible then
		badge.Visible = true
		badgeScale.Scale = 0.6
		TweenService:Create(badgeScale, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	elseif multiplier > before or previous ~= state then
		badgeScale.Scale = if multiplier > before then 1.3 else 1.1
		TweenService:Create(badgeScale, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	end
end
Hatch.BoostChanged.Event:Connect(setBadge)

-- Rolling --------------------------------------------------------------------------------

local rollLabel, cooldownFill -- set by Roll.buildControls
local function setRollLabel(text)
	if rollLabel then
		rollLabel.Text = string.upper(text)
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
	setRollLabel("Roll")
	local started = os.clock()
	local world = currentWorld(data)
	local discoveredBefore = table.clone(data.Discovered or {})
	local ok, results = pcall(rollFunction.InvokeServer, rollFunction)
	if ok and type(results) == "table" and #results > 0 then
		-- the full hatch the first time and when rolling by hand; a quicker
		-- one when grinding (auto roll, Auto Hatch 1, or the setting off)
		local fast = hatchedOnce and (not State.Settings.Reveals or autoRoll or Config.upgradeLevel(data, "AutoHatch") >= 1)
		hatchedOnce = true
		-- the spinner is always at the bottom of the screen (by hand and on
		-- auto); the full mode adds the big reveal. A Huge or Titanic gets the
		-- bush cutscene and a crazy pull its own show (Hatch decides, from the
		-- results the server already rolled; the animation never changes them)
		local mode = if State.Settings.FullHatch and not autoRoll then "full" else "compact"
		if not autoRoll then
			setRollLabel("Skip") -- pressing it now skips the show
		end
		Hatch.play(results, fast, results[1].World or world, mode, autoRoll)
		setRollLabel("Roll")
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
	-- wait out the cooldown (the bar in the Roll button fills meanwhile)
	local cooldown = Config.rollCooldown(State.Data)
	while os.clock() - started < cooldown do
		if cooldownFill then
			cooldownFill.Size = UDim2.fromScale(math.clamp((os.clock() - started) / cooldown, 0, 1), 1)
		end
		task.wait()
	end
	if cooldownFill then
		cooldownFill.Size = UDim2.fromScale(1, 1)
	end
	setRollLabel("Roll")
	rolling = false
end

local autoRow -- set by Roll.buildControls
local function refreshAuto(animate)
	if not autoRow then
		return
	end
	-- AUTO: white "AUTO OFF", or green "AUTO ON" with its status dot lit
	Ui.setStyle(autoRow, if autoRoll then "green" else "glass")
	if Roll.AutoCaption then
		Roll.AutoCaption.Text = if autoRoll then "AUTO ON" else "AUTO OFF"
	end
	if Roll.AutoDot then
		Roll.AutoDot.Visible = autoRoll
	end
	if animate then
		Ui.pop(autoRow, 0.92)
	end
end

function Roll.autoOn()
	return autoRoll
end

-- Auto roll: free for everyone
function Roll.toggleAuto()
	autoRoll = not autoRoll
	refreshAuto(true)
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

-- (kept for older callers)
function Roll.bindButtons(roll, auto)
	rollButton, autoButton = roll, auto
	refreshAuto()
end

-- the ROLL button and the AUTO switch (for the simulator)
function Roll.controls()
	return rollButton, autoButton
end

-- The roll controls ---------------------------------------------------------------------------
-- Two buttons in the bottom-right corner, made like the navigation buttons
-- on the left (a rounded square with an icon and a caption under it), with
-- a cleaner finish: a soft shadow under each, a faint shine on top, small
-- bold captions.
--   ROLL   a little bigger, blue. A slim bar inside fills while the next
--          roll gets ready; its caption says SKIP while a hatch shows (by hand).
--   AUTO   next to it: white with a dark icon and "AUTO OFF", or green with
--          "AUTO ON" and a small status dot in its corner.
-- The R key (or a gamepad's X) rolls too. The compact/full hatch choice
-- lives in Settings ("Big hatch reveals").

local ROLL_SIZE, AUTO_SIZE, GAP = 72, 58, 12
Roll.DOCK_SIZE = Vector2.new(ROLL_SIZE + GAP + AUTO_SIZE, ROLL_SIZE + 18)

-- the shared finish: shadow under the button, shine on top, neat caption
local function finish(holder, button, size)
	local radius = math.floor(size * 0.32)
	button.ZIndex = 2
	Ui.shadow(button, radius, 4)
	Ui.new("Frame", {
		Name = "Shine",
		Position = UDim2.fromOffset(4, 3),
		Size = UDim2.new(1, -8, 0.42, 0),
		BackgroundColor3 = Ui.WHITE,
		BackgroundTransparency = 0.88,
		ZIndex = 3,
		Parent = button,
	}, { Ui.corner(radius - 3) })
	local caption = holder.Caption
	caption.Font = Ui.FONT_TITLE
	caption.TextSize = 12
	caption.TextStrokeTransparency = 0.7
	return caption
end

function Roll.buildControls(parent)
	-- an invisible row that just lines the two buttons up
	local row = Ui.new("Frame", {
		Name = "RollButtons",
		LayoutOrder = 1,
		Size = UDim2.fromOffset(Roll.DOCK_SIZE.X, Roll.DOCK_SIZE.Y),
		BackgroundTransparency = 1,
		Parent = parent,
	}, {
		Ui.new("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			VerticalAlignment = Enum.VerticalAlignment.Bottom,
			Padding = UDim.new(0, GAP),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})

	-- ROLL
	local rollHolder, roll = Ui.dockButton({
		Name = "Roll",
		Label = "ROLL",
		Icon = "dice",
		IconSize = 34,
		Size = ROLL_SIZE,
		Style = "primary",
		LayoutOrder = 1,
		Parent = row,
	}, function()
		Effects.play("Click", 1, 0.05)
		task.spawn(Roll.roll)
	end)
	roll.Name = "RollButton"
	rollLabel = finish(rollHolder, roll, ROLL_SIZE)
	rollLabel.TextSize = 13
	-- the slim ready bar near the bottom of the button
	local bar = Ui.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -7),
		Size = UDim2.new(1, -30, 0, 3),
		BackgroundColor3 = Color3.fromRGB(28, 66, 180),
		BackgroundTransparency = 0.3,
		ZIndex = 4,
		Parent = roll,
	}, { Ui.corner(2) })
	cooldownFill = Ui.new("Frame", {
		Name = "Ready",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Ui.WHITE,
		ZIndex = 5,
		Parent = bar,
	}, { Ui.corner(2) })

	-- AUTO
	local autoHolder, auto = Ui.dockButton({
		Name = "Auto",
		Label = "AUTO OFF",
		Icon = "loop",
		IconSize = 26,
		Size = AUTO_SIZE,
		Style = "glass",
		LayoutOrder = 2,
		Parent = row,
	}, function()
		Effects.play("Click", 1, 0.05)
		Roll.toggleAuto()
	end)
	auto.Name = "AutoButton"
	Roll.AutoCaption = finish(autoHolder, auto, AUTO_SIZE)
	-- a small status dot, lit while auto is on
	Roll.AutoDot = Ui.new("Frame", {
		Name = "Dot",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(1, -9, 0, 9),
		Size = UDim2.fromOffset(8, 8),
		BackgroundColor3 = Ui.WHITE,
		Visible = false,
		ZIndex = 5,
		Parent = auto,
	}, { Ui.corner(0.5) })

	rollButton, autoButton, autoRow = roll, auto, auto
	refreshAuto(false)
	return roll, auto
end

-- the R key (or a gamepad's X) rolls too
game:GetService("UserInputService").InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.KeyCode == Enum.KeyCode.R or input.KeyCode == Enum.KeyCode.ButtonX then
		task.spawn(Roll.roll)
	end
end)

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
	if not Hatch.busy() then
		local waiting = Config.luckMultiplier(State.Data)
		if waiting > 1 then
			setBadge("waiting", waiting)
		elseif Roll.BadgeState ~= "none" then
			setBadge("none", 1)
		end
	end
end)

return Roll
