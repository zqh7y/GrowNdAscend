-- UI theme and helpers. The look is clean, calm and friendly, like a
-- premium casual game: white rounded panels with soft shadows, light grey
-- cards, clear dark text, a rounded display font for headings, solid
-- friendly colours on buttons, and simple icons drawn with frames (no image
-- assets needed). It should feel expensive because it's clean, not because
-- of effects.
local TweenService = game:GetService("TweenService")

local State = require(script.Parent.State)

local Ui = {}

-- true when the player asked for calmer animations (Settings)
function Ui.reduced()
	return State.Settings.ReducedMotion == true
end

-- Theme --------------------------------------------------------------------------

Ui.FONT = Enum.Font.GothamBold -- buttons, numbers, names
Ui.FONT_TITLE = Enum.Font.GothamBlack -- small labels and tags
Ui.FONT_DISPLAY = Enum.Font.FredokaOne -- headings and big moments (friendly)
Ui.FONT_MEDIUM = Enum.Font.GothamMedium -- small print

Ui.GLASS = Color3.fromRGB(255, 255, 255) -- panels
Ui.GLASS_LIGHT = Color3.fromRGB(243, 245, 250) -- cards on panels
Ui.LINE = Color3.fromRGB(224, 228, 238) -- hairlines
Ui.INK = Color3.fromRGB(34, 38, 56) -- dark text
Ui.TEXT = Color3.fromRGB(34, 38, 56)
Ui.MUTED = Color3.fromRGB(130, 136, 158)
Ui.WHITE = Color3.new(1, 1, 1)
Ui.BLUE = Color3.fromRGB(64, 132, 255)
Ui.PURPLE = Color3.fromRGB(140, 102, 240)
Ui.PINK = Color3.fromRGB(255, 104, 150)
-- (older names, kept so every screen picks up the new colours)
Ui.CYAN = Ui.BLUE
Ui.VIOLET = Ui.PURPLE
Ui.MAGENTA = Ui.PINK
Ui.PRIMARY_A = Color3.fromRGB(88, 156, 255)
Ui.PRIMARY_B = Color3.fromRGB(56, 112, 245)
Ui.ACCENT = Ui.BLUE
Ui.SUCCESS = Color3.fromRGB(46, 196, 120)
Ui.DANGER = Color3.fromRGB(240, 82, 96)
Ui.GOLD = Color3.fromRGB(255, 186, 40)
Ui.PANEL_TRANSPARENCY = 0.06

-- Basics -------------------------------------------------------------------------

-- Ui.new("Frame", { props }, { children })
function Ui.new(className, props, children)
	local inst = Instance.new(className)
	if inst:IsA("GuiObject") then
		inst.BorderSizePixel = 0
	end
	if inst:IsA("TextLabel") or inst:IsA("TextButton") then
		inst.Font = Ui.FONT
		inst.TextColor3 = Ui.TEXT
		inst.TextScaled = true
		inst.BackgroundTransparency = 1
	end
	for k, v in pairs(props or {}) do
		if k ~= "Parent" then
			inst[k] = v
		end
	end
	for _, child in ipairs(children or {}) do
		child.Parent = inst
	end
	if props and props.Parent then
		inst.Parent = props.Parent
	end
	return inst
end

function Ui.corner(radius)
	return Ui.new("UICorner", { CornerRadius = if radius < 1 then UDim.new(radius, 0) else UDim.new(0, radius) })
end

function Ui.stroke(color, thickness, transparency)
	return Ui.new("UIStroke", {
		Color = color,
		Thickness = thickness or 1.5,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

function Ui.padding(px)
	return Ui.new("UIPadding", {
		PaddingTop = UDim.new(0, px),
		PaddingBottom = UDim.new(0, px),
		PaddingLeft = UDim.new(0, px),
		PaddingRight = UDim.new(0, px),
	})
end

-- A white rounded panel with a hairline edge (HUD pills, small panels)
function Ui.glass(props, children)
	local radius = props.Radius or 14
	props.Radius = nil
	props.BackgroundColor3 = props.BackgroundColor3 or Ui.GLASS
	props.BackgroundTransparency = props.BackgroundTransparency or Ui.PANEL_TRANSPARENCY
	local frame = Ui.new("Frame", props, children)
	Ui.corner(radius).Parent = frame
	local edge = Ui.stroke(Ui.LINE, 1, 0)
	edge.Name = "Edge"
	edge.Parent = frame
	return frame
end

-- (kept for older screens: the clean style has no accent lines or corner
-- brackets, so these draw nothing)
function Ui.accentLine(parent)
	return Ui.new("Frame", { Name = "Accent", BackgroundTransparency = 1, Size = UDim2.fromOffset(0, 0), Parent = parent })
end
function Ui.brackets() end

-- A card on a panel: light grey, rounded, with a soft edge that takes the
-- `accent` colour gently (rarity, etc.)
function Ui.card(props, accent, children)
	local radius = props.Radius or 12
	props.Radius = nil
	props.BackgroundColor3 = props.BackgroundColor3 or Ui.GLASS_LIGHT
	props.BackgroundTransparency = props.BackgroundTransparency or 0
	local frame = Ui.new("Frame", props, children)
	Ui.corner(radius).Parent = frame
	local edge = Ui.stroke(if accent then accent:Lerp(Ui.LINE, 0.45) else Ui.LINE, if accent then 1.5 else 1, 0)
	edge.Name = "Edge"
	edge.Parent = frame
	return frame
end

-- A soft drop shadow under a frame (a dark rounded frame behind it)
function Ui.shadow(frame, radius, offset)
	return Ui.new("Frame", {
		Name = "Shadow",
		AnchorPoint = frame.AnchorPoint,
		Position = frame.Position + UDim2.fromOffset(0, offset or 4),
		Size = frame.Size,
		BackgroundColor3 = Color3.fromRGB(20, 24, 40),
		BackgroundTransparency = 0.85,
		ZIndex = math.max((frame.ZIndex or 1) - 1, 0),
		Parent = frame.Parent,
	}, { Ui.corner(radius or 14) })
end

-- Icons (line icons drawn with frames; they fill their parent) ----------------------

local function dot(parent, x, y, size, color)
	return Ui.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(x, y),
		Size = UDim2.fromScale(size, size),
		BackgroundColor3 = color,
		Parent = parent,
	}, { Ui.corner(0.5) })
end

local function bar(parent, props)
	props.Parent = parent
	return Ui.new("Frame", props, { Ui.corner(0.5) })
end

local function outline(parent, x, y, size, radius, color)
	return Ui.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(x, y),
		Size = UDim2.fromScale(size, size),
		BackgroundTransparency = 1,
		Parent = parent,
	}, { Ui.corner(radius), Ui.stroke(color, 2.5) })
end

Ui.icons = {}

-- rounded die with three pips
function Ui.icons.dice(parent, color)
	local box = outline(parent, 0.5, 0.5, 0.86, 0.28, color)
	dot(box, 0.28, 0.28, 0.2, color)
	dot(box, 0.5, 0.5, 0.2, color)
	dot(box, 0.72, 0.72, 0.2, color)
end

-- 2x2 grid of rounded squares (collection)
function Ui.icons.grid(parent, color)
	for _, pos in ipairs({ { 0.27, 0.27 }, { 0.73, 0.27 }, { 0.27, 0.73 }, { 0.73, 0.73 } }) do
		outline(parent, pos[1], pos[2], 0.38, 0.3, color)
	end
end

-- three podium bars (leaderboard)
function Ui.icons.podium(parent, color)
	for _, b in ipairs({ { 0.2, 0.55 }, { 0.5, 0.9 }, { 0.8, 0.4 } }) do
		bar(parent, {
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.fromScale(b[1], 0.95),
			Size = UDim2.fromScale(0.22, b[2]),
			BackgroundColor3 = color,
		})
	end
end

-- open ring with a dot at the end (auto / repeat)
function Ui.icons.loop(parent, color)
	local ring = outline(parent, 0.5, 0.5, 0.78, 0.5, color)
	-- fade out a slice of the ring to leave a gap
	Ui.new("UIGradient", {
		Rotation = 45,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.72, 0),
			NumberSequenceKeypoint.new(0.8, 1),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Parent = ring:FindFirstChildOfClass("UIStroke"),
	})
	dot(parent, 0.8, 0.38, 0.2, color)
end

-- two bold chevrons ">>" (auto / fast forward)
function Ui.icons.auto(parent, color)
	for _, cx in ipairs({ 0.43, 0.73 }) do
		for _, side in ipairs({ -1, 1 }) do
			bar(parent, {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(cx - 0.08, 0.5 + side * 0.14),
				Size = UDim2.fromScale(0.42, 0.15),
				Rotation = side * 45,
				BackgroundColor3 = color,
			})
		end
	end
end

-- padlock (locked)
function Ui.icons.lock(parent, color)
	local shackle = outline(parent, 0.5, 0.36, 0.46, 0.5, color)
	shackle.Size = UDim2.fromScale(0.46, 0.5)
	Ui.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.45),
		Size = UDim2.fromScale(0.72, 0.5),
		BackgroundColor3 = color,
		Parent = parent,
	}, { Ui.corner(0.2) })
end

-- X (close)
function Ui.icons.close(parent, color)
	for _, angle in ipairs({ 45, -45 }) do
		bar(parent, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.95, 0.14),
			Rotation = angle,
			BackgroundColor3 = color,
		})
	end
end

-- four-point sparkle (luck / bonus)
function Ui.icons.spark(parent, color)
	for _, angle in ipairs({ 0, 90 }) do
		bar(parent, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.95, 0.14),
			Rotation = angle,
			BackgroundColor3 = color,
		})
	end
	dot(parent, 0.5, 0.5, 0.34, color)
end

-- gold coin with a ring and a shine
function Ui.icons.coin(parent, color)
	local coin = dot(parent, 0.5, 0.5, 0.92, color)
	Ui.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.58, 0.58),
		BackgroundTransparency = 1,
		Parent = coin,
	}, { Ui.corner(0.5), Ui.stroke(color:Lerp(Color3.new(0, 0, 0), 0.25), 2) })
	dot(coin, 0.32, 0.3, 0.18, Color3.new(1, 1, 1))
end

-- a sword pointing up and to the right
function Ui.icons.sword(parent, color)
	local holder = Ui.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Rotation = 45, Parent = parent })
	bar(holder, { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.02), Size = UDim2.fromScale(0.16, 0.62), BackgroundColor3 = color })
	bar(holder, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.68), Size = UDim2.fromScale(0.52, 0.12), BackgroundColor3 = color })
	bar(holder, { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.72), Size = UDim2.fromScale(0.13, 0.26), BackgroundColor3 = color })
end

-- four-leaf clover
function Ui.icons.clover(parent, color)
	for _, p in ipairs({ { 0.5, 0.26 }, { 0.26, 0.5 }, { 0.74, 0.5 }, { 0.5, 0.74 } }) do
		dot(parent, p[1], p[2], 0.44, color)
	end
	dot(parent, 0.5, 0.5, 0.2, color:Lerp(Color3.new(1, 1, 1), 0.4))
end

-- lightning bolt
function Ui.icons.bolt(parent, color)
	bar(parent, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.56, 0.3), Size = UDim2.fromScale(0.2, 0.5), Rotation = 25, BackgroundColor3 = color })
	bar(parent, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.5, 0.16), Rotation = -10, BackgroundColor3 = color })
	bar(parent, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.44, 0.7), Size = UDim2.fromScale(0.2, 0.5), Rotation = 25, BackgroundColor3 = color })
end

-- a small square and a big one with an arrow between (size)
function Ui.icons.grow(parent, color)
	outline(parent, 0.3, 0.7, 0.3, 0.25, color)
	outline(parent, 0.62, 0.38, 0.62, 0.2, color)
	bar(parent, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.4, 0.12), Rotation = -45, BackgroundColor3 = color })
end

-- paw print
function Ui.icons.paw(parent, color)
	local pad = dot(parent, 0.5, 0.66, 0.5, color)
	pad.Size = UDim2.fromScale(0.52, 0.42)
	for _, p in ipairs({ { 0.2, 0.42 }, { 0.37, 0.2 }, { 0.63, 0.2 }, { 0.8, 0.42 } }) do
		dot(parent, p[1], p[2], 0.22, color)
	end
end

-- round tree with a trunk (the upgrade tree)
function Ui.icons.tree(parent, color)
	bar(parent, { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 0.98), Size = UDim2.fromScale(0.18, 0.42), BackgroundColor3 = color })
	dot(parent, 0.5, 0.36, 0.58, color)
	dot(parent, 0.27, 0.5, 0.36, color)
	dot(parent, 0.73, 0.5, 0.36, color)
end

-- Odds text in two colours mixing diagonally: `from` at the bottom-left
-- into `to` at the top-right (uses the label's "Tint" gradient)
function Ui.diagonal(label, from, to)
	local tint = label:FindFirstChild("Tint") or Ui.new("UIGradient", { Name = "Tint", Parent = label })
	tint.Color = ColorSequence.new(from, to)
	tint.Rotation = -45
	label.TextColor3 = Color3.new(1, 1, 1)
	return tint
end

-- teleport: a portal ring with a spark in the middle
function Ui.icons.teleport(parent, color)
	outline(parent, 0.5, 0.5, 0.84, 0.5, color)
	outline(parent, 0.5, 0.5, 0.5, 0.5, color)
	dot(parent, 0.5, 0.5, 0.18, color)
end

-- gear (settings)
function Ui.icons.gear(parent, color)
	for k = 0, 7 do
		bar(parent, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.2, 0.96),
			Rotation = k * 22.5,
			BackgroundColor3 = color,
		}).UICorner.CornerRadius = UDim.new(0.2, 0)
	end
	dot(parent, 0.5, 0.5, 0.72, color)
	local hole = dot(parent, 0.5, 0.5, 0.3, color)
	hole.BackgroundTransparency = 1
	Ui.stroke(color, 2).Parent = hole
end

-- five-point star, drawn as a sparkle with a round centre (rebirth)
function Ui.icons.star(parent, color)
	for k = 0, 4 do
		bar(parent, {
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.fromScale(0.5, 0.55),
			Size = UDim2.fromScale(0.2, 0.5),
			Rotation = k * 72,
			BackgroundColor3 = color,
		})
	end
	dot(parent, 0.5, 0.55, 0.42, color)
end

-- an open book (the animal index)
function Ui.icons.book(parent, color)
	for _, side in ipairs({ -1, 1 }) do
		local page = outline(parent, 0.5 + side * 0.22, 0.52, 0.44, 0.15, color)
		page.Size = UDim2.fromScale(0.42, 0.7)
		page.Rotation = side * 6
		for k = 0, 1 do
			bar(page, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.36 + k * 0.26), Size = UDim2.fromScale(0.5, 0.09), BackgroundColor3 = color })
		end
	end
end

-- an eye (show / hide)
function Ui.icons.eye(parent, color)
	local lid = outline(parent, 0.5, 0.5, 0.9, 0.5, color)
	lid.Size = UDim2.fromScale(0.92, 0.56)
	dot(parent, 0.5, 0.5, 0.3, color)
end

-- three lines, shortest last (sorting)
function Ui.icons.sort(parent, color)
	for k = 0, 2 do
		bar(parent, { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0.08, 0.25 + k * 0.25), Size = UDim2.fromScale(0.84 - k * 0.24, 0.12), BackgroundColor3 = color })
	end
end

-- A standalone icon of the given pixel size
function Ui.icon(name, size, color, props)
	props = props or {}
	props.Size = UDim2.fromOffset(size, size)
	props.BackgroundTransparency = 1
	local holder = Ui.new("Frame", props)
	holder.Name = "Icon"
	Ui.icons[name](holder, color or Ui.TEXT)
	return holder
end

-- Buttons ------------------------------------------------------------------------

-- A = gradient fill (bright), else Fill; Edge = the thin outline; Text/Icon
-- colours (dark text on bright fills). The colour styles are dark tinted
-- glass with a neon edge and a neon icon.
-- A/B = a soft vertical gradient fill, else Fill; Edge = the outline;
-- Text = text and icon colour. Coloured styles are solid and friendly.
local STYLES = {
	primary = { A = Color3.fromRGB(92, 160, 255), B = Color3.fromRGB(56, 112, 245), Edge = Color3.fromRGB(56, 112, 245), EdgeT = 0.7, Text = Ui.WHITE },
	glass = { Fill = Ui.GLASS, FillT = 0, Edge = Ui.LINE, EdgeT = 0 },
	success = { A = Color3.fromRGB(70, 214, 140), B = Color3.fromRGB(38, 178, 108), Edge = Color3.fromRGB(38, 178, 108), EdgeT = 0.7, Text = Ui.WHITE },
	danger = { A = Color3.fromRGB(250, 110, 120), B = Color3.fromRGB(226, 70, 86), Edge = Color3.fromRGB(226, 70, 86), EdgeT = 0.7, Text = Ui.WHITE },
	disabled = { Fill = Color3.fromRGB(236, 238, 244), FillT = 0, Edge = Ui.LINE, EdgeT = 0, Text = Color3.fromRGB(160, 165, 184) },
	blue = { A = Color3.fromRGB(92, 160, 255), B = Color3.fromRGB(56, 112, 245), Edge = Color3.fromRGB(56, 112, 245), EdgeT = 0.7, Text = Ui.WHITE },
	green = { A = Color3.fromRGB(70, 214, 140), B = Color3.fromRGB(38, 178, 108), Edge = Color3.fromRGB(38, 178, 108), EdgeT = 0.7, Text = Ui.WHITE },
	purple = { A = Color3.fromRGB(170, 134, 255), B = Color3.fromRGB(126, 88, 230), Edge = Color3.fromRGB(126, 88, 230), EdgeT = 0.7, Text = Ui.WHITE },
	gold = { A = Color3.fromRGB(255, 206, 80), B = Color3.fromRGB(245, 168, 30), Edge = Color3.fromRGB(245, 168, 30), EdgeT = 0.7, Text = Ui.WHITE },
	orange = { A = Color3.fromRGB(255, 170, 90), B = Color3.fromRGB(245, 128, 50), Edge = Color3.fromRGB(245, 128, 50), EdgeT = 0.7, Text = Ui.WHITE },
	gray = { A = Color3.fromRGB(168, 176, 198), B = Color3.fromRGB(128, 136, 160), Edge = Color3.fromRGB(128, 136, 160), EdgeT = 0.7, Text = Ui.WHITE },
	magenta = { A = Color3.fromRGB(255, 130, 175), B = Color3.fromRGB(236, 84, 136), Edge = Color3.fromRGB(236, 84, 136), EdgeT = 0.7, Text = Ui.WHITE },
}
Ui.STYLES = STYLES

-- Restyles a button: "primary", "glass", "success", "danger", "disabled",
-- or a colour: "blue", "green", "purple", "gold", "orange", "gray"
function Ui.setStyle(button, styleName)
	if button:GetAttribute("Style") == styleName then
		return
	end
	local style = STYLES[styleName]
	local fill = button:FindFirstChild("Fill")
	button:SetAttribute("Style", styleName)
	if style.A then
		button.BackgroundColor3 = Color3.new(1, 1, 1)
		button.BackgroundTransparency = 0
		fill.Enabled = true
		fill.Color = ColorSequence.new(style.A, style.B)
		fill.Rotation = 90
	else
		button.BackgroundColor3 = style.Fill
		button.BackgroundTransparency = style.FillT
		fill.Enabled = false
	end
	button.Edge.Transparency = style.EdgeT
	button.Edge.Color = style.Edge or Ui.LINE
	button.Content.Label.TextStrokeTransparency = 1
	local color = style.Text or Ui.TEXT
	local iconColor = style.Icon or color
	local content = button.Content
	content.Label.TextColor3 = color
	for _, d in ipairs(content:GetDescendants()) do
		if d:IsA("Frame") and d.BackgroundTransparency < 1 then
			d.BackgroundColor3 = iconColor
		elseif d:IsA("UIStroke") then
			d.Color = iconColor
		end
	end
end

function Ui.setText(button, text)
	button.Content.Label.Text = text
	button.Content.Label.Visible = text ~= ""
end

-- Swaps a button's icon ("dice", "lock", ...) or removes it (nil)
function Ui.setIcon(button, iconName)
	if button:GetAttribute("IconName") == iconName then
		return
	end
	button:SetAttribute("IconName", iconName)
	local content = button.Content
	local old = content:FindFirstChild("Icon")
	if old then
		old:Destroy()
	end
	if iconName then
		local size = button:GetAttribute("IconSize")
		Ui.icon(iconName, size, content.Label.TextColor3, { LayoutOrder = 0, Parent = content })
	end
end

-- A soft rounded button: an optional line icon and a label, centred.
-- props: usual GuiObject props plus Text, Icon, TextSize, IconSize, Radius.
function Ui.button(props, onClick, styleName)
	local text = props.Text or ""
	local iconName = props.Icon
	local textSize = props.TextSize or 20
	local iconSize = props.IconSize or math.floor(textSize * 1.1)
	local radius = props.Radius or 12
	props.Text, props.Icon, props.TextSize, props.IconSize, props.Radius = "", nil, nil, nil, nil

	local button = Ui.new("TextButton", props, { Ui.corner(radius) })
	button.AutoButtonColor = false
	button:SetAttribute("IconSize", iconSize)
	Ui.new("UIGradient", { Name = "Fill", Parent = button })
	local edge = Ui.stroke(Ui.LINE, 1, 0)
	edge.Name = "Edge"
	edge.Parent = button

	local content = Ui.new("Frame", {
		Name = "Content",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Parent = button,
	}, {
		Ui.new("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, math.floor(textSize * 0.5)),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
	Ui.new("TextLabel", {
		Name = "Label",
		LayoutOrder = 1,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, textSize + 4),
		TextScaled = false,
		TextSize = textSize,
		Text = text,
		TextStrokeColor3 = Ui.INK,
		Visible = text ~= "",
		Parent = content,
	})
	if iconName then
		button:SetAttribute("IconName", iconName)
		Ui.icon(iconName, iconSize, Ui.TEXT, { LayoutOrder = 0, Parent = content })
	end
	Ui.setStyle(button, styleName or "glass")

	local scaler = Ui.new("UIScale", { Parent = button })
	local function settle()
		TweenService:Create(scaler, TweenInfo.new(0.2, Enum.EasingStyle.Back), { Scale = 1 }):Play()
		local style = STYLES[button:GetAttribute("Style")]
		TweenService:Create(edge, TweenInfo.new(0.2), { Transparency = style.EdgeT }):Play()
	end
	button.MouseEnter:Connect(function()
		TweenService:Create(scaler, TweenInfo.new(0.15, Enum.EasingStyle.Quint), { Scale = if Ui.reduced() then 1 else 1.04 }):Play()
		TweenService:Create(edge, TweenInfo.new(0.15), { Transparency = 0.25 }):Play()
	end)
	button.MouseLeave:Connect(settle)
	button.MouseButton1Down:Connect(function()
		TweenService:Create(scaler, TweenInfo.new(0.06), { Scale = if Ui.reduced() then 1 else 0.94 }):Play()
	end)
	button.MouseButton1Up:Connect(settle)
	button.Activated:Connect(onClick)
	return button
end

-- A compact square icon button with a small label underneath (the dock).
-- Returns the holder (for layout) and the button.
function Ui.dockButton(props, onClick)
	local size = props.Size or 56
	local holder = Ui.new("Frame", {
		Name = props.Name or props.Label or "DockButton",
		LayoutOrder = props.LayoutOrder or 0,
		Size = UDim2.fromOffset(size, size + 18),
		BackgroundTransparency = 1,
		Parent = props.Parent,
	})
	local button = Ui.button({
		Size = UDim2.fromOffset(size, size),
		Radius = math.floor(size * 0.32),
		Icon = props.Icon,
		IconSize = props.IconSize or math.floor(size * 0.5),
		Text = "",
		Parent = holder,
	}, onClick, props.Style or "glass")
	Ui.new("TextLabel", {
		Name = "Caption",
		Position = UDim2.new(0, -10, 0, size + 3),
		Size = UDim2.new(1, 20, 0, 14),
		TextScaled = false,
		Font = Ui.FONT,
		TextSize = 12,
		Text = props.Label or "",
		TextColor3 = Ui.WHITE,
		TextStrokeTransparency = 0.55,
		TextStrokeColor3 = Color3.fromRGB(20, 24, 40),
		Parent = holder,
	})
	return holder, button
end

-- A card arriving in a list: it grows in, a few milliseconds after the one
-- before it (capped, so long lists stay quick)
function Ui.appear(frame, order)
	if Ui.reduced() then
		return
	end
	local scaler = frame:FindFirstChildOfClass("UIScale") or Ui.new("UIScale", { Parent = frame })
	scaler.Scale = 0.9
	local delay = math.min((order or 0) * 0.015, 0.25)
	TweenService:Create(scaler, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, 0, false, delay), { Scale = 1 }):Play()
end

-- A quick "this changed" pop (equipping, claiming)
function Ui.pop(frame, amount)
	if Ui.reduced() then
		return
	end
	local scaler = frame:FindFirstChildOfClass("UIScale") or Ui.new("UIScale", { Parent = frame })
	scaler.Scale = amount or 1.08
	TweenService:Create(scaler, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Scale = 1 }):Play()
end

-- Shows a panel (or a modal's dark background) and eases its box in
function Ui.popIn(frame)
	local target = frame:FindFirstChild("Box") or frame
	local scaler = target:FindFirstChildOfClass("UIScale") or Ui.new("UIScale", { Parent = target })
	local fit = target:GetAttribute("Fit") or 1 -- (smaller on a small screen: Screen.fitScale)
	scaler.Scale = if Ui.reduced() then fit else fit * 0.9
	frame.Visible = true
	TweenService:Create(scaler, TweenInfo.new(0.24, Enum.EasingStyle.Quint), { Scale = fit }):Play()
end

-- Hexagons and chunky text (the collection look) ------------------------------------
-- A pointy-top hexagon is three rectangles (width 1, height 0.5 of the
-- hexagon's box) turned 0, 60 and 120 degrees. The colour layer sits in a
-- CanvasGroup so one gradient runs smoothly over the whole shape.

Ui.HEX_RATIO = math.sqrt(3) / 2 -- a pointy-top hexagon's width / height

local function hexRects(parent, color, zIndex)
	for _, angle in ipairs({ 0, 60, 120 }) do
		Ui.new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(1, 0.5),
			Rotation = angle,
			BackgroundColor3 = color,
			BorderSizePixel = 0,
			ZIndex = zIndex,
			Parent = parent,
		})
	end
end

-- A hexagon tile. props: Size (height; width follows), Position,
-- AnchorPoint, Colors = { top, bottom }, Edge (outline colour, or nil),
-- EdgeSize (pixels), ZIndex, Parent, Name. Returns the holder; put
-- content in it (it is a plain transparent frame of the hexagon's size).
function Ui.hexagon(props)
	local height = props.Size or 80
	local z = props.ZIndex or 2
	local holder = Ui.new("Frame", {
		Name = props.Name or "Hex",
		AnchorPoint = props.AnchorPoint or Vector2.new(0, 0),
		Position = props.Position or UDim2.new(),
		Size = UDim2.fromOffset(math.floor(height * Ui.HEX_RATIO + 0.5), height),
		BackgroundTransparency = 1,
		ZIndex = z,
		LayoutOrder = props.LayoutOrder or 0,
		Parent = props.Parent,
	})
	local edgeSize = if props.Edge then (props.EdgeSize or 3) else 0
	if props.Edge then
		local edge = Ui.new("Frame", {
			Name = "Edge",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			ZIndex = z,
			Parent = holder,
		})
		hexRects(edge, props.Edge, z)
	end
	local colors = props.Colors or { Ui.WHITE, Ui.GLASS_LIGHT }
	local fill = Ui.new("CanvasGroup", {
		Name = "Fill",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, -edgeSize * 2, 1, -edgeSize * 2),
		BackgroundTransparency = 1,
		ZIndex = z,
		Parent = holder,
	}, {
		Ui.new("UIGradient", { Name = "Tint", Rotation = 90, Color = ColorSequence.new(colors[1], colors[2] or colors[1]) }),
	})
	hexRects(fill, Ui.WHITE, z)
	return holder
end

-- Recolours a hexagon made by Ui.hexagon
function Ui.setHexColors(hex, top, bottom, edge)
	hex.Fill.Tint.Color = ColorSequence.new(top, bottom or top)
	local edgeFrame = hex:FindFirstChild("Edge")
	if edgeFrame and edge then
		for _, rect in ipairs(edgeFrame:GetChildren()) do
			if rect:IsA("Frame") then
				rect.BackgroundColor3 = edge
			end
		end
	end
end

-- Big friendly outlined text (white with a dark outline, or a two-colour
-- gradient). props: the usual TextLabel props plus Colors = { top, bottom }
-- and Outline (thickness, default 2.5).
Ui.OUTLINE = Color3.fromRGB(28, 22, 40)
function Ui.chunky(props)
	local colors = props.Colors
	local outline = props.Outline or 2.5
	props.Colors, props.Outline = nil, nil
	props.Font = props.Font or Ui.FONT_DISPLAY
	props.TextScaled = false
	props.BackgroundTransparency = 1
	props.TextColor3 = props.TextColor3 or Ui.WHITE
	local label = Ui.new("TextLabel", props)
	Ui.new("UIStroke", { Name = "Outline", Color = Ui.OUTLINE, Thickness = outline, Parent = label })
	if colors then
		Ui.new("UIGradient", { Name = "Tint", Rotation = 90, Color = ColorSequence.new(colors[1], colors[2] or colors[1]), Parent = label })
	end
	return label
end

-- The two colours for something of this rarity (light on top, deeper below)
function Ui.rarityColors(color)
	return color:Lerp(Ui.WHITE, 0.35), color:Lerp(Color3.new(0, 0, 0), 0.12)
end

return Ui
