-- The Animal Index: every animal there is, as hexagon tiles (PetTile) on
-- the right; on the left, how many you've found, the three categories and
-- the collection rewards. Hover (or tap) a tile for its card: name,
-- rarity, the chance here, power and stats. Categories: NORMAL (the 70 animals, the collection
-- count), HUGE and TITANIC (the same 70 in those sizes, tracked separately;
-- they don't add to the 70). Found ones show in full colour; the rest are
-- dark silhouettes marked "???". Every animal can hatch in every world, so
-- each card shows the exact chance of your next roll in the world you're
-- standing in (animals from worlds ahead are much rarer there, never
-- impossible). Tabs along the top
-- show one world's animals at a time.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local Effects = require(script.Parent.Effects)
local PetTile = require(script.Parent.PetTile)
local PetView = require(script.Parent.PetView)
local Screen = require(script.Parent.Screen)
local State = require(script.Parent.State)
local Ui = require(script.Parent.Ui)

local Index = {}

local SIDE = 200 -- the info column on the left
local GRID_X = SIDE + 14
local TILE_W = 100
local modal, box = Screen.modal(940, 640, "Index")
Screen.title(box, "Animal Index")
local hint = Screen.subtitle(box, "")

-- World tabs along the top ---------------------------------------------------------------------

Index.Tab = 0 -- 0 = all worlds
Index.Size = 1 -- 1 Normal, 2 Huge, 3 Titanic
local refresh
local tabRow = Ui.new("Frame", {
	Position = UDim2.fromOffset(GRID_X, 0),
	Size = UDim2.new(1, -GRID_X, 0, 38),
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
for tab = 1, Config.PET_WORLDS + 1 do -- (worlds with animals of their own)
	local world = tab - 1 -- 0 is "All"
	tabs[world] = Ui.button({
		LayoutOrder = world,
		Size = UDim2.fromOffset(if world == 0 then 60 else 136, 38),
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

-- The info column on the left -------------------------------------------------------------

local side = Ui.new("Frame", {
	Position = UDim2.fromOffset(0, 0),
	Size = UDim2.new(0, SIDE, 1, 0),
	BackgroundTransparency = 1,
	ZIndex = 32,
	Parent = box,
}, {
	Ui.new("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}),
})
Ui.chunky({
	LayoutOrder = 0,
	Size = UDim2.new(1, 0, 0, 30),
	TextSize = 26,
	Text = "Animal Index",
	Outline = 2.5,
	ZIndex = 33,
	Parent = side,
})
local foundCount = Ui.chunky({
	Name = "FoundCount",
	LayoutOrder = 1,
	Size = UDim2.new(1, 0, 0, 34),
	TextSize = 30,
	Text = "[0/70]",
	TextColor3 = Color3.fromRGB(235, 230, 245),
	Outline = 2.5,
	ZIndex = 33,
	Parent = side,
})
local SIZE_STYLES = { "blue", "gold", "purple" }
local categories = {}
for i, size in ipairs(Config.SIZES) do
	local b = Ui.button({
		LayoutOrder = 1 + i,
		Size = UDim2.new(1, 0, 0, 58),
		Radius = 14,
		Text = "",
		ZIndex = 33,
		Parent = side,
	}, function()
		Index.Size = i
		refresh(true)
	end, "glass")
	local name = Ui.new("TextLabel", {
		Position = UDim2.fromOffset(0, 6),
		Size = UDim2.new(1, 0, 0, 22),
		Font = Ui.FONT_TITLE,
		TextScaled = false,
		TextSize = 15,
		Text = string.upper(size.Name),
		ZIndex = 35,
		Parent = b,
	})
	local count = Ui.new("TextLabel", {
		Position = UDim2.fromOffset(0, 28),
		Size = UDim2.new(1, 0, 0, 24),
		TextScaled = false,
		TextSize = 20,
		Text = "0/70",
		ZIndex = 35,
		Parent = b,
	})
	categories[i] = { Button = b, Name = name, Count = count }
end
-- Collection rewards, under the categories: the next milestone and how close
-- you are ("18 / 20"), with a gift; when one is reached the card turns gold
-- and a CLAIM button appears. What's inside stays a surprise until you open it.
local rewards = Ui.new("Frame", {
	Name = "Rewards",
	LayoutOrder = 10,
	Size = UDim2.new(1, 0, 0, 176),
	BackgroundColor3 = Ui.WHITE,
	ZIndex = 33,
	Parent = side,
}, { Ui.corner(14), Ui.padding(12) })
local rewardsEdge = Ui.stroke(Ui.LINE, 1.5, 0)
rewardsEdge.Parent = rewards
local rewardsScale = Ui.new("UIScale", { Parent = rewards })
local giftHolder = Ui.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.fromScale(0.5, 0),
	Size = UDim2.fromOffset(44, 44),
	BackgroundTransparency = 1,
	ZIndex = 34,
	Parent = rewards,
})

-- a little gift box drawn with frames
local function gift(parent, size, color)
	local holder = Ui.new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(size, size), BackgroundTransparency = 1, ZIndex = parent.ZIndex + 1, Parent = parent })
	local z = holder.ZIndex
	local boxPart = Ui.new("Frame", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 1), Size = UDim2.fromScale(0.82, 0.62), BackgroundColor3 = color, ZIndex = z, Parent = holder }, { Ui.corner(0.18) })
	local lid = Ui.new("Frame", { Name = "Lid", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 0.42), Size = UDim2.fromScale(0.96, 0.22), BackgroundColor3 = color:Lerp(Ui.WHITE, 0.15), ZIndex = z + 1, Parent = holder }, { Ui.corner(0.3) })
	Ui.new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0), Size = UDim2.fromScale(0.16, 1), BackgroundColor3 = Ui.WHITE, ZIndex = z + 1, Parent = boxPart })
	Ui.new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0), Size = UDim2.fromScale(0.16, 1), BackgroundColor3 = Ui.WHITE, ZIndex = z + 2, Parent = lid })
	for _, side in ipairs({ -1, 1 }) do
		Ui.new("Frame", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, side * size * 0.1, 0, 0), Size = UDim2.fromScale(0.22, 0.18), Rotation = side * 30, BackgroundColor3 = Ui.WHITE, ZIndex = z + 2, Parent = lid }, { Ui.corner(0.5) })
	end
	return holder, lid
end
gift(giftHolder, 40, Ui.PURPLE)
local rewardsTitle = Ui.new("TextLabel", {
	Position = UDim2.fromOffset(0, 48),
	Size = UDim2.new(1, 0, 0, 18),
	Font = Ui.FONT,
	TextScaled = false,
	TextSize = 14,
	TextColor3 = Ui.INK,
	Text = "Next reward",
	ZIndex = 34,
	Parent = rewards,
})
local rewardsGoal = Ui.new("TextLabel", {
	Position = UDim2.fromOffset(0, 68),
	Size = UDim2.new(1, 0, 0, 16),
	Font = Ui.FONT_MEDIUM,
	TextScaled = false,
	TextSize = 12,
	TextWrapped = true,
	TextColor3 = Ui.MUTED,
	Text = "",
	ZIndex = 34,
	Parent = rewards,
})
local rewardsTrack = Ui.new("Frame", {
	Position = UDim2.fromOffset(0, 92),
	Size = UDim2.new(1, 0, 0, 10),
	BackgroundColor3 = Color3.fromRGB(232, 235, 243),
	ZIndex = 34,
	Parent = rewards,
}, { Ui.corner(5) })
local rewardsFill = Ui.new("Frame", {
	Size = UDim2.fromScale(0, 1),
	BackgroundColor3 = Ui.WHITE,
	ZIndex = 35,
	Parent = rewardsTrack,
}, { Ui.corner(5), Ui.new("UIGradient", { Color = ColorSequence.new(Ui.PURPLE, Ui.BLUE) }) })
local claimButton
claimButton = Ui.button({
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, 0),
	Size = UDim2.new(1, 0, 0, 40),
	Radius = 14,
	Text = "CLAIM",
	TextSize = 16,
	ZIndex = 35,
	Parent = rewards,
}, function()
	Index.claim()
end, "gold")
local claimScale = claimButton:FindFirstChildOfClass("UIScale")

local grid = Screen.scrollList(box, 48, Ui.new("UIGridLayout", {
	CellSize = UDim2.fromOffset(TILE_W, math.floor(TILE_W * PetTile.ASPECT)),
	CellPadding = UDim2.fromOffset(8, 8),
	SortOrder = Enum.SortOrder.LayoutOrder,
}))
grid.Position = UDim2.fromOffset(GRID_X, 48)
grid.Size = UDim2.new(1, -GRID_X, 1, -48)
Index.Side, Index.Grid = side, grid -- (for the simulator)

-- The world the player is standing in (for "odds here")
local function currentWorld(data)
	local character = Players.LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local world = if root then Config.areaAt(root.Position.X) else 1
	return math.min(world, data.Unlocked or 1)
end
Index.currentWorld = currentWorld

-- The card that pops up over a tile ---------------------------------------------------------------

local tip = Ui.new("Frame", {
	Name = "Tooltip",
	Size = UDim2.fromOffset(230, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundColor3 = Ui.WHITE,
	Visible = false,
	ZIndex = 60,
	Parent = box,
}, {
	Ui.corner(18),
	Ui.padding(14),
	Ui.new("UIListLayout", { HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
})
local tipEdge = Ui.stroke(Ui.GOLD, 4, 0)
tipEdge.Parent = tip
Index.Tooltip = tip
local function tipLabel(order, props)
	props.LayoutOrder = order
	props.Size = props.Size or UDim2.new(1, 0, 0, (props.TextSize or 14) + 6)
	props.TextScaled = false
	props.ZIndex = 61
	props.Parent = tip
	return Ui.new("TextLabel", props)
end
local tipName = tipLabel(1, { Font = Ui.FONT_DISPLAY, TextSize = 26, TextColor3 = Ui.INK })
local tipRarity = tipLabel(2, {
	Size = UDim2.fromOffset(0, 24),
	AutomaticSize = Enum.AutomaticSize.X,
	BackgroundTransparency = 0,
	Font = Ui.FONT_DISPLAY,
	TextSize = 16,
	TextColor3 = Ui.WHITE,
})
Ui.corner(12).Parent = tipRarity
Ui.new("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14), Parent = tipRarity })
Ui.new("UIStroke", { Color = Ui.OUTLINE, Thickness = 1.5, Parent = tipRarity })
local tipOdds = tipLabel(3, { Font = Ui.FONT_DISPLAY, TextSize = 20, TextColor3 = Color3.fromRGB(190, 120, 20) })
local tipPower = tipLabel(4, { Font = Ui.FONT, TextSize = 17, TextColor3 = Ui.INK })
local tipStats = tipLabel(5, { Font = Ui.FONT_MEDIUM, TextSize = 13, TextColor3 = Ui.MUTED, TextWrapped = true, Size = UDim2.new(1, 0, 0, 34) })
local tipOutfit = tipLabel(6, { Name = "Outfit", Font = Ui.FONT, TextSize = 13, TextColor3 = Ui.INK })
local tipWorlds = tipLabel(7, { Name = "Worlds", Font = Ui.FONT_MEDIUM, TextSize = 12, TextColor3 = Ui.MUTED, Text = "Hatches in every world" })
local tipOwner = nil

-- shows the card for a tile (or hides it with nil)
function Index.showTip(frame, info)
	if not frame then
		tip.Visible = false
		tipOwner = nil
		return
	end
	tipOwner = frame
	local pet, sizeIndex, found = info.Pet, info.Size, info.Found
	local rarity = Config.rarity(pet.Odds)
	local name = Config.petName(pet.Name, sizeIndex)
	tipName.Text = if found then name else "???"
	tipRarity.Text = rarity.Name
	tipRarity.BackgroundColor3 = rarity.Color
	tipOdds.Text = info.Odds .. " at x1 luck"
	tipPower.Text = if found then "⚔ " .. Config.formatNumber(Config.petPower(name)) .. " power" else "Not found yet"
	local parts = {}
	if found then
		for _, stat in ipairs({ "Luck", "Coins", "Damage", "Exp" }) do
			local value = Config.petStat(name, stat)
			if value > 1.001 then
				table.insert(parts, stat .. " " .. Config.formatStat(value))
			end
		end
	end
	tipStats.Text = table.concat(parts, "  ·  ")
	local look = Config.outfitOf(name)
	tipOutfit.Text = if found and look then "Outfit: " .. look.Name else ""
	tipOutfit.Visible = found and look ~= nil
	tipStats.Visible = #parts > 0
	tipWorlds.Text = "Hatches in every world"
	tipEdge.Color = rarity.Color
	-- next to the tile, inside the panel
	local holder = box.Parent
	local ratio = if holder and holder.Size.X.Offset > 0 then math.max(box.AbsoluteSize.X / holder.Size.X.Offset, 0.01) else 1
	local rel = (frame.AbsolutePosition - box.AbsolutePosition) / ratio
	local x = rel.X + frame.AbsoluteSize.X / ratio + 6
	if x + 230 > box.AbsoluteSize.X / ratio - 24 then
		x = rel.X - 236
	end
	tip.Position = UDim2.fromOffset(math.max(x, 0), math.clamp(rel.Y - 10, 0, 420))
	tip.Visible = true
end

-- Tiles ------------------------------------------------------------------------------------

local function card(pet, sizeIndex, found, world)
	-- how rare it really is: its odds at x1 luck (the same for everyone,
	-- whatever their luck), counting its size
	local _ = world
	local odds = Config.shortOdds(Config.oddsOf(Config.petName(pet.Name, sizeIndex)))
	local tile = PetTile.new({
		Name = Config.petName(pet.Name, sizeIndex),
		Width = TILE_W,
		LayoutOrder = pet.Index,
		Silhouette = not found,
		Odds = odds,
		Parent = grid,
	})
	tile.Odds.Name = "ChanceHere"
	local info = { Pet = pet, Size = sizeIndex, Found = found, Odds = odds }
	tile.Frame.MouseEnter:Connect(function()
		Index.showTip(tile.Frame, info)
	end)
	tile.Frame.MouseLeave:Connect(function()
		if tipOwner == tile.Frame then
			Index.showTip(nil)
		end
	end)
	tile.Frame.Activated:Connect(function()
		if tipOwner == tile.Frame and tip.Visible then
			Index.showTip(nil)
		else
			Index.showTip(tile.Frame, info)
		end
	end)
	return tile.Frame
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
	local luckKey = "" -- (the odds shown don't depend on luck)
	local signature = Index.Tab .. "|" .. Index.Size .. "|" .. world .. "|" .. luckKey .. "|" .. table.concat(names, ",")
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
	hint.Text = perSize[1] .. " / " .. total .. " Animals Discovered"
	foundCount.Text = "[" .. perSize[Index.Size] .. "/" .. total .. "]"
	for i, c in ipairs(categories) do
		Ui.setStyle(c.Button, if i == Index.Size then SIZE_STYLES[i] else "glass")
		c.Count.Text = perSize[i] .. "/" .. total
		c.Name.TextColor3 = if i == Index.Size then Color3.new(1, 1, 1) else Config.SIZES[i].Color
	end
	Index.refreshRewards()
	for w, tab in pairs(tabs) do
		Ui.setStyle(tab, if w == Index.Tab then "blue" else "glass")
		Ui.setText(tab, if w == 0
			then "All"
			else Config.AREAS[w].Name .. " " .. (perWorld[w] or 0) .. "/" .. sizeOf[w])
	end

	Index.showTip(nil)
	PetView.releaseAll(grid)
	for _, child in ipairs(grid:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	local order = 0
	for _, pet in ipairs(Config.PETS) do
		if Index.Tab == 0 or pet.World == Index.Tab then
			order += 1
			local frame = card(pet, Index.Size, discovered[Config.petName(pet.Name, Index.Size)] == true, world)
			if force and frame then
				Ui.appear(frame, order)
			end
		end
	end
end

-- Collection rewards -------------------------------------------------------------------------

local claimFunction = State.remote("ClaimMilestone")
local claiming = false

local function sizeLabel(m)
	return if m.Size == 1 then "animals" elseif m.Size == 2 then "Huge animals" else "Titanic animals"
end

-- the first reward you can claim now, else the next one to reach (closest first)
function Index.nextMilestone(data)
	local claimable, nextUp, bestRatio = nil, nil, -1
	for _, m in ipairs(Config.MILESTONES) do
		if not (data.Milestones and data.Milestones[m.Id]) then
			local have = Config.discoveredCount(data, m.Size)
			if have >= m.Count then
				claimable = claimable or m
			else
				local ratio = have / m.Count
				if ratio > bestRatio then
					nextUp, bestRatio = m, ratio
				end
			end
		end
	end
	return claimable, nextUp
end

function Index.anyClaimable()
	local data = State.Data
	return data ~= nil and (Index.nextMilestone(data)) ~= nil
end

function Index.refreshRewards()
	local data = State.Data
	if not data then
		return
	end
	local claimable, nextUp = Index.nextMilestone(data)
	local m = claimable or nextUp
	if not m then
		rewardsTitle.Text = "All rewards claimed"
		rewardsGoal.Text = "You found them all!"
		rewardsFill.Size = UDim2.fromScale(1, 1)
		claimButton.Visible = false
		rewardsEdge.Color = Ui.LINE
		return
	end
	local have = math.min(Config.discoveredCount(data, m.Size), m.Count)
	rewardsTitle.Text = if claimable then "Reward ready!" else "Next reward"
	rewardsGoal.Text = string.format("%d / %d %s", have, m.Count, sizeLabel(m))
	TweenService:Create(rewardsFill, TweenInfo.new(0.4, Enum.EasingStyle.Quint), { Size = UDim2.fromScale(have / m.Count, 1) }):Play()
	claimButton.Visible = claimable ~= nil
	if claimable and Index.ShownReady ~= claimable.Id then
		-- a reward just became ready: a gentle pop
		rewardsScale.Scale = 1.08
		TweenService:Create(rewardsScale, TweenInfo.new(0.4, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	end
	Index.ShownReady = claimable and claimable.Id
	rewardsEdge.Color = if claimable then Ui.GOLD else Ui.LINE
	rewardsEdge.Thickness = if claimable then 2 else 1.5
	rewards.BackgroundColor3 = if claimable then Color3.fromRGB(255, 249, 232) else Ui.WHITE
end

-- the reveal: a gift in the middle of the Index that wobbles, pops open and
-- shows exactly what the server gave
local revealLayer = Ui.new("TextButton", {
	Name = "RewardReveal",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Ui.WHITE,
	BackgroundTransparency = 0.12,
	AutoButtonColor = false,
	Text = "",
	Visible = false,
	ZIndex = 70,
	Parent = box,
}, { Ui.corner(22) })
local revealGiftHolder = Ui.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.4),
	Size = UDim2.fromOffset(140, 140),
	BackgroundTransparency = 1,
	ZIndex = 72,
	Parent = revealLayer,
})
local revealScale = Ui.new("UIScale", { Parent = revealGiftHolder })
local revealRays = Ui.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.4),
	Size = UDim2.fromOffset(360, 360),
	BackgroundTransparency = 1,
	ZIndex = 71,
	Parent = revealLayer,
})
for k = 0, 5 do
	Ui.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0, 46, 1, 0),
		Rotation = k * 30,
		BackgroundColor3 = Ui.GOLD,
		BackgroundTransparency = 0.55,
		ZIndex = 71,
		Parent = revealRays,
	}, { Ui.new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.2), NumberSequenceKeypoint.new(1, 1) }) }) })
end
local revealTitle = Ui.new("TextLabel", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.64),
	Size = UDim2.fromOffset(500, 36),
	Font = Ui.FONT_DISPLAY,
	TextScaled = false,
	TextSize = 30,
	TextColor3 = Ui.INK,
	Text = "",
	ZIndex = 73,
	Parent = revealLayer,
})
local revealPrizes = Ui.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.fromScale(0.5, 0.7),
	Size = UDim2.fromOffset(500, 44),
	BackgroundTransparency = 1,
	ZIndex = 73,
	Parent = revealLayer,
}, {
	Ui.new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Padding = UDim.new(0, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}),
})
local revealHint = Ui.new("TextLabel", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.86),
	Size = UDim2.fromOffset(300, 18),
	Font = Ui.FONT_MEDIUM,
	TextScaled = false,
	TextSize = 13,
	TextColor3 = Ui.MUTED,
	Text = "Click to continue",
	ZIndex = 73,
	Parent = revealLayer,
})
local revealDone = false
revealLayer.Activated:Connect(function()
	revealDone = true
end)

local function prize(order, iconName, iconColor, text, color, background)
	local chip = Ui.new("Frame", {
		LayoutOrder = order,
		Size = UDim2.fromOffset(0, 40),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = background,
		ZIndex = 74,
		Parent = revealPrizes,
	}, {
		Ui.corner(20),
		Ui.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
		Ui.new("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 16) }),
	})
	Ui.icon(iconName, 22, iconColor, { LayoutOrder = 0, ZIndex = 75, Parent = chip })
	Ui.new("TextLabel", {
		LayoutOrder = 1,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 24),
		Font = Ui.FONT_DISPLAY,
		TextScaled = false,
		TextWrapped = false,
		TextSize = 20,
		TextColor3 = color,
		Text = text,
		ZIndex = 75,
		Parent = chip,
	})
	local scale = Ui.new("UIScale", { Scale = 0, Parent = chip })
	TweenService:Create(scale, TweenInfo.new(0.4, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	return chip
end

Index.LastClaim = nil -- for the simulator: what the last claim got and showed

-- Claims the reward that's ready (the server checks and pays it, once)
function Index.claim()
	local data = State.Data
	if claiming or not data then
		return
	end
	local m = Index.nextMilestone(data)
	if not m then
		return
	end
	claiming = true
	claimButton.Visible = false
	local got = claimFunction:InvokeServer(m.Id)
	if not got then
		claiming = false
		Index.refreshRewards()
		return
	end
	Index.LastClaim = { Id = got.Id, Coins = got.Coins, Boost = got.Boost, Shown = {} }
	-- the reveal
	for _, child in ipairs(revealGiftHolder:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	for _, child in ipairs(revealPrizes:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	local _, lid = gift(revealGiftHolder, 120, Ui.PURPLE)
	revealTitle.Text = string.format("%d %s discovered!", m.Count, sizeLabel(m))
	revealTitle.TextTransparency = 1
	revealRays.Visible = false
	revealHint.Visible = false
	revealDone = false
	revealLayer.Visible = true
	revealScale.Scale = 0.4
	TweenService:Create(revealScale, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	-- anticipation: the gift wobbles harder and harder
	local start = os.clock()
	while os.clock() - start < 0.9 and not revealDone do
		local t = os.clock() - start
		revealGiftHolder.Rotation = math.sin(t * 34) * (2 + t * 9)
		task.wait()
	end
	revealGiftHolder.Rotation = 0
	-- it pops open
	Effects.jingle(5)
	Effects.confetti(50)
	TweenService:Create(lid, TweenInfo.new(0.45, Enum.EasingStyle.Quint), { Position = UDim2.fromScale(0.5, -0.4), Rotation = -25, BackgroundTransparency = 1 }):Play()
	revealScale.Scale = 1.18
	TweenService:Create(revealScale, TweenInfo.new(0.4, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	revealRays.Visible = true
	TweenService:Create(revealTitle, TweenInfo.new(0.3), { TextTransparency = 0 }):Play()
	if got.Coins > 0 then
		local text = "+" .. Config.formatNumber(got.Coins) .. " coins"
		prize(1, "coin", Ui.GOLD, text, Color3.fromRGB(150, 100, 10), Color3.fromRGB(255, 244, 214))
		table.insert(Index.LastClaim.Shown, text)
	end
	if got.Boost > 1 then
		local text = "×" .. got.Boost .. " luck boost"
		prize(2, "clover", Ui.SUCCESS, text, Color3.fromRGB(30, 140, 80), Color3.fromRGB(226, 248, 234))
		table.insert(Index.LastClaim.Shown, text)
	end
	revealHint.Visible = true
	local shown = os.clock()
	revealDone = false
	while os.clock() - shown < 3 and not revealDone do
		revealRays.Rotation += 0.6
		task.wait()
	end
	revealLayer.Visible = false
	claiming = false
	Index.refreshRewards()
end

-- the claim button breathes while a reward is ready
task.spawn(function()
	while true do
		task.wait()
		if claimButton.Visible and modal.Visible and claimScale then
			claimScale.Scale = 1 + (math.sin(os.clock() * 4) * 0.5 + 0.5) * 0.04
		end
	end
end)

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
