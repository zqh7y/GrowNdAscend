-- Sticker buttons (the user's reference style): no tile behind them, just a
-- big glossy 3D cartoon icon (a darker copy under it is its thick edge, a
-- soft shadow on the ground) with a dark outline and a white shine, and a
-- chunky white caption with a thick dark outline sitting over the icon's
-- bottom edge. Hovering grows the icon a little and tilts it; pressing
-- squashes it.
--
-- Sticker.button(props, onClick) -> holder, button
--   props: Name, LayoutOrder, Size (icon size in px), Label, Art (a name in
--          Sticker.art), CaptionSize, Parent
--   holder has the Caption; button is the transparent TextButton the icon
--   is drawn in (its "Art" frame).
local TweenService = game:GetService("TweenService")

local Ui = require(script.Parent.Ui)

local Sticker = {}

local INK = Color3.fromRGB(28, 22, 40) -- the outline colour
local OUTLINE = 3

-- one piece of an icon: a frame with a dark outline, rounded, maybe a gradient
local function piece(parent, props)
	local frame = Ui.new("Frame", {
		Name = props.Name or "Piece",
		AnchorPoint = props.Anchor or Vector2.new(0.5, 0.5),
		Position = props.Position,
		Size = props.Size,
		Rotation = props.Rotation or 0,
		BackgroundColor3 = props.Color or Color3.new(1, 1, 1),
		BackgroundTransparency = props.Transparency or 0,
		BorderSizePixel = 0,
		ZIndex = props.ZIndex or 3,
		Parent = parent,
	})
	if props.Radius then
		Ui.new("UICorner", { CornerRadius = if props.Radius <= 1 then UDim.new(props.Radius, 0) else UDim.new(0, props.Radius), Parent = frame })
	end
	if props.Outline ~= false then
		Ui.new("UIStroke", { Color = INK, Thickness = props.Thickness or OUTLINE, LineJoinMode = Enum.LineJoinMode.Round, Parent = frame })
	end
	if props.Gradient then
		Ui.new("UIGradient", { Rotation = props.GradientRotation or 90, Color = ColorSequence.new(props.Gradient[1], props.Gradient[2]), Parent = frame })
	end
	if props.Aspect then
		Ui.new("UIAspectRatioConstraint", { AspectRatio = props.Aspect, Parent = frame })
	end
	return frame
end
Sticker.piece = piece

-- the white shine on the upper left of a shape
local function shine(parent, x, y, w, h, z)
	return piece(parent, {
		Name = "Shine",
		Anchor = Vector2.new(0, 0),
		Position = UDim2.fromScale(x, y),
		Size = UDim2.fromScale(w, h),
		Color = Color3.new(1, 1, 1),
		Transparency = 0.35,
		Radius = 0.5,
		Outline = false,
		ZIndex = z or 6,
	})
end

local function scale(x, y)
	return UDim2.fromScale(x, y)
end

-- The icons -------------------------------------------------------------------------------------
-- Each draws into a square frame (all sizes in scale, so any size works).

Sticker.art = {}

-- a dice like the reference: icy white-blue cube with a darker side, dark
-- navy pips, a shine
function Sticker.art.dice(art)
	local die = Ui.new("Frame", { Name = "Die", AnchorPoint = Vector2.new(0.5, 0.5), Position = scale(0.5, 0.47), Size = scale(0.8, 0.8), Rotation = -8, BackgroundTransparency = 1, ZIndex = 3, Parent = art })
	piece(die, { Name = "Side", Anchor = Vector2.new(0, 0), Position = scale(0.1, 0.12), Size = scale(0.92, 0.92), Color = Color3.fromRGB(120, 168, 222), Radius = 0.24, ZIndex = 3 })
	local face = piece(die, { Name = "Face", Anchor = Vector2.new(0, 0), Position = scale(0, 0), Size = scale(0.92, 0.92), Color = Color3.new(1, 1, 1), Radius = 0.24, ZIndex = 4,
		Gradient = { Color3.fromRGB(250, 253, 255), Color3.fromRGB(196, 222, 248) } })
	for _, p in ipairs({ { 0.27, 0.27 }, { 0.73, 0.27 }, { 0.5, 0.5 }, { 0.27, 0.73 }, { 0.73, 0.73 } }) do
		piece(face, { Position = scale(p[1], p[2]), Size = scale(0.2, 0.2), Color = Color3.fromRGB(38, 52, 104), Radius = 0.5, Outline = false, ZIndex = 5,
			Gradient = { Color3.fromRGB(70, 92, 160), Color3.fromRGB(30, 40, 86) } })
	end
	shine(face, 0.1, 0.07, 0.36, 0.12, 6)
end

-- a backpack (Inventory): orange body, darker flap, pocket, gold buckle,
-- a handle loop on top
function Sticker.art.backpack(art)
	piece(art, { Name = "Handle", Position = scale(0.5, 0.16), Size = scale(0.34, 0.2), Color = Color3.fromRGB(0, 0, 0), Transparency = 1, Radius = 0.5, Thickness = 5, ZIndex = 2 })
	piece(art, { Name = "Body", Position = scale(0.5, 0.58), Size = scale(0.72, 0.68), Color = Color3.new(1, 1, 1), Radius = 0.26, ZIndex = 3,
		Gradient = { Color3.fromRGB(255, 176, 72), Color3.fromRGB(232, 112, 30) } })
	piece(art, { Name = "Flap", Position = scale(0.5, 0.39), Size = scale(0.74, 0.32), Color = Color3.new(1, 1, 1), Radius = 0.4, ZIndex = 4,
		Gradient = { Color3.fromRGB(226, 108, 34), Color3.fromRGB(196, 80, 22) } })
	piece(art, { Name = "Pocket", Position = scale(0.5, 0.72), Size = scale(0.44, 0.26), Color = Color3.fromRGB(255, 196, 110), Radius = 0.3, ZIndex = 5 })
	piece(art, { Name = "Buckle", Position = scale(0.5, 0.53), Size = scale(0.16, 0.13), Color = Color3.fromRGB(255, 220, 80), Radius = 0.25, ZIndex = 6 })
	shine(art, 0.2, 0.28, 0.24, 0.08, 7)
end

-- a book (Index): blue cover with pages showing and a gold star
function Sticker.art.book(art)
	local book = Ui.new("Frame", { Name = "Book", AnchorPoint = Vector2.new(0.5, 0.5), Position = scale(0.5, 0.5), Size = scale(0.78, 0.84), Rotation = -10, BackgroundTransparency = 1, ZIndex = 3, Parent = art })
	piece(book, { Name = "Back", Anchor = Vector2.new(0, 0), Position = scale(0.08, 0.06), Size = scale(0.92, 0.94), Color = Color3.fromRGB(70, 60, 170), Radius = 0.14, ZIndex = 3 })
	piece(book, { Name = "Pages", Anchor = Vector2.new(0, 0), Position = scale(0.06, 0.03), Size = scale(0.9, 0.9), Color = Color3.fromRGB(255, 250, 236), Radius = 0.1, ZIndex = 4 })
	local cover = piece(book, { Name = "Cover", Anchor = Vector2.new(0, 0), Position = scale(0, 0), Size = scale(0.86, 0.88), Color = Color3.new(1, 1, 1), Radius = 0.14, ZIndex = 5,
		Gradient = { Color3.fromRGB(130, 150, 255), Color3.fromRGB(88, 92, 230) } })
	piece(cover, { Name = "Spine", Anchor = Vector2.new(0, 0), Position = scale(0, 0), Size = scale(0.16, 1), Color = Color3.fromRGB(70, 66, 190), Radius = 0.14, Outline = false, ZIndex = 6 })
	local star = Ui.new("Frame", { Name = "Star", AnchorPoint = Vector2.new(0.5, 0.5), Position = scale(0.58, 0.5), Size = scale(0.52, 0.52), BackgroundTransparency = 1, ZIndex = 7, Parent = cover })
	Ui.icons.star(star, Color3.fromRGB(255, 214, 70))
	for _, d in ipairs(star:GetDescendants()) do
		if d:IsA("GuiObject") then
			d.ZIndex = 7
		end
	end
	shine(cover, 0.24, 0.07, 0.4, 0.09, 8)
end

-- an arrowhead made of a turned square, clipped to its top half
local function arrowHead(parent, center, width, color, z, outline)
	local clip = Ui.new("CanvasGroup", {
		Name = "Head",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = center,
		Size = UDim2.fromScale(width, width * 0.5),
		BackgroundTransparency = 1,
		ZIndex = z,
		Parent = parent,
	})
	local side = 1 / math.sqrt(2)
	Ui.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 1),
		Size = UDim2.fromScale(side, side * 2),
		Rotation = 45,
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		Parent = clip,
	}, { Ui.new("UIAspectRatioConstraint", { AspectRatio = 1 }) })
	if outline then
		clip.GroupColor3 = Color3.new(1, 1, 1)
	end
	return clip
end

-- a chunky green up arrow (Upgrades): drawn twice, a dark one a little
-- bigger behind for the outline
function Sticker.art.upgrade(art)
	for _, layer in ipairs({ { INK, 0.04, 2 }, { Color3.fromRGB(70, 210, 90), 0, 3 } }) do
		local grow = layer[2]
		arrowHead(art, scale(0.5, 0.52 + grow * 0.3), 0.82 + grow * 2.2, layer[1], layer[3])
		Ui.new("Frame", {
			Name = "Stem",
			AnchorPoint = Vector2.new(0.5, 0),
			Position = scale(0.5, 0.5 - grow * 0.4),
			Size = scale(0.36 + grow * 2, 0.4 + grow * 2),
			BackgroundColor3 = layer[1],
			BorderSizePixel = 0,
			ZIndex = layer[3],
			Parent = art,
		}, { Ui.corner(0.12) })
	end
	-- a darker lower half for depth
	Ui.new("Frame", {
		Name = "Shade",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = scale(0.5, 0.7),
		Size = scale(0.36, 0.2),
		BackgroundColor3 = Color3.fromRGB(40, 160, 70),
		BorderSizePixel = 0,
		ZIndex = 4,
		Parent = art,
	}, { Ui.corner(0.12) })
	shine(art, 0.44, 0.24, 0.1, 0.4, 6).Rotation = 0
end

-- a portal (Teleport): a purple ring around a swirl of cyan and violet, a sparkle
function Sticker.art.portal(art)
	piece(art, { Name = "Ring", Position = scale(0.5, 0.52), Size = scale(0.86, 0.86), Color = Color3.new(1, 1, 1), Radius = 0.5, ZIndex = 3,
		Gradient = { Color3.fromRGB(190, 120, 255), Color3.fromRGB(120, 60, 220) } })
	local inner = piece(art, { Name = "Swirl", Position = scale(0.5, 0.52), Size = scale(0.62, 0.62), Color = Color3.new(1, 1, 1), Radius = 0.5, ZIndex = 4,
		Gradient = { Color3.fromRGB(120, 240, 255), Color3.fromRGB(150, 90, 255) }, GradientRotation = 45 })
	piece(inner, { Name = "Core", Position = scale(0.5, 0.5), Size = scale(0.42, 0.42), Color = Color3.fromRGB(240, 250, 255), Radius = 0.5, Outline = false, ZIndex = 5,
		Gradient = { Color3.fromRGB(255, 255, 255), Color3.fromRGB(170, 230, 255) } })
	for k = 0, 1 do
		piece(art, { Name = "Spark", Position = scale(0.8, 0.18), Size = scale(0.08, 0.26), Rotation = k * 90, Color = Color3.fromRGB(255, 240, 150), Radius = 0.5, Thickness = 2, ZIndex = 6 })
	end
	shine(art, 0.2, 0.2, 0.22, 0.08, 6).Rotation = -35
end

-- a crown (Rebirth): gold with three points, balls on the tips and a red gem
function Sticker.art.crown(art)
	local gold = { Color3.fromRGB(255, 226, 90), Color3.fromRGB(240, 160, 30) }
	for _, p in ipairs({ { 0.2, 0.42, -18 }, { 0.5, 0.34, 0 }, { 0.8, 0.42, 18 } }) do
		piece(art, { Name = "Point", Position = scale(p[1], p[2] + 0.1), Size = scale(0.34, 0.34), Rotation = 45 + p[3], Color = Color3.new(1, 1, 1), Radius = 0.12, ZIndex = 3, Gradient = gold })
		piece(art, { Name = "Tip", Position = scale(p[1], p[2] - 0.12), Size = scale(0.14, 0.14), Color = Color3.fromRGB(255, 236, 140), Radius = 0.5, ZIndex = 4 })
	end
	piece(art, { Name = "Band", Position = scale(0.5, 0.66), Size = scale(0.84, 0.36), Color = Color3.new(1, 1, 1), Radius = 0.16, ZIndex = 5, Gradient = gold })
	piece(art, { Name = "Gem", Position = scale(0.5, 0.66), Size = scale(0.2, 0.2), Rotation = 45, Color = Color3.new(1, 1, 1), Radius = 0.15, ZIndex = 6,
		Gradient = { Color3.fromRGB(255, 110, 140), Color3.fromRGB(200, 30, 70) } })
	for _, x in ipairs({ 0.24, 0.76 }) do
		piece(art, { Name = "Jewel", Position = scale(x, 0.66), Size = scale(0.1, 0.1), Color = Color3.fromRGB(110, 210, 255), Radius = 0.5, Thickness = 2, ZIndex = 6 })
	end
	shine(art, 0.16, 0.53, 0.24, 0.07, 7)
end

-- a gear (Settings): grey teeth around a ring with a hole
function Sticker.art.gear(art)
	local grey = { Color3.fromRGB(214, 222, 236), Color3.fromRGB(150, 160, 182) }
	for k = 0, 3 do
		piece(art, { Name = "Teeth", Position = scale(0.5, 0.5), Size = scale(0.2, 0.9), Rotation = k * 45, Color = Color3.new(1, 1, 1), Radius = 0.25, ZIndex = 3, Gradient = grey })
	end
	piece(art, { Name = "Wheel", Position = scale(0.5, 0.5), Size = scale(0.7, 0.7), Color = Color3.new(1, 1, 1), Radius = 0.5, ZIndex = 4, Gradient = grey })
	piece(art, { Name = "Hole", Position = scale(0.5, 0.5), Size = scale(0.28, 0.28), Color = Color3.fromRGB(90, 100, 130), Radius = 0.5, ZIndex = 5 })
	shine(art, 0.26, 0.24, 0.2, 0.07, 6).Rotation = -30
end

-- the auto switch: a round badge (grey off, green on) with two white
-- chevrons ">>"
function Sticker.art.auto(art)
	local badge = piece(art, { Name = "Badge", Position = scale(0.5, 0.5), Size = scale(0.84, 0.84), Color = Color3.new(1, 1, 1), Radius = 0.5, ZIndex = 3,
		Gradient = { Color3.fromRGB(200, 206, 222), Color3.fromRGB(140, 148, 172) } })
	local glyph = Ui.new("Frame", { Name = "Glyph", AnchorPoint = Vector2.new(0.5, 0.5), Position = scale(0.5, 0.5), Size = scale(0.56, 0.56), BackgroundTransparency = 1, ZIndex = 5, Parent = badge })
	Ui.icons.auto(glyph, Color3.new(1, 1, 1))
	for _, d in ipairs(glyph:GetDescendants()) do
		if d:IsA("GuiObject") then
			d.ZIndex = 5
			Ui.new("UIStroke", { Color = INK, Thickness = 2, Parent = d })
		end
	end
	shine(badge, 0.2, 0.1, 0.4, 0.12, 6)
end

-- recolours the auto switch: green when on (the round badge, or the dice's face)
function Sticker.setAuto(button, on)
	local art = button:FindFirstChild("Art")
	local die = art and art:FindFirstChild("Die")
	local face = die and die:FindFirstChild("Face")
	local faceGradient = face and face:FindFirstChildOfClass("UIGradient")
	if faceGradient then
		faceGradient.Color = if on
			then ColorSequence.new(Color3.fromRGB(200, 255, 200), Color3.fromRGB(90, 214, 120))
			else ColorSequence.new(Color3.fromRGB(250, 253, 255), Color3.fromRGB(196, 222, 248))
	end
	local badge = art and art:FindFirstChild("Badge")
	local gradient = badge and badge:FindFirstChildOfClass("UIGradient")
	if gradient then
		gradient.Color = if on
			then ColorSequence.new(Color3.fromRGB(110, 236, 140), Color3.fromRGB(40, 178, 96))
			else ColorSequence.new(Color3.fromRGB(200, 206, 222), Color3.fromRGB(140, 148, 172))
	end
	button:SetAttribute("On", on)
end

-- Turns a drawn icon into its own darker bottom edge: every colour (or the
-- end colour of its gradient) gets much darker, shines go, outlines stay
function Sticker.darken(root)
	for _, d in ipairs(root:GetDescendants()) do
		if d.Name == "Shine" then
			d:Destroy()
		end
	end
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("GuiObject") then
			local color = d.BackgroundColor3
			local gradient = d:FindFirstChildOfClass("UIGradient")
			if gradient then
				local keys = gradient.Color.Keypoints
				color = keys[#keys].Value
				gradient:Destroy()
			end
			if color then -- (frames that only hold other pieces have none worth darkening)
				d.BackgroundColor3 = color:Lerp(INK, 0.45)
			end
			d.ZIndex = math.max(1, (d.ZIndex or 3) - 1)
		end
	end
end

-- The button --------------------------------------------------------------------------------------

function Sticker.button(props, onClick)
	local size = props.Size or 64
	local captionSize = props.CaptionSize or math.max(13, math.floor(size * 0.27))
	local holder = Ui.new("Frame", {
		Name = props.Name or props.Label or "Sticker",
		LayoutOrder = props.LayoutOrder or 0,
		Size = UDim2.fromOffset(size, size + math.floor(captionSize * 0.6)),
		BackgroundTransparency = 1,
		Parent = props.Parent,
	})
	local button = Ui.new("TextButton", {
		Name = "Button",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0),
		Size = UDim2.fromOffset(size, size),
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
		ZIndex = 2,
		Parent = holder,
	})
	local art = Ui.new("Frame", {
		Name = "Art",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ZIndex = 3,
		Parent = button,
	})
	local draw = Sticker.art[props.Art or "dice"]
	if draw then
		-- the 3D look: a soft shadow on the ground, then the same icon in
		-- darker colours a little lower (its thick bottom edge), then the icon
		Ui.new("Frame", {
			Name = "Shadow",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.94),
			Size = UDim2.fromScale(0.78, 0.16),
			BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = 0.72,
			ZIndex = 2,
			Parent = art,
		}, { Ui.corner(0.5) })
		local depth = Ui.new("Frame", {
			Name = "Depth",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, math.max(3, math.floor(size * 0.07))),
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			ZIndex = 2,
			Parent = art,
		})
		draw(depth)
		Sticker.darken(depth)
		local face = Ui.new("Frame", {
			Name = "Face",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			ZIndex = 3,
			Parent = art,
		})
		draw(face)
		-- (callers look for the icon's pieces right under Art)
		for _, child in ipairs(face:GetChildren()) do
			child.Parent = art
		end
		face:Destroy()
	end
	local caption = Ui.new("TextLabel", {
		Name = "Caption",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, size - math.floor(captionSize * 0.55)),
		Size = UDim2.new(1, 40, 0, captionSize + 4),
		BackgroundTransparency = 1,
		Font = Enum.Font.FredokaOne,
		TextScaled = false,
		TextSize = captionSize,
		Text = props.Label or "",
		TextColor3 = Color3.new(1, 1, 1),
		ZIndex = 9,
		Parent = holder,
	})
	Ui.new("UIStroke", { Color = INK, Thickness = math.max(2.5, captionSize / 7), LineJoinMode = Enum.LineJoinMode.Round, Parent = caption })

	-- hover: grow and tilt; press: squash
	local grow = Ui.new("UIScale", { Parent = art })
	local function to(s, r)
		if Ui.reduced() then
			return
		end
		TweenService:Create(grow, TweenInfo.new(0.18, Enum.EasingStyle.Back), { Scale = s }):Play()
		TweenService:Create(art, TweenInfo.new(0.18, Enum.EasingStyle.Back), { Rotation = r }):Play()
	end
	button.MouseEnter:Connect(function()
		to(1.1, -6)
	end)
	button.MouseLeave:Connect(function()
		to(1, 0)
	end)
	button.MouseButton1Down:Connect(function()
		to(0.9, 0)
	end)
	button.MouseButton1Up:Connect(function()
		to(1.1, -6)
	end)
	button.Activated:Connect(function()
		if onClick then
			onClick()
		end
	end)
	return holder, button
end

return Sticker
