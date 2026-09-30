-- The ScreenGui everything lives in, scaled for the screen size, plus the
-- shared building blocks for panels (modal, title, lists) and toasts.
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Ui = require(script.Parent.Ui)

local Screen = {}

local gui = Ui.new("ScreenGui", {
	Name = "GameGui",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = Players.LocalPlayer:WaitForChild("PlayerGui"),
})
Screen.Gui = gui

local uiScale = Ui.new("UIScale", { Parent = gui })
local function fitScreen()
	local size = Workspace.CurrentCamera.ViewportSize
	uiScale.Scale = math.clamp(math.min(size.X / 1280, size.Y / 760), 0.55, 1.15)
end
fitScreen()
Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fitScreen)

-- Panels (modals) ---------------------------------------------------------------------

local openModal = nil

-- Every panel's colour and icon (its title ribbon, border glow and bubbles)
Screen.THEMES = {
	Default = { Color = Color3.fromRGB(90, 200, 255), Icon = "star" },
	Inventory = { Color = Color3.fromRGB(255, 160, 70), Icon = "paw" },
	Index = { Color = Color3.fromRGB(90, 190, 255), Icon = "book" },
	Upgrades = { Color = Color3.fromRGB(110, 220, 110), Icon = "tree" },
	Rebirth = { Color = Color3.fromRGB(215, 120, 255), Icon = "star" },
	Fusion = { Color = Color3.fromRGB(255, 120, 190), Icon = "grow" },
	Settings = { Color = Color3.fromRGB(160, 165, 220), Icon = "gear" },
	Top = { Color = Color3.fromRGB(255, 200, 70), Icon = "podium" },
}

local themes = {} -- [box] = theme

-- The world softly blurs behind open panels and the hatch
local blur = Instance.new("BlurEffect")
blur.Size = 0
blur.Parent = Workspace.CurrentCamera
local blurUsers = 0
function Screen.blur(on)
	blurUsers = math.max(blurUsers + (if on then 1 else -1), 0)
	game:GetService("TweenService"):Create(blur, TweenInfo.new(0.25), { Size = if blurUsers > 0 then 12 else 0 }):Play()
end

-- A centred cartoon panel over a soft dark background: a gradient body in
-- the theme's colour with a thick white border, a soft shadow, a few
-- bubbles, and a round close button on its corner. `theme` is a name from
-- Screen.THEMES (or a { Color, Icon } table). Returns the background (show
-- with Screen.open) and the panel box (put content in it).
function Screen.modal(width, height, theme)
	theme = Screen.THEMES[theme] or theme or Screen.THEMES.Default
	local shade = Ui.new("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(10, 6, 30),
		BackgroundTransparency = 0.45,
		Text = "",
		AutoButtonColor = false,
		Visible = false,
		ZIndex = 30,
		Parent = gui,
	})
	-- holder (scaled when it pops in) = shadow + panel
	local holder = Ui.new("Frame", {
		Name = "Box",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 12),
		Size = UDim2.fromOffset(width, height),
		BackgroundTransparency = 1,
		ZIndex = 30,
		Parent = shade,
	})
	Ui.new("Frame", {
		Name = "Shadow",
		Position = UDim2.fromOffset(0, 10),
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(8, 4, 24),
		BackgroundTransparency = 0.55,
		ZIndex = 30,
		Parent = holder,
	}, { Ui.corner(30) })
	local dark = Color3.fromRGB(34, 26, 80)
	local box = Ui.new("Frame", {
		Name = "Panel",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.06,
		ZIndex = 31,
		Parent = holder,
	}, {
		Ui.corner(30),
		Ui.padding(22),
		Ui.new("UIGradient", { Rotation = 90, Color = ColorSequence.new(theme.Color:Lerp(dark, 0.62), dark) }),
	})
	Ui.stroke(Color3.new(1, 1, 1), 4, 0.08).Parent = box
	-- a few soft bubbles in the theme colour
	for _, b in ipairs({ { 0.02, 0.9, 90 }, { 0.93, 0.8, 60 }, { 0.12, 0.72, 34 }, { 0.86, 0.12, 40 } }) do
		Ui.new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(b[1], b[2]),
			Size = UDim2.fromOffset(b[3], b[3]),
			BackgroundColor3 = theme.Color,
			BackgroundTransparency = 0.86,
			ZIndex = 31,
			Parent = box,
		}, { Ui.corner(0.5) })
	end
	themes[box] = theme
	Ui.button({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(1, 14, 0, -14),
		Size = UDim2.fromOffset(46, 46),
		Radius = 23,
		Icon = "close",
		IconSize = 16,
		ZIndex = 36,
		Parent = box,
	}, function()
		Screen.close(shade)
	end, "danger")
	return shade, box
end

local function holderOf(shade)
	return shade:FindFirstChild("Box")
end

function Screen.open(shade)
	if openModal and openModal ~= shade then
		openModal.Visible = false
	elseif openModal == shade and shade.Visible then
		return
	end
	if not openModal then
		Screen.blur(true)
	end
	openModal = shade
	Ui.popIn(shade)
	local holder = holderOf(shade)
	if holder then
		-- a little bounce in from below
		holder.Position = UDim2.new(0.5, 0, 0.5, 40)
		game:GetService("TweenService"):Create(holder, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Position = UDim2.new(0.5, 0, 0.5, 12) }):Play()
	end
end

function Screen.close(shade)
	shade.Visible = false
	if openModal == shade then
		openModal = nil
		Screen.blur(false)
	end
end

-- The panel's title: a ribbon across the top edge in the theme's colour,
-- with the theme's icon in a white badge. Returns the text label.
function Screen.title(box, text)
	local theme = themes[box] or Screen.THEMES.Default
	local ribbon = Ui.new("Frame", {
		Name = "Ribbon",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0, -22),
		Size = UDim2.fromOffset(0, 54),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = Color3.new(1, 1, 1),
		ZIndex = 35,
		Parent = box,
	}, {
		Ui.corner(27),
		Ui.new("UIGradient", { Rotation = 90, Color = ColorSequence.new(theme.Color:Lerp(Color3.new(1, 1, 1), 0.25), theme.Color:Lerp(Color3.new(0, 0, 0), 0.12)) }),
		Ui.new("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 10),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		Ui.new("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 26) }),
	})
	Ui.stroke(Color3.new(1, 1, 1), 3.5, 0).Parent = ribbon
	local badge = Ui.new("Frame", {
		LayoutOrder = 0,
		Size = UDim2.fromOffset(40, 40),
		BackgroundColor3 = Color3.new(1, 1, 1),
		ZIndex = 36,
		Parent = ribbon,
	}, { Ui.corner(0.5) })
	Ui.icon(theme.Icon, 24, theme.Color:Lerp(Color3.new(0, 0, 0), 0.15), {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		ZIndex = 37,
		Parent = badge,
	})
	return Ui.new("TextLabel", {
		LayoutOrder = 1,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 34),
		TextScaled = false,
		TextSize = 28,
		Text = text,
		TextStrokeTransparency = 0,
		TextStrokeColor3 = Ui.INK,
		ZIndex = 36,
		Parent = ribbon,
	})
end

function Screen.subtitle(box, text)
	return Ui.new("TextLabel", {
		Position = UDim2.fromOffset(0, 22),
		Size = UDim2.new(1, 0, 0, 22),
		Font = Ui.FONT,
		TextScaled = false,
		TextSize = 18,
		Text = text,
		TextColor3 = Color3.fromRGB(230, 225, 255),
		ZIndex = 32,
		Parent = box,
	})
end

function Screen.scrollList(box, top, layout)
	return Ui.new("ScrollingFrame", {
		Position = UDim2.fromOffset(0, top),
		Size = UDim2.new(1, 0, 1, -top),
		BackgroundTransparency = 1,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = Ui.MUTED,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ZIndex = 32,
		Parent = box,
	}, { layout, Ui.new("UIPadding", { PaddingRight = UDim.new(0, 10), PaddingTop = UDim.new(0, 4), PaddingLeft = UDim.new(0, 2) }) })
end

-- Toasts ------------------------------------------------------------------------------

local toast = Ui.glass({
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 96),
	Size = UDim2.fromOffset(0, 38),
	AutomaticSize = Enum.AutomaticSize.X,
	Radius = 19,
	Visible = false,
	ZIndex = 25,
	Parent = gui,
}, { Ui.new("UIPadding", { PaddingLeft = UDim.new(0, 20), PaddingRight = UDim.new(0, 20) }) })
local toastText = Ui.new("TextLabel", {
	AutomaticSize = Enum.AutomaticSize.X,
	Size = UDim2.fromOffset(0, 38),
	TextScaled = false,
	TextSize = 16,
	ZIndex = 26,
	Parent = toast,
})
local toastId = 0
local TOAST_COLORS = { danger = Ui.DANGER, success = Ui.SUCCESS }

-- A short message under the coin counter; style is "danger", "success" or nil
function Screen.toast(text, style)
	toastId += 1
	local id = toastId
	toastText.Text = text
	toast.Edge.Color = TOAST_COLORS[style] or Ui.ACCENT
	toast.Edge.Transparency = 0.1
	Ui.popIn(toast)
	task.delay(2.4, function()
		if toastId == id then
			toast.Visible = false
		end
	end)
end

return Screen
