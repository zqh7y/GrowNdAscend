-- Rolling: the Roll button's action, a row of reveal cards (one per pet
-- rolled), the big full-screen reveal for rare pets and big sizes, the luck
-- chip, and auto roll (an upgrade).
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local Ui = require(script.Parent.Ui)
local Screen = require(script.Parent.Screen)
local State = require(script.Parent.State)
local Effects = require(script.Parent.Effects)

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

local function refreshLuck()
	local data = State.Data
	if not data then
		return
	end
	local untilBonus = Config.BONUS_EVERY - data.Rolls % Config.BONUS_EVERY
	local nextIsBonus = untilBonus == 1
	local luck = Config.luck(data, nextIsBonus)
	luckText.Text = string.format("x%.2f LUCK", luck) .. "  ·  " .. (if nextIsBonus then "BONUS ROLL NEXT!" else "bonus in " .. untilBonus)
	luckText.TextColor3 = if nextIsBonus then Ui.GOLD else Ui.TEXT
	for _, d in ipairs(luckIcon:GetDescendants()) do
		if d:IsA("Frame") and d.BackgroundTransparency < 1 then
			d.BackgroundColor3 = if nextIsBonus then Ui.GOLD else Ui.SUCCESS
		end
	end
	luckChip.Edge.Color = if nextIsBonus then Ui.GOLD else Color3.new(1, 1, 1)
	luckChip.Edge.Transparency = if nextIsBonus then 0.2 else 0.82
end

-- Reveal cards (a row along the bottom middle) -------------------------------------------

local cardRow = Ui.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -18),
	Size = UDim2.fromOffset(700, 86),
	BackgroundTransparency = 1,
	Parent = gui,
}, {
	Ui.new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}),
})

local function makeCard(order)
	local card = Ui.glass({
		LayoutOrder = order,
		Size = UDim2.fromOffset(128, 86),
		Radius = 16,
		Parent = cardRow,
	})
	local swatch = Ui.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 8),
		Size = UDim2.fromOffset(26, 26),
		Parent = card,
	}, { Ui.corner(0.5) })
	local swatchStroke = Ui.stroke(Color3.new(1, 1, 1), 2)
	swatchStroke.Parent = swatch
	local name = Ui.new("TextLabel", {
		Position = UDim2.fromOffset(4, 38),
		Size = UDim2.new(1, -8, 0, 20),
		TextScaled = true,
		Parent = card,
	})
	local odds = Ui.new("TextLabel", {
		Position = UDim2.fromOffset(4, 60),
		Size = UDim2.new(1, -8, 0, 16),
		Font = Ui.FONT_MEDIUM,
		TextScaled = true,
		Parent = card,
	})
	return { Card = card, Swatch = swatch, SwatchStroke = swatchStroke, Name = name, Odds = odds, Scale = Ui.new("UIScale", { Parent = card }) }
end

local cards = {}
local function showOnCard(c, petName, sizeIndex)
	local pet = Config.PETS_BY_NAME[petName]
	local size = Config.SIZES[sizeIndex]
	local rarity = Config.rarity(pet.Odds)
	c.Swatch.BackgroundColor3 = pet.Color
	c.SwatchStroke.Color = if sizeIndex > 1 then size.Color else rarity.Color
	c.SwatchStroke.Thickness = 2 + (sizeIndex - 1) * 2
	c.Name.Text = Config.petName(pet.Name, sizeIndex)
	c.Name.TextColor3 = if sizeIndex > 1 then size.Color else Ui.TEXT
	c.Odds.Text = rarity.Name:upper() .. " · " .. Config.formatOdds(pet.Odds)
	c.Odds.TextColor3 = rarity.Color
	c.Card.Edge.Color = rarity.Color
	c.Card.Edge.Transparency = 0.15
end

local hideAt = 0
local function showCards(results, spin)
	for i = #cards + 1, #results do
		cards[i] = makeCard(i)
	end
	for i, c in ipairs(cards) do
		c.Card.Visible = i <= #results
	end
	if spin then
		-- random names flicker past before the real results land
		for step = 1, 8 do
			for i = 1, #results do
				showOnCard(cards[i], Config.PETS[math.random(1, math.min(#Config.PETS, 4 + step))].Name, 1)
				cards[i].Scale.Scale = 0.95
				TweenService:Create(cards[i].Scale, TweenInfo.new(0.05), { Scale = 1 }):Play()
			end
			Effects.play("Roll", 1 + step * 0.05, 0.03)
			task.wait(0.03 + step * 0.012)
		end
	end
	for i, result in ipairs(results) do
		showOnCard(cards[i], result.Pet, result.Size)
		cards[i].Scale.Scale = 1.2
		TweenService:Create(cards[i].Scale, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	end
	hideAt = os.clock() + 4
	task.delay(4.1, function()
		if os.clock() >= hideAt then
			for _, c in ipairs(cards) do
				c.Card.Visible = false
			end
		end
	end)
end

-- Big reveal ----------------------------------------------------------------------------

local flash = Ui.new("Frame", {
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.new(1, 1, 1),
	BackgroundTransparency = 1,
	Visible = false,
	ZIndex = 40,
	Parent = gui,
})
local flashGlow = Ui.new("UIGradient", { Rotation = 90, Parent = flash })
local rays = Ui.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.45),
	Size = UDim2.fromOffset(900, 900),
	BackgroundTransparency = 1,
	ZIndex = 40,
	Parent = flash,
})
for k = 0, 11 do
	Ui.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0, 60, 1, 0),
		Rotation = k * 15,
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.88,
		ZIndex = 40,
		Parent = rays,
	})
end
local bigSize = Ui.new("TextLabel", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.33),
	Size = UDim2.fromOffset(700, 40),
	TextScaled = false,
	TextSize = 34,
	ZIndex = 41,
	Parent = flash,
})
local bigName = Ui.new("TextLabel", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.44),
	Size = UDim2.fromOffset(900, 100),
	TextScaled = false,
	TextSize = 84,
	TextStrokeTransparency = 0.5,
	TextStrokeColor3 = Color3.fromRGB(20, 20, 40),
	ZIndex = 41,
	Parent = flash,
})
local bigOdds = Ui.new("TextLabel", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.55),
	Size = UDim2.fromOffset(700, 40),
	Font = Ui.FONT_MEDIUM,
	TextScaled = false,
	TextSize = 30,
	ZIndex = 41,
	Parent = flash,
})
local bigScale = Ui.new("UIScale", { Parent = flash })
local rainbow = nil

-- How impressive a result is: 0 = normal card only, higher = bigger show
local function excitement(result)
	local pet = Config.PETS_BY_NAME[result.Pet]
	local level = 0
	if pet.Odds >= Config.BIG_ROLL then
		level = 1 + math.floor(math.log10(pet.Odds / Config.BIG_ROLL))
	end
	return level + (result.Size - 1) * 2
end

function Roll.bigReveal(petName, sizeIndex)
	local pet = Config.PETS_BY_NAME[petName]
	local size = Config.SIZES[sizeIndex]
	local rarity = Config.rarity(pet.Odds)
	local glow = if sizeIndex > 1 then size.Color else rarity.Color
	flashGlow.Color = ColorSequence.new(Color3.fromRGB(10, 10, 25), glow:Lerp(Color3.new(0, 0, 0), 0.35))
	flash.BackgroundTransparency = 0
	flash.Visible = true
	bigSize.Text = if sizeIndex > 1 then size.Name:upper() .. "!" else rarity.Name:upper()
	bigSize.TextColor3 = glow
	bigName.Text = pet.Name
	bigName.TextColor3 = Color3.new(1, 1, 1)
	bigOdds.Text = Config.formatOdds(pet.Odds) .. (if sizeIndex > 1 then "  ·  " .. size.Name .. " " .. Config.formatOdds(size.Chance) else "")
	bigOdds.TextColor3 = rarity.Color
	bigScale.Scale = 0.5
	TweenService:Create(flash, TweenInfo.new(0.4), { BackgroundTransparency = 0.12 }):Play()
	TweenService:Create(bigScale, TweenInfo.new(0.5, Enum.EasingStyle.Back), { Scale = 1 }):Play()

	-- the bigger the moment, the more happens
	local level = excitement({ Pet = petName, Size = sizeIndex })
	Effects.jingle(math.clamp(2 + level, 3, 7))
	if sizeIndex >= 2 or level >= 3 then
		Effects.confetti(30 + level * 15)
	end
	if sizeIndex >= 3 then
		-- titanic: the name cycles through the rainbow
		rainbow = RunService.RenderStepped:Connect(function()
			bigName.TextColor3 = Color3.fromHSV((os.clock() * 0.5) % 1, 0.55, 1)
			bigSize.TextColor3 = bigName.TextColor3
		end)
	end
	local spin = RunService.RenderStepped:Connect(function(dt)
		rays.Rotation += dt * 20
	end)
	task.wait(math.clamp(1.6 + level * 0.5, 1.6, 5))
	TweenService:Create(flash, TweenInfo.new(0.35), { BackgroundTransparency = 1 }):Play()
	TweenService:Create(bigScale, TweenInfo.new(0.35), { Scale = 0.8 }):Play()
	task.wait(0.35)
	spin:Disconnect()
	if rainbow then
		rainbow:Disconnect()
		rainbow = nil
	end
	flash.Visible = false
end

-- Rolling --------------------------------------------------------------------------------

local function setRollLabel(text)
	if rollButton then
		rollButton.Parent.Caption.Text = text
	end
end

function Roll.roll()
	local data = State.Data
	if rolling or not data then
		return
	end
	rolling = true
	setRollLabel("Rolling")
	local started = os.clock()
	local ok, results = pcall(rollFunction.InvokeServer, rollFunction)
	if ok and type(results) == "table" and #results > 0 then
		local quick = not State.Settings.Reveals or Config.upgradeLevel(data, "AutoHatch") >= 2
		showCards(results, not quick)
		for _, result in ipairs(results) do
			if result.First then
				Screen.toast("New pet: " .. result.Name .. "!", "success")
			end
		end
		-- the most exciting result gets the big reveal
		local best, bestLevel = nil, 0
		for _, result in ipairs(results) do
			local level = excitement(result)
			if level > bestLevel then
				best, bestLevel = result, level
			end
		end
		if best then
			Roll.bigReveal(best.Pet, best.Size)
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

State.watch(function()
	refreshLuck()
	refreshAuto()
end)

return Roll
