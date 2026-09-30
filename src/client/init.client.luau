-- Client entry point: the HUD, trainer shop, pet card, ascend, offline
-- earnings popup and the Strongest Pet leaderboard.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Ui = require(script.Ui)
local Pet = require(script.Pet)

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local stateEvent = remotes:WaitForChild("State")
local offlineEvent = remotes:WaitForChild("Offline")
local tapEvent = remotes:WaitForChild("Tap")
local buyFunction = remotes:WaitForChild("Buy")
local ascendFunction = remotes:WaitForChild("Ascend")
local leaderboardEvent = remotes:WaitForChild("Leaderboard")

local state = nil -- latest data from the server
local stateTime = 0 -- os.clock() when it arrived
local predicted = 0 -- tap energy we've shown but the server hasn't confirmed yet
local buyMode = 1 -- 1, 10 or "Max"

-- Screen -----------------------------------------------------------------------

local gui = Ui.new("ScreenGui", {
	Name = "GrowNdAscend",
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

-- Energy counter (top middle)
local energyBox = Ui.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 14),
	Size = UDim2.fromOffset(360, 96),
	BackgroundColor3 = Ui.DARK,
	BackgroundTransparency = 0.15,
	Parent = gui,
}, { Ui.corner(18), Ui.stroke(Ui.GOLD, 3) })
local energyText = Ui.new("TextLabel", {
	Position = UDim2.fromOffset(12, 6),
	Size = UDim2.new(1, -24, 0, 56),
	Text = "⚡ 0",
	TextColor3 = Ui.GOLD,
	Parent = energyBox,
})
local rateText = Ui.new("TextLabel", {
	Position = UDim2.fromOffset(12, 62),
	Size = UDim2.new(1, -24, 0, 26),
	Text = "0 / sec",
	TextColor3 = Ui.MUTED,
	Parent = energyBox,
})

-- Tap button (bottom middle)
local tapButton
local function floatText(text, color)
	local label = Ui.new("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, math.random(-80, 80), 1, -210),
		Size = UDim2.fromOffset(200, 40),
		Text = text,
		TextColor3 = color or Ui.GOLD,
		TextStrokeTransparency = 0.2,
		ZIndex = 20,
		Parent = gui,
	})
	TweenService:Create(label, TweenInfo.new(0.9, Enum.EasingStyle.Quad), {
		Position = label.Position - UDim2.fromOffset(0, 120),
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	}):Play()
	task.delay(0.9, function()
		label:Destroy()
	end)
end

local tapTimes = {} -- recent taps, to not go over the server's limit
tapButton = Ui.button({
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -24),
	Size = UDim2.fromOffset(230, 110),
	Text = "💪 TRAIN!",
	BackgroundColor3 = Color3.new(1, 1, 1),
	Parent = gui,
}, function()
	if not state then
		return
	end
	local now = os.clock()
	while tapTimes[1] and now - tapTimes[1] > 1 do
		table.remove(tapTimes, 1)
	end
	if #tapTimes >= Config.MAX_TAPS_PER_SECOND then
		return
	end
	table.insert(tapTimes, now)
	tapEvent:FireServer()
	local gain = Config.tapValue(state)
	predicted += gain
	Pet.bounce()
	floatText("+" .. Config.formatNumber(gain) .. " ⚡")
end)
Ui.gradient(Color3.fromRGB(255, 150, 60), Color3.fromRGB(235, 80, 110)).Parent = tapButton
Ui.stroke(Color3.new(1, 1, 1), 4).Parent = tapButton
Ui.padding(18).Parent = tapButton

-- Pet card (left) ----------------------------------------------------------------

local petCard = Ui.new("Frame", {
	Position = UDim2.new(0, 16, 0.5, -170),
	Size = UDim2.fromOffset(280, 340),
	BackgroundColor3 = Ui.DARK,
	BackgroundTransparency = 0.1,
	Parent = gui,
}, { Ui.corner(18), Ui.stroke(Ui.PURPLE, 3), Ui.padding(14) })

local function cardLine(y, height, text, color)
	return Ui.new("TextLabel", {
		Position = UDim2.fromOffset(0, y),
		Size = UDim2.new(1, 0, 0, height),
		Text = text,
		TextColor3 = color or Ui.TEXT,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = petCard,
	})
end
local formText = cardLine(0, 38, "Sprout Pup")
local powerText = cardLine(44, 30, "💪 Power 0", Ui.GOLD)
local bestText = cardLine(76, 24, "🏆 Best 0", Ui.MUTED)
local starsText = cardLine(104, 24, "⭐ 0 Stars (+0%)", Ui.MUTED)
local nextFormText = cardLine(130, 22, "", Ui.MUTED)

local progressBack = Ui.new("Frame", {
	Position = UDim2.fromOffset(0, 166),
	Size = UDim2.new(1, 0, 0, 22),
	BackgroundColor3 = Ui.PANEL,
	Parent = petCard,
}, { Ui.corner(11) })
local progressFill = Ui.new("Frame", {
	Size = UDim2.fromScale(0, 1),
	BackgroundColor3 = Ui.PURPLE,
	Parent = progressBack,
}, { Ui.corner(11) })
local progressText = Ui.new("TextLabel", {
	Size = UDim2.fromScale(1, 1),
	Text = "",
	ZIndex = 2,
	Parent = progressBack,
}, { Ui.padding(3) })

local ascendModal -- built below
local ascendButton = Ui.button({
	Position = UDim2.fromOffset(0, 200),
	Size = UDim2.new(1, 0, 0, 70),
	Text = "🌟 ASCEND",
	BackgroundColor3 = Ui.GREY,
	Parent = petCard,
}, function()
	if state and Config.starsFor(state.RunEarned) > 0 then
		Ui.popIn(ascendModal)
	end
end)
Ui.padding(12).Parent = ascendButton

local leaderboardButton -- built below

-- Trainer shop (right) -----------------------------------------------------------

local shop = Ui.new("Frame", {
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -16, 0.5, 0),
	Size = UDim2.fromOffset(380, 560),
	BackgroundColor3 = Ui.DARK,
	BackgroundTransparency = 0.1,
	Parent = gui,
}, { Ui.corner(18), Ui.stroke(Ui.GREEN, 3), Ui.padding(12) })
Ui.new("TextLabel", {
	Size = UDim2.new(0.5, 0, 0, 36),
	Text = "🏋️ Trainers",
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = shop,
})

local modeButtons = {}
local function refreshModes()
	for mode, button in pairs(modeButtons) do
		button.BackgroundColor3 = if mode == buyMode then Ui.GREEN else Ui.GREY
	end
end
for i, mode in ipairs({ 1, 10, "Max" }) do
	local button = Ui.button({
		Position = UDim2.new(0.5, (i - 1) * 60, 0, 2),
		Size = UDim2.fromOffset(54, 32),
		Text = if mode == "Max" then "Max" else "x" .. mode,
		BackgroundColor3 = Ui.GREY,
		Parent = shop,
	}, function()
		buyMode = mode
		refreshModes()
	end)
	Ui.padding(5).Parent = button
	modeButtons[mode] = button
end
refreshModes()

local list = Ui.new("ScrollingFrame", {
	Position = UDim2.fromOffset(0, 46),
	Size = UDim2.new(1, 0, 1, -46),
	BackgroundTransparency = 1,
	ScrollBarThickness = 6,
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	CanvasSize = UDim2.new(),
	Parent = shop,
}, {
	Ui.new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
	Ui.new("UIPadding", { PaddingRight = UDim.new(0, 10) }),
})

local rows = {} -- { Kind, Trainer, Frame, Title, Info, Buy }
local function makeRow(order, icon, onBuy)
	local frame = Ui.new("Frame", {
		LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, 74),
		BackgroundColor3 = Ui.PANEL,
		Parent = list,
	}, { Ui.corner(12) })
	Ui.new("TextLabel", {
		Position = UDim2.fromOffset(8, 12),
		Size = UDim2.fromOffset(50, 50),
		Text = icon,
		Parent = frame,
	})
	local title = Ui.new("TextLabel", {
		Position = UDim2.fromOffset(64, 8),
		Size = UDim2.new(1, -190, 0, 28),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = frame,
	})
	local info = Ui.new("TextLabel", {
		Position = UDim2.fromOffset(64, 40),
		Size = UDim2.new(1, -190, 0, 22),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Ui.MUTED,
		Parent = frame,
	})
	local buy = Ui.button({
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		Size = UDim2.fromOffset(112, 56),
		BackgroundColor3 = Ui.GREY,
		Parent = frame,
	}, onBuy)
	Ui.padding(8).Parent = buy
	return { Frame = frame, Title = title, Info = info, Buy = buy }
end

local function currentEnergy()
	if not state then
		return 0
	end
	local elapsed = math.min(os.clock() - stateTime, 1)
	return state.Energy + Config.perSecond(state) * elapsed + predicted
end

local tapRow = makeRow(0, "👊", function()
	if buyFunction:InvokeServer("Tap") then
		Pet.bounce()
	end
end)
tapRow.Kind = "Tap"
table.insert(rows, tapRow)

for i, trainer in ipairs(Config.TRAINERS) do
	local row = makeRow(i, trainer.Icon, function()
		if buyFunction:InvokeServer("Trainer", trainer.Id, buyMode) then
			Pet.bounce()
		end
	end)
	row.Kind = "Trainer"
	row.Trainer = trainer
	table.insert(rows, row)
end

-- the bulk count and cost shown on a trainer's button for the current mode
local function trainerOffer(trainer, owned, energy)
	if buyMode == 1 then
		return 1, Config.trainerCost(trainer, owned)
	elseif buyMode == 10 then
		local total = 0
		for n = 0, 9 do
			total += Config.trainerCost(trainer, owned + n)
		end
		return 10, total
	end
	local count, total = Config.trainerBulk(trainer, owned, energy, 1000)
	if count == 0 then
		return 1, Config.trainerCost(trainer, owned)
	end
	return count, total
end

local function refreshShop(energy)
	for _, row in ipairs(rows) do
		if row.Kind == "Tap" then
			local cost = Config.tapCost(state.TapLevel)
			row.Title.Text = "Stronger Taps  Lv " .. state.TapLevel
			row.Info.Text = Config.formatNumber(Config.tapValue(state)) .. " ⚡ per tap"
			row.Buy.Text = "⚡ " .. Config.formatNumber(cost)
			row.Buy.BackgroundColor3 = if energy >= cost then Ui.GREEN else Ui.GREY
		else
			local trainer = row.Trainer
			local owned = state.Trainers[trainer.Id] or 0
			-- hide trainers more than one step beyond what you own, so there's
			-- always something new to unlock
			local previous = Config.TRAINERS[table.find(Config.TRAINERS, trainer) - 1]
			local unlocked = not previous or (state.Trainers[previous.Id] or 0) > 0 or owned > 0
			row.Frame.Visible = unlocked
			local count, cost = trainerOffer(trainer, owned, energy)
			local nextMilestone = (math.floor(owned / Config.MILESTONE) + 1) * Config.MILESTONE
			row.Title.Text = trainer.Name .. "  x" .. owned
			row.Info.Text = Config.formatNumber(Config.trainerRate(trainer, math.max(owned, 1), state.Stars) / math.max(owned, 1))
				.. "/s each · 2x at " .. nextMilestone
			row.Buy.Text = (if count > 1 then "+" .. count .. "  " else "") .. "⚡ " .. Config.formatNumber(cost)
			row.Buy.BackgroundColor3 = if energy >= cost then Ui.GREEN else Ui.GREY
		end
	end
end

-- Ascend modal -------------------------------------------------------------------

local function modal(accent)
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
		Size = UDim2.fromOffset(460, 300),
		BackgroundColor3 = Ui.DARK,
		ZIndex = 31,
		Parent = shade,
	}, { Ui.corner(20), Ui.stroke(accent, 4), Ui.padding(18) })
	return shade, box
end

local function modalText(box, y, height, text, color)
	return Ui.new("TextLabel", {
		Position = UDim2.fromOffset(0, y),
		Size = UDim2.new(1, 0, 0, height),
		Text = text,
		TextColor3 = color or Ui.TEXT,
		ZIndex = 32,
		Parent = box,
	})
end

local ascendBox
ascendModal, ascendBox = modal(Ui.GOLD)
modalText(ascendBox, 0, 44, "🌟 Ascend?", Ui.GOLD)
local ascendInfo = modalText(ascendBox, 54, 100, "", Ui.MUTED)
ascendInfo.TextWrapped = true
local confirm = Ui.button({
	Position = UDim2.new(0, 0, 1, -70),
	Size = UDim2.new(0.48, 0, 0, 70),
	Text = "Ascend!",
	BackgroundColor3 = Ui.GREEN,
	ZIndex = 32,
	Parent = ascendBox,
}, function()
	ascendModal.Visible = false
	local result = ascendFunction:InvokeServer()
	if result then
		predicted = 0
		Pet.evolve()
		floatText("+" .. result.Stars .. " ⭐", Ui.GOLD)
		floatText(result.Form .. "!", Color3.fromRGB(210, 160, 255))
	end
end)
Ui.padding(14).Parent = confirm
local cancel = Ui.button({
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, 0, 1, -70),
	Size = UDim2.new(0.48, 0, 0, 70),
	Text = "Not yet",
	BackgroundColor3 = Ui.GREY,
	ZIndex = 32,
	Parent = ascendBox,
}, function()
	ascendModal.Visible = false
end)
Ui.padding(14).Parent = cancel

-- Offline earnings popup ---------------------------------------------------------

local offlineModal, offlineBox = modal(Ui.GREEN)
modalText(offlineBox, 0, 44, "💤 Welcome back!", Ui.GREEN)
local offlineInfo = modalText(offlineBox, 54, 100, "", Ui.MUTED)
offlineInfo.TextWrapped = true
local collect = Ui.button({
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 1, -70),
	Size = UDim2.new(0.6, 0, 0, 70),
	Text = "Collect!",
	BackgroundColor3 = Ui.GREEN,
	ZIndex = 32,
	Parent = offlineBox,
}, function()
	offlineModal.Visible = false
end)
Ui.padding(14).Parent = collect

offlineEvent.OnClientEvent:Connect(function(info)
	offlineInfo.Text = "Your pet kept training for " .. Config.formatTime(info.Seconds)
		.. " while you were away and earned\n⚡ " .. Config.formatNumber(info.Gain)
	Ui.popIn(offlineModal)
end)

-- Leaderboard --------------------------------------------------------------------

local boardModal, boardBox = modal(Ui.GOLD)
boardBox.Size = UDim2.fromOffset(520, 620)
modalText(boardBox, 0, 44, "🏆 Strongest Pets", Ui.GOLD)
local myRankText = modalText(boardBox, 48, 26, "", Ui.MUTED)
local boardList = Ui.new("ScrollingFrame", {
	Position = UDim2.fromOffset(0, 84),
	Size = UDim2.new(1, 0, 1, -150),
	BackgroundTransparency = 1,
	ScrollBarThickness = 6,
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	CanvasSize = UDim2.new(),
	ZIndex = 32,
	Parent = boardBox,
}, {
	Ui.new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
	Ui.new("UIPadding", { PaddingRight = UDim.new(0, 10) }),
})
local close = Ui.button({
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, 0),
	Size = UDim2.new(0.5, 0, 0, 54),
	Text = "Close",
	BackgroundColor3 = Ui.GREY,
	ZIndex = 32,
	Parent = boardBox,
}, function()
	boardModal.Visible = false
end)
Ui.padding(12).Parent = close

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
			Text = "💪 " .. Config.formatNumber(entry.Power),
			TextColor3 = Ui.GOLD,
			TextXAlignment = Enum.TextXAlignment.Right,
			ZIndex = 33,
			Parent = row,
		})
	end
	myRankText.Text = if myRank then "You are #" .. myRank .. "!" else "Grow your pet to get on the board!"
	if leaderboardButton then
		leaderboardButton.Text = if myRank then "🏆 #" .. myRank else "🏆 Top Pets"
	end
end)

leaderboardButton = Ui.button({
	Position = UDim2.new(0, 16, 0, 16),
	Size = UDim2.fromOffset(180, 56),
	Text = "🏆 Top Pets",
	BackgroundColor3 = Color3.fromRGB(230, 160, 30),
	Parent = gui,
}, function()
	Ui.popIn(boardModal)
end)
Ui.padding(10).Parent = leaderboardButton
Ui.stroke(Color3.new(1, 1, 1), 3).Parent = leaderboardButton

-- Updates ------------------------------------------------------------------------

local lastForm = nil
stateEvent.OnClientEvent:Connect(function(newState)
	state = newState
	stateTime = os.clock()
	predicted = 0
	local form = Pet.update(state)
	if lastForm and lastForm ~= form.Name then
		Pet.evolve()
	end
	lastForm = form.Name
end)

local function refresh()
	if not state then
		return
	end
	local energy = currentEnergy()
	local perSecond = Config.perSecond(state)
	energyText.Text = "⚡ " .. Config.formatNumber(energy)
	rateText.Text = Config.formatNumber(perSecond) .. " / sec"

	local form, index = Config.form(state.Ascensions)
	local power = Config.petPower(state)
	formText.Text = form.Name
	formText.TextColor3 = form.Glow
	powerText.Text = "💪 Power " .. Config.formatNumber(power)
	bestText.Text = "🏆 Best " .. Config.formatNumber(math.max(state.BestPower, power))
	starsText.Text = "⭐ " .. Config.formatNumber(state.Stars) .. " Stars (+"
		.. Config.formatNumber(state.Stars * Config.STAR_BONUS * 100) .. "%)"
	local nextForm = Config.FORMS[index + 1]
	nextFormText.Text = if nextForm
		then "Next form: " .. nextForm.Name .. " (ascend " .. nextForm.Ascensions - state.Ascensions .. "x)"
		else "Final form reached!"

	-- ascend progress
	local stars = Config.starsFor(state.RunEarned)
	if stars > 0 then
		progressFill.Size = UDim2.fromScale(1, 1)
		progressText.Text = "Ready! +" .. Config.formatNumber(stars) .. " ⭐"
		ascendButton.BackgroundColor3 = Ui.GOLD
		ascendButton.Text = "🌟 ASCEND +" .. Config.formatNumber(stars) .. " ⭐"
	else
		progressFill.Size = UDim2.fromScale(math.clamp(state.RunEarned / Config.ASCEND_MIN, 0, 1), 1)
		progressText.Text = Config.formatNumber(state.RunEarned) .. " / " .. Config.formatNumber(Config.ASCEND_MIN)
		ascendButton.BackgroundColor3 = Ui.GREY
		ascendButton.Text = "🌟 ASCEND"
	end
	ascendInfo.Text = "Reset your energy, trainers and taps for +" .. Config.formatNumber(stars)
		.. " ⭐ Stars. Every star is +10% energy and pet power forever, and your pet evolves!"

	refreshShop(energy)
end

local elapsed = 0
RunService.Heartbeat:Connect(function(dt)
	elapsed += dt
	if elapsed >= 0.1 then
		elapsed = 0
		refresh()
	end
end)
