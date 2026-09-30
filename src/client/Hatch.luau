-- The hatch show: what you see every time you roll. It's the heart of the
-- game, so it builds up and pays off:
--   1. Start     the world darkens and blurs, the hatch window pops up
--   2. Scroll    a strip of pet cards races past, then slows down and lands
--                the result exactly in the middle (a tick on every card)
--   3. Shake     the window shakes harder and harder as it slows down
--   4. Shadow    the result is a dark silhouette with a glow in its rarity's
--                colour (rarer = longer wait)
--   5. Reveal    the pet in 3D pops up with rays, sparkles, sound, its name,
--                rarity, power and size
-- The reveal grows with the result:
--   common        quick, a few sparkles, a ding
--   rare / epic   rays, more sparkles, a jingle
--   legendary+    a flash, confetti, a longer jingle
--   HUGE          gold screen flash, big sparkles, a "HUGE!" banner that slams
--                 in, a camera kick, lots of confetti
--   TITANIC       its own show: the screen goes dark, then a rainbow flash,
--                 "JACKPOT!", rainbow rays and rings, waves of confetti,
--                 camera shake and zoom, the longest jingle
-- Clicking anywhere skips to the next step. The first few hatches of a
-- session get the long strip; after that it's a bit quicker, and fast mode
-- (auto roll, Auto Hatch level 2, or the setting off) is quicker still but
-- still gives Huge and Titanic a proper moment. Rolling several pets at once shows the best one on the
-- strip and the rest as little cards under the reveal.
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
local CARD_W, CARD_H, GAP = 132, 172, 12
local STEP = CARD_W + GAP
local WINDOW_W = 760
local CARDS = 34 -- cards on the strip
local LANDING = 30 -- the result's place on the strip

-- Layout ----------------------------------------------------------------------------------------

-- the dark background also catches clicks (to skip)
local shade = Ui.new("TextButton", {
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.fromRGB(8, 4, 24),
	BackgroundTransparency = 1,
	AutoButtonColor = false,
	Text = "",
	Visible = false,
	ZIndex = 50,
	Parent = gui,
})
local stage = Ui.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.46),
	Size = UDim2.fromOffset(WINDOW_W + 40, 520),
	BackgroundTransparency = 1,
	ZIndex = 51,
	Parent = shade,
})
local stageScale = Ui.new("UIScale", { Parent = stage })

-- the strip's window
local window = Ui.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.42),
	Size = UDim2.fromOffset(WINDOW_W, CARD_H + 40),
	BackgroundColor3 = Color3.fromRGB(34, 26, 82),
	BackgroundTransparency = 0.08,
	ClipsDescendants = true,
	ZIndex = 52,
	Parent = stage,
}, { Ui.corner(30), Ui.new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(120, 110, 220), Color3.fromRGB(50, 40, 120)) }) })
local windowStroke = Ui.stroke(Color3.new(1, 1, 1), 5, 0)
windowStroke.Parent = window
local strip = Ui.new("Frame", {
	Position = UDim2.fromOffset(0, 20),
	Size = UDim2.fromOffset(CARDS * STEP, CARD_H),
	BackgroundTransparency = 1,
	ZIndex = 53,
	Parent = window,
})
-- soft edges so cards fade in and out at the sides
for _, side in ipairs({ 0, 1 }) do
	Ui.new("Frame", {
		AnchorPoint = Vector2.new(side, 0),
		Position = UDim2.fromScale(side, 0),
		Size = UDim2.new(0, 110, 1, 0),
		BackgroundColor3 = Color3.fromRGB(40, 32, 100),
		ZIndex = 56,
		Parent = window,
	}, { Ui.new("UIGradient", { Rotation = if side == 0 then 0 else 180, Transparency = NumberSequence.new(0, 1) }) })
end
-- the landing slot: a gold frame in the middle and two pointers
local slot = Ui.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.42),
	Size = UDim2.fromOffset(CARD_W + 14, CARD_H + 14),
	BackgroundTransparency = 1,
	ZIndex = 57,
	Parent = stage,
}, { Ui.corner(24) })
local slotStroke = Ui.stroke(Ui.GOLD, 5, 0)
slotStroke.Parent = slot
for _, side in ipairs({ -1, 1 }) do
	Ui.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, side * (CARD_H / 2 + 26)),
		Size = UDim2.fromOffset(26, 26),
		Rotation = 45,
		BackgroundColor3 = Ui.GOLD,
		ZIndex = 58,
		Parent = slot,
	}, { Ui.corner(5), Ui.stroke(Ui.INK, 3) })
end
local skipHint = Ui.new("TextLabel", {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -8),
	Size = UDim2.fromOffset(400, 22),
	TextScaled = false,
	TextSize = 17,
	Text = "Click to skip",
	TextColor3 = Color3.fromRGB(210, 205, 240),
	TextTransparency = 0.2,
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
local revealScale = Ui.new("UIScale", { Parent = reveal })
local rays = Ui.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.36),
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
	Position = UDim2.fromScale(0.5, 0.36),
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
		Position = UDim2.fromScale(0.5, 0.36),
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
	Position = UDim2.fromScale(0.5, 0.36),
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
local banner = text({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.03), Size = UDim2.fromOffset(700, 60), TextSize = 56 })
local bannerScale = Ui.new("UIScale", { Parent = banner })
local newBadge = text({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 120, 0.2, 0), Size = UDim2.fromOffset(110, 34), TextSize = 22, Text = "NEW!", BackgroundTransparency = 0, BackgroundColor3 = Ui.SUCCESS, Rotation = 12 })
Ui.corner(17).Parent = newBadge
Ui.stroke(Color3.new(1, 1, 1), 3).Parent = newBadge
local nameText = text({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.67), Size = UDim2.fromOffset(760, 64), TextSize = 58 })
local rarityPill = text({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.77), Size = UDim2.fromOffset(0, 32), AutomaticSize = Enum.AutomaticSize.X, TextSize = 22, BackgroundTransparency = 0, TextStrokeTransparency = 0.4 })
Ui.corner(16).Parent = rarityPill
Ui.stroke(Color3.new(1, 1, 1), 3).Parent = rarityPill
Ui.new("UIPadding", { PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16), Parent = rarityPill })
local powerText = text({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.86), Size = UDim2.fromOffset(700, 34), TextSize = 30, TextColor3 = Ui.GOLD })
local extras = Ui.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 1, 6),
	Size = UDim2.fromOffset(700, 96),
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
local plays = 0 -- shows so far this session: the first few get the long strip
local skipRequested = false
Hatch.Last = nil -- for the simulator: what the last show did

shade.Activated:Connect(function()
	Hatch.skip()
end)

function Hatch.busy()
	return busy
end

-- Jump to the next step (clicking, or pressing Roll during a show)
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
	elseif odds >= 100 then
		return if odds >= 1000 then 2 else 1
	end
	return 0
end

-- Cards -----------------------------------------------------------------------------------------

local function card(parent, name, silhouette, x)
	local pet, size = Config.petInfo(name)
	local rarity = Config.rarity(pet.Odds)
	local accent = if size.Index > 1 then size.Color else rarity.Color
	local frame = Ui.new("Frame", {
		Position = UDim2.fromOffset(x, 0),
		Size = UDim2.fromOffset(CARD_W, CARD_H),
		BackgroundColor3 = if silhouette then Color3.fromRGB(20, 14, 44) else accent:Lerp(Color3.fromRGB(40, 30, 90), 0.6),
		ZIndex = 54,
		Parent = parent,
	}, { Ui.corner(20) })
	Ui.stroke(if silhouette then Color3.new(1, 1, 1) else accent, 4, 0).Parent = frame
	local view = PetView.take(name, silhouette)
	view.AnchorPoint = Vector2.new(0.5, 0)
	view.Position = UDim2.new(0.5, 0, 0, 2)
	view.Size = UDim2.fromOffset(CARD_W - 6, 118)
	view.ZIndex = 55
	view.Parent = frame
	text({
		Position = UDim2.fromOffset(4, 122),
		Size = UDim2.new(1, -8, 0, 22),
		TextSize = 19,
		Text = if silhouette then "???" else pet.Name,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 56,
		Parent = frame,
	})
	text({
		Position = UDim2.fromOffset(4, 146),
		Size = UDim2.new(1, -8, 0, 16),
		TextSize = 13,
		Text = if silhouette then "?" else string.upper(rarity.Name),
		TextColor3 = if silhouette then Ui.MUTED else rarity.Color,
		TextStrokeTransparency = 0.5,
		ZIndex = 56,
		Parent = frame,
	})
	return frame
end

local function clear(container)
	PetView.releaseAll(container)
	for _, child in ipairs(container:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

-- Pets for the strip: mostly the common ones of this world, now and then a
-- rare "teaser" (and one right after the result, for a near miss)
local function stripPets(world)
	local pool = {}
	for _, pet in ipairs(Config.PETS) do
		if pet.World <= world + 1 then
			table.insert(pool, pet)
		end
	end
	local list = {}
	for i = 1, CARDS do
		local r = math.random() ^ 2.4
		if i == LANDING + 1 or math.random() < 0.08 then
			r = 0.75 + math.random() * 0.25 -- a teaser
		end
		list[i] = pool[math.clamp(math.floor(r * #pool) + 1, 1, #pool)].Name
	end
	return list
end

-- Effects ----------------------------------------------------------------------------------------

local function sparkleBurst(count, size, colors, spread)
	for k = 1, count do
		local a = math.random() * math.pi * 2
		local s = size * (0.6 + math.random() * 0.8)
		local star = Ui.new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.36),
			Size = UDim2.fromOffset(s, s),
			Rotation = 45,
			BackgroundColor3 = colors[(k % #colors) + 1],
			ZIndex = 56,
			Parent = reveal,
		}, { Ui.corner(math.floor(s / 4)) })
		local d = spread * (0.5 + math.random() * 0.7)
		TweenService:Create(star, TweenInfo.new(0.9 + math.random() * 0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			Position = UDim2.new(0.5, math.cos(a) * d, 0.36, math.sin(a) * d),
			Rotation = 45 + math.random(-200, 200),
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(2, 2),
		}):Play()
		task.delay(1.5, function()
			star:Destroy()
		end)
	end
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

-- The show -------------------------------------------------------------------------------------

local SIZE_WORDS = { "", "HUGE!", "TITANIC!" }

-- The reveal of one result (also used on its own for the simulator/tests)
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
	window.Visible, slot.Visible = false, false
	glow.BackgroundColor3 = accent
	for _, ray in pairs(rayFrames) do
		ray.BackgroundColor3 = accent:Lerp(Color3.new(1, 1, 1), 0.3)
	end
	rays.Visible = tier >= 1
	banner.Text = if result.Size > 1 then SIZE_WORDS[result.Size] else (if tier >= 3 then string.upper(rarity.Name) .. "!" else "")
	if tier >= 5 then
		banner.Text = "✨ TITANIC ✨"
	end
	banner.TextColor3 = accent
	banner.Visible = banner.Text ~= ""
	newBadge.Visible = result.First or (result.Size > 1 and result.FirstOfSize) or false
	newBadge.Text = if result.First then "NEW!" else "NEW " .. string.upper(size.Name) .. "!"
	nameText.Text = name
	nameText.TextColor3 = if result.Size > 1 then size.Color else Color3.new(1, 1, 1)
	rarityPill.Text = string.upper(rarity.Name) .. "  ·  " .. Config.formatOdds(pet.Odds)
	rarityPill.BackgroundColor3 = rarity.Color
	powerText.Text = Config.formatNumber(Config.petPower(name)) .. " Power" .. (if result.Size > 1 then "  ·  " .. size.Name .. " x" .. size.Power else "")

	-- the other pets from this roll, as little cards
	clear(extras)
	for i, other in ipairs(others or {}) do
		local mini = card(extras, Config.petName(other.Pet, other.Size), false, 0)
		mini.LayoutOrder = i
		mini.Size = UDim2.fromOffset(74, 96)
		for _, d in ipairs(mini:GetDescendants()) do
			if d:IsA("ViewportFrame") then
				d.Size = UDim2.fromOffset(70, 64)
			elseif d:IsA("TextLabel") then
				d.Position = UDim2.fromOffset(2, if d.TextSize > 15 then 64 else 80)
				d.TextSize = if d.TextSize > 15 then 13 else 10
				d.Size = UDim2.new(1, -4, 0, 14)
			end
		end
	end

	-- pop in
	petScale.Scale = 0.2
	revealScale.Scale = 0.85
	TweenService:Create(petScale, TweenInfo.new(if tier >= 4 then 0.7 else 0.45, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	TweenService:Create(revealScale, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	bannerScale.Scale = if tier >= 4 then 3 else 0.5
	TweenService:Create(bannerScale, TweenInfo.new(if tier >= 4 then 0.35 else 0.3, Enum.EasingStyle.Back), { Scale = 1 }):Play()

	-- the bigger the moment, the more happens
	local hold
	if tier <= 0 then
		sparkleBurst(8, 12, { Color3.new(1, 1, 1), accent }, 160)
		Effects.play("Coin", 1.3)
		hold = 0.9
	elseif tier == 1 then
		sparkleBurst(14, 14, { Color3.new(1, 1, 1), accent, Ui.GOLD }, 200)
		Effects.jingle(2)
		hold = 1.1
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
		-- HUGE
		flashScreen(Color3.fromRGB(255, 220, 110), 0, 0.7)
		sparkleBurst(36, 26, { Ui.GOLD, Color3.new(1, 1, 1), Color3.fromRGB(255, 170, 60) }, 340)
		ringWave(Ui.GOLD)
		cameraKick(6, 0.6)
		Effects.jingle(6)
		Effects.play("Hit", 0.5)
		Effects.confetti(90)
		hold = 2.6
	else
		-- TITANIC: its own show
		flashScreen(Color3.new(0, 0, 0), 0, 0.3)
		task.delay(0.3, function()
			flashScreen(Color3.new(1, 1, 1), 0, 0.9)
			ringWave(Color3.fromRGB(255, 90, 200))
			cameraKick(10, 1.4)
			Effects.play("Hit", 0.4)
		end)
		for wave = 0, 2 do
			task.delay(0.3 + wave * 0.6, function()
				sparkleBurst(30, 28, { Color3.fromRGB(255, 90, 90), Color3.fromRGB(255, 220, 60), Color3.fromRGB(80, 220, 255), Color3.fromRGB(200, 100, 255), Color3.new(1, 1, 1) }, 380)
				Effects.confetti(80)
			end)
		end
		Effects.jingle(7)
		task.delay(0.9, Effects.jingle, 7)
		hold = 3.6
	end
	if fast then
		hold = if tier >= 5 then 2.2 elseif tier == 4 then 1.6 else 0.7
	end
	Hatch.Last = { Name = name, Tier = tier, Size = result.Size, Rays = rays.Visible, Banner = banner.Text, Hold = hold }

	-- rays turn, titanic cycles through the rainbow
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

-- Puts everything back (after a show, or if one fails halfway)
local function finish()
	stage.Position = UDim2.fromScale(0.5, 0.46)
	stage.Rotation = 0
	slotStroke.Thickness, slotStroke.Color, windowStroke.Color = 5, Ui.GOLD, Color3.new(1, 1, 1)
	shade.Visible = false
	reveal.Visible = false
	clear(strip)
	clear(petHolder)
	clear(extras)
	busy = false
	skipRequested = false
end

local function show(results, fast, world)

	-- the best result is the one on the strip
	local best, bestTier = results[1], -1
	for _, r in ipairs(results) do
		local tier = Hatch.tier(r) * 10 + Config.PETS_BY_NAME[r.Pet].Odds / 1e8
		if tier > bestTier then
			best, bestTier = r, tier
		end
	end
	local others = {}
	for _, r in ipairs(results) do
		if r ~= best then
			table.insert(others, r)
		end
	end
	local tier = Hatch.tier(best)
	local accent = if best.Size > 1 then Config.SIZES[best.Size].Color else Config.rarity(Config.PETS_BY_NAME[best.Pet].Odds).Color

	-- 1. start: darken, blur, pop the window in
	shade.Visible = true
	reveal.Visible = false
	window.Visible, slot.Visible = true, true
	skipHint.Visible = true
	shade.BackgroundTransparency = 1
	TweenService:Create(shade, TweenInfo.new(0.25), { BackgroundTransparency = 0.35 }):Play()
	stageScale.Scale = 0.7
	TweenService:Create(stageScale, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Scale = 1 }):Play()

	-- 2. the strip: cards race past and slow down onto the result
	clear(strip)
	local names = stripPets(world or 1)
	local cards = {}
	for i = 1, CARDS do
		local silhouette = i == LANDING
		local name = if silhouette then Config.petName(best.Pet, best.Size) else names[i]
		cards[i] = card(strip, name, silhouette, (i - 1) * STEP)
	end
	local finalX = WINDOW_W / 2 - ((LANDING - 1) * STEP + CARD_W / 2)
	local startX = WINDOW_W / 2 - CARD_W / 2 + 40
	plays += 1
	local first = plays <= 3
	local duration = (if fast then 0.9 elseif first then 2.4 else 1.5) + (if fast then 0 else math.min(tier, 3) * 0.15)
	local start = os.clock()
	local lastIndex = -1
	local shakes = 0
	local lastX, speedEarly, speedLate = nil, 0, math.huge
	local maxShake, earlyShake = 0, math.huge
	while true do
		local u = math.clamp((os.clock() - start) / duration, 0, 1)
		if skipRequested then
			u = 1
		end
		-- fast at first, then a long slow-down onto the result
		local eased = 1 - (1 - u) ^ 4
		local x = startX + (finalX - startX) * eased
		strip.Position = UDim2.fromOffset(x, 20)
		-- how fast it moves at the start and at the end (for the simulator)
		if lastX then
			local speed = math.abs(x - lastX)
			if u < 0.25 then
				speedEarly = math.max(speedEarly, speed)
			elseif u > 0.85 and u < 1 then
				speedLate = math.min(speedLate, speed)
			end
		end
		lastX = x
		-- only the cards in view are drawn
		for i, c in ipairs(cards) do
			local left = x + (i - 1) * STEP
			c.Visible = left > -CARD_W and left < WINDOW_W
		end
		-- a tick each time a card crosses the middle, higher as it slows
		local index = math.floor((WINDOW_W / 2 - x) / STEP)
		if index ~= lastIndex then
			lastIndex = index
			Effects.play("Roll", 0.9 + u * 0.6, 0.02)
		end
		-- 3. shaking: harder as it slows down
		local shake = if u > 0.45 then (u - 0.45) / 0.55 else 0
		local amount = shake * (4 + math.min(tier, 5) * 1.5)
		stage.Position = UDim2.new(0.5, (math.random() - 0.5) * amount, 0.46, (math.random() - 0.5) * amount)
		stage.Rotation = (math.random() - 0.5) * shake * 1.6
		if shake > 0 then
			shakes += 1
		end
		maxShake = math.max(maxShake, amount)
		if u > 0.5 and u < 0.6 then
			earlyShake = math.min(earlyShake, amount)
		end
		if u >= 1 then
			break
		end
		task.wait()
	end
	stage.Position = UDim2.fromScale(0.5, 0.46)
	stage.Rotation = 0

	-- 4. the silhouette glows in its rarity's colour a moment
	slotStroke.Color = accent
	local glowTime = if fast then 0.2 else (if first then 0.45 else 0.3) + math.min(tier, 5) * 0.18
	skipRequested = false
	local pulse = RunService.RenderStepped:Connect(function()
		local p = math.sin(os.clock() * 12) * 0.5 + 0.5
		slotStroke.Thickness = 5 + p * 5
		windowStroke.Color = Color3.new(1, 1, 1):Lerp(accent, p)
	end)
	if tier >= 3 then
		Effects.play("Roll", 0.5)
	end
	pause(glowTime)
	pulse:Disconnect()
	slotStroke.Thickness, slotStroke.Color, windowStroke.Color = 5, Ui.GOLD, Color3.new(1, 1, 1)

	-- 5. the reveal
	skipHint.Visible = not fast
	skipRequested = false
	showReveal(best, fast, others)
	if Hatch.Last then
		Hatch.Last.Cards = CARDS
		Hatch.Last.Landed = cards[LANDING] ~= nil and math.abs(strip.Position.X.Offset - finalX) < 0.5
		Hatch.Last.Shakes = shakes
		Hatch.Last.SpeedEarly = speedEarly
		Hatch.Last.SpeedLate = speedLate
		Hatch.Last.ShakeGrows = maxShake > earlyShake
		Hatch.Last.StripCardsShown = CARDS
		Hatch.Last.Silhouette = glowTime
		Hatch.Last.Others = #others
	end

	-- done: fade out
	TweenService:Create(shade, TweenInfo.new(0.2), { BackgroundTransparency = 1 }):Play()
	task.wait(0.2)
end

-- Plays the whole show for a roll's results. Yields until it's done.
-- fast: shorter version (the setting, or auto hatching). If anything goes
-- wrong halfway, it still cleans up, so rolling never gets stuck.
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

-- Just the reveal (no strip), for a result that comes from elsewhere
function Hatch.reveal(petName, sizeIndex)
	if busy then
		return
	end
	busy = true
	shade.Visible = true
	shade.BackgroundTransparency = 0.35
	Screen.blur(true)
	local ok, err = pcall(showReveal, { Pet = petName, Size = sizeIndex, First = false }, false, {})
	if not ok then
		warn("[Hatch] " .. tostring(err))
	end
	Screen.blur(false)
	finish()
end

return Hatch
