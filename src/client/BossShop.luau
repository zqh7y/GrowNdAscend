-- The Boss Shop screen (opened at the shop stall in the Lava Arena, where the
-- AFK spot was). Upgrades that only work on bosses, bought with coins
-- (Config.BOSS_UPGRADES; the server checks and charges: server/BossShop.luau):
--   Boss Damage   your pets hit bosses harder
--   Boss Coins    more coins from bosses
--   Boss EXP      more EXP from bosses
--   Boss Crits    a chance for any hit on a boss to do x3 damage
-- Each row: the icon, name, level, now -> next, a level bar and a BUY
-- button with the price (MAX when done).
local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local Effects = require(script.Parent.Effects)
local Screen = require(script.Parent.Screen)
local State = require(script.Parent.State)
local Ui = require(script.Parent.Ui)

local BossShop = {}

local buyFunction = State.remote("BuyBossUpgrade")

local LAVA = Color3.fromRGB(255, 120, 60)
local WIDTH, HEIGHT = 760, 520
local modal, box = Screen.modal(WIDTH, HEIGHT, { Color = LAVA, Icon = "sword" })
BossShop.Modal = modal
Screen.title(box, "Boss Shop")
Screen.subtitle(box, "Upgrades that only work on bosses")

local ROW_H = 96
local list = Screen.scrollList(box, 30, Ui.new("UIListLayout", {
	Padding = UDim.new(0, 10),
	SortOrder = Enum.SortOrder.LayoutOrder,
}))
BossShop.List = list

BossShop.Rows = {} -- [id] = { Level, Now, Bar, Buy }
BossShop.LastResult = nil -- (for the simulator: the server's answer)

local refresh

function BossShop.buy(id)
	local ok = buyFunction:InvokeServer(id)
	BossShop.LastResult = ok
	if ok then
		Effects.play("Coin", 1.2, 0.05)
	end
	return ok
end

for i, def in ipairs(Config.BOSS_UPGRADES) do
	local row = Ui.new("Frame", {
		Name = def.Id,
		LayoutOrder = i,
		Size = UDim2.new(1, 0, 0, ROW_H),
		BackgroundColor3 = Color3.fromRGB(255, 244, 236),
		ZIndex = 33,
		Parent = list,
	}, { Ui.corner(18) })
	Ui.stroke(def.Color:Lerp(Color3.new(1, 1, 1), 0.45), 2, 0).Parent = row
	local iconBack = Ui.new("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 14, 0.5, 0),
		Size = UDim2.fromOffset(66, 66),
		BackgroundColor3 = def.Color,
		ZIndex = 34,
		Parent = row,
	}, { Ui.corner(0.5) })
	Ui.icon(def.Icon, 38, Ui.WHITE, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		ZIndex = 35,
		Parent = iconBack,
	})
	Ui.chunky({
		Position = UDim2.fromOffset(94, 10),
		Size = UDim2.fromOffset(300, 30),
		TextSize = 26,
		Text = def.Name,
		TextXAlignment = Enum.TextXAlignment.Left,
		Outline = 2,
		ZIndex = 35,
		Parent = row,
	})
	local level = Ui.new("TextLabel", {
		Name = "Level",
		Position = UDim2.fromOffset(300, 14),
		Size = UDim2.fromOffset(110, 22),
		Font = Ui.FONT,
		TextScaled = false,
		TextSize = 16,
		TextColor3 = Ui.MUTED,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = "",
		ZIndex = 35,
		Parent = row,
	})
	local now = Ui.new("TextLabel", {
		Name = "Now",
		Position = UDim2.fromOffset(94, 42),
		Size = UDim2.fromOffset(410, 20),
		Font = Ui.FONT_MEDIUM,
		TextScaled = false,
		TextSize = 15,
		TextColor3 = Ui.TEXT,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = "",
		ZIndex = 35,
		Parent = row,
	})
	local barBack = Ui.new("Frame", {
		Position = UDim2.fromOffset(94, 70),
		Size = UDim2.fromOffset(400, 10),
		BackgroundColor3 = Color3.fromRGB(240, 222, 210),
		ZIndex = 35,
		Parent = row,
	}, { Ui.corner(0.5) })
	local bar = Ui.new("Frame", {
		Name = "Bar",
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = def.Color,
		ZIndex = 36,
		Parent = barBack,
	}, { Ui.corner(0.5) })
	local buy = Ui.button({
		Name = "Buy",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0.5, 0),
		Size = UDim2.fromOffset(170, 58),
		Text = "",
		Icon = "coin",
		TextSize = 20,
		ZIndex = 35,
		Parent = row,
	}, function()
		BossShop.buy(def.Id)
	end, "gold")
	BossShop.Rows[def.Id] = { Level = level, Now = now, Bar = bar, Buy = buy }
end

function refresh()
	local data = State.Data
	if not data then
		return
	end
	for _, def in ipairs(Config.BOSS_UPGRADES) do
		local row = BossShop.Rows[def.Id]
		local lvl = Config.bossUpgradeLevel(data, def.Id)
		row.Level.Text = "Lv " .. lvl .. " / " .. def.Max
		row.Bar.Size = UDim2.fromScale(lvl / def.Max, 1)
		if lvl >= def.Max then
			row.Now.Text = def.Format(def.Value(lvl)) .. "  ·  maxed!"
			Ui.setText(row.Buy, "MAX")
			Ui.setIcon(row.Buy, nil)
			Ui.setStyle(row.Buy, "disabled")
		else
			row.Now.Text = def.Format(def.Value(lvl)) .. "  →  " .. def.Format(def.Value(lvl + 1))
			local ok = Config.canBossUpgrade(data, def.Id)
			local cost = def.Cost(lvl)
			Ui.setText(row.Buy, Config.formatNumber(cost))
			Ui.setIcon(row.Buy, "coin")
			Ui.setStyle(row.Buy, if ok and data.Coins >= cost then "gold" else "disabled")
		end
	end
end
BossShop.refresh = refresh
State.watch(refresh)

function BossShop.open()
	Screen.open(modal)
	refresh()
end

-- The circle in front of the stall: standing on it opens the screen (like
-- the Fuse Machine's); stepping off closes it. Closed with the X, it stays
-- closed until you step off and back on.
local player = game:GetService("Players").LocalPlayer
local circlePart = nil
local dismissed = false
local openedHere = false
BossShop.OnCircle = false

local function findCircle()
	if not (circlePart and circlePart.Parent) then
		local map = workspace:FindFirstChild("Map")
		circlePart = map and map:FindFirstChild("BossShopCircle", true)
	end
	return circlePart
end

local function standingOn(circle)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return false
	end
	local c = circle.Position
	local flat = Vector3.new(root.Position.X - c.X, 0, root.Position.Z - c.Z)
	return flat.Magnitude <= circle.Size.Y / 2 + 0.5 and math.abs(root.Position.Y - c.Y) < 8
end

local function isOpen()
	return modal.Visible and not modal:GetAttribute("Closing")
end

function BossShop.check()
	local circle = findCircle()
	if not circle then
		return
	end
	local on = standingOn(circle)
	BossShop.OnCircle = on
	if on then
		local other = Screen.current()
		if not isOpen() and not dismissed and (other == nil or other == modal) then
			BossShop.open()
			openedHere = true
		end
	else
		dismissed = false
		if openedHere then
			openedHere = false
			if isOpen() then
				Screen.close(modal)
			end
		end
	end
end

local closeButton = box:FindFirstChild("Close")
if closeButton then
	closeButton.Activated:Connect(function()
		if BossShop.OnCircle then
			dismissed = true
		end
	end)
end

local since = 0
game:GetService("RunService").Heartbeat:Connect(function(dt)
	since += dt
	if since >= 0.15 then
		since = 0
		BossShop.check()
	end
end)

return BossShop
