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
	Default = { Color = Color3.fromRGB(0, 229, 255), Icon = "star", Tag = "SYSTEM" },
	Inventory = { Color = Color3.fromRGB(0, 229, 255), Icon = "paw", Tag = "COLLECTION" },
	Index = { Color = Color3.fromRGB(150, 110, 255), Icon = "book", Tag = "DATABASE" },
	Upgrades = { Color = Color3.fromRGB(40, 240, 170), Icon = "tree", Tag = "SYSTEMS" },
	Rebirth = { Color = Color3.fromRGB(255, 60, 200), Icon = "star", Tag = "PRESTIGE" },
	Fusion = { Color = Color3.fromRGB(255, 120, 200), Icon = "grow", Tag = "LAB" },
	Settings = { Color = Color3.fromRGB(160, 170, 210), Icon = "gear", Tag = "CONFIG" },
	Top = { Color = Color3.fromRGB(255, 205, 70), Icon = "podium", Tag = "RANKS" },
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

-- A centred panel: dark glass with a thin edge in the theme's colour, a
-- neon line along the top, a faint tech grid, HUD corner brackets, a soft
-- shadow, and a square close button. `theme` is a name from Screen.THEMES
-- (or a { Color, Icon, Tag } table). Returns the background (show with
-- Screen.open) and the panel box (put content in it).
function Screen.modal(width, height, theme)
	theme = Screen.THEMES[theme] or theme or Screen.THEMES.Default
	local shade = Ui.new("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(2, 4, 12),
		BackgroundTransparency = 0.4,
		Text = "",
		AutoButtonColor = false,
		Visible = false,
		ZIndex = 30,
		Parent = gui,
	})
	-- holder (scaled when it pops in) = glow + panel
	local holder = Ui.new("Frame", {
		Name = "Box",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 12),
		Size = UDim2.fromOffset(width, height),
		BackgroundTransparency = 1,
		ZIndex = 30,
		Parent = shade,
	})
	-- a soft glow in the theme colour behind the panel
	Ui.new("Frame", {
		Name = "Shadow",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, 24, 1, 24),
		BackgroundColor3 = theme.Color,
		BackgroundTransparency = 0.9,
		ZIndex = 30,
		Parent = holder,
	}, { Ui.corner(16) })
	local box = Ui.new("Frame", {
		Name = "Panel",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.04,
		ClipsDescendants = false,
		ZIndex = 31,
		Parent = holder,
	}, {
		Ui.corner(10),
		Ui.padding(22),
		Ui.new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(16, 20, 40), Color3.fromRGB(7, 9, 20)) }),
	})
	Ui.stroke(theme.Color, 1.2, 0.45).Parent = box
	-- the faint grid
	local grid = Ui.new("Frame", {
		Name = "Grid",
		Position = UDim2.fromOffset(-22, -22),
		Size = UDim2.new(1, 44, 1, 44),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		ZIndex = 31,
		Parent = box,
	})
	for k = 1, math.floor(width / 48) do
		Ui.new("Frame", { Position = UDim2.fromOffset(k * 48, 0), Size = UDim2.new(0, 1, 1, 0), BackgroundColor3 = theme.Color, BackgroundTransparency = 0.95, ZIndex = 31, Parent = grid })
	end
	for k = 1, math.floor(height / 48) do
		Ui.new("Frame", { Position = UDim2.fromOffset(0, k * 48), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = theme.Color, BackgroundTransparency = 0.95, ZIndex = 31, Parent = grid })
	end
	-- neon line on top, brackets in the corners
	local line = Ui.accentLine(grid, theme.Color, 33)
	line.Size = UDim2.new(1, -40, 0, 2)
	Ui.brackets(grid, theme.Color, 16, 33)
	themes[box] = theme
	Ui.button({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 8, 0, -10),
		Size = UDim2.fromOffset(34, 34),
		Radius = 6,
		Icon = "close",
		IconSize = 12,
		ZIndex = 36,
		Parent = box,
	}, function()
		Screen.close(shade)
	end, "glass")
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

-- The panel's title, top left: a small "// TAG" in the theme's colour over
-- the title in the wide tech font, with a short neon underline. Returns the
-- title's text label.
function Screen.title(box, text)
	local theme = themes[box] or Screen.THEMES.Default
	local holder = Ui.new("Frame", {
		Name = "Title",
		Position = UDim2.fromOffset(0, -10),
		Size = UDim2.new(1, -60, 0, 44),
		BackgroundTransparency = 1,
		ZIndex = 35,
		Parent = box,
	})
	Ui.new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 12),
		Font = Ui.FONT_TITLE,
		TextScaled = false,
		TextSize = 10,
		Text = "// " .. (theme.Tag or "SYSTEM"),
		TextColor3 = theme.Color,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 35,
		Parent = holder,
	})
	local label = Ui.new("TextLabel", {
		Position = UDim2.fromOffset(0, 14),
		Size = UDim2.new(1, 0, 0, 26),
		Font = Ui.FONT_TITLE,
		TextScaled = false,
		TextSize = 22,
		Text = text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 35,
		Parent = holder,
	})
	Ui.new("Frame", {
		Position = UDim2.fromOffset(0, 43),
		Size = UDim2.fromOffset(48, 2),
		BackgroundColor3 = theme.Color,
		ZIndex = 35,
		Parent = holder,
	})
	-- titles are written in capitals
	label:GetPropertyChangedSignal("Text"):Connect(function()
		local upper = string.upper(label.Text)
		if label.Text ~= upper then
			label.Text = upper
		end
	end)
	label.Text = string.upper(text)
	return label
end

-- A line of info under the title (right of it on wide panels)
function Screen.subtitle(box, text)
	return Ui.new("TextLabel", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -46, 0, 6),
		Size = UDim2.new(0.5, 0, 0, 18),
		Font = Ui.FONT_MEDIUM,
		TextScaled = false,
		TextSize = 14,
		Text = text,
		TextColor3 = Ui.MUTED,
		TextXAlignment = Enum.TextXAlignment.Right,
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
	Position = UDim2.new(0.5, 0, 0, 160),
	Size = UDim2.fromOffset(0, 38),
	AutomaticSize = Enum.AutomaticSize.X,
	Radius = 6,
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
