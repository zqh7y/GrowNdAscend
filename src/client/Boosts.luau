-- Boosts: the Inventory's second section, the Boost Machine's sign, and the
-- little timers of running boosts.
--   BOOSTS SECTION   "Running now" (each active boost and its time left),
--                    then a card for everything you have: Mega Rolls from the
--                    pad in the Sahara ("x12,000 Luck Roll", one roll with
--                    that luck, the full hatch show) and boost items from the
--                    Boost Machine (x2 Luck, x2 Coins, x5 Luck for a while).
--                    Each card has how many you have and a USE button.
--   BOOST MACHINE    in the Frozen Peaks: a sign over it says "FREE BOOST"
--                    and when the next one is ready; step on its circle then.
--   TIMERS           while a boost runs, a small chip in the top-left shows
--                    it and its time left.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Effects = require(script.Parent.Effects)
local Hatch = require(script.Parent.Hatch)
local Inventory = require(script.Parent.Inventory)
local Screen = require(script.Parent.Screen)
local State = require(script.Parent.State)
local Ui = require(script.Parent.Ui)

local Boosts = {}

local player = Players.LocalPlayer
local useFunction = State.remote("UseItem")
local claimFunction = State.remote("BoostClaim")

local function now()
	return workspace:GetServerTimeNow()
end

local function clock(seconds)
	seconds = math.max(math.ceil(seconds), 0)
	return string.format("%d:%02d", seconds // 60, seconds % 60)
end

local STAT_ICON = { Luck = "clover", Coins = "coin" }
local STAT_COLOR = { Luck = Color3.fromRGB(90, 200, 110), Coins = Color3.fromRGB(255, 190, 50) }
local MEGA_COLOR = Color3.fromRGB(120, 170, 255)

-- The Boosts section ------------------------------------------------------------------------------

local view = Ui.new("Frame", {
	Name = "BoostsView",
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	ZIndex = 32,
})
Boosts.View = view
Ui.new("TextLabel", {
	Position = UDim2.fromOffset(0, -2),
	Size = UDim2.new(1, 0, 0, 22),
	BackgroundTransparency = 1,
	Font = Ui.FONT_TITLE,
	TextSize = 15,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = Ui.MUTED,
	Text = "RUNNING NOW",
	ZIndex = 33,
	Parent = view,
})
local activeRow = Ui.new("Frame", {
	Name = "Active",
	Position = UDim2.fromOffset(0, 24),
	Size = UDim2.new(1, 0, 0, 40),
	BackgroundTransparency = 1,
	ZIndex = 33,
	Parent = view,
}, {
	Ui.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
})
Boosts.ActiveRow = activeRow
Ui.new("TextLabel", {
	Position = UDim2.fromOffset(0, 78),
	Size = UDim2.new(1, 0, 0, 22),
	BackgroundTransparency = 1,
	Font = Ui.FONT_TITLE,
	TextSize = 15,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = Ui.MUTED,
	Text = "YOUR BOOSTS",
	ZIndex = 33,
	Parent = view,
})
local grid = Ui.new("ScrollingFrame", {
	Name = "Items",
	Position = UDim2.fromOffset(0, 104),
	Size = UDim2.new(1, 0, 1, -104),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 6,
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	CanvasSize = UDim2.new(),
	ZIndex = 33,
	Parent = view,
}, {
	Ui.new("UIGridLayout", { CellSize = UDim2.fromOffset(190, 214), CellPadding = UDim2.fromOffset(12, 12), SortOrder = Enum.SortOrder.LayoutOrder }),
	Ui.new("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingLeft = UDim.new(0, 4) }),
})
Boosts.Grid = grid
local empty = Ui.new("TextLabel", {
	Name = "Empty",
	Position = UDim2.fromOffset(0, 140),
	Size = UDim2.new(1, 0, 0, 60),
	BackgroundTransparency = 1,
	Font = Ui.FONT,
	TextSize = 16,
	TextWrapped = true,
	TextColor3 = Ui.MUTED,
	Text = "No boosts yet. Step on the Mega Roll pad in the Sahara, or on the Boost Machine's circle in the Frozen Peaks!",
	ZIndex = 33,
	Parent = view,
})

-- a running boost: "x2 Luck  9:41"
local function activeChip(parent, stat, active, order, compact)
	local chip = Ui.new("Frame", {
		Name = stat,
		LayoutOrder = order,
		Size = UDim2.fromOffset(if compact then 126 else 170, if compact then 30 else 38),
		BackgroundColor3 = STAT_COLOR[stat] or Ui.GOLD,
		ZIndex = 34,
		Parent = parent,
	}, { Ui.corner(if compact then 15 else 19), Ui.stroke(Color3.new(1, 1, 1), 2, 0) })
	Ui.icon(STAT_ICON[stat] or "spark", if compact then 18 else 22, Color3.new(1, 1, 1), {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 8, 0.5, 0),
		ZIndex = 35,
		Parent = chip,
	})
	Ui.new("TextLabel", {
		Name = "Text",
		Position = UDim2.fromOffset(if compact then 30 else 36, 0),
		Size = UDim2.new(1, if compact then -36 else -42, 1, 0),
		BackgroundTransparency = 1,
		Font = Ui.FONT,
		TextSize = if compact then 13 else 15,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Color3.new(1, 1, 1),
		TextStrokeTransparency = 0.6,
		Text = string.format("x%s %s  %s", Config.formatNumber(active.Value), stat, clock(active.Ends - now())),
		ZIndex = 35,
		Parent = chip,
	})
	return chip
end

-- the running boosts, as { stat, active }
local function running(data)
	local list = {}
	for _, stat in ipairs({ "Luck", "Coins" }) do
		local active = data.ActiveBoosts and data.ActiveBoosts[stat]
		if active and active.Ends > now() then
			table.insert(list, { stat, active })
		end
	end
	return list
end

local busy = false

-- Uses something: a Mega Roll (multiplier) or a boost item (id)
function Boosts.use(kind, value)
	if busy then
		return nil
	end
	if kind == "MegaRoll" and Hatch.busy() then
		Screen.toast("Wait for the roll to finish", "danger")
		return nil
	end
	busy = true
	local ok, result = pcall(useFunction.InvokeServer, useFunction, kind, value)
	busy = false
	if not ok or not result then
		Screen.toast("Couldn't use that right now", "danger")
		return nil
	end
	Boosts.LastUse = result
	if kind == "MegaRoll" then
		-- one huge roll: close the Inventory and play the full show
		Screen.close(Inventory.Modal)
		Screen.toast("x" .. Config.commas(value) .. " MEGA ROLL!", "success")
		if type(result) == "table" and result[1] then
			task.spawn(Hatch.play, result, false, result[1].World, "full", false)
		end
	else
		local item = Config.ITEMS_BY_ID[value]
		Screen.toast(string.format("%s for %s!", item.Name, clock(result.Ends - now())), "success")
		Effects.jingle(2)
	end
	Boosts.refresh()
	return result
end

local function card(order, color, iconName, titleText, desc, count, onUse)
	local c = Ui.new("Frame", {
		LayoutOrder = order,
		BackgroundColor3 = Ui.WHITE,
		ZIndex = 34,
		Parent = grid,
	}, { Ui.corner(18), Ui.stroke(color:Lerp(Color3.new(1, 1, 1), 0.4), 2.5, 0) })
	local badge = Ui.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 12),
		Size = UDim2.fromOffset(64, 64),
		BackgroundColor3 = color,
		ZIndex = 35,
		Parent = c,
	}, { Ui.corner(0.5), Ui.stroke(Color3.new(1, 1, 1), 3, 0) })
	Ui.icon(iconName, 34, Color3.new(1, 1, 1), { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), ZIndex = 36, Parent = badge })
	Ui.new("TextLabel", {
		Name = "Count",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -10, 0, 10),
		Size = UDim2.fromOffset(44, 22),
		BackgroundColor3 = Ui.INK,
		Font = Ui.FONT,
		TextSize = 14,
		TextColor3 = Color3.new(1, 1, 1),
		Text = "x" .. count,
		ZIndex = 36,
		Parent = c,
	}, { Ui.corner(11) })
	Ui.chunky({
		Name = "Title",
		Position = UDim2.fromOffset(6, 82),
		Size = UDim2.new(1, -12, 0, 26),
		TextSize = 20,
		Text = titleText,
		Outline = 2,
		ZIndex = 36,
		Parent = c,
	})
	Ui.new("TextLabel", {
		Name = "Desc",
		Position = UDim2.fromOffset(10, 110),
		Size = UDim2.new(1, -20, 0, 44),
		BackgroundTransparency = 1,
		Font = Ui.FONT,
		TextSize = 13,
		TextWrapped = true,
		TextColor3 = Ui.MUTED,
		Text = desc,
		ZIndex = 36,
		Parent = c,
	})
	local use = Ui.button({
		Name = "Use",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -12),
		Size = UDim2.new(1, -24, 0, 38),
		Radius = 12,
		Text = "USE",
		TextSize = 17,
		ZIndex = 36,
		Parent = c,
	}, onUse, "green")
	return c, use
end

Boosts.Cards = {}

function Boosts.refresh()
	local data = State.Data
	if not data then
		return
	end
	-- running now
	for _, child in ipairs(activeRow:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	local list = running(data)
	for k, entry in ipairs(list) do
		activeChip(activeRow, entry[1], entry[2], k, false)
	end
	if #list == 0 then
		Ui.new("TextLabel", {
			Size = UDim2.fromOffset(300, 38),
			BackgroundTransparency = 1,
			Font = Ui.FONT,
			TextSize = 15,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = Ui.MUTED,
			Text = "Nothing running. Use a boost below!",
			ZIndex = 34,
			Parent = activeRow,
		})
	end
	-- the cards
	for _, child in ipairs(grid:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	table.clear(Boosts.Cards)
	local order = 0
	-- Mega Rolls, grouped by multiplier (biggest first)
	local megas, counts = {}, {}
	for _, m in ipairs(data.MegaRolls or {}) do
		if not counts[m] then
			table.insert(megas, m)
		end
		counts[m] = (counts[m] or 0) + 1
	end
	table.sort(megas, function(a, b)
		return a > b
	end)
	for _, m in ipairs(megas) do
		order += 1
		local c, use = card(order, MEGA_COLOR, "dice", "x" .. Config.commas(m) .. " Roll", "One roll with x" .. Config.commas(m) .. " luck, where you stand", counts[m], function()
			Boosts.use("MegaRoll", m)
		end)
		table.insert(Boosts.Cards, { Kind = "MegaRoll", Value = m, Card = c, Use = use })
	end
	for _, item in ipairs(Config.ITEMS) do
		local n = (data.Items or {})[item.Id] or 0
		if n > 0 then
			order += 1
			local minutes = math.floor(item.Seconds / 60)
			local c, use = card(order, item.Color, item.Icon, item.Name, string.format("%s x%d for %d minutes", item.Stat, item.Value, minutes), n, function()
				Boosts.use("Boost", item.Id)
			end)
			table.insert(Boosts.Cards, { Kind = "Boost", Value = item.Id, Card = c, Use = use })
		end
	end
	empty.Visible = order == 0
end

Inventory.addSection("Boosts", "My Boosts", "spark", view, Boosts.refresh)

-- Running boosts on the screen (top-left) ----------------------------------------------------------

local hudChips = Ui.new("Frame", {
	Name = "BoostChips",
	Position = UDim2.fromOffset(16, 62),
	Size = UDim2.fromOffset(300, 30),
	BackgroundTransparency = 1,
	Visible = false,
	ZIndex = 20,
	Parent = Screen.Gui,
}, {
	Ui.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
})
Boosts.HudChips = hudChips

local shownKey = nil
function Boosts.tick()
	local data = State.Data
	if not data then
		return
	end
	local list = running(data)
	local key = ""
	for _, entry in ipairs(list) do
		key ..= entry[1] .. clock(entry[2].Ends - now())
	end
	if key == shownKey then
		return
	end
	shownKey = key
	for _, child in ipairs(hudChips:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	for k, entry in ipairs(list) do
		activeChip(hudChips, entry[1], entry[2], k, true)
	end
	hudChips.Visible = #list > 0
	-- the section's timers too, while it's open
	if Inventory.Section == "Boosts" and Inventory.Modal.Visible then
		for _, child in ipairs(activeRow:GetChildren()) do
			local text = child:FindFirstChild("Text")
			local active = data.ActiveBoosts and data.ActiveBoosts[child.Name]
			if text and active then
				text.Text = string.format("x%s %s  %s", Config.formatNumber(active.Value), child.Name, clock(active.Ends - now()))
			end
		end
	end
end

-- The Boost Machine ------------------------------------------------------------------------------

local machine = workspace:WaitForChild("Map"):FindFirstChild("BoostMachine", true)
local sign = Ui.new("BillboardGui", {
	Name = "BoostMachineSign",
	Size = UDim2.fromScale(12, 4),
	LightInfluence = 0,
	MaxDistance = 120,
	ResetOnSpawn = false,
	Adornee = machine and machine:FindFirstChild("Sign"),
	Parent = player:WaitForChild("PlayerGui"),
})
local function outlined(props, color)
	local label = Ui.new("TextLabel", props)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	Ui.new("UIStroke", { Color = color, Thickness = 3, LineJoinMode = Enum.LineJoinMode.Round, Parent = label })
	return label
end
Boosts.SignTitle = outlined({ Size = UDim2.fromScale(1, 0.55), Text = "FREE BOOST", TextColor3 = Color3.new(1, 1, 1), Parent = sign }, Color3.fromRGB(40, 90, 160))
Boosts.SignTimer = outlined({ Position = UDim2.fromScale(0, 0.6), Size = UDim2.fromScale(1, 0.38), Text = "", TextColor3 = Color3.fromRGB(170, 225, 255), Parent = sign }, Color3.fromRGB(40, 90, 160))

local claiming = false
function Boosts.claim()
	local data = State.Data
	if claiming or not data or not data.BoostReady or data.BoostReady > now() then
		return nil
	end
	claiming = true
	local ok, id = pcall(claimFunction.InvokeServer, claimFunction)
	claiming = false
	if ok and type(id) == "string" then
		Boosts.LastClaim = id
		Effects.jingle(3)
		Boosts.refresh()
		return id
	end
	return nil
end

function Boosts.checkMachine()
	local data = State.Data
	if not data or not machine then
		return
	end
	local left = (data.BoostReady or 0) - now()
	if left > 0 then
		Boosts.SignTimer.Text = "Next in " .. Config.countdown(left)
		Boosts.SignTimer.TextColor3 = Color3.fromRGB(170, 225, 255)
	else
		Boosts.SignTimer.Text = "Ready! Step on the circle"
		Boosts.SignTimer.TextColor3 = Color3.fromRGB(130, 255, 150)
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local circle = machine:FindFirstChild("BoostCircle", true)
		if root and circle then
			local flat = Vector3.new(root.Position.X - circle.Position.X, 0, root.Position.Z - circle.Position.Z)
			if flat.Magnitude <= Config.BOOST_MACHINE.Radius then
				task.spawn(Boosts.claim)
			end
		end
	end
end

local since = 0
RunService.Heartbeat:Connect(function(dt)
	since += dt
	if since >= 0.25 then
		since = 0
		Boosts.tick()
		Boosts.checkMachine()
	end
end)
State.watch(function()
	shownKey = nil
	if Inventory.Section == "Boosts" then
		Boosts.refresh()
	end
end)

return Boosts
