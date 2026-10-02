-- Teleport: a panel listing every world as a big coloured button. Worlds
-- you've unlocked take you straight to their start (the server checks and
-- moves you); the one you're in says "You're here"; locked ones show a
-- lock and their price. Opened by the Teleport button on the left.
local Players = game:GetService("Players")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local Effects = require(script.Parent.Effects)
local Screen = require(script.Parent.Screen)
local State = require(script.Parent.State)
local Ui = require(script.Parent.Ui)

local Travel = {}

local teleportFunction = State.remote("Teleport")

local ROW_H = 74
local modal, box = Screen.modal(460, 24 + #Config.AREAS * (ROW_H + 10) + 20, "Default")
Screen.title(box, "Teleport")
Travel.Modal = modal
Travel.Rows = {}

local function currentArea()
	local character = Players.LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root then Config.areaAt(root.Position.X) else 1
end

for i, area in ipairs(Config.AREAS) do
	local row = Ui.button({
		Name = "World" .. i,
		Position = UDim2.fromOffset(0, 8 + (i - 1) * (ROW_H + 10)),
		Size = UDim2.new(1, 0, 0, ROW_H),
		Radius = 18,
		Text = "",
		ZIndex = 33,
		Parent = box,
	}, function()
		Travel.go(i)
	end, "glass")
	local swatch = Ui.new("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 12, 0.5, 0),
		Size = UDim2.fromOffset(50, 50),
		BackgroundColor3 = area.Color,
		ZIndex = 34,
		Parent = row,
	}, { Ui.corner(14), Ui.stroke(Color3.new(1, 1, 1), 3, 0) })
	Ui.new("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Font = Enum.Font.FredokaOne,
		TextSize = 24,
		TextColor3 = Color3.new(1, 1, 1),
		Text = tostring(i),
		ZIndex = 35,
		Parent = swatch,
	})
	local name = Ui.chunky({
		Name = "WorldName",
		Position = UDim2.fromOffset(76, 10),
		Size = UDim2.new(1, -90, 0, 30),
		TextSize = 24,
		Text = area.Name,
		TextXAlignment = Enum.TextXAlignment.Left,
		Outline = 2,
		ZIndex = 35,
		Parent = row,
	})
	local status = Ui.new("TextLabel", {
		Name = "Status",
		Position = UDim2.fromOffset(76, 42),
		Size = UDim2.new(1, -90, 0, 20),
		BackgroundTransparency = 1,
		Font = Ui.FONT,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Ui.MUTED,
		Text = "",
		ZIndex = 35,
		Parent = row,
	})
	Travel.Rows[i] = { Button = row, Name = name, Status = status }
end

function Travel.refresh()
	local unlocked = (State.Data and State.Data.Unlocked) or 1
	local here = currentArea()
	for i, r in ipairs(Travel.Rows) do
		if i == here then
			r.Status.Text = "You're here"
			Ui.setStyle(r.Button, "glass")
		elseif i <= unlocked then
			r.Status.Text = "Tap to teleport"
			Ui.setStyle(r.Button, "glass")
		else
			r.Status.Text = "🔒 Locked · " .. Config.areaCostText(i)
			Ui.setStyle(r.Button, "disabled")
		end
	end
end

-- Teleports to world `i` (if it's open), closing the panel
function Travel.go(i)
	local unlocked = (State.Data and State.Data.Unlocked) or 1
	if i > unlocked then
		Effects.play("Click", 0.7)
		Screen.toast("Unlock " .. Config.AREAS[i].Name .. " first!", "danger")
		return false
	end
	Effects.play("Click", 1.1, 0.05)
	local ok, moved = pcall(teleportFunction.InvokeServer, teleportFunction, i)
	if ok and moved then
		Screen.close(modal)
		Effects.flash(Color3.new(1, 1, 1), 0.35)
		return true
	end
	return false
end

function Travel.open()
	Travel.refresh()
	Screen.open(modal)
end

State.watch(Travel.refresh)

return Travel
