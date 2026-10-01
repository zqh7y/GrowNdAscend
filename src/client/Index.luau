-- The Animal Index: every animal there is, in three categories picked with
-- the buttons down the right side: NORMAL (the 70 animals, the collection
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
	BackgroundColor3 = Ui.GLASS_LIGHT,
	BackgroundTransparency = 0.3,
	ZIndex = 32,
	Parent = box,
}, {
	Ui.corner(8),
	Ui.stroke(Ui.LINE, 1, 0.5),
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
	Font = Ui.FONT_TITLE,
	TextScaled = false,
	TextSize = 14,
	Text = "Category",
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
		Radius = 6,
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
		Font = Ui.FONT_TITLE,
		TextScaled = false,
		TextSize = 15,
		Text = string.upper(size.Name),
		ZIndex = 35,
		Parent = b,
	})
	local count = Ui.new("TextLabel", {
		Position = UDim2.fromOffset(0, 46),
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
	local frame = Ui.card({
		LayoutOrder = pet.Index,
		BackgroundColor3 = if found then Ui.GLASS_LIGHT else Color3.fromRGB(236, 238, 244),
		ZIndex = 32,
		Parent = grid,
	}, if found then accent else Ui.LINE, { Ui.padding(8) })
	-- a holo pad under the pet
	Ui.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0, 72),
		Size = UDim2.fromOffset(80, 14),
		BackgroundColor3 = if found then accent else Ui.LINE,
		BackgroundTransparency = if found then 0.75 else 0.85,
		ZIndex = 32,
		Parent = frame,
	}, { Ui.corner(0.5), Ui.stroke(if found then accent else Ui.LINE, 1, 0.4) })
	local view = PetView.take(Config.petName(pet.Name, sizeIndex), not found)
	view.AnchorPoint = Vector2.new(0.5, 0)
	view.Position = UDim2.new(0.5, 0, 0, -2)
	view.Size = UDim2.fromOffset(92, 86)
	view.ZIndex = 33
	view.Parent = frame

	Ui.new("TextLabel", {
		Size = UDim2.fromOffset(34, 16),
		TextScaled = false,
		Font = Ui.FONT_TITLE,
		TextSize = 11,
		Text = string.format("#%02d", pet.Index),
		TextColor3 = Ui.MUTED,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 34,
		Parent = frame,
	})
	if found then
		Ui.new("TextLabel", {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, 0, 0, 0),
			Size = UDim2.fromOffset(18, 18),
			BackgroundTransparency = 0,
			BackgroundColor3 = Ui.SUCCESS,
			TextScaled = false,
			TextSize = 13,
			Text = "✓",
			TextColor3 = Ui.INK,
			ZIndex = 34,
			Parent = frame,
		}, { Ui.corner(3) })
	end
	if sizeIndex > 1 then
		Ui.new("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 70),
			Size = UDim2.fromOffset(70, 16),
			BackgroundTransparency = 0,
			BackgroundColor3 = size.Color,
			Font = Ui.FONT_TITLE,
			TextScaled = false,
			TextSize = 11,
			Text = string.upper(size.Name),
			TextColor3 = Ui.INK,
			ZIndex = 35,
			Parent = frame,
		}, { Ui.corner(3) })
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
	line(88, 16, Ui.FONT, if found then pet.Name else "???", if found then Ui.TEXT else Ui.MUTED)
	line(108, 11, Ui.FONT_TITLE, string.upper(rarity.Name), rarity.Color)
	-- the exact chance of your next roll here (your luck, size luck and this
	-- world: the same numbers the server rolls with); every animal can hatch
	-- in every world, it's just rarer in worlds before its home world
	local data = State.Data
	local chance = 0
	if data then
		local nextIsBonus = (data.Rolls + 1) % Config.BONUS_EVERY == 0
		local sizeLuck = Config.sizeLuck(data) * (if nextIsBonus then Config.BONUS_LUCK else 1)
		chance = Config.chanceOf(Config.petName(pet.Name, sizeIndex), Config.luck(data, nextIsBonus, world), sizeLuck, world)
	end
	local here = line(123, 12, Ui.FONT_MEDIUM, Config.formatChance(chance) .. " here", Ui.INK)
	here.Name = "ChanceHere"
	local every = line(141, 11, Ui.FONT_MEDIUM, "Hatches in every world", Ui.MUTED)
	every.Name = "Worlds"
	return frame
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
	local nextIsBonus = (data.Rolls + 1) % Config.BONUS_EVERY == 0
	local luckKey = string.format("%.6g|%.6g", Config.luck(data, nextIsBonus, world), Config.sizeLuck(data) * (if nextIsBonus then 2 else 1))
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

	PetView.releaseAll(grid)
	for _, child in ipairs(grid:GetChildren()) do
		if child:IsA("Frame") then
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
