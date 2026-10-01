-- UI theme and helpers. The look is sleek and futuristic: dark glass panels
-- with thin neon edges, a wide tech font for titles, HUD-style corner
-- brackets and accent lines, cyan -> violet on the main actions, and simple
-- line icons drawn with frames (no image assets needed).
local TweenService = game:GetService("TweenService")

local Ui = {}

-- Theme --------------------------------------------------------------------------

Ui.FONT = Enum.Font.GothamBold -- buttons, numbers, names
Ui.FONT_TITLE = Enum.Font.Michroma -- wide tech font for titles and labels
Ui.FONT_MEDIUM = Enum.Font.GothamMedium -- small print

Ui.GLASS = Color3.fromRGB(11, 14, 28) -- panel fill
Ui.GLASS_LIGHT = Color3.fromRGB(22, 27, 50) -- cards on panels
Ui.LINE = Color3.fromRGB(70, 88, 150) -- thin edges and dividers
Ui.INK = Color3.fromRGB(4, 6, 16) -- text on bright fills, soft outlines
Ui.TEXT = Color3.fromRGB(236, 242, 255)
Ui.MUTED = Color3.fromRGB(128, 140, 182)
Ui.CYAN = Color3.fromRGB(0, 229, 255)
Ui.VIOLET = Color3.fromRGB(150, 95, 255)
Ui.MAGENTA = Color3.fromRGB(255, 60, 200)
-- the game's main colour: cyan -> violet on the main action
Ui.PRIMARY_A = Ui.CYAN
Ui.PRIMARY_B = Ui.VIOLET
Ui.ACCENT = Ui.CYAN
Ui.SUCCESS = Color3.fromRGB(40, 240, 170)
Ui.DANGER = Color3.fromRGB(255, 70, 110)
Ui.GOLD = Color3.fromRGB(255, 205, 70)
Ui.PANEL_TRANSPARENCY = 0.2

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

-- A dark glass panel with a thin edge
function Ui.glass(props, children)
	local radius = math.min(props.Radius or 10, 10)
	props.Radius = nil
	props.BackgroundColor3 = props.BackgroundColor3 or Ui.GLASS
	props.BackgroundTransparency = props.BackgroundTransparency or Ui.PANEL_TRANSPARENCY
	local frame = Ui.new("Frame", props, children)
	Ui.corner(radius).Parent = frame
	local edge = Ui.stroke(Ui.LINE, 1.2, 0.35)
	edge.Name = "Edge"
	edge.Parent = frame
	return frame
end

-- A thin neon line along the top of a frame, fading out at both ends
function Ui.accentLine(parent, color, z)
	return Ui.new("Frame", {
		Name = "Accent",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 0),
		Size = UDim2.new(1, -16, 0, 2),
		BackgroundColor3 = color or Ui.CYAN,
		ZIndex = z or ((parent.ZIndex or 1) + 1),
		Parent = parent,
	}, { Ui.new("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.2, 0), NumberSequenceKeypoint.new(0.8, 0), NumberSequenceKeypoint.new(1, 1) }) }) })
end

-- HUD-style corner brackets (little L shapes) just inside a frame's corners
function Ui.brackets(parent, color, length, z)
	length = length or 12
	z = z or ((parent.ZIndex or 1) + 1)
	for _, corner in ipairs({ { 0, 0 }, { 1, 0 }, { 0, 1 }, { 1, 1 } }) do
		local anchor = Vector2.new(corner[1], corner[2])
		local at = UDim2.new(corner[1], if corner[1] == 0 then -3 else 3, corner[2], if corner[2] == 0 then -3 else 3)
		Ui.new("Frame", { AnchorPoint = anchor, Position = at, Size = UDim2.fromOffset(length, 2), BackgroundColor3 = color or Ui.CYAN, ZIndex = z, Parent = parent })
		Ui.new("Frame", { AnchorPoint = anchor, Position = at, Size = UDim2.fromOffset(2, length), BackgroundColor3 = color or Ui.CYAN, ZIndex = z, Parent = parent })
	end
end

-- A card on a panel: darker glass, a thin edge in `accent`, an accent line
-- on top. props: usual Frame props (+ Radius).
function Ui.card(props, accent, children)
	local radius = math.min(props.Radius or 8, 10)
	props.Radius = nil
	props.BackgroundColor3 = props.BackgroundColor3 or Ui.GLASS_LIGHT
	props.BackgroundTransparency = props.BackgroundTransparency or 0.1
	local frame = Ui.new("Frame", props, children)
	Ui.corner(radius).Parent = frame
	local edge = Ui.stroke(accent or Ui.LINE, 1.2, 0.45)
	edge.Name = "Edge"
	edge.Parent = frame
	Ui.accentLine(frame, accent or Ui.CYAN)
	return frame
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
local STYLES = {
	primary = { A = Ui.CYAN, B = Ui.VIOLET, Edge = Color3.new(1, 1, 1), EdgeT = 0.55, Text = Ui.INK, Icon = Ui.INK },
	glass = { Fill = Ui.GLASS, FillT = 0.12, Edge = Ui.LINE, EdgeT = 0.25 },
	success = { A = Color3.fromRGB(40, 240, 170), B = Color3.fromRGB(0, 180, 220), Edge = Color3.new(1, 1, 1), EdgeT = 0.55, Text = Ui.INK, Icon = Ui.INK },
	danger = { A = Color3.fromRGB(255, 80, 120), B = Color3.fromRGB(200, 40, 170), Edge = Color3.new(1, 1, 1), EdgeT = 0.55 },
	disabled = { Fill = Color3.fromRGB(18, 21, 38), FillT = 0.2, Edge = Color3.fromRGB(50, 56, 88), EdgeT = 0.3 },
	blue = { Fill = Color3.fromRGB(90, 200, 255):Lerp(Ui.GLASS, 0.8), FillT = 0.05, Edge = Color3.fromRGB(90, 200, 255), EdgeT = 0.15, Icon = Color3.fromRGB(90, 200, 255) },
	green = { Fill = Color3.fromRGB(60, 240, 160):Lerp(Ui.GLASS, 0.8), FillT = 0.05, Edge = Color3.fromRGB(60, 240, 160), EdgeT = 0.15, Icon = Color3.fromRGB(60, 240, 160) },
	purple = { Fill = Color3.fromRGB(170, 110, 255):Lerp(Ui.GLASS, 0.8), FillT = 0.05, Edge = Color3.fromRGB(170, 110, 255), EdgeT = 0.15, Icon = Color3.fromRGB(170, 110, 255) },
	gold = { Fill = Color3.fromRGB(255, 205, 70):Lerp(Ui.GLASS, 0.8), FillT = 0.05, Edge = Color3.fromRGB(255, 205, 70), EdgeT = 0.15, Icon = Color3.fromRGB(255, 205, 70) },
	orange = { Fill = Color3.fromRGB(255, 150, 60):Lerp(Ui.GLASS, 0.8), FillT = 0.05, Edge = Color3.fromRGB(255, 150, 60), EdgeT = 0.15, Icon = Color3.fromRGB(255, 150, 60) },
	gray = { Fill = Color3.fromRGB(160, 170, 210):Lerp(Ui.GLASS, 0.8), FillT = 0.05, Edge = Color3.fromRGB(160, 170, 210), EdgeT = 0.15, Icon = Color3.fromRGB(160, 170, 210) },
	magenta = { Fill = Color3.fromRGB(255, 60, 200):Lerp(Ui.GLASS, 0.8), FillT = 0.05, Edge = Color3.fromRGB(255, 60, 200), EdgeT = 0.15, Icon = Color3.fromRGB(255, 60, 200) },
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
	else
		button.BackgroundColor3 = style.Fill
		button.BackgroundTransparency = style.FillT
		fill.Enabled = false
	end
	button.Edge.Transparency = style.EdgeT
	button.Edge.Color = style.Edge or Ui.LINE
	button.Content.Label.TextStrokeTransparency = 1
	local color = if styleName == "disabled" then Ui.MUTED else (style.Text or Ui.TEXT)
	local iconColor = if styleName == "disabled" then Ui.MUTED else (style.Icon or color)
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
	local radius = math.min(props.Radius or 8, 10) -- crisp, not bubbly
	props.Text, props.Icon, props.TextSize, props.IconSize, props.Radius = "", nil, nil, nil, nil

	local button = Ui.new("TextButton", props, { Ui.corner(radius) })
	button.AutoButtonColor = false
	button:SetAttribute("IconSize", iconSize)
	Ui.new("UIGradient", { Name = "Fill", Parent = button })
	local edge = Ui.stroke(Ui.LINE, 1.5, 0.2)
	edge.Name = "Edge"
	edge.Parent = button
	-- a hairline of light along the top edge
	Ui.new("Frame", {
		Name = "Shine",
		Position = UDim2.new(0, 8, 0, 1),
		Size = UDim2.new(1, -16, 0, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.75,
		ZIndex = 0,
		Parent = button,
	})

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
		TweenService:Create(scaler, TweenInfo.new(0.15), { Scale = 1.04 }):Play()
		TweenService:Create(edge, TweenInfo.new(0.15), { Transparency = 0.25 }):Play()
	end)
	button.MouseLeave:Connect(settle)
	button.MouseButton1Down:Connect(function()
		TweenService:Create(scaler, TweenInfo.new(0.06), { Scale = 0.94 }):Play()
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
		Font = Ui.FONT_TITLE,
		TextSize = 9,
		Text = string.upper(props.Label or ""),
		TextColor3 = Ui.TEXT,
		TextStrokeTransparency = 0.4,
		TextStrokeColor3 = Ui.INK,
		Parent = holder,
	})
	return holder, button
end

-- Shows a panel (or a modal's dark background) and eases its box in
function Ui.popIn(frame)
	local target = frame:FindFirstChild("Box") or frame
	local scaler = target:FindFirstChildOfClass("UIScale") or Ui.new("UIScale", { Parent = target })
	scaler.Scale = 0.88
	frame.Visible = true
	TweenService:Create(scaler, TweenInfo.new(0.22, Enum.EasingStyle.Quint), { Scale = 1 }):Play()
end

return Ui
