-- The always-on screen, laid out around the fights in the middle:
--   top centre   coins and luck
--   bottom left  the player card: your LEVEL with its EXP bar, and under it
--                YOUR TEAM (equipped pets + damage), out of the way (on
--                phones it goes top left, clear of the joystick, and ROLL /
--                AUTO move up above the jump button: Hud.layout)
--   left side    navigation: Inventory, Index, Upgrades, Rebirth, Settings
--                (the leaderboards are in the world, in the Forest)
--   right side   gameplay: the big Roll button and Auto
-- The top-left corner is left alone: Roblox puts its menu and chat buttons
-- there (the HUD ignores the top bar inset, so anything there would overlap).
local TweenService = game:GetService("TweenService")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local Sticker = require(script.Parent.Sticker)
local Ui = require(script.Parent.Ui)
local Screen = require(script.Parent.Screen)
local State = require(script.Parent.State)
local Effects = require(script.Parent.Effects)
local PetView = require(script.Parent.PetView)
local Roll = require(script.Parent.Roll)
local Index = require(script.Parent.Index)
local Inventory = require(script.Parent.Inventory)
local Travel = require(script.Parent.Travel)
local UpgradeBoard = require(script.Parent.UpgradeBoard) -- every upgrade, on the board standing in the world (and on screen)
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

-- The player card (bottom left): level + EXP on top, your team under it ----------------------------

local card = Ui.new("Frame", {
	Name = "PlayerCard",
	AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.new(0, 16, 1, -16),
	Size = UDim2.fromOffset(0, 0),
	AutomaticSize = Enum.AutomaticSize.XY,
	BackgroundTransparency = 1,
	Parent = gui,
}, {
	Ui.new("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}),
})
Hud.PlayerCard = card
local cardScale = Ui.new("UIScale", { Name = "TouchScale", Parent = card })

-- Your team -----------------------------------------------------------------------------------

local team = Ui.glass({
	Name = "Team",
	LayoutOrder = 2,
	Size = UDim2.fromOffset(0, 64),
	AutomaticSize = Enum.AutomaticSize.X,
	Radius = 20,
	Parent = card,
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
	Size = UDim2.fromOffset(0, 50),
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

-- each equipped pet: a round chip with the pet inside, and under it its
-- damage per second and its share of the team's damage ("1.2K · 45%")
Hud.TeamShares = nil -- for the simulator: what the team bar shows
local teamKey = nil
local function refreshTeam(data)
	local shares, total = Config.teamShares(data)
	local parts = { Config.maxEquipped(data), total }
	for _, share in ipairs(shares) do
		table.insert(parts, share.Name .. "=" .. share.Percent)
	end
	local key = table.concat(parts, ",")
	teamText.Text = Config.formatNumber(total) .. " DPS"
	if key == teamKey then
		return
	end
	teamKey = key
	PetView.releaseAll(chips)
	for _, child in ipairs(chips:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	local shown = {}
	for slot = 1, Config.maxEquipped(data) do
		local share = shares[slot]
		local name = share and share.Name
		local pet, size = Config.petInfo(name)
		local holder = Ui.new("Frame", {
			Name = "Slot" .. slot,
			LayoutOrder = slot,
			Size = UDim2.fromOffset(64, 50),
			BackgroundTransparency = 1,
			Parent = chips,
		})
		-- an equipped pet sits at the top with its DPS under it; an empty
		-- slot has nothing under it, so it sits in the middle
		local chip = Ui.new("Frame", {
			Name = "Chip",
			AnchorPoint = Vector2.new(0.5, if pet then 0 else 0.5),
			Position = UDim2.fromScale(0.5, if pet then 0 else 0.5),
			Size = UDim2.fromOffset(32, 32),
			BackgroundColor3 = if pet then pet.Color:Lerp(Ui.WHITE, 0.55) else Ui.GLASS_LIGHT,
			BackgroundTransparency = if pet then 0 else 0.3,
			Parent = holder,
		}, { Ui.corner(0.5) })
		Ui.stroke(if size and size.Index > 1 then size.Color elseif pet then pet.Color else Ui.LINE, if size and size.Index > 1 then 2.5 else 1.5, 0).Parent = chip
		if pet then
			local view = PetView.take(name)
			view.Size = UDim2.fromScale(1.15, 1.15)
			view.AnchorPoint = Vector2.new(0.5, 0.5)
			view.Position = UDim2.fromScale(0.5, 0.5)
			view.Parent = chip
			local label = Ui.new("TextLabel", {
				Name = "Share",
				Position = UDim2.fromOffset(-6, 33),
				Size = UDim2.new(1, 12, 0, 15),
				Font = Ui.FONT,
				TextScaled = false,
				TextWrapped = false,
				TextSize = 11,
				TextColor3 = Ui.INK,
				Text = Config.formatNumber(share.Dps) .. " · " .. share.Percent .. "%",
				Parent = holder,
			})
			table.insert(shown, { Name = name, Dps = share.Dps, Percent = share.Percent, Text = label.Text })
		end
	end
	Hud.TeamShares = shown
end

-- Level and EXP (the top of the player card) -------------------------------------------------------
-- A chunky gold badge with a star and "LEVEL 12" in white outlined letters,
-- and next to it a thick green EXP bar with a dark cartoon outline.

local OUTLINE = Color3.fromRGB(40, 28, 56)
local levelBar = Ui.new("Frame", {
	Name = "Level",
	LayoutOrder = 1,
	Size = UDim2.fromOffset(320, 40),
	BackgroundTransparency = 1,
	Parent = card,
})
-- (a frame for the gold and its outline; the letters are a label on it with
-- their own outline: one UIStroke per object)
local badgeFrame = Ui.new("Frame", {
	Name = "Badge",
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.fromScale(0, 0.5),
	Size = UDim2.fromOffset(118, 40),
	BackgroundColor3 = Color3.new(1, 1, 1),
	ZIndex = 4,
	Parent = levelBar,
}, {
	Ui.corner(14),
	Ui.new("UIStroke", { Color = OUTLINE, Thickness = 3, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
	Ui.new("UIGradient", { Rotation = 90, Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 232, 100)),
		ColorSequenceKeypoint.new(0.75, Color3.fromRGB(255, 176, 30)),
		ColorSequenceKeypoint.new(0.77, Color3.fromRGB(214, 130, 10)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(214, 130, 10)),
	}) }),
})
local levelBadge = Ui.new("TextLabel", {
	Position = UDim2.fromOffset(30, 0),
	Size = UDim2.new(1, -38, 1, 0),
	Font = Enum.Font.FredokaOne,
	TextScaled = false,
	TextSize = 19,
	TextColor3 = Ui.WHITE,
	Text = "LEVEL 1",
	ZIndex = 5,
	Parent = badgeFrame,
}, { Ui.new("UIStroke", { Color = OUTLINE, Thickness = 2.5, LineJoinMode = Enum.LineJoinMode.Round }) })
-- a white star on the badge's left
local levelStar = Ui.new("Frame", {
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 6, 0.5, 0),
	Size = UDim2.fromOffset(24, 24),
	BackgroundTransparency = 1,
	ZIndex = 5,
	Parent = badgeFrame,
})
Ui.icons.star(levelStar, Ui.WHITE)
for _, d in ipairs(levelStar:GetDescendants()) do
	if d:IsA("GuiObject") then
		d.ZIndex = 5
	end
end
local levelScale = Ui.new("UIScale", { Parent = badgeFrame })
local expTrack = Ui.new("Frame", {
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 110, 0.5, 0),
	Size = UDim2.new(1, -110, 0, 26),
	BackgroundColor3 = Color3.fromRGB(255, 248, 232),
	ZIndex = 2,
	Parent = levelBar,
}, { Ui.corner(13), Ui.new("UIStroke", { Color = OUTLINE, Thickness = 3, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }) })
local expFill = Ui.new("Frame", {
	Size = UDim2.fromScale(0, 1),
	BackgroundColor3 = Color3.new(1, 1, 1),
	ZIndex = 2,
	Parent = expTrack,
}, { Ui.corner(13), Ui.new("UIGradient", { Rotation = 90, Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(150, 240, 110)),
	ColorSequenceKeypoint.new(0.7, Color3.fromRGB(60, 196, 80)),
	ColorSequenceKeypoint.new(0.72, Color3.fromRGB(40, 160, 66)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 160, 66)),
}) }) })
local expText = Ui.new("TextLabel", {
	Size = UDim2.fromScale(1, 1),
	Font = Enum.Font.FredokaOne,
	TextScaled = false,
	TextSize = 14,
	TextColor3 = Ui.WHITE,
	Text = "",
	ZIndex = 3,
	Parent = expTrack,
}, { Ui.new("UIStroke", { Color = OUTLINE, Thickness = 2, LineJoinMode = Enum.LineJoinMode.Round }) })

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
	Size = UDim2.fromOffset(2 * 70 + 6, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundTransparency = 1,
	Parent = gui,
}, {
	-- two columns: Inventory | Index, Upgrades | Teleport, Rebirth | Settings
	Ui.new("UIGridLayout", {
		CellSize = UDim2.fromOffset(70, 76),
		CellPadding = UDim2.fromOffset(6, 4),
		FillDirection = Enum.FillDirection.Horizontal,
		FillDirectionMaxCells = 2,
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
		SortOrder = Enum.SortOrder.LayoutOrder,
	}),
})

-- sticker buttons (Sticker.luau): a big 3D cartoon icon, its name under it
local function button(parent, order, art, label, onClick)
	local holder, b = Sticker.button({
		LayoutOrder = order,
		Art = art,
		Label = label,
		Size = 58,
		CaptionSize = 15,
		Parent = parent,
	}, function()
		Effects.play("Click", 1, 0.05)
		onClick()
	end)
	return holder, b
end

button(nav, 1, "backpack", "Inventory", function()
	Inventory.open()
end)
local _, indexButton = button(nav, 2, "book", "Index", Index.open)
button(nav, 3, "upgrade", "Upgrades", UpgradeBoard.openScreen)
button(nav, 4, "portal", "Teleport", Travel.open)
button(nav, 5, "crown", "Rebirth", Panels.openRebirth)
button(nav, 6, "gear", "Settings", Panels.openSettings)

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



-- Gameplay controls (right side), on their own layer so they always work --------------------------

local controls = Ui.new("Frame", {
	Name = "Controls",
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -18, 1, -16),
	Size = UDim2.fromOffset(Roll.DOCK_SIZE.X, 0),
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
-- the ROLL and AUTO buttons, side by side (Roll.luau)
Roll.buildControls(controls)

-- Phones and tablets ---------------------------------------------------------------------------
-- Roblox puts its movement joystick in the bottom-left corner and the jump
-- button in the bottom-right on touch screens. There the player card moves
-- to the top-left (under Roblox's own menu buttons) and ROLL / AUTO move up
-- above the jump button; with a mouse and keyboard nothing changes.
Hud.Touch = false
Hud.TOUCH_CARD_TOP = 92 -- (under Roblox's top bar on a phone)
Hud.TOUCH_CARD_SCALE = 0.75
function Hud.layout(touch)
	Hud.Touch = touch
	if touch then
		-- card top left under Roblox's buttons, the menu right under the card,
		-- ROLL / AUTO up above the jump button
		-- (a quarter smaller, and low enough to clear Roblox's logo and menu
		-- buttons along the top of a phone)
		card.AnchorPoint = Vector2.new(0, 0)
		card.Position = UDim2.new(0, 12, 0, Hud.TOUCH_CARD_TOP)
		cardScale.Scale = Hud.TOUCH_CARD_SCALE
		nav.AnchorPoint = Vector2.new(0, 0)
		nav.Position = UDim2.new(0, 12, 0, Hud.TOUCH_CARD_TOP + math.ceil(112 * Hud.TOUCH_CARD_SCALE) + 10)
		controls.Position = UDim2.new(1, -18, 1, -210)
	else
		card.AnchorPoint = Vector2.new(0, 1)
		card.Position = UDim2.new(0, 16, 1, -16)
		cardScale.Scale = 1
		nav.AnchorPoint = Vector2.new(0, 0.5)
		nav.Position = UDim2.new(0, 16, 0.5, 20)
		controls.Position = UDim2.new(1, -18, 1, -16)
	end
end
Hud.layout(Screen.Touch)

-- the luck boost badge sits right next to the luck chip at the top (the
-- coin pill lines them up)
Roll.BoostBadge.AnchorPoint = Vector2.new(0, 0)
Roll.BoostBadge.LayoutOrder = 4
Roll.BoostBadge.Parent = coinPill

-- World banner ----------------------------------------------------------------------------------
-- Walking into another world slides a small banner down under the HUD
-- ("Sahara"), in that world's colour, then it slides away.

local banner = Ui.new("Frame", {
	Name = "WorldBanner",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 78),
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
	banner.Position = UDim2.new(0.5, 0, 0, if Ui.reduced() then 78 else 48)
	banner.BackgroundTransparency = 0
	TweenService:Create(banner, TweenInfo.new(0.35, Enum.EasingStyle.Quint), { Position = UDim2.new(0.5, 0, 0, 78) }):Play()
	task.delay(2.2, function()
		if token == bannerToken then
			TweenService:Create(banner, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.In), { Position = UDim2.new(0.5, 0, 0, 48), BackgroundTransparency = 1 }):Play()
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
