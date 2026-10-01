-- The Rebirth screen: a clear, sleek summary of the deal.
--   top      "REBIRTH 3 / 8" and a bar of 8 segments (lit = done)
--   middle   RESET (just your coins; everything else you keep, listed) and
--            GAIN (Luck x1.5 and Money +200%, now -> after)
--   bottom   the two requirements, each MET or LOCKED: the cash (with how
--            much you have) and the level ("Current Level 48 / 50" and a
--            bar), then the REBIRTH button, which only lights up when both
--            are met
-- At rebirth 8 it shows MAX. Rebirthing plays confetti and a jingle.
local RunService = game:GetService("RunService")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local Effects = require(script.Parent.Effects)
local Screen = require(script.Parent.Screen)
local State = require(script.Parent.State)
local Ui = require(script.Parent.Ui)

local Rebirth = {}

local rebirthFunction = State.remote("Rebirth")

local MAGENTA = Color3.fromRGB(255, 60, 200)
local modal, box = Screen.modal(780, 560, "Rebirth")
Screen.title(box, "Rebirth")

local function label(parent, props)
	props.BackgroundTransparency = props.BackgroundTransparency or 1
	props.TextScaled = false
	props.ZIndex = props.ZIndex or 34
	props.Parent = parent
	return Ui.new("TextLabel", props)
end

-- Rebirth X / 8 and the segment bar -----------------------------------------------------------

local levelText = label(box, {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -46, 0, 2),
	Size = UDim2.fromOffset(260, 22),
	Font = Ui.FONT_TITLE,
	TextSize = 14,
	TextColor3 = MAGENTA,
	TextXAlignment = Enum.TextXAlignment.Right,
})
local segments = {}
local segmentRow = Ui.new("Frame", {
	Position = UDim2.fromOffset(0, 54),
	Size = UDim2.new(1, 0, 0, 10),
	BackgroundTransparency = 1,
	ZIndex = 33,
	Parent = box,
}, {
	Ui.new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}),
})
for i = 1, Config.MAX_REBIRTHS do
	segments[i] = Ui.new("Frame", {
		LayoutOrder = i,
		Size = UDim2.new(1 / Config.MAX_REBIRTHS, -6, 1, 0),
		BackgroundColor3 = Ui.GLASS_LIGHT,
		ZIndex = 33,
		Parent = segmentRow,
	}, { Ui.corner(2), Ui.stroke(Ui.LINE, 1, 0.4) })
end

-- Reset / gain cards --------------------------------------------------------------------------------

local function card(x, title, color)
	local frame = Ui.card({
		Position = UDim2.new(x, if x == 0 then 0 else 8, 0, 80),
		Size = UDim2.new(0.5, -8, 0, 196),
		ZIndex = 33,
		Parent = box,
	}, color, { Ui.padding(16) })
	label(frame, {
		Size = UDim2.new(1, 0, 0, 14),
		Font = Ui.FONT_TITLE,
		TextSize = 10,
		Text = "// " .. title,
		TextColor3 = color,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	return frame
end

-- a line in a card: an icon in a small square, a big value and a note
local function row(parent, y, icon, color)
	local chip = Ui.new("Frame", {
		Position = UDim2.fromOffset(0, y),
		Size = UDim2.fromOffset(44, 44),
		BackgroundColor3 = color:Lerp(Ui.GLASS, 0.8),
		ZIndex = 34,
		Parent = parent,
	}, { Ui.corner(6), Ui.stroke(color, 1.2, 0.2) })
	Ui.icon(icon, 24, color, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), ZIndex = 35, Parent = chip })
	local big = label(parent, {
		Position = UDim2.fromOffset(56, y),
		Size = UDim2.new(1, -56, 0, 24),
		TextSize = 21,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	local small = label(parent, {
		Position = UDim2.fromOffset(56, y + 26),
		Size = UDim2.new(1, -56, 0, 16),
		Font = Ui.FONT_MEDIUM,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Ui.MUTED,
	})
	return big, small
end

local lose = card(0, "RESETS", Ui.DANGER)
local loseCoins, loseCoinsNote = row(lose, 24, "coin", Ui.DANGER)
local keepText, keepNote = row(lose, 86, "star", Ui.SUCCESS)
label(lose, {
	AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.new(0, 0, 1, 0),
	Size = UDim2.new(1, 0, 0, 14),
	Font = Ui.FONT_MEDIUM,
	TextSize = 12,
	Text = "Worlds · pets · upgrades · Index · level all stay",
	TextColor3 = Ui.SUCCESS,
	TextXAlignment = Enum.TextXAlignment.Left,
})

local gain = card(0.5, "GAIN", Ui.SUCCESS)
local gainLuck, gainLuckNote = row(gain, 24, "clover", Ui.SUCCESS)
local gainCoins, gainCoinsNote = row(gain, 86, "coin", Ui.GOLD)
label(gain, {
	AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.new(0, 0, 1, 0),
	Size = UDim2.new(1, 0, 0, 14),
	Font = Ui.FONT_MEDIUM,
	TextSize = 12,
	Text = "Permanent · every rebirth stacks",
	TextColor3 = Ui.GOLD,
	TextXAlignment = Enum.TextXAlignment.Left,
})

-- Requirements ----------------------------------------------------------------------------------------

local reqTitle = label(box, {
	Position = UDim2.fromOffset(0, 288),
	Size = UDim2.new(1, 0, 0, 14),
	Font = Ui.FONT_TITLE,
	TextSize = 10,
	Text = "// REQUIREMENTS",
	TextColor3 = Ui.MUTED,
	TextXAlignment = Enum.TextXAlignment.Left,
})

-- a requirement card with a MET / LOCKED status chip
local function requirement(x, title, icon, color)
	local frame = Ui.card({
		Position = UDim2.new(x, if x == 0 then 0 else 8, 0, 310),
		Size = UDim2.new(0.5, -8, 0, 110),
		ZIndex = 33,
		Parent = box,
	}, color, { Ui.padding(14) })
	local chip = Ui.new("Frame", {
		Size = UDim2.fromOffset(52, 52),
		BackgroundColor3 = color:Lerp(Ui.GLASS, 0.8),
		ZIndex = 34,
		Parent = frame,
	}, { Ui.corner(6), Ui.stroke(color, 1.2, 0.2) })
	Ui.icon(icon, 30, color, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), ZIndex = 35, Parent = chip })
	label(frame, { Position = UDim2.fromOffset(64, 0), Size = UDim2.new(1, -150, 0, 14), Font = Ui.FONT_TITLE, TextSize = 9, Text = title, TextColor3 = Ui.MUTED, TextXAlignment = Enum.TextXAlignment.Left })
	local value = label(frame, { Position = UDim2.fromOffset(64, 16), Size = UDim2.new(1, -64, 0, 32), TextSize = 28, TextColor3 = color, TextXAlignment = Enum.TextXAlignment.Left })
	local note = label(frame, { Position = UDim2.fromOffset(64, 52), Size = UDim2.new(1, -64, 0, 16), Font = Ui.FONT_MEDIUM, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left })
	local status = label(frame, {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 0),
		Size = UDim2.fromOffset(78, 20),
		BackgroundTransparency = 0,
		Font = Ui.FONT_TITLE,
		TextSize = 9,
		ZIndex = 35,
	})
	Ui.corner(3).Parent = status
	local track = Ui.new("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(1, 0, 0, 5),
		BackgroundColor3 = Ui.INK,
		ZIndex = 34,
		Parent = frame,
	}, { Ui.corner(2) })
	local fill = Ui.new("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = color,
		ZIndex = 35,
		Parent = track,
	}, { Ui.corner(2) })
	return { Frame = frame, Value = value, Note = note, Status = status, Fill = fill, Color = color }
end

local cash = requirement(0, "REQUIRED CASH", "coin", Ui.GOLD)
local level = requirement(0.5, "REQUIRED LEVEL", "star", Ui.VIOLET)

local testingNote = label(box, {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, 0, 0, 288),
	Size = UDim2.fromOffset(0, 16),
	AutomaticSize = Enum.AutomaticSize.X,
	BackgroundTransparency = 0,
	BackgroundColor3 = Color3.fromRGB(255, 150, 60),
	Font = Ui.FONT_TITLE,
	TextSize = 8,
	Text = "  TEST MODE: NO CASH COST  ",
	TextColor3 = Ui.INK,
	Visible = Config.REBIRTH_FREE_FOR_TESTING,
})
Ui.corner(3).Parent = testingNote

local rebirthButton = Ui.button({
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, 0),
	Size = UDim2.new(1, 0, 0, 58),
	Radius = 8,
	Text = "REBIRTH",
	Icon = "star",
	TextSize = 20,
	ZIndex = 34,
	Parent = box,
}, function()
	Rebirth.rebirth()
end, "disabled")
local buttonScale = Ui.new("UIScale", { Parent = rebirthButton })

-- Showing state -----------------------------------------------------------------------------------

local ready = false

local function setStatus(req, met, progress)
	req.Status.Text = if met then "✓ MET" else "LOCKED"
	req.Status.BackgroundColor3 = if met then Ui.SUCCESS else Ui.GLASS
	req.Status.TextColor3 = if met then Ui.INK else Ui.DANGER
	req.Frame.Edge.Color = if met then Ui.SUCCESS else req.Color
	req.Fill.Size = UDim2.fromScale(math.clamp(progress, 0, 1), 1)
	req.Fill.BackgroundColor3 = if met then Ui.SUCCESS else req.Color
	req.Note.TextColor3 = if met then Ui.SUCCESS else Color3.fromRGB(255, 150, 170)
end

local function refresh()
	local data = State.Data
	if not data then
		return
	end
	local r = data.Rebirths
	local nextRow = Config.nextRebirth(r)
	levelText.Text = "REBIRTH " .. r .. " / " .. Config.MAX_REBIRTHS
	for i, segment in ipairs(segments) do
		segment.BackgroundColor3 = if i <= r then MAGENTA elseif i == r + 1 then MAGENTA:Lerp(Ui.GLASS, 0.7) else Ui.GLASS_LIGHT
	end

	loseCoins.Text = Config.formatNumber(data.Coins) .. " coins"
	loseCoinsNote.Text = "Your coins go back to 0"
	keepText.Text = "Everything else"
	keepNote.Text = "No worlds to unlock again"
	local after = math.min(r + 1, Config.MAX_REBIRTHS)
	gainLuck.Text = "Luck x" .. Config.REBIRTH_LUCK
	gainLuckNote.Text = string.format("Total x%.2f → x%.2f", Config.rebirthLuck(r), Config.rebirthLuck(after))
	gainCoins.Text = "Money +" .. math.floor(Config.REBIRTH_COINS * 100) .. "%"
	gainCoinsNote.Text = "Coins x" .. Config.coinMultiplier(r) .. " → x" .. Config.coinMultiplier(after)

	if not nextRow then
		reqTitle.Text = "// MAX REBIRTH REACHED"
		reqTitle.TextColor3 = Ui.GOLD
		cash.Frame.Visible, level.Frame.Visible, testingNote.Visible = false, false, false
		Ui.setText(rebirthButton, "MAX REBIRTH " .. Config.MAX_REBIRTHS .. " / " .. Config.MAX_REBIRTHS)
		Ui.setStyle(rebirthButton, "gold")
		ready = false
		return
	end
	cash.Frame.Visible, level.Frame.Visible = true, true
	testingNote.Visible = Config.REBIRTH_FREE_FOR_TESTING
	reqTitle.Text = "// REQUIREMENTS FOR REBIRTH " .. (r + 1)
	reqTitle.TextColor3 = Ui.MUTED
	local ok, hasCoins, hasLevel = Config.canRebirth(data)
	local cost = Config.rebirthCost(r)
	cash.Value.Text = if cost == 0 then "FREE" else Config.formatNumber(cost)
	cash.Note.Text = "You have " .. Config.formatNumber(data.Coins)
	setStatus(cash, hasCoins, if cost == 0 then 1 else data.Coins / cost)

	local current = data.Level or 1
	level.Value.Text = "Level " .. nextRow.Level
	level.Note.Text = "Current Level: " .. current .. " / " .. nextRow.Level
	setStatus(level, hasLevel, current / nextRow.Level)

	ready = ok
	Ui.setText(rebirthButton, if ok then "REBIRTH NOW" else "REBIRTH")
	Ui.setStyle(rebirthButton, if ok then "primary" else "disabled")
end

function Rebirth.rebirth()
	local data = State.Data
	if not data then
		return false
	end
	if not ready then
		Effects.play("Click", 0.7)
		-- shake what's missing
		for _, req in ipairs({ cash, level }) do
			local frame = req.Frame
			local home = frame.Position
			for k = 1, 4 do
				task.delay(k * 0.04, function()
					frame.Position = home + UDim2.fromOffset(if k % 2 == 0 then -6 else 6, 0)
				end)
			end
			task.delay(0.2, function()
				frame.Position = home
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

-- the button breathes when ready; the next segment blinks
RunService.RenderStepped:Connect(function()
	if not modal.Visible then
		return
	end
	local t = os.clock()
	buttonScale.Scale = if ready then 1 + (math.sin(t * 5) * 0.5 + 0.5) * 0.03 else 1
	local data = State.Data
	local nextSegment = data and segments[data.Rebirths + 1]
	if nextSegment then
		nextSegment.BackgroundTransparency = (math.sin(t * 4) * 0.5 + 0.5) * 0.6
	end
end)

State.watch(function()
	if modal.Visible then
		refresh()
	end
end)

return Rebirth
