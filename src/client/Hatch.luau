-- Hatching: how a roll's result is shown. The pets are the stars: no
-- windows, no boxes, just the pets moving through the screen with soft
-- shadows, depth and smooth easing. Two ways to watch:
--
--   COMPACT  a small row at the top of the screen (under your coins). Pets
--            glide in from the right, the middle one larger, and ease to a
--            stop on your pet, which pops with its name and rarity, then the
--            row fades. Only a faint pill (10% opacity) sits behind it; the
--            game stays fully visible and playable underneath.
--
--   FULL     the same idea, bigger, in the middle of the screen over a soft
--            dim: a carousel of large pets with depth (smaller and fainter
--            towards the sides) that slows down onto your pet, a short
--            silhouette moment, then your pet rises large with its name,
--            rarity and power in clean type. Effects stay calm and grow
--            with rarity: rare = soft sparkles, legendary = gentle light
--            rays, HUGE = a gold glow, TITANIC = a slow rise, a rainbow glow
--            and confetti. Now and then (about 1 in 30 full hatches) a flex
--            roll slips a Huge or Titanic past the middle with a small label
--            ("Huge Dragon?!"); it's only a show: the carousel always stops
--            on the pet you actually rolled.
--
-- Clicking (or pressing Roll) skips ahead. Fast versions are used when
-- grinding. It always cleans up, so rolling never gets stuck.
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local Effects = require(script.Parent.Effects)
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

-- How big a moment a result is: 0 common .. 3 legendary+, 4 huge, 5 titanic
function Hatch.tier(result)
	if result.Size >= 3 then
		return 5
	elseif result.Size == 2 then
		return 4
	end
	local odds = Config.PETS_BY_NAME[result.Pet].Odds
	if odds >= 10000 then
		return 3
	elseif odds >= 1000 then
		return 2
	elseif odds >= 100 then
		return 1
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

-- The pets that pass by: mostly common ones of this world, now and then a
-- rarer one (and one right after the result, a near miss). A flex roll adds
-- a few showstoppers a little before the result.
local function carouselNames(world, flex)
	local pool = {}
	for _, pet in ipairs(Config.PETS) do
		if pet.World <= world + 1 then
			table.insert(pool, pet)
		end
	end
	local names, flexAt = {}, {}
	for i = 1, COUNT do
		local r = math.random() ^ 2.4
		if i == LANDING + 1 or math.random() < 0.06 then
			r = 0.7 + math.random() * 0.3
		end
		names[i] = pool[math.clamp(math.floor(r * #pool) + 1, 1, #pool)].Name
	end
	if flex then
		local best = { "Glitch", "Galaxy Whale", "Void Serpent", "Celestial Lion", "Kraken", "Phoenix", "Dragon", "Frost Dragon" }
		local count = math.random(1, 2)
		for k = 1, count do
			local at = LANDING - 9 + (k - 1) * 4
			names[at] = Config.petName(best[math.random(1, #best)], if k == count and math.random() < 0.6 then 3 else 2)
			flexAt[at] = true
		end
	end
	return names, flexAt
end

-- One pet in a row: a soft shadow under it and the pet in 3D
local function rowPet(parent, name, size, silhouette)
	local item = Ui.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(size, size),
		BackgroundTransparency = 1,
		ZIndex = 53,
		Parent = parent,
	})
	local scale = Ui.new("UIScale", { Parent = item })
	local shadow = Ui.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.92),
		Size = UDim2.fromScale(0.62, 0.12),
		BackgroundColor3 = Color3.fromRGB(10, 14, 30),
		BackgroundTransparency = 0.75,
		ZIndex = 53,
		Parent = item,
	}, { Ui.corner(0.5) })
	local view = PetView.take(name, silhouette)
	view.AnchorPoint = Vector2.new(0.5, 0.5)
	view.Position = UDim2.fromScale(0.5, 0.45)
	view.Size = UDim2.fromScale(1, 1)
	view.ZIndex = 54
	view.Parent = item
	local pet = Config.petInfo(name)
	return { Frame = item, Scale = scale, Shadow = shadow, View = view, Name = name, Odds = pet.Odds }
end

-- Places a row of pets for an offset (in slots): the middle one is at full
-- size, the others smaller and fainter the further away they are
local function layoutRow(items, offset, spacing, reach, centreScale)
	for i, item in ipairs(items) do
		local slot = (i - 1) - offset
		local x = slot * spacing
		local away = math.abs(slot) / reach
		local visible = away < 1
		item.Frame.Visible = visible
		if visible then
			item.Frame.Position = UDim2.new(0.5, x, 0.5, 0)
			local near = 1 - math.min(math.abs(slot), 1)
			item.Scale.Scale = (0.62 + (1 - away) * 0.28) + near * (centreScale - 0.9)
			local fade = math.clamp((away - 0.45) / 0.55, 0, 1)
			item.View.ImageTransparency = fade
			item.Shadow.BackgroundTransparency = 0.75 + fade * 0.25
		end
	end
end

-- COMPACT ---------------------------------------------------------------------------------------

local compact = Ui.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 196),
	Size = UDim2.fromOffset(440, 96),
	BackgroundColor3 = Ui.WHITE,
	BackgroundTransparency = 0.9, -- a faint pill: 10% opacity
	Visible = false,
	ZIndex = 44,
	Parent = gui,
}, { Ui.corner(48) })
local compactRow = Ui.new("Frame", {
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	ClipsDescendants = true,
	ZIndex = 45,
	Parent = compact,
}, { Ui.corner(48) })
local compactName = Ui.new("TextLabel", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 1, 4),
	Size = UDim2.fromOffset(440, 24),
	Font = Ui.FONT_DISPLAY,
	TextScaled = false,
	TextSize = 22,
	TextColor3 = Ui.WHITE,
	TextStrokeTransparency = 0.5,
	TextStrokeColor3 = Color3.fromRGB(20, 24, 40),
	Text = "",
	ZIndex = 46,
	Parent = compact,
})
local compactChip = Ui.new("TextLabel", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 1, 30),
	Size = UDim2.fromOffset(0, 20),
	AutomaticSize = Enum.AutomaticSize.X,
	BackgroundTransparency = 0,
	Font = Ui.FONT,
	TextScaled = false,
	TextSize = 12,
	TextColor3 = Ui.WHITE,
	Text = "",
	ZIndex = 46,
	Parent = compact,
}, { Ui.corner(10), Ui.new("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }) })

-- Shows a roll in the compact row. Yields until it's done (about a second
-- and a half; quicker with `fast`).
function Hatch.compact(results, fast)
	if busy or #results == 0 then
		return
	end
	busy = true
	skipRequested = false
	local ok, err = pcall(function()
		local best, bestScore = results[1], -1
		for _, r in ipairs(results) do
			local score = Hatch.tier(r) * 10 + Config.PETS_BY_NAME[r.Pet].Odds / 1e8
			if score > bestScore then
				best, bestScore = r, score
			end
		end
		local resultName = Config.petName(best.Pet, best.Size)
		local tier = Hatch.tier(best)
		local names = carouselNames(1, false)
		names[LANDING] = resultName
		clear(compactRow)
		local items = {}
		for i = 1, COUNT do
			items[i] = rowPet(compactRow, names[i], 70, false)
		end
		compactName.Text, compactChip.Text = "", ""
		compactChip.Visible = false
		compact.Visible = true
		compact.BackgroundTransparency = 0.9 -- a faint pill, the game stays visible

		local startOffset, finalOffset = 2, LANDING - 1
		local duration = if fast then 0.7 else 1.1
		local start = os.clock()
		local lastIndex = -1
		while true do
			local u = math.clamp((os.clock() - start) / duration, 0, 1)
			if skipRequested then
				u = 1
			end
			local offset = startOffset + (finalOffset - startOffset) * (1 - (1 - u) ^ 3)
			layoutRow(items, offset, 74, 3.2, 1.25)
			local index = math.floor(offset + 0.5)
			if index ~= lastIndex then
				lastIndex = index
				Effects.play("Roll", 1 + u * 0.5, 0.03)
			end
			if u >= 1 then
				break
			end
			task.wait()
		end
		-- the result pops, with its name and rarity underneath
		local landed = items[LANDING]
		landed.Scale.Scale = 1.6
		TweenService:Create(landed.Scale, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Scale = 1.3 }):Play()
		local pet = Config.PETS_BY_NAME[best.Pet]
		local rarity = Config.rarity(pet.Odds)
		compactName.Text = resultName .. (if #results > 1 then "  +" .. (#results - 1) else "")
		compactName.TextColor3 = if best.Size > 1 then Config.SIZES[best.Size].Color else Ui.WHITE
		compactChip.Text = rarity.Name .. "  ·  " .. Config.formatOdds(pet.Odds) .. (if best.First then "  ·  NEW" else "")
		compactChip.BackgroundColor3 = rarity.Color
		compactChip.Visible = true
		if tier >= 4 then
			Effects.jingle(if tier >= 5 then 7 else 5)
			Effects.confetti(if tier >= 5 then 60 else 30)
		elseif tier >= 2 then
			Effects.jingle(2)
		else
			Effects.play("Coin", 1.3, 0.05)
		end
		Hatch.LastFeed = { Names = { resultName }, Cards = #results, Landed = landed.Name, Backdrop = compact.BackgroundTransparency }
		skipRequested = false
		pause(if fast then 0.45 else (if tier >= 4 then 1.6 else 0.8))
		TweenService:Create(compact, TweenInfo.new(0.2), { BackgroundTransparency = 1 }):Play()
		task.wait(0.1)
	end)
	if not ok then
		warn("[Hatch] " .. tostring(err))
	end
	compact.Visible = false
	clear(compactRow)
	busy = false
	skipRequested = false
end

-- Kept for older callers: hidden hatches now use the compact row
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
shade.Activated:Connect(function()
	Hatch.skip()
end)
local stage = Ui.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.48),
	Size = UDim2.fromOffset(900, 600),
	BackgroundTransparency = 1,
	ZIndex = 51,
	Parent = shade,
})
local carousel = Ui.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.42),
	Size = UDim2.fromOffset(160, 160),
	BackgroundTransparency = 1,
	ZIndex = 52,
	Parent = stage,
})
local hint = Ui.new("TextLabel", {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -10),
	Size = UDim2.fromOffset(300, 20),
	Font = Ui.FONT_MEDIUM,
	TextScaled = false,
	TextSize = 14,
	Text = "Click to skip",
	TextColor3 = Ui.WHITE,
	TextTransparency = 0.35,
	ZIndex = 52,
	Parent = stage,
})
local flexLabel = Ui.new("TextLabel", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.2),
	Size = UDim2.fromOffset(600, 40),
	Font = Ui.FONT_DISPLAY,
	TextScaled = false,
	TextSize = 30,
	TextColor3 = Ui.WHITE,
	TextStrokeTransparency = 0.6,
	TextStrokeColor3 = Color3.fromRGB(20, 24, 40),
	Visible = false,
	ZIndex = 56,
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
	local camera = workspace.CurrentCamera
	if camera and camera.FieldOfView then
		local fov = camera.FieldOfView
		camera.FieldOfView = fov - strength
		TweenService:Create(camera, TweenInfo.new(0.6, Enum.EasingStyle.Sine), { FieldOfView = fov }):Play()
	end
end

local function showReveal(result, fast, others)
	local pet, size = Config.PETS_BY_NAME[result.Pet], Config.SIZES[result.Size]
	local rarity = Config.rarity(pet.Odds)
	local tier = Hatch.tier(result)
	local accent = if result.Size > 1 then size.Color else rarity.Color
	local name = Config.petName(result.Pet, result.Size)

	clear(petHolder)
	local view = PetView.take(name)
	view.Size = UDim2.fromScale(1, 1)
	view.ZIndex = 54
	view.Parent = petHolder
	reveal.Visible = true
	carousel.Visible = false

	glowInner.BackgroundColor3 = accent
	glowOuter.BackgroundColor3 = accent
	glowInner.BackgroundTransparency = if tier >= 2 then 0.72 else 0.82
	glowOuter.BackgroundTransparency = if tier >= 2 then 0.86 else 0.92
	rays.Visible = tier >= 2
	sizeChip.Visible = result.Size > 1
	sizeChip.Text = string.upper(size.Name)
	sizeChip.BackgroundColor3 = accent
	newChip.Visible = result.First or (result.Size > 1 and result.FirstOfSize) or false
	newChip.Text = if result.First then "NEW" else "NEW " .. string.upper(size.Name)
	nameText.Text = name
	rarityChip.Text = rarity.Name .. "  ·  " .. Config.formatOdds(pet.Odds)
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
	if tier >= 5 and not fast then
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
	if fast then
		hold = if tier >= 5 then 2 elseif tier == 4 then 1.4 else 0.5
	end
	Hatch.Last = Hatch.Last or {}
	Hatch.Last.Name, Hatch.Last.Tier, Hatch.Last.Size = name, tier, result.Size
	Hatch.Last.Rays, Hatch.Last.Banner, Hatch.Last.Hold = rays.Visible, if sizeChip.Visible then sizeChip.Text else "", hold
	Hatch.Last.Revealed = nameText.Text

	local shownAt = os.clock()
	local spin = RunService.RenderStepped:Connect(function(dt)
		rays.Rotation += dt * 12
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
	powerText.Text = Config.formatNumber(power) .. " power"
	Hatch.Last.Power = powerText.Text
end

local function show(results, fast, world)
	local best, bestScore = results[1], -1
	for _, r in ipairs(results) do
		local score = Hatch.tier(r) * 10 + Config.PETS_BY_NAME[r.Pet].Odds / 1e8
		if score > bestScore then
			best, bestScore = r, score
		end
	end
	local others = {}
	for _, r in ipairs(results) do
		if r ~= best then
			table.insert(others, r)
		end
	end
	local tier = Hatch.tier(best)
	local resultName = Config.petName(best.Pet, best.Size)
	plays += 1
	local first = plays <= 3
	local flex = Hatch.ForceFlex or (not fast and math.random() < Hatch.FLEX_CHANCE)
	Hatch.ForceFlex = false

	shade.Visible = true
	shade.BackgroundTransparency = 1
	TweenService:Create(shade, TweenInfo.new(0.2), { BackgroundTransparency = 0.55 }):Play()
	reveal.Visible = false
	carousel.Visible = true
	hint.Visible = not fast
	flexLabel.Visible = false

	clear(carousel)
	local names, flexAt = carouselNames(world or 1, flex)
	local items = {}
	for i = 1, COUNT do
		local silhouette = i == LANDING
		items[i] = rowPet(carousel, if silhouette then resultName else names[i], 160, silhouette)
		items[i].Flex = flexAt[i]
	end

	-- the carousel: fast at first, a smooth slow-down onto the result
	local startOffset, finalOffset = 2, LANDING - 1
	local duration = (if fast then 0.8 elseif first then 2 else 1.3) + (if tier >= 3 and not fast then 0.5 else 0)
	local progress, previous = 0, os.clock()
	local lastOffset, lastIndex = nil, -1
	local speedEarly, speedLate = 0, math.huge
	local flexShown, flexNames = 0, {}
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
			local speed = math.abs(offset - lastOffset) * 170
			if u < 0.25 then
				speedEarly = math.max(speedEarly, speed)
			elseif u > 0.85 and u < 1 then
				speedLate = math.min(speedLate, speed)
			end
		end
		lastOffset = offset
		layoutRow(items, offset, 170, 3.4, 1.15)
		local index = math.floor(offset + 0.5)
		if index ~= lastIndex then
			lastIndex = index
			local passing = items[index + 1]
			Effects.play("Roll", 0.9 + u * 0.6 + (if passing and passing.Odds >= 1000 then 0.25 else 0), 0.02)
		end
		if u >= 1 then
			break
		end
		task.wait()
	end
	flexLabel.Visible = false

	-- a short silhouette moment, longer for rarer pets
	local landed = items[LANDING]
	local silhouette = if fast then 0.12 else (if first then 0.4 else 0.25) + math.min(tier, 5) * 0.15
	skipRequested = false
	TweenService:Create(landed.Scale, TweenInfo.new(0.3, Enum.EasingStyle.Sine), { Scale = 1.3 }):Play()
	pause(silhouette)

	Hatch.Last = {
		Mode = "full",
		Landed = math.abs(lastOffset - finalOffset) < 0.01,
		LandedName = landed.Name,
		Result = resultName,
		SpeedEarly = speedEarly,
		SpeedLate = speedLate,
		Silhouette = silhouette,
		Pets = COUNT,
		Others = #others,
		Flex = flex,
		FlexShown = flexShown,
		FlexNames = flexNames,
	}
	skipRequested = false
	showReveal(best, fast, others)
	TweenService:Create(shade, TweenInfo.new(0.2), { BackgroundTransparency = 1 }):Play()
	task.wait(0.2)
end

local function finish()
	shade.Visible = false
	reveal.Visible = false
	flexLabel.Visible = false
	clear(carousel)
	clear(petHolder)
	clear(extras)
	busy = false
	skipRequested = false
end

-- Plays the full hatch for a roll's results. Yields until it's done.
function Hatch.play(results, fast, world)
	if busy or #results == 0 then
		return
	end
	busy = true
	skipRequested = false
	Screen.blur(true)
	local ok, err = pcall(show, results, fast, world)
	if not ok then
		warn("[Hatch] " .. tostring(err))
	end
	Screen.blur(false)
	finish()
end

-- Just the reveal (no carousel), for a result that comes from elsewhere
function Hatch.reveal(petName, sizeIndex)
	if busy then
		return
	end
	busy = true
	shade.Visible = true
	shade.BackgroundTransparency = 0.55
	local ok, err = pcall(showReveal, { Pet = petName, Size = sizeIndex, First = false }, false, {})
	if not ok then
		warn("[Hatch] " .. tostring(err))
	end
	finish()
end

return Hatch
