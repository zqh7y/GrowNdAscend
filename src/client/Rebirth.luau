-- The Rebirth screen: friendly and clear about the deal.
--   top      "Rebirth 4 / 8" with a row of 8 stars (gold = done)
--   middle   two cards side by side: YOU LOSE (just your coins) and
--            YOU GAIN (Luck x1.5 and Money +200%, shown as now -> after)
--   bottom   the two requirements, each ticked (met) or locked: the coins
--            (with how many you have) and the level ("Current Level 48 / 50"
--            with a bar), then the big REBIRTH button, which only lights up
--            when both are met
-- Worlds, pets, upgrades, the Index and your level are kept (it says so).
-- At rebirth 8 it shows the max. Rebirthing plays confetti and a jingle.
local RunService = game:GetService("RunService")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local Effects = require(script.Parent.Effects)
local Screen = require(script.Parent.Screen)
local State = require(script.Parent.State)
local Ui = require(script.Parent.Ui)

local Rebirth = {}

local rebirthFunction = State.remote("Rebirth")

local modal, box = Screen.modal(760, 600, "Rebirth")
Screen.title(box, "Rebirth")

local function label(parent, props)
	props.BackgroundTransparency = props.BackgroundTransparency or 1
	props.TextScaled = false
	props.ZIndex = props.ZIndex or 34
	props.Parent = parent
	return Ui.new("TextLabel", props)
end

-- Level and stars -------------------------------------------------------------------------------

local levelText = label(box, {
	Position = UDim2.fromOffset(0, 20),
	Size = UDim2.new(1, 0, 0, 36),
	TextSize = 34,
	TextStrokeTransparency = 0,
	TextStrokeColor3 = Ui.INK,
})
local starRow = Ui.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 60),
	Size = UDim2.fromOffset(Config.MAX_REBIRTHS * 40, 34),
	BackgroundTransparency = 1,
	ZIndex = 33,
	Parent = box,
}, {
	Ui.new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}),
})
local stars = {}
for i = 1, Config.MAX_REBIRTHS do
	local holder = Ui.new("Frame", {
		LayoutOrder = i,
		Size = UDim2.fromOffset(34, 34),
		BackgroundColor3 = Color3.fromRGB(30, 22, 70),
		ZIndex = 33,
		Parent = starRow,
	}, { Ui.corner(0.5), Ui.stroke(Color3.new(1, 1, 1), 2, 0.3) })
	stars[i] = { Holder = holder, Icon = Ui.icon("star", 22, Color3.fromRGB(90, 85, 130), { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), ZIndex = 34, Parent = holder }) }
end

-- Lose / gain cards ----------------------------------------------------------------------------------

local function card(x, title, color)
	local frame = Ui.new("Frame", {
		Position = UDim2.new(x, if x == 0 then 0 else 8, 0, 108),
		Size = UDim2.new(0.5, -8, 0, 200),
		BackgroundColor3 = color:Lerp(Color3.fromRGB(30, 20, 70), 0.55),
		BackgroundTransparency = 0.1,
		ZIndex = 33,
		Parent = box,
	}, { Ui.corner(24), Ui.padding(14) })
	Ui.stroke(color, 3.5, 0).Parent = frame
	local head = label(frame, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0, -14),
		Size = UDim2.fromOffset(150, 30),
		BackgroundTransparency = 0,
		BackgroundColor3 = color,
		TextSize = 20,
		Text = title,
		TextStrokeTransparency = 0.3,
		TextStrokeColor3 = Ui.INK,
		ZIndex = 35,
	})
	Ui.corner(15).Parent = head
	Ui.stroke(Color3.new(1, 1, 1), 2.5).Parent = head
	return frame
end

-- one line in a card: an icon in a bubble, a big line and a small one
local function row(parent, y, icon, iconColor)
	local bubble = Ui.new("Frame", {
		Position = UDim2.fromOffset(0, y),
		Size = UDim2.fromOffset(54, 54),
		BackgroundColor3 = iconColor,
		ZIndex = 34,
		Parent = parent,
	}, { Ui.corner(0.5), Ui.stroke(Color3.new(1, 1, 1), 3) })
	Ui.icon(icon, 30, Color3.new(1, 1, 1), { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), ZIndex = 35, Parent = bubble })
	local big = label(parent, {
		Position = UDim2.fromOffset(66, y + 2),
		Size = UDim2.new(1, -66, 0, 28),
		TextSize = 25,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextStrokeTransparency = 0.3,
		TextStrokeColor3 = Ui.INK,
	})
	local small = label(parent, {
		Position = UDim2.fromOffset(66, y + 30),
		Size = UDim2.new(1, -66, 0, 20),
		Font = Ui.FONT_MEDIUM,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Color3.fromRGB(225, 220, 250),
	})
	return big, small
end

local lose = card(0, "YOU LOSE", Color3.fromRGB(255, 110, 130))
local loseCoins, loseCoinsNote = row(lose, 16, "coin", Color3.fromRGB(255, 190, 60))
local keepWorlds, keepWorldsNote = row(lose, 86, "star", Color3.fromRGB(110, 200, 120))
label(lose, {
	AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.new(0, 0, 1, 0),
	Size = UDim2.new(1, 0, 0, 20),
	Font = Ui.FONT_MEDIUM,
	TextSize = 13,
	Text = "You KEEP worlds, pets, upgrades, Index, level",
	TextColor3 = Ui.SUCCESS,
})

local gain = card(0.5, "YOU GAIN", Color3.fromRGB(110, 225, 120))
local gainLuck, gainLuckNote = row(gain, 16, "clover", Color3.fromRGB(80, 200, 110))
local gainCoins, gainCoinsNote = row(gain, 86, "coin", Color3.fromRGB(255, 190, 60))
label(gain, {
	AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.new(0, 0, 1, 0),
	Size = UDim2.new(1, 0, 0, 20),
	Font = Ui.FONT_MEDIUM,
	TextSize = 13,
	Text = "Forever, and every rebirth stacks!",
	TextColor3 = Ui.GOLD,
})

-- Requirements ------------------------------------------------------------------------------------

local reqTitle = label(box, {
	Position = UDim2.fromOffset(0, 318),
	Size = UDim2.new(1, 0, 0, 24),
	TextSize = 20,
	Text = "TO REBIRTH YOU NEED",
	TextColor3 = Ui.MUTED,
})

local function requirement(x)
	local frame = Ui.new("Frame", {
		Position = UDim2.new(x, if x == 0 then 0 else 8, 0, 348),
		Size = UDim2.new(0.5, -8, 0, 104),
		BackgroundColor3 = Color3.fromRGB(35, 26, 80),
		BackgroundTransparency = 0.1,
		ZIndex = 33,
		Parent = box,
	}, { Ui.corner(22), Ui.padding(10) })
	local stroke = Ui.stroke(Color3.new(1, 1, 1), 3, 0.2)
	stroke.Parent = frame
	local tick = label(frame, {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 0),
		Size = UDim2.fromOffset(34, 34),
		BackgroundTransparency = 0,
		TextSize = 22,
		ZIndex = 36,
	})
	Ui.corner(0.5).Parent = tick
	Ui.stroke(Color3.new(1, 1, 1), 2.5).Parent = tick
	return frame, stroke, tick
end

local cashCard, cashStroke, cashTick = requirement(0)
local cashBubble = Ui.new("Frame", {
	Position = UDim2.fromOffset(0, 12),
	Size = UDim2.fromOffset(60, 60),
	BackgroundColor3 = Color3.fromRGB(255, 190, 60),
	ZIndex = 34,
	Parent = cashCard,
}, { Ui.corner(0.5), Ui.stroke(Color3.new(1, 1, 1), 3) })
Ui.icon("coin", 36, Color3.new(1, 1, 1), { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), ZIndex = 35, Parent = cashBubble })
label(cashCard, { Position = UDim2.fromOffset(72, 4), Size = UDim2.new(1, -110, 0, 18), TextSize = 15, Text = "REQUIRED CASH", TextColor3 = Ui.MUTED, TextXAlignment = Enum.TextXAlignment.Left })
local cashAmount = label(cashCard, { Position = UDim2.fromOffset(72, 24), Size = UDim2.new(1, -110, 0, 34), TextSize = 32, TextColor3 = Ui.GOLD, TextXAlignment = Enum.TextXAlignment.Left, TextStrokeTransparency = 0.3, TextStrokeColor3 = Ui.INK })
local cashHave = label(cashCard, { Position = UDim2.fromOffset(72, 62), Size = UDim2.new(1, -72, 0, 18), Font = Ui.FONT_MEDIUM, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left })

local levelCard, levelStroke, levelTick = requirement(0.5)
local levelBubble = Ui.new("Frame", {
	Position = UDim2.fromOffset(0, 12),
	Size = UDim2.fromOffset(60, 60),
	BackgroundColor3 = Color3.fromRGB(140, 100, 255),
	ZIndex = 34,
	Parent = levelCard,
}, { Ui.corner(0.5), Ui.stroke(Color3.new(1, 1, 1), 3) })
Ui.icon("star", 36, Color3.new(1, 1, 1), { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), ZIndex = 35, Parent = levelBubble })
label(levelCard, { Position = UDim2.fromOffset(72, 4), Size = UDim2.new(1, -110, 0, 18), TextSize = 15, Text = "REQUIRED LEVEL", TextColor3 = Ui.MUTED, TextXAlignment = Enum.TextXAlignment.Left })
local levelNeed = label(levelCard, { Position = UDim2.fromOffset(72, 24), Size = UDim2.new(1, -110, 0, 34), TextSize = 32, TextColor3 = Color3.fromRGB(200, 170, 255), TextXAlignment = Enum.TextXAlignment.Left, TextStrokeTransparency = 0.3, TextStrokeColor3 = Ui.INK })
local levelHave = label(levelCard, { Position = UDim2.fromOffset(72, 60), Size = UDim2.new(1, -72, 0, 16), Font = Ui.FONT_MEDIUM, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left })
local levelTrack = Ui.new("Frame", {
	Position = UDim2.fromOffset(72, 78),
	Size = UDim2.new(1, -72, 0, 8),
	BackgroundColor3 = Color3.fromRGB(20, 14, 50),
	ZIndex = 34,
	Parent = levelCard,
}, { Ui.corner(0.5) })
local levelFill = Ui.new("Frame", {
	Size = UDim2.fromScale(0, 1),
	BackgroundColor3 = Color3.fromRGB(160, 120, 255),
	ZIndex = 35,
	Parent = levelTrack,
}, { Ui.corner(0.5) })

local testingNote = label(box, {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 456),
	Size = UDim2.fromOffset(0, 22),
	AutomaticSize = Enum.AutomaticSize.X,
	BackgroundTransparency = 0,
	BackgroundColor3 = Color3.fromRGB(255, 140, 60),
	TextSize = 14,
	Text = "  TESTING: rebirths cost no coins right now  ",
	TextColor3 = Ui.INK,
	Visible = Config.REBIRTH_FREE_FOR_TESTING,
})
Ui.corner(11).Parent = testingNote

local rebirthButton = Ui.button({
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, 0),
	Size = UDim2.new(0.7, 0, 0, 70),
	Radius = 26,
	Text = "REBIRTH",
	Icon = "star",
	TextSize = 30,
	ZIndex = 34,
	Parent = box,
}, function()
	Rebirth.rebirth()
end, "purple")
local buttonScale = Ui.new("UIScale", { Parent = rebirthButton })

-- Showing state -----------------------------------------------------------------------------------

local ready = false

local function setTick(tick, stroke, ok)
	tick.Text = if ok then "✓" else "🔒"
	tick.BackgroundColor3 = if ok then Ui.SUCCESS else Ui.DANGER
	stroke.Color = if ok then Ui.SUCCESS else Color3.fromRGB(255, 140, 150)
	stroke.Transparency = 0
end

local function refresh()
	local data = State.Data
	if not data then
		return
	end
	local r = data.Rebirths
	local row = Config.nextRebirth(r)
	levelText.Text = "Rebirth " .. r .. " / " .. Config.MAX_REBIRTHS
	for i, s in ipairs(stars) do
		local done = i <= r
		s.Holder.BackgroundColor3 = if done then Color3.fromRGB(255, 190, 50) elseif i == r + 1 then Color3.fromRGB(120, 80, 200) else Color3.fromRGB(30, 22, 70)
		for _, d in ipairs(s.Icon:GetDescendants()) do
			if d:IsA("Frame") and d.BackgroundTransparency < 1 then
				d.BackgroundColor3 = if done then Color3.new(1, 1, 1) else Color3.fromRGB(90, 85, 130)
			end
		end
	end

	-- what you lose and gain
	loseCoins.Text = Config.formatNumber(data.Coins) .. " coins"
	loseCoinsNote.Text = "Your coins go back to 0"
	keepWorlds.Text = "Worlds stay open"
	keepWorldsNote.Text = "Only your coins reset"
	local nextR = math.min(r + 1, Config.MAX_REBIRTHS)
	gainLuck.Text = "Luck x" .. Config.REBIRTH_LUCK
	gainLuckNote.Text = string.format("Total luck bonus x%.2f → x%.2f", Config.rebirthLuck(r), Config.rebirthLuck(nextR))
	gainCoins.Text = "Money +" .. math.floor(Config.REBIRTH_COINS * 100) .. "%"
	gainCoinsNote.Text = "Coins x" .. Config.coinMultiplier(r) .. " → x" .. Config.coinMultiplier(nextR)

	if not row then
		-- all 8 done
		reqTitle.Text = "MAX REBIRTH REACHED!"
		reqTitle.TextColor3 = Ui.GOLD
		cashCard.Visible, levelCard.Visible, testingNote.Visible = false, false, false
		Ui.setText(rebirthButton, "MAX REBIRTH  " .. Config.MAX_REBIRTHS .. "/" .. Config.MAX_REBIRTHS)
		Ui.setStyle(rebirthButton, "gold")
		ready = false
		return
	end
	cashCard.Visible, levelCard.Visible = true, true
	testingNote.Visible = Config.REBIRTH_FREE_FOR_TESTING
	reqTitle.Text = "TO REBIRTH YOU NEED"
	reqTitle.TextColor3 = Ui.MUTED
	local ok, hasCoins, hasLevel = Config.canRebirth(data)
	local cost = Config.rebirthCost(r)
	cashAmount.Text = if cost == 0 then "FREE" else Config.formatNumber(cost)
	cashHave.Text = "You have " .. Config.formatNumber(data.Coins)
	cashHave.TextColor3 = if hasCoins then Ui.SUCCESS else Color3.fromRGB(255, 170, 170)
	setTick(cashTick, cashStroke, hasCoins)

	local level = data.Level or 1
	levelNeed.Text = "Level " .. row.Level
	levelHave.Text = "Current Level: " .. level .. " / " .. row.Level
	levelHave.TextColor3 = if hasLevel then Ui.SUCCESS else Color3.fromRGB(255, 170, 170)
	levelFill.Size = UDim2.fromScale(math.clamp(level / row.Level, 0, 1), 1)
	levelFill.BackgroundColor3 = if hasLevel then Ui.SUCCESS else Color3.fromRGB(160, 120, 255)
	setTick(levelTick, levelStroke, hasLevel)

	ready = ok
	Ui.setText(rebirthButton, if ok then "REBIRTH NOW!" else "REBIRTH")
	Ui.setStyle(rebirthButton, if ok then "purple" else "disabled")
end

function Rebirth.rebirth()
	local data = State.Data
	if not data then
		return false
	end
	if not ready then
		Effects.play("Click", 0.7)
		-- wiggle whatever is missing
		for _, target in ipairs({ cashCard, levelCard }) do
			local home = target.Position
			for k = 1, 4 do
				task.delay(k * 0.04, function()
					target.Position = home + UDim2.fromOffset(if k % 2 == 0 then -6 else 6, 0)
				end)
			end
			task.delay(0.2, function()
				target.Position = home
			end)
		end
		return false
	end
	local done = rebirthFunction:InvokeServer()
	if done then
		Effects.jingle(6)
		Effects.confetti(80)
		Screen.close(modal)
	end
	return done
end

function Rebirth.open()
	Screen.open(modal)
	refresh()
end

-- the button bounces when ready
RunService.RenderStepped:Connect(function()
	if not modal.Visible then
		return
	end
	local t = os.clock()
	buttonScale.Scale = if ready then 1 + (math.sin(t * 5) * 0.5 + 0.5) * 0.05 else 1
end)

State.watch(function()
	if modal.Visible then
		refresh()
	end
end)

return Rebirth
