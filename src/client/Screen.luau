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

-- A centred glass panel over a soft dark background, with a close button.
-- Returns the background (show with Screen.open) and the panel box.
function Screen.modal(width, height)
	local shade = Ui.new("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(5, 6, 15),
		BackgroundTransparency = 0.5,
		Text = "",
		AutoButtonColor = false,
		Visible = false,
		ZIndex = 30,
		Parent = gui,
	})
	local box = Ui.glass({
		Name = "Box",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(width, height),
		BackgroundTransparency = 0.12, -- panels with lots of text stay readable
		Radius = 24,
		ZIndex = 31,
		Parent = shade,
	}, { Ui.padding(22) })
	Ui.button({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 0),
		Size = UDim2.fromOffset(40, 40),
		Radius = 20,
		Icon = "close",
		IconSize = 14,
		ZIndex = 33,
		Parent = box,
	}, function()
		Screen.close(shade)
	end, "glass")
	return shade, box
end

function Screen.open(shade)
	if openModal and openModal ~= shade then
		openModal.Visible = false
	end
	openModal = shade
	Ui.popIn(shade)
end

function Screen.close(shade)
	shade.Visible = false
	if openModal == shade then
		openModal = nil
	end
end

function Screen.title(box, text)
	return Ui.new("TextLabel", {
		Size = UDim2.new(1, -60, 0, 30),
		TextScaled = false,
		TextSize = 26,
		Text = text,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 32,
		Parent = box,
	})
end

function Screen.subtitle(box, text)
	return Ui.new("TextLabel", {
		Position = UDim2.fromOffset(0, 36),
		Size = UDim2.new(1, -60, 0, 18),
		Font = Ui.FONT_MEDIUM,
		TextScaled = false,
		TextSize = 15,
		Text = text,
		TextColor3 = Ui.MUTED,
		TextXAlignment = Enum.TextXAlignment.Left,
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
