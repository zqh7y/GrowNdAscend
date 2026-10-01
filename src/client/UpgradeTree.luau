-- The upgrade tree: hexagon nodes on a teal board, joined by paths. It's
-- built from Config.UPGRADES, so new branches appear on their own. Each
-- node: the icon and a short name on a hexagon, its level under it and the
-- price (or MAX / a padlock). Tapping a node opens a card next to it with
-- the description, now -> next and BUY. (The rest of this comment
-- describes the states, which work the same as before.)
--
-- Layout: a soft board (scrollable on small screens) where the tree grows
-- up from a START point. Upgrades without a requirement hang off START; the
-- others branch off the upgrade they need (Config.UPGRADES[].Requires),
-- joined by rounded elbow connectors that fill with the branch colour once
-- unlocked.
--
-- Each upgrade is a card: a coloured icon tile and the name, the level as
-- "Lv 4 / 20" with a slim progress bar, and the price ALWAYS visible in a
-- pill at the bottom. States read at a glance:
--   locked      faded card, grey tile, padlock + what it needs
--   available   white card, price in grey (not enough coins yet)
--   affordable  coloured outline that gently breathes, green price pill
--   maxed       gold outline and a gold MAX pill
-- Hover lifts a card, pressing presses it, clicking selects it (outlined,
-- shown in full on the right: now -> next, description, BUY). Buying makes
-- the card pop, the bar fill, the connector flash, sparkles burst and
-- "+1 level" float up, with a jingle.
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local Ui = require(script.Parent.Ui)
local Screen = require(script.Parent.Screen)
local State = require(script.Parent.State)
local Effects = require(script.Parent.Effects)

local UpgradeTree = {}

local buyFunction = State.remote("BuyUpgrade")

local WIDTH, HEIGHT = 1060, 660
local DETAIL_W = 300
local VIEW_W, VIEW_H = WIDTH - 48, HEIGHT - 48 - 46
local CARD_H = 96 -- a node's hexagon height
local CARD_W = math.floor(CARD_H * Ui.HEX_RATIO + 0.5)
local COL_GAP, ROW_GAP = 210, 172
local EASE = TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local TRACK = Color3.fromRGB(70, 140, 150)
local BOARD = Color3.fromRGB(30, 98, 110)
local NODE_TOP, NODE_BOTTOM = Color3.fromRGB(150, 236, 236), Color3.fromRGB(46, 170, 184)
local LOCKED_TOP, LOCKED_BOTTOM = Color3.fromRGB(96, 104, 120), Color3.fromRGB(58, 64, 80)

local modal, box = Screen.modal(WIDTH, HEIGHT, "Upgrades")
UpgradeTree.Modal = modal
Screen.title(box, "Upgrade Tree")
local coinsLine = Screen.subtitle(box, "")
coinsLine.Position = UDim2.new(1, -188, 0, 8) -- left of Equip Best
coinsLine.TextColor3 = Ui.INK

-- Equip Best: your strongest team in one tap (same as in the Inventory)
UpgradeTree.EquipBestButton = Ui.button({
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -44, 0, 0),
	Size = UDim2.fromOffset(132, 34),
	Radius = 17,
	Text = "Equip Best",
	Icon = "star",
	TextSize = 14,
	ZIndex = 33,
	Parent = box,
}, function()
	require(script.Parent.Inventory).equipBest()
end, "primary")

-- The board ----------------------------------------------------------------------------------------

local view = Ui.new("ScrollingFrame", {
	Name = "Board",
	Position = UDim2.fromOffset(0, 46),
	Size = UDim2.fromOffset(VIEW_W, VIEW_H),
	BackgroundColor3 = BOARD,
	ScrollBarThickness = 6,
	ScrollBarImageColor3 = Color3.fromRGB(150, 210, 214),
	ScrollingDirection = Enum.ScrollingDirection.XY,
	ElasticBehavior = Enum.ElasticBehavior.Always,
	ZIndex = 32,
	Parent = box,
}, { Ui.corner(16) })
Ui.new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(190, 200, 205)), Parent = view })
Ui.stroke(Color3.fromRGB(20, 70, 80), 3, 0).Parent = view

-- Laying out the tree ---------------------------------------------------------------------------

-- depth: 0 for upgrades that need nothing, parent's depth + 1 otherwise
local children, depth, roots = {}, {}, {}
for _, upgrade in ipairs(Config.UPGRADES) do
	children[upgrade.Id] = {}
end
for _, upgrade in ipairs(Config.UPGRADES) do
	if upgrade.Requires then
		table.insert(children[upgrade.Requires[1]], upgrade.Id)
	else
		table.insert(roots, upgrade.Id)
	end
end
local maxDepth = 0
local function setDepth(id, d)
	depth[id] = d
	maxDepth = math.max(maxDepth, d)
	for _, child in ipairs(children[id]) do
		setDepth(child, d + 1)
	end
end
for _, id in ipairs(roots) do
	setDepth(id, 0)
end
-- columns: leaves get one each (left to right); parents sit over their children
local column, columns = {}, 0
local function place(id)
	if #children[id] == 0 then
		columns += 1
		column[id] = columns
		return columns
	end
	local sum = 0
	for _, child in ipairs(children[id]) do
		sum += place(child)
	end
	column[id] = sum / #children[id]
	return column[id]
end
for _, id in ipairs(roots) do
	place(id)
end

-- the board is as big as the tree (at least the view), the tree centred in it
local BOARD_W = math.max(VIEW_W, columns * COL_GAP + 60)
local BOARD_H = math.max(VIEW_H, maxDepth * ROW_GAP + 250)
view.CanvasSize = UDim2.fromOffset(BOARD_W, BOARD_H)
local left = (BOARD_W - columns * COL_GAP) / 2
local START = Vector2.new(BOARD_W / 2, BOARD_H - 40)
local function centreOf(id)
	return Vector2.new(left + (column[id] - 0.5) * COL_GAP, BOARD_H - 130 - depth[id] * ROW_GAP)
end
-- start scrolled to the bottom (where the tree begins), centred
view.CanvasPosition = Vector2.new((BOARD_W - VIEW_W) / 2, BOARD_H - VIEW_H)

-- a straight rounded bar between two points (horizontal or vertical)
local function segment(a, b, color, z)
	local min = Vector2.new(math.min(a.X, b.X), math.min(a.Y, b.Y))
	local size = Vector2.new(math.abs(a.X - b.X), math.abs(a.Y - b.Y))
	return Ui.new("Frame", {
		Position = UDim2.fromOffset(min.X - 4, min.Y - 4),
		Size = UDim2.fromOffset(size.X + 8, size.Y + 8),
		BackgroundColor3 = color,
		ZIndex = z or 33,
		Parent = view,
	}, { Ui.corner(2) })
end

-- an elbow connector from `from` up to the bottom of a card at `to`
local function connector(from, to)
	local midY = (from.Y + to.Y) / 2
	return {
		segment(from, Vector2.new(from.X, midY), TRACK),
		segment(Vector2.new(from.X, midY), Vector2.new(to.X, midY), TRACK),
		segment(Vector2.new(to.X, midY), to, TRACK),
	}
end

-- the START point
local startDot = Ui.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromOffset(START.X, START.Y),
	Size = UDim2.fromOffset(84, 30),
	BackgroundColor3 = Ui.INK,
	ZIndex = 35,
	Parent = view,
}, { Ui.corner(15) })
Ui.new("TextLabel", {
	Size = UDim2.fromScale(1, 1),
	Font = Ui.FONT,
	TextScaled = false,
	TextSize = 13,
	Text = "START",
	TextColor3 = Ui.WHITE,
	ZIndex = 36,
	Parent = startDot,
})

local function label(parent, props)
	props.BackgroundTransparency = props.BackgroundTransparency or 1
	props.TextScaled = false
	props.ZIndex = props.ZIndex or 37
	props.Parent = parent
	return Ui.new("TextLabel", props)
end

local nodes = {} -- [id] = { Card, Scale, Stroke, Tile, Bar, Price, ... }
UpgradeTree.Nodes = nodes -- (for the simulator)
local selected = Config.UPGRADES[1].Id

for _, upgrade in ipairs(Config.UPGRADES) do
	local id = upgrade.Id
	local c = centreOf(id)
	local from = if upgrade.Requires then centreOf(upgrade.Requires[1]) - Vector2.new(0, CARD_H / 2) else START - Vector2.new(0, 15)
	local n = { Upgrade = upgrade, Position = c }
	n.Path = connector(from, c + Vector2.new(0, CARD_H / 2))

	-- the node: a transparent button holding the hexagon
	n.Shadow = Ui.hexagon({
		Size = CARD_H,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(c.X, c.Y + 5),
		Colors = { Color3.fromRGB(10, 40, 48), Color3.fromRGB(10, 40, 48) },
		ZIndex = 34,
		Parent = view,
	})
	n.Shadow.Fill.GroupTransparency = 0.55
	local card = Ui.new("TextButton", {
		Name = id,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(c.X, c.Y),
		Size = UDim2.fromOffset(CARD_W, CARD_H),
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
		ZIndex = 35,
		Parent = view,
	})
	n.Card = card
	n.Scale = Ui.new("UIScale", { Parent = card })
	n.Hex = Ui.hexagon({
		Size = CARD_H,
		Colors = { NODE_TOP, NODE_BOTTOM },
		Edge = Color3.fromRGB(235, 255, 255),
		EdgeSize = 3,
		ZIndex = 35,
		Parent = card,
	})
	-- (the outline that marks selected / affordable / maxed)
	n.Stroke = { Color = Ui.WHITE, Thickness = 0, Transparency = 0 }
	n.Tile = Ui.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 16),
		Size = UDim2.fromOffset(36, 36),
		BackgroundTransparency = 1,
		BackgroundColor3 = upgrade.Color,
		ZIndex = 36,
		Parent = card,
	})
	n.Icon = Ui.icon(upgrade.Icon, 32, upgrade.Color, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), ZIndex = 37, Parent = n.Tile })
	n.Unknown = Ui.chunky({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.42),
		Size = UDim2.fromOffset(40, 40),
		TextSize = 40,
		Text = "?",
		Outline = 3,
		Visible = false,
		ZIndex = 38,
		Parent = card,
	})
	n.Name = Ui.chunky({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 54),
		Size = UDim2.new(1, -14, 0, 24),
		TextSize = 12,
		TextWrapped = true,
		Text = upgrade.Name,
		Outline = 1.5,
		ZIndex = 37,
		Parent = card,
	})
	-- level badge on the top-right edge ("3/20")
	n.Level = Ui.chunky({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(1, -6, 0, 12),
		Size = UDim2.fromOffset(44, 18),
		TextSize = 13,
		Outline = 2,
		ZIndex = 38,
		Parent = card,
	})
	n.Bar = Ui.new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundTransparency = 1, Parent = card }) -- (kept for older code)
	-- price under the node (always visible)
	n.Price = Ui.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 1, 2),
		Size = UDim2.fromOffset(0, 24),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = Color3.fromRGB(16, 56, 66),
		BackgroundTransparency = 0.2,
		ZIndex = 38,
		Parent = card,
	}, {
		Ui.corner(12),
		Ui.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }),
		Ui.new("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 8) }),
	})
	n.PriceIcon = Ui.icon("coin", 16, Ui.GOLD, { LayoutOrder = 0, ZIndex = 39, Parent = n.Price })
	n.LockIcon = Ui.icon("lock", 14, Ui.WHITE, { LayoutOrder = 1, ZIndex = 39, Parent = n.Price })
	n.PriceText = Ui.chunky({
		LayoutOrder = 2,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 20),
		TextSize = 14,
		TextWrapped = false,
		Outline = 1.5,
		ZIndex = 39,
		Parent = n.Price,
	})

	-- hover lifts, press presses, click selects
	card.MouseEnter:Connect(function()
		n.Hover = true
		TweenService:Create(n.Scale, EASE, { Scale = 1.04 }):Play()
		TweenService:Create(n.Shadow, EASE, { Position = UDim2.fromOffset(c.X, c.Y + 9) }):Play()
	end)
	card.MouseLeave:Connect(function()
		n.Hover = false
		TweenService:Create(n.Scale, EASE, { Scale = 1 }):Play()
		TweenService:Create(n.Shadow, EASE, { Position = UDim2.fromOffset(c.X, c.Y + 5) }):Play()
	end)
	card.MouseButton1Down:Connect(function()
		TweenService:Create(n.Scale, TweenInfo.new(0.08), { Scale = 0.97 }):Play()
	end)
	card.MouseButton1Up:Connect(function()
		TweenService:Create(n.Scale, EASE, { Scale = if n.Hover then 1.04 else 1 }):Play()
	end)
	card.Activated:Connect(function()
		Effects.play("Click", 1.1, 0.05)
		UpgradeTree.select(id)
	end)
	nodes[id] = n
end

-- The detail panel on the right ------------------------------------------------------------------

-- (a white card that pops up next to the node you tapped)
local detail = Ui.new("Frame", {
	Name = "NodeCard",
	Position = UDim2.fromOffset(0, 52),
	Size = UDim2.fromOffset(DETAIL_W, 380),
	BackgroundColor3 = Ui.WHITE,
	Visible = false,
	ZIndex = 50,
	Parent = box,
}, { Ui.corner(22), Ui.padding(18) })
Ui.new("UIStroke", { Color = Ui.OUTLINE, Thickness = 4, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = detail })
UpgradeTree.Card = detail
local cardClose = Ui.new("TextButton", {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, 8, 0, -8),
	Size = UDim2.fromOffset(28, 28),
	BackgroundColor3 = Ui.GLASS_LIGHT,
	AutoButtonColor = false,
	Text = "",
	ZIndex = 60,
	Parent = detail,
}, { Ui.corner(14) })
Ui.icon("close", 10, Ui.MUTED, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), ZIndex = 61, Parent = cardClose })
cardClose.Activated:Connect(function()
	detail.Visible = false
	if UpgradeTree.refresh then
		UpgradeTree.refresh()
	end
end)
local detailTile = Ui.new("Frame", {
	Size = UDim2.fromOffset(64, 64),
	BackgroundColor3 = Ui.BLUE,
	ZIndex = 33,
	Parent = detail,
}, {
	Ui.corner(20),
	Ui.new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(215, 215, 215)) }),
})
local detailTileScale = Ui.new("UIScale", { Parent = detailTile })
local detailIconHolder = Ui.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(36, 36),
	BackgroundTransparency = 1,
	ZIndex = 34,
	Parent = detailTile,
})
local detailName = label(detail, {
	Position = UDim2.fromOffset(78, 6),
	Size = UDim2.new(1, -78, 0, 28),
	Font = Ui.FONT_DISPLAY,
	TextSize = 24,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextTruncate = Enum.TextTruncate.AtEnd,
	TextColor3 = Ui.INK,
	ZIndex = 33,
})
local detailLevel = label(detail, {
	Position = UDim2.fromOffset(78, 36),
	Size = UDim2.new(1, -78, 0, 18),
	Font = Ui.FONT_MEDIUM,
	TextSize = 14,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = Ui.MUTED,
	ZIndex = 33,
})
local detailText = label(detail, {
	Position = UDim2.fromOffset(0, 80),
	Size = UDim2.new(1, 0, 0, 46),
	Font = Ui.FONT_MEDIUM,
	TextSize = 14,
	TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	TextColor3 = Ui.MUTED,
	ZIndex = 33,
})
-- level pips (one per level, up to 25)
local pips = Ui.new("Frame", {
	Position = UDim2.fromOffset(0, 132),
	Size = UDim2.new(1, 0, 0, 8),
	BackgroundTransparency = 1,
	ZIndex = 33,
	Parent = detail,
}, {
	Ui.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }),
})
-- now -> next
local change = Ui.new("Frame", {
	Position = UDim2.fromOffset(0, 156),
	Size = UDim2.new(1, 0, 0, 86),
	BackgroundColor3 = Ui.WHITE,
	ZIndex = 33,
	Parent = detail,
}, { Ui.corner(14), Ui.stroke(Ui.LINE, 1, 0) })
label(change, { Position = UDim2.fromOffset(0, 10), Size = UDim2.new(0.5, 0, 0, 14), Font = Ui.FONT_MEDIUM, TextSize = 12, Text = "Now", TextColor3 = Ui.MUTED, ZIndex = 34 })
label(change, { Position = UDim2.new(0.5, 0, 0, 10), Size = UDim2.new(0.5, 0, 0, 14), Font = Ui.FONT_MEDIUM, TextSize = 12, Text = "Next", TextColor3 = Ui.MUTED, ZIndex = 34 })
local nowText = label(change, { Position = UDim2.fromOffset(6, 30), Size = UDim2.new(0.5, -16, 0, 40), Font = Ui.FONT_DISPLAY, TextSize = 24, TextColor3 = Ui.INK, ZIndex = 34 })
local nextText = label(change, { Position = UDim2.new(0.5, 10, 0, 30), Size = UDim2.new(0.5, -16, 0, 40), Font = Ui.FONT_DISPLAY, TextSize = 24, TextColor3 = Ui.SUCCESS, ZIndex = 34 })
local arrow = Ui.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(0.5, 0, 0, 50),
	Size = UDim2.fromOffset(26, 26),
	BackgroundColor3 = Ui.GLASS_LIGHT,
	ZIndex = 34,
	Parent = change,
}, { Ui.corner(13) })
label(arrow, { Size = UDim2.fromScale(1, 1), TextSize = 14, Text = "→", TextColor3 = Ui.MUTED, ZIndex = 35 })
local lockNote = label(detail, {
	Position = UDim2.fromOffset(0, 246),
	Size = UDim2.new(1, 0, 0, 36),
	Font = Ui.FONT_MEDIUM,
	TextSize = 14,
	TextWrapped = true,
	TextColor3 = Ui.MUTED,
	ZIndex = 33,
})
local buyButton = Ui.button({
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, 0),
	Size = UDim2.new(1, 0, 0, 58),
	Radius = 18,
	Icon = "coin",
	Text = "BUY",
	TextSize = 22,
	ZIndex = 34,
	Parent = detail,
}, function()
	UpgradeTree.buy()
end, "success")
local buyScale = Ui.new("UIScale", { Parent = buyButton })

-- Showing state ------------------------------------------------------------------------------------

UpgradeTree.States = {} -- for the simulator: [id] = "locked" | "available" | "affordable" | "maxed"

local function refresh(animate)
	local data = State.Data
	if not data then
		return
	end
	coinsLine.Text = "You have " .. Config.formatNumber(data.Coins) .. " coins"
	for _, upgrade in ipairs(Config.UPGRADES) do
		local n = nodes[upgrade.Id]
		local level = Config.upgradeLevel(data, upgrade.Id)
		local ok, reason = Config.canUpgrade(data, upgrade.Id)
		local maxed = level >= upgrade.Max
		local cost = upgrade.Cost(level)
		local locked = not ok and not maxed
		local affordable = ok and data.Coins >= cost
		local state = if maxed then "maxed" elseif locked then "locked" elseif affordable then "affordable" else "available"
		UpgradeTree.States[upgrade.Id] = state
		n.State = state

		local isSelected = upgrade.Id == selected and detail.Visible
		-- the hexagon: teal, gold when maxed, dark with "?" when locked; its
		-- rim is dark when selected and the upgrade's colour when affordable
		local top, bottom = NODE_TOP, NODE_BOTTOM
		if maxed then
			top, bottom = Color3.fromRGB(255, 226, 120), Color3.fromRGB(240, 170, 30)
		elseif locked then
			top, bottom = LOCKED_TOP, LOCKED_BOTTOM
		end
		local rim = if isSelected then Ui.OUTLINE elseif affordable then upgrade.Color:Lerp(Ui.WHITE, 0.2) else Color3.fromRGB(235, 255, 255)
		Ui.setHexColors(n.Hex, top, bottom, rim)
		n.Stroke.Color, n.Stroke.Thickness = rim, if isSelected then 3 else 2
		n.Icon.Visible = not locked
		n.Unknown.Visible = locked
		n.Name.Text = if locked then "" else upgrade.Name
		n.Level.Text = level .. "/" .. upgrade.Max
		n.Level.Visible = not locked
		for _, piece in ipairs(n.Path) do
			piece.BackgroundColor3 = if locked then TRACK else (if maxed then Ui.GOLD else Color3.fromRGB(170, 240, 240))
		end
		-- the price under the node
		n.LockIcon.Visible = locked
		n.PriceIcon.Visible = not locked and not maxed
		if maxed then
			n.PriceText.Text = "MAX"
			n.PriceText.TextColor3 = Ui.GOLD
			n.Price.BackgroundColor3 = Color3.fromRGB(120, 80, 10)
		elseif locked then
			-- short, so neighbours never overlap: "Coins Lv 1"
			n.PriceText.Text = (string.gsub(string.gsub(reason or "", "^Needs ", ""), " level ", " Lv "))
			n.PriceText.TextSize = 11
			n.PriceText.TextColor3 = Ui.WHITE
			n.Price.BackgroundColor3 = Color3.fromRGB(40, 46, 60)
		else
			n.PriceText.Text = Config.formatNumber(cost)
			n.PriceText.TextSize = 14
			n.PriceText.TextColor3 = if affordable then Color3.fromRGB(150, 255, 160) else Color3.fromRGB(255, 150, 160)
			n.Price.BackgroundColor3 = if affordable then Color3.fromRGB(20, 110, 60) else Color3.fromRGB(16, 56, 66)
		end
	end

	-- the selected upgrade in full
	local upgrade = Config.UPGRADES_BY_ID[selected]
	local level = Config.upgradeLevel(data, selected)
	local ok, reason = Config.canUpgrade(data, selected)
	local cost = upgrade.Cost(level)
	local maxed = level >= upgrade.Max
	detailTile.BackgroundColor3 = if maxed then Ui.GOLD else upgrade.Color
	if detailIconHolder:GetAttribute("Icon") ~= upgrade.Icon then
		detailIconHolder:ClearAllChildren()
		Ui.icons[upgrade.Icon](detailIconHolder, Ui.WHITE)
		detailIconHolder:SetAttribute("Icon", upgrade.Icon)
	end
	detailName.Text = upgrade.Name
	detailLevel.Text = "Level " .. level .. " of " .. upgrade.Max
	detailText.Text = upgrade.Describe
	nowText.Text = upgrade.Format(upgrade.Value(level))
	nextText.Text = if maxed then "MAX" else upgrade.Format(upgrade.Value(level + 1))
	nextText.TextColor3 = if maxed then Ui.GOLD else Ui.SUCCESS
	lockNote.Text = if maxed then "All levels bought" elseif not ok then "Needs: " .. reason else ""
	-- pips
	if pips:GetAttribute("For") ~= selected .. ":" .. level then
		pips:SetAttribute("For", selected .. ":" .. level)
		for _, child in ipairs(pips:GetChildren()) do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end
		local count = math.min(upgrade.Max, 25)
		local width = math.floor((DETAIL_W - 36 - (count - 1) * 3) / count)
		for k = 1, count do
			local reached = k <= math.floor(level / upgrade.Max * count + 1e-9)
			Ui.new("Frame", {
				LayoutOrder = k,
				Size = UDim2.fromOffset(width, 8),
				BackgroundColor3 = if reached then (if maxed then Ui.GOLD else upgrade.Color) else TRACK,
				ZIndex = 34,
				Parent = pips,
			}, { Ui.corner(4) })
		end
	end
	if maxed then
		Ui.setText(buyButton, "MAXED")
		Ui.setStyle(buyButton, "disabled")
	else
		Ui.setText(buyButton, "BUY  " .. Config.formatNumber(cost))
		Ui.setStyle(buyButton, if ok and data.Coins >= cost then "success" else "disabled")
	end
end

-- puts the card next to a node (right of it, or left if there's no room)
local function placeCard(id)
	local n = nodes[id]
	local onBoard = n.Position - view.CanvasPosition + Vector2.new(0, 46)
	local x = onBoard.X + CARD_W / 2 + 16
	if x + DETAIL_W > VIEW_W then
		x = onBoard.X - CARD_W / 2 - 16 - DETAIL_W
	end
	local y = math.clamp(onBoard.Y - 190, 46, 46 + VIEW_H - 380)
	detail.Position = UDim2.fromOffset(math.clamp(x, 0, VIEW_W - DETAIL_W), y)
end

UpgradeTree.refresh = refresh

function UpgradeTree.select(id)
	if selected ~= id or not detail.Visible then
		detailTileScale.Scale = 0.85
		TweenService:Create(detailTileScale, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	end
	selected = id
	placeCard(id)
	if not detail.Visible then
		detail.Visible = true
		Ui.pop(detail, 0.9)
	end
	refresh()
end

-- A burst of little stars flying out of a point on the board
local function sparkles(at, color)
	for k = 1, 12 do
		local a = k / 12 * math.pi * 2 + math.random() * 0.4
		local star = Ui.new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(at.X, at.Y),
			Size = UDim2.fromOffset(10, 10),
			Rotation = 45,
			BackgroundColor3 = if k % 3 == 0 then Color3.new(1, 1, 1) elseif k % 3 == 1 then Ui.GOLD else color,
			ZIndex = 40,
			Parent = view,
		}, { Ui.corner(3) })
		local distance = 80 + math.random() * 40
		TweenService:Create(star, TweenInfo.new(0.6, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			Position = UDim2.fromOffset(at.X + math.cos(a) * distance, at.Y + math.sin(a) * distance),
			Rotation = 45 + 180,
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(4, 4),
		}):Play()
		task.delay(0.65, function()
			star:Destroy()
		end)
	end
end

-- "+1 level" rising from a card and fading
local function floatText(at, text, color)
	local l = label(view, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(at.X, at.Y - CARD_H / 2),
		Size = UDim2.fromOffset(260, 26),
		Font = Ui.FONT_DISPLAY,
		TextSize = 20,
		Text = text,
		TextColor3 = color,
		TextStrokeTransparency = 0.4,
		TextStrokeColor3 = Ui.INK,
		ZIndex = 41,
	})
	TweenService:Create(l, TweenInfo.new(1.1, Enum.EasingStyle.Quint), { Position = UDim2.fromOffset(at.X, at.Y - CARD_H / 2 - 56), TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	task.delay(1.15, function()
		l:Destroy()
	end)
end

UpgradeTree.LastBuy = nil -- for the simulator: { Id, Level, Text }

function UpgradeTree.buy()
	local id = selected
	local upgrade = Config.UPGRADES_BY_ID[id]
	local before = if State.Data then Config.upgradeLevel(State.Data, id) else 0
	local n = nodes[id]
	buyScale.Scale = 0.94
	TweenService:Create(buyScale, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	if buyFunction:InvokeServer(id) then
		local text = "+1 level  " .. upgrade.Format(upgrade.Value(before + 1))
		UpgradeTree.LastBuy = { Id = id, Level = before + 1, Text = text }
		Effects.jingle(3)
		-- anticipation (a little squash), then the pop
		n.Scale.Scale = 0.94
		TweenService:Create(n.Scale, TweenInfo.new(0.4, Enum.EasingStyle.Back), { Scale = 1 }):Play()
		for _, piece in ipairs(n.Path) do
			piece.BackgroundColor3 = Ui.WHITE
		end
		sparkles(n.Position, upgrade.Color)
		floatText(n.Position, text, upgrade.Color:Lerp(Ui.WHITE, 0.2))
		task.delay(0.12, refresh, true)
	else
		Effects.play("Click", 0.7)
		-- a short "no" shake
		for k = 1, 4 do
			task.delay(k * 0.04, function()
				n.Card.Position = UDim2.fromOffset(n.Position.X + (if k % 2 == 0 then -4 else 4), n.Position.Y)
			end)
		end
		task.delay(0.2, function()
			n.Card.Position = UDim2.fromOffset(n.Position.X, n.Position.Y)
		end)
	end
end

function UpgradeTree.open()
	Screen.open(modal)
	detail.Visible = false
	refresh()
end

-- true if anything can be bought right now (the HUD shows a dot)
function UpgradeTree.anyAffordable()
	local data = State.Data
	if not data then
		return false
	end
	for _, upgrade in ipairs(Config.UPGRADES) do
		if Config.canUpgrade(data, upgrade.Id) and data.Coins >= upgrade.Cost(Config.upgradeLevel(data, upgrade.Id)) then
			return true
		end
	end
	return false
end

-- affordable cards breathe gently (their outline); nothing else moves
RunService.RenderStepped:Connect(function()
	if not modal.Visible then
		return
	end
	local t = os.clock()
	for id, n in pairs(nodes) do
		-- affordable nodes breathe gently (a soft pulse in size)
		if n.State == "affordable" and id ~= selected and not n.Hover and not Ui.reduced() then
			n.Scale.Scale = 1 + (math.sin(t * 3 + n.Position.X * 0.01) * 0.5 + 0.5) * 0.04
		elseif not n.Hover and n.Scale.Scale ~= 1 and n.State ~= "affordable" then
			n.Scale.Scale = 1
		end
	end
end)

State.watch(function()
	if modal.Visible then
		refresh()
	end
end)

return UpgradeTree
