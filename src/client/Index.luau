-- The Animal Index: every animal there is, in three categories picked with
-- the buttons down the right side: NORMAL (the 70 animals, the collection
-- count), HUGE and TITANIC (the same 70 in those sizes, tracked separately;
-- they don't add to the 70). Found ones show in full colour; the rest are
-- dark silhouettes marked "???". Every animal can hatch in every world, so
-- each card shows its home world and its odds in the world you're standing
-- in (animals from worlds ahead are much rarer there). Tabs along the top
-- show one world's animals at a time.
local Players = game:GetService("Players")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local PetView = require(script.Parent.PetView)
local Screen = require(script.Parent.Screen)
local State = require(script.Parent.State)
local Ui = require(script.Parent.Ui)

local Index = {}

local SIDE = 168 -- the category column on the right
local modal, box = Screen.modal(940, 640, "Index")
Screen.title(box, "Animal Index")
local hint = Screen.subtitle(box, "")

-- World tabs along the top ---------------------------------------------------------------------

Index.Tab = 0 -- 0 = all worlds
Index.Size = 1 -- 1 Normal, 2 Huge, 3 Titanic
local refresh
local tabRow = Ui.new("Frame", {
	Position = UDim2.fromOffset(0, 56),
	Size = UDim2.new(1, -SIDE - 12, 0, 38),
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
		Size = UDim2.fromOffset(if world == 0 then 70 else 142, 38),
		Radius = 19,
		Text = "",
		TextSize = 15,
		ZIndex = 33,
		Parent = tabRow,
	}, function()
		Index.Tab = world
		refresh(true)
	end, "glass")
end

-- Categories down the right side ------------------------------------------------------------

local side = Ui.new("Frame", {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, 0, 0, 56),
	Size = UDim2.new(0, SIDE, 1, -56),
	BackgroundColor3 = Color3.fromRGB(20, 14, 50),
	BackgroundTransparency = 0.45,
	ZIndex = 32,
	Parent = box,
}, {
	Ui.corner(22),
	Ui.padding(12),
	Ui.new("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Padding = UDim.new(0, 12),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}),
})
Ui.new("TextLabel", {
	LayoutOrder = 0,
	Size = UDim2.new(1, 0, 0, 22),
	TextScaled = false,
	TextSize = 18,
	Text = "CATEGORY",
	TextColor3 = Ui.MUTED,
	ZIndex = 33,
	Parent = side,
})
local SIZE_STYLES = { "blue", "gold", "purple" }
local categories = {}
for i, size in ipairs(Config.SIZES) do
	local b = Ui.button({
		LayoutOrder = i,
		Size = UDim2.new(1, 0, 0, 86),
		Radius = 20,
		Text = "",
		ZIndex = 33,
		Parent = side,
	}, function()
		Index.Size = i
		refresh(true)
	end, "glass")
	local name = Ui.new("TextLabel", {
		Position = UDim2.fromOffset(0, 12),
		Size = UDim2.new(1, 0, 0, 30),
		TextScaled = false,
		TextSize = 26,
		Text = string.upper(size.Name),
		TextStrokeTransparency = 0,
		TextStrokeColor3 = Ui.INK,
		ZIndex = 35,
		Parent = b,
	})
	local count = Ui.new("TextLabel", {
		Position = UDim2.fromOffset(0, 46),
		Size = UDim2.new(1, 0, 0, 24),
		TextScaled = false,
		TextSize = 20,
		Text = "0/70",
		TextStrokeTransparency = 0.3,
		TextStrokeColor3 = Ui.INK,
		ZIndex = 35,
		Parent = b,
	})
	categories[i] = { Button = b, Name = name, Count = count }
end
-- overall progress, under the categories
local progressHolder = Ui.new("Frame", {
	LayoutOrder = 10,
	Size = UDim2.new(1, 0, 0, 120),
	BackgroundTransparency = 1,
	ZIndex = 33,
	Parent = side,
})
local progressText = Ui.new("TextLabel", {
	Size = UDim2.new(1, 0, 0, 60),
	TextScaled = false,
	TextSize = 17,
	TextWrapped = true,
	Text = "",
	ZIndex = 33,
	Parent = progressHolder,
})
local track = Ui.new("Frame", {
	Position = UDim2.fromOffset(0, 66),
	Size = UDim2.new(1, 0, 0, 16),
	BackgroundColor3 = Color3.fromRGB(20, 14, 50),
	ZIndex = 33,
	Parent = progressHolder,
}, { Ui.corner(0.5), Ui.stroke(Color3.new(1, 1, 1), 2, 0.4) })
local fill = Ui.new("Frame", {
	Size = UDim2.fromScale(0, 1),
	BackgroundColor3 = Color3.new(1, 1, 1),
	ZIndex = 34,
	Parent = track,
}, { Ui.corner(0.5), Ui.new("UIGradient", { Color = ColorSequence.new(Ui.PRIMARY_A, Ui.PRIMARY_B) }) })

local grid = Screen.scrollList(box, 106, Ui.new("UIGridLayout", {
	CellSize = UDim2.fromOffset(134, 178),
	CellPadding = UDim2.fromOffset(10, 10),
	SortOrder = Enum.SortOrder.LayoutOrder,
}))
grid.Size = UDim2.new(1, -SIDE - 12, 1, -106)
Index.Side, Index.Grid = side, grid -- (for the simulator)

-- The world the player is standing in (for "odds here")
local function currentWorld(data)
	local character = Players.LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local world = if root then Config.areaAt(root.Position.X) else 1
	return math.min(world, data.Unlocked or 1)
end
Index.currentWorld = currentWorld

-- Cards ------------------------------------------------------------------------------------

local function card(pet, sizeIndex, found, world)
	local rarity = Config.rarity(pet.Odds)
	local size = Config.SIZES[sizeIndex]
	local accent = if sizeIndex > 1 then size.Color else rarity.Color
	local frame = Ui.new("Frame", {
		LayoutOrder = pet.Index,
		BackgroundColor3 = if found then Color3.fromRGB(70, 60, 140) else Color3.fromRGB(30, 24, 66),
		BackgroundTransparency = 0.15,
		ZIndex = 32,
		Parent = grid,
	}, { Ui.corner(20), Ui.padding(8) })
	Ui.stroke(accent, if found then 3 else 2, if found then 0 else 0.6).Parent = frame

	Ui.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 6),
		Size = UDim2.fromOffset(72, 72),
		BackgroundColor3 = if found then accent else Color3.fromRGB(90, 90, 150),
		BackgroundTransparency = if found then 0.72 else 0.85,
		ZIndex = 32,
		Parent = frame,
	}, { Ui.corner(0.5) })
	local view = PetView.take(Config.petName(pet.Name, sizeIndex), not found)
	view.AnchorPoint = Vector2.new(0.5, 0)
	view.Position = UDim2.new(0.5, 0, 0, -2)
	view.Size = UDim2.fromOffset(92, 86)
	view.ZIndex = 33
	view.Parent = frame

	Ui.new("TextLabel", {
		Size = UDim2.fromOffset(34, 16),
		TextScaled = false,
		TextSize = 13,
		Text = "#" .. pet.Index,
		TextColor3 = Ui.MUTED,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 34,
		Parent = frame,
	})
	if found then
		Ui.new("TextLabel", {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, 0, 0, 0),
			Size = UDim2.fromOffset(20, 20),
			BackgroundTransparency = 0,
			BackgroundColor3 = Ui.SUCCESS,
			TextScaled = false,
			TextSize = 14,
			Text = "✓",
			ZIndex = 34,
			Parent = frame,
		}, { Ui.corner(0.5), Ui.stroke(Color3.new(1, 1, 1), 2) })
	end
	if sizeIndex > 1 then
		Ui.new("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 70),
			Size = UDim2.fromOffset(70, 16),
			BackgroundTransparency = 0,
			BackgroundColor3 = size.Color,
			TextScaled = false,
			TextSize = 12,
			Text = string.upper(size.Name),
			TextColor3 = Ui.INK,
			ZIndex = 35,
			Parent = frame,
		}, { Ui.corner(8) })
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
	line(88, 17, Ui.FONT, if found then pet.Name else "???", if found then Ui.TEXT else Ui.MUTED)
	line(107, 13, Ui.FONT, string.upper(rarity.Name), rarity.Color)
	-- odds where you stand (the size chance included for Huge/Titanic)
	local odds = Config.worldOdds(pet, world) * size.Chance
	line(123, 12, Ui.FONT_MEDIUM, Config.formatOdds(odds) .. " here", if pet.World > world then Color3.fromRGB(255, 170, 170) else Ui.MUTED)
	local area = Config.AREAS[pet.World]
	line(141, 12, Ui.FONT_MEDIUM, "Best in " .. area.Name, area.Color)
end

local lastSignature = nil

function refresh(force)
	local data = State.Data
	if not data or not modal.Visible then
		return
	end
	local discovered = data.Discovered or {}
	local world = currentWorld(data)
	local names = {}
	for name in pairs(discovered) do
		table.insert(names, name)
	end
	table.sort(names)
	local signature = Index.Tab .. "|" .. Index.Size .. "|" .. world .. "|" .. table.concat(names, ",")
	if signature == lastSignature and not force then
		return
	end
	lastSignature = signature

	-- progress: per category, and per world for the chosen category
	local perSize, perWorld, sizeOf = {}, {}, {}
	for i = 1, #Config.SIZES do
		perSize[i] = 0
	end
	for _, pet in ipairs(Config.PETS) do
		sizeOf[pet.World] = (sizeOf[pet.World] or 0) + 1
		for i = 1, #Config.SIZES do
			if discovered[Config.petName(pet.Name, i)] then
				perSize[i] += 1
				if i == Index.Size then
					perWorld[pet.World] = (perWorld[pet.World] or 0) + 1
				end
			end
		end
	end
	local total = #Config.PETS
	local size = Config.SIZES[Index.Size]
	hint.Text = perSize[1] .. " / " .. total .. " Animals Discovered"
	for i, c in ipairs(categories) do
		Ui.setStyle(c.Button, if i == Index.Size then SIZE_STYLES[i] else "glass")
		c.Count.Text = perSize[i] .. "/" .. total
		c.Name.TextColor3 = if i == Index.Size then Color3.new(1, 1, 1) else Config.SIZES[i].Color
	end
	progressText.Text = string.upper(size.Name) .. "\n" .. perSize[Index.Size] .. " of " .. total .. " found"
	fill.Size = UDim2.fromScale(perSize[Index.Size] / total, 1)
	for w, tab in pairs(tabs) do
		Ui.setStyle(tab, if w == Index.Tab then "blue" else "glass")
		Ui.setText(tab, if w == 0
			then "All"
			else Config.AREAS[w].Name .. " " .. (perWorld[w] or 0) .. "/" .. sizeOf[w])
	end

	PetView.releaseAll(grid)
	for _, child in ipairs(grid:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	for _, pet in ipairs(Config.PETS) do
		if Index.Tab == 0 or pet.World == Index.Tab then
			card(pet, Index.Size, discovered[Config.petName(pet.Name, Index.Size)] == true, world)
		end
	end
end

function Index.open()
	Screen.open(modal)
	refresh(true)
end

-- How many are found in a category (for the simulator and other screens)
function Index.found(sizeIndex)
	local data = State.Data
	local n = 0
	for _, pet in ipairs(Config.PETS) do
		if data and data.Discovered and data.Discovered[Config.petName(pet.Name, sizeIndex or 1)] then
			n += 1
		end
	end
	return n
end

State.watch(function()
	refresh(false)
end)

return Index
