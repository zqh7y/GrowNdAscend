-- The hatch: what you see every time you roll. It happens right over the
-- game (only a 10% dark veil behind it), with no box or window:
--   1. Pets fall     a column of pets streams down from the top of the screen
--                    through the middle, fast at first (stretched with motion
--                    blur), each with a soft glow in its rarity's colour and a
--                    shadow; pets shrink and fade away from the middle (depth)
--   2. Slowing down  it eases out, with sparkles drifting up, a tick as each
--                    pet passes the middle, a gentle zoom and a shake that
--                    builds near the end, and stops exactly on your result
--   3. Silhouette    your pet waits as a dark shape, glowing in its rarity's
--                    colour (longer for rarer ones)
--   4. Reveal        it pops out in 3D with rays, sparkles, name, rarity,
--                    power and size, and grows with rarity:
--        common      quick, a few sparkles, a ding
--        rare/epic   rays, more sparkles, a jingle
--        legendary+  a flash, rings, confetti
--        HUGE        gold flash, big sparkles, "HUGE!" slams in, camera kick
--        TITANIC     an event: the lights go down, a slow heartbeat reveal,
--                    a rainbow flash, "TITANIC", rainbow rays and rings,
--                    waves of confetti, screen shake and zoom, long jingle
-- FLEX ROLLS: now and then (about 1 roll in 30) the column slips in some
-- ridiculous pets on the way down (a Huge, a Titanic, a Secret), slows for
-- a moment as each one passes with a big label, then carries on. They are
-- only visual: the column always stops on the pet the server actually
-- rolled, and that's what the reveal shows.
-- Speed: the first few hatches get the long version; after that it's
-- quicker, and fast mode (auto roll, Auto Hatch 2, or the setting off) is
-- quicker still, but rare results always get their full moment. Clicking
-- (or pressing Roll) skips to the next step. It can never get stuck.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local Effects = require(script.Parent.Effects)
local PetView = require(script.Parent.PetView)
local Screen = require(script.Parent.Screen)
local Ui = require(script.Parent.Ui)

local Hatch = {}

local gui = Screen.Gui
local SPACING = 150 -- pixels between pets in the column
local PETS = 30 -- pets in the column
local LANDING = 26 -- the result's place in the column
local VIEW = 150 -- pet size in pixels
local REACH = 420 -- pixels from the middle where pets have faded out
Hatch.FLEX_CHANCE = 1 / 30

-- Layout ----------------------------------------------------------------------------------------

-- a very light veil (it also catches clicks, to skip)
local shade = Ui.new("TextButton", {
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.fromRGB(10, 6, 30),
	BackgroundTransparency = 1,
	AutoButtonColor = false,
	Text = "",
	Visible = false,
	ZIndex = 50,
	Parent = gui,
})
local stage = Ui.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.new(0, 800, 1, 0),
	BackgroundTransparency = 1,
	ZIndex = 51,
	Parent = shade,
})
local stageScale = Ui.new("UIScale", { Parent = stage })

-- the column the pets fall through (no frame, nothing drawn)
local column = Ui.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.45),
	Size = UDim2.fromOffset(VIEW, VIEW),
	BackgroundTransparency = 1,
	ZIndex = 52,
	Parent = stage,
})
-- a soft band of light across the middle, and two small gold pointers
local band = Ui.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.45),
	Size = UDim2.fromOffset(520, 170),
	BackgroundColor3 = Color3.new(1, 1, 1),
	BackgroundTransparency = 0.8,
	ZIndex = 51,
	Parent = stage,
}, {
	Ui.corner(0.5),
	Ui.new("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.2), NumberSequenceKeypoint.new(1, 1) }) }),
})
local pointers = {}
for _, side in ipairs({ -1, 1 }) do
	pointers[side] = Ui.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, side * 150, 0.45, 0),
		Size = UDim2.fromOffset(22, 22),
		Rotation = 45,
		BackgroundColor3 = Ui.GOLD,
		ZIndex = 56,
		Parent = stage,
	}, { Ui.corner(5), Ui.stroke(Ui.INK, 3) })
end
local skipHint = Ui.new("TextLabel", {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -40),
	Size = UDim2.fromOffset(400, 22),
	TextScaled = false,
	TextSize = 17,
	Text = "Click to skip",
	TextColor3 = Color3.new(1, 1, 1),
	TextStrokeTransparency = 0.4,
	TextStrokeColor3 = Ui.INK,
	TextTransparency = 0.25,
	ZIndex = 52,
	Parent = stage,
})
local flexBanner = Ui.new("TextLabel", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.45),
	Size = UDim2.fromOffset(700, 60),
	TextScaled = false,
	Font = Ui.FONT_TITLE,
	TextSize = 30,
	Text = "",
	TextStrokeTransparency = 0,
	TextStrokeColor3 = Ui.INK,
	Visible = false,
	ZIndex = 58,
	Parent = stage,
})
local flexScale = Ui.new("UIScale", { Parent = flexBanner })

-- the reveal
local reveal = Ui.new("Frame", {
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	Visible = false,
	ZIndex = 52,
	Parent = stage,
})
local revealScale = Ui.new("UIScale", { Parent = reveal })
local rays = Ui.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.4),
	Size = UDim2.fromOffset(640, 640),
	BackgroundTransparency = 1,
	ZIndex = 52,
	Parent = reveal,
})
local rayFrames = {}
for k = 0, 11 do
	rayFrames[k] = Ui.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0, 46, 1, 0),
		Rotation = k * 15,
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.82,
		ZIndex = 52,
		Parent = rays,
	}, { Ui.new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1) }) }) })
end
local glow = Ui.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.4),
	Size = UDim2.fromOffset(250, 250),
	BackgroundColor3 = Color3.new(1, 1, 1),
	BackgroundTransparency = 0.5,
	ZIndex = 53,
	Parent = reveal,
}, { Ui.corner(0.5) })
local rings = {}
for k = 1, 3 do
	rings[k] = Ui.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.4),
		Size = UDim2.fromOffset(100, 100),
		BackgroundTransparency = 1,
		Visible = false,
		ZIndex = 53,
		Parent = reveal,
	}, { Ui.corner(0.5) })
	Ui.stroke(Color3.new(1, 1, 1), 6, 0).Parent = rings[k]
end
local petHolder = Ui.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.4),
	Size = UDim2.fromOffset(300, 290),
	BackgroundTransparency = 1,
	ZIndex = 54,
	Parent = reveal,
})
local petScale = Ui.new("UIScale", { Parent = petHolder })
local function text(props)
	props.TextScaled = false
	props.BackgroundTransparency = props.BackgroundTransparency or 1
	props.TextStrokeTransparency = props.TextStrokeTransparency or 0
	props.TextStrokeColor3 = props.TextStrokeColor3 or Ui.INK
	props.ZIndex = props.ZIndex or 55
	props.Parent = props.Parent or reveal
	return Ui.new("TextLabel", props)
end
local banner = text({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.14), Size = UDim2.fromOffset(760, 60), Font = Ui.FONT_TITLE, TextSize = 40, TextStrokeTransparency = 0.3 })
local bannerScale = Ui.new("UIScale", { Parent = banner })
local newBadge = text({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 130, 0.25, 0), Size = UDim2.fromOffset(120, 26), Font = Ui.FONT_TITLE, TextSize = 12, Text = "NEW", TextColor3 = Ui.INK, TextStrokeTransparency = 1, BackgroundTransparency = 0, BackgroundColor3 = Ui.SUCCESS })
Ui.corner(3).Parent = newBadge
local nameText = text({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.63), Size = UDim2.fromOffset(760, 56), Font = Enum.Font.GothamBlack, TextSize = 50, TextStrokeTransparency = 0.5 })
local rarityPill = text({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.7), Size = UDim2.fromOffset(0, 26), AutomaticSize = Enum.AutomaticSize.X, Font = Ui.FONT_TITLE, TextSize = 12, TextColor3 = Ui.INK, BackgroundTransparency = 0, TextStrokeTransparency = 1 })
Ui.corner(3).Parent = rarityPill
Ui.new("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14), Parent = rarityPill })
local powerText = text({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.77), Size = UDim2.fromOffset(700, 34), Font = Ui.FONT_TITLE, TextSize = 22, TextColor3 = Ui.CYAN, TextStrokeTransparency = 0.5 })
-- a holo pad under the revealed pet, and a scan line that sweeps over it
local pad = Ui.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(0.5, 0, 0.4, 130),
	Size = UDim2.fromOffset(240, 40),
	BackgroundColor3 = Color3.new(1, 1, 1),
	BackgroundTransparency = 0.8,
	ZIndex = 53,
	Parent = reveal,
}, { Ui.corner(0.5) })
local padStroke = Ui.stroke(Ui.CYAN, 2, 0.1)
padStroke.Parent = pad
local scan = Ui.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0),
	Size = UDim2.new(1.1, 0, 0, 3),
	BackgroundColor3 = Ui.CYAN,
	BackgroundTransparency = 0.2,
	Visible = false,
	ZIndex = 56,
	Parent = petHolder,
}, { Ui.new("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1) }) }) })
local extras = Ui.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.fromScale(0.5, 0.82),
	Size = UDim2.fromOffset(700, 90),
	BackgroundTransparency = 1,
	ZIndex = 55,
	Parent = reveal,
}, {
	Ui.new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Padding = UDim.new(0, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}),
})

-- full-screen flash on top of everything
local flash = Ui.new("Frame", {
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.new(1, 1, 1),
	BackgroundTransparency = 1,
	ZIndex = 70,
	Parent = gui,
})

-- State -----------------------------------------------------------------------------------------

local busy = false
local skipRequested = false
local plays = 0 -- hatches so far this session: the first few get the long version
Hatch.Last = nil -- for the simulator: what the last hatch did
Hatch.ForceFlex = false -- (for the simulator) make the next hatch a flex roll

shade.Activated:Connect(function()
	Hatch.skip()
end)

function Hatch.busy()
	return busy
end

-- Jump to the next step (clicking, or pressing Roll during a hatch)
function Hatch.skip()
	if busy then
		skipRequested = true
	end
end

-- Waits `seconds`, or less if a skip comes in; returns true if skipped
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

local function clear(container)
	PetView.releaseAll(container)
	for _, child in ipairs(container:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

-- The column --------------------------------------------------------------------------------------

-- One pet in the column: a rarity glow, a soft shadow, the pet in 3D
local function columnPet(name, silhouette)
	local pet, size = Config.petInfo(name)
	local rarity = Config.rarity(pet.Odds)
	local accent = if silhouette then Color3.new(1, 1, 1) elseif size.Index > 1 then size.Color else rarity.Color
	local item = Ui.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(VIEW, VIEW),
		BackgroundTransparency = 1,
		ZIndex = 53,
		Parent = column,
	})
	local scale = Ui.new("UIScale", { Parent = item })
	local itemGlow = Ui.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.78, 0.78),
		BackgroundColor3 = accent,
		BackgroundTransparency = 0.82,
		ZIndex = 53,
		Parent = item,
	}, { Ui.corner(0.5), Ui.stroke(accent, 2, 0.15) })
	local shadow = Ui.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.9),
		Size = UDim2.fromScale(0.55, 0.12),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.7,
		ZIndex = 53,
		Parent = item,
	}, { Ui.corner(0.5) })
	local view = PetView.take(name, silhouette)
	view.AnchorPoint = Vector2.new(0.5, 0.5)
	view.Position = UDim2.fromScale(0.5, 0.5)
	view.Size = UDim2.fromOffset(VIEW, VIEW)
	view.ZIndex = 54
	view.Parent = item
	return { Frame = item, Scale = scale, Glow = itemGlow, Shadow = shadow, View = view, Name = name, Accent = accent, Size = size.Index, Odds = pet.Odds, Silhouette = silhouette }
end

-- The pets in the column: mostly common ones of this world, now and then a
-- rarer one; the result goes at LANDING. A flex roll adds a few absurd
-- pets a little before the result (visual only).
local function columnNames(world, flex)
	local pool = {}
	for _, pet in ipairs(Config.PETS) do
		if pet.World <= world + 1 then
			table.insert(pool, pet)
		end
	end
	local names, flexAt = {}, {}
	for i = 1, PETS do
		local r = math.random() ^ 2.4
		if i == LANDING + 1 or math.random() < 0.07 then
			r = 0.7 + math.random() * 0.3 -- a rare teaser (one just after the result: a near miss)
		end
		names[i] = pool[math.clamp(math.floor(r * #pool) + 1, 1, #pool)].Name
	end
	if flex then
		-- one to three showstoppers on the way down, never the result itself
		local best = { "Glitch", "Galaxy Whale", "Void Serpent", "Celestial Lion", "Kraken", "Phoenix", "Dragon", "Frost Dragon" }
		local count = math.random(1, 3)
		for k = 1, count do
			local at = LANDING - 12 + (k - 1) * 3 + math.random(0, 1)
			local sizeIndex = if k == count and math.random() < 0.6 then 3 elseif math.random() < 0.6 then 2 else 1
			names[at] = Config.petName(best[math.random(1, #best)], sizeIndex)
			flexAt[at] = true
		end
	end
	return names, flexAt
end

-- Effects ----------------------------------------------------------------------------------------

local function sparkleBurst(count, size, colors, spread)
	for k = 1, count do
		local a = math.random() * math.pi * 2
		local s = size * (0.6 + math.random() * 0.8)
		local star = Ui.new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.4),
			Size = UDim2.fromOffset(s, s),
			Rotation = 45,
			BackgroundColor3 = colors[(k % #colors) + 1],
			ZIndex = 56,
			Parent = reveal,
		}, { Ui.corner(math.floor(s / 4)) })
		local d = spread * (0.5 + math.random() * 0.7)
		TweenService:Create(star, TweenInfo.new(0.9 + math.random() * 0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			Position = UDim2.new(0.5, math.cos(a) * d, 0.4, math.sin(a) * d),
			Rotation = 45 + math.random(-200, 200),
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(2, 2),
		}):Play()
		task.delay(1.5, function()
			star:Destroy()
		end)
	end
end

-- a little spark drifting up around the column while it rolls
local function drift(color)
	local s = math.random(4, 9)
	local spark = Ui.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, math.random(-200, 200), 0.45, math.random(-60, 160)),
		Size = UDim2.fromOffset(s, s),
		Rotation = 45,
		BackgroundColor3 = color,
		BackgroundTransparency = 0.2,
		ZIndex = 52,
		Parent = stage,
	}, { Ui.corner(2) })
	TweenService:Create(spark, TweenInfo.new(1.2, Enum.EasingStyle.Sine), {
		Position = spark.Position - UDim2.fromOffset(0, 140),
		BackgroundTransparency = 1,
	}):Play()
	task.delay(1.25, function()
		spark:Destroy()
	end)
end

local function flashScreen(color, from, duration)
	flash.BackgroundColor3 = color
	flash.BackgroundTransparency = from
	TweenService:Create(flash, TweenInfo.new(duration, Enum.EasingStyle.Quad), { BackgroundTransparency = 1 }):Play()
end

local function ringWave(color)
	for k, ring in ipairs(rings) do
		task.delay((k - 1) * 0.18, function()
			ring.Visible = true
			ring.Size = UDim2.fromOffset(100, 100)
			local stroke = ring:FindFirstChildOfClass("UIStroke")
			stroke.Color = color
			stroke.Transparency = 0
			TweenService:Create(ring, TweenInfo.new(0.9, Enum.EasingStyle.Quad), { Size = UDim2.fromOffset(620, 620) }):Play()
			TweenService:Create(stroke, TweenInfo.new(0.9), { Transparency = 1 }):Play()
		end)
	end
end

-- The camera: a quick shake (the character's camera offset) and a zoom kick
local function cameraKick(strength, duration)
	local humanoid = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
	local camera = workspace.CurrentCamera
	if camera and camera.FieldOfView then
		local fov = camera.FieldOfView
		camera.FieldOfView = fov - strength * 2
		TweenService:Create(camera, TweenInfo.new(0.5, Enum.EasingStyle.Back), { FieldOfView = fov }):Play()
	end
	if humanoid then
		task.spawn(function()
			local start = os.clock()
			while os.clock() - start < duration do
				local fade = 1 - (os.clock() - start) / duration
				humanoid.CameraOffset = Vector3.new(math.random() - 0.5, math.random() - 0.5, 0) * strength * 0.25 * fade
				task.wait()
			end
			humanoid.CameraOffset = Vector3.zero
		end)
	end
end

-- The reveal -------------------------------------------------------------------------------------

local SIZE_WORDS = { "", "HUGE!", "✨ TITANIC ✨" }

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
	column.Visible, band.Visible = false, false
	for _, p in pairs(pointers) do
		p.Visible = false
	end
	glow.BackgroundColor3 = accent
	for _, ray in pairs(rayFrames) do
		ray.BackgroundColor3 = accent:Lerp(Color3.new(1, 1, 1), 0.3)
	end
	rays.Visible = tier >= 1
	banner.Text = if result.Size > 1 then SIZE_WORDS[result.Size] else (if tier >= 3 then string.upper(rarity.Name) .. "!" else "")
	banner.TextColor3 = accent
	banner.Visible = banner.Text ~= ""
	newBadge.Visible = result.First or (result.Size > 1 and result.FirstOfSize) or false
	newBadge.Text = if result.First then "NEW ANIMAL" else "NEW " .. string.upper(size.Name)
	nameText.Text = name
	nameText.TextColor3 = if result.Size > 1 then size.Color else Color3.new(1, 1, 1)
	rarityPill.Text = string.upper(rarity.Name) .. "  ·  " .. string.upper(Config.formatOdds(pet.Odds))
	rarityPill.BackgroundColor3 = rarity.Color
	pad.BackgroundColor3 = accent
	padStroke.Color = accent
	-- the power counts up (satisfying), then holds
	local power = Config.petPower(name)
	local suffix = " PWR" .. (if result.Size > 1 then "  ·  " .. string.upper(size.Name) .. " x" .. size.Power else "")
	powerText.Text = "0" .. suffix
	task.spawn(function()
		local start = os.clock()
		local length = if tier >= 4 then 1.1 else 0.55
		while reveal.Visible and os.clock() - start < length do
			local u = (os.clock() - start) / length
			powerText.Text = Config.formatNumber(power * (1 - (1 - u) ^ 3)) .. suffix
			task.wait()
		end
		powerText.Text = Config.formatNumber(power) .. suffix
	end)
	-- one scan line sweeps down over the pet
	scan.Visible = true
	scan.BackgroundColor3 = accent
	scan.Position = UDim2.fromScale(0.5, 0)
	TweenService:Create(scan, TweenInfo.new(0.6, Enum.EasingStyle.Quad), { Position = UDim2.fromScale(0.5, 1) }):Play()
	task.delay(0.62, function()
		scan.Visible = false
	end)

	-- the other pets from this roll, small underneath
	clear(extras)
	for i, other in ipairs(others or {}) do
		local otherName = Config.petName(other.Pet, other.Size)
		local mini = Ui.new("Frame", {
			LayoutOrder = i,
			Size = UDim2.fromOffset(74, 90),
			BackgroundTransparency = 1,
			ZIndex = 55,
			Parent = extras,
		})
		local miniView = PetView.take(otherName)
		miniView.Size = UDim2.fromOffset(74, 66)
		miniView.ZIndex = 55
		miniView.Parent = mini
		text({ Position = UDim2.fromOffset(0, 66), Size = UDim2.new(1, 0, 0, 16), TextSize = 13, Text = otherName, TextTruncate = Enum.TextTruncate.AtEnd, Parent = mini })
	end

	-- the bigger the moment, the more happens
	if tier >= 5 and not fast then
		-- TITANIC: the lights go down and the pet rises slowly first
		TweenService:Create(shade, TweenInfo.new(0.4), { BackgroundTransparency = 0.45 }):Play()
		petScale.Scale = 0.05
		banner.Visible = false
		for beat = 1, 3 do
			TweenService:Create(petScale, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Scale = 0.15 + beat * 0.12 }):Play()
			Effects.play("Hit", 0.45 + beat * 0.08)
			if pause(0.45) then
				break
			end
		end
		banner.Visible = true
	else
		petScale.Scale = 0.2
	end
	revealScale.Scale = 0.85
	TweenService:Create(petScale, TweenInfo.new(if tier >= 4 then 0.7 else 0.45, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	TweenService:Create(revealScale, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	bannerScale.Scale = if tier >= 4 then 3 else 0.5
	TweenService:Create(bannerScale, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Scale = 1 }):Play()

	local hold
	if tier <= 0 then
		sparkleBurst(8, 12, { Color3.new(1, 1, 1), accent }, 160)
		Effects.play("Coin", 1.3)
		hold = 0.7
	elseif tier == 1 then
		sparkleBurst(14, 14, { Color3.new(1, 1, 1), accent, Ui.GOLD }, 200)
		Effects.jingle(2)
		hold = 1.0
	elseif tier == 2 then
		sparkleBurst(20, 16, { Color3.new(1, 1, 1), accent, Ui.GOLD }, 240)
		flashScreen(accent, 0.6, 0.4)
		Effects.jingle(3)
		hold = 1.4
	elseif tier == 3 then
		sparkleBurst(28, 18, { Color3.new(1, 1, 1), accent, Ui.GOLD }, 280)
		flashScreen(Color3.new(1, 1, 1), 0.3, 0.5)
		ringWave(accent)
		Effects.jingle(5)
		Effects.confetti(40)
		hold = 1.9
	elseif tier == 4 then
		flashScreen(Color3.fromRGB(255, 220, 110), 0, 0.7)
		sparkleBurst(36, 26, { Ui.GOLD, Color3.new(1, 1, 1), Color3.fromRGB(255, 170, 60) }, 340)
		ringWave(Ui.GOLD)
		cameraKick(6, 0.6)
		Effects.jingle(6)
		Effects.play("Hit", 0.5)
		Effects.confetti(90)
		hold = 2.6
	else
		flashScreen(Color3.new(1, 1, 1), 0, 0.9)
		ringWave(Color3.fromRGB(255, 90, 200))
		cameraKick(10, 1.4)
		Effects.play("Hit", 0.4)
		for wave = 0, 2 do
			task.delay(wave * 0.6, function()
				sparkleBurst(30, 28, { Color3.fromRGB(255, 90, 90), Color3.fromRGB(255, 220, 60), Color3.fromRGB(80, 220, 255), Color3.fromRGB(200, 100, 255), Color3.new(1, 1, 1) }, 380)
				Effects.confetti(80)
			end)
		end
		Effects.jingle(7)
		task.delay(0.9, Effects.jingle, 7)
		hold = 3.6
	end
	if fast then
		hold = if tier >= 5 then 2.2 elseif tier == 4 then 1.6 else 0.6
	end
	Hatch.Last = Hatch.Last or {}
	Hatch.Last.Name, Hatch.Last.Tier, Hatch.Last.Size = name, tier, result.Size
	Hatch.Last.Rays, Hatch.Last.Banner, Hatch.Last.Hold = rays.Visible, banner.Text, hold

	local spin = RunService.RenderStepped:Connect(function(dt)
		rays.Rotation += dt * (if tier >= 5 then 45 elseif tier >= 4 then 30 else 18)
		local pulse = math.sin(os.clock() * 5) * 0.5 + 0.5
		glow.BackgroundTransparency = 0.45 + pulse * 0.2
		if tier >= 5 then
			local rainbow = Color3.fromHSV((os.clock() * 0.6) % 1, 0.55, 1)
			banner.TextColor3 = rainbow
			nameText.TextColor3 = rainbow
			glow.BackgroundColor3 = rainbow
			for _, ray in pairs(rayFrames) do
				ray.BackgroundColor3 = rainbow
			end
		end
	end)
	skipRequested = false
	pause(hold)
	spin:Disconnect()
end

-- The hatch ----------------------------------------------------------------------------------------

local function finish()
	stage.Position = UDim2.fromScale(0.5, 0.5)
	stage.Rotation = 0
	stageScale.Scale = 1
	shade.Visible = false
	reveal.Visible = false
	flexBanner.Visible = false
	clear(column)
	clear(petHolder)
	clear(extras)
	busy = false
	skipRequested = false
end

local function show(results, fast, world)
	-- the best result is the one the column lands on
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
	local accent = if best.Size > 1 then Config.SIZES[best.Size].Color else Config.rarity(Config.PETS_BY_NAME[best.Pet].Odds).Color
	plays += 1
	local first = plays <= 3
	local flex = Hatch.ForceFlex or (not fast and math.random() < Hatch.FLEX_CHANCE)
	Hatch.ForceFlex = false

	-- 1. the veil (very light) and the column
	shade.Visible = true
	reveal.Visible = false
	column.Visible, band.Visible = true, true
	for _, p in pairs(pointers) do
		p.Visible = true
	end
	skipHint.Visible = true
	shade.BackgroundTransparency = 1
	TweenService:Create(shade, TweenInfo.new(0.2), { BackgroundTransparency = 0.9 }):Play()
	stageScale.Scale = 1

	clear(column)
	local names, flexAt = columnNames(world or 1, flex)
	local items = {}
	for i = 1, PETS do
		local silhouette = i == LANDING
		items[i] = columnPet(if silhouette then resultName else names[i], silhouette)
		items[i].Flex = flexAt[i]
	end

	-- 2. falling: pet i sits at y = offset - (i - 1) * SPACING from the
	-- middle, so as the offset grows the pets move DOWN the screen
	local startOffset = 2 * SPACING
	local finalOffset = (LANDING - 1) * SPACING
	local duration = (if fast then 0.75 elseif first then 2.2 else 1.2) + (if tier >= 3 and not fast then 0.6 else 0)
	local progress = 0
	local lastOffset, lastIndex = nil, -1
	local speedEarly, speedLate = 0, math.huge
	local shakes, maxShake, earlyShake = 0, 0, math.huge
	local flexShown, flexNames = 0, {}
	local driftClock = 0
	local previous = os.clock()
	while true do
		local now = os.clock()
		local dt = now - previous
		previous = now
		-- flex pets slow the fall right down as they pass the middle
		local rate = 1
		local offsetNow = lastOffset or startOffset
		for i, item in ipairs(items) do
			if item.Flex then
				local y = offsetNow - (i - 1) * SPACING
				if math.abs(y) < SPACING * 0.6 then
					rate = 0.25
					if not item.Announced then
						item.Announced = true
						flexShown += 1
						table.insert(flexNames, item.Name)
						local sizeIndex = item.Size
						flexBanner.Text = if sizeIndex >= 3 then "👑 TITANIC " .. item.Name:gsub("^Titanic ", "") .. " 👑?!"
							elseif sizeIndex == 2 then "✨ HUGE " .. item.Name:gsub("^Huge ", "") .. " ✨?!"
							else "WAIT... " .. string.upper(item.Name) .. "?!"
						flexBanner.TextColor3 = item.Accent
						flexBanner.Visible = true
						flexScale.Scale = 1.8
						TweenService:Create(flexScale, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Scale = 1 }):Play()
						flashScreen(item.Accent, 0.75, 0.35)
						Effects.play("Coin", 1.8)
						task.delay(0.7, function()
							flexBanner.Visible = false
						end)
					end
				end
			end
		end
		progress += dt / duration * rate
		if skipRequested then
			progress = 1
		end
		local u = math.clamp(progress, 0, 1)
		-- fast at first, a long, smooth slow-down onto the result
		local eased = 1 - (1 - u) ^ 3.2
		local offset = startOffset + (finalOffset - startOffset) * eased
		local speed = if lastOffset then math.abs(offset - lastOffset) else 0
		if lastOffset then
			if u < 0.25 then
				speedEarly = math.max(speedEarly, speed)
			elseif u > 0.85 and u < 1 then
				speedLate = math.min(speedLate, speed)
			end
		end
		lastOffset = offset
		-- place, scale, fade and stretch every pet by where it is
		for i, item in ipairs(items) do
			local y = offset - (i - 1) * SPACING
			local away = math.abs(y) / REACH
			local visible = away < 1.05
			item.Frame.Visible = visible
			if visible then
				item.Frame.Position = UDim2.new(0.5, 0, 0.5, y)
				item.Scale.Scale = 1.15 - math.min(away, 1) * 0.55 -- bigger in the middle (depth)
				local fade = math.clamp((away - 0.35) / 0.65, 0, 1)
				item.View.ImageTransparency = fade
				item.Glow.BackgroundTransparency = 0.72 + fade * 0.28
				item.Shadow.BackgroundTransparency = 0.7 + fade * 0.3
				-- motion blur: stretched and a little see-through when fast
				local blur = math.clamp(speed / 60, 0, 0.7)
				item.View.Size = UDim2.fromOffset(VIEW * (1 - blur * 0.15), VIEW * (1 + blur))
				if blur > 0.05 then
					item.View.ImageTransparency = math.max(item.View.ImageTransparency, blur * 0.5)
				end
			end
		end
		-- a tick as each pet passes the middle; higher as it slows down
		local index = math.floor(offset / SPACING + 0.5)
		if index ~= lastIndex then
			lastIndex = index
			local passing = items[index + 1]
			Effects.play("Roll", 0.9 + u * 0.7 + (if passing and passing.Odds >= 1000 then 0.3 else 0), 0.02)
		end
		-- sparkles drifting up in the result's colour
		driftClock += dt
		if driftClock > 0.08 then
			driftClock = 0
			drift(if math.random() < 0.5 then accent else Color3.new(1, 1, 1))
		end
		-- 3. near the end: a gentle zoom and a shake that builds
		local near = if u > 0.6 then (u - 0.6) / 0.4 else 0
		stageScale.Scale = 1 + near * 0.06
		local amount = near * (3 + math.min(tier, 5) * 1.4)
		stage.Position = UDim2.new(0.5, (math.random() - 0.5) * amount, 0.5, (math.random() - 0.5) * amount)
		stage.Rotation = (math.random() - 0.5) * near * 1.2
		if near > 0 then
			shakes += 1
		end
		maxShake = math.max(maxShake, amount)
		if u > 0.62 and u < 0.7 then
			earlyShake = math.min(earlyShake, amount)
		end
		if u >= 1 then
			break
		end
		task.wait()
	end
	stage.Position = UDim2.fromScale(0.5, 0.5)
	stage.Rotation = 0
	flexBanner.Visible = false

	-- a near miss: a much rarer pet stopped right above yours
	local above = items[LANDING + 1]
	local nearMiss = above and above.Odds >= 10 * Config.PETS_BY_NAME[best.Pet].Odds and tier <= 2
	if nearMiss then
		local tag = Ui.new("TextLabel", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(1, 6, 0.5, 0),
			Size = UDim2.fromOffset(120, 18),
			BackgroundTransparency = 0,
			BackgroundColor3 = Ui.DANGER,
			Font = Ui.FONT_TITLE,
			TextScaled = false,
			TextSize = 9,
			Text = "SO CLOSE",
			TextColor3 = Ui.TEXT,
			ZIndex = 57,
			Parent = above.Frame,
		}, { Ui.corner(3) })
		Effects.play("Click", 0.6)
		task.delay(1.2, function()
			tag:Destroy()
		end)
	end

	-- 4. the silhouette glows in its rarity's colour a moment
	local landed = items[LANDING]
	local glowTime = if fast then (if tier >= 4 then 0.4 else 0.15) else (if first then 0.45 else 0.3) + math.min(tier, 5) * 0.18
	skipRequested = false
	local pulse = RunService.RenderStepped:Connect(function()
		local p = math.sin(os.clock() * 12) * 0.5 + 0.5
		landed.Glow.BackgroundColor3 = accent
		landed.Glow.BackgroundTransparency = 0.35 + p * 0.3
		landed.Scale.Scale = 1.15 + p * 0.06
	end)
	if tier >= 3 then
		Effects.play("Roll", 0.5)
		cameraKick(2, 0.3)
	end
	pause(glowTime)
	pulse:Disconnect()

	-- 5. the reveal: always the pet actually rolled
	skipHint.Visible = not fast
	skipRequested = false
	Hatch.Last = {
		Vertical = true,
		Landed = math.abs(lastOffset - finalOffset) < 0.5,
		LandedName = landed.Name,
		Result = resultName,
		SpeedEarly = speedEarly,
		SpeedLate = speedLate,
		Shakes = shakes,
		ShakeGrows = maxShake > earlyShake,
		Silhouette = glowTime,
		StripCardsShown = PETS,
		NearMiss = nearMiss,
		Others = #others,
		Flex = flex,
		FlexShown = flexShown,
		FlexNames = flexNames,
		Veil = 0.9,
	}
	showReveal(best, fast, others)
	Hatch.Last.Revealed = nameText.Text

	TweenService:Create(shade, TweenInfo.new(0.2), { BackgroundTransparency = 1 }):Play()
	task.wait(0.2)
end

-- Hidden hatches ---------------------------------------------------------------------------------
-- With hatches hidden, results slide in as small cards on the right (no
-- veil, nothing blocking) and fade after a few seconds. Big results still
-- get a moment: a Huge or Titanic flashes its name in the middle.

local feedList = Ui.new("Frame", {
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -130, 0.42, 0),
	Size = UDim2.fromOffset(250, 380),
	BackgroundTransparency = 1,
	ZIndex = 45,
	Parent = gui,
}, {
	Ui.new("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}),
})
local feedBanner = Ui.new("TextLabel", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.3),
	Size = UDim2.fromOffset(800, 50),
	Font = Ui.FONT_TITLE,
	TextScaled = false,
	TextSize = 30,
	TextStrokeTransparency = 0.3,
	TextStrokeColor3 = Ui.INK,
	Visible = false,
	ZIndex = 46,
	Parent = gui,
})
local feedBannerScale = Ui.new("UIScale", { Parent = feedBanner })
local feedOrder = 0
Hatch.LastFeed = nil -- for the simulator

function Hatch.feed(results)
	local shown = {}
	for _, result in ipairs(results) do
		local name = Config.petName(result.Pet, result.Size)
		local pet, size = Config.petInfo(name)
		local rarity = Config.rarity(pet.Odds)
		local tier = Hatch.tier(result)
		local accent = if size.Index > 1 then size.Color else rarity.Color
		feedOrder += 1
		local card = Ui.card({
			LayoutOrder = feedOrder,
			Size = UDim2.fromOffset(250, 54),
			BackgroundColor3 = Ui.GLASS,
			BackgroundTransparency = 0.15,
			ZIndex = 45,
			Parent = feedList,
		}, accent)
		local view = PetView.take(name)
		view.Size = UDim2.fromOffset(52, 52)
		view.ZIndex = 46
		view.Parent = card
		Ui.new("TextLabel", {
			Position = UDim2.fromOffset(58, 8),
			Size = UDim2.new(1, -64, 0, 18),
			TextScaled = false,
			TextSize = 15,
			Text = name,
			TextColor3 = if size.Index > 1 then size.Color else Ui.TEXT,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = 46,
			Parent = card,
		})
		Ui.new("TextLabel", {
			Position = UDim2.fromOffset(58, 30),
			Size = UDim2.new(1, -64, 0, 14),
			Font = Ui.FONT_TITLE,
			TextScaled = false,
			TextSize = 8,
			Text = string.upper(rarity.Name) .. "  ·  " .. Config.formatNumber(Config.petPower(name)) .. " PWR" .. (if result.First then "  ·  NEW" else ""),
			TextColor3 = rarity.Color,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 46,
			Parent = card,
		})
		local scale = Ui.new("UIScale", { Scale = 0.6, Parent = card })
		TweenService:Create(scale, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Scale = 1 }):Play()
		task.delay(if tier >= 3 then 6 else 3, function()
			PetView.releaseAll(card)
			card:Destroy()
		end)
		table.insert(shown, name)
		if tier >= 4 then
			-- a Huge or Titanic still gets its moment, without stopping you
			feedBanner.Text = (if tier >= 5 then "TITANIC " else "HUGE ") .. string.upper(result.Pet) .. "!"
			feedBanner.TextColor3 = accent
			feedBanner.Visible = true
			feedBannerScale.Scale = 2
			TweenService:Create(feedBannerScale, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Scale = 1 }):Play()
			flashScreen(accent, 0.6, 0.5)
			Effects.jingle(if tier >= 5 then 7 else 5)
			Effects.confetti(if tier >= 5 then 80 else 40)
			task.delay(2, function()
				feedBanner.Visible = false
			end)
		elseif tier >= 2 then
			Effects.jingle(2)
		else
			Effects.play("Coin", 1.4, 0.05)
		end
	end
	-- never more than 6 cards at once
	local cards = {}
	for _, child in ipairs(feedList:GetChildren()) do
		if child:IsA("Frame") then
			table.insert(cards, child)
		end
	end
	table.sort(cards, function(x, y)
		return x.LayoutOrder < y.LayoutOrder
	end)
	for i = 1, #cards - 6 do
		PetView.releaseAll(cards[i])
		cards[i]:Destroy()
	end
	Hatch.LastFeed = { Names = shown, Cards = math.min(#cards, 6) }
end

-- Plays the whole hatch for a roll's results. Yields until it's done.
-- fast: the quick version (auto roll, Auto Hatch 2, or the setting off).
-- If anything goes wrong halfway it still cleans up, so rolling never
-- gets stuck.
function Hatch.play(results, fast, world)
	if busy or #results == 0 then
		return
	end
	busy = true
	skipRequested = false
	local ok, err = pcall(show, results, fast, world)
	if not ok then
		warn("[Hatch] " .. tostring(err))
	end
	finish()
end

-- Just the reveal (no column), for a result that comes from elsewhere
function Hatch.reveal(petName, sizeIndex)
	if busy then
		return
	end
	busy = true
	shade.Visible = true
	shade.BackgroundTransparency = 0.9
	local ok, err = pcall(showReveal, { Pet = petName, Size = sizeIndex, First = false }, false, {})
	if not ok then
		warn("[Hatch] " .. tostring(err))
	end
	finish()
end

return Hatch
