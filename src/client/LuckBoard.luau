-- The Luck Board: a real board standing in the first area (like the
-- upgrade walls in incremental games). Walk up to it and click its rows:
-- six luck multipliers (Config.LUCK_BOARD) you level up with coins; each
-- unlocks when the row before reaches level 5. At the top, everything the
-- board gives together in big numbers ("x492"). The server builds the
-- stand (World.buildLuckBoard); this draws on its screen part.
local TweenService = game:GetService("TweenService")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local Effects = require(script.Parent.Effects)
local State = require(script.Parent.State)
local Ui = require(script.Parent.Ui)

local LuckBoard = {}

local buyFunction = State.remote("BuyLuck")

-- the board's screen in the world (16 x 12.5 studs; 40 pixels a stud)
local screenPart = workspace:WaitForChild("Map"):WaitForChild("LuckBoard"):WaitForChild("Screen")
local gui = Ui.new("SurfaceGui", {
	Name = "LuckBoardGui",
	Adornee = screenPart,
	Face = Enum.NormalId.Front,
	SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud,
	PixelsPerStud = 40,
	LightInfluence = 0,
	MaxDistance = 90,
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui"),
})
LuckBoard.Gui = gui
local box = Ui.new("Frame", {
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.fromRGB(246, 250, 247),
	ZIndex = 31,
	Parent = gui,
}, { Ui.padding(14) })

-- the board's total, big
local total = Ui.new("Frame", {
	Size = UDim2.new(1, 0, 0, 64),
	BackgroundColor3 = Ui.WHITE,
	ZIndex = 32,
	Parent = box,
}, {
	Ui.corner(18),
	Ui.new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(110, 226, 120), Color3.fromRGB(34, 156, 74)) }),
})
Ui.icon("clover", 40, Color3.fromRGB(200, 255, 200), { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 16, 0.5, 0), ZIndex = 33, Parent = total })
Ui.chunky({
	Position = UDim2.fromOffset(68, 4),
	Size = UDim2.new(1, -80, 0, 22),
	TextSize = 18,
	Text = "LUCK FROM THE BOARD",
	TextXAlignment = Enum.TextXAlignment.Left,
	Outline = 2,
	ZIndex = 33,
	Parent = total,
})
local coinsLine = Ui.chunky({
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -14, 0, 6),
	Size = UDim2.fromOffset(240, 20),
	TextSize = 16,
	TextXAlignment = Enum.TextXAlignment.Right,
	Outline = 1.5,
	ZIndex = 33,
	Parent = total,
})
local totalText = Ui.chunky({
	Name = "Total",
	Position = UDim2.fromOffset(68, 24),
	Size = UDim2.new(1, -80, 0, 36),
	TextSize = 34,
	Text = "x1",
	TextXAlignment = Enum.TextXAlignment.Left,
	Outline = 3,
	ZIndex = 33,
	Parent = total,
})
local totalScale = Ui.new("UIScale", { Parent = total })
LuckBoard.Total = totalText

-- the rows
local list = Ui.new("Frame", {
	Position = UDim2.fromOffset(0, 72),
	Size = UDim2.new(1, 0, 1, -72),
	BackgroundTransparency = 1,
	ZIndex = 32,
	Parent = box,
}, { Ui.new("UIListLayout", { Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder }) })

local rows = {}
LuckBoard.Rows = rows
for i, item in ipairs(Config.LUCK_BOARD) do
	local row = Ui.new("Frame", {
		Name = item.Id,
		LayoutOrder = i,
		Size = UDim2.new(1, 0, 0, 62),
		BackgroundColor3 = Ui.GLASS_LIGHT,
		ZIndex = 33,
		Parent = list,
	}, { Ui.corner(16) })
	local edge = Ui.stroke(Ui.LINE, 2, 0)
	edge.Parent = row
	local tile = Ui.new("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 12, 0.5, 0),
		Size = UDim2.fromOffset(46, 46),
		BackgroundColor3 = item.Color,
		ZIndex = 34,
		Parent = row,
	}, { Ui.corner(14) })
	Ui.icon(item.Icon, 28, Ui.WHITE, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), ZIndex = 35, Parent = tile })
	local name = Ui.new("TextLabel", {
		Position = UDim2.fromOffset(70, 5),
		Size = UDim2.new(1, -260, 0, 22),
		Font = Ui.FONT_DISPLAY,
		TextScaled = false,
		TextSize = 20,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Ui.INK,
		Text = item.Name,
		ZIndex = 34,
		Parent = row,
	})
	local info = Ui.new("TextLabel", {
		Name = "Info",
		Position = UDim2.fromOffset(70, 27),
		Size = UDim2.new(1, -260, 0, 18),
		Font = Ui.FONT,
		TextScaled = false,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Ui.MUTED,
		ZIndex = 34,
		Parent = row,
	})
	-- level bar
	local track = Ui.new("Frame", {
		Position = UDim2.fromOffset(70, 47),
		Size = UDim2.new(1, -260, 0, 8),
		BackgroundColor3 = Color3.fromRGB(224, 228, 238),
		ZIndex = 34,
		Parent = row,
	}, { Ui.corner(4) })
	local bar = Ui.new("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = item.Color,
		ZIndex = 35,
		Parent = track,
	}, { Ui.corner(4) })
	local buy = Ui.button({
		Name = "Buy",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.fromOffset(150, 44),
		Radius = 16,
		Icon = "coin",
		Text = "",
		TextSize = 17,
		ZIndex = 36,
		Parent = row,
	}, function()
		LuckBoard.buy(item.Id)
	end, "disabled")
	rows[item.Id] = { Row = row, Edge = edge, Tile = tile, Name = name, Info = info, Bar = bar, Buy = buy, Scale = Ui.new("UIScale", { Parent = row }) }
end

local shownTotal = nil
local function refresh()
	local data = State.Data
	if not data then
		return
	end
	coinsLine.Text = Config.formatNumber(data.Coins) .. " coins"
	local luck = Config.boardLuck(data)
	totalText.Text = "x" .. (if luck < 1000 then Config.formatStat(luck):sub(1, -2) else Config.formatNumber(luck))
	if shownTotal and luck > shownTotal + 1e-9 and not Ui.reduced() then
		totalScale.Scale = 1.08
		TweenService:Create(totalScale, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	end
	shownTotal = luck
	for _, item in ipairs(Config.LUCK_BOARD) do
		local r = rows[item.Id]
		local level = Config.boardLevel(data, item.Id)
		local ok, reason = Config.canBoard(data, item.Id)
		local maxed = level >= item.Max
		local locked = not ok and not maxed
		local cost = Config.boardCost(item, level)
		local now, nextValue = Config.boardValue(item, level), Config.boardValue(item, level + 1)
		r.Info.Text = if locked then reason
			elseif maxed then "Lv " .. level .. "/" .. item.Max .. "  ·  x" .. Config.formatStat(now):sub(1, -2) .. " luck  ·  MAX"
			else "Lv " .. level .. "/" .. item.Max .. "  ·  x" .. Config.formatStat(now):sub(1, -2) .. " → x" .. Config.formatStat(nextValue):sub(1, -2) .. " luck"
		r.Bar.Size = UDim2.fromScale(level / item.Max, 1)
		r.Row.BackgroundColor3 = if locked then Color3.fromRGB(236, 238, 244) else Ui.GLASS_LIGHT
		r.Tile.BackgroundColor3 = if locked then Color3.fromRGB(190, 196, 210) elseif maxed then Ui.GOLD else item.Color
		r.Name.TextColor3 = if locked then Ui.MUTED else Ui.INK
		local affordable = ok and data.Coins >= cost
		r.Edge.Color = if maxed then Ui.GOLD elseif affordable then item.Color else Ui.LINE
		if maxed then
			Ui.setText(r.Buy, "MAX")
			Ui.setStyle(r.Buy, "gold")
		elseif locked then
			Ui.setText(r.Buy, "LOCKED")
			Ui.setStyle(r.Buy, "disabled")
		else
			Ui.setText(r.Buy, Config.formatNumber(cost))
			Ui.setStyle(r.Buy, if affordable then "success" else "disabled")
		end
	end
end
LuckBoard.refresh = refresh

-- Buys the next level of a row (the server checks and charges)
function LuckBoard.buy(id)
	local r = rows[id]
	if buyFunction:InvokeServer(id) then
		Effects.jingle(2)
		if r and not Ui.reduced() then
			r.Scale.Scale = 1.04
			TweenService:Create(r.Scale, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Scale = 1 }):Play()
		end
	else
		Effects.play("Click", 0.7)
	end
	refresh()
end

-- true if a row can be bought now (the HUD shows a dot)
function LuckBoard.anyAffordable()
	local data = State.Data
	if not data then
		return false
	end
	for _, item in ipairs(Config.LUCK_BOARD) do
		if Config.canBoard(data, item.Id) and data.Coins >= Config.boardCost(item, Config.boardLevel(data, item.Id)) then
			return true
		end
	end
	return false
end

State.watch(refresh)

return LuckBoard
