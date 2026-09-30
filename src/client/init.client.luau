-- Client entry point: coins and rolls, the Roll button (bottom middle), the
-- reveal, auto roll, the pets panel, the Most Rolls leaderboard, rebirths,
-- the fusion machine screen, coin pops and toast messages.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Ui = require(script.Ui)
local Pets = require(script.Pets)
require(script.Motion)

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local stateEvent = remotes:WaitForChild("State")
local rollFunction = remotes:WaitForChild("Roll")
local equipFunction = remotes:WaitForChild("Equip")
local leaderboardEvent = remotes:WaitForChild("Leaderboard")
local notifyEvent = remotes:WaitForChild("Notify")
local coinEvent = remotes:WaitForChild("CoinPop")
local rebirthFunction = remotes:WaitForChild("Rebirth")
local fusionOpenEvent = remotes:WaitForChild("FusionOpen")
local fuseStartFunction = remotes:WaitForChild("FuseStart")
local fuseCollectFunction = remotes:WaitForChild("FuseCollect")

local state = nil -- latest data from the server
local clockOffset = 0 -- server os.time() minus ours, for the fusion timer
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
	Size = UDim2.fromOffset(340, 96),
	Radius = 22,
	Parent = gui,
})
-- coins: a drawn gold coin and the amount
local coinRow = Ui.new("Frame", {
	Position = UDim2.fromOffset(0, 10),
	Size = UDim2.new(1, 0, 0, 36),
	BackgroundTransparency = 1,
	Parent = statsBox,
}, {
	Ui.new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}),
})
local coinIcon = Ui.new("Frame", {
	LayoutOrder = 0,
	Size = UDim2.fromOffset(26, 26),
	BackgroundColor3 = Ui.GOLD,
	Parent = coinRow,
}, { Ui.corner(0.5), Ui.stroke(Color3.fromRGB(255, 240, 180), 2, 0.2) })
Ui.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromScale(0.5, 0.5),
	BackgroundTransparency = 1,
	Parent = coinIcon,
}, { Ui.corner(0.5), Ui.stroke(Color3.fromRGB(200, 140, 30), 2) })
local coinsText = Ui.new("TextLabel", {
	LayoutOrder = 1,
	AutomaticSize = Enum.AutomaticSize.X,
	Size = UDim2.fromOffset(0, 32),
	TextScaled = false,
	TextSize = 30,
	Text = "0",
	TextColor3 = Ui.GOLD,
	Parent = coinRow,
})
local rollsText = Ui.new("TextLabel", {
	Position = UDim2.fromOffset(0, 52),
	Size = UDim2.new(1, 0, 0, 16),
	Font = Ui.FONT_MEDIUM,
	TextScaled = false,
	TextSize = 15,
	Text = "0 ROLLS",
	Parent = statsBox,
})
local bestText = Ui.new("TextLabel", {
	Position = UDim2.fromOffset(0, 72),
	Size = UDim2.new(1, 0, 0, 14),
	Font = Ui.FONT_MEDIUM,
	TextScaled = false,
	TextSize = 13,
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

-- displayName is set for huge pets ("Huge Tiger")
local function bigReveal(pet, displayName)
	local rarity = Config.rarity(pet.Odds)
	flashGlow.Color = ColorSequence.new(Color3.new(0, 0, 0), rarity.Color:Lerp(Color3.new(0, 0, 0), 0.4))
	flash.BackgroundColor3 = Color3.new(1, 1, 1)
	flash.BackgroundTransparency = 0
	flash.Visible = true
	bigRarity.Text = (if displayName then "HUGE  ·  " else "") .. rarity.Name:upper()
	bigRarity.TextColor3 = if displayName then Ui.GOLD else rarity.Color
	bigName.Text = displayName or pet.Name
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

local petCells = {} -- [pet name or "Huge " .. name] = { Frame, Name, Count, Stats, Equip }
for _, huge in ipairs({ false, true }) do
	for _, pet in ipairs(Config.PETS) do
		local name = if huge then Config.HUGE_PREFIX .. pet.Name else pet.Name
		local rarity = Config.rarity(pet.Odds)
		local frame = Ui.new("Frame", {
			LayoutOrder = if huge then -1000 - pet.Index else -pet.Index, -- huges first, then rarest first
			BackgroundColor3 = Ui.GLASS_LIGHT,
			BackgroundTransparency = 0.3,
			Visible = not huge, -- huge cells only show once you own one
			ZIndex = 32,
			Parent = petsGrid,
		}, { Ui.corner(16), Ui.padding(10), Ui.stroke(if huge then Ui.GOLD else rarity.Color, if huge then 2.5 else 1.5, if huge then 0.1 else 0.45) })
		-- rarity colour strip along the top
		Ui.new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, -4),
			Size = UDim2.new(0.4, 0, 0, 3),
			BackgroundColor3 = if huge then Ui.GOLD else rarity.Color,
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
		local nameLabel = line(6, if huge then 16 else 19, Ui.FONT, "", Ui.TEXT)
		line(32, 12, Ui.FONT, (if huge then "HUGE  ·  " else "") .. rarity.Name:upper(), if huge then Ui.GOLD else rarity.Color)
		line(50, 13, Ui.FONT_MEDIUM, Config.formatOdds(pet.Odds), Ui.MUTED)
		local countLabel = line(70, 13, Ui.FONT_MEDIUM, "", Ui.MUTED)
		local luck = Config.petLuck(pet) * (if huge then 2 else 1)
		local statsLabel = line(90, 12, Ui.FONT_MEDIUM,
			Config.formatNumber(Config.petPower(name)) .. " POWER  ·  +" .. math.floor(luck * 100 + 0.5) .. "% LUCK",
			Ui.SUCCESS)
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
			equipFunction:InvokeServer(name)
		end, "success")
		petCells[name] = { Frame = frame, Name = nameLabel, Count = countLabel, Stats = statsLabel, Equip = equip }
	end
end

local function refreshPets()
	if not state then
		return
	end
	local found = 0
	for _, huge in ipairs({ false, true }) do
		for _, pet in ipairs(Config.PETS) do
			local name = if huge then Config.HUGE_PREFIX .. pet.Name else pet.Name
			local cell = petCells[name]
			local owned = (if huge then state.Huges[pet.Name] else state.Pets[pet.Name]) or 0
			local everFound = huge or state.Pets[pet.Name] ~= nil -- 0 left after fusing still counts as found
			local equipped = table.find(state.Equipped, name) ~= nil
			if huge then
				cell.Frame.Visible = owned > 0
			elseif everFound then
				found += 1
			end
			if everFound then
				cell.Name.Text = name
				cell.Name.TextColor3 = if huge then Ui.GOLD else Ui.TEXT
				cell.Count.Text = if huge then "OWNED x" .. owned else "ROLLED x" .. Config.formatNumber(owned)
				cell.Stats.Visible = true
				cell.Equip.Visible = owned > 0
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
				cell.Stats.Visible = false
				cell.Equip.Visible = false
			end
		end
	end
	petsTitle.Text = "Pets  ·  " .. found .. "/" .. #Config.PETS
	equipHint.Text = "Equipped " .. #state.Equipped .. "/" .. Config.MAX_EQUIPPED .. "  ·  pets hit breakables and add luck"
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

sideButton(-68, "PETS", "grid", function()
	refreshPets()
	Ui.popIn(petsModal)
end)
local boardButton = sideButton(0, "TOP", "podium", function()
	Ui.popIn(boardModal)
end)
local rebirthModal -- built below
local refreshRebirth
sideButton(68, "REBIRTH", "loop", function()
	refreshRebirth()
	Ui.popIn(rebirthModal)
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

-- Toasts ------------------------------------------------------------------------------

local toast = Ui.glass({
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 124),
	Size = UDim2.fromOffset(0, 40),
	AutomaticSize = Enum.AutomaticSize.X,
	Radius = 20,
	Visible = false,
	ZIndex = 25,
	Parent = gui,
}, { Ui.new("UIPadding", { PaddingLeft = UDim.new(0, 22), PaddingRight = UDim.new(0, 22) }) })
local toastText = Ui.new("TextLabel", {
	AutomaticSize = Enum.AutomaticSize.X,
	Size = UDim2.fromOffset(0, 40),
	TextScaled = false,
	TextSize = 17,
	ZIndex = 26,
	Parent = toast,
})
local toastId = 0
local TOAST_COLORS = { danger = Ui.DANGER, success = Ui.SUCCESS }

local function showToast(text, style)
	toastId += 1
	local id = toastId
	toastText.Text = text
	toast.Edge.Color = TOAST_COLORS[style] or Ui.ACCENT
	toast.Edge.Transparency = 0.1
	Ui.popIn(toast)
	task.delay(2.5, function()
		if toastId == id then
			toast.Visible = false
		end
	end)
end
notifyEvent.OnClientEvent:Connect(showToast)

-- Coins popping out of broken things ---------------------------------------------------

local coinScale = Ui.new("UIScale", { Parent = coinRow })

coinEvent.OnClientEvent:Connect(function(position, coins)
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.Transparency = 1
	anchor.Size = Vector3.one
	anchor.CFrame = CFrame.new(position)
	anchor.Parent = workspace
	local billboard = Ui.new("BillboardGui", {
		Size = UDim2.fromOffset(160, 40),
		AlwaysOnTop = true,
		Adornee = anchor,
		Parent = anchor,
	})
	local label = Ui.new("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		TextScaled = false,
		TextSize = 26,
		Text = "+" .. Config.formatNumber(coins),
		TextColor3 = Ui.GOLD,
		TextStrokeColor3 = Color3.fromRGB(90, 55, 0),
		TextStrokeTransparency = 0.2,
		Parent = billboard,
	})
	TweenService:Create(billboard, TweenInfo.new(1, Enum.EasingStyle.Quad), { StudsOffsetWorldSpace = Vector3.new(0, 5, 0) }):Play()
	TweenService:Create(label, TweenInfo.new(1, Enum.EasingStyle.Quad), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	task.delay(1, function()
		anchor:Destroy()
	end)
	-- the coin counter punches
	coinScale.Scale = 1.15
	TweenService:Create(coinScale, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Scale = 1 }):Play()
end)

-- Rebirth ------------------------------------------------------------------------------

local rebirthBox
rebirthModal, rebirthBox = modal(460, 330)
title(rebirthBox, "Rebirth")
subtitle(rebirthBox, "Reset your coins and areas. You keep all your pets.")
local rebirthBonus = Ui.new("TextLabel", {
	Position = UDim2.fromOffset(0, 84),
	Size = UDim2.new(1, 0, 0, 40),
	TextScaled = false,
	TextSize = 34,
	TextColor3 = Ui.GOLD,
	ZIndex = 32,
	Parent = rebirthBox,
})
Ui.new("TextLabel", {
	Position = UDim2.fromOffset(0, 128),
	Size = UDim2.new(1, 0, 0, 18),
	Font = Ui.FONT_MEDIUM,
	TextScaled = false,
	TextSize = 15,
	Text = "COINS FROM EVERYTHING, FOREVER",
	TextColor3 = Ui.MUTED,
	ZIndex = 32,
	Parent = rebirthBox,
})
local rebirthCost = Ui.new("TextLabel", {
	Position = UDim2.fromOffset(0, 162),
	Size = UDim2.new(1, 0, 0, 20),
	TextScaled = false,
	TextSize = 17,
	ZIndex = 32,
	Parent = rebirthBox,
})
local rebirthButton = Ui.button({
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, 0),
	Size = UDim2.new(1, 0, 0, 60),
	Radius = 20,
	Text = "REBIRTH",
	Icon = "loop",
	TextSize = 22,
	ZIndex = 33,
	Parent = rebirthBox,
}, function()
	if rebirthFunction:InvokeServer() then
		rebirthModal.Visible = false
	end
end, "primary")

function refreshRebirth()
	if not state then
		return
	end
	local cost = Config.rebirthCost(state.Rebirths)
	rebirthBonus.Text = "x" .. Config.coinMultiplier(state.Rebirths) .. "  →  x" .. Config.coinMultiplier(state.Rebirths + 1)
	rebirthCost.Text = if cost == 0
		then "FREE (TESTING)"
		else "COSTS " .. Config.formatNumber(cost) .. " COINS  ·  YOU HAVE " .. Config.formatNumber(state.Coins)
	rebirthCost.TextColor3 = if state.Coins >= cost then Ui.SUCCESS else Ui.MUTED
	Ui.setStyle(rebirthButton, if state.Coins >= cost then "primary" else "disabled")
end

-- Fusion machine -----------------------------------------------------------------------

local fusionModal, fusionBox = modal(560, 520)
title(fusionBox, "Pet Fusion")
subtitle(fusionBox, "Put in " .. Config.FUSE_COPIES .. " of the same pet, get a HUGE one with 10x power")

-- shown while the machine is working
local fusingCard = Ui.new("Frame", {
	Position = UDim2.fromOffset(0, 76),
	Size = UDim2.new(1, 0, 0, 190),
	BackgroundColor3 = Ui.GLASS_LIGHT,
	BackgroundTransparency = 0.3,
	Visible = false,
	ZIndex = 32,
	Parent = fusionBox,
}, { Ui.corner(18), Ui.padding(18) })
local fusingName = Ui.new("TextLabel", {
	Size = UDim2.new(1, 0, 0, 30),
	TextScaled = false,
	TextSize = 26,
	TextColor3 = Ui.GOLD,
	ZIndex = 33,
	Parent = fusingCard,
})
local fusingTimer = Ui.new("TextLabel", {
	Position = UDim2.fromOffset(0, 40),
	Size = UDim2.new(1, 0, 0, 22),
	Font = Ui.FONT_MEDIUM,
	TextScaled = false,
	TextSize = 18,
	TextColor3 = Ui.MUTED,
	ZIndex = 33,
	Parent = fusingCard,
})
local fusingBarBack = Ui.new("Frame", {
	Position = UDim2.fromOffset(0, 74),
	Size = UDim2.new(1, 0, 0, 12),
	BackgroundColor3 = Ui.GLASS,
	ZIndex = 33,
	Parent = fusingCard,
}, { Ui.corner(0.5) })
local fusingBar = Ui.new("Frame", {
	Size = UDim2.fromScale(0, 1),
	BackgroundColor3 = Color3.new(1, 1, 1),
	ZIndex = 34,
	Parent = fusingBarBack,
}, { Ui.corner(0.5), Ui.new("UIGradient", { Color = ColorSequence.new(Ui.PRIMARY_A, Ui.PRIMARY_B) }) })
local collectButton = Ui.button({
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, 0),
	Size = UDim2.new(1, 0, 0, 52),
	Radius = 18,
	Text = "COLLECT",
	TextSize = 20,
	ZIndex = 34,
	Parent = fusingCard,
}, function()
	local huge = fuseCollectFunction:InvokeServer()
	if huge then
		showToast(huge .. " is yours!", "success")
		local pet = Config.petInfo(huge)
		fusionModal.Visible = false
		task.spawn(bigReveal, pet, huge)
	end
end, "disabled")

-- shown when the machine is free: pets you have enough copies of
local fuseList = scrollList(fusionBox, 76, Ui.new("UIListLayout", {
	Padding = UDim.new(0, 8),
	SortOrder = Enum.SortOrder.LayoutOrder,
}))
local fuseEmpty = Ui.new("TextLabel", {
	Position = UDim2.fromOffset(0, 120),
	Size = UDim2.new(1, 0, 0, 20),
	Font = Ui.FONT_MEDIUM,
	TextScaled = false,
	TextSize = 16,
	Text = "Roll " .. Config.FUSE_COPIES .. " of the same pet to fuse it",
	TextColor3 = Ui.MUTED,
	ZIndex = 33,
	Parent = fusionBox,
})

local function refreshFusion()
	if not state then
		return
	end
	local fusion = state.Fusion
	fusingCard.Visible = fusion ~= nil
	fuseList.Visible = fusion == nil
	if fusion then
		fuseEmpty.Visible = false
		local pet = Config.PETS_BY_NAME[fusion.Pet]
		local total = Config.fuseTime(pet)
		local left = math.max(fusion.Ends - (os.time() + clockOffset), 0)
		fusingName.Text = "HUGE " .. fusion.Pet:upper()
		fusingTimer.Text = if left > 0 then string.format("Ready in %d:%02d", left // 60, left % 60) else "Ready!"
		fusingBar.Size = UDim2.fromScale(1 - left / total, 1)
		Ui.setStyle(collectButton, if left > 0 then "disabled" else "primary")
		return
	end

	for _, child in ipairs(fuseList:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	local count = 0
	for _, pet in ipairs(Config.PETS) do
		local owned = state.Pets[pet.Name] or 0
		if owned >= Config.FUSE_COPIES then
			count += 1
			local row = Ui.new("Frame", {
				LayoutOrder = -pet.Index,
				Size = UDim2.new(1, 0, 0, 58),
				BackgroundColor3 = Ui.GLASS_LIGHT,
				BackgroundTransparency = 0.35,
				ZIndex = 32,
				Parent = fuseList,
			}, { Ui.corner(14), Ui.stroke(Config.rarity(pet.Odds).Color, 1.5, 0.5) })
			Ui.new("TextLabel", {
				Position = UDim2.fromOffset(16, 8),
				Size = UDim2.new(1, -170, 0, 22),
				TextScaled = false,
				TextSize = 19,
				Text = pet.Name,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 33,
				Parent = row,
			})
			local seconds = Config.fuseTime(pet)
			Ui.new("TextLabel", {
				Position = UDim2.fromOffset(16, 32),
				Size = UDim2.new(1, -170, 0, 16),
				Font = Ui.FONT_MEDIUM,
				TextScaled = false,
				TextSize = 13,
				Text = "x" .. owned .. " owned  ·  " .. string.format("%d:%02d", seconds // 60, seconds % 60) .. "  ·  "
					.. Config.formatNumber(Config.petPower(Config.HUGE_PREFIX .. pet.Name)) .. " power",
				TextColor3 = Ui.MUTED,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 33,
				Parent = row,
			})
			Ui.button({
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -10, 0.5, 0),
				Size = UDim2.fromOffset(130, 40),
				Radius = 14,
				Text = "FUSE " .. Config.FUSE_COPIES,
				TextSize = 15,
				ZIndex = 34,
				Parent = row,
			}, function()
				fuseStartFunction:InvokeServer(pet.Name)
			end, "primary")
		end
	end
	fuseEmpty.Visible = count == 0
end

fusionOpenEvent.OnClientEvent:Connect(function()
	refreshFusion()
	Ui.popIn(fusionModal)
end)

-- keep the timer ticking while the screen is open
task.spawn(function()
	while true do
		task.wait(0.5)
		if fusionModal.Visible and state and state.Fusion then
			refreshFusion()
		end
	end
end)

-- Updates ------------------------------------------------------------------------

stateEvent.OnClientEvent:Connect(function(newState)
	state = newState
	clockOffset = state.ServerTime - os.time()
	coinsText.Text = Config.formatNumber(state.Coins)
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
	if rebirthModal.Visible then
		refreshRebirth()
	end
	if fusionModal.Visible then
		refreshFusion()
	end
end)
