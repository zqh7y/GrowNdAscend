-- Hatching: how a roll's result is shown. The SERVER decides every result
-- first (pet, size, the exact luck it used); this module only shows it and
-- never changes it.
--
--   THE REEL     vertical, always at the bottom of the screen (by hand and
--                on auto), over a faint panel (10% opacity) so the game
--                stays visible. Pets AND luck boosts fall from the top to
--                the bottom and ease to a stop on the result in the middle
--                slot. Every item shows its complete, exact chance for this
--                roll ("1 in 12.5K", Config.chanceOf with the server's luck,
--                size luck and world). A chip above it shows the luck boost
--                ("THIS ROLL: x4 LUCK", then "NEXT ROLL: x8 LUCK" in gold).
--   FULL MODE    a bigger reel with a silhouette moment, then the
--                centred reveal: the pet rises large with its name, exact
--                chance and power counting up; effects grow with rarity.
--                Now and then a flex roll slips a Huge or Titanic past the
--                middle ("Huge Dragon?!"); the reel still stops on the
--                pet you actually rolled.
--   HUGE/TITANIC the bush cutscene: the camera glides onto a bush ahead of
--                you, it rustles for about 2 seconds, then your pet jumps
--                out towards the screen and the reveal shows it with its
--                exact chance. Only for a result that really is Huge or
--                Titanic. On auto it plays at most once per cooldown; in
--                between, a short reveal.
--   CRAZY PULLS  (Mythic/Secret animals) their own show before the reveal.
--   RESULTS      after a compact hatch (and on auto) the pets you got float
--                big near the top of the screen, no panel: each with its
--                odds in outlined letters ("1 in 3.26K") and its name under it.
--                They stay a moment, then rise and fade (the next roll can
--                start meanwhile).
--
-- The player can't skip it (clicks and Roll presses are ignored while it
-- plays). It always cleans up (camera, bush, spinner), so rolling never
-- gets stuck. Hatch.skip() is only used internally (switching the hatch
-- mode in Settings).
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Players = game:GetService("Players")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local Effects = require(script.Parent.Effects)
local Ground = require(script.Parent.Ground)
local PetModels = require(script.Parent.PetModels)
local PetView = require(script.Parent.PetView)
local Screen = require(script.Parent.Screen)
local Ui = require(script.Parent.Ui)

local Hatch = {}

local gui = Screen.Gui
Hatch.FLEX_CHANCE = 1 / 30
local COUNT = 24 -- pets in a carousel
local LANDING = 20 -- the result's place in it

local busy = false
local skipRequested = false
local plays = 0
Hatch.Last = nil -- for the simulator: what the last full hatch did
Hatch.LastFeed = nil -- for the simulator: what the last compact hatch showed
Hatch.ForceFlex = false -- (for the simulator) make the next full hatch a flex roll

function Hatch.busy()
	return busy
end

function Hatch.skip()
	if busy then
		skipRequested = true
	end
end

local function pause(seconds)
	local start = os.clock()
	while os.clock() - start < seconds do
		if skipRequested then
			return true
		end
		task.wait()
	end
	return false
end

-- (odds read "1 in 430K" everywhere)
-- A really crazy pull: a Secret animal, a Titanic of a Rare or better one,
-- or a Huge of a Mythic or better one (by rarity tier: Config.RARITIES)
function Hatch.isCrazy(result)
	if result.Kind == "Boost" then
		return false
	end
	local tier = Config.rarityIndex(Config.PETS_BY_NAME[result.Pet].Odds)
	return tier >= 7 or (result.Size >= 3 and tier >= 3) or (result.Size == 2 and tier >= 6)
end

-- How big a moment a result is: 0 common .. 3 legendary+, 4 huge, 5 titanic,
-- 6 a crazy pull (its own very special show)
function Hatch.tier(result)
	if result.Kind == "Boost" then
		return 1
	elseif Hatch.isCrazy(result) then
		return 6
	elseif result.Size >= 3 then
		return 5
	elseif result.Size == 2 then
		return 4
	end
	local tier = Config.rarityIndex(Config.PETS_BY_NAME[result.Pet].Odds)
	if tier >= 5 then
		return 3 -- Legendary and up
	elseif tier >= 4 then
		return 2 -- Epic
	elseif tier >= 3 then
		return 1 -- Rare
	end
	return 0
end

local function accentOf(name)
	local pet, size = Config.petInfo(name)
	return if size.Index > 1 then size.Color else Config.rarity(pet.Odds).Color
end

local function clear(container)
	PetView.releaseAll(container)
	for _, child in ipairs(container:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

-- THE REEL (bottom of the screen) ---------------------------------------------------------------
-- Every roll spins here, by hand and on auto: a vertical reel where pets
-- and luck boosts fall from the top to the bottom and ease to a stop on the
-- result in the middle slot. Each item carries its complete, exact chance
-- for this roll ("1 in 12.5K"), worked out by Config.chanceOf from the very
-- luck, size luck and world the server rolled with. A chip above the reel
-- shows the luck boost ("THIS ROLL: x4 LUCK", then "NEXT ROLL: x8 LUCK").

local BOOST = Config.BOOST.Name

local function isBoost(result)
	return result.Kind == "Boost"
end

-- the luck, size luck and world a result was rolled with (the server sends
-- them with every result); results from elsewhere fall back to plain odds
local function rollContext(result)
	local pet = result.Pet and Config.PETS_BY_NAME[result.Pet]
	return {
		Luck = result.Luck or 1,
		SizeLuck = result.SizeLuck or 1,
		World = result.World or (pet and pet.World) or 1,
	}
end
Hatch.rollContext = rollContext

local function chanceText(name, ctx)
	return Config.formatChance(Config.chanceOf(name, ctx.Luck, ctx.SizeLuck, ctx.World))
end
Hatch.chanceText = chanceText

-- What passes by: mostly common pets, now and then a rarer one (and one
-- right after the result, a near miss), and luck boosts about as often as
-- they really come. Only things that can really come out of this roll are
-- used. A flex roll adds a few showstoppers a little before the result.
local function reelNames(ctx, flex)
	local chances = Config.petChances(ctx.Luck, ctx.World)
	local pool = {}
	for _, pet in ipairs(Config.PETS) do
		if pet.World <= ctx.World + 1 and chances[pet.Name] > 0 then
			table.insert(pool, pet)
		end
	end
	if #pool == 0 then
		for _, pet in ipairs(Config.PETS) do
			if chances[pet.Name] > 0 then
				table.insert(pool, pet)
			end
		end
	end
	local names, flexAt = {}, {}
	for i = 1, COUNT do
		if math.random() < Config.BOOST_CHANCE * 1.5 then
			names[i] = BOOST
		else
			local r = math.random() ^ 2.4
			if i == LANDING + 1 or math.random() < 0.06 then
				r = 0.7 + math.random() * 0.3
			end
			names[i] = pool[math.clamp(math.floor(r * #pool) + 1, 1, #pool)].Name
		end
	end
	if flex then
		local best = { "Glitch", "Galaxy Whale", "Void Serpent", "Celestial Lion", "Kraken", "Phoenix", "Dragon", "Frost Dragon" }
		local count = math.random(1, 2)
		for k = 1, count do
			local at = LANDING - 9 + (k - 1) * 4
			local name = Config.petName(best[math.random(1, #best)], if k == count and math.random() < 0.6 then 3 else 2)
			if Config.chanceOf(name, ctx.Luck, ctx.SizeLuck, ctx.World) > 0 then
				names[at] = name
				flexAt[at] = true
			end
		end
	end
	return names, flexAt
end


-- The reel's look ------------------------------------------------------------------------------
-- A soft frosted tray at the bottom of the screen. Each result is a small
-- white card: the pet (or the green luck-boost tile) on the left and its
-- complete chance in a pill on the right. Two little notches on the tray's
-- edges mark the middle slot; the card that stops there lifts and takes a
-- coloured outline (gold for rare results). The tray slides up into place
-- when a roll starts and slips away afterwards.

local EASE_OUT = TweenInfo.new(0.24, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

-- the luck boost's tile: a green rounded square with a clover and "×2"
local function boostTile(parent, size)
	local tile = Ui.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(size, size),
		BackgroundColor3 = Ui.WHITE,
		ZIndex = 55,
		Parent = parent,
	}, {
		Ui.corner(math.floor(size * 0.28)),
		Ui.new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(120, 226, 150), Color3.fromRGB(36, 168, 100)) }),
	})
	Ui.icon("clover", math.floor(size * 0.42), Ui.WHITE, { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, math.floor(size * 0.1)), ZIndex = 56, Parent = tile })
	Ui.new("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -math.floor(size * 0.06)),
		Size = UDim2.new(1, 0, 0, math.floor(size * 0.34)),
		Font = Ui.FONT_DISPLAY,
		TextScaled = false,
		TextSize = math.floor(size * 0.3),
		TextColor3 = Ui.WHITE,
		Text = "×" .. Config.BOOST.Multiplier,
		ZIndex = 56,
		Parent = tile,
	})
	return tile
end

-- One card on the reel
local function reelItem(parent, name, look, silhouette, ctx)
	local boost = name == BOOST
	local item = Ui.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, -20, 0, look.Card),
		BackgroundTransparency = 1,
		ZIndex = 52,
		Parent = parent,
	})
	local scale = Ui.new("UIScale", { Parent = item })
	local shadow = Ui.new("Frame", {
		Position = UDim2.fromOffset(0, 3),
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(16, 22, 44),
		BackgroundTransparency = 0.86,
		ZIndex = 52,
		Parent = item,
	}, { Ui.corner(16) })
	local card = Ui.new("Frame", {
		Name = "Card",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = if boost then Color3.fromRGB(236, 250, 240) else Ui.WHITE,
		ZIndex = 53,
		Parent = item,
	}, { Ui.corner(16) })
	local outline = Ui.stroke(if boost then Color3.fromRGB(150, 220, 170) else Ui.LINE, 1.5, 0)
	outline.Parent = card
	local icon = Ui.new("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 8, 0.5, 0),
		Size = UDim2.fromOffset(look.Art, look.Art),
		BackgroundTransparency = 1,
		ZIndex = 54,
		Parent = card,
	})
	local view
	if boost then
		view = boostTile(icon, look.Art - 6)
	else
		view = PetView.take(name, silhouette)
		view.Size = UDim2.fromScale(1, 1)
		view.ZIndex = 55
		view.Parent = icon
	end
	local text = chanceText(name, ctx)
	local chip = Ui.new("TextLabel", {
		Name = "Chance",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(look.Chip, look.ChipHeight),
		BackgroundColor3 = if boost then Ui.WHITE else Ui.GLASS_LIGHT,
		Font = Ui.FONT,
		TextScaled = false,
		TextWrapped = false,
		TextSize = look.Text,
		TextColor3 = if boost then Color3.fromRGB(30, 140, 80) else Ui.INK,
		TextXAlignment = Enum.TextXAlignment.Center,
		Text = text,
		ZIndex = 56,
		Parent = card,
	}, { Ui.corner(look.ChipHeight // 2) })
	local pet = not boost and Config.petInfo(name)
	return {
		Frame = item,
		Card = card,
		Shadow = shadow,
		Outline = outline,
		Scale = scale,
		View = view,
		Chip = chip,
		Chance = text,
		Name = name,
		Odds = if pet then pet.Odds else 1,
		Boost = boost,
	}
end

-- Places the reel for an offset (in slots). Item i sits ABOVE the middle
-- until the offset reaches it, so as the offset grows everything moves
-- DOWN: cards come in at the top and leave at the bottom. Cards away from
-- the middle are a touch smaller and fade towards the tray's edges.
local function layoutReel(items, offset, height, reach)
	for i, item in ipairs(items) do
		local slot = (i - 1) - offset
		local away = math.abs(slot) / reach
		local visible = away < 1
		item.Frame.Visible = visible
		item.Frame.Position = UDim2.new(0.5, 0, 0.5, -slot * height)
		if visible then
			local near = 1 - math.min(math.abs(slot), 1)
			item.Scale.Scale = 0.9 + near * 0.08
			local fade = math.clamp((away - 0.45) / 0.55, 0, 1) ^ 1.5
			item.Card.BackgroundTransparency = fade
			item.Shadow.BackgroundTransparency = 0.86 + fade * 0.14
			item.Outline.Transparency = fade
			if item.Boost then
				item.View.BackgroundTransparency = fade
			else
				item.View.ImageTransparency = fade
			end
			item.Chip.TextTransparency = fade
			item.Chip.BackgroundTransparency = fade
		end
	end
end

local REEL_SIZES = {
	compact = { Width = 280, Height = 214, Card = 60, Art = 52, Slot = 70, Reach = 1.75, Chip = 126, ChipHeight = 28, Text = 15 },
	full = { Width = 340, Height = 300, Card = 84, Art = 76, Slot = 96, Reach = 1.75, Chip = 150, ChipHeight = 34, Text = 18 },
}
-- The tray is anchored at one fixed spot and NEVER moves or resizes during a
-- spin: only the cards inside it move. (It used to slide in and out with
-- position tweens; a new roll could start while the slide-out tween was
-- still running, so the tray drifted down mid-spin and then snapped back.)
-- Its size only changes between rolls, when switching compact/full.
local BOTTOM = UDim2.new(0.5, 0, 1, -14)

local spinner = Ui.new("Frame", {
	Name = "HatchReel",
	AnchorPoint = Vector2.new(0.5, 1),
	Position = BOTTOM,
	Size = UDim2.fromOffset(280, 214),
	BackgroundColor3 = Ui.WHITE,
	BackgroundTransparency = 0.9, -- a faint tray: 10% opacity, the game stays visible
	Visible = false,
	ZIndex = 44,
	Parent = gui,
}, { Ui.corner(24) })
Hatch.Spinner = spinner -- (for the simulator)
local trayEdge = Ui.stroke(Ui.WHITE, 1.5, 0.45)
trayEdge.Parent = spinner
-- the middle-slot notches: two small rounded wedges on the tray's edges
local notches = {}
for _, side in ipairs({ 0, 1 }) do
	notches[side] = Ui.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(side, 0.5),
		Size = UDim2.fromOffset(14, 14),
		Rotation = 45,
		BackgroundColor3 = Ui.WHITE,
		ZIndex = 58,
		Parent = spinner,
	}, { Ui.corner(3), Ui.stroke(Ui.LINE, 1, 0) })
end
local spinRow = Ui.new("Frame", {
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	ClipsDescendants = true,
	ZIndex = 46,
	Parent = spinner,
}, { Ui.corner(24) })
-- the result's name, just above the tray once it lands
local spinName = Ui.new("TextLabel", {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 0, -8),
	Size = UDim2.fromOffset(420, 28),
	Font = Ui.FONT_DISPLAY,
	TextScaled = false,
	TextWrapped = false,
	TextSize = 24,
	TextColor3 = Ui.WHITE,
	TextStrokeTransparency = 0.5,
	TextStrokeColor3 = Color3.fromRGB(20, 24, 40),
	Text = "",
	ZIndex = 46,
	Parent = spinner,
})
local spinNameScale = Ui.new("UIScale", { Parent = spinName })
local flexLabel = Ui.new("TextLabel", {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 0, -8),
	Size = UDim2.fromOffset(600, 34),
	Font = Ui.FONT_DISPLAY,
	TextScaled = false,
	TextSize = 28,
	TextColor3 = Ui.WHITE,
	TextStrokeTransparency = 0.6,
	TextStrokeColor3 = Color3.fromRGB(20, 24, 40),
	Visible = false,
	ZIndex = 48,
	Parent = spinner,
})

-- The luck boost badge lives next to the Roll button (Roll.luau draws it);
-- the hatch tells it what happens: "active" (this roll uses ×N), "waiting"
-- (×N saved for the next roll) or "none"
Hatch.BoostChanged = Instance.new("BindableEvent")
local function boostState(state, multiplier)
	Hatch.BoostChanged:Fire(state, multiplier)
	return state .. " ×" .. multiplier
end

-- shows the tray (fixed in place; it just fades its background in)
local fadeToken = 0
local function showSpinner()
	fadeToken += 1 -- cancels a pending hide
	spinner.Position = BOTTOM
	spinner.AnchorPoint = Vector2.new(0.5, 1)
	if not spinner.Visible then
		spinner.Visible = true
		spinner.BackgroundTransparency = 1
		TweenService:Create(spinner, EASE_OUT, { BackgroundTransparency = 0.9 }):Play()
	end
end

-- Spins the reel onto `best` (a result already decided by the server).
-- Returns what happened (for the simulator and the reveal).
local function spin(results, best, fast, full)
	local ctx = rollContext(best)
	local tier = Hatch.tier(best)
	local resultName = if isBoost(best) then BOOST else Config.petName(best.Pet, best.Size)
	local look = REEL_SIZES[if full then "full" else "compact"]
	plays += 1
	local first = plays <= 3
	local flex = full and not isBoost(best) and (Hatch.ForceFlex or (not fast and math.random() < Hatch.FLEX_CHANCE))
	Hatch.ForceFlex = false

	clear(spinRow)
	local names, flexAt = reelNames(ctx, flex)
	local items = {}
	for i = 1, COUNT do
		local silhouette = full and i == LANDING and not isBoost(best)
		items[i] = reelItem(spinRow, if i == LANDING then resultName else names[i], look, silhouette, ctx)
		items[i].Flex = flexAt[i]
	end
	-- (the size only changes when compact/full is switched, never mid-spin)
	spinner.Size = UDim2.fromOffset(look.Width, look.Height)
	spinName.Text = ""
	flexLabel.Visible = false
	for _, notch in pairs(notches) do
		notch.BackgroundColor3 = Ui.WHITE
	end
	-- the boost this roll uses (if any) turns "active" on the badge
	local multiplier = best.Multiplier or 1
	local badgeAtStart = boostState(if multiplier > 1 then "active" else "none", multiplier)
	layoutReel(items, 2, look.Slot, look.Reach)
	showSpinner()

	-- fast at first, a smooth slow-down onto the result
	local startOffset, finalOffset = 2, LANDING - 1
	local duration = (if fast then 0.75 elseif first then 1.8 else 1.25) + (if tier >= 3 and not fast then 0.4 else 0)
	local progress, previous = 0, os.clock()
	local lastOffset, lastIndex = nil, -1
	local speedEarly, speedLate = 0, math.huge
	local flexShown, flexNames = 0, {}
	local watch = items[LANDING]
	local xs, ys = {}, {}
	local trayMoved = 0
	while true do
		local now = os.clock()
		local dt = now - previous
		previous = now
		local rate = 1
		local offsetNow = lastOffset or startOffset
		for i, item in ipairs(items) do
			if item.Flex and math.abs((i - 1) - offsetNow) < 0.6 then
				rate = 0.3 -- linger on a showstopper for a moment
				if not item.Announced then
					item.Announced = true
					flexShown += 1
					table.insert(flexNames, item.Name)
					flexLabel.Text = item.Name .. "?!"
					flexLabel.TextColor3 = accentOf(item.Name)
					flexLabel.Visible = true
					Effects.play("Coin", 1.8)
					task.delay(0.7, function()
						flexLabel.Visible = false
					end)
				end
			end
		end
		progress += dt / duration * rate
		if skipRequested then
			progress = 1
		end
		local u = math.clamp(progress, 0, 1)
		local offset = startOffset + (finalOffset - startOffset) * (1 - (1 - u) ^ 3.2)
		if lastOffset then
			local speed = math.abs(offset - lastOffset) * look.Slot
			if u < 0.25 then
				speedEarly = math.max(speedEarly, speed)
			elseif u > 0.85 and u < 1 then
				speedLate = math.min(speedLate, speed)
			end
		end
		lastOffset = offset
		layoutReel(items, offset, look.Slot, look.Reach)
		-- (for the simulator) how the result's card moves on screen, and
		-- that the tray itself stays exactly where it is
		table.insert(xs, watch.Frame.Position.X.Offset)
		table.insert(ys, watch.Frame.Position.Y.Offset)
		local p = spinner.Position
		if p.X.Scale ~= 0.5 or p.X.Offset ~= 0 or p.Y.Scale ~= 1 or p.Y.Offset ~= -14 or spinner.Size.Y.Offset ~= look.Height then
			trayMoved += 1
		end
		local index = math.floor(offset + 0.5)
		if index ~= lastIndex then
			lastIndex = index
			local passing = items[index + 1]
			Effects.play("Roll", 0.9 + u * 0.6 + (if passing and Config.rarityIndex(passing.Odds) >= 3 then 0.25 else 0), 0.02)
		end
		if u >= 1 then
			break
		end
		task.wait()
	end
	flexLabel.Visible = false

	-- the result settles: a little lift, a coloured outline, the notches take its colour
	local landed = items[LANDING]
	local accent = if isBoost(best) then Ui.SUCCESS elseif tier >= 4 then Config.SIZES[best.Size].Color elseif tier >= 3 then Ui.GOLD else Ui.BLUE
	landed.Scale.Scale = 1.1
	TweenService:Create(landed.Scale, TweenInfo.new(0.32, Enum.EasingStyle.Back), { Scale = 1.03 }):Play()
	landed.Outline.Color = accent
	landed.Outline.Thickness = if tier >= 3 then 3 else 2
	TweenService:Create(landed.Shadow, EASE_OUT, { Position = UDim2.fromOffset(0, 7), BackgroundTransparency = 0.8 }):Play()
	for _, notch in pairs(notches) do
		notch.BackgroundColor3 = accent
	end
	local extra = #results - 1
	spinName.Text = if full and not isBoost(best) then "" else resultName .. (if extra > 0 then "  +" .. extra else "")
	spinName.TextColor3 = if isBoost(best) then Color3.fromRGB(150, 240, 170) elseif best.Size > 1 then Config.SIZES[best.Size].Color else Ui.WHITE
	spinNameScale.Scale = 0.85
	TweenService:Create(spinNameScale, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	-- the boost waiting for the next roll ("none" if this roll used it up)
	local nextMultiplier = best.NextMultiplier or 1
	local badgeAfter = boostState(if nextMultiplier > 1 then "waiting" else "none", nextMultiplier)
	if nextMultiplier > multiplier then
		Effects.play("Coin", 1.6)
	end
	if isBoost(best) then
		Effects.jingle(3)
	elseif not full then
		if tier >= 2 and tier < 4 then
			Effects.jingle(2)
		elseif tier < 2 then
			Effects.play("Coin", 1.3, 0.05)
		end
	end

	-- (for the simulator) the reel only moved down, never sideways
	local sideways, down, up = 0, 0, 0
	for k = 2, #ys do
		sideways = math.max(sideways, math.abs(xs[k] - xs[1]))
		if ys[k] > ys[k - 1] + 1e-6 then
			down += 1
		elseif ys[k] < ys[k - 1] - 1e-6 then
			up += 1
		end
	end
	local shown = {}
	for _, item in ipairs(items) do
		table.insert(shown, {
			Name = item.Name,
			Text = item.Chance,
			Label = item.Chip.Text,
			Width = item.Chip.Size.X.Offset,
			TextSize = item.Chip.TextSize,
			Wrapped = item.Chip.TextWrapped,
			Scaled = item.Chip.TextScaled,
		})
	end
	return {
		Items = items,
		Landed = landed,
		LandedExactly = math.abs(lastOffset - finalOffset) < 0.01,
		Result = resultName,
		SpeedEarly = speedEarly,
		SpeedLate = speedLate,
		Flex = flex,
		FlexShown = flexShown,
		FlexNames = flexNames,
		Chances = shown,
		ResultChance = landed.Chance,
		Context = ctx,
		LuckChip = badgeAtStart,
		NextChip = badgeAfter,
		First = first,
		Tier = tier,
		Motion = { Sideways = sideways, Down = down, Up = up, TrayMoved = trayMoved },
	}
end

-- the tray hides after a roll: the cards fade, then it's hidden (it never
-- moves; a roll starting meanwhile keeps it)
local function hideSpinner()
	flexLabel.Visible = false
	fadeToken += 1
	local token = fadeToken
	if not spinner.Visible then
		clear(spinRow)
		return
	end
	task.delay(0.12, function()
		if token == fadeToken then
			spinner.Visible = false
			clear(spinRow)
		end
	end)
end

-- Kept for older callers
function Hatch.feed(results)
	task.spawn(Hatch.compact, results, true)
end

-- FULL ------------------------------------------------------------------------------------------

local shade = Ui.new("TextButton", {
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.fromRGB(14, 18, 34),
	BackgroundTransparency = 1,
	AutoButtonColor = false,
	Text = "",
	Visible = false,
	ZIndex = 50,
	Parent = gui,
})
Hatch.Shade = shade -- (for the simulator)
-- (clicking it does nothing: a roll can't be skipped)
local stage = Ui.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.48),
	Size = UDim2.fromOffset(900, 600),
	BackgroundTransparency = 1,
	ZIndex = 51,
	Parent = shade,
})
local hint = Ui.new("TextLabel", {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -10),
	Size = UDim2.fromOffset(300, 20),
	Font = Ui.FONT_MEDIUM,
	TextScaled = false,
	TextSize = 14,
	Text = "",
	TextColor3 = Ui.WHITE,
	TextTransparency = 0.35,
	ZIndex = 52,
	Parent = stage,
})
-- the reveal
local reveal = Ui.new("Frame", {
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	Visible = false,
	ZIndex = 52,
	Parent = stage,
})
local glowOuter = Ui.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.38),
	Size = UDim2.fromOffset(360, 360),
	BackgroundColor3 = Ui.WHITE,
	BackgroundTransparency = 0.9,
	ZIndex = 52,
	Parent = reveal,
}, { Ui.corner(0.5) })
local glowInner = Ui.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.38),
	Size = UDim2.fromOffset(230, 230),
	BackgroundColor3 = Ui.WHITE,
	BackgroundTransparency = 0.82,
	ZIndex = 52,
	Parent = reveal,
}, { Ui.corner(0.5) })
local rays = Ui.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.38),
	Size = UDim2.fromOffset(560, 560),
	BackgroundTransparency = 1,
	Visible = false,
	ZIndex = 52,
	Parent = reveal,
})
local rayFrames = {}
for k = 0, 5 do
	rayFrames[k] = Ui.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0, 70, 1, 0),
		Rotation = k * 30,
		BackgroundColor3 = Ui.WHITE,
		BackgroundTransparency = 0.88,
		ZIndex = 52,
		Parent = rays,
	}, { Ui.new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.2), NumberSequenceKeypoint.new(1, 1) }) }) })
end
local petHolder = Ui.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.38),
	Size = UDim2.fromOffset(280, 280),
	BackgroundTransparency = 1,
	ZIndex = 54,
	Parent = reveal,
})
local petScale = Ui.new("UIScale", { Parent = petHolder })
Ui.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(0.5, 0, 0.38, 128),
	Size = UDim2.fromOffset(170, 22),
	BackgroundColor3 = Color3.fromRGB(10, 14, 30),
	BackgroundTransparency = 0.7,
	ZIndex = 53,
	Parent = reveal,
}, { Ui.corner(0.5) })
local sizeChip = Ui.new("TextLabel", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.08),
	Size = UDim2.fromOffset(0, 40),
	AutomaticSize = Enum.AutomaticSize.X,
	BackgroundTransparency = 0,
	Font = Ui.FONT_DISPLAY,
	TextScaled = false,
	TextSize = 28,
	TextColor3 = Ui.WHITE,
	Text = "",
	Visible = false,
	ZIndex = 56,
	Parent = reveal,
}, { Ui.corner(20), Ui.new("UIPadding", { PaddingLeft = UDim.new(0, 22), PaddingRight = UDim.new(0, 22) }) })
local sizeScale = Ui.new("UIScale", { Parent = sizeChip })
local nameText = Ui.new("TextLabel", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.66),
	Size = UDim2.fromOffset(800, 52),
	Font = Ui.FONT_DISPLAY,
	TextScaled = false,
	TextSize = 46,
	TextColor3 = Ui.WHITE,
	TextStrokeTransparency = 0.65,
	TextStrokeColor3 = Color3.fromRGB(20, 24, 40),
	ZIndex = 56,
	Parent = reveal,
})
local rarityChip = Ui.new("TextLabel", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.74),
	Size = UDim2.fromOffset(0, 26),
	AutomaticSize = Enum.AutomaticSize.X,
	BackgroundTransparency = 0,
	Font = Ui.FONT,
	TextScaled = false,
	TextSize = 14,
	TextColor3 = Ui.WHITE,
	ZIndex = 56,
	Parent = reveal,
}, { Ui.corner(13), Ui.new("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14) }) })
local powerText = Ui.new("TextLabel", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.8),
	Size = UDim2.fromOffset(600, 26),
	Font = Ui.FONT,
	TextScaled = false,
	TextSize = 20,
	TextColor3 = Ui.WHITE,
	TextTransparency = 0.1,
	ZIndex = 56,
	Parent = reveal,
})
local newChip = Ui.new("TextLabel", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(0.5, 120, 0.2, 0),
	Size = UDim2.fromOffset(0, 24),
	AutomaticSize = Enum.AutomaticSize.X,
	BackgroundTransparency = 0,
	BackgroundColor3 = Ui.SUCCESS,
	Font = Ui.FONT,
	TextScaled = false,
	TextSize = 13,
	TextColor3 = Ui.WHITE,
	Text = "NEW",
	Visible = false,
	ZIndex = 57,
	Parent = reveal,
}, { Ui.corner(12), Ui.new("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }) })
local extras = Ui.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.fromScale(0.5, 0.85),
	Size = UDim2.fromOffset(600, 70),
	BackgroundTransparency = 1,
	ZIndex = 55,
	Parent = reveal,
}, {
	Ui.new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}),
})

-- a few soft sparkles drifting out of the pet
local function sparkle(count, colors, spread)
	for k = 1, count do
		local a = math.random() * math.pi * 2
		local s = math.random(6, 12)
		local spark = Ui.new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.38),
			Size = UDim2.fromOffset(s, s),
			BackgroundColor3 = colors[(k % #colors) + 1],
			ZIndex = 55,
			Parent = reveal,
		}, { Ui.corner(0.5) })
		local d = spread * (0.6 + math.random() * 0.5)
		TweenService:Create(spark, TweenInfo.new(1 + math.random() * 0.4, Enum.EasingStyle.Sine), {
			Position = UDim2.new(0.5, math.cos(a) * d, 0.38, math.sin(a) * d),
			BackgroundTransparency = 1,
		}):Play()
		task.delay(1.5, function()
			spark:Destroy()
		end)
	end
end

local function cameraKick(strength)
	if Ui.reduced() then
		return
	end
	local camera = workspace.CurrentCamera
	if camera and camera.FieldOfView then
		local fov = camera.FieldOfView
		camera.FieldOfView = fov - strength
		TweenService:Create(camera, TweenInfo.new(0.6, Enum.EasingStyle.Sine), { FieldOfView = fov }):Play()
	end
end

-- THE CRAZY PULL: the screen goes dark, three heartbeats with growing
-- rings of light and teasing words, the screen trembles and cracks open
-- with rainbow light, then a white flash and a confetti storm. Then the pet
-- rises slowly under "INSANE ...!" with a rainbow glow, firework sparkles
-- and jingles for a long hold. It plays even when auto rolling.
local flash = Ui.new("Frame", {
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Ui.WHITE,
	BackgroundTransparency = 1,
	ZIndex = 62,
	Parent = shade,
})
local teaser = Ui.new("TextLabel", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.42),
	Size = UDim2.fromOffset(900, 60),
	Font = Ui.FONT_DISPLAY,
	TextScaled = false,
	TextSize = 44,
	TextColor3 = Ui.WHITE,
	Text = "",
	ZIndex = 61,
	Parent = shade,
})
local teaserScale = Ui.new("UIScale", { Parent = teaser })

local function rainbowAt(t)
	return Color3.fromHSV(t % 1, 0.55, 1)
end

local function crazyIntro()
	Hatch.Last = Hatch.Last or {}
	Hatch.Last.Crazy = true
	reveal.Visible = false
	shade.Visible = true
	TweenService:Create(shade, TweenInfo.new(0.4), { BackgroundTransparency = 0.04 }):Play()
	local temporary = {}
	local function cleanup()
		teaser.Text = ""
		for _, g in ipairs(temporary) do
			g:Destroy()
		end
		stage.Position = UDim2.fromScale(0.5, 0.48)
	end
	-- three heartbeats
	for beat, words in ipairs({ "...", "wait...", "NO WAY..." }) do
		Effects.play("Roll", 0.45 + beat * 0.12)
		local stroke = Ui.stroke(rainbowAt(beat / 3), 6)
		local ring = Ui.new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.42),
			Size = UDim2.fromOffset(40, 40),
			BackgroundTransparency = 1,
			ZIndex = 60,
			Parent = shade,
		}, { Ui.corner(0.5), stroke })
		table.insert(temporary, ring)
		local reach = 260 + beat * 180
		TweenService:Create(ring, TweenInfo.new(0.75, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = UDim2.fromOffset(reach, reach) }):Play()
		TweenService:Create(stroke, TweenInfo.new(0.75), { Transparency = 1 }):Play()
		teaser.Text = words
		teaser.TextColor3 = rainbowAt(beat / 3)
		teaserScale.Scale = 1.6
		TweenService:Create(teaserScale, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Scale = 1 + beat * 0.12 }):Play()
		if pause(0.8 - beat * 0.08) then
			cleanup()
			return
		end
	end
	-- the screen trembles and cracks open with rainbow light
	teaser.Text = ""
	local cracks = {}
	for k = 0, 11 do
		local crack = Ui.new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5, 0.42),
			Size = UDim2.fromOffset(10, 0),
			Rotation = k * 30 + math.random(-8, 8),
			BackgroundColor3 = rainbowAt(k / 12),
			ZIndex = 59,
			Parent = shade,
		}, { Ui.corner(5) })
		table.insert(temporary, crack)
		table.insert(cracks, crack)
		TweenService:Create(crack, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Size = UDim2.fromOffset(10 + k % 3 * 6, 1100) }):Play()
	end
	Effects.jingle(3)
	local start = os.clock()
	while os.clock() - start < 0.9 do
		local strength = (os.clock() - start) / 0.9 * 10
		if not Ui.reduced() then
			stage.Position = UDim2.new(0.5, math.random(-10, 10) * strength / 10, 0.48, math.random(-10, 10) * strength / 10)
		end
		for i, crack in ipairs(cracks) do
			crack.BackgroundColor3 = rainbowAt(os.clock() * 0.8 + i / 12)
		end
		if skipRequested then
			break
		end
		task.wait()
	end
	-- the flash
	cleanup()
	flash.BackgroundTransparency = 0
	TweenService:Create(flash, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 1 }):Play()
	Effects.confetti(160)
	Effects.jingle(7)
	cameraKick(8)
end

local function showReveal(result, fast, others, opts)
	local pet, size = Config.PETS_BY_NAME[result.Pet], Config.SIZES[result.Size]
	local rarity = Config.rarity(pet.Odds)
	local tier = Hatch.tier(result)
	local accent = if result.Size > 1 then size.Color else rarity.Color
	local name = Config.petName(result.Pet, result.Size)
	if tier >= 6 and not (opts and opts.NoIntro) then
		crazyIntro()
		skipRequested = false
	end

	clear(petHolder)
	local view = PetView.take(name)
	view.Size = UDim2.fromScale(1, 1)
	view.ZIndex = 54
	view.Parent = petHolder
	reveal.Visible = true

	glowInner.BackgroundColor3 = accent
	glowOuter.BackgroundColor3 = accent
	glowInner.BackgroundTransparency = if tier >= 2 then 0.72 else 0.82
	glowOuter.BackgroundTransparency = if tier >= 2 then 0.86 else 0.92
	rays.Visible = tier >= 2
	sizeChip.Visible = result.Size > 1 or tier >= 6
	sizeChip.Text = if tier >= 6
		then "INSANE " .. (if result.Size > 1 then string.upper(size.Name) else "PULL") .. "!"
		else string.upper(size.Name)
	sizeChip.BackgroundColor3 = accent
	newChip.Visible = result.First or (result.Size > 1 and result.FirstOfSize) or false
	newChip.Text = if result.First then "NEW" else "NEW " .. string.upper(size.Name)
	nameText.Text = name
	hint.Visible = false
	-- the exact chance this roll had (the same numbers the server rolled with)
	rarityChip.Text = chanceText(name, rollContext(result))
	rarityChip.BackgroundColor3 = rarity.Color
	local power = Config.petPower(name)
	powerText.Text = "0 power"

	clear(extras)
	for i, other in ipairs(others or {}) do
		local otherName = Config.petName(other.Pet, other.Size)
		local mini = Ui.new("Frame", { LayoutOrder = i, Size = UDim2.fromOffset(60, 60), BackgroundTransparency = 1, ZIndex = 55, Parent = extras })
		local miniView = PetView.take(otherName)
		miniView.Size = UDim2.fromScale(1, 1)
		miniView.ZIndex = 55
		miniView.Parent = mini
	end

	-- the rise: quick for most, slow and grand for a Titanic
	if tier >= 6 then
		-- the slowest, grandest rise
		petScale.Scale = 0.05
		TweenService:Create(petScale, TweenInfo.new(1.6, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), { Scale = 1.15 }):Play()
		TweenService:Create(shade, TweenInfo.new(0.6), { BackgroundTransparency = 0.25 }):Play()
	elseif tier >= 5 and not fast then
		petScale.Scale = 0.1
		TweenService:Create(petScale, TweenInfo.new(1.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Scale = 1 }):Play()
		TweenService:Create(shade, TweenInfo.new(0.6), { BackgroundTransparency = 0.35 }):Play()
		cameraKick(4)
	else
		petScale.Scale = 0.35
		TweenService:Create(petScale, TweenInfo.new(if tier >= 4 then 0.55 else 0.35, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	end
	sizeScale.Scale = 1.5
	TweenService:Create(sizeScale, TweenInfo.new(0.4, Enum.EasingStyle.Back), { Scale = 1 }):Play()

	-- calm effects that grow with rarity
	local hold
	if tier <= 0 then
		Effects.play("Coin", 1.3)
		hold = 0.6
	elseif tier == 1 then
		sparkle(6, { Ui.WHITE, accent }, 150)
		Effects.jingle(2)
		hold = 0.9
	elseif tier == 2 then
		sparkle(10, { Ui.WHITE, accent }, 180)
		Effects.jingle(3)
		hold = 1.2
	elseif tier == 3 then
		sparkle(14, { Ui.WHITE, accent, Ui.GOLD }, 210)
		Effects.jingle(5)
		hold = 1.7
	elseif tier == 4 then
		sparkle(18, { Ui.GOLD, Ui.WHITE }, 240)
		Effects.jingle(6)
		Effects.confetti(40)
		cameraKick(3)
		hold = 2.3
	else
		sparkle(24, { Color3.fromRGB(255, 120, 120), Color3.fromRGB(255, 210, 90), Color3.fromRGB(110, 210, 255), Color3.fromRGB(190, 140, 255), Ui.WHITE }, 270)
		Effects.jingle(7)
		task.delay(0.8, Effects.jingle, 7)
		Effects.confetti(90)
		hold = 3.2
	end
	if tier >= 6 then
		task.delay(1.2, Effects.jingle, 7)
		task.delay(2.4, Effects.confetti, 100)
		hold = 5
	end
	if fast then
		hold = if tier >= 6 then 3.5 elseif tier >= 5 then 2 elseif tier == 4 then 1.4 else 0.5
	end
	Hatch.Last = Hatch.Last or {}
	Hatch.Last.Name, Hatch.Last.Tier, Hatch.Last.Size = name, tier, result.Size
	Hatch.Last.Rays, Hatch.Last.Banner, Hatch.Last.Hold = rays.Visible, if sizeChip.Visible then sizeChip.Text else "", hold
	Hatch.Last.Revealed = nameText.Text
	Hatch.Last.RevealChance = rarityChip.Text

	local shownAt = os.clock()
	local nextBurst = os.clock() + 0.5
	local spin = RunService.RenderStepped:Connect(function(dt)
		rays.Rotation += dt * (if tier >= 6 then 40 else 12)
		if tier >= 6 then
			-- the name shimmers and fireworks keep popping
			nameText.TextColor3 = Color3.fromHSV((os.clock() * 0.4) % 1, 0.35, 1)
			for _, ray in pairs(rayFrames) do
				ray.BackgroundColor3 = Color3.fromHSV((os.clock() * 0.3 + ray.Rotation / 180) % 1, 0.5, 1)
			end
			if os.clock() >= nextBurst then
				nextBurst = os.clock() + 0.55
				sparkle(10, { Color3.fromHSV(math.random(), 0.6, 1), Ui.WHITE, Ui.GOLD }, 320)
			end
		end
		-- the power counts up quickly
		local u = math.clamp((os.clock() - shownAt) / 0.6, 0, 1)
		powerText.Text = Config.formatNumber(math.floor(power * (1 - (1 - u) ^ 3))) .. " power"
		if tier >= 5 then
			local rainbow = Color3.fromHSV((os.clock() * 0.25) % 1, 0.45, 1)
			glowInner.BackgroundColor3 = rainbow
			glowOuter.BackgroundColor3 = rainbow
			sizeChip.BackgroundColor3 = rainbow
		end
	end)
	skipRequested = false
	pause(hold)
	spin:Disconnect()
	nameText.TextColor3 = Ui.WHITE
	for _, ray in pairs(rayFrames) do
		ray.BackgroundColor3 = Ui.WHITE
	end
	powerText.Text = Config.formatNumber(power) .. " power"
	Hatch.Last.Power = powerText.Text
end

-- THE BUSH CUTSCENE (Huge and Titanic only) ---------------------------------------------------------
-- Only for a Huge or Titanic the server really gave you. The camera glides
-- onto a bush a little ahead of you, the bush rustles harder and harder for
-- about 2 seconds, then your pet (built from the exact result) bursts out
-- and jumps towards the screen, and the reveal shows it with its exact
-- chance. It can't be skipped. While auto rolling it plays at
-- most once every CUTSCENE_COOLDOWN seconds; in between, a short reveal.
Hatch.CUTSCENE_COOLDOWN = 90
Hatch.LastCutscene = nil -- for the simulator
local lastCutscene = -math.huge

local caption = Ui.new("TextLabel", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.2),
	Size = UDim2.fromOffset(700, 40),
	Font = Ui.FONT_DISPLAY,
	TextScaled = false,
	TextSize = 30,
	TextColor3 = Ui.WHITE,
	TextStrokeTransparency = 0.55,
	TextStrokeColor3 = Color3.fromRGB(20, 24, 40),
	Text = "",
	Visible = false,
	ZIndex = 58,
	Parent = gui,
})
local captionHint = Ui.new("TextLabel", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(0.5, 0, 0.2, 30),
	Size = UDim2.fromOffset(400, 20),
	Font = Ui.FONT_MEDIUM,
	TextScaled = false,
	TextSize = 14,
	TextColor3 = Ui.WHITE,
	TextTransparency = 0.25,
	TextStrokeTransparency = 0.7,
	Text = "",
	Visible = false,
	ZIndex = 58,
	Parent = gui,
})

local function ball(parent, position, diameter, color)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Shape = Enum.PartType.Ball
	p.Material = Enum.Material.SmoothPlastic
	p.Size = Vector3.one * diameter
	p.Color = color
	p.CFrame = CFrame.new(position)
	p.Parent = parent
	return p
end

local function bushCutscene(result, name)
	local camera = workspace.CurrentCamera
	local character = Players.LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not camera or not root then
		return false
	end
	local size = Config.SIZES[result.Size]
	local s = math.max(1, size.Scale * 0.7)
	-- a spot a little ahead of the player, on the ground, inside the map
	local look = root.CFrame.LookVector
	local flat = Vector3.new(look.X, 0, look.Z)
	flat = if flat.Magnitude > 0.1 then flat.Unit else Vector3.new(0, 0, -1)
	local guess = root.Position + flat * (12 + 4 * s)
	local spotZ = math.clamp(guess.Z, -30, 30)
	local groundY = Ground.at(guess.X, spotZ, root.Position.Y + 40, 120) or (root.Position.Y - 3)
	local spot = Vector3.new(guess.X, groundY, spotZ)
	local stats = { Name = name, Bush = true, Shake = 0, Jumped = false, Skipped = false }
	Hatch.LastCutscene = stats

	-- the bush: leafy clumps with a few berries
	local bush = Instance.new("Model")
	bush.Name = "HatchBush"
	local parts, homes = {}, {}
	local greens = { Color3.fromRGB(86, 176, 74), Color3.fromRGB(70, 156, 64), Color3.fromRGB(104, 194, 86) }
	for k, o in ipairs({ { -1.6, 1.2, 0.3, 2.8 }, { 1.5, 1.1, 0.2, 2.6 }, { 0, 1.8, 0, 3.2 }, { -0.7, 0.9, -1.0, 2.3 }, { 0.9, 0.9, -0.9, 2.2 }, { 0, 2.8, 0.4, 2.0 }, { 2.2, 0.8, 0.9, 1.8 }, { -2.3, 0.8, 0.8, 1.8 } }) do
		local p = ball(bush, spot + Vector3.new(o[1], o[2], o[3]) * s, o[4] * s, greens[(k % 3) + 1])
		table.insert(parts, p)
		homes[p] = p.Position
	end
	for k, o in ipairs({ { -0.9, 1.5, -1.5 }, { 0.6, 2.1, -1.4 }, { 1.4, 1.0, -1.2 }, { -0.2, 0.8, -1.7 } }) do
		local p = ball(bush, spot + Vector3.new(o[1], o[2], o[3]) * s, 0.36 * s, if k % 2 == 0 then Color3.fromRGB(235, 70, 90) else Color3.fromRGB(150, 90, 230))
		table.insert(parts, p)
		homes[p] = p.Position
	end
	bush.Parent = workspace

	local saved = { Type = camera.CameraType, CFrame = camera.CFrame, Fov = camera.FieldOfView }
	local model
	local ok, err = pcall(function()
		camera.CameraType = Enum.CameraType.Scriptable
		local focus = spot + Vector3.new(0, 1.6 * s, 0)
		local camGoal = CFrame.lookAt(focus - flat * (12 * s) + Vector3.new(0, 3.5 * s, 0), focus)
		-- the camera glides in
		local start, from = os.clock(), camera.CFrame
		while os.clock() - start < 0.6 and not skipRequested and not Ui.reduced() do
			local u = (os.clock() - start) / 0.6
			camera.CFrame = from:Lerp(camGoal, 1 - (1 - u) ^ 3)
			task.wait()
		end
		camera.CFrame = camGoal
		caption.Text = "Something is in the bushes..."
		caption.Visible = true
		captionHint.Visible = true

		-- the bush shakes, harder and harder (about 2 seconds)
		local shakeStart, nextRustle = os.clock(), 0
		while os.clock() - shakeStart < 2 and not skipRequested do
			local t = os.clock() - shakeStart
			local amplitude = (0.04 + t * 0.13) * s
			for i, p in ipairs(parts) do
				local offset = Vector3.new(math.sin(t * 38 + i * 1.7), math.abs(math.sin(t * 29 + i)) * 0.6, math.cos(t * 33 + i * 2.3)) * amplitude
				p.CFrame = CFrame.new(homes[p] + offset)
			end
			if t >= nextRustle then
				nextRustle = t + 0.3 - t * 0.08
				Effects.play("Roll", 0.5 + t * 0.2, 0.02)
			end
			task.wait()
		end
		stats.Shake = os.clock() - shakeStart
		caption.Visible = false

		-- the pet bursts out and jumps towards the screen
		model = PetModels.build(name)
		if size.Scale ~= 1 then
			model:ScaleTo(size.Scale)
		end
		local glow = Instance.new("PointLight")
		glow.Color = Color3.fromRGB(255, 236, 190)
		glow.Range = 12 * s
		glow.Brightness = 2
		glow.Parent = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
		model.Parent = workspace
		local camPos = camGoal.Position
		local jumpFrom = spot + Vector3.new(0, 1.2 * s, 0)
		local jumpTo = camPos + (jumpFrom - camPos).Unit * (5 + 3 * size.Scale)
		Effects.jingle(6)
		Effects.play("Coin", 0.8)
		local jumpStart = os.clock()
		while true do
			local u = math.clamp((os.clock() - jumpStart) / 0.75, 0, 1)
			if skipRequested then
				u = 1
			end
			local e = 1 - (1 - u) ^ 2
			local position = jumpFrom:Lerp(jumpTo, e) + Vector3.new(0, math.sin(u * math.pi) * 3 * s, 0)
			model:PivotTo(CFrame.lookAt(position, camPos) * CFrame.Angles(0, 0, math.sin(u * math.pi * 2) * 0.25))
			-- the leaves burst apart
			for i, p in ipairs(parts) do
				local away = (homes[p] - spot)
				away = Vector3.new(away.X, 0, away.Z)
				away = if away.Magnitude > 0.01 then away.Unit else Vector3.new(math.cos(i), 0, math.sin(i))
				p.CFrame = CFrame.new(homes[p] + away * e * 4 * s + Vector3.new(0, math.sin(u * math.pi) * 1.5 * s, 0))
				p.Transparency = e * 0.8
			end
			if u >= 1 then
				break
			end
			task.wait()
		end
		stats.Jumped = true
		cameraKick(6)
		if not skipRequested then
			pause(0.45)
		end
	end)
	stats.Skipped = skipRequested
	caption.Visible = false
	captionHint.Visible = false
	camera.CameraType = saved.Type or Enum.CameraType.Custom
	camera.CFrame = saved.CFrame
	camera.FieldOfView = saved.Fov or 70
	bush:Destroy()
	if model then
		model:Destroy()
	end
	if not ok then
		warn("[Hatch] cutscene: " .. tostring(err))
	end
	return true
end

local function openShade(transparency)
	shade.Visible = true
	shade.BackgroundTransparency = transparency or 0.55
end

-- The big moment for a special result: the bush cutscene for a Huge or
-- Titanic (abbreviated on auto during the cooldown), the crazy intro for a
-- crazy normal pet, then the reveal
local function special(best, others, fast, auto)
	local name = Config.petName(best.Pet, best.Size)
	local abbreviated = auto and os.clock() - lastCutscene < Hatch.CUTSCENE_COOLDOWN
	local played = false
	if not abbreviated then
		if auto then
			lastCutscene = os.clock()
		end
		if best.Size >= 2 then
			-- a transparent layer over the world while it plays
			openShade(1)
			played = bushCutscene(best, name)
		end
	else
		Hatch.LastCutscene = { Name = name, Bush = false, Abbreviated = true }
	end
	skipRequested = false
	openShade(0.55)
	Screen.blur(true)
	showReveal(best, fast or abbreviated, others, { NoIntro = played or abbreviated })
	Screen.blur(false)
end

local function finish()
	flash.BackgroundTransparency = 1
	teaser.Text = ""
	stage.Position = UDim2.fromScale(0.5, 0.48)
	shade.Visible = false
	reveal.Visible = false
	caption.Visible = false
	captionHint.Visible = false
	hideSpinner()
	clear(petHolder)
	clear(extras)
	busy = false
	skipRequested = false
end

-- THE FLOATING RESULTS -------------------------------------------------------------------------

Hatch.ROW_POSITION = UDim2.new(0.5, 0, 1, -12) -- the rolls sit at the bottom of the screen
local resultsRow = Ui.new("Frame", {
	Name = "Results",
	AnchorPoint = Vector2.new(0.5, 1),
	Position = Hatch.ROW_POSITION,
	Size = UDim2.fromOffset(0, 200),
	AutomaticSize = Enum.AutomaticSize.X,
	BackgroundTransparency = 1,
	ZIndex = 20,
	Parent = gui,
}, {
	Ui.new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}),
})
Hatch.ResultsRow = resultsRow
Hatch.LastResults = nil -- for the simulator: { Names, Odds }
local resultsId = 0

-- One slot in the row: the pet (or the luck-boost tile), its odds and its name
local function makeSlot(order)
	local holder = Ui.new("Frame", {
		Name = "Slot" .. order,
		LayoutOrder = order,
		Size = UDim2.fromOffset(160, 200),
		BackgroundTransparency = 1,
		ZIndex = 20,
		Parent = resultsRow,
	})
	-- a window the pets scroll through, top to bottom (it clips them)
	local viewHolder = Ui.new("Frame", {
		Name = "Pet",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0),
		Size = UDim2.fromOffset(150, 132),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		ZIndex = 21,
		Parent = holder,
	})
	local pop = Ui.new("UIScale", { Parent = viewHolder })
	local odds = Ui.chunky({
		Name = "Odds",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 128),
		Size = UDim2.new(1, 30, 0, 36),
		TextSize = 34,
		Colors = { Ui.WHITE, Ui.WHITE },
		Outline = 3,
		ZIndex = 22,
		Parent = holder,
	})
	local label = Ui.chunky({
		Name = "PetName",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 164),
		Size = UDim2.new(1, 30, 0, 28),
		TextSize = 24,
		Outline = 2.5,
		ZIndex = 22,
		Parent = holder,
	})
	return { Holder = holder, View = viewHolder, Pop = pop, Odds = odds, Name = label, Shows = nil }
end

-- The pet you hatched shines: light rays turning slowly behind it, a soft
-- glow and sparkles bursting out, all in its rarity's colour (bigger and
-- brighter for rarer pets). They stay as long as the result is shown.
local function landedEffect(slot, color, tier)
	local holder = slot.Holder
	local centre = UDim2.new(0.5, 0, 0, 32) -- the zoomed pet's middle
	local size = 200 + math.min(tier, 6) * 22
	local glow = Ui.new("Frame", {
		Name = "Glow",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = centre,
		Size = UDim2.fromOffset(size * 0.7, size * 0.7),
		BackgroundColor3 = color,
		BackgroundTransparency = 0.55,
		ZIndex = 19,
		Parent = holder,
	}, {
		Ui.corner(0.5),
		Ui.new("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) }), Rotation = 90 }),
	})
	if Ui.reduced() then
		return
	end
	local rays = Ui.new("Frame", {
		Name = "Rays",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = centre,
		Size = UDim2.fromOffset(size, size),
		BackgroundTransparency = 1,
		ZIndex = 19,
		Parent = holder,
	})
	local count = if tier >= 3 then 8 else 6
	for k = 0, count - 1 do
		Ui.new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(0, 26, 1, 0),
			Rotation = k * (180 / count),
			BackgroundColor3 = color:Lerp(Ui.WHITE, 0.35),
			BackgroundTransparency = 0.35,
			ZIndex = 19,
			Parent = rays,
		}, { Ui.new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.15), NumberSequenceKeypoint.new(1, 1) }) }) })
	end
	local raysScale = Ui.new("UIScale", { Scale = 0.2, Parent = rays })
	TweenService:Create(raysScale, TweenInfo.new(0.4, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	glow.Size = UDim2.fromOffset(20, 20)
	TweenService:Create(glow, TweenInfo.new(0.35, Enum.EasingStyle.Quint), { Size = UDim2.fromOffset(size * 0.7, size * 0.7) }):Play()
	-- sparkles burst out
	for k = 1, 10 + math.min(tier, 6) * 2 do
		local a = math.random() * math.pi * 2
		local star = Ui.new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = centre,
			Size = UDim2.fromOffset(9, 9),
			Rotation = 45,
			BackgroundColor3 = if k % 3 == 0 then Ui.WHITE elseif k % 3 == 1 then Ui.GOLD else color,
			ZIndex = 24,
			Parent = holder,
		}, { Ui.corner(2) })
		local distance = 70 + math.random() * 60
		TweenService:Create(star, TweenInfo.new(0.6, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			Position = centre + UDim2.fromOffset(math.cos(a) * distance, math.sin(a) * distance),
			Rotation = 225,
			BackgroundTransparency = 1,
		}):Play()
		task.delay(0.65, function()
			star:Destroy()
		end)
	end
	-- the rays turn slowly while the result is shown
	task.spawn(function()
		while rays.Parent do
			rays.Rotation = (rays.Rotation + 0.6) % 360
			task.wait()
		end
	end)
end

-- Where a pet sits in its window: above it (coming in), in the middle,
-- below it (leaving)
local ABOVE, MIDDLE, BELOW = UDim2.fromScale(0.5, -0.6), UDim2.fromScale(0.5, 0.5), UDim2.fromScale(0.5, 1.6)
Hatch.ZOOM = 1.5 -- the pet you got ends up this big
Hatch.HOLD = 1.8 -- seconds the roll stays on the pet you got (landing + ~1s) before the next roll

-- Puts a pet (or the boost tile) in a slot with its odds and name. Pets
-- scroll top to bottom: the new one slides in from above while the old one
-- drops out below. When it lands (`landed` true) the pet you got comes
-- down past the middle, comes back up to the middle and zooms to 150%.
local function setSlot(slot, name, oddsText, landed, step)
	local color = if name == BOOST then Ui.SUCCESS else Config.rarity(Config.PETS_BY_NAME[(Config.petInfo(name)).Name].Odds).Color
	if slot.Shows ~= name or landed then
		local reduced = Ui.reduced()
		local time = math.min(step or 0.14, 0.16)
		-- the old one drops out below
		for _, old in ipairs(slot.View:GetChildren()) do
			if old:IsA("GuiObject") then
				if reduced then
					if old:IsA("ViewportFrame") then PetView.release(old) else old:Destroy() end
				else
					TweenService:Create(old, TweenInfo.new(time, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = BELOW }):Play()
					task.delay(time, function()
						if old.Parent == slot.View then
							if old:IsA("ViewportFrame") then PetView.release(old) else old:Destroy() end
						end
					end)
				end
			end
		end
		-- the new one comes in from above
		local view
		if name == BOOST then
			view = boostTile(slot.View, 100)
			view.ZIndex = 21
		else
			view = PetView.take(name)
			view.Size = UDim2.fromScale(1, 1)
			view.ZIndex = 21
			view.Parent = slot.View
		end
		view.AnchorPoint = Vector2.new(0.5, 0.5)
		if name ~= BOOST then
			view.Size = UDim2.fromScale(1, 1)
		end
		slot.Shows = name
		if reduced then
			view.Position = MIDDLE
		elseif not landed then
			view.Position = ABOVE
			TweenService:Create(view, TweenInfo.new(time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = MIDDLE }):Play()
		else
			-- past the middle to the bottom, back up to the middle, then the zoom
			view.Position = ABOVE
			TweenService:Create(view, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = UDim2.fromScale(0.5, 0.85) }):Play()
			task.delay(0.22, function()
				if view.Parent ~= slot.View then
					return
				end
				TweenService:Create(view, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Position = MIDDLE }):Play()
				task.delay(0.25, function()
					if view.Parent ~= slot.View then
						return
					end
					-- out of the window, bigger, lifted so it doesn't cover the text
					slot.View.ClipsDescendants = false
					TweenService:Create(slot.Pop, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = Hatch.ZOOM }):Play()
					TweenService:Create(slot.View, TweenInfo.new(0.3, Enum.EasingStyle.Quint), { Position = UDim2.new(0.5, 0, 0, -34) }):Play()
					landedEffect(slot, color, if name == BOOST then 1 else Hatch.tier({ Pet = (Config.petInfo(name)).Name, Size = (select(2, Config.petInfo(name))).Index }))
				end)
			end)
		end
		if landed and reduced then
			slot.View.ClipsDescendants = false
			slot.Pop.Scale = Hatch.ZOOM
			slot.View.Position = UDim2.new(0.5, 0, 0, -34)
			landedEffect(slot, color, 1)
		end
	end
	slot.Name.Text = if name == BOOST then "Luck Boost" else name
	slot.Odds.Text = oddsText
	-- two colours mixing diagonally: the rarity's (or the size's, or green
	-- for a boost) from the bottom-left into its second from the top-right
	local second = color:Lerp(Ui.WHITE, 0.55)
	if name ~= BOOST then
		local pet, size = Config.petInfo(name)
		if pet and size.Index == 1 then
			local rarity = Config.rarity(pet.Odds)
			color, second = rarity.Color, rarity.Color2
		elseif pet then
			second = Config.rarity(pet.Odds).Color
		end
	end
	Ui.diagonal(slot.Odds, color, second)
end

-- the odds shown for a result: the exact chance it was rolled at (the
-- server sends the luck it used), or its plain odds for results from elsewhere
local function oddsTextFor(result, name)
	if name == BOOST then
		return "x" .. Config.BOOST.Multiplier
	end
	if result.Luck then
		local ctx = rollContext(result)
		local chance = Config.chanceOf(name, ctx.Luck, ctx.SizeLuck, ctx.World)
		return if chance > 0 then Config.shortOdds(1 / chance) else "-"
	end
	return Config.shortOdds(Config.oddsOf(name))
end

local function resultName(r)
	return if isBoost(r) then BOOST else Config.petName(r.Pet, r.Size or 1)
end

-- the result stays until the next roll starts (or a few seconds), then
-- simply disappears
local function fadeResultsLater(id, fast)
	resultsRow.Position = Hatch.ROW_POSITION
	task.delay(if fast then 2.5 else 4, function()
		if resultsId == id then
			resultsRow.Visible = false
			PetView.releaseAll(resultsRow)
			clear(resultsRow)
		end
	end)
end

-- Shows the pets a roll gave, big, near the top of the screen (no cycling)
function Hatch.showResults(results, fast)
	resultsId += 1
	local id = resultsId
	PetView.releaseAll(resultsRow)
	clear(resultsRow)
	local shown = { Names = {}, Odds = {} }
	local order = 0
	for _, r in ipairs(results) do
		if not isBoost(r) and r.Pet then
			order += 1
			local name = resultName(r)
			local slot = makeSlot(order)
			setSlot(slot, name, oddsTextFor(r, name), true)
			table.insert(shown.Names, name)
			table.insert(shown.Odds, slot.Odds.Text)
		end
	end
	Hatch.LastResults = shown
	resultsRow.Visible = order > 0
	if order > 0 then
		fadeResultsLater(id, fast)
	end
end

-- THE ROLL (compact and auto): one slot per result in the row near the top.
-- Each flickers through pets that can come out of this roll (with their
-- exact odds and names), slower and slower, then lands on what the server
-- gave. Returns what happened, in the same shape as the reel's spin.
Hatch.CYCLE_START, Hatch.CYCLE_END = 0.09, 0.3 -- seconds per pet, at the start / near the end
local function cycle(results, best, fast)
	local ctx = rollContext(best)
	local tier = Hatch.tier(best)
	plays += 1
	local first = plays <= 3
	resultsId += 1
	local id = resultsId
	PetView.releaseAll(resultsRow)
	clear(resultsRow)
	resultsRow.Position = Hatch.ROW_POSITION
	resultsRow.Visible = true
	local multiplier = best.Multiplier or 1
	local badgeAtStart = boostState(if multiplier > 1 then "active" else "none", multiplier)

	local slots = {}
	for i, r in ipairs(results) do
		local slot = makeSlot(i)
		slot.Result = r
		slot.Final = resultName(r)
		slot.Context = rollContext(r)
		slot.Pool = reelNames(slot.Context, false)
		slot.Next = 0
		slot.Step = math.random(1, #slot.Pool)
		slots[i] = slot
	end
	local duration = (if fast then 1.8 elseif first then 3.2 else 2.6) + (if tier >= 3 and not fast then 0.6 else 0)
	local start = os.clock()
	local shownForBest, intervals = {}, {}
	while true do
		local t = os.clock() - start
		if t >= duration or skipRequested then
			break
		end
		local u = t / duration
		local interval = Hatch.CYCLE_START + (Hatch.CYCLE_END - Hatch.CYCLE_START) * u * u
		for i, slot in ipairs(slots) do
			if t >= slot.Next then
				slot.Step = slot.Step % #slot.Pool + 1
				local name = slot.Pool[slot.Step]
				if name == slot.Final and #slot.Pool > 1 then
					-- (the real result only shows when it lands)
					slot.Step = slot.Step % #slot.Pool + 1
					name = slot.Pool[slot.Step]
				end
				local oddsText = if name == BOOST then "x" .. Config.BOOST.Multiplier else (function()
					local chance = Config.chanceOf(name, slot.Context.Luck, slot.Context.SizeLuck, slot.Context.World)
					return if chance > 0 then Config.shortOdds(1 / chance) else "-"
				end)()
				setSlot(slot, name, oddsText, false, interval)
				if slot.Result == best then
					table.insert(shownForBest, { Name = name, Text = oddsText })
					table.insert(intervals, interval)
				end
				if i == 1 then
					Effects.play("Roll", 0.9 + u * 0.5, 0.02)
				end
				-- each slot ticks on its own beat
				slot.Next = t + interval * (0.9 + math.random() * 0.2)
			end
		end
		task.wait()
	end

	-- every slot lands on its real result
	local landedText = nil
	for _, slot in ipairs(slots) do
		setSlot(slot, slot.Final, oddsTextFor(slot.Result, slot.Final), true)
		if slot.Result == best then
			landedText = slot.Odds.Text
		end
	end
	local nextMultiplier = best.NextMultiplier or 1
	local badgeAfter = boostState(if nextMultiplier > 1 then "waiting" else "none", nextMultiplier)
	if nextMultiplier > multiplier then
		Effects.play("Coin", 1.6)
	end
	if isBoost(best) then
		Effects.jingle(3)
	elseif tier >= 2 and tier < 4 then
		Effects.jingle(2)
	elseif tier < 2 then
		Effects.play("Coin", 1.3, 0.05)
	end
	local names, odds = {}, {}
	for _, slot in ipairs(slots) do
		if slot.Final ~= BOOST then
			table.insert(names, slot.Final)
			table.insert(odds, slot.Odds.Text)
		end
	end
	Hatch.LastResults = { Names = names, Odds = odds }
	fadeResultsLater(id, fast)
	local finalName = resultName(best)
	return {
		Landed = { Name = finalName },
		LandedExactly = true,
		Result = finalName,
		SpeedEarly = 1 / (intervals[1] or 1),
		SpeedLate = 1 / (intervals[#intervals] or 1),
		Flex = false,
		FlexShown = 0,
		FlexNames = {},
		Chances = shownForBest,
		ResultChance = landedText,
		Context = ctx,
		LuckChip = badgeAtStart,
		NextChip = badgeAfter,
		First = first,
		Tier = tier,
		Slots = #slots,
		Motion = { Sideways = 0, Down = 0, Up = 0, TrayMoved = 0 },
	}
end

local function show(results, fast, mode, auto)
	-- the reel lands on the best pet; on a boost if the spin only gave boosts
	local best, bestScore = results[1], -math.huge
	for _, r in ipairs(results) do
		local score = if r.Kind == "Boost" then -1 else Hatch.tier(r) * 10 + math.log10(Config.PETS_BY_NAME[r.Pet].Odds) / 100
		if score > bestScore then
			best, bestScore = r, score
		end
	end
	local others = {}
	for _, r in ipairs(results) do
		if r ~= best and r.Kind ~= "Boost" then
			table.insert(others, r)
		end
	end
	local full = mode ~= "compact"
	local tier = Hatch.tier(best)
	Hatch.LastCutscene = nil
	local spun = if full then spin(results, best, fast, full) else cycle(results, best, fast)
	local landed = spun.Landed

	local record = {
		Mode = if full then "full" else "compact",
		Landed = spun.LandedExactly,
		LandedName = landed.Name,
		Result = spun.Result,
		SpeedEarly = spun.SpeedEarly,
		SpeedLate = spun.SpeedLate,
		Pets = COUNT,
		Others = #others,
		Flex = spun.Flex,
		FlexShown = spun.FlexShown,
		FlexNames = spun.FlexNames,
		Chances = spun.Chances,
		ResultChance = spun.ResultChance,
		Context = spun.Context,
		LuckChip = spun.LuckChip,
		NextChip = spun.NextChip,
		Motion = spun.Motion,
		Kinds = (function()
			local kinds = {}
			for _, r in ipairs(results) do
				table.insert(kinds, r.Kind or "Pet")
			end
			return kinds
		end)(),
		Multiplier = best.Multiplier or 1,
		NextMultiplier = best.NextMultiplier or 1,
		Bottom = if full then spinner.AnchorPoint.Y == 1 and spinner.Position.Y.Scale == 1 else false,
		Backdrop = if full then spinner.BackgroundTransparency else 1,
		Slots = spun.Slots,
	}
	if full and not isBoost(best) then
		-- a short silhouette moment, longer for rarer pets
		record.Silhouette = if fast then 0.12 else (if spun.First then 0.4 else 0.25) + math.min(tier, 5) * 0.15
		skipRequested = false
		pause(record.Silhouette)
		Hatch.Last = record
	else
		Hatch.LastFeed = record
		record.Names = { spun.Result }
		record.Cards = #results
		skipRequested = false
		-- the landing animation (~0.8s), then about 1 more second on the pet
		-- you got before anything else happens (so you can see what it is)
		pause(Hatch.HOLD)
	end
	hideSpinner()

	skipRequested = false
	if isBoost(best) then
		Hatch.Last = record
		pause(if fast then 0.3 else 0.5)
	elseif best.Size >= 2 or tier >= 6 then
		special(best, others, fast, auto)
	elseif full then
		openShade(0.55)
		Screen.blur(true)
		showReveal(best, fast, others)
		Screen.blur(false)
	end

	if shade.Visible then
		TweenService:Create(shade, TweenInfo.new(0.2), { BackgroundTransparency = 1 }):Play()
		task.wait(0.2)
	end
end

-- Plays a roll's results: the spinner at the bottom, then (full mode, or a
-- special result) the reveal. mode = "full" (default) or "compact"; auto =
-- rolling on auto (the cutscene cooldown applies). Yields until it's done.
-- It only ever SHOWS results the server already decided.
function Hatch.play(results, fast, _world, mode, auto)
	if busy or #results == 0 then
		return
	end
	busy = true
	skipRequested = false
	local ok, err = pcall(show, results, fast, mode or "full", auto)
	if not ok then
		warn("[Hatch] " .. tostring(err))
	end
	finish()
end

-- The compact version (the small spinner only)
function Hatch.compact(results, fast, auto)
	Hatch.play(results, fast, nil, "compact", auto)
end

-- Just the reveal (no spinner), for a result that comes from elsewhere
function Hatch.reveal(petName, sizeIndex)
	if busy then
		return
	end
	busy = true
	skipRequested = false
	Hatch.Last = { Mode = "reveal" }
	openShade(0.55)
	local ok, err = pcall(showReveal, { Pet = petName, Size = sizeIndex, First = false }, false, {})
	if not ok then
		warn("[Hatch] " .. tostring(err))
	end
	finish()
end

return Hatch
