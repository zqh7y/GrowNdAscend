-- The always-on screen: coins at the top, the team (equipped pets and their
-- damage) at the top left, and a compact dock of icon buttons at the bottom.
-- The middle stays clear so the pets' fights are easy to watch.
local TweenService = game:GetService("TweenService")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local Ui = require(script.Parent.Ui)
local Screen = require(script.Parent.Screen)
local State = require(script.Parent.State)
local Effects = require(script.Parent.Effects)
local Roll = require(script.Parent.Roll)
local PetsPanel = require(script.Parent.PetsPanel)
local UpgradeTree = require(script.Parent.UpgradeTree)
local Panels = require(script.Parent.Panels)

local gui = Screen.Gui

-- Coins (top middle) -----------------------------------------------------------------------

local coinPill = Ui.glass({
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 14),
	Size = UDim2.fromOffset(0, 50),
	AutomaticSize = Enum.AutomaticSize.X,
	Radius = 25,
	Parent = gui,
}, {
	Ui.new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}),
	Ui.new("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 22) }),
})
local coinIcon = Ui.icon("coin", 32, Ui.GOLD, { LayoutOrder = 0, Parent = coinPill })
local coinsText = Ui.new("TextLabel", {
	LayoutOrder = 1,
	AutomaticSize = Enum.AutomaticSize.X,
	Size = UDim2.fromOffset(0, 32),
	TextScaled = false,
	TextSize = 28,
	Text = "0",
	TextColor3 = Ui.GOLD,
	Parent = coinPill,
})
local coinScale = Ui.new("UIScale", { Parent = coinPill })
local rollsText = Ui.new("TextLabel", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 68),
	Size = UDim2.fromOffset(400, 16),
	Font = Ui.FONT_MEDIUM,
	TextScaled = false,
	TextSize = 13,
	TextColor3 = Ui.TEXT,
	TextStrokeTransparency = 0.5,
	TextStrokeColor3 = Color3.fromRGB(10, 12, 30),
	Parent = gui,
})

Effects.CoinTarget = coinIcon
Effects.CoinLanded.Event:Connect(function()
	coinScale.Scale = 1.08
	TweenService:Create(coinScale, TweenInfo.new(0.2, Enum.EasingStyle.Back), { Scale = 1 }):Play()
end)

-- Team (top left) ---------------------------------------------------------------------------

local team = Ui.glass({
	Position = UDim2.fromOffset(14, 14),
	Size = UDim2.fromOffset(0, 72),
	AutomaticSize = Enum.AutomaticSize.X,
	Radius = 20,
	Parent = gui,
}, { Ui.new("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) }) })
local teamRow = Ui.new("Frame", {
	Position = UDim2.fromOffset(0, 8),
	Size = UDim2.fromOffset(0, 34),
	AutomaticSize = Enum.AutomaticSize.X,
	BackgroundTransparency = 1,
	Parent = team,
}, {
	Ui.new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Center,
	}),
})
local teamLine = Ui.new("Frame", {
	Position = UDim2.fromOffset(0, 46),
	Size = UDim2.fromOffset(0, 18),
	AutomaticSize = Enum.AutomaticSize.X,
	BackgroundTransparency = 1,
	Parent = team,
}, {
	Ui.new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 5),
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Center,
	}),
})
Ui.icon("sword", 14, Ui.DANGER, { LayoutOrder = 0, Parent = teamLine })
local teamText = Ui.new("TextLabel", {
	LayoutOrder = 1,
	AutomaticSize = Enum.AutomaticSize.X,
	Size = UDim2.fromOffset(0, 16),
	Font = Ui.FONT_MEDIUM,
	TextScaled = false,
	TextSize = 13,
	Parent = teamLine,
})

local function refreshTeam(data)
	for _, child in ipairs(teamRow:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	for slot = 1, Config.maxEquipped(data) do
		local name = data.Equipped[slot]
		local pet, size = Config.petInfo(name)
		local chip = Ui.new("Frame", {
			LayoutOrder = slot,
			Size = UDim2.fromOffset(34, 34),
			BackgroundColor3 = if pet then pet.Color else Ui.GLASS_LIGHT,
			BackgroundTransparency = if pet then 0 else 0.4,
			Parent = teamRow,
		}, { Ui.corner(0.5) })
		Ui.stroke(if size and size.Index > 1 then size.Color else Color3.new(1, 1, 1), if size then 1 + size.Index else 1.5, if pet then 0 else 0.7).Parent = chip
		if not pet then
			-- an empty slot: a faint plus
			Ui.new("TextLabel", { Size = UDim2.fromScale(1, 1), TextScaled = false, TextSize = 18, Text = "+", TextColor3 = Ui.MUTED, Parent = chip })
		elseif size.Index > 1 then
			Ui.new("TextLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 1),
				Size = UDim2.fromOffset(20, 12),
				BackgroundTransparency = 0,
				BackgroundColor3 = size.Color,
				TextScaled = false,
				TextSize = 9,
				Text = size.Name:sub(1, 1),
				TextColor3 = Color3.fromRGB(30, 30, 50),
				Parent = chip,
			}, { Ui.corner(6) })
		end
	end
	teamText.Text = Config.formatNumber(Config.teamDamage(data)) .. " damage / sec"
end

-- Dock (bottom middle) ------------------------------------------------------------------------

local dock = Ui.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -10),
	Size = UDim2.fromOffset(0, 96),
	AutomaticSize = Enum.AutomaticSize.X,
	BackgroundTransparency = 1,
	Parent = gui,
}, {
	Ui.new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		Padding = UDim.new(0, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}),
})

local function dockButton(order, icon, label, onClick, size, style)
	local holder, button = Ui.dockButton({
		LayoutOrder = order,
		Icon = icon,
		Label = label,
		Size = size,
		Style = style,
		Parent = dock,
	}, function()
		Effects.play("Click", 1, 0.05)
		onClick()
	end)
	return holder, button
end

dockButton(1, "paw", "Pets", PetsPanel.open)
local _, upgradesButton = dockButton(2, "tree", "Upgrades", UpgradeTree.open)
local _, rollButton = dockButton(3, "dice", "Roll", function()
	task.spawn(Roll.roll)
end, 78, "primary")
local _, autoButton = dockButton(4, "loop", "Auto", Roll.toggleAuto)
local topHolder = dockButton(5, "podium", "Top", Panels.openTop)
dockButton(6, "star", "Rebirth", Panels.openRebirth)
dockButton(7, "gear", "Settings", Panels.openSettings)
Roll.bindButtons(rollButton, autoButton)

-- a gold dot on Upgrades when something can be bought
local upgradeDot = Ui.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(1, -4, 0, 4),
	Size = UDim2.fromOffset(14, 14),
	BackgroundColor3 = Ui.GOLD,
	Visible = false,
	ZIndex = 5,
	Parent = upgradesButton,
}, { Ui.corner(0.5), Ui.stroke(Color3.new(1, 1, 1), 2) })

Panels.RankChanged.Event:Connect(function()
	topHolder.Caption.Text = if Panels.Rank then "#" .. Panels.Rank else "Top"
end)

-- Updates -------------------------------------------------------------------------------------

State.watch(function()
	local data = State.Data
	coinsText.Text = Config.formatNumber(data.Coins)
	local best = data.Best and Config.PETS_BY_NAME[data.Best]
	rollsText.Text = Config.formatNumber(data.Rolls) .. " rolls" .. (if best then "  ·  best: " .. best.Name .. " (" .. Config.formatOdds(best.Odds) .. ")" else "")
	refreshTeam(data)
	upgradeDot.Visible = UpgradeTree.anyAffordable()
end)

return {}
