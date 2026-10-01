-- The Inventory: the pets you own, made simple. Each card shows just what
-- matters at a glance: a big picture of the pet, its name, its power (a
-- sword and a number), its rarity as a coloured card edge and top stripe
-- (gold for Huge, pink for Titanic), how many you have, whether it's
-- equipped (green card with a check) and ONE button: Equip or Unequip.
-- Tap a card to open its details on the right: everything else (rarity,
-- size, power, how many you have and its five multipliers with plain words
-- and icons). Filters are four simple tabs; the sort button says what it
-- does ("Strongest first").
local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local PetView = require(script.Parent.PetView)
local Screen = require(script.Parent.Screen)
local State = require(script.Parent.State)
local Ui = require(script.Parent.Ui)

local Inventory = {}

local equipFunction = State.remote("Equip")
local equipBestFunction = State.remote("EquipBest")

local DETAIL_W = 270
local modal, box = Screen.modal(900, 620, "Inventory")
local title = Screen.title(box, "My Pets")
local hint = Screen.subtitle(box, "")
Ui.button({
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -40, 0, 6),
	Size = UDim2.fromOffset(150, 40),
	Radius = 20,
	Text = "Equip Best",
	Icon = "star",
	TextSize = 15,
	ZIndex = 33,
	Parent = box,
}, function()
	equipBestFunction:InvokeServer()
end, "primary")

-- Filters and sorting ----------------------------------------------------------------------

local FILTERS = {
	{ Name = "All", Empty = "No pets yet. Roll to hatch your first one!", Keep = function() return true end },
	{ Name = "Equipped", Empty = "Nothing equipped. Tap Equip on a pet!", Keep = function(_, equipped) return equipped > 0 end },
	{ Name = "Huge", Empty = "No Huge pets yet.", Keep = function(name) return select(2, Config.petInfo(name)).Index == 2 end },
	{ Name = "Titanic", Empty = "No Titanic pets yet.", Keep = function(name) return select(2, Config.petInfo(name)).Index == 3 end },
}
local SORTS = {
	{ Name = "Strongest first", Before = function(a, b) return Config.petPower(a) > Config.petPower(b) end },
	{ Name = "Rarest first", Before = function(a, b)
		local pa, pb = Config.petInfo(a), Config.petInfo(b)
		if pa.Odds ~= pb.Odds then return pa.Odds > pb.Odds end
		return Config.petPower(a) > Config.petPower(b)
	end },
	{ Name = "Most owned", Before = function(a, b, data)
		if data.Pets[a] ~= data.Pets[b] then return data.Pets[a] > data.Pets[b] end
		return Config.petPower(a) > Config.petPower(b)
	end },
	{ Name = "A to Z", Before = function(a, b) return a < b end },
}
Inventory.FILTERS, Inventory.SORTS = FILTERS, SORTS
Inventory.Filter = 1
Inventory.Sort = 1
Inventory.Selected = nil -- the pet whose details are open
local refresh, showDetails

local LIST_W = 900 - 48 - DETAIL_W - 16
local toolbar = Ui.new("Frame", {
	Position = UDim2.fromOffset(0, 56),
	Size = UDim2.fromOffset(LIST_W, 40),
	BackgroundTransparency = 1,
	ZIndex = 32,
	Parent = box,
})
local chipRow = Ui.new("Frame", {
	Size = UDim2.new(1, -176, 1, 0),
	BackgroundTransparency = 1,
	Parent = toolbar,
}, {
	Ui.new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}),
})
local chips = {}
for i, filter in ipairs(FILTERS) do
	chips[i] = Ui.button({
		LayoutOrder = i,
		Size = UDim2.fromOffset(if filter.Name == "Equipped" then 108 else 84, 40),
		Radius = 20,
		Text = filter.Name,
		TextSize = 16,
		ZIndex = 33,
		Parent = chipRow,
	}, function()
		Inventory.Filter = i
		refresh(true)
	end, "glass")
end
local sortButton = Ui.button({
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, 0, 0, 0),
	Size = UDim2.fromOffset(170, 40),
	Radius = 20,
	Icon = "sort",
	Text = "Strongest first",
	TextSize = 14,
	ZIndex = 33,
	Parent = toolbar,
}, function()
	Inventory.Sort = Inventory.Sort % #SORTS + 1
	refresh(true)
end, "glass")

local grid = Screen.scrollList(box, 108, Ui.new("UIGridLayout", {
	CellSize = UDim2.fromOffset(170, 228),
	CellPadding = UDim2.fromOffset(12, 12),
	SortOrder = Enum.SortOrder.LayoutOrder,
}))
grid.Size = UDim2.new(0, LIST_W, 1, -108)
Inventory.Grid = grid -- (for the simulator)
local empty = Ui.new("TextLabel", {
	Position = UDim2.fromOffset(0, 170),
	Size = UDim2.fromOffset(LIST_W, 24),
	Font = Ui.FONT_MEDIUM,
	TextScaled = false,
	TextSize = 17,
	TextColor3 = Ui.MUTED,
	Text = "",
	Visible = false,
	ZIndex = 33,
	Parent = box,
})

-- Cards --------------------------------------------------------------------------------------

local function count(list, name)
	local n = 0
	for _, v in ipairs(list) do
		if v == name then
			n += 1
		end
	end
	return n
end

-- the colour that stands for a pet's rarity (or its size, for Huge/Titanic)
local function accentOf(name)
	local pet, size = Config.petInfo(name)
	return if size.Index > 1 then size.Color else Config.rarity(pet.Odds).Color
end

local staggering = false -- cards grow in one after another (when the screen opens)
local shownEquipped = nil -- [name] = copies equipped when the cards were last drawn

local function label(parent, props)
	props.TextScaled = false
	props.BackgroundTransparency = props.BackgroundTransparency or 1
	props.ZIndex = props.ZIndex or 34
	props.Parent = parent
	return Ui.new("TextLabel", props)
end

local function equip(name, unequip)
	equipFunction:InvokeServer(name, unequip)
end

local function card(order, name, owned, equipped, data)
	local _, size = Config.petInfo(name)
	local accent = accentOf(name)
	local isEquipped = equipped > 0
	local cardColor = if isEquipped then Color3.fromRGB(232, 249, 239) else Ui.WHITE
	-- the whole card is a button (tap = details)
	local frame = Ui.new("TextButton", {
		Name = name,
		LayoutOrder = order,
		BackgroundColor3 = cardColor,
		AutoButtonColor = false,
		Text = "",
		ZIndex = 32,
		Parent = grid,
	}, { Ui.corner(18) })
	local edge = Ui.stroke(if isEquipped then Ui.SUCCESS else accent:Lerp(Ui.WHITE, 0.25), if isEquipped or size.Index > 1 then 3 else 2, 0)
	edge.Parent = frame
	if staggering then
		Ui.appear(frame, order)
	elseif shownEquipped and (shownEquipped[name] or 0) ~= equipped then
		-- this pet was just equipped or unequipped
		Ui.pop(frame, if equipped > (shownEquipped[name] or 0) then 1.08 else 0.94)
	end
	frame.Activated:Connect(function()
		showDetails(name)
	end)
	-- rarity stripe along the top
	Ui.new("Frame", {
		Size = UDim2.new(1, 0, 0, 10),
		BackgroundColor3 = accent,
		ZIndex = 33,
		Parent = frame,
	}, { Ui.corner(18) })
	Ui.new("Frame", {
		Position = UDim2.fromOffset(0, 5),
		Size = UDim2.new(1, 0, 0, 6),
		BackgroundColor3 = cardColor,
		ZIndex = 33,
		Parent = frame,
	})
	-- the pet, big
	local view = PetView.take(name)
	view.AnchorPoint = Vector2.new(0.5, 0)
	view.Position = UDim2.new(0.5, 0, 0, 16)
	view.Size = UDim2.fromOffset(120, 104)
	view.ZIndex = 34
	view.Parent = frame
	-- equipped check (top left) and how many you have (top right)
	if isEquipped then
		local tick = label(frame, {
			Name = "Equipped",
			Position = UDim2.fromOffset(8, 16),
			Size = UDim2.fromOffset(if equipped > 1 then 40 else 26, 26),
			BackgroundTransparency = 0,
			BackgroundColor3 = Ui.SUCCESS,
			Font = Ui.FONT,
			TextSize = 14,
			TextColor3 = Ui.WHITE,
			Text = if equipped > 1 then "✓" .. equipped else "✓",
			ZIndex = 35,
		})
		Ui.corner(13).Parent = tick
	end
	if owned > 1 then
		local amount = label(frame, {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -8, 0, 16),
			Size = UDim2.fromOffset(42, 24),
			BackgroundTransparency = 0,
			BackgroundColor3 = Ui.GLASS_LIGHT,
			Font = Ui.FONT,
			TextSize = 13,
			TextColor3 = Ui.INK,
			Text = "x" .. Config.formatNumber(owned),
			ZIndex = 35,
		})
		Ui.corner(12).Parent = amount
	end
	-- name and power
	label(frame, {
		Name = "PetName",
		Position = UDim2.fromOffset(8, 122),
		Size = UDim2.new(1, -16, 0, 22),
		Font = Ui.FONT,
		TextSize = 17,
		TextColor3 = Ui.INK,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Text = name,
	})
	local power = Ui.new("Frame", {
		Name = "Power",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 148),
		Size = UDim2.fromOffset(0, 22),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		ZIndex = 34,
		Parent = frame,
	}, {
		Ui.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	Ui.icon("sword", 16, Ui.DANGER, { LayoutOrder = 0, ZIndex = 35, Parent = power })
	label(power, {
		LayoutOrder = 1,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 22),
		Font = Ui.FONT_DISPLAY,
		TextSize = 19,
		TextColor3 = Ui.INK,
		Text = Config.formatNumber(Config.petPower(name)),
		ZIndex = 35,
	})
	-- ONE clear action: Equip, or Unequip
	local full = #data.Equipped >= Config.maxEquipped(data)
	local canAdd = equipped < owned and not full
	local action = Ui.button({
		Name = "Action",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -10),
		Size = UDim2.new(1, -20, 0, 38),
		Radius = 19,
		Text = if isEquipped then "Unequip" else (if full then "Team full" else "Equip"),
		TextSize = 16,
		ZIndex = 35,
		Parent = frame,
	}, function()
		if isEquipped then
			equip(name, true)
		elseif canAdd then
			equip(name, false)
		end
	end, if isEquipped then "danger" elseif canAdd then "success" else "disabled")
	return frame, action
end

-- Details (right side) -----------------------------------------------------------------------

local detail = Ui.new("Frame", {
	Name = "Details",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, 0, 0, 56),
	Size = UDim2.new(0, DETAIL_W, 1, -56),
	BackgroundColor3 = Color3.fromRGB(246, 248, 252),
	ZIndex = 32,
	Parent = box,
}, { Ui.corner(18), Ui.padding(16) })
Ui.stroke(Ui.LINE, 1, 0).Parent = detail
Inventory.Detail = detail
local detailHint = label(detail, {
	Size = UDim2.new(1, 0, 1, 0),
	Font = Ui.FONT_MEDIUM,
	TextSize = 15,
	TextWrapped = true,
	TextColor3 = Ui.MUTED,
	Text = "Tap a pet to see everything about it",
	ZIndex = 33,
})
local detailBody = Ui.new("Frame", {
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	Visible = false,
	ZIndex = 33,
	Parent = detail,
})
local detailScale = Ui.new("UIScale", { Parent = detailBody })
local detailView = Ui.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.fromScale(0.5, 0),
	Size = UDim2.fromOffset(150, 130),
	BackgroundTransparency = 1,
	ZIndex = 34,
	Parent = detailBody,
})
local detailName = label(detailBody, {
	Position = UDim2.fromOffset(0, 132),
	Size = UDim2.new(1, 0, 0, 28),
	Font = Ui.FONT_DISPLAY,
	TextSize = 24,
	TextColor3 = Ui.INK,
	TextTruncate = Enum.TextTruncate.AtEnd,
})
local detailTag = label(detailBody, {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 162),
	Size = UDim2.fromOffset(0, 22),
	AutomaticSize = Enum.AutomaticSize.X,
	BackgroundTransparency = 0,
	Font = Ui.FONT,
	TextSize = 12,
	TextColor3 = Ui.WHITE,
})
Ui.corner(11).Parent = detailTag
Ui.new("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), Parent = detailTag })
local detailInfo = label(detailBody, {
	Position = UDim2.fromOffset(0, 188),
	Size = UDim2.new(1, 0, 0, 18),
	Font = Ui.FONT_MEDIUM,
	TextSize = 13,
	TextColor3 = Ui.MUTED,
})
-- its five multipliers in plain words
local statList = Ui.new("Frame", {
	Name = "Stats",
	Position = UDim2.fromOffset(0, 214),
	Size = UDim2.new(1, 0, 0, 160),
	BackgroundTransparency = 1,
	ZIndex = 34,
	Parent = detailBody,
}, {
	Ui.new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }),
})
local STAT_LOOK = {
	{ Stat = "Damage", Icon = "sword", Color = Ui.DANGER, Text = "Damage" },
	{ Stat = "Coins", Icon = "coin", Color = Ui.GOLD, Text = "Coins" },
	{ Stat = "Luck", Icon = "clover", Color = Ui.SUCCESS, Text = "Luck" },
	{ Stat = "Exp", Icon = "star", Color = Ui.PURPLE, Text = "EXP" },
	{ Stat = "Speed", Icon = "bolt", Color = Ui.BLUE, Text = "Speed" },
}
local statValues = {}
for i, look in ipairs(STAT_LOOK) do
	local row = Ui.new("Frame", {
		Name = look.Stat,
		LayoutOrder = i,
		Size = UDim2.new(1, 0, 0, 28),
		BackgroundColor3 = Ui.WHITE,
		ZIndex = 34,
		Parent = statList,
	}, { Ui.corner(10) })
	Ui.icon(look.Icon, 16, look.Color, { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 10, 0.5, 0), ZIndex = 35, Parent = row })
	label(row, {
		Position = UDim2.fromOffset(34, 0),
		Size = UDim2.new(0.6, -34, 1, 0),
		Font = Ui.FONT_MEDIUM,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Ui.INK,
		Text = look.Text,
		ZIndex = 35,
	})
	statValues[look.Stat] = label(row, {
		Name = "Value",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -10, 0, 0),
		Size = UDim2.new(0.4, 0, 1, 0),
		Font = Ui.FONT,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextColor3 = Ui.INK,
		ZIndex = 35,
	})
end
local detailAction
detailAction = Ui.button({
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, 0),
	Size = UDim2.new(1, 0, 0, 46),
	Radius = 23,
	Text = "Equip",
	TextSize = 18,
	ZIndex = 35,
	Parent = detailBody,
}, function()
	local name, data = Inventory.Selected, State.Data
	if not name or not data then
		return
	end
	local equipped = count(data.Equipped, name)
	if equipped > 0 then
		equip(name, true)
	elseif equipped < (data.Pets[name] or 0) and #data.Equipped < Config.maxEquipped(data) then
		equip(name, false)
	end
end, "success")

function showDetails(name)
	local data = State.Data
	if not data or not name or not data.Pets[name] or data.Pets[name] <= 0 then
		Inventory.Selected = nil
		detailBody.Visible = false
		detailHint.Visible = true
		return
	end
	local changed = Inventory.Selected ~= name
	Inventory.Selected = name
	detailHint.Visible = false
	detailBody.Visible = true
	if changed then
		if not Ui.reduced() then
			detailScale.Scale = 0.94
			game:GetService("TweenService"):Create(detailScale, TweenInfo.new(0.25, Enum.EasingStyle.Quint), { Scale = 1 }):Play()
		end
		PetView.releaseAll(detailView)
		for _, child in ipairs(detailView:GetChildren()) do
			if child:IsA("GuiObject") then
				child:Destroy()
			end
		end
		local view = PetView.take(name)
		view.Size = UDim2.fromScale(1, 1)
		view.ZIndex = 35
		view.Parent = detailView
	end
	local pet, size = Config.petInfo(name)
	local rarity = Config.rarity(pet.Odds)
	detailName.Text = name
	detailTag.Text = string.upper(rarity.Name) .. (if size.Index > 1 then "  ·  " .. string.upper(size.Name) else "")
	detailTag.BackgroundColor3 = accentOf(name)
	detailInfo.Text = Config.formatNumber(Config.petPower(name)) .. " power  ·  you have " .. Config.formatNumber(data.Pets[name])
	for _, look in ipairs(STAT_LOOK) do
		local value = Config.petStat(name, look.Stat)
		statValues[look.Stat].Text = Config.formatStat(value)
		statValues[look.Stat].TextColor3 = if value > 1.001 then Ui.INK else Ui.MUTED
	end
	local equipped = count(data.Equipped, name)
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
Inventory.showDetails = showDetails

local lastSignature = nil

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
		return
	end
	lastSignature = signature

	for i, chip in ipairs(chips) do
		Ui.setStyle(chip, if i == Inventory.Filter then "blue" else "glass")
	end
	Ui.setText(sortButton, SORTS[Inventory.Sort].Name)

	PetView.releaseAll(grid)
	for _, child in ipairs(grid:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
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
	table.sort(list, function(a, b)
		return sort.Before(a, b, data)
	end)
	staggering = force == true
	for i, name in ipairs(list) do
		card(i, name, data.Pets[name], count(data.Equipped, name), data)
	end
	staggering = false
	shownEquipped = {}
	for _, name in ipairs(data.Equipped) do
		shownEquipped[name] = (shownEquipped[name] or 0) + 1
	end
	empty.Visible = #list == 0
	empty.Text = if total == 0 then FILTERS[1].Empty else filter.Empty
	title.Text = "My Pets"
	hint.Text = "Team " .. #data.Equipped .. "/" .. Config.maxEquipped(data) .. "  ·  " .. Config.formatNumber(total) .. " pets"
	-- keep the details current (or close them if that pet is gone)
	showDetails(Inventory.Selected)
end

function Inventory.open()
	Screen.open(modal)
	refresh(true)
end

State.watch(function()
	refresh(false)
end)

return Inventory
