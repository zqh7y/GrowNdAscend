-- The Inventory ("My Pets"): your pet collection.
--
--   EQUIPPED   along the top: "3/5 Equipped" and your team's tiles.
--   THE GRID   many pet tiles at once (about 5-8 per row, worked out from
--              the space available, so it adapts to the panel and screen).
--              Each is the collection tile (PetTile): the pet on a hexagon
--              in its rarity's colours, HUGE/TITANIC, its odds ("1/430K"),
--              "x3" for copies and a green check when equipped.
--   DETAILS    tapping a pet slides a details panel in on the right (the
--              grid stays visible, just narrower): a big preview, name,
--              rarity and size, power and damage per second, its five
--              multipliers, how many you have and are using, and one
--              Equip / Unequip button. Tapping another pet updates it in
--              place; the X closes it and the grid takes the full width.
--   TOOLBAR    compact tabs (All, Normal, Huge, Titanic, Equipped), a small
--              Sort menu (Power, Newest, Rarity) and Equip Best.
local TweenService = game:GetService("TweenService")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local Effects = require(script.Parent.Effects)
local PetTile = require(script.Parent.PetTile)
local PetView = require(script.Parent.PetView)
local Screen = require(script.Parent.Screen)
local State = require(script.Parent.State)
local Ui = require(script.Parent.Ui)

local Inventory = {}

local equipFunction = State.remote("Equip")
local equipBestFunction = State.remote("EquipBest")

local WIDTH, HEIGHT = 900, 660
local INNER_W = WIDTH - 48
local DETAIL_W, GAP = 268, 12
local TEAM_TILE = 76 -- width of the equipped tiles along the top
local TEAM_Y = 30
local TABS_Y = TEAM_Y + math.floor(TEAM_TILE * 1.18) + 12
local TOP = TABS_Y + 46 -- where the grid starts
local CARD_TARGET, CARD_GAP = 100, 10
local EASE = TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

local modal, box = Screen.modal(WIDTH, HEIGHT, "Inventory")
Screen.title(box, "My Pets")
local hint = Screen.subtitle(box, "")
hint.Position = UDim2.new(1, -40, 0, 2)

-- "3/5 Equipped" with a line each side, then the team's tiles
local equippedTitle = Ui.chunky({
	Name = "EquippedTitle",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, -4),
	Size = UDim2.fromOffset(240, 28),
	TextSize = 24,
	Text = "0/1 Equipped",
	Outline = 2.5,
	ZIndex = 34,
	Parent = box,
})
for _, side in ipairs({ -1, 1 }) do
	Ui.new("Frame", {
		AnchorPoint = Vector2.new(if side < 0 then 1 else 0, 0.5),
		Position = UDim2.new(0.5, side * 130, 0, 10),
		Size = UDim2.new(0.5, -170, 0, 3),
		BackgroundColor3 = Color3.fromRGB(196, 186, 214),
		ZIndex = 33,
		Parent = box,
	}, { Ui.corner(2) })
end
local teamRow = Ui.new("Frame", {
	Name = "TeamRow",
	Position = UDim2.fromOffset(0, TEAM_Y),
	Size = UDim2.new(1, 0, 0, math.floor(TEAM_TILE * 1.18)),
	BackgroundTransparency = 1,
	ZIndex = 33,
	Parent = box,
}, {
	Ui.new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Padding = UDim.new(0, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}),
})
Inventory.TeamRow = teamRow
Ui.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, TABS_Y - 7),
	Size = UDim2.new(1, -40, 0, 3),
	BackgroundColor3 = Color3.fromRGB(196, 186, 214),
	ZIndex = 33,
	Parent = box,
}, { Ui.corner(2) })

-- Equip Best (shared with the upgrade tree) -----------------------------------------------------

Inventory.LastEquipBest = nil -- for the simulator: the server's answer

-- Equips your best team (the server picks it: real damage, then luck,
-- then coins) and says what happened in a small toast
function Inventory.equipBest()
	local result = equipBestFunction:InvokeServer()
	Inventory.LastEquipBest = result
	if type(result) ~= "table" then
		return
	end
	if not result.Changed then
		Screen.toast("Team already optimized ✓", "success")
		return
	end
	-- "Equipped: Tiger x2, Huge Fox"
	local counts, order = {}, {}
	for _, name in ipairs(result.Added) do
		if not counts[name] then
			table.insert(order, name)
		end
		counts[name] = (counts[name] or 0) + 1
	end
	local parts = {}
	for _, name in ipairs(order) do
		table.insert(parts, Config.fullName(name) .. (if counts[name] > 1 then " x" .. counts[name] else ""))
	end
	Screen.toast("Equipped: " .. table.concat(parts, ", "), "success")
	Effects.jingle(2)
end

local equipBestButton = Ui.button({
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, 0, 0, TABS_Y + 1),
	Size = UDim2.fromOffset(132, 34),
	Radius = 17,
	Text = "Equip Best",
	Icon = "star",
	TextSize = 14,
	ZIndex = 33,
	Parent = box,
}, function()
	Inventory.equipBest()
end, "primary")
Inventory.EquipBestButton = equipBestButton

-- Filters and sorting ----------------------------------------------------------------------

local function count(list, name)
	local n = 0
	for _, v in ipairs(list) do
		if v == name then
			n += 1
		end
	end
	return n
end

local function sizeOf(name)
	return (select(2, Config.petInfo(name))).Index
end

local FILTERS = {
	{ Name = "All", Empty = "No pets yet. Press ROLL to hatch your first one!", Keep = function() return true end },
	{ Name = "Normal", Empty = "No normal pets.", Keep = function(name) return sizeOf(name) == 1 end },
	{ Name = "Huge", Empty = "No Huge pets yet.", Keep = function(name) return sizeOf(name) == 2 end },
	{ Name = "Titanic", Empty = "No Titanic pets yet.", Keep = function(name) return sizeOf(name) == 3 end },
	{ Name = "Equipped", Empty = "Nothing equipped. Tap a pet, then Equip!", Keep = function(_, equipped) return equipped > 0 end },
}
local SORTS = {
	{ Name = "Power", Before = function(a, b) return Config.petPower(a) > Config.petPower(b) end },
	{ Name = "Newest", Before = function(a, b, data)
		local na, nb = (data.Obtained or {})[a] or 0, (data.Obtained or {})[b] or 0
		if na ~= nb then return na > nb end
		return Config.petPower(a) > Config.petPower(b)
	end },
	{ Name = "Rarity", Before = function(a, b)
		local pa, pb = Config.petInfo(a), Config.petInfo(b)
		local sa, sb = sizeOf(a), sizeOf(b)
		if sa ~= sb then return sa > sb end
		if pa.Odds ~= pb.Odds then return pa.Odds > pb.Odds end
		return a < b
	end },
}
Inventory.FILTERS, Inventory.SORTS = FILTERS, SORTS
Inventory.Filter = 1
Inventory.Sort = 1
Inventory.Selected = nil -- the pet whose details are open
local refresh, select, rebuild

-- tabs: one compact segmented pill
local tabs = Ui.new("Frame", {
	Name = "Tabs",
	Position = UDim2.fromOffset(0, TABS_Y),
	Size = UDim2.fromOffset(0, 36),
	AutomaticSize = Enum.AutomaticSize.X,
	BackgroundColor3 = Ui.GLASS_LIGHT,
	ZIndex = 32,
	Parent = box,
}, {
	Ui.corner(18),
	Ui.padding(3),
	Ui.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }),
})
local tabButtons = {}
for i, filter in ipairs(FILTERS) do
	local tab = Ui.new("TextButton", {
		Name = filter.Name,
		LayoutOrder = i,
		Size = UDim2.fromOffset(if filter.Name == "Equipped" then 92 else 76, 30),
		BackgroundColor3 = Ui.WHITE,
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Font = Ui.FONT,
		TextScaled = false,
		TextSize = 14,
		Text = filter.Name,
		TextColor3 = Ui.MUTED,
		ZIndex = 33,
		Parent = tabs,
	}, { Ui.corner(15) })
	tab.Activated:Connect(function()
		Effects.play("Click", 1.1, 0.05)
		Inventory.Filter = i
		refresh(true)
	end)
	tabButtons[i] = tab
end

-- sort: a small menu button
local sortButton = Ui.new("TextButton", {
	Name = "Sort",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -142, 0, TABS_Y),
	Size = UDim2.fromOffset(140, 36),
	BackgroundColor3 = Ui.GLASS_LIGHT,
	AutoButtonColor = false,
	Font = Ui.FONT,
	TextScaled = false,
	TextSize = 14,
	Text = "Sort: Power  ▾",
	TextColor3 = Ui.INK,
	ZIndex = 33,
	Parent = box,
}, { Ui.corner(18) })
local sortMenu = Ui.new("Frame", {
	Name = "SortMenu",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -142, 0, TABS_Y + 40),
	Size = UDim2.fromOffset(140, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundColor3 = Ui.WHITE,
	Visible = false,
	ZIndex = 50,
	Parent = box,
}, {
	Ui.corner(14),
	Ui.padding(4),
	Ui.new("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }),
})
Ui.stroke(Ui.LINE, 1, 0).Parent = sortMenu
for i, sort in ipairs(SORTS) do
	local option = Ui.new("TextButton", {
		LayoutOrder = i,
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundColor3 = Ui.GLASS_LIGHT,
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Font = Ui.FONT,
		TextScaled = false,
		TextSize = 14,
		Text = sort.Name,
		TextColor3 = Ui.INK,
		ZIndex = 51,
		Parent = sortMenu,
	}, { Ui.corner(10) })
	option.MouseEnter:Connect(function()
		option.BackgroundTransparency = 0
	end)
	option.MouseLeave:Connect(function()
		option.BackgroundTransparency = 1
	end)
	option.Activated:Connect(function()
		Inventory.Sort = i
		sortMenu.Visible = false
		refresh(true)
	end)
end
sortButton.Activated:Connect(function()
	sortMenu.Visible = not sortMenu.Visible
end)

-- The grid ---------------------------------------------------------------------------------

local layout = Ui.new("UIGridLayout", {
	CellSize = UDim2.fromOffset(CARD_TARGET, math.floor(CARD_TARGET * PetTile.ASPECT)),
	CellPadding = UDim2.fromOffset(CARD_GAP, CARD_GAP),
	SortOrder = Enum.SortOrder.LayoutOrder,
})
local grid = Screen.scrollList(box, TOP, layout)
grid.Size = UDim2.new(0, INNER_W, 1, -TOP)
Inventory.Grid, Inventory.Layout = grid, layout -- (for the simulator)
local empty = Ui.new("TextLabel", {
	Position = UDim2.fromOffset(0, TOP + 80),
	Size = UDim2.fromOffset(INNER_W, 24),
	Font = Ui.FONT_MEDIUM,
	TextScaled = false,
	TextSize = 17,
	TextColor3 = Ui.MUTED,
	Text = "",
	Visible = false,
	ZIndex = 33,
	Parent = box,
})

-- How many columns fit in a width, and the card size for it (cards about
-- CARD_TARGET wide; never fewer than 3 or more than 10 per row)
function Inventory.columnsFor(width)
	local usable = width - 12 -- padding and the scroll bar
	local columns = math.clamp(math.floor((usable + CARD_GAP) / (CARD_TARGET + CARD_GAP)), 3, 10)
	local cell = math.floor((usable - (columns - 1) * CARD_GAP) / columns)
	return columns, cell
end

local cellWidth = CARD_TARGET -- the tiles' width for the current column count
local function fitGrid(width)
	grid.Size = UDim2.new(0, width, 1, -TOP)
	empty.Size = UDim2.fromOffset(width, 24)
	local columns, cell = Inventory.columnsFor(width)
	cellWidth = cell
	layout.CellSize = UDim2.fromOffset(cell, math.floor(cell * PetTile.ASPECT))
	Inventory.Columns = columns
end

-- Cards --------------------------------------------------------------------------------------

-- the colour that stands for a pet's rarity (or its size, for Huge/Titanic)
local function accentOf(name)
	local pet, size = Config.petInfo(name)
	return if size.Index > 1 then size.Color else Config.rarity(pet.Odds).Color
end

local cards = {} -- [name] = { Frame, Edge, Scale, Equipped }
local staggering = false -- cards grow in one after another (when the screen opens)
local shownEquipped = nil -- [name] = copies equipped when the cards were last drawn

local function label(parent, props)
	props.TextScaled = false
	props.BackgroundTransparency = props.BackgroundTransparency or 1
	props.ZIndex = props.ZIndex or 35
	props.Parent = parent
	return Ui.new("TextLabel", props)
end

-- how a card looks for its state (selected gets a dark outline)
local function paintCard(c)
	PetTile.setSelected(c.Tile, Inventory.Selected == c.Name)
end

local function card(order, name, owned, equipped)
	local tile = PetTile.new({
		Name = name,
		Width = cellWidth,
		LayoutOrder = order,
		Amount = owned,
		Equipped = equipped > 0,
		Parent = grid,
	})
	local frame = tile.Frame
	local c = { Name = name, Frame = frame, Tile = tile, Equipped = equipped > 0 }
	paintCard(c)
	cards[name] = c
	if staggering then
		Ui.appear(frame, order)
	elseif shownEquipped and (shownEquipped[name] or 0) ~= equipped then
		Ui.pop(frame, if equipped > (shownEquipped[name] or 0) then 1.1 else 0.92)
	end
	frame.Activated:Connect(function()
		Effects.play("Click", 1.2, 0.04)
		select(name)
	end)
	return c
end

-- the equipped tiles along the top (tap one for its details)
local function drawTeam(data)
	PetView.releaseAll(teamRow)
	for _, child in ipairs(teamRow:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	for slot, name in ipairs(data.Equipped) do
		if Config.petInfo(name) then
			local tile = PetTile.new({ Name = name, Width = TEAM_TILE, LayoutOrder = slot, Parent = teamRow })
			tile.Frame.Activated:Connect(function()
				Effects.play("Click", 1.2, 0.04)
				select(name)
			end)
		end
	end
	equippedTitle.Text = #data.Equipped .. "/" .. Config.maxEquipped(data) .. " Equipped"
end

-- Details (slides in on the right) ------------------------------------------------------------

local DETAIL_SHOWN = UDim2.new(1, 0, 0, TOP)
local DETAIL_HIDDEN = UDim2.new(1, 40, 0, TOP)
local detail = Ui.new("Frame", {
	Name = "Details",
	AnchorPoint = Vector2.new(1, 0),
	Position = DETAIL_HIDDEN,
	Size = UDim2.new(0, DETAIL_W, 1, -TOP),
	BackgroundColor3 = Color3.fromRGB(246, 248, 252),
	Visible = false,
	ZIndex = 36,
	Parent = box,
}, { Ui.corner(18), Ui.padding(14) })
Ui.stroke(Ui.LINE, 1, 0).Parent = detail
Inventory.Detail = detail
local closeDetail = Ui.new("TextButton", {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, 4, 0, -4),
	Size = UDim2.fromOffset(28, 28),
	BackgroundColor3 = Ui.WHITE,
	AutoButtonColor = false,
	Text = "",
	ZIndex = 40,
	Parent = detail,
}, { Ui.corner(14) })
Ui.icon("close", 10, Ui.MUTED, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), ZIndex = 41, Parent = closeDetail })
closeDetail.Activated:Connect(function()
	select(nil)
end)
local detailView = Ui.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.fromScale(0.5, 0),
	Size = UDim2.fromOffset(110, 88),
	BackgroundTransparency = 1,
	ZIndex = 37,
	Parent = detail,
})
local detailName = label(detail, {
	Position = UDim2.fromOffset(0, 88),
	Size = UDim2.new(1, 0, 0, 26),
	Font = Ui.FONT_DISPLAY,
	TextSize = 22,
	TextColor3 = Ui.INK,
	TextTruncate = Enum.TextTruncate.AtEnd,
	ZIndex = 37,
})
local detailTag = label(detail, {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 116),
	Size = UDim2.fromOffset(0, 20),
	AutomaticSize = Enum.AutomaticSize.X,
	BackgroundTransparency = 0,
	Font = Ui.FONT,
	TextSize = 11,
	TextColor3 = Ui.WHITE,
	ZIndex = 37,
})
Ui.corner(10).Parent = detailTag
Ui.new("UIPadding", { PaddingLeft = UDim.new(0, 9), PaddingRight = UDim.new(0, 9), Parent = detailTag })

-- rows: icon, name, value
local function row(parent, order, iconName, color, text)
	local r = Ui.new("Frame", {
		LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, 20),
		BackgroundColor3 = Ui.WHITE,
		ZIndex = 37,
		Parent = parent,
	}, { Ui.corner(9) })
	Ui.icon(iconName, 14, color, { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 9, 0.5, 0), ZIndex = 38, Parent = r })
	label(r, {
		Position = UDim2.fromOffset(30, 0),
		Size = UDim2.new(0.6, -30, 1, 0),
		Font = Ui.FONT_MEDIUM,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Ui.INK,
		Text = text,
		ZIndex = 38,
	})
	return label(r, {
		Name = "Value",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -9, 0, 0),
		Size = UDim2.new(0.45, 0, 1, 0),
		Font = Ui.FONT,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextColor3 = Ui.INK,
		ZIndex = 38,
	}), r
end
local rows = Ui.new("Frame", {
	Name = "Stats",
	Position = UDim2.fromOffset(0, 142),
	Size = UDim2.new(1, 0, 0, 212),
	BackgroundTransparency = 1,
	ZIndex = 37,
	Parent = detail,
}, {
	Ui.new("UIListLayout", { Padding = UDim.new(0, 1), SortOrder = Enum.SortOrder.LayoutOrder }),
})
local powerValue = row(rows, 1, "sword", Ui.INK, "Power")
local dpsValue = row(rows, 2, "bolt", Ui.DANGER, "Damage / sec")
local STAT_LOOK = {
	{ Stat = "Damage", Icon = "sword", Color = Ui.DANGER, Text = "Damage" },
	{ Stat = "Coins", Icon = "coin", Color = Ui.GOLD, Text = "Coins" },
	{ Stat = "Luck", Icon = "clover", Color = Ui.SUCCESS, Text = "Luck" },
	{ Stat = "Exp", Icon = "star", Color = Ui.PURPLE, Text = "EXP" },
	{ Stat = "Speed", Icon = "bolt", Color = Ui.BLUE, Text = "Speed" },
}
local statValues = {}
for i, look in ipairs(STAT_LOOK) do
	local value, r = row(rows, 2 + i, look.Icon, look.Color, look.Text)
	r.Name = look.Stat
	statValues[look.Stat] = value
end
local ownedValue = row(rows, 9, "paw", Ui.BLUE, "You have")
local outfitValue, outfitRow = row(rows, 10, "star", Ui.PURPLE, "Outfit")
outfitRow.Name = "Outfit"

local detailAction = Ui.button({
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, 0),
	Size = UDim2.new(1, 0, 0, 44),
	Radius = 22,
	Text = "Equip",
	TextSize = 17,
	ZIndex = 38,
	Parent = detail,
}, function()
	local name, data = Inventory.Selected, State.Data
	if not name or not data then
		return
	end
	local equipped = count(data.Equipped, name)
	if equipped > 0 then
		equipFunction:InvokeServer(name, true)
	elseif equipped < (data.Pets[name] or 0) and #data.Equipped < Config.maxEquipped(data) then
		equipFunction:InvokeServer(name, false)
	end
end, "success")
Inventory.DetailAction = detailAction
local detailSwap = Ui.new("UIScale", { Parent = detailName })

-- fills the details for a pet, in place (no rebuilding)
local shownPet = nil
local function fillDetails(name)
	local data = State.Data
	if not data or not name then
		return
	end
	if shownPet ~= name then
		shownPet = name
		PetView.releaseAll(detailView)
		for _, child in ipairs(detailView:GetChildren()) do
			if child:IsA("GuiObject") then
				child:Destroy()
			end
		end
		local view = PetView.take(name)
		view.Size = UDim2.fromScale(1, 1)
		view.ZIndex = 38
		view.Parent = detailView
		if not Ui.reduced() then
			detailSwap.Scale = 0.9
			TweenService:Create(detailSwap, EASE, { Scale = 1 }):Play()
		end
	end
	local pet, size = Config.petInfo(name)
	local rarity = Config.rarity(pet.Odds)
	detailName.Text = Config.displayName(name)
	local aura = Config.petAura(name)
	detailTag.Text = string.upper(rarity.Name) .. (if size.Index > 1 then "  ·  " .. string.upper(size.Name) else "")
		.. (if aura then "  ·  " .. string.upper(aura.Name) else "")
	detailTag.BackgroundColor3 = accentOf(name)
	local outfit = Config.outfitOf(name)
	outfitValue.Text = if outfit then outfit.Name else "-"
	powerValue.Text = Config.formatNumber(Config.petPower(name))
	dpsValue.Text = Config.formatNumber(Config.petDps(data, name))
	for _, look in ipairs(STAT_LOOK) do
		local value = Config.petStat(name, look.Stat)
		statValues[look.Stat].Text = Config.formatStat(value)
		statValues[look.Stat].TextColor3 = if value > 1.001 then Ui.INK else Ui.MUTED
	end
	local owned, equipped = data.Pets[name] or 0, count(data.Equipped, name)
	ownedValue.Text = Config.formatNumber(owned) .. (if equipped > 0 then "  ·  " .. equipped .. " on" else "")
	local full = #data.Equipped >= Config.maxEquipped(data)
	if equipped > 0 then
		Ui.setText(detailAction, "Unequip")
		Ui.setStyle(detailAction, "danger")
	elseif full then
		Ui.setText(detailAction, "Team full")
		Ui.setStyle(detailAction, "disabled")
	else
		Ui.setText(detailAction, "Equip")
		Ui.setStyle(detailAction, "success")
	end
end

-- selects a pet (or nil to close the details): the grid narrows to make
-- room and the panel slides in; nothing is rebuilt
function select(name)
	local data = State.Data
	if name and (not data or (data.Pets[name] or 0) <= 0) then
		name = nil
	end
	local before = Inventory.Selected
	Inventory.Selected = name
	for _, c in pairs(cards) do
		if c.Name == before or c.Name == name then
			paintCard(c)
		end
	end
	if name then
		fillDetails(name)
		if not detail.Visible then
			detail.Visible = true
			detail.Position = if Ui.reduced() then DETAIL_SHOWN else DETAIL_HIDDEN
			TweenService:Create(detail, EASE, { Position = DETAIL_SHOWN }):Play()
			fitGrid(INNER_W - DETAIL_W - GAP)
			rebuild() -- the tiles get the narrower size
		end
	elseif detail.Visible then
		detail.Visible = false
		shownPet = nil
		fitGrid(INNER_W)
		rebuild()
	end
end
Inventory.select = select
Inventory.showDetails = select

-- Building the grid ------------------------------------------------------------------------------

local lastSignature = nil

-- redraws the tiles (after the grid changed width), without the grow-in
function rebuild()
	if modal.Visible then
		lastSignature = nil
		refresh(false)
	end
end

function refresh(force)
	local data = State.Data
	if not data or not modal.Visible then
		return
	end
	-- only rebuild when something shown here changed
	local parts = { Inventory.Filter, Inventory.Sort, #data.Equipped, Config.maxEquipped(data) }
	for name, n in pairs(data.Pets) do
		table.insert(parts, name .. "=" .. n .. ":" .. count(data.Equipped, name))
	end
	table.sort(parts, function(a, b) return tostring(a) < tostring(b) end)
	local signature = table.concat(parts, ",")
	if signature == lastSignature and not force then
		if Inventory.Selected then
			fillDetails(Inventory.Selected)
		end
		return
	end
	lastSignature = signature

	for i, tab in ipairs(tabButtons) do
		local on = i == Inventory.Filter
		tab.BackgroundTransparency = if on then 0 else 1
		tab.TextColor3 = if on then Ui.INK else Ui.MUTED
	end
	sortButton.Text = "Sort: " .. (SORTS[Inventory.Sort] or SORTS[1]).Name .. "  ▾"

	PetView.releaseAll(grid)
	for _, child in ipairs(grid:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	cards = {}
	local filter = FILTERS[Inventory.Filter] or FILTERS[1]
	local list, total = {}, 0
	for name, n in pairs(data.Pets) do
		if n > 0 and Config.petInfo(name) then
			total += n
			if filter.Keep(name, count(data.Equipped, name)) then
				table.insert(list, name)
			end
		end
	end
	local sort = SORTS[Inventory.Sort] or SORTS[1]
	Inventory.Sort = table.find(SORTS, sort)
	table.sort(list, function(a, b)
		return sort.Before(a, b, data)
	end)
	staggering = force == true
	for i, name in ipairs(list) do
		card(i, name, data.Pets[name], count(data.Equipped, name))
	end
	staggering = false
	shownEquipped = {}
	for _, name in ipairs(data.Equipped) do
		shownEquipped[name] = (shownEquipped[name] or 0) + 1
	end
	empty.Visible = #list == 0
	empty.Text = if total == 0 then FILTERS[1].Empty else filter.Empty
	hint.Text = Config.formatNumber(total) .. " pets"
	drawTeam(data)
	-- keep the details current (or close them if that pet is gone)
	select(Inventory.Selected)
end

function Inventory.open()
	Screen.open(modal)
	fitGrid(if Inventory.Selected then INNER_W - DETAIL_W - GAP else INNER_W)
	refresh(true)
end

State.watch(function()
	refresh(false)
end)

return Inventory
