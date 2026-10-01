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

-- The Roll / Auto / hatch mode buttons live on their own layer above
-- everything (panels, the hatch), so they can be pressed at any time
local controlsGui = Ui.new("ScreenGui", {
	Name = "ControlsGui",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	DisplayOrder = 10,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = Players.LocalPlayer:WaitForChild("PlayerGui"),
})
Screen.Controls = controlsGui

local uiScale = Ui.new("UIScale", { Parent = gui })
local controlsScale = Ui.new("UIScale", { Parent = controlsGui })
local function fitScreen()
	local size = Workspace.CurrentCamera.ViewportSize
	uiScale.Scale = math.clamp(math.min(size.X / 1280, size.Y / 760), 0.55, 1.15)
	controlsScale.Scale = uiScale.Scale
end
fitScreen()
Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fitScreen)

-- Panels (modals) ---------------------------------------------------------------------

local openModal = nil

-- Every panel's colour and icon (its title ribbon, border glow and bubbles)
Screen.THEMES = {
	Default = { Color = Color3.fromRGB(64, 132, 255), Icon = "star" },
	Inventory = { Color = Color3.fromRGB(64, 132, 255), Icon = "paw" },
	Index = { Color = Color3.fromRGB(140, 102, 240), Icon = "book" },
	Upgrades = { Color = Color3.fromRGB(46, 196, 120), Icon = "tree" },
	Rebirth = { Color = Color3.fromRGB(255, 104, 150), Icon = "star" },
	Fusion = { Color = Color3.fromRGB(255, 150, 70), Icon = "grow" },
	Settings = { Color = Color3.fromRGB(128, 136, 160), Icon = "gear" },
	Top = { Color = Color3.fromRGB(255, 186, 40), Icon = "podium" },
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

-- A centred panel: white and rounded, with a soft shadow, over a gently
-- dimmed screen, and a round close button. `theme` is a name from
-- Screen.THEMES (or a { Color, Icon } table): its colour is only used for
-- the small icon next to the heading. Returns the background (show with
-- Screen.open) and the panel box (put content in it).
function Screen.modal(width, height, theme)
	theme = Screen.THEMES[theme] or theme or Screen.THEMES.Default
	local shade = Ui.new("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(16, 20, 36),
		BackgroundTransparency = 0.55,
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
		Position = UDim2.fromOffset(0, 8),
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(10, 14, 30),
		BackgroundTransparency = 0.78,
		ZIndex = 30,
		Parent = holder,
	}, { Ui.corner(22) })
	local box = Ui.new("Frame", {
		Name = "Panel",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Ui.GLASS,
		BackgroundTransparency = 0,
		ZIndex = 31,
		Parent = holder,
	}, { Ui.corner(22), Ui.padding(24) })
	themes[box] = theme
	Ui.button({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 6, 0, -8),
		Size = UDim2.fromOffset(36, 36),
		Radius = 18,
		Icon = "close",
		IconSize = 12,
		ZIndex = 36,
		Parent = box,
	}, function()
		Screen.close(shade)
	end, "disabled")
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
	shade:SetAttribute("Closing", false)
	Ui.popIn(shade)
	local tweens = game:GetService("TweenService")
	-- the dim fades in; the panel rises into place
	shade.BackgroundTransparency = 1
	tweens:Create(shade, TweenInfo.new(0.2), { BackgroundTransparency = 0.55 }):Play()
	local holder = holderOf(shade)
	if holder then
		holder.Position = UDim2.new(0.5, 0, 0.5, if Ui.reduced() then 12 else 36)
		tweens:Create(holder, TweenInfo.new(0.32, Enum.EasingStyle.Quint), { Position = UDim2.new(0.5, 0, 0.5, 12) }):Play()
	end
end

-- Closes a panel: it eases down and fades, then hides
function Screen.close(shade)
	if openModal == shade then
		openModal = nil
		Screen.blur(false)
	end
	if not shade.Visible or shade:GetAttribute("Closing") then
		return
	end
	local holder = holderOf(shade)
	if Ui.reduced() or not holder then
		shade.Visible = false
		return
	end
	shade:SetAttribute("Closing", true)
	local tweens = game:GetService("TweenService")
	local scaler = holder:FindFirstChildOfClass("UIScale")
	local out = TweenInfo.new(0.14, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
	tweens:Create(shade, out, { BackgroundTransparency = 1 }):Play()
	tweens:Create(holder, out, { Position = UDim2.new(0.5, 0, 0.5, 30) }):Play()
	if scaler then
		tweens:Create(scaler, out, { Scale = 0.95 }):Play()
	end
	task.delay(0.15, function()
		-- (unless it was opened again meanwhile)
		if shade:GetAttribute("Closing") then
			shade:SetAttribute("Closing", false)
			shade.Visible = false
		end
	end)
end

-- The panel's heading, top left: a small rounded icon tile in the theme's
-- colour and the title in the friendly display font. Returns the title's
-- text label.
function Screen.title(box, text)
	local theme = themes[box] or Screen.THEMES.Default
	local tile = Ui.new("Frame", {
		Name = "TitleIcon",
		Position = UDim2.fromOffset(0, -6),
		Size = UDim2.fromOffset(34, 34),
		BackgroundColor3 = theme.Color,
		ZIndex = 35,
		Parent = box,
	}, { Ui.corner(10) })
	Ui.icon(theme.Icon, 20, Ui.WHITE, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), ZIndex = 36, Parent = tile })
	return Ui.new("TextLabel", {
		Name = "Title",
		Position = UDim2.fromOffset(46, -6),
		Size = UDim2.new(0.6, -46, 0, 34),
		Font = Ui.FONT_DISPLAY,
		TextScaled = false,
		TextSize = 28,
		Text = text,
		TextColor3 = Ui.TEXT,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 35,
		Parent = box,
	})
end

-- A line of info at the top right, next to the close button
function Screen.subtitle(box, text)
	return Ui.new("TextLabel", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -48, 0, 2),
		Size = UDim2.new(0.45, 0, 0, 18),
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
	Position = UDim2.new(0.5, 0, 0, 200),
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
	toast.Edge.Transparency = 0
	toast.Edge.Thickness = 2
	Ui.popIn(toast)
	task.delay(2.4, function()
		if toastId == id then
			toast.Visible = false
		end
	end)
end

return Screen
