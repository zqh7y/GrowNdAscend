-- The upgrade tree. A trunk at the bottom splits into one branch per upgrade
-- (Config.UPGRADES, so new branches appear automatically). Each branch grows
-- up as a line of level nodes (filled when bought) and ends in a card that
-- always shows everything: icon, name, "Lv 4 -> 5", what the next level
-- gives, and the cost (or MAX, or a lock with what it needs). Clicking a
-- card buys it; the bar at the bottom explains the selected branch in full.
local RunService = game:GetService("RunService")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local Ui = require(script.Parent.Ui)
local Screen = require(script.Parent.Screen)
local State = require(script.Parent.State)
local Effects = require(script.Parent.Effects)

local UpgradeTree = {}

local buyFunction = State.remote("BuyUpgrade")

local WIDTH, HEIGHT = 960, 640
local CANVAS_W, CANVAS_H = WIDTH - 44, 470
local CARD_W, CARD_H = 104, 126
local MAX_NODES = 10 -- branches with more levels show one node per few levels

local modal, box = Screen.modal(WIDTH, HEIGHT)
Screen.title(box, "Upgrade Tree")
local coinsLine = Screen.subtitle(box, "")

local canvas = Ui.new("Frame", {
	Position = UDim2.fromOffset(0, 62),
	Size = UDim2.fromOffset(CANVAS_W, CANVAS_H),
	BackgroundColor3 = Color3.fromRGB(30, 40, 70),
	BackgroundTransparency = 0.45,
	ClipsDescendants = true,
	ZIndex = 32,
	Parent = box,
}, { Ui.corner(18) })
Ui.new("UIGradient", {
	Rotation = 90,
	Color = ColorSequence.new(Color3.fromRGB(120, 170, 255), Color3.fromRGB(90, 200, 140)),
	Transparency = NumberSequence.new(0.35, 0.15),
	Parent = canvas,
})

local function line(from, to, thickness, color)
	local d = to - from
	return Ui.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset((from.X + to.X) / 2, (from.Y + to.Y) / 2),
		Size = UDim2.fromOffset(d.Magnitude + thickness * 0.5, thickness),
		Rotation = math.deg(math.atan2(d.Y, d.X)),
		BackgroundColor3 = color,
		ZIndex = 33,
		Parent = canvas,
	}, { Ui.corner(0.5) })
end

-- Trunk, boughs, branch lines, nodes and cards ---------------------------------------------

local TRUNK = Color3.fromRGB(175, 115, 70)
local count = #Config.UPGRADES
local trunkTop = Vector2.new(CANVAS_W / 2, CANVAS_H - 70)
line(Vector2.new(CANVAS_W / 2, CANVAS_H + 10), trunkTop, 36, TRUNK)
for _, side in ipairs({ -1, 1 }) do
	line(Vector2.new(CANVAS_W / 2, CANVAS_H), Vector2.new(CANVAS_W / 2 + side * 46, CANVAS_H + 8), 16, TRUNK)
end

local spacing = (CANVAS_W - 24) / count
local branches = {} -- [id] = { Nodes, Links, Card, parts of the card... }

local function cardText(parent, y, height, size, font, color)
	return Ui.new("TextLabel", {
		Position = UDim2.fromOffset(4, y),
		Size = UDim2.new(1, -8, 0, height),
		Font = font,
		TextScaled = false,
		TextSize = size,
		TextColor3 = color,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 36,
		Parent = parent,
	})
end

for i, upgrade in ipairs(Config.UPGRADES) do
	local x = 12 + spacing * (i - 0.5)
	local base = Vector2.new(x, CANVAS_H - 110 - math.abs(i - (count + 1) / 2) * 8)
	local top = Vector2.new(x, CARD_H + 26)
	line(trunkTop, base, 10, TRUNK)

	-- level nodes from the base up to the card
	local b = { Nodes = {}, Links = {} }
	local nodes = math.min(upgrade.Max, MAX_NODES)
	local previous = base
	for k = 1, nodes do
		local p = base:Lerp(top, k / nodes) + Vector2.new(if k % 2 == 0 then 5 else -5, 0)
		table.insert(b.Links, line(previous, p, 5, Ui.GLASS_LIGHT))
		previous = p
		local node = Ui.new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(p.X, p.Y),
			Size = UDim2.fromOffset(16, 16),
			BackgroundColor3 = Ui.GLASS_LIGHT,
			ZIndex = 34,
			Parent = canvas,
		}, { Ui.corner(0.5) })
		local stroke = Ui.stroke(Color3.new(1, 1, 1), 2, 0.5)
		stroke.Parent = node
		table.insert(b.Nodes, { Frame = node, Stroke = stroke, Level = math.ceil(k * upgrade.Max / nodes) })
	end

	-- the card at the top of the branch: click to buy
	local card = Ui.new("TextButton", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromOffset(x, 10),
		Size = UDim2.fromOffset(CARD_W, CARD_H),
		BackgroundColor3 = Color3.fromRGB(28, 32, 60),
		BackgroundTransparency = 0.1,
		AutoButtonColor = false,
		Text = "",
		ZIndex = 35,
		Parent = canvas,
	}, { Ui.corner(16) })
	local cardStroke = Ui.stroke(upgrade.Color, 2, 0.3)
	cardStroke.Parent = card
	local iconBack = Ui.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 7),
		Size = UDim2.fromOffset(34, 34),
		BackgroundColor3 = upgrade.Color,
		ZIndex = 36,
		Parent = card,
	}, { Ui.corner(0.5) })
	Ui.icon(upgrade.Icon, 20, Color3.new(1, 1, 1), { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), ZIndex = 37, Parent = iconBack })
	b.Name = cardText(card, 44, 15, 13, Ui.FONT, Ui.TEXT)
	b.Name.Text = upgrade.Name:upper()
	b.Level = cardText(card, 60, 14, 12, Ui.FONT_MEDIUM, Ui.MUTED)
	b.Step = cardText(card, 76, 14, 12, Ui.FONT, Ui.SUCCESS)
	b.Cost = cardText(card, 96, 22, 16, Ui.FONT, Ui.GOLD)
	b.Card, b.CardStroke, b.IconBack = card, cardStroke, iconBack
	b.Scale = Ui.new("UIScale", { Parent = card })
	card.Activated:Connect(function()
		UpgradeTree.select(upgrade.Id)
		UpgradeTree.buy()
	end)
	branches[upgrade.Id] = b
end

-- The bottom bar: the selected branch explained, and a big Buy button ------------------------------

local bar = Ui.new("Frame", {
	Position = UDim2.fromOffset(0, 62 + CANVAS_H + 12),
	Size = UDim2.new(1, 0, 0, HEIGHT - 44 - 62 - CANVAS_H - 12),
	BackgroundColor3 = Ui.GLASS_LIGHT,
	BackgroundTransparency = 0.35,
	ZIndex = 32,
	Parent = box,
}, { Ui.corner(16), Ui.padding(12) })
local barName = Ui.new("TextLabel", {
	Size = UDim2.new(1, -230, 0, 22),
	TextScaled = false,
	TextSize = 19,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 33,
	Parent = bar,
})
local barText = Ui.new("TextLabel", {
	Position = UDim2.fromOffset(0, 26),
	Size = UDim2.new(1, -230, 0, 34),
	Font = Ui.FONT_MEDIUM,
	TextScaled = false,
	TextSize = 14,
	TextWrapped = true,
	TextColor3 = Ui.MUTED,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	ZIndex = 33,
	Parent = bar,
})
local buyButton = Ui.button({
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, 0, 0.5, 0),
	Size = UDim2.fromOffset(210, 52),
	Radius = 18,
	Icon = "coin",
	Text = "BUY",
	TextSize = 18,
	ZIndex = 34,
	Parent = bar,
}, function()
	UpgradeTree.buy()
end, "primary")

-- Showing state ------------------------------------------------------------------------------------

local selected = Config.UPGRADES[1].Id

local function refresh()
	local data = State.Data
	if not data then
		return
	end
	coinsLine.Text = "You have " .. Config.formatNumber(data.Coins) .. " coins  ·  click a card to buy its next level"
	for _, upgrade in ipairs(Config.UPGRADES) do
		local b = branches[upgrade.Id]
		local level = Config.upgradeLevel(data, upgrade.Id)
		local ok, reason = Config.canUpgrade(data, upgrade.Id)
		local maxed = level >= upgrade.Max
		local cost = upgrade.Cost(level)
		local affordable = ok and data.Coins >= cost
		local locked = not ok and not maxed

		for k, node in ipairs(b.Nodes) do
			local owned = level >= node.Level
			node.Frame.BackgroundColor3 = if owned then upgrade.Color else Color3.fromRGB(80, 85, 115)
			node.Stroke.Color = if owned then Color3.new(1, 1, 1) else Color3.fromRGB(120, 125, 160)
			node.Stroke.Transparency = if owned then 0 else 0.5
			b.Links[k].BackgroundColor3 = if owned then upgrade.Color else Color3.fromRGB(80, 85, 115)
		end

		b.Level.Text = if maxed then "Lv " .. level .. "  ·  MAX" else "Lv " .. level .. " → " .. (level + 1)
		b.Step.Text = if maxed then upgrade.Format(upgrade.Value(level)) elseif locked then "LOCKED" else upgrade.Step
		b.Step.TextColor3 = if locked then Ui.DANGER else Ui.SUCCESS
		b.Cost.Text = if maxed then "DONE" elseif locked then (reason:gsub("^Needs ", "")) else Config.formatNumber(cost)
		b.Cost.TextSize = if locked then 12 else 16
		b.Cost.TextColor3 = if maxed then Ui.SUCCESS elseif locked then Ui.MUTED elseif affordable then Ui.GOLD else Color3.fromRGB(255, 150, 150)
		b.IconBack.BackgroundColor3 = if locked then Color3.fromRGB(95, 100, 130) else upgrade.Color
		b.CardStroke.Color = if upgrade.Id == selected then Color3.new(1, 1, 1) elseif affordable then Ui.GOLD else upgrade.Color
		b.CardStroke.Thickness = if upgrade.Id == selected or affordable then 3 else 2
		b.CardStroke.Transparency = if locked then 0.7 else 0.1
		b.Affordable = affordable
	end

	-- the selected branch in full
	local upgrade = Config.UPGRADES_BY_ID[selected]
	local level = Config.upgradeLevel(data, selected)
	local ok, reason = Config.canUpgrade(data, selected)
	local cost = upgrade.Cost(level)
	barName.Text = upgrade.Name .. "  ·  Level " .. level .. " of " .. upgrade.Max
	if level >= upgrade.Max then
		barText.Text = upgrade.Describe .. ". All levels bought: " .. upgrade.Format(upgrade.Value(level)) .. "."
		Ui.setText(buyButton, "MAXED")
		Ui.setStyle(buyButton, "disabled")
	else
		barText.Text = upgrade.Describe .. ". Now " .. upgrade.Format(upgrade.Value(level)) .. ", next level " .. upgrade.Format(upgrade.Value(level + 1)) .. "."
			.. (if ok then "" else "  " .. reason .. ".")
		Ui.setText(buyButton, "BUY  " .. Config.formatNumber(cost))
		Ui.setStyle(buyButton, if ok and data.Coins >= cost then "primary" else "disabled")
	end
end

function UpgradeTree.select(id)
	selected = id
	refresh()
end

function UpgradeTree.buy()
	if buyFunction:InvokeServer(selected) then
		Effects.jingle(2)
		local b = branches[selected]
		b.Scale.Scale = 1.12
		task.delay(0.12, function()
			b.Scale.Scale = 1
		end)
	else
		Effects.play("Click", 0.7)
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

-- affordable cards gently pulse
RunService.RenderStepped:Connect(function()
	if not modal.Visible then
		return
	end
	local pulse = 1 + math.sin(os.clock() * 4) * 0.025
	for id, b in pairs(branches) do
		if b.Affordable and b.Scale.Scale < 1.1 then
			b.Scale.Scale = pulse
		elseif not b.Affordable and id ~= selected then
			b.Scale.Scale = 1
		end
	end
end)

State.watch(function()
	if modal.Visible then
		refresh()
	end
end)

return UpgradeTree
