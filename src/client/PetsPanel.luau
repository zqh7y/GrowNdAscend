-- The Pets panel: every pet you own (every size), strongest first, with
-- equip buttons and Equip Best; pets you haven't found yet show as "???"
-- with their odds, as something to chase.
local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local Ui = require(script.Parent.Ui)
local Screen = require(script.Parent.Screen)
local State = require(script.Parent.State)

local PetsPanel = {}

local equipFunction = State.remote("Equip")
local equipBestFunction = State.remote("EquipBest")

local modal, box = Screen.modal(760, 580)
local title = Screen.title(box, "Pets")
local hint = Screen.subtitle(box, "")
Ui.button({
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -52, 0, 0),
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

local grid = Screen.scrollList(box, 70, Ui.new("UIGridLayout", {
	CellSize = UDim2.fromOffset(160, 178),
	CellPadding = UDim2.fromOffset(12, 12),
	SortOrder = Enum.SortOrder.LayoutOrder,
}))

local function count(list, name)
	local n = 0
	for _, v in ipairs(list) do
		if v == name then
			n += 1
		end
	end
	return n
end

local function cell(order, name, owned, equipped, data)
	local pet, size = Config.petInfo(name)
	local rarity = Config.rarity(pet.Odds)
	local found = owned > 0
	local frame = Ui.new("Frame", {
		LayoutOrder = order,
		BackgroundColor3 = if equipped > 0 then Color3.fromRGB(60, 55, 110) else Ui.GLASS_LIGHT,
		BackgroundTransparency = 0.25,
		ZIndex = 32,
		Parent = grid,
	}, { Ui.corner(16), Ui.padding(10) })
	Ui.stroke(if size.Index > 1 then size.Color else rarity.Color, if size.Index > 1 then 2.5 else 1.5, if found then 0.2 else 0.7).Parent = frame

	-- the pet's colour in a circle, ringed in its size colour
	local swatch = Ui.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 0),
		Size = UDim2.fromOffset(40, 40),
		BackgroundColor3 = if found then pet.Color else Color3.fromRGB(70, 75, 100),
		ZIndex = 33,
		Parent = frame,
	}, { Ui.corner(0.5) })
	Ui.stroke(if size.Index > 1 then size.Color else Color3.new(1, 1, 1), 1 + size.Index * 1.5, if found then 0 else 0.6).Parent = swatch
	if equipped > 0 then
		Ui.new("TextLabel", {
			AnchorPoint = Vector2.new(0, 0),
			Position = UDim2.fromOffset(0, 0),
			Size = UDim2.fromOffset(34, 18),
			BackgroundTransparency = 0,
			BackgroundColor3 = Ui.SUCCESS,
			TextScaled = false,
			TextSize = 12,
			Text = "x" .. equipped,
			ZIndex = 34,
			Parent = frame,
		}, { Ui.corner(9) })
	end
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
	line(44, 16, Ui.FONT, if found then name else "???", if not found then Ui.MUTED elseif size.Index > 1 then size.Color else Ui.TEXT)
	line(64, 11, Ui.FONT, rarity.Name:upper(), rarity.Color)
	line(78, 12, Ui.FONT_MEDIUM, Config.formatOdds(pet.Odds), Ui.MUTED)
	if not found then
		line(100, 12, Ui.FONT_MEDIUM, "Not found yet", Ui.MUTED)
		return
	end
	line(94, 12, Ui.FONT, Config.formatNumber(Config.petPower(name)) .. " power  ·  x" .. Config.formatNumber(owned), Ui.SUCCESS)

	-- equip one more / take one off
	local full = #data.Equipped >= Config.maxEquipped(data)
	local canAdd = equipped < owned and not full
	Ui.button({
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(if equipped > 0 then 0.62 else 1, if equipped > 0 then -3 else 0, 0, 34),
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
			Size = UDim2.new(0.38, -3, 0, 34),
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

local function refresh()
	local data = State.Data
	if not data or not modal.Visible then
		return
	end
	for _, child in ipairs(grid:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	-- owned pets (every size), strongest first
	local owned = {}
	local found = {}
	for name, n in pairs(data.Pets) do
		local pet = Config.petInfo(name)
		if pet then
			found[pet.Name] = true
			if n > 0 then
				table.insert(owned, name)
			end
		end
	end
	table.sort(owned, function(a, b)
		return Config.petPower(a) > Config.petPower(b)
	end)
	for i, name in ipairs(owned) do
		cell(i, name, data.Pets[name], count(data.Equipped, name), data)
	end
	-- then the ones still to find, most common first
	local missing = 0
	for _, pet in ipairs(Config.PETS) do
		if not found[pet.Name] then
			missing += 1
			cell(1000 + pet.Index, pet.Name, 0, 0, data)
		end
	end
	title.Text = "Pets  ·  " .. (#Config.PETS - missing) .. "/" .. #Config.PETS .. " found"
	hint.Text = "Equipped " .. #data.Equipped .. "/" .. Config.maxEquipped(data)
		.. "  ·  team damage " .. Config.formatNumber(Config.teamDamage(data)) .. "/s"
end

function PetsPanel.open()
	Screen.open(modal)
	refresh()
end

State.watch(refresh)

return PetsPanel
