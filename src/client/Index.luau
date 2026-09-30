-- The Animal Index: all 70 animals there are (Huge and Titanic versions
-- don't count separately). Animals you've hatched show in full colour with
-- their name; the rest are dark silhouettes marked "???", with their rarity,
-- odds and the world they hatch in, so there's always something to chase.
-- Tabs show one world at a time, each with its own progress.
local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local PetView = require(script.Parent.PetView)
local Screen = require(script.Parent.Screen)
local State = require(script.Parent.State)
local Ui = require(script.Parent.Ui)

local Index = {}

local modal, box = Screen.modal(860, 620)
Screen.title(box, "Animal Index")
local hint = Screen.subtitle(box, "")

-- overall progress bar
local track = Ui.new("Frame", {
	Position = UDim2.fromOffset(0, 62),
	Size = UDim2.new(1, -60, 0, 10),
	BackgroundColor3 = Ui.GLASS_LIGHT,
	ZIndex = 32,
	Parent = box,
}, { Ui.corner(0.5) })
local fill = Ui.new("Frame", {
	Size = UDim2.fromScale(0, 1),
	BackgroundColor3 = Color3.new(1, 1, 1),
	ZIndex = 33,
	Parent = track,
}, { Ui.corner(0.5), Ui.new("UIGradient", { Color = ColorSequence.new(Ui.PRIMARY_A, Ui.PRIMARY_B) }) })

-- world tabs: All, then one per world
Index.Tab = 0
local refresh
local tabRow = Ui.new("Frame", {
	Position = UDim2.fromOffset(0, 84),
	Size = UDim2.new(1, 0, 0, 34),
	BackgroundTransparency = 1,
	ZIndex = 32,
	Parent = box,
}, {
	Ui.new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}),
})
local tabs = {}
for tab = 1, #Config.AREAS + 1 do
	local world = tab - 1 -- 0 is "All"
	tabs[world] = Ui.button({
		LayoutOrder = world,
		Size = UDim2.fromOffset(if world == 0 then 90 else 150, 34),
		Radius = 17,
		Text = "",
		TextSize = 13,
		ZIndex = 33,
		Parent = tabRow,
	}, function()
		Index.Tab = world
		refresh(true)
	end, "glass")
end

local grid = Screen.scrollList(box, 130, Ui.new("UIGridLayout", {
	CellSize = UDim2.fromOffset(142, 176),
	CellPadding = UDim2.fromOffset(10, 10),
	SortOrder = Enum.SortOrder.LayoutOrder,
}))

local function card(pet, found, unlocked)
	local rarity = Config.rarity(pet.Odds)
	local frame = Ui.new("Frame", {
		LayoutOrder = pet.Index,
		BackgroundColor3 = if found then Ui.GLASS_LIGHT else Color3.fromRGB(26, 29, 54),
		BackgroundTransparency = 0.25,
		ZIndex = 32,
		Parent = grid,
	}, { Ui.corner(16), Ui.padding(8) })
	Ui.stroke(rarity.Color, 1.5, if found then 0.2 else 0.65).Parent = frame

	Ui.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 6),
		Size = UDim2.fromOffset(70, 70),
		BackgroundColor3 = if found then rarity.Color else Color3.fromRGB(90, 95, 140),
		BackgroundTransparency = if found then 0.8 else 0.85,
		ZIndex = 32,
		Parent = frame,
	}, { Ui.corner(0.5) })
	local view = PetView.take(pet.Name, not found)
	view.AnchorPoint = Vector2.new(0.5, 0)
	view.Position = UDim2.new(0.5, 0, 0, -2)
	view.Size = UDim2.fromOffset(92, 86)
	view.ZIndex = 33
	view.Parent = frame

	Ui.new("TextLabel", {
		Size = UDim2.fromOffset(32, 16),
		TextScaled = false,
		TextSize = 11,
		Font = Ui.FONT_MEDIUM,
		Text = "#" .. pet.Index,
		TextColor3 = Ui.MUTED,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 34,
		Parent = frame,
	})
	if found then
		Ui.new("Frame", {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, 0, 0, 0),
			Size = UDim2.fromOffset(16, 16),
			BackgroundColor3 = Ui.SUCCESS,
			ZIndex = 34,
			Parent = frame,
		}, { Ui.corner(0.5) })
	elseif pet.World > unlocked then
		Ui.icon("lock", 14, Ui.MUTED, {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, 0, 0, 0),
			ZIndex = 34,
			Parent = frame,
		})
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
	line(86, 15, Ui.FONT, if found then pet.Name else "???", if found then Ui.TEXT else Ui.MUTED)
	line(104, 11, Ui.FONT, string.upper(rarity.Name), rarity.Color)
	line(118, 12, Ui.FONT_MEDIUM, Config.formatOdds(pet.Odds), Ui.MUTED)
	local area = Config.AREAS[pet.World]
	line(138, 11, Ui.FONT, if found or pet.World <= unlocked then "Hatch in " .. area.Name else "Unlock " .. area.Name, area.Color)
end

local lastSignature = nil

function refresh(force)
	local data = State.Data
	if not data or not modal.Visible then
		return
	end
	local discovered = data.Discovered or {}
	local names = {}
	for name in pairs(discovered) do
		table.insert(names, name)
	end
	table.sort(names)
	local signature = Index.Tab .. "|" .. (data.Unlocked or 1) .. "|" .. table.concat(names, ",")
	if signature == lastSignature and not force then
		return
	end
	lastSignature = signature

	-- progress, overall and per world
	local total, perWorld, sizeOf = 0, {}, {}
	for _, pet in ipairs(Config.PETS) do
		sizeOf[pet.World] = (sizeOf[pet.World] or 0) + 1
		if discovered[pet.Name] then
			total += 1
			perWorld[pet.World] = (perWorld[pet.World] or 0) + 1
		end
	end
	hint.Text = total .. " / " .. #Config.PETS .. " Animals Discovered"
	fill.Size = UDim2.fromScale(total / #Config.PETS, 1)
	for world, tab in pairs(tabs) do
		Ui.setStyle(tab, if world == Index.Tab then "primary" else "glass")
		Ui.setText(tab, if world == 0
			then "All"
			else Config.AREAS[world].Name .. "  " .. (perWorld[world] or 0) .. "/" .. sizeOf[world])
	end

	PetView.releaseAll(grid)
	for _, child in ipairs(grid:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	for _, pet in ipairs(Config.PETS) do
		if Index.Tab == 0 or pet.World == Index.Tab then
			card(pet, discovered[pet.Name] == true, data.Unlocked or 1)
		end
	end
end

function Index.open()
	-- start on the world you're furthest in
	local data = State.Data
	if data and Index.Tab ~= 0 then
		Index.Tab = math.min(Index.Tab, data.Unlocked or 1)
	end
	Screen.open(modal)
	refresh(true)
end

State.watch(function()
	refresh(false)
end)

return Index
