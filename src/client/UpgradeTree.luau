-- The upgrade tree: a real tree growing out of a grassy hill. Upgrades
-- without a requirement grow straight from the trunk; the others grow out
-- of the upgrade they need (Config.UPGRADES[].Requires), so the picture
-- shows what unlocks what. It's all built from Config.UPGRADES, so new
-- branches appear on their own.
--
-- Each upgrade is a big round node: its icon in its colour, a level bar
-- ("Lv 4/20"), and its cost in a pill (gold when you can afford it). Paths
-- light up in the upgrade's colour once they're unlocked; locked nodes are
-- grey with a padlock and say what they need; maxed ones get a gold ring.
-- Affordable nodes glow and bob. Clicking a node selects it and shows it in
-- full on the right (now -> next, cost, BUY). Buying pops the node, bursts
-- sparkles, floats "+1 level: x1.82 coins" up from it and plays a jingle.
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
local DETAIL_W = 290
local CANVAS_W, CANVAS_H = WIDTH - 44 - DETAIL_W - 14, HEIGHT - 44 - 50
local NODE = 84

local modal, box = Screen.modal(WIDTH, HEIGHT, "Upgrades")
Screen.title(box, "Upgrade Tree")
local coinsLine = Screen.subtitle(box, "")

-- The canvas: sky, clouds, a grassy hill --------------------------------------------------------

local canvas = Ui.new("Frame", {
	Position = UDim2.fromOffset(0, 50),
	Size = UDim2.fromOffset(CANVAS_W, CANVAS_H),
	BackgroundColor3 = Color3.new(1, 1, 1),
	ClipsDescendants = true,
	ZIndex = 32,
	Parent = box,
}, {
	Ui.corner(24),
	Ui.new("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new(Color3.fromRGB(120, 200, 255), Color3.fromRGB(190, 235, 255)),
	}),
})
Ui.stroke(Color3.new(1, 1, 1), 3, 0.2).Parent = canvas
for _, c in ipairs({ { 0.14, 0.12, 110 }, { 0.62, 0.08, 150 }, { 0.9, 0.3, 90 }, { 0.36, 0.34, 70 } }) do
	for k = 0, 2 do
		Ui.new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(c[1], (k - 1) * c[3] * 0.32, c[2], if k == 1 then -c[3] * 0.12 else 0),
			Size = UDim2.fromOffset(c[3] * (if k == 1 then 0.62 else 0.46), c[3] * (if k == 1 then 0.42 else 0.3)),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BackgroundTransparency = 0.25,
			ZIndex = 32,
			Parent = canvas,
		}, { Ui.corner(0.5) })
	end
end
local hill = Ui.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 1, -70),
	Size = UDim2.new(1.4, 0, 0, 260),
	BackgroundColor3 = Color3.new(1, 1, 1),
	ZIndex = 32,
	Parent = canvas,
}, { Ui.corner(0.5), Ui.new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(130, 220, 90), Color3.fromRGB(70, 170, 70)) }) })
Ui.stroke(Color3.fromRGB(60, 140, 60), 3, 0.3).Parent = hill

local function path(from, to, thickness, color, z)
	local d = to - from
	return Ui.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset((from.X + to.X) / 2, (from.Y + to.Y) / 2),
		Size = UDim2.fromOffset(d.Magnitude + thickness, thickness),
		Rotation = math.deg(math.atan2(d.Y, d.X)),
		BackgroundColor3 = color,
		ZIndex = z or 33,
		Parent = canvas,
	}, { Ui.corner(0.5) })
end

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

local ROW_BOTTOM, ROW_GAP = CANVAS_H - 170, math.min(160, (CANVAS_H - 250) / math.max(maxDepth, 1))
local function positionOf(id)
	local x = CANVAS_W * (column[id] - 0.5) / columns
	return Vector2.new(x, ROW_BOTTOM - depth[id] * ROW_GAP)
end

-- the trunk, growing out of the hill and splitting to the first upgrades
local TRUNK = Color3.fromRGB(165, 105, 60)
local trunkTop = Vector2.new(CANVAS_W / 2, CANVAS_H - 105)
path(Vector2.new(CANVAS_W / 2, CANVAS_H + 20), trunkTop, 44, TRUNK, 33)
for _, side in ipairs({ -1, 1 }) do
	path(Vector2.new(CANVAS_W / 2, CANVAS_H - 50), Vector2.new(CANVAS_W / 2 + side * 60, CANVAS_H - 20), 18, TRUNK, 33)
end

local nodes = {} -- [id] = { Button, Path, Halo, Scale, ... }

local function label(parent, props)
	props.BackgroundTransparency = props.BackgroundTransparency or 1
	props.TextScaled = false
	props.ZIndex = props.ZIndex or 36
	props.Parent = parent
	return Ui.new("TextLabel", props)
end

for _, upgrade in ipairs(Config.UPGRADES) do
	local id = upgrade.Id
	local p = positionOf(id)
	local from = if upgrade.Requires then positionOf(upgrade.Requires[1]) else trunkTop
	local n = { Upgrade = upgrade, Position = p }
	-- the branch into this node: a dark outline and the coloured path on top
	path(from, p, 20, Color3.fromRGB(120, 75, 45), 33)
	n.Path = path(from, p, 12, Color3.fromRGB(150, 150, 170), 34)

	-- glow behind affordable nodes
	n.Halo = Ui.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(p.X, p.Y),
		Size = UDim2.fromOffset(NODE + 30, NODE + 30),
		BackgroundColor3 = upgrade.Color,
		BackgroundTransparency = 0.55,
		Visible = false,
		ZIndex = 34,
		Parent = canvas,
	}, { Ui.corner(0.5) })

	local button = Ui.new("TextButton", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(p.X, p.Y),
		Size = UDim2.fromOffset(NODE, NODE),
		BackgroundColor3 = Color3.new(1, 1, 1),
		AutoButtonColor = false,
		Text = "",
		ZIndex = 35,
		Parent = canvas,
	}, { Ui.corner(0.5) })
	n.Gradient = Ui.new("UIGradient", { Rotation = 90, Parent = button })
	n.Ring = Ui.stroke(Color3.new(1, 1, 1), 4, 0)
	n.Ring.Parent = button
	Ui.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 6),
		Size = UDim2.new(0.62, 0, 0.32, 0),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.72,
		ZIndex = 36,
		Parent = button,
	}, { Ui.corner(0.5) })
	n.Icon = Ui.icon(upgrade.Icon, 40, Color3.new(1, 1, 1), {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.52),
		ZIndex = 37,
		Parent = button,
	})
	-- padlock badge (locked) / crown badge (maxed)
	n.Lock = Ui.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(1, -8, 0, 8),
		Size = UDim2.fromOffset(30, 30),
		BackgroundColor3 = Color3.fromRGB(70, 70, 100),
		ZIndex = 38,
		Parent = button,
	}, { Ui.corner(0.5), Ui.stroke(Color3.new(1, 1, 1), 2.5) })
	Ui.icon("lock", 16, Color3.new(1, 1, 1), { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), ZIndex = 39, Parent = n.Lock })
	n.Crown = label(button, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0, -6),
		Size = UDim2.fromOffset(56, 22),
		BackgroundTransparency = 0,
		BackgroundColor3 = Ui.GOLD,
		TextSize = 15,
		Text = "MAX",
		TextColor3 = Ui.INK,
		ZIndex = 39,
	})
	Ui.corner(11).Parent = n.Crown
	Ui.stroke(Color3.new(1, 1, 1), 2).Parent = n.Crown

	-- under the node: name, level bar, cost
	local info = Ui.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromOffset(p.X, p.Y + NODE / 2 + 4),
		Size = UDim2.fromOffset(132, 70),
		BackgroundTransparency = 1,
		ZIndex = 35,
		Parent = canvas,
	})
	n.Name = label(info, {
		Size = UDim2.new(1, 0, 0, 20),
		TextSize = 18,
		Text = upgrade.Name,
		TextStrokeTransparency = 0,
		TextStrokeColor3 = Ui.INK,
	})
	local bar = Ui.new("Frame", {
		Position = UDim2.fromOffset(10, 22),
		Size = UDim2.new(1, -20, 0, 18),
		BackgroundColor3 = Color3.fromRGB(30, 24, 66),
		ZIndex = 36,
		Parent = info,
	}, { Ui.corner(0.5), Ui.stroke(Color3.new(1, 1, 1), 2, 0.1) })
	n.BarFill = Ui.new("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = upgrade.Color,
		ZIndex = 37,
		Parent = bar,
	}, { Ui.corner(0.5) })
	n.Level = label(bar, {
		Size = UDim2.fromScale(1, 1),
		TextSize = 13,
		TextStrokeTransparency = 0.2,
		TextStrokeColor3 = Ui.INK,
		ZIndex = 38,
	})
	n.Cost = label(info, {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 44),
		Size = UDim2.fromOffset(0, 24),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 0,
		BackgroundColor3 = Color3.fromRGB(40, 30, 80),
		TextSize = 16,
	})
	Ui.corner(12).Parent = n.Cost
	n.CostStroke = Ui.stroke(Color3.new(1, 1, 1), 2, 0.2)
	n.CostStroke.Parent = n.Cost
	Ui.new("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), Parent = n.Cost })

	n.Button = button
	n.Scale = Ui.new("UIScale", { Parent = button })
	button.Activated:Connect(function()
		Effects.play("Click", 1.1, 0.05)
		UpgradeTree.select(id)
	end)
	nodes[id] = n
end

-- The detail panel on the right ------------------------------------------------------------------

local detail = Ui.new("Frame", {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, 0, 0, 50),
	Size = UDim2.fromOffset(DETAIL_W, CANVAS_H),
	BackgroundColor3 = Color3.fromRGB(24, 18, 58),
	BackgroundTransparency = 0.3,
	ZIndex = 32,
	Parent = box,
}, { Ui.corner(24), Ui.padding(16) })
Ui.stroke(Color3.new(1, 1, 1), 2.5, 0.5).Parent = detail
local detailBadge = Ui.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 4),
	Size = UDim2.fromOffset(96, 96),
	BackgroundColor3 = Color3.new(1, 1, 1),
	ZIndex = 33,
	Parent = detail,
}, { Ui.corner(0.5) })
local detailGradient = Ui.new("UIGradient", { Rotation = 90, Parent = detailBadge })
Ui.stroke(Color3.new(1, 1, 1), 4).Parent = detailBadge
local detailIconHolder = Ui.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(52, 52),
	BackgroundTransparency = 1,
	ZIndex = 34,
	Parent = detailBadge,
})
local detailName = label(detail, {
	Position = UDim2.fromOffset(0, 108),
	Size = UDim2.new(1, 0, 0, 30),
	TextSize = 28,
	TextStrokeTransparency = 0,
	TextStrokeColor3 = Ui.INK,
	ZIndex = 33,
})
local detailLevel = label(detail, {
	Position = UDim2.fromOffset(0, 140),
	Size = UDim2.new(1, 0, 0, 20),
	TextSize = 17,
	TextColor3 = Ui.MUTED,
	ZIndex = 33,
})
local detailText = label(detail, {
	Position = UDim2.fromOffset(0, 166),
	Size = UDim2.new(1, 0, 0, 44),
	Font = Ui.FONT_MEDIUM,
	TextSize = 14,
	TextWrapped = true,
	TextColor3 = Color3.fromRGB(220, 215, 250),
	ZIndex = 33,
})
-- now -> next, big
local change = Ui.new("Frame", {
	Position = UDim2.fromOffset(0, 218),
	Size = UDim2.new(1, 0, 0, 78),
	BackgroundColor3 = Color3.fromRGB(50, 40, 105),
	BackgroundTransparency = 0.2,
	ZIndex = 33,
	Parent = detail,
}, { Ui.corner(18) })
label(change, { Position = UDim2.fromOffset(0, 6), Size = UDim2.new(0.5, 0, 0, 16), TextSize = 13, Text = "NOW", TextColor3 = Ui.MUTED, ZIndex = 34 })
label(change, { Position = UDim2.new(0.5, 0, 0, 6), Size = UDim2.new(0.5, 0, 0, 16), TextSize = 13, Text = "NEXT", TextColor3 = Ui.MUTED, ZIndex = 34 })
local nowText = label(change, { Position = UDim2.fromOffset(4, 26), Size = UDim2.new(0.5, -12, 0, 40), TextSize = 22, ZIndex = 34 })
local nextText = label(change, { Position = UDim2.new(0.5, 8, 0, 26), Size = UDim2.new(0.5, -12, 0, 40), TextSize = 22, TextColor3 = Ui.SUCCESS, ZIndex = 34 })
label(change, { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 30), Size = UDim2.fromOffset(20, 30), TextSize = 22, Text = "→", TextColor3 = Ui.GOLD, ZIndex = 34 })
local lockNote = label(detail, {
	Position = UDim2.fromOffset(0, 304),
	Size = UDim2.new(1, 0, 0, 40),
	TextSize = 16,
	TextWrapped = true,
	TextColor3 = Color3.fromRGB(255, 170, 170),
	ZIndex = 33,
})
local buyButton = Ui.button({
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, 0),
	Size = UDim2.new(1, 0, 0, 66),
	Radius = 22,
	Icon = "coin",
	Text = "BUY",
	TextSize = 24,
	ZIndex = 34,
	Parent = detail,
}, function()
	UpgradeTree.buy()
end, "success")
local buyScale = Ui.new("UIScale", { Parent = buyButton })

-- Showing state ------------------------------------------------------------------------------------

local selected = Config.UPGRADES[1].Id

local LOCKED_TOP, LOCKED_BOTTOM = Color3.fromRGB(170, 170, 190), Color3.fromRGB(110, 110, 140)

local function refresh()
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

		local top = if locked then LOCKED_TOP else upgrade.Color:Lerp(Color3.new(1, 1, 1), 0.3)
		local bottom = if locked then LOCKED_BOTTOM else upgrade.Color:Lerp(Color3.new(0, 0, 0), 0.2)
		n.Gradient.Color = ColorSequence.new(top, bottom)
		n.Ring.Color = if maxed then Ui.GOLD else Color3.new(1, 1, 1)
		n.Ring.Thickness = if upgrade.Id == selected then 7 elseif maxed then 5 else 4
		n.Lock.Visible = locked
		n.Crown.Visible = maxed
		n.Path.BackgroundColor3 = if locked then Color3.fromRGB(150, 150, 170) else upgrade.Color
		n.BarFill.Size = UDim2.fromScale(level / upgrade.Max, 1)
		n.Level.Text = "Lv " .. level .. "/" .. upgrade.Max
		if maxed then
			n.Cost.Text = "MAXED"
			n.Cost.TextSize = 16
			n.Cost.TextColor3 = Ui.GOLD
			n.Cost.BackgroundColor3 = Color3.fromRGB(90, 70, 20)
		elseif locked then
			n.Cost.Text = reason
			n.Cost.TextSize = 13
			n.Cost.TextColor3 = Color3.fromRGB(230, 230, 240)
			n.Cost.BackgroundColor3 = Color3.fromRGB(70, 70, 100)
		else
			n.Cost.Text = Config.formatNumber(cost) .. " coins"
			n.Cost.TextSize = 16
			n.Cost.TextColor3 = if affordable then Ui.INK else Color3.fromRGB(255, 190, 190)
			n.Cost.BackgroundColor3 = if affordable then Ui.GOLD else Color3.fromRGB(80, 40, 70)
		end
		n.Halo.Visible = affordable
		n.Affordable = affordable
	end

	-- the selected upgrade in full
	local upgrade = Config.UPGRADES_BY_ID[selected]
	local level = Config.upgradeLevel(data, selected)
	local ok, reason = Config.canUpgrade(data, selected)
	local cost = upgrade.Cost(level)
	local maxed = level >= upgrade.Max
	detailGradient.Color = ColorSequence.new(upgrade.Color:Lerp(Color3.new(1, 1, 1), 0.3), upgrade.Color:Lerp(Color3.new(0, 0, 0), 0.2))
	if detailIconHolder:GetAttribute("Icon") ~= upgrade.Icon then
		detailIconHolder:ClearAllChildren()
		Ui.icons[upgrade.Icon](detailIconHolder, Color3.new(1, 1, 1))
		detailIconHolder:SetAttribute("Icon", upgrade.Icon)
	end
	detailName.Text = upgrade.Name
	detailLevel.Text = "Level " .. level .. " of " .. upgrade.Max
	detailText.Text = upgrade.Describe
	nowText.Text = upgrade.Format(upgrade.Value(level))
	nextText.Text = if maxed then "MAX" else upgrade.Format(upgrade.Value(level + 1))
	lockNote.Text = if maxed then "All levels bought!" elseif not ok then reason else ""
	lockNote.TextColor3 = if maxed then Ui.GOLD else Color3.fromRGB(255, 170, 170)
	if maxed then
		Ui.setText(buyButton, "MAXED")
		Ui.setStyle(buyButton, "disabled")
	else
		Ui.setText(buyButton, "BUY  " .. Config.formatNumber(cost))
		Ui.setStyle(buyButton, if ok and data.Coins >= cost then "success" else "disabled")
	end
end

function UpgradeTree.select(id)
	selected = id
	refresh()
end

-- A burst of little stars flying out of a point on the canvas
local function sparkles(at, color)
	for k = 1, 12 do
		local a = k / 12 * math.pi * 2 + math.random() * 0.4
		local star = Ui.new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(at.X, at.Y),
			Size = UDim2.fromOffset(12, 12),
			Rotation = 45,
			BackgroundColor3 = if k % 3 == 0 then Color3.new(1, 1, 1) elseif k % 3 == 1 then Ui.GOLD else color,
			ZIndex = 40,
			Parent = canvas,
		}, { Ui.corner(3) })
		local distance = 70 + math.random() * 40
		TweenService:Create(star, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
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

-- "+1 level" text rising from a node and fading
local function floatText(at, text, color)
	local l = label(canvas, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(at.X, at.Y - NODE / 2),
		Size = UDim2.fromOffset(260, 28),
		TextSize = 22,
		Text = text,
		TextColor3 = color,
		TextStrokeTransparency = 0,
		TextStrokeColor3 = Ui.INK,
		ZIndex = 41,
	})
	TweenService:Create(l, TweenInfo.new(1.3, Enum.EasingStyle.Quad), { Position = UDim2.fromOffset(at.X, at.Y - NODE / 2 - 70), TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	task.delay(1.35, function()
		l:Destroy()
	end)
end

UpgradeTree.LastBuy = nil -- for the simulator: { Id, Level, Text }

function UpgradeTree.buy()
	local id = selected
	local upgrade = Config.UPGRADES_BY_ID[id]
	local before = if State.Data then Config.upgradeLevel(State.Data, id) else 0
	local n = nodes[id]
	if buyFunction:InvokeServer(id) then
		local text = "+1 level!  " .. upgrade.Format(upgrade.Value(before + 1))
		UpgradeTree.LastBuy = { Id = id, Level = before + 1, Text = text }
		Effects.jingle(3)
		-- the node pops, the path flashes, sparkles, and the change floats up
		n.Scale.Scale = 1.4
		TweenService:Create(n.Scale, TweenInfo.new(0.45, Enum.EasingStyle.Back), { Scale = 1 }):Play()
		n.Path.BackgroundColor3 = Color3.new(1, 1, 1)
		sparkles(n.Position, upgrade.Color)
		floatText(n.Position, text, Ui.GOLD)
		buyScale.Scale = 0.9
		TweenService:Create(buyScale, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Scale = 1 }):Play()
		task.delay(0.15, refresh)
	else
		Effects.play("Click", 0.7)
		-- a little "no" shake
		for k = 1, 4 do
			task.delay(k * 0.04, function()
				n.Button.Position = UDim2.fromOffset(n.Position.X + (if k % 2 == 0 then -5 else 5), n.Position.Y)
			end)
		end
		task.delay(0.2, function()
			n.Button.Position = UDim2.fromOffset(n.Position.X, n.Position.Y)
		end)
	end
end

function UpgradeTree.open()
	Screen.open(modal)
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

-- affordable nodes glow and bob; the selected one breathes
RunService.RenderStepped:Connect(function()
	if not modal.Visible then
		return
	end
	local t = os.clock()
	for id, n in pairs(nodes) do
		if n.Affordable then
			local pulse = math.sin(t * 4 + n.Position.X * 0.02)
			n.Halo.Size = UDim2.fromOffset(NODE + 26 + pulse * 8, NODE + 26 + pulse * 8)
			n.Halo.BackgroundTransparency = 0.55 + pulse * 0.15
			n.Button.Position = UDim2.fromOffset(n.Position.X, n.Position.Y + math.sin(t * 3 + n.Position.X) * 3)
		elseif id == selected and n.Scale.Scale >= 0.99 and n.Scale.Scale <= 1.06 then
			n.Scale.Scale = 1 + (math.sin(t * 3) * 0.5 + 0.5) * 0.05
		end
	end
end)

State.watch(function()
	if modal.Visible then
		refresh()
	end
end)

return UpgradeTree
