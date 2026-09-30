-- The upgrade tree. A trunk at the bottom splits into one branch per upgrade
-- (Config.UPGRADES, so new branches appear automatically). Each branch has an
-- icon where it leaves the trunk and a node per level going up: filled when
-- bought, glowing when it's the next one you can buy, grey with a lock when
-- it needs something first. Pick a branch to see what it does, what the next
-- level gives, and buy it.
local RunService = game:GetService("RunService")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local Ui = require(script.Parent.Ui)
local Screen = require(script.Parent.Screen)
local State = require(script.Parent.State)
local Effects = require(script.Parent.Effects)

local UpgradeTree = {}

local buyFunction = State.remote("BuyUpgrade")

local WIDTH, HEIGHT = 900, 580
local CANVAS_W, CANVAS_H = 560, 476
local NODE = 22

local modal, box = Screen.modal(WIDTH, HEIGHT)
Screen.title(box, "Upgrade Tree")
local coinsLine = Screen.subtitle(box, "")

-- the tree drawing on the left, details on the right
local canvas = Ui.new("Frame", {
	Position = UDim2.fromOffset(0, 64),
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
	Transparency = NumberSequence.new(0.3, 0.1),
	Parent = canvas,
})

local details = Ui.glass({
	Position = UDim2.fromOffset(CANVAS_W + 16, 64),
	Size = UDim2.fromOffset(WIDTH - 44 - CANVAS_W - 16, CANVAS_H),
	Radius = 18,
	ZIndex = 32,
	Parent = box,
}, { Ui.padding(18) })

-- a straight line between two points on the canvas
local function line(from, to, thickness, color, z)
	local d = to - from
	return Ui.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset((from.X + to.X) / 2, (from.Y + to.Y) / 2),
		Size = UDim2.fromOffset(d.Magnitude + thickness * 0.5, thickness),
		Rotation = math.deg(math.atan2(d.Y, d.X)),
		BackgroundColor3 = color,
		ZIndex = z or 33,
		Parent = canvas,
	}, { Ui.corner(0.5) })
end

-- Layout: the trunk, and where each branch starts and how high it goes ------------------

local count = #Config.UPGRADES
local trunkTop = Vector2.new(CANVAS_W / 2, CANVAS_H - 120)
local trunkBase = Vector2.new(CANVAS_W / 2, CANVAS_H + 10)
local TRUNK = Color3.fromRGB(175, 115, 70)
line(trunkBase, trunkTop, 34, TRUNK, 33)
for _, side in ipairs({ -1, 1 }) do
	line(trunkBase + Vector2.new(0, -10), trunkBase + Vector2.new(side * 40, 0), 16, TRUNK, 33) -- roots
end

local branches = {} -- [id] = { Nodes = { frame }, Links = { frame }, Icon, Base }
local spacing = (CANVAS_W - 60) / count
for i, upgrade in ipairs(Config.UPGRADES) do
	local x = 30 + spacing * (i - 0.5)
	local base = Vector2.new(x, CANVAS_H - 150 - math.abs(i - (count + 1) / 2) * 6)
	-- bough from the trunk out to the branch's icon
	line(trunkTop, base, 10, TRUNK, 33)
	local b = { Nodes = {}, Links = {}, Base = base }
	-- level nodes going up from the icon, spread to fit the canvas
	local top = 40
	local step = math.min((base.Y - 40 - top) / math.max(upgrade.Max, 1), 36)
	local previous = base
	for level = 1, upgrade.Max do
		local p = Vector2.new(x + (if level % 2 == 0 then 6 else -6), base.Y - 30 - (level - 1) * step)
		table.insert(b.Links, line(previous, p, 5, Ui.GLASS_LIGHT, 33))
		previous = p
		local node = Ui.new("TextButton", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(p.X, p.Y),
			Size = UDim2.fromOffset(NODE, NODE),
			BackgroundColor3 = Ui.GLASS_LIGHT,
			BackgroundTransparency = 0,
			AutoButtonColor = false,
			Text = "",
			TextSize = 11,
			TextScaled = false,
			ZIndex = 35,
			Parent = canvas,
		}, { Ui.corner(0.5) })
		local stroke = Ui.stroke(Color3.new(1, 1, 1), 2, 0.6)
		stroke.Parent = node
		node.Activated:Connect(function()
			UpgradeTree.select(upgrade.Id)
		end)
		table.insert(b.Nodes, { Button = node, Stroke = stroke })
	end
	-- the branch icon where it meets the bough
	local icon = Ui.new("TextButton", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(base.X, base.Y),
		Size = UDim2.fromOffset(44, 44),
		BackgroundColor3 = upgrade.Color,
		BackgroundTransparency = 0,
		AutoButtonColor = false,
		Text = "",
		ZIndex = 36,
		Parent = canvas,
	}, { Ui.corner(0.5) })
	local iconStroke = Ui.stroke(Color3.new(1, 1, 1), 3, 0)
	iconStroke.Parent = icon
	Ui.icon(upgrade.Icon, 24, Color3.new(1, 1, 1), {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		ZIndex = 37,
		Parent = icon,
	})
	local levelBadge = Ui.new("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 1, 2),
		Size = UDim2.fromOffset(46, 16),
		BackgroundColor3 = Color3.fromRGB(25, 28, 50),
		BackgroundTransparency = 0.2,
		TextScaled = false,
		TextSize = 11,
		ZIndex = 37,
		Parent = icon,
	}, { Ui.corner(8) })
	icon.Activated:Connect(function()
		UpgradeTree.select(upgrade.Id)
	end)
	b.Icon = icon
	b.IconStroke = iconStroke
	b.Badge = levelBadge
	branches[upgrade.Id] = b
end

-- Details ------------------------------------------------------------------------------

local detailIcon = Ui.new("Frame", {
	Size = UDim2.fromOffset(64, 64),
	ZIndex = 33,
	Parent = details,
}, { Ui.corner(0.5) })
local detailName = Ui.new("TextLabel", {
	Position = UDim2.fromOffset(76, 4),
	Size = UDim2.new(1, -76, 0, 28),
	TextScaled = false,
	TextSize = 24,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 33,
	Parent = details,
})
local detailLevel = Ui.new("TextLabel", {
	Position = UDim2.fromOffset(76, 36),
	Size = UDim2.new(1, -76, 0, 18),
	Font = Ui.FONT_MEDIUM,
	TextScaled = false,
	TextSize = 15,
	TextColor3 = Ui.MUTED,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 33,
	Parent = details,
})
local detailDescribe = Ui.new("TextLabel", {
	Position = UDim2.fromOffset(0, 80),
	Size = UDim2.new(1, 0, 0, 44),
	Font = Ui.FONT_MEDIUM,
	TextScaled = false,
	TextSize = 15,
	TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	ZIndex = 33,
	Parent = details,
})

-- now -> next
local function effectBox(y, caption)
	local frame = Ui.new("Frame", {
		Position = UDim2.fromOffset(0, y),
		Size = UDim2.new(1, 0, 0, 54),
		BackgroundColor3 = Ui.GLASS_LIGHT,
		BackgroundTransparency = 0.35,
		ZIndex = 33,
		Parent = details,
	}, { Ui.corner(14) })
	Ui.new("TextLabel", {
		Position = UDim2.fromOffset(12, 6),
		Size = UDim2.new(1, -24, 0, 14),
		Font = Ui.FONT_MEDIUM,
		TextScaled = false,
		TextSize = 12,
		Text = caption,
		TextColor3 = Ui.MUTED,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 34,
		Parent = frame,
	})
	return Ui.new("TextLabel", {
		Position = UDim2.fromOffset(12, 22),
		Size = UDim2.new(1, -24, 0, 24),
		TextScaled = false,
		TextSize = 19,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 34,
		Parent = frame,
	})
end
local nowText = effectBox(136, "NOW")
local nextText = effectBox(198, "NEXT LEVEL")
local needText = Ui.new("TextLabel", {
	Position = UDim2.fromOffset(0, 264),
	Size = UDim2.new(1, 0, 0, 20),
	Font = Ui.FONT_MEDIUM,
	TextScaled = false,
	TextSize = 14,
	TextColor3 = Ui.DANGER,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 33,
	Parent = details,
})
local buyButton = Ui.button({
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, 0),
	Size = UDim2.new(1, 0, 0, 58),
	Radius = 20,
	Icon = "coin",
	Text = "BUY",
	TextSize = 20,
	ZIndex = 34,
	Parent = details,
}, function()
	UpgradeTree.buy()
end, "primary")

-- Showing state ------------------------------------------------------------------------------

local selected = Config.UPGRADES[1].Id
local pulse = 0

local function refresh()
	local data = State.Data
	if not data then
		return
	end
	coinsLine.Text = "You have " .. Config.formatNumber(data.Coins) .. " coins  ·  pick a branch, buy the glowing node"
	for _, upgrade in ipairs(Config.UPGRADES) do
		local b = branches[upgrade.Id]
		local level = Config.upgradeLevel(data, upgrade.Id)
		local canBuy = Config.canUpgrade(data, upgrade.Id)
		local affordable = canBuy and data.Coins >= upgrade.Cost(level)
		for i, node in ipairs(b.Nodes) do
			local owned = i <= level
			local isNext = i == level + 1
			node.Button.BackgroundColor3 = if owned then upgrade.Color elseif isNext and canBuy then Color3.new(1, 1, 1) else Color3.fromRGB(80, 85, 115)
			node.Button.Text = if owned then tostring(i) else ""
			node.Button.TextColor3 = Color3.new(1, 1, 1)
			node.Stroke.Color = if isNext and affordable then Ui.GOLD elseif owned then Color3.new(1, 1, 1) else Color3.fromRGB(120, 125, 160)
			node.Stroke.Transparency = if owned or isNext then 0 else 0.5
			node.Stroke.Thickness = if isNext and canBuy then 3 else 2
			b.Links[i].BackgroundColor3 = if owned then upgrade.Color else Color3.fromRGB(80, 85, 115)
		end
		b.Icon.BackgroundColor3 = if canBuy or level > 0 then upgrade.Color else Color3.fromRGB(95, 100, 130)
		b.IconStroke.Color = if upgrade.Id == selected then Ui.GOLD else Color3.new(1, 1, 1)
		b.IconStroke.Thickness = if upgrade.Id == selected then 4 else 2
		b.Badge.Text = if level >= upgrade.Max then "MAX" elseif not canBuy and level == 0 then "LOCKED" else level .. "/" .. upgrade.Max
		b.Badge.TextColor3 = if affordable then Ui.GOLD else Ui.TEXT
	end

	-- details of the selected branch
	local upgrade = Config.UPGRADES_BY_ID[selected]
	local level = Config.upgradeLevel(data, selected)
	local ok, reason = Config.canUpgrade(data, selected)
	local cost = upgrade.Cost(level)
	detailIcon:ClearAllChildren()
	Ui.corner(0.5).Parent = detailIcon
	detailIcon.BackgroundColor3 = upgrade.Color
	Ui.icon(upgrade.Icon, 36, Color3.new(1, 1, 1), { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), ZIndex = 34, Parent = detailIcon })
	detailName.Text = upgrade.Name
	detailLevel.Text = "Level " .. level .. " of " .. upgrade.Max
	detailDescribe.Text = upgrade.Describe
	nowText.Text = upgrade.Format(upgrade.Value(level))
	if level >= upgrade.Max then
		nextText.Text = "All done!"
		nextText.TextColor3 = Ui.MUTED
	else
		nextText.Text = upgrade.Format(upgrade.Value(level + 1))
		nextText.TextColor3 = Ui.SUCCESS
	end
	needText.Text = if ok or level >= upgrade.Max then "" else reason
	if level >= upgrade.Max then
		Ui.setText(buyButton, "MAXED")
		Ui.setStyle(buyButton, "disabled")
	else
		Ui.setText(buyButton, "BUY  " .. Config.formatNumber(cost))
		Ui.setStyle(buyButton, if ok and data.Coins >= cost then "primary" else "disabled")
	end
end

function UpgradeTree.select(id)
	selected = id
	Effects.play("Click", 1.2)
	refresh()
end

function UpgradeTree.buy()
	if buyFunction:InvokeServer(selected) then
		Effects.jingle(2)
	end
end

function UpgradeTree.open()
	-- start on something worth buying
	local data = State.Data
	if data then
		for _, upgrade in ipairs(Config.UPGRADES) do
			if Config.canUpgrade(data, upgrade.Id) and data.Coins >= upgrade.Cost(Config.upgradeLevel(data, upgrade.Id)) then
				selected = upgrade.Id
				break
			end
		end
	end
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

-- the next node you can buy gently pulses
RunService.RenderStepped:Connect(function(dt)
	if not modal.Visible or not State.Data then
		return
	end
	pulse += dt * 4
	local s = NODE + math.sin(pulse) * 3
	for _, upgrade in ipairs(Config.UPGRADES) do
		local level = Config.upgradeLevel(State.Data, upgrade.Id)
		local node = branches[upgrade.Id].Nodes[level + 1]
		if node then
			node.Button.Size = UDim2.fromOffset(s, s)
		end
	end
end)

State.watch(function()
	if modal.Visible then
		refresh()
	end
end)

return UpgradeTree
