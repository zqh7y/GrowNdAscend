-- The Inventory: the pets you own. Each card shows the pet in 3D, its size
-- and rarity, its power, how many you have and how many are equipped, with
-- equip / unequip buttons. Filter by All, Equipped or a size, and sort by
-- power, rarity, amount or name. (Every animal there is, found or not, is in
-- the Index instead.)
local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local PetView = require(script.Parent.PetView)
local Screen = require(script.Parent.Screen)
local State = require(script.Parent.State)
local Ui = require(script.Parent.Ui)

local Inventory = {}

local equipFunction = State.remote("Equip")
local equipBestFunction = State.remote("EquipBest")

local modal, box = Screen.modal(860, 620, "Inventory")
local title = Screen.title(box, "Inventory")
local hint = Screen.subtitle(box, "")
Ui.button({
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -40, 0, 8),
	Size = UDim2.fromOffset(150, 40),
	Radius = 14,
	Text = "EQUIP BEST",
	Icon = "star",
	TextSize = 14,
	ZIndex = 33,
	Parent = box,
}, function()
	equipBestFunction:InvokeServer()
end, "primary")

-- Filters and sorting ----------------------------------------------------------------------

local FILTERS = {
	{ Name = "All", Keep = function() return true end },
	{ Name = "Equipped", Keep = function(_, equipped) return equipped > 0 end },
	{ Name = "Normal", Keep = function(name) return select(2, Config.petInfo(name)).Index == 1 end },
	{ Name = "Huge", Keep = function(name) return select(2, Config.petInfo(name)).Index == 2 end },
	{ Name = "Titanic", Keep = function(name) return select(2, Config.petInfo(name)).Index == 3 end },
}
local SORTS = {
	{ Name = "Power", Before = function(a, b) return Config.petPower(a) > Config.petPower(b) end },
	{ Name = "Rarity", Before = function(a, b)
		local pa, pb = Config.petInfo(a), Config.petInfo(b)
		if pa.Odds ~= pb.Odds then return pa.Odds > pb.Odds end
		return Config.petPower(a) > Config.petPower(b)
	end },
	{ Name = "Amount", Before = function(a, b, data)
		if data.Pets[a] ~= data.Pets[b] then return data.Pets[a] > data.Pets[b] end
		return Config.petPower(a) > Config.petPower(b)
	end },
	{ Name = "Name", Before = function(a, b) return a < b end },
}
Inventory.Filter = 1
Inventory.Sort = 1
local refresh

local toolbar = Ui.new("Frame", {
	Position = UDim2.fromOffset(0, 56),
	Size = UDim2.new(1, 0, 0, 38),
	BackgroundTransparency = 1,
	ZIndex = 32,
	Parent = box,
})
Ui.new("Frame", {
	Size = UDim2.new(1, -170, 1, 0),
	BackgroundTransparency = 1,
	Parent = toolbar,
}, {
	Ui.new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}),
})
local chipRow = toolbar:FindFirstChildOfClass("Frame")
local chips = {}
for i, filter in ipairs(FILTERS) do
	chips[i] = Ui.button({
		LayoutOrder = i,
		Size = UDim2.fromOffset(if filter.Name == "Equipped" then 104 else 86, 38),
		Radius = 19,
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
	Size = UDim2.fromOffset(170, 38),
	Radius = 19,
	Icon = "sort",
	Text = "Power",
	TextSize = 16,
	ZIndex = 33,
	Parent = toolbar,
}, function()
	Inventory.Sort = Inventory.Sort % #SORTS + 1
	refresh(true)
end, "glass")

local grid = Screen.scrollList(box, 106, Ui.new("UIGridLayout", {
	CellSize = UDim2.fromOffset(170, 214),
	CellPadding = UDim2.fromOffset(12, 12),
	SortOrder = Enum.SortOrder.LayoutOrder,
}))
local empty = Ui.new("TextLabel", {
	Position = UDim2.fromOffset(0, 150),
	Size = UDim2.new(1, 0, 0, 24),
	Font = Ui.FONT_MEDIUM,
	TextScaled = false,
	TextSize = 16,
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

local function card(order, name, owned, equipped, data)
	local pet, size = Config.petInfo(name)
	local rarity = Config.rarity(pet.Odds)
	local accent = if size.Index > 1 then size.Color else rarity.Color
	local frame = Ui.card({
		LayoutOrder = order,
		BackgroundColor3 = if equipped > 0 then Color3.fromRGB(14, 40, 40) else Ui.GLASS_LIGHT,
		ZIndex = 32,
		Parent = grid,
	}, if equipped > 0 then Ui.SUCCESS else accent, { Ui.padding(10) })
	if size.Index > 1 then
		Ui.brackets(frame, accent, 10, 34)
	end

	-- the pet itself, standing on a holo pad in its rarity colour
	Ui.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0, 72),
		Size = UDim2.fromOffset(82, 16),
		BackgroundColor3 = accent,
		BackgroundTransparency = 0.75,
		ZIndex = 32,
		Parent = frame,
	}, { Ui.corner(0.5), Ui.stroke(accent, 1, 0.3) })
	local view = PetView.take(name)
	view.AnchorPoint = Vector2.new(0.5, 0)
	view.Position = UDim2.new(0.5, 0, 0, -4)
	view.Size = UDim2.fromOffset(96, 90)
	view.ZIndex = 33
	view.Parent = frame

	if equipped > 0 then
		Ui.new("TextLabel", {
			Size = UDim2.fromOffset(70, 16),
			BackgroundTransparency = 0,
			BackgroundColor3 = Ui.SUCCESS,
			Font = Ui.FONT_TITLE,
			TextScaled = false,
			TextSize = 7,
			TextColor3 = Ui.INK,
			Text = "EQUIPPED" .. (if equipped > 1 then " x" .. equipped else ""),
			ZIndex = 34,
			Parent = frame,
		}, { Ui.corner(3) })
	end
	Ui.new("TextLabel", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 0),
		Size = UDim2.fromOffset(44, 18),
		BackgroundTransparency = 0.2,
		BackgroundColor3 = Ui.GLASS,
		TextScaled = false,
		TextSize = 12,
		Text = "x" .. Config.formatNumber(owned),
		ZIndex = 34,
		Parent = frame,
	}, { Ui.corner(3), Ui.stroke(Ui.LINE, 1, 0.4) })

	local function line(y, textSize, font, text, color)
		return Ui.new("TextLabel", {
			Position = UDim2.fromOffset(0, y),
			Size = UDim2.new(1, 0, 0, textSize + 2),
			Font = font,
			TextScaled = false,
			TextSize = textSize,
			Text = text,
			TextColor3 = color,
			TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = 33,
			Parent = frame,
		})
	end
	line(88, 15, Ui.FONT, name, if size.Index > 1 then size.Color else Ui.TEXT)
	line(106, 8, Ui.FONT_TITLE, string.upper(rarity.Name) .. " · " .. string.upper(size.Name), rarity.Color)
	line(121, 12, Ui.FONT, Config.formatNumber(Config.petPower(name)) .. " PWR", Ui.CYAN)
	line(137, 11, Ui.FONT_MEDIUM, Config.formatOdds(pet.Odds) .. "  ·  " .. Config.AREAS[pet.World].Name, Ui.MUTED)

	-- equip one more / take one off
	local full = #data.Equipped >= Config.maxEquipped(data)
	local canAdd = equipped < owned and not full
	Ui.button({
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(if equipped > 0 then 0.62 else 1, if equipped > 0 then -3 else 0, 0, 32),
		Radius = 12,
		Text = if equipped > 0 then "+1" else "EQUIP",
		TextSize = 14,
		ZIndex = 33,
		Parent = frame,
	}, function()
		equipFunction:InvokeServer(name, false)
	end, if canAdd then "success" else "disabled")
	if equipped > 0 then
		Ui.button({
			AnchorPoint = Vector2.new(1, 1),
			Position = UDim2.new(1, 0, 1, 0),
			Size = UDim2.new(0.38, -3, 0, 32),
			Radius = 12,
			Text = "−1",
			TextSize = 14,
			ZIndex = 33,
			Parent = frame,
		}, function()
			equipFunction:InvokeServer(name, true)
		end, "danger")
	end
end

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
	Ui.setText(sortButton, "Sort: " .. SORTS[Inventory.Sort].Name)

	PetView.releaseAll(grid)
	for _, child in ipairs(grid:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	local filter = FILTERS[Inventory.Filter]
	local list, total = {}, 0
	for name, n in pairs(data.Pets) do
		if n > 0 and Config.petInfo(name) then
			total += n
			if filter.Keep(name, count(data.Equipped, name)) then
				table.insert(list, name)
			end
		end
	end
	local sort = SORTS[Inventory.Sort]
	table.sort(list, function(a, b)
		return sort.Before(a, b, data)
	end)
	for i, name in ipairs(list) do
		card(i, name, data.Pets[name], count(data.Equipped, name), data)
	end
	empty.Visible = #list == 0
	empty.Text = if total == 0 then "No pets yet. Roll to hatch your first one!" else "No " .. string.lower(filter.Name) .. " pets."
	title.Text = "Inventory  ·  " .. Config.formatNumber(total) .. " pets"
	hint.Text = "Equipped " .. #data.Equipped .. "/" .. Config.maxEquipped(data)
		.. "  ·  team damage " .. Config.formatNumber(Config.teamDamage(data)) .. "/s"
end

function Inventory.open()
	Screen.open(modal)
	refresh(true)
end

State.watch(function()
	refresh(false)
end)

return Inventory
