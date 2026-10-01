-- The always-on screen, laid out around the fights in the middle:
--   top centre   coins, and under them YOUR TEAM (equipped pets + damage)
--   left side    navigation: Inventory, Index, Upgrades, Rebirth, Settings
--                (the leaderboards are in the world, in the Forest)
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

local Hud = {}

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
	Font = Ui.FONT_DISPLAY,
	TextScaled = false,
	TextSize = 28,
	Text = "0",
	TextColor3 = Ui.TEXT,
	Parent = coinPill,
})
local coinScale = Ui.new("UIScale", { Parent = coinPill })
-- your luck sits in the same pill, after a thin divider (Roll.luau keeps it current)
Ui.new("Frame", { LayoutOrder = 2, Size = UDim2.fromOffset(1, 26), BackgroundColor3 = Ui.LINE, Parent = coinPill })
Roll.LuckPill.Parent = coinPill

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

-- Level and EXP (under the team) ---------------------------------------------------------------

local levelBar = Ui.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 118),
	Size = UDim2.fromOffset(330, 34),
	BackgroundTransparency = 1,
	Parent = gui,
})
local levelBadge = Ui.new("TextLabel", {
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.fromScale(0, 0.5),
	Size = UDim2.fromOffset(104, 34),
	BackgroundTransparency = 0,
	BackgroundColor3 = Ui.VIOLET:Lerp(Ui.GLASS, 0.75),
	Font = Ui.FONT_TITLE,
	TextScaled = false,
	TextSize = 14,
	Text = "LEVEL 1",
	ZIndex = 3,
	Parent = levelBar,
}, { Ui.corner(4), Ui.stroke(Ui.VIOLET, 1.2, 0) })
local levelScale = Ui.new("UIScale", { Parent = levelBadge })
local expTrack = Ui.new("Frame", {
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 96, 0.5, 0),
	Size = UDim2.new(1, -96, 0, 22),
	BackgroundColor3 = Ui.GLASS,
	BackgroundTransparency = 0.2,
	Parent = levelBar,
}, { Ui.corner(3), Ui.stroke(Ui.LINE, 1, 0.3) })
local expFill = Ui.new("Frame", {
	Size = UDim2.fromScale(0, 1),
	BackgroundColor3 = Color3.new(1, 1, 1),
	ZIndex = 2,
	Parent = expTrack,
}, { Ui.corner(3), Ui.new("UIGradient", { Color = ColorSequence.new(Ui.CYAN, Ui.VIOLET) }) })
local expText = Ui.new("TextLabel", {
	Size = UDim2.fromScale(1, 1),
	TextScaled = false,
	TextSize = 13,
	Text = "",
	ZIndex = 3,
	Parent = expTrack,
})

local function refreshLevel(data)
	local level, exp = data.Level or 1, data.Exp or 0
	local need = Config.expToNext(level)
	levelBadge.Text = "LEVEL " .. level
	TweenService:Create(expFill, TweenInfo.new(0.25), { Size = UDim2.fromScale(math.clamp(exp / need, 0, 1), 1) }):Play()
	expText.Text = Config.formatNumber(exp) .. " / " .. Config.formatNumber(need) .. " EXP"
end

-- Level up: a big "LEVEL UP!" with the new level, sparkles and a jingle
local levelUp = Ui.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.3),
	Size = UDim2.fromOffset(420, 130),
	BackgroundTransparency = 1,
	Visible = false,
	ZIndex = 45,
	Parent = gui,
})
local levelUpScale = Ui.new("UIScale", { Parent = levelUp })
Ui.new("TextLabel", {
	Size = UDim2.new(1, 0, 0, 62),
	TextScaled = false,
	Font = Ui.FONT_TITLE,
	TextSize = 38,
	Text = "LEVEL UP",
	TextColor3 = Ui.CYAN,
	TextStrokeTransparency = 0.4,
	TextStrokeColor3 = Ui.INK,
	ZIndex = 46,
	Parent = levelUp,
})
local levelUpNumber = Ui.new("TextLabel", {
	Position = UDim2.fromOffset(0, 66),
	Size = UDim2.new(1, 0, 0, 44),
	TextScaled = false,
	Font = Ui.FONT_TITLE,
	TextSize = 22,
	Text = "",
	TextStrokeTransparency = 0.4,
	TextStrokeColor3 = Ui.INK,
	ZIndex = 46,
	Parent = levelUp,
})
local levelUpId = 0
local function celebrateLevel(level)
	levelUpId += 1
	local id = levelUpId
	levelUpNumber.Text = "Level " .. level
	levelUp.Visible = true
	levelUpScale.Scale = 0.3
	TweenService:Create(levelUpScale, TweenInfo.new(0.45, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	levelScale.Scale = 1.4
	TweenService:Create(levelScale, TweenInfo.new(0.5, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	Effects.jingle(4)
	-- a ring of little stars bursting out
	for k = 1, 14 do
		local a = k / 14 * math.pi * 2
		local star = Ui.new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.45),
			Size = UDim2.fromOffset(14, 14),
			Rotation = 45,
			BackgroundColor3 = if k % 2 == 0 then Ui.CYAN else Ui.VIOLET,
			ZIndex = 45,
			Parent = levelUp,
		}, { Ui.corner(3) })
		TweenService:Create(star, TweenInfo.new(0.8, Enum.EasingStyle.Quint), {
			Position = UDim2.new(0.5, math.cos(a) * 230, 0.45, math.sin(a) * 110),
			BackgroundTransparency = 1,
			Rotation = 225,
		}):Play()
		task.delay(0.85, function()
			star:Destroy()
		end)
	end
	task.delay(1.8, function()
		if levelUpId == id then
			levelUp.Visible = false
		end
	end)
end
State.remote("LevelUp").OnClientEvent:Connect(celebrateLevel)
Hud.LevelUpShown = function()
	return levelUp.Visible, levelUpNumber.Text
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

button(nav, 1, "paw", "Inventory", Inventory.open, nil, "blue")
local _, indexButton = button(nav, 2, "book", "Index", Index.open, nil, "purple")
local _, upgradesButton = button(nav, 3, "tree", "Upgrades", UpgradeTree.open, nil, "green")
button(nav, 4, "star", "Rebirth", Panels.openRebirth, nil, "magenta")
button(nav, 5, "gear", "Settings", Panels.openSettings, nil, "gray")

-- a gold dot on Index when a collection reward is ready
local indexDot = Ui.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(1, -4, 0, 4),
	Size = UDim2.fromOffset(14, 14),
	BackgroundColor3 = Ui.GOLD,
	Visible = false,
	ZIndex = 5,
	Parent = indexButton,
}, { Ui.corner(0.5), Ui.stroke(Ui.WHITE, 2) })
Hud.IndexDot = indexDot

-- a gold dot on Upgrades when something can be bought
local upgradeDot = Ui.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(1, -4, 0, 4),
	Size = UDim2.fromOffset(14, 14),
	BackgroundColor3 = Ui.GOLD,
	Visible = false,
	ZIndex = 5,
	Parent = upgradesButton,
}, { Ui.corner(0.5), Ui.stroke(Ui.INK, 1.5) })


-- Gameplay controls (right side), on their own layer so they always work --------------------------

local controls = Ui.new("Frame", {
	Name = "Controls",
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
controls.Parent = Screen.Controls
local _, hideButton = button(controls, 0, "eye", "Compact", Roll.toggleHatchMode, 44)
local _, autoButton = button(controls, 1, "loop", "Auto", Roll.toggleAuto, 56)
local _, rollButton = button(controls, 2, "dice", "Roll", function()
	task.spawn(Roll.roll)
end, 88, "primary")
Roll.bindButtons(rollButton, autoButton, hideButton)
-- the luck boost badge sits on top of the control column (clear of the
-- reel at any screen size: the column is always right of it)
Roll.BoostBadge.AnchorPoint = Vector2.new(0.5, 1)
Roll.BoostBadge.Position = UDim2.new(1, -66, 1, -288)
Roll.BoostBadge.Parent = Screen.Controls

-- World banner ----------------------------------------------------------------------------------
-- Walking into another world slides a small banner down under the HUD
-- ("Sahara"), in that world's colour, then it slides away.

local banner = Ui.new("Frame", {
	Name = "WorldBanner",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 150),
	Size = UDim2.fromOffset(0, 34),
	AutomaticSize = Enum.AutomaticSize.X,
	BackgroundColor3 = Ui.WHITE,
	Visible = false,
	Parent = gui,
}, {
	Ui.corner(17),
	Ui.new("UIPadding", { PaddingLeft = UDim.new(0, 18), PaddingRight = UDim.new(0, 18) }),
})
local bannerEdge = Ui.stroke(Ui.LINE, 2, 0)
bannerEdge.Parent = banner
local bannerText = Ui.new("TextLabel", {
	AutomaticSize = Enum.AutomaticSize.X,
	Size = UDim2.fromOffset(0, 34),
	Font = Ui.FONT_DISPLAY,
	TextScaled = false,
	TextWrapped = false,
	TextSize = 20,
	Text = "",
	Parent = banner,
})
local bannerToken = 0
Hud.LastBanner = nil -- for the simulator
local function showBanner(area)
	bannerToken += 1
	local token = bannerToken
	Hud.LastBanner = area.Name
	bannerText.Text = area.Name
	bannerText.TextColor3 = area.Color:Lerp(Ui.INK, 0.35)
	bannerEdge.Color = area.Color
	banner.Visible = true
	banner.Position = UDim2.new(0.5, 0, 0, if Ui.reduced() then 150 else 120)
	banner.BackgroundTransparency = 0
	TweenService:Create(banner, TweenInfo.new(0.35, Enum.EasingStyle.Quint), { Position = UDim2.new(0.5, 0, 0, 150) }):Play()
	task.delay(2.2, function()
		if token == bannerToken then
			TweenService:Create(banner, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.In), { Position = UDim2.new(0.5, 0, 0, 120), BackgroundTransparency = 1 }):Play()
			task.delay(0.26, function()
				if token == bannerToken then
					banner.Visible = false
				end
			end)
		end
	end)
end
local shownArea = nil
task.spawn(function()
	while true do
		task.wait(0.3)
		local character = game:GetService("Players").LocalPlayer.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root then
			local area = Config.areaAt(root.Position.X)
			if shownArea and area ~= shownArea then
				showBanner(Config.AREAS[area])
			end
			shownArea = area
		end
	end
end)

-- Updates ------------------------------------------------------------------------------------------

State.watch(function()
	local data = State.Data
	coinsText.Text = Config.formatNumber(data.Coins)
	refreshTeam(data)
	refreshLevel(data)
	upgradeDot.Visible = UpgradeTree.anyAffordable()
	indexDot.Visible = Index.anyClaimable()
end)

-- which version is running (bottom left, small)
Ui.new("TextLabel", {
	AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.new(0, 10, 1, -6),
	Size = UDim2.fromOffset(320, 16),
	Font = Ui.FONT_MEDIUM,
	TextScaled = false,
	TextSize = 12,
	Text = Config.BUILD,
	TextTransparency = 0.35,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = gui,
})
print("[Hatch Incremental] " .. Config.BUILD)

return Hud
