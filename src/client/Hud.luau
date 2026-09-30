-- The always-on screen, laid out around the fights in the middle:
--   top centre   coins, and under them YOUR TEAM (equipped pets + damage)
--   left side    navigation: Pets, Upgrades, Rebirth, Top, Settings
--   right side   gameplay: the big Roll button and Auto
-- The top-left corner is left alone: Roblox puts its menu and chat buttons
-- there (the HUD ignores the top bar inset, so anything there would overlap).
local TweenService = game:GetService("TweenService")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local Ui = require(script.Parent.Ui)
local Screen = require(script.Parent.Screen)
local State = require(script.Parent.State)
local Effects = require(script.Parent.Effects)
local Roll = require(script.Parent.Roll)
local Index = require(script.Parent.Index)
local Inventory = require(script.Parent.Inventory)
local UpgradeTree = require(script.Parent.UpgradeTree)
local Panels = require(script.Parent.Panels)

local gui = Screen.Gui

-- Coins (top centre) --------------------------------------------------------------------------

local coinPill = Ui.glass({
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 12),
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

Effects.CoinTarget = coinIcon
Effects.CoinLanded.Event:Connect(function()
	coinScale.Scale = 1.08
	TweenService:Create(coinScale, TweenInfo.new(0.2, Enum.EasingStyle.Back), { Scale = 1 }):Play()
end)

-- Your team (under the coins) -----------------------------------------------------------------

local team = Ui.glass({
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 70),
	Size = UDim2.fromOffset(0, 40),
	AutomaticSize = Enum.AutomaticSize.X,
	Radius = 20,
	Parent = gui,
}, {
	Ui.new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}),
	Ui.new("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 14) }),
})
Ui.new("TextLabel", {
	LayoutOrder = 0,
	AutomaticSize = Enum.AutomaticSize.X,
	Size = UDim2.fromOffset(0, 16),
	TextScaled = false,
	TextSize = 12,
	Text = "YOUR TEAM",
	TextColor3 = Ui.MUTED,
	Parent = team,
})
local chips = Ui.new("Frame", {
	LayoutOrder = 1,
	AutomaticSize = Enum.AutomaticSize.X,
	Size = UDim2.fromOffset(0, 28),
	BackgroundTransparency = 1,
	Parent = team,
}, {
	Ui.new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 5),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}),
})
Ui.icon("sword", 14, Ui.DANGER, { LayoutOrder = 2, Parent = team })
local teamText = Ui.new("TextLabel", {
	LayoutOrder = 3,
	AutomaticSize = Enum.AutomaticSize.X,
	Size = UDim2.fromOffset(0, 16),
	Font = Ui.FONT_MEDIUM,
	TextScaled = false,
	TextSize = 13,
	Parent = team,
})

local function refreshTeam(data)
	for _, child in ipairs(chips:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	for slot = 1, Config.maxEquipped(data) do
		local name = data.Equipped[slot]
		local pet, size = Config.petInfo(name)
		local chip = Ui.new("Frame", {
			LayoutOrder = slot,
			Size = UDim2.fromOffset(26, 26),
			BackgroundColor3 = if pet then pet.Color else Ui.GLASS_LIGHT,
			BackgroundTransparency = if pet then 0 else 0.4,
			Parent = chips,
		}, { Ui.corner(0.5) })
		Ui.stroke(if size and size.Index > 1 then size.Color else Color3.new(1, 1, 1), if size then 1 + size.Index else 1.5, if pet then 0 else 0.7).Parent = chip
		if size and size.Index > 1 then
			Ui.new("TextLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 1),
				Size = UDim2.fromOffset(18, 11),
				BackgroundTransparency = 0,
				BackgroundColor3 = size.Color,
				TextScaled = false,
				TextSize = 9,
				Text = size.Name:sub(1, 1),
				TextColor3 = Color3.fromRGB(30, 30, 50),
				Parent = chip,
			}, { Ui.corner(5) })
		end
	end
	teamText.Text = Config.formatNumber(Config.teamDamage(data)) .. " damage/sec"
end

-- Navigation (left side) ------------------------------------------------------------------------

local nav = Ui.new("Frame", {
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 16, 0.5, 20),
	Size = UDim2.fromOffset(64, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundTransparency = 1,
	Parent = gui,
}, {
	Ui.new("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Padding = UDim.new(0, 12),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}),
})

local function button(parent, order, icon, label, onClick, size, style)
	local holder, b = Ui.dockButton({
		LayoutOrder = order,
		Icon = icon,
		Label = label,
		Size = size,
		Style = style,
		Parent = parent,
	}, function()
		Effects.play("Click", 1, 0.05)
		onClick()
	end)
	return holder, b
end

button(nav, 1, "paw", "Inventory", Inventory.open)
button(nav, 2, "book", "Index", Index.open)
local _, upgradesButton = button(nav, 3, "tree", "Upgrades", UpgradeTree.open)
button(nav, 4, "star", "Rebirth", Panels.openRebirth)
local topHolder = button(nav, 5, "podium", "Top", Panels.openTop)
button(nav, 6, "gear", "Settings", Panels.openSettings)

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

-- Gameplay controls (right side) -----------------------------------------------------------------

local controls = Ui.new("Frame", {
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -18, 1, -16),
	Size = UDim2.fromOffset(96, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundTransparency = 1,
	Parent = gui,
}, {
	Ui.new("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		Padding = UDim.new(0, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}),
})
local _, autoButton = button(controls, 1, "loop", "Auto", Roll.toggleAuto, 56)
local _, rollButton = button(controls, 2, "dice", "Roll", function()
	task.spawn(Roll.roll)
end, 88, "primary")
Roll.bindButtons(rollButton, autoButton)

-- Updates ------------------------------------------------------------------------------------------

State.watch(function()
	local data = State.Data
	coinsText.Text = Config.formatNumber(data.Coins)
	refreshTeam(data)
	upgradeDot.Visible = UpgradeTree.anyAffordable()
end)

return {}
