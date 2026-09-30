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

-- Stats (top middle)
local statsBox = Ui.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 14),
	Size = UDim2.fromOffset(380, 84),
	BackgroundColor3 = Ui.DARK,
	BackgroundTransparency = 0.15,
	Parent = gui,
}, { Ui.corner(18), Ui.stroke(Ui.GOLD, 3) })
local rollsText = Ui.new("TextLabel", {
	Position = UDim2.fromOffset(12, 6),
	Size = UDim2.new(1, -24, 0, 44),
	Text = "🎲 0 Rolls",
	TextColor3 = Ui.GOLD,
	Parent = statsBox,
})
local bestText = Ui.new("TextLabel", {
	Position = UDim2.fromOffset(12, 52),
	Size = UDim2.new(1, -24, 0, 24),
	Text = "Best: nothing yet",
	TextColor3 = Ui.MUTED,
	Parent = statsBox,
})

-- Reveal card (above the roll button) ------------------------------------------

local card = Ui.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -170),
	Size = UDim2.fromOffset(340, 110),
	BackgroundColor3 = Ui.DARK,
	BackgroundTransparency = 0.1,
	Visible = false,
	Parent = gui,
}, { Ui.corner(18), Ui.padding(10) })
local cardStroke = Ui.stroke(Ui.GREY, 4)
cardStroke.Parent = card
local cardName = Ui.new("TextLabel", {
	Size = UDim2.new(1, 0, 0, 50),
	Text = "",
	Parent = card,
})
local cardOdds = Ui.new("TextLabel", {
	Position = UDim2.fromOffset(0, 54),
	Size = UDim2.new(1, 0, 0, 34),
	Text = "",
	Parent = card,
})
local cardScale = Ui.new("UIScale", { Parent = card })

local function showOnCard(pet)
	local rarity = Config.rarity(pet.Odds)
	cardName.Text = pet.Name
	cardName.TextColor3 = pet.Color:Lerp(Color3.new(1, 1, 1), 0.35)
	cardOdds.Text = rarity.Name .. " · " .. Config.formatOdds(pet.Odds)
	cardOdds.TextColor3 = rarity.Color
	cardStroke.Color = rarity.Color
end

-- Big reveal for rare rolls (full screen) ---------------------------------------

local flash = Ui.new("Frame", {
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.new(1, 1, 1),
	BackgroundTransparency = 1,
	Visible = false,
	ZIndex = 40,
	Parent = gui,
})
local bigName = Ui.new("TextLabel", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.42),
	Size = UDim2.fromOffset(900, 120),
	TextStrokeTransparency = 0,
	ZIndex = 41,
	Parent = flash,
})
local bigOdds = Ui.new("TextLabel", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.56),
	Size = UDim2.fromOffset(700, 60),
	TextStrokeTransparency = 0,
	ZIndex = 41,
	Parent = flash,
})
local bigScale = Ui.new("UIScale", { Parent = flash })

local function bigReveal(pet)
	local rarity = Config.rarity(pet.Odds)
	flash.BackgroundColor3 = rarity.Color
	flash.BackgroundTransparency = 0
	flash.Visible = true
	bigName.Text = pet.Name:upper() .. "!"
	bigName.TextColor3 = Color3.new(1, 1, 1)
	bigName.TextStrokeColor3 = pet.Color
	bigOdds.Text = rarity.Name .. " · " .. Config.formatOdds(pet.Odds)
	bigOdds.TextColor3 = Color3.new(1, 1, 1)
	bigOdds.TextStrokeColor3 = rarity.Color
	bigScale.Scale = 0.3
	TweenService:Create(flash, TweenInfo.new(0.6), { BackgroundTransparency = 0.55 }):Play()
	TweenService:Create(bigScale, TweenInfo.new(0.5, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	-- rarer rolls stay on screen longer
	task.wait(math.clamp(math.log10(pet.Odds) - 1.5, 1.5, 4))
	TweenService:Create(flash, TweenInfo.new(0.4), { BackgroundTransparency = 1 }):Play()
	TweenService:Create(bigScale, TweenInfo.new(0.4), { Scale = 0 }):Play()
	task.wait(0.4)
	flash.Visible = false
end

-- Roll button + auto roll (bottom middle) ---------------------------------------

local luckText = Ui.new("TextLabel", {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -138),
	Size = UDim2.fromOffset(420, 26),
	Text = "",
	TextColor3 = Ui.GREEN,
	TextStrokeTransparency = 0.4,
	Parent = gui,
})

local rollButton, autoButton

local function refreshLuck()
	if not state then
		return
	end
	local untilBonus = Config.BONUS_EVERY - state.Rolls % Config.BONUS_EVERY
	local nextIsBonus = untilBonus == 1
	local luck = Config.luck(state.Equipped, nextIsBonus)
	luckText.Text = "🍀 Luck x" .. string.format("%.2f", luck) .. "   ·   "
		.. (if nextIsBonus then "✨ BONUS ROLL NEXT! ✨" else "Bonus roll in " .. untilBonus)
	luckText.TextColor3 = if nextIsBonus then Ui.GOLD else Ui.GREEN
end

-- random names flicker past before the real result lands
local function spinTo(pet)
	card.Visible = true
	local steps = 9
	for i = 1, steps do
		-- mostly common pets flash by, like a real roll
		local fake = Config.PETS[math.random(1, math.min(#Config.PETS, 4 + i))]
		showOnCard(fake)
		cardScale.Scale = 0.94
		TweenService:Create(cardScale, TweenInfo.new(0.05), { Scale = 1 }):Play()
		task.wait(0.03 + i * 0.012)
	end
	showOnCard(pet)
	cardScale.Scale = 1.25
	TweenService:Create(cardScale, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Scale = 1 }):Play()
end

local function floatText(text, color)
	local label = Ui.new("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 1, -300),
		Size = UDim2.fromOffset(360, 40),
		Text = text,
		TextColor3 = color,
		TextStrokeTransparency = 0.2,
		ZIndex = 20,
		Parent = gui,
	})
	TweenService:Create(label, TweenInfo.new(1.4, Enum.EasingStyle.Quad), {
		Position = label.Position - UDim2.fromOffset(0, 90),
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
	rollButton.Text = "🎲 ..."
	local started = os.clock()
	local ok, result = pcall(rollFunction.InvokeServer, rollFunction)
	if ok and result then
		local pet = Config.PETS_BY_NAME[result.Pet]
		spinTo(pet)
		if result.Bonus then
			floatText("✨ Bonus roll x" .. Config.BONUS_LUCK .. " luck!", Ui.GOLD)
		end
		if result.First then
			floatText("🆕 New pet: " .. pet.Name .. "!", Config.rarity(pet.Odds).Color)
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
	rollButton.Text = "🎲 ROLL"
	rolling = false
end

rollButton = Ui.button({
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -24),
	Size = UDim2.fromOffset(240, 104),
	Text = "🎲 ROLL",
	BackgroundColor3 = Color3.new(1, 1, 1),
	Parent = gui,
}, function()
	task.spawn(doRoll)
end)
Ui.gradient(Color3.fromRGB(90, 200, 255), Color3.fromRGB(120, 80, 240)).Parent = rollButton
Ui.stroke(Color3.new(1, 1, 1), 4).Parent = rollButton
Ui.padding(18).Parent = rollButton

local function refreshAuto()
	if not state then
		return
	end
	if state.Rolls < Config.AUTO_ROLL_AT then
		autoButton.Text = "🔒 Auto (" .. state.Rolls .. "/" .. Config.AUTO_ROLL_AT .. ")"
		autoButton.BackgroundColor3 = Ui.GREY
	else
		autoButton.Text = if autoRoll then "🔁 Auto: ON" else "🔁 Auto: OFF"
		autoButton.BackgroundColor3 = if autoRoll then Ui.GREEN else Ui.GREY
	end
end

autoButton = Ui.button({
	AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.new(0.5, 136, 1, -40),
	Size = UDim2.fromOffset(170, 64),
	Text = "🔁 Auto: OFF",
	BackgroundColor3 = Ui.GREY,
	Parent = gui,
}, function()
	if not state or state.Rolls < Config.AUTO_ROLL_AT then
		return
	end
	autoRoll = not autoRoll
	refreshAuto()
end)
Ui.padding(12).Parent = autoButton
Ui.stroke(Color3.new(1, 1, 1), 3).Parent = autoButton

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

local function modal(accent, width, height)
	local shade = Ui.new("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.45,
		Text = "",
		AutoButtonColor = false,
		Visible = false,
		ZIndex = 30,
		Parent = gui,
	})
	local box = Ui.new("Frame", {
		Name = "Box",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(width, height),
		BackgroundColor3 = Ui.DARK,
		ZIndex = 31,
		Parent = shade,
	}, { Ui.corner(20), Ui.stroke(accent, 4), Ui.padding(18) })
	local close = Ui.button({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 0),
		Size = UDim2.fromOffset(44, 44),
		Text = "✕",
		BackgroundColor3 = Color3.fromRGB(230, 70, 80),
		ZIndex = 33,
		Parent = box,
	}, function()
		shade.Visible = false
	end)
	Ui.padding(8).Parent = close
	return shade, box
end

local function title(box, text, color)
	return Ui.new("TextLabel", {
		Size = UDim2.new(1, -60, 0, 44),
		Text = text,
		TextColor3 = color,
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
		ScrollBarThickness = 6,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ZIndex = 32,
		Parent = box,
	}, { layout, Ui.new("UIPadding", { PaddingRight = UDim.new(0, 10), PaddingTop = UDim.new(0, 4) }) })
end

-- Pets panel: every pet in the game, owned ones can be equipped ------------------

local petsModal, petsBox = modal(Ui.PURPLE, 720, 560)
local petsTitle = title(petsBox, "🎒 Pets", Ui.PURPLE)
local equipHint = Ui.new("TextLabel", {
	Position = UDim2.fromOffset(0, 46),
	Size = UDim2.new(1, 0, 0, 24),
	Text = "Equip up to " .. Config.MAX_EQUIPPED .. " pets. Rarer pets give more luck!",
	TextColor3 = Ui.MUTED,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 32,
	Parent = petsBox,
})
local petsGrid = scrollList(petsBox, 80, Ui.new("UIGridLayout", {
	CellSize = UDim2.fromOffset(158, 176),
	CellPadding = UDim2.fromOffset(10, 10),
	SortOrder = Enum.SortOrder.LayoutOrder,
}))

local petCells = {} -- [pet name] = { Frame, Name, Count, Luck, Equip, Stroke }
for _, pet in ipairs(Config.PETS) do
	local rarity = Config.rarity(pet.Odds)
	local frame = Ui.new("Frame", {
		LayoutOrder = -pet.Index, -- rarest first
		BackgroundColor3 = Ui.PANEL,
		ZIndex = 32,
		Parent = petsGrid,
	}, { Ui.corner(14), Ui.padding(8) })
	local stroke = Ui.stroke(rarity.Color, 2)
	stroke.Parent = frame
	local nameLabel = Ui.new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 30),
		ZIndex = 33,
		Parent = frame,
	})
	Ui.new("TextLabel", {
		Position = UDim2.fromOffset(0, 32),
		Size = UDim2.new(1, 0, 0, 20),
		Text = rarity.Name,
		TextColor3 = rarity.Color,
		ZIndex = 33,
		Parent = frame,
	})
	Ui.new("TextLabel", {
		Position = UDim2.fromOffset(0, 54),
		Size = UDim2.new(1, 0, 0, 20),
		Text = Config.formatOdds(pet.Odds),
		TextColor3 = Ui.MUTED,
		ZIndex = 33,
		Parent = frame,
	})
	local countLabel = Ui.new("TextLabel", {
		Position = UDim2.fromOffset(0, 76),
		Size = UDim2.new(1, 0, 0, 20),
		TextColor3 = Ui.MUTED,
		ZIndex = 33,
		Parent = frame,
	})
	local luckLabel = Ui.new("TextLabel", {
		Position = UDim2.fromOffset(0, 98),
		Size = UDim2.new(1, 0, 0, 20),
		Text = "🍀 +" .. math.floor(Config.petLuck(pet) * 100 + 0.5) .. "% luck",
		TextColor3 = Ui.GREEN,
		ZIndex = 33,
		Parent = frame,
	})
	local equip = Ui.button({
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(1, 0, 0, 36),
		Text = "Equip",
		BackgroundColor3 = Ui.GREEN,
		ZIndex = 33,
		Parent = frame,
	}, function()
		equipFunction:InvokeServer(pet.Name)
	end)
	Ui.padding(6).Parent = equip
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
			cell.Name.TextColor3 = Color3.new(1, 1, 1)
			cell.Count.Text = "Rolled x" .. Config.formatNumber(owned)
			cell.Luck.Visible = true
			cell.Equip.Visible = true
			cell.Equip.Text = if equipped then "Unequip" else "Equip"
			cell.Equip.BackgroundColor3 = if equipped
				then Color3.fromRGB(230, 70, 80)
				elseif #state.Equipped >= Config.MAX_EQUIPPED then Ui.GREY
				else Ui.GREEN
		else
			-- not found yet: show only the odds, as something to chase
			cell.Name.Text = "???"
			cell.Name.TextColor3 = Ui.MUTED
			cell.Count.Text = "Not found yet"
			cell.Luck.Visible = false
			cell.Equip.Visible = false
		end
	end
	petsTitle.Text = "🎒 Pets  (" .. found .. "/" .. #Config.PETS .. " found)"
	equipHint.Text = "Equipped " .. #state.Equipped .. "/" .. Config.MAX_EQUIPPED .. ". Rarer pets give more luck!"
end

-- Leaderboard ----------------------------------------------------------------------

local boardModal, boardBox = modal(Ui.GOLD, 520, 600)
title(boardBox, "🏆 Most Rolls", Ui.GOLD)
local myRankText = Ui.new("TextLabel", {
	Position = UDim2.fromOffset(0, 46),
	Size = UDim2.new(1, 0, 0, 24),
	Text = "",
	TextColor3 = Ui.MUTED,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 32,
	Parent = boardBox,
})
local boardList = scrollList(boardBox, 80, Ui.new("UIListLayout", {
	Padding = UDim.new(0, 6),
	SortOrder = Enum.SortOrder.LayoutOrder,
}))

-- Side buttons (left) ------------------------------------------------------------

local function sideButton(y, text, color, onClick)
	local button = Ui.button({
		Position = UDim2.new(0, 16, 0.5, y),
		Size = UDim2.fromOffset(180, 60),
		Text = text,
		BackgroundColor3 = color,
		Parent = gui,
	}, onClick)
	Ui.padding(10).Parent = button
	Ui.stroke(Color3.new(1, 1, 1), 3).Parent = button
	return button
end

sideButton(-70, "🎒 Pets", Ui.PURPLE, function()
	refreshPets()
	Ui.popIn(petsModal)
end)
local boardButton = sideButton(10, "🏆 Top Rollers", Color3.fromRGB(230, 160, 30), function()
	Ui.popIn(boardModal)
end)

local MEDALS = { "🥇", "🥈", "🥉" }
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
			Size = UDim2.new(1, 0, 0, 44),
			BackgroundColor3 = if mine then Color3.fromRGB(90, 70, 150) else Ui.PANEL,
			ZIndex = 32,
			Parent = boardList,
		}, { Ui.corner(10) })
		Ui.new("TextLabel", {
			Position = UDim2.fromOffset(8, 6),
			Size = UDim2.fromOffset(52, 32),
			Text = MEDALS[i] or ("#" .. i),
			ZIndex = 33,
			Parent = row,
		})
		Ui.new("TextLabel", {
			Position = UDim2.fromOffset(68, 8),
			Size = UDim2.new(1, -220, 0, 28),
			Text = entry.Name,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 33,
			Parent = row,
		})
		Ui.new("TextLabel", {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -10, 0, 8),
			Size = UDim2.fromOffset(140, 28),
			Text = "🎲 " .. Config.formatNumber(entry.Rolls),
			TextColor3 = Ui.GOLD,
			TextXAlignment = Enum.TextXAlignment.Right,
			ZIndex = 33,
			Parent = row,
		})
	end
	myRankText.Text = if myRank then "You are #" .. myRank .. "!" else "Keep rolling to get on the board!"
	boardButton.Text = if myRank then "🏆 You're #" .. myRank else "🏆 Top Rollers"
end)

-- Updates ------------------------------------------------------------------------

stateEvent.OnClientEvent:Connect(function(newState)
	state = newState
	rollsText.Text = "🎲 " .. Config.formatNumber(state.Rolls) .. " Rolls"
	local best = state.Best and Config.PETS_BY_NAME[state.Best]
	if best then
		bestText.Text = "Best: " .. best.Name .. " (" .. Config.formatOdds(best.Odds) .. ")"
		bestText.TextColor3 = Config.rarity(best.Odds).Color
	end
	Pets.update(state.Equipped)
	refreshLuck()
	refreshAuto()
	if petsModal.Visible then
		refreshPets()
	end
end)
