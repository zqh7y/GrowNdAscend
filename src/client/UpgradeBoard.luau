-- The Upgrade Board: every upgrade in the game, on a real board standing in
-- the first area (like the upgrade walls in incremental games; it replaced
-- the upgrade tree screen). Walk up and click it.
--   LEFT    the sections: Damage, Coins, Luck and Rolls.
--   TOP     the section's total in big numbers (your damage, coins or luck
--           multiplier, or rolls at once) and your coins.
--   ROWS    each upgrade in the section: its icon, name, level, now -> next,
--           a level bar and a BUY button with the price (LOCKED with what it
--           needs, MAX when done). The Luck section also has the six Luck
--           Board rows (Config.LUCK_BOARD).
-- The server builds the stand (World.buildUpgradeBoard); this draws on it.
local TweenService = game:GetService("TweenService")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local Effects = require(script.Parent.Effects)
local State = require(script.Parent.State)
local Ui = require(script.Parent.Ui)

local UpgradeBoard = {}

local buyUpgrade = State.remote("BuyUpgrade")
local buyLuck = State.remote("BuyLuck")

-- What's on the board. An entry is an upgrade (Config.UPGRADES) or a Luck
-- Board row (Config.LUCK_BOARD).
local function upgrade(id)
	return { Kind = "upgrade", Id = id, Def = Config.UPGRADES_BY_ID[id] }
end
local function board(id)
	return { Kind = "board", Id = id, Def = Config.LUCK_BOARD_BY_ID[id] }
end
local luckEntries = { upgrade("Luck"), upgrade("SizeLuck") }
for _, item in ipairs(Config.LUCK_BOARD) do
	table.insert(luckEntries, board(item.Id))
end
UpgradeBoard.SECTIONS = {
	{ Name = "Damage", Icon = "sword", Color = Color3.fromRGB(240, 82, 96), Entries = { upgrade("Damage"), upgrade("Slots") } },
	{ Name = "Coins", Icon = "coin", Color = Color3.fromRGB(255, 186, 40), Entries = { upgrade("Coins") } },
	{ Name = "Luck", Icon = "clover", Color = Color3.fromRGB(46, 196, 120), Entries = luckEntries },
	{ Name = "Rolls", Icon = "dice", Color = Color3.fromRGB(64, 132, 255), Entries = { upgrade("RollSpeed"), upgrade("Rolls"), upgrade("AutoHatch") } },
}
local ENTRIES = {}
for _, section in ipairs(UpgradeBoard.SECTIONS) do
	for _, entry in ipairs(section.Entries) do
		entry.Section = section.Name
		ENTRIES[entry.Id] = entry
	end
end
UpgradeBoard.Entries = ENTRIES

local function plain(value)
	return Config.formatStat(value):sub(1, -2)
end

-- level, max, cost, can buy (ok, reason), "now", "next"
local function info(entry, data)
	local def = entry.Def
	if entry.Kind == "upgrade" then
		local level = Config.upgradeLevel(data, entry.Id)
		local ok, reason = Config.canUpgrade(data, entry.Id)
		return level, def.Max, def.Cost(level), ok, reason, def.Format(def.Value(level)), def.Format(def.Value(level + 1))
	end
	local level = Config.boardLevel(data, entry.Id)
	local ok, reason = Config.canBoard(data, entry.Id)
	return level, def.Max, Config.boardCost(def, level), ok, reason,
		"x" .. plain(Config.boardValue(def, level)) .. " luck", "x" .. plain(Config.boardValue(def, level + 1)) .. " luck"
end

-- "locked" | "available" | "affordable" | "maxed"
local function stateOf(entry, data)
	local level, max, cost, ok = info(entry, data)
	if level >= max then
		return "maxed"
	elseif not ok then
		return "locked"
	end
	return if data.Coins >= cost then "affordable" else "available"
end
UpgradeBoard.stateOf = stateOf

-- the big number at the top of a section
function UpgradeBoard.sectionValue(name, data)
	local function times(v)
		return "x" .. (if v < 1000 then plain(v) else Config.formatNumber(v))
	end
	if name == "Damage" then
		return times(Config.upgradeValue(data, "Damage")) .. " damage"
	elseif name == "Coins" then
		return times(Config.coinGain(data)) .. " coins"
	elseif name == "Luck" then
		return times(Config.luck(data, false, 1, 1)) .. " luck"
	end
	return Config.rollsAtOnce(data) .. " at once · " .. string.format("%.2gs", Config.rollCooldown(data))
end

-- The board's screen (20 x 15 studs, 40 pixels a stud) ----------------------------------------

local screenPart = workspace:WaitForChild("Map"):WaitForChild("UpgradeBoard"):WaitForChild("Screen")
local gui = Ui.new("SurfaceGui", {
	Name = "UpgradeBoardGui",
	Adornee = screenPart,
	Face = Enum.NormalId.Front,
	SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud,
	PixelsPerStud = 40,
	LightInfluence = 0,
	MaxDistance = 100,
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui"),
})
UpgradeBoard.Gui = gui
local box = Ui.new("Frame", {
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.fromRGB(246, 250, 247),
	ZIndex = 31,
	Parent = gui,
}, { Ui.padding(14) })

-- the sections, down the left
local TAB_W = 150
local tabs = Ui.new("Frame", {
	Size = UDim2.new(0, TAB_W, 1, 0),
	BackgroundTransparency = 1,
	ZIndex = 32,
	Parent = box,
}, { Ui.new("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }) })
local tabButtons = {}
local selectSection

for i, section in ipairs(UpgradeBoard.SECTIONS) do
	local tab = Ui.new("TextButton", {
		Name = section.Name,
		LayoutOrder = i,
		Size = UDim2.new(1, 0, 0, 96),
		BackgroundColor3 = section.Color,
		AutoButtonColor = false,
		Text = "",
		ZIndex = 33,
		Parent = tabs,
	}, { Ui.corner(18) })
	local edge = Ui.stroke(Ui.OUTLINE, 0, 0)
	edge.Parent = tab
	Ui.icon(section.Icon, 40, Ui.WHITE, { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 12), ZIndex = 34, Parent = tab })
	Ui.chunky({
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -8),
		Size = UDim2.new(1, 0, 0, 28),
		TextSize = 24,
		Text = string.upper(section.Name),
		Outline = 2,
		ZIndex = 34,
		Parent = tab,
	})
	local dot = Ui.new("Frame", {
		Name = "Dot",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(1, -10, 0, 10),
		Size = UDim2.fromOffset(18, 18),
		BackgroundColor3 = Ui.GOLD,
		Visible = false,
		ZIndex = 35,
		Parent = tab,
	}, { Ui.corner(0.5), Ui.stroke(Ui.OUTLINE, 2) })
	local scale = Ui.new("UIScale", { Parent = tab })
	tab.Activated:Connect(function()
		Effects.play("Click", 1.1, 0.05)
		selectSection(section.Name)
	end)
	tabButtons[section.Name] = { Button = tab, Edge = edge, Dot = dot, Scale = scale, Section = section }
end

-- the section's total, big, at the top
local RIGHT_X = TAB_W + 14
local header = Ui.new("Frame", {
	Position = UDim2.fromOffset(RIGHT_X, 0),
	Size = UDim2.new(1, -RIGHT_X, 0, 64),
	BackgroundColor3 = Ui.WHITE,
	ZIndex = 32,
	Parent = box,
}, { Ui.corner(18), Ui.new("UIGradient", { Name = "Tint", Rotation = 90 }) })
local headerIcon = Ui.new("Frame", {
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 14, 0.5, 0),
	Size = UDim2.fromOffset(40, 40),
	BackgroundTransparency = 1,
	ZIndex = 33,
	Parent = header,
})
local headerTitle = Ui.chunky({
	Position = UDim2.fromOffset(66, 4),
	Size = UDim2.new(0.6, -66, 0, 22),
	TextSize = 18,
	TextXAlignment = Enum.TextXAlignment.Left,
	Outline = 2,
	ZIndex = 33,
	Parent = header,
})
local totalText = Ui.chunky({
	Name = "Total",
	Position = UDim2.fromOffset(66, 24),
	Size = UDim2.new(1, -80, 0, 36),
	TextSize = 32,
	TextXAlignment = Enum.TextXAlignment.Left,
	Outline = 3,
	ZIndex = 33,
	Parent = header,
})
local coinsLine = Ui.chunky({
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -14, 0, 6),
	Size = UDim2.fromOffset(260, 22),
	TextSize = 18,
	TextXAlignment = Enum.TextXAlignment.Right,
	Outline = 2,
	ZIndex = 33,
	Parent = header,
})
local totalScale = Ui.new("UIScale", { Parent = header })
UpgradeBoard.Total = totalText

-- the rows
local list = Ui.new("Frame", {
	Position = UDim2.fromOffset(RIGHT_X, 72),
	Size = UDim2.new(1, -RIGHT_X, 1, -72),
	BackgroundTransparency = 1,
	ZIndex = 32,
	Parent = box,
}, { Ui.new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }) })

UpgradeBoard.Rows = {} -- the rows on the board now: [id] = { Row, Info, Buy, ... }
UpgradeBoard.States = {} -- every entry's state (all sections)
UpgradeBoard.Section = nil

local function makeRow(entry, order, height)
	local def = entry.Def
	local color = def.Color
	local row = Ui.new("Frame", {
		Name = entry.Id,
		LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, height),
		BackgroundColor3 = Ui.GLASS_LIGHT,
		ZIndex = 33,
		Parent = list,
	}, { Ui.corner(14) })
	local edge = Ui.stroke(Ui.LINE, 2, 0)
	edge.Parent = row
	local tileSize = height - 12
	local tile = Ui.new("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 8, 0.5, 0),
		Size = UDim2.fromOffset(tileSize, tileSize),
		BackgroundColor3 = color,
		ZIndex = 34,
		Parent = row,
	}, { Ui.corner(12) })
	Ui.icon(def.Icon, math.floor(tileSize * 0.6), Ui.WHITE, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), ZIndex = 35, Parent = tile })
	local x = tileSize + 18
	local name = Ui.new("TextLabel", {
		Position = UDim2.fromOffset(x, 4),
		Size = UDim2.new(1, -x - 170, 0, 22),
		Font = Ui.FONT_DISPLAY,
		TextScaled = false,
		TextSize = 20,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Ui.INK,
		Text = def.Name,
		ZIndex = 34,
		Parent = row,
	})
	local infoLabel = Ui.new("TextLabel", {
		Name = "Info",
		Position = UDim2.fromOffset(x, 26),
		Size = UDim2.new(1, -x - 170, 0, 16),
		Font = Ui.FONT,
		TextScaled = false,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Ui.MUTED,
		ZIndex = 34,
		Parent = row,
	})
	local track = Ui.new("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, x, 1, -6),
		Size = UDim2.new(1, -x - 170, 0, 6),
		BackgroundColor3 = Color3.fromRGB(224, 228, 238),
		ZIndex = 34,
		Parent = row,
	}, { Ui.corner(3) })
	local bar = Ui.new("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = color,
		ZIndex = 35,
		Parent = track,
	}, { Ui.corner(3) })
	local buy = Ui.button({
		Name = "Buy",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		Size = UDim2.fromOffset(150, height - 14),
		Radius = 14,
		Icon = "coin",
		Text = "",
		TextSize = 17,
		ZIndex = 36,
		Parent = row,
	}, function()
		UpgradeBoard.buy(entry.Id)
	end, "disabled")
	return { Row = row, Edge = edge, Tile = tile, Name = name, Info = infoLabel, Bar = bar, Buy = buy, Scale = Ui.new("UIScale", { Parent = row }), Color = color }
end

local shownTotal = nil
local function refresh()
	local data = State.Data
	if not data or not UpgradeBoard.Section then
		return
	end
	coinsLine.Text = Config.formatNumber(data.Coins) .. " coins"
	local section
	for _, s in ipairs(UpgradeBoard.SECTIONS) do
		if s.Name == UpgradeBoard.Section then
			section = s
		end
	end
	local value = UpgradeBoard.sectionValue(section.Name, data)
	if shownTotal and shownTotal ~= value and not Ui.reduced() then
		totalScale.Scale = 1.06
		TweenService:Create(totalScale, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	end
	shownTotal = value
	totalText.Text = value
	-- every entry's state; a gold dot on sections with something to buy
	for name, tab in pairs(tabButtons) do
		local any = false
		for _, entry in ipairs(tab.Section.Entries) do
			local state = stateOf(entry, data)
			UpgradeBoard.States[entry.Id] = state
			if state == "affordable" then
				any = true
			end
		end
		tab.Dot.Visible = any
		local on = name == section.Name
		tab.Edge.Thickness = if on then 4 else 0
		tab.Button.BackgroundColor3 = if on then tab.Section.Color else tab.Section.Color:Lerp(Ui.WHITE, 0.35)
	end
	for _, entry in ipairs(section.Entries) do
		local r = UpgradeBoard.Rows[entry.Id]
		if r then
			local level, max, cost, _, reason, now, nextText = info(entry, data)
			local state = UpgradeBoard.States[entry.Id]
			local locked, maxed = state == "locked", state == "maxed"
			r.Info.Text = if locked then reason
				elseif maxed then "Lv " .. level .. "/" .. max .. "  ·  " .. now .. "  ·  MAX"
				else "Lv " .. level .. "/" .. max .. "  ·  " .. now .. " → " .. nextText
			r.Bar.Size = UDim2.fromScale(level / max, 1)
			r.Row.BackgroundColor3 = if locked then Color3.fromRGB(236, 238, 244) else Ui.GLASS_LIGHT
			r.Tile.BackgroundColor3 = if locked then Color3.fromRGB(190, 196, 210) elseif maxed then Ui.GOLD else r.Color
			r.Name.TextColor3 = if locked then Ui.MUTED else Ui.INK
			r.Edge.Color = if maxed then Ui.GOLD elseif state == "affordable" then r.Color else Ui.LINE
			if maxed then
				Ui.setText(r.Buy, "MAX")
				Ui.setStyle(r.Buy, "gold")
			elseif locked then
				Ui.setText(r.Buy, "LOCKED")
				Ui.setStyle(r.Buy, "disabled")
			else
				Ui.setText(r.Buy, Config.formatNumber(cost))
				Ui.setStyle(r.Buy, if state == "affordable" then "success" else "disabled")
			end
		end
	end
end
UpgradeBoard.refresh = refresh

-- Shows a section's rows
function selectSection(name)
	local section
	for _, s in ipairs(UpgradeBoard.SECTIONS) do
		if s.Name == name then
			section = s
		end
	end
	if not section then
		return
	end
	UpgradeBoard.Section = name
	shownTotal = nil
	for _, child in ipairs(list:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	UpgradeBoard.Rows = {}
	local count = #section.Entries
	-- rows share the 500 pixels under the header (never taller than 96)
	local height = math.clamp(math.floor((500 - (count - 1) * 4) / math.max(count, 4)), 48, 96)
	for i, entry in ipairs(section.Entries) do
		UpgradeBoard.Rows[entry.Id] = makeRow(entry, i, height)
	end
	header.Tint.Color = ColorSequence.new(section.Color:Lerp(Ui.WHITE, 0.25), section.Color)
	headerIcon:ClearAllChildren()
	Ui.icons[section.Icon](headerIcon, Ui.WHITE)
	headerTitle.Text = string.upper(name)
	refresh()
end
UpgradeBoard.select = selectSection

-- Buys the next level of an entry (the server checks and charges)
function UpgradeBoard.buy(id)
	local entry = ENTRIES[id]
	if not entry then
		return false
	end
	local remote = if entry.Kind == "board" then buyLuck else buyUpgrade
	local ok = remote:InvokeServer(id)
	local r = UpgradeBoard.Rows[id]
	if ok then
		Effects.jingle(2)
		if r and not Ui.reduced() then
			r.Scale.Scale = 1.04
			TweenService:Create(r.Scale, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Scale = 1 }):Play()
		end
	else
		Effects.play("Click", 0.7)
	end
	refresh()
	return ok
end

-- true if anything on the board can be bought now
function UpgradeBoard.anyAffordable()
	local data = State.Data
	if not data then
		return false
	end
	for _, entry in pairs(ENTRIES) do
		if stateOf(entry, data) == "affordable" then
			return true
		end
	end
	return false
end

selectSection("Damage")
State.watch(refresh)

return UpgradeBoard
