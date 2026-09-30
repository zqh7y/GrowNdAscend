-- Client entry point: the Roll button (bottom middle), the reveal, auto roll,
-- the pets panel and the Most Rolls leaderboard.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Ui = require(script.Ui)
local Pets = require(script.Pets)

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local stateEvent = remotes:WaitForChild("State")
local rollFunction = remotes:WaitForChild("Roll")
local equipFunction = remotes:WaitForChild("Equip")
local leaderboardEvent = remotes:WaitForChild("Leaderboard")

local state = nil -- latest data from the server
local rolling = false
local autoRoll = false

local function commas(n)
	local digits = tostring(math.floor(n))
	return (digits:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", ""))
end

-- Screen -----------------------------------------------------------------------

local gui = Ui.new("ScreenGui", {
	Name = "RollGui",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = player:WaitForChild("PlayerGui"),
})
local uiScale = Ui.new("UIScale", { Parent = gui })
local function fitScreen()
	local size = Workspace.CurrentCamera.ViewportSize
	uiScale.Scale = math.clamp(math.min(size.X / 1280, size.Y / 760), 0.55, 1.2)
end
fitScreen()
Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fitScreen)

-- Stats (top middle) ---------------------------------------------------------------

local statsBox = Ui.glass({
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 16),
	Size = UDim2.fromOffset(340, 72),
	Radius = 22,
	Parent = gui,
})
local rollsText = Ui.new("TextLabel", {
	Position = UDim2.fromOffset(0, 10),
	Size = UDim2.new(1, 0, 0, 30),
	TextScaled = false,
	TextSize = 28,
	Text = "0 ROLLS",
	Parent = statsBox,
})
local bestText = Ui.new("TextLabel", {
	Position = UDim2.fromOffset(0, 44),
	Size = UDim2.new(1, 0, 0, 18),
	Font = Ui.FONT_MEDIUM,
	TextScaled = false,
	TextSize = 15,
	Text = "BEST  ·  nothing yet",
	TextColor3 = Ui.MUTED,
	Parent = statsBox,
})

-- Reveal card (above the roll button) ----------------------------------------------

local card = Ui.glass({
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -178),
	Size = UDim2.fromOffset(320, 96),
	Radius = 20,
	Visible = false,
	Parent = gui,
})
local cardEdge = card.Edge
local cardName = Ui.new("TextLabel", {
	Position = UDim2.fromOffset(0, 16),
	Size = UDim2.new(1, 0, 0, 36),
	TextScaled = false,
	TextSize = 32,
	Text = "",
	Parent = card,
})
local cardOdds = Ui.new("TextLabel", {
	Position = UDim2.fromOffset(0, 58),
	Size = UDim2.new(1, 0, 0, 20),
	Font = Ui.FONT_MEDIUM,
	TextScaled = false,
	TextSize = 16,
	Text = "",
	Parent = card,
})
local cardScale = Ui.new("UIScale", { Parent = card })

local function showOnCard(pet)
	local rarity = Config.rarity(pet.Odds)
	cardName.Text = pet.Name
	cardOdds.Text = rarity.Name:upper() .. "  ·  " .. Config.formatOdds(pet.Odds)
	cardOdds.TextColor3 = rarity.Color
	cardEdge.Color = rarity.Color
	cardEdge.Transparency = 0.1
end

-- Big reveal for rare rolls (full screen) -------------------------------------------

local flash = Ui.new("Frame", {
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.new(0, 0, 0),
	BackgroundTransparency = 1,
	Visible = false,
	ZIndex = 40,
	Parent = gui,
})
local flashGlow = Ui.new("UIGradient", { Rotation = 90, Parent = flash })
local bigRarity = Ui.new("TextLabel", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.36),
	Size = UDim2.fromOffset(700, 30),
	Font = Ui.FONT_MEDIUM,
	TextScaled = false,
	TextSize = 26,
	ZIndex = 41,
	Parent = flash,
})
local bigName = Ui.new("TextLabel", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.46),
	Size = UDim2.fromOffset(900, 100),
	TextScaled = false,
	TextSize = 88,
	ZIndex = 41,
	Parent = flash,
})
local bigOdds = Ui.new("TextLabel", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.56),
	Size = UDim2.fromOffset(700, 40),
	Font = Ui.FONT_MEDIUM,
	TextScaled = false,
	TextSize = 32,
	TextColor3 = Ui.TEXT,
	ZIndex = 41,
	Parent = flash,
})
local bigScale = Ui.new("UIScale", { Parent = flash })

local function bigReveal(pet)
	local rarity = Config.rarity(pet.Odds)
	flashGlow.Color = ColorSequence.new(Color3.new(0, 0, 0), rarity.Color:Lerp(Color3.new(0, 0, 0), 0.4))
	flash.BackgroundColor3 = Color3.new(1, 1, 1)
	flash.BackgroundTransparency = 0
	flash.Visible = true
	bigRarity.Text = rarity.Name:upper()
	bigRarity.TextColor3 = rarity.Color
	bigName.Text = pet.Name
	bigName.TextColor3 = Color3.new(1, 1, 1)
	bigOdds.Text = Config.formatOdds(pet.Odds)
	bigScale.Scale = 0.6
	TweenService:Create(flash, TweenInfo.new(0.5), { BackgroundTransparency = 0.15 }):Play()
	TweenService:Create(bigScale, TweenInfo.new(0.5, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	-- rarer rolls stay on screen longer
	task.wait(math.clamp(math.log10(pet.Odds) - 1.5, 1.5, 4))
	TweenService:Create(flash, TweenInfo.new(0.35), { BackgroundTransparency = 1 }):Play()
	TweenService:Create(bigScale, TweenInfo.new(0.35), { Scale = 0.8 }):Play()
	task.wait(0.35)
	flash.Visible = false
end

-- Luck chip, Roll button, Auto (bottom middle) ----------------------------------------

local luckChip = Ui.glass({
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -132),
	Size = UDim2.fromOffset(300, 34),
	Radius = 17,
	Parent = gui,
}, {
	Ui.new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 8),
	}),
})
local luckIcon = Ui.icon("spark", 14, Ui.SUCCESS, { LayoutOrder = 0, Parent = luckChip })
local luckText = Ui.new("TextLabel", {
	LayoutOrder = 1,
	AutomaticSize = Enum.AutomaticSize.X,
	Size = UDim2.fromOffset(0, 18),
	Font = Ui.FONT_MEDIUM,
	TextScaled = false,
	TextSize = 15,
	Text = "",
	Parent = luckChip,
})

local rollButton, autoButton

local function setLuckColor(color)
	for _, d in ipairs(luckIcon:GetDescendants()) do
		if d:IsA("Frame") and d.BackgroundTransparency < 1 then
			d.BackgroundColor3 = color
		end
	end
	luckChip.Edge.Color = color
end

local function refreshLuck()
	if not state then
		return
	end
	local untilBonus = Config.BONUS_EVERY - state.Rolls % Config.BONUS_EVERY
	local nextIsBonus = untilBonus == 1
	local luck = Config.luck(state.Equipped, nextIsBonus)
	luckText.Text = "LUCK x" .. string.format("%.2f", luck) .. "   ·   "
		.. (if nextIsBonus then "BONUS ROLL NEXT" else "BONUS IN " .. untilBonus)
	luckText.TextColor3 = if nextIsBonus then Ui.GOLD else Ui.TEXT
	setLuckColor(if nextIsBonus then Ui.GOLD else Ui.SUCCESS)
	luckChip.Edge.Transparency = if nextIsBonus then 0.2 else 0.82
end

-- random names flicker past before the real result lands
local function spinTo(pet)
	card.Visible = true
	local steps = 9
	for i = 1, steps do
		-- mostly common pets flash by, like a real roll
		showOnCard(Config.PETS[math.random(1, math.min(#Config.PETS, 4 + i))])
		cardScale.Scale = 0.96
		TweenService:Create(cardScale, TweenInfo.new(0.05), { Scale = 1 }):Play()
		task.wait(0.03 + i * 0.012)
	end
	showOnCard(pet)
	cardScale.Scale = 1.15
	TweenService:Create(cardScale, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Scale = 1 }):Play()
end

local function floatText(text, color)
	local label = Ui.new("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 1, -300),
		Size = UDim2.fromOffset(420, 28),
		TextScaled = false,
		TextSize = 22,
		Text = text,
		TextColor3 = color,
		TextStrokeColor3 = Color3.fromRGB(10, 10, 25),
		TextStrokeTransparency = 0.4,
		ZIndex = 20,
		Parent = gui,
	})
	TweenService:Create(label, TweenInfo.new(1.4, Enum.EasingStyle.Quad), {
		Position = label.Position - UDim2.fromOffset(0, 80),
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	}):Play()
	task.delay(1.4, function()
		label:Destroy()
	end)
end

local function doRoll()
	if rolling or not state then
		return
	end
	rolling = true
	Ui.setText(rollButton, "ROLLING")
	local started = os.clock()
	local ok, result = pcall(rollFunction.InvokeServer, rollFunction)
	if ok and result then
		local pet = Config.PETS_BY_NAME[result.Pet]
		spinTo(pet)
		if result.Bonus then
			floatText("BONUS ROLL  ·  " .. Config.BONUS_LUCK .. "x LUCK", Ui.GOLD)
		end
		if result.First then
			floatText("NEW  ·  " .. pet.Name, Config.rarity(pet.Odds).Color)
		end
		if pet.Odds >= Config.BIG_ROLL then
			bigReveal(pet)
		end
	end
	-- wait out the cooldown
	local left = Config.ROLL_COOLDOWN - (os.clock() - started)
	if left > 0 then
		task.wait(left)
	end
	Ui.setText(rollButton, "ROLL")
	rolling = false
end

rollButton = Ui.button({
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -28),
	Size = UDim2.fromOffset(250, 88),
	Radius = 26,
	Text = "ROLL",
	Icon = "dice",
	TextSize = 32,
	Parent = gui,
}, function()
	task.spawn(doRoll)
end, "primary")

local function refreshAuto()
	if not state then
		return
	end
	-- style first so a new icon gets the style's colour
	if state.Rolls < Config.AUTO_ROLL_AT then
		Ui.setStyle(autoButton, "disabled")
		Ui.setIcon(autoButton, "lock")
		Ui.setText(autoButton, state.Rolls .. "/" .. Config.AUTO_ROLL_AT)
	else
		Ui.setStyle(autoButton, if autoRoll then "success" else "glass")
		Ui.setIcon(autoButton, "loop")
		Ui.setText(autoButton, if autoRoll then "AUTO ON" else "AUTO")
	end
end

autoButton = Ui.button({
	AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.new(0.5, 141, 1, -40),
	Size = UDim2.fromOffset(150, 64),
	Radius = 20,
	Text = "AUTO",
	Icon = "loop",
	TextSize = 18,
	Parent = gui,
}, function()
	if not state or state.Rolls < Config.AUTO_ROLL_AT then
		return
	end
	autoRoll = not autoRoll
	refreshAuto()
end, "glass")

task.spawn(function()
	while true do
		if autoRoll and not rolling then
			doRoll()
		else
			task.wait(0.1)
		end
	end
end)

-- Modals -------------------------------------------------------------------------

local function modal(width, height)
	local shade = Ui.new("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(5, 6, 15),
		BackgroundTransparency = 0.35,
		Text = "",
		AutoButtonColor = false,
		Visible = false,
		ZIndex = 30,
		Parent = gui,
	})
	local box = Ui.glass({
		Name = "Box",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(width, height),
		BackgroundTransparency = 0.06,
		Radius = 24,
		ZIndex = 31,
		Parent = shade,
	}, { Ui.padding(22) })
	Ui.button({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 0),
		Size = UDim2.fromOffset(40, 40),
		Radius = 20,
		Icon = "close",
		IconSize = 14,
		ZIndex = 33,
		Parent = box,
	}, function()
		shade.Visible = false
	end, "glass")
	return shade, box
end

local function title(box, text)
	return Ui.new("TextLabel", {
		Size = UDim2.new(1, -60, 0, 30),
		TextScaled = false,
		TextSize = 26,
		Text = text,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 32,
		Parent = box,
	})
end

local function subtitle(box, text)
	return Ui.new("TextLabel", {
		Position = UDim2.fromOffset(0, 36),
		Size = UDim2.new(1, -60, 0, 18),
		Font = Ui.FONT_MEDIUM,
		TextScaled = false,
		TextSize = 15,
		Text = text,
		TextColor3 = Ui.MUTED,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 32,
		Parent = box,
	})
end

local function scrollList(box, top, layout)
	return Ui.new("ScrollingFrame", {
		Position = UDim2.fromOffset(0, top),
		Size = UDim2.new(1, 0, 1, -top),
		BackgroundTransparency = 1,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = Ui.MUTED,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ZIndex = 32,
		Parent = box,
	}, { layout, Ui.new("UIPadding", { PaddingRight = UDim.new(0, 10), PaddingTop = UDim.new(0, 4) }) })
end

-- Pets panel: every pet in the game, owned ones can be equipped --------------------

local petsModal, petsBox = modal(720, 560)
local petsTitle = title(petsBox, "Pets")
local equipHint = subtitle(petsBox, "")
local petsGrid = scrollList(petsBox, 72, Ui.new("UIGridLayout", {
	CellSize = UDim2.fromOffset(154, 168),
	CellPadding = UDim2.fromOffset(12, 12),
	SortOrder = Enum.SortOrder.LayoutOrder,
}))

local petCells = {} -- [pet name] = { Name, Count, Luck, Equip }
for _, pet in ipairs(Config.PETS) do
	local rarity = Config.rarity(pet.Odds)
	local frame = Ui.new("Frame", {
		LayoutOrder = -pet.Index, -- rarest first
		BackgroundColor3 = Ui.GLASS_LIGHT,
		BackgroundTransparency = 0.3,
		ZIndex = 32,
		Parent = petsGrid,
	}, { Ui.corner(16), Ui.padding(10), Ui.stroke(rarity.Color, 1.5, 0.45) })
	-- rarity colour strip along the top
	Ui.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, -4),
		Size = UDim2.new(0.4, 0, 0, 3),
		BackgroundColor3 = rarity.Color,
		ZIndex = 33,
		Parent = frame,
	}, { Ui.corner(0.5) })
	local function line(y, size, font, text, color)
		return Ui.new("TextLabel", {
			Position = UDim2.fromOffset(0, y),
			Size = UDim2.new(1, 0, 0, size + 2),
			Font = font,
			TextScaled = false,
			TextSize = size,
			Text = text,
			TextColor3 = color,
			ZIndex = 33,
			Parent = frame,
		})
	end
	local nameLabel = line(6, 19, Ui.FONT, "", Ui.TEXT)
	line(32, 12, Ui.FONT, rarity.Name:upper(), rarity.Color)
	line(50, 13, Ui.FONT_MEDIUM, Config.formatOdds(pet.Odds), Ui.MUTED)
	local countLabel = line(70, 13, Ui.FONT_MEDIUM, "", Ui.MUTED)
	local luckLabel = line(90, 13, Ui.FONT_MEDIUM, "+" .. math.floor(Config.petLuck(pet) * 100 + 0.5) .. "% LUCK", Ui.SUCCESS)
	local equip = Ui.button({
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(1, 0, 0, 34),
		Radius = 12,
		Text = "EQUIP",
		TextSize = 14,
		ZIndex = 33,
		Parent = frame,
	}, function()
		equipFunction:InvokeServer(pet.Name)
	end, "success")
	petCells[pet.Name] = { Name = nameLabel, Count = countLabel, Luck = luckLabel, Equip = equip }
end

local function refreshPets()
	if not state then
		return
	end
	local found = 0
	for _, pet in ipairs(Config.PETS) do
		local cell = petCells[pet.Name]
		local owned = state.Pets[pet.Name] or 0
		local equipped = table.find(state.Equipped, pet.Name) ~= nil
		if owned > 0 then
			found += 1
			cell.Name.Text = pet.Name
			cell.Name.TextColor3 = Ui.TEXT
			cell.Count.Text = "ROLLED x" .. Config.formatNumber(owned)
			cell.Luck.Visible = true
			cell.Equip.Visible = true
			Ui.setText(cell.Equip, if equipped then "UNEQUIP" else "EQUIP")
			Ui.setStyle(cell.Equip, if equipped
				then "danger"
				elseif #state.Equipped >= Config.MAX_EQUIPPED then "disabled"
				else "success")
		else
			-- not found yet: show only the odds, as something to chase
			cell.Name.Text = "???"
			cell.Name.TextColor3 = Ui.MUTED
			cell.Count.Text = "NOT FOUND YET"
			cell.Luck.Visible = false
			cell.Equip.Visible = false
		end
	end
	petsTitle.Text = "Pets  ·  " .. found .. "/" .. #Config.PETS
	equipHint.Text = "Equipped " .. #state.Equipped .. "/" .. Config.MAX_EQUIPPED .. "  ·  rarer pets give more luck"
end

-- Leaderboard ----------------------------------------------------------------------

local boardModal, boardBox = modal(520, 600)
title(boardBox, "Top Rollers")
local myRankText = subtitle(boardBox, "")
local boardList = scrollList(boardBox, 72, Ui.new("UIListLayout", {
	Padding = UDim.new(0, 6),
	SortOrder = Enum.SortOrder.LayoutOrder,
}))

-- Side buttons (left) ------------------------------------------------------------

local function sideButton(y, text, icon, onClick)
	return Ui.button({
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 20, 0.5, y),
		Size = UDim2.fromOffset(170, 56),
		Radius = 18,
		Text = text,
		Icon = icon,
		TextSize = 18,
		Parent = gui,
	}, onClick, "glass")
end

sideButton(-36, "PETS", "grid", function()
	refreshPets()
	Ui.popIn(petsModal)
end)
local boardButton = sideButton(36, "TOP", "podium", function()
	Ui.popIn(boardModal)
end)

local MEDALS = { Ui.GOLD, Color3.fromRGB(200, 210, 225), Color3.fromRGB(225, 150, 95) }
leaderboardEvent.OnClientEvent:Connect(function(entries)
	for _, child in ipairs(boardList:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	local myRank
	for i, entry in ipairs(entries) do
		local mine = entry.UserId == player.UserId
		if mine then
			myRank = i
		end
		local row = Ui.new("Frame", {
			LayoutOrder = i,
			Size = UDim2.new(1, 0, 0, 46),
			BackgroundColor3 = Ui.GLASS_LIGHT,
			BackgroundTransparency = if mine then 0 else 0.4,
			ZIndex = 32,
			Parent = boardList,
		}, { Ui.corner(14) })
		if mine then
			Ui.stroke(Ui.PRIMARY_B, 1.5, 0.2).Parent = row
		end
		Ui.new("TextLabel", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 10, 0.5, 0),
			Size = UDim2.fromOffset(30, 30),
			BackgroundTransparency = if MEDALS[i] then 0 else 1,
			BackgroundColor3 = MEDALS[i] or Ui.GLASS,
			TextScaled = false,
			TextSize = 15,
			Text = tostring(i),
			TextColor3 = if MEDALS[i] then Color3.fromRGB(20, 20, 35) else Ui.MUTED,
			ZIndex = 33,
			Parent = row,
		}, { Ui.corner(0.5) })
		Ui.new("TextLabel", {
			Position = UDim2.fromOffset(54, 0),
			Size = UDim2.new(1, -200, 1, 0),
			Font = Ui.FONT_MEDIUM,
			TextScaled = false,
			TextSize = 17,
			Text = entry.Name,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 33,
			Parent = row,
		})
		Ui.new("TextLabel", {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -14, 0, 0),
			Size = UDim2.new(0, 140, 1, 0),
			TextScaled = false,
			TextSize = 17,
			Text = commas(entry.Rolls),
			TextColor3 = if mine then Ui.PRIMARY_A else Ui.TEXT,
			TextXAlignment = Enum.TextXAlignment.Right,
			ZIndex = 33,
			Parent = row,
		})
	end
	myRankText.Text = if myRank then "You're #" .. myRank .. " in the world" else "Keep rolling to get on the board"
	Ui.setText(boardButton, if myRank then "TOP  #" .. myRank else "TOP")
end)

-- Updates ------------------------------------------------------------------------

stateEvent.OnClientEvent:Connect(function(newState)
	state = newState
	rollsText.Text = commas(state.Rolls) .. (if state.Rolls == 1 then " ROLL" else " ROLLS")
	local best = state.Best and Config.PETS_BY_NAME[state.Best]
	if best then
		bestText.Text = "BEST  ·  " .. best.Name .. "  ·  " .. Config.formatOdds(best.Odds)
		bestText.TextColor3 = Config.rarity(best.Odds).Color
	end
	Pets.update(state.Equipped)
	refreshLuck()
	refreshAuto()
	if petsModal.Visible then
		refreshPets()
	end
end)
