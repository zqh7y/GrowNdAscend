-- Small helpers for building UI in code.
local TweenService = game:GetService("TweenService")

local Ui = {}

Ui.FONT = Enum.Font.FredokaOne
Ui.DARK = Color3.fromRGB(28, 30, 48)
Ui.PANEL = Color3.fromRGB(40, 43, 68)
Ui.TEXT = Color3.new(1, 1, 1)
Ui.MUTED = Color3.fromRGB(170, 175, 205)
Ui.GREEN = Color3.fromRGB(70, 200, 110)
Ui.GREY = Color3.fromRGB(80, 84, 110)
Ui.GOLD = Color3.fromRGB(255, 200, 60)
Ui.PURPLE = Color3.fromRGB(150, 90, 240)

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

function Ui.stroke(color, thickness)
	return Ui.new("UIStroke", { Color = color, Thickness = thickness or 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
end

function Ui.padding(px)
	return Ui.new("UIPadding", {
		PaddingTop = UDim.new(0, px),
		PaddingBottom = UDim.new(0, px),
		PaddingLeft = UDim.new(0, px),
		PaddingRight = UDim.new(0, px),
	})
end

function Ui.gradient(a, b)
	return Ui.new("UIGradient", { Color = ColorSequence.new(a, b), Rotation = 90 })
end

-- A rounded button that squishes when pressed
function Ui.button(props, onClick)
	local button = Ui.new("TextButton", props, { Ui.corner(12) })
	button.BackgroundTransparency = props.BackgroundTransparency or 0
	button.AutoButtonColor = false
	local scaler = Ui.new("UIScale", { Parent = button })
	button.MouseButton1Down:Connect(function()
		TweenService:Create(scaler, TweenInfo.new(0.06), { Scale = 0.92 }):Play()
	end)
	local function release()
		TweenService:Create(scaler, TweenInfo.new(0.12, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	end
	button.MouseButton1Up:Connect(release)
	button.MouseLeave:Connect(release)
	button.Activated:Connect(onClick)
	return button
end

-- Shows a panel (or a modal's dark background) and pops its box in from small
function Ui.popIn(frame)
	local target = frame:FindFirstChild("Box") or frame
	local scaler = target:FindFirstChildOfClass("UIScale") or Ui.new("UIScale", { Parent = target })
	scaler.Scale = 0.6
	frame.Visible = true
	TweenService:Create(scaler, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Scale = 1 }):Play()
end

return Ui
