-- UI theme and helpers: soft, futuristic glass panels, gradient buttons and
-- simple line icons drawn with frames (no image assets needed).
local TweenService = game:GetService("TweenService")

local Ui = {}

-- Theme --------------------------------------------------------------------------

Ui.FONT = Enum.Font.GothamBold
Ui.FONT_MEDIUM = Enum.Font.GothamMedium

Ui.GLASS = Color3.fromRGB(22, 25, 48)
Ui.GLASS_LIGHT = Color3.fromRGB(36, 40, 72)
Ui.TEXT = Color3.fromRGB(240, 242, 255)
Ui.MUTED = Color3.fromRGB(150, 156, 195)
-- the game's main colour: a warm orange -> hot pink gradient on the main action
Ui.PRIMARY_A = Color3.fromRGB(255, 145, 60)
Ui.PRIMARY_B = Color3.fromRGB(255, 60, 140)
Ui.ACCENT = Color3.fromRGB(80, 220, 255)
Ui.SUCCESS = Color3.fromRGB(70, 225, 160)
Ui.DANGER = Color3.fromRGB(255, 85, 110)
Ui.GOLD = Color3.fromRGB(255, 205, 80)

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

-- A frosted dark panel with a faint glowing edge
function Ui.glass(props, children)
	local radius = props.Radius or 18
	props.Radius = nil
	props.BackgroundColor3 = props.BackgroundColor3 or Ui.GLASS
	props.BackgroundTransparency = props.BackgroundTransparency or 0.18
	local frame = Ui.new("Frame", props, children)
	Ui.corner(radius).Parent = frame
	local edge = Ui.stroke(Color3.new(1, 1, 1), 1.5, 0.82)
	edge.Name = "Edge"
	edge.Parent = frame
	-- soft sheen: slightly more see-through at the bottom
	Ui.new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(0, 0.15), Parent = frame })
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

local STYLES = {
	primary = { A = Ui.PRIMARY_A, B = Ui.PRIMARY_B, EdgeT = 0.55 },
	glass = { Fill = Ui.GLASS, FillT = 0.18, EdgeT = 0.8 },
	success = { A = Color3.fromRGB(60, 220, 150), B = Color3.fromRGB(40, 190, 215), EdgeT = 0.6 },
	danger = { A = Color3.fromRGB(255, 95, 110), B = Color3.fromRGB(230, 60, 140), EdgeT = 0.6 },
	disabled = { Fill = Ui.GLASS_LIGHT, FillT = 0.35, EdgeT = 0.9 },
}

-- Restyles a button: "primary", "glass", "success", "danger" or "disabled"
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
	local color = if styleName == "disabled" then Ui.MUTED else Ui.TEXT
	local content = button.Content
	content.Label.TextColor3 = color
	for _, d in ipairs(content:GetDescendants()) do
		if d:IsA("Frame") and d.BackgroundTransparency < 1 then
			d.BackgroundColor3 = color
		elseif d:IsA("UIStroke") then
			d.Color = color
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
	local radius = props.Radius or 14
	props.Text, props.Icon, props.TextSize, props.IconSize, props.Radius = "", nil, nil, nil, nil

	local button = Ui.new("TextButton", props, { Ui.corner(radius) })
	button.AutoButtonColor = false
	button:SetAttribute("IconSize", iconSize)
	Ui.new("UIGradient", { Name = "Fill", Parent = button })
	local edge = Ui.stroke(Color3.new(1, 1, 1), 1.5, 0.8)
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

-- Shows a panel (or a modal's dark background) and eases its box in
function Ui.popIn(frame)
	local target = frame:FindFirstChild("Box") or frame
	local scaler = target:FindFirstChildOfClass("UIScale") or Ui.new("UIScale", { Parent = target })
	scaler.Scale = 0.88
	frame.Visible = true
	TweenService:Create(scaler, TweenInfo.new(0.22, Enum.EasingStyle.Quint), { Scale = 1 }):Play()
end

return Ui
