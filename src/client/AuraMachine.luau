-- The Pet Aura Machine screen (opened at the machine in the Sahara).
--   LEFT    your pets that can get an aura (no aura yet), as tiles with how
--           many you have; tap one to pick it.
--   RIGHT   the pet you picked, "2 / 3", the FUSE button and every aura's
--           chance and what it boosts.
-- Fusing turns 3 of the pet into 1 of it holding a random aura weapon (the
-- server picks it); a reveal shows the pet with its weapon and the aura.
local TweenService = game:GetService("TweenService")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local Effects = require(script.Parent.Effects)
local PetTile = require(script.Parent.PetTile)
local PetView = require(script.Parent.PetView)
local Screen = require(script.Parent.Screen)
local State = require(script.Parent.State)
local Ui = require(script.Parent.Ui)

local AuraMachine = {}

local fuseFunction = State.remote("AuraFuse")

local WIDTH, HEIGHT = 900, 600
local SIDE_W = 300
local LIST_W = WIDTH - 48 - SIDE_W - 16
local modal, box = Screen.modal(WIDTH, HEIGHT, "Aura")
AuraMachine.Modal = modal
Screen.title(box, "Pet Aura Machine")
Screen.subtitle(box, Config.AURA_COPIES .. " of the same pet → 1 with a random aura weapon")

AuraMachine.Selected = nil
AuraMachine.LastResult = nil -- for the simulator: the server's answer
local refresh

-- Your pets (left) ------------------------------------------------------------------------------

local TILE = 96
local grid = Screen.scrollList(box, 30, Ui.new("UIGridLayout", {
	CellSize = UDim2.fromOffset(TILE, math.floor(TILE * PetTile.ASPECT) + 18),
	CellPadding = UDim2.fromOffset(8, 8),
	SortOrder = Enum.SortOrder.LayoutOrder,
}))
grid.Size = UDim2.new(0, LIST_W, 1, -30)
AuraMachine.Grid = grid
local empty = Ui.new("TextLabel", {
	Position = UDim2.fromOffset(0, 150),
	Size = UDim2.fromOffset(LIST_W, 24),
	Font = Ui.FONT_MEDIUM,
	TextScaled = false,
	TextSize = 16,
	TextColor3 = Ui.MUTED,
	Text = "Roll some pets first!",
	Visible = false,
	ZIndex = 33,
	Parent = box,
})

-- The picked pet and the chances (right) -------------------------------------------------------------

local side = Ui.new("Frame", {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, 0, 0, 30),
	Size = UDim2.new(0, SIDE_W, 1, -30),
	BackgroundColor3 = Color3.fromRGB(246, 243, 252),
	ZIndex = 32,
	Parent = box,
}, { Ui.corner(18), Ui.padding(14) })
Ui.stroke(Color3.fromRGB(220, 210, 240), 1.5, 0).Parent = side
local pickHolder = Ui.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.fromScale(0.5, 0),
	Size = UDim2.fromOffset(110, math.floor(110 * PetTile.ASPECT)),
	BackgroundTransparency = 1,
	ZIndex = 33,
	Parent = side,
})
local pickName = Ui.chunky({
	Position = UDim2.fromOffset(0, 134),
	Size = UDim2.new(1, 0, 0, 24),
	TextSize = 20,
	Text = "Pick a pet",
	Outline = 2,
	ZIndex = 34,
	Parent = side,
})
local pickCount = Ui.new("TextLabel", {
	Position = UDim2.fromOffset(0, 160),
	Size = UDim2.new(1, 0, 0, 18),
	Font = Ui.FONT,
	TextScaled = false,
	TextSize = 14,
	TextColor3 = Ui.MUTED,
	Text = "",
	ZIndex = 34,
	Parent = side,
})
local chances = Ui.new("Frame", {
	Position = UDim2.fromOffset(0, 186),
	Size = UDim2.new(1, 0, 0, 230),
	BackgroundTransparency = 1,
	ZIndex = 33,
	Parent = side,
}, { Ui.new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }) })

-- what an aura boosts, short: "Damage x1.8 · Coins x1.2"
local function boostText(aura)
	local parts = {}
	for _, stat in ipairs({ "Damage", "Coins", "Luck" }) do
		if aura.Boosts[stat] then
			table.insert(parts, stat .. " x" .. aura.Boosts[stat])
		end
	end
	return table.concat(parts, " · ")
end
AuraMachine.boostText = boostText

local totalWeight = 0
for _, aura in ipairs(Config.AURAS) do
	totalWeight += aura.Weight
end
for i, aura in ipairs(Config.AURAS) do
	local row = Ui.new("Frame", {
		Name = aura.Id,
		LayoutOrder = i,
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundColor3 = Ui.WHITE,
		ZIndex = 34,
		Parent = chances,
	}, { Ui.corner(10) })
	Ui.new("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 8, 0.5, 0),
		Size = UDim2.fromOffset(14, 14),
		BackgroundColor3 = aura.Color,
		ZIndex = 35,
		Parent = row,
	}, { Ui.corner(0.5) })
	Ui.new("TextLabel", {
		Position = UDim2.fromOffset(28, 2),
		Size = UDim2.new(1, -80, 0, 16),
		Font = Ui.FONT,
		TextScaled = false,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Ui.INK,
		Text = aura.Name,
		ZIndex = 35,
		Parent = row,
	})
	Ui.new("TextLabel", {
		Position = UDim2.fromOffset(28, 17),
		Size = UDim2.new(1, -80, 0, 14),
		Font = Ui.FONT_MEDIUM,
		TextScaled = false,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Ui.MUTED,
		Text = boostText(aura),
		ZIndex = 35,
		Parent = row,
	})
	Ui.new("TextLabel", {
		Name = "Chance",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -8, 0, 0),
		Size = UDim2.new(0, 50, 1, 0),
		Font = Ui.FONT_DISPLAY,
		TextScaled = false,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextColor3 = aura.Color:Lerp(Ui.INK, 0.2),
		Text = string.format("%g%%", aura.Weight / totalWeight * 100),
		ZIndex = 35,
		Parent = row,
	})
end

local fuseButton = Ui.button({
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, 0),
	Size = UDim2.new(1, 0, 0, 52),
	Radius = 18,
	Icon = "spark",
	Text = "FUSE " .. Config.AURA_COPIES,
	TextSize = 20,
	ZIndex = 36,
	Parent = side,
}, function()
	AuraMachine.fuse()
end, "disabled")
AuraMachine.FuseButton = fuseButton

-- The reveal ---------------------------------------------------------------------------------------

local reveal = Ui.new("TextButton", {
	Name = "Reveal",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.fromRGB(20, 14, 36),
	BackgroundTransparency = 0.15,
	AutoButtonColor = false,
	Text = "",
	Visible = false,
	ZIndex = 70,
	Parent = box,
}, { Ui.corner(22) })
AuraMachine.Reveal = reveal
local revealRays = Ui.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.42),
	Size = UDim2.fromOffset(420, 420),
	BackgroundTransparency = 1,
	ZIndex = 71,
	Parent = reveal,
})
local rayFrames = {}
for k = 0, 7 do
	rayFrames[k + 1] = Ui.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0, 40, 1, 0),
		Rotation = k * 22.5,
		BackgroundColor3 = Ui.WHITE,
		BackgroundTransparency = 0.4,
		ZIndex = 71,
		Parent = revealRays,
	}, { Ui.new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.1), NumberSequenceKeypoint.new(1, 1) }) }) })
end
local revealPet = Ui.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.42),
	Size = UDim2.fromOffset(260, 240),
	BackgroundTransparency = 1,
	ZIndex = 72,
	Parent = reveal,
})
local revealScale = Ui.new("UIScale", { Parent = revealPet })
local revealAura = Ui.chunky({
	Name = "AuraName",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.fromScale(0.5, 0.68),
	Size = UDim2.fromOffset(600, 44),
	TextSize = 40,
	Outline = 3,
	ZIndex = 73,
	Parent = reveal,
})
local revealBoosts = Ui.chunky({
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.fromScale(0.5, 0.78),
	Size = UDim2.fromOffset(600, 26),
	TextSize = 20,
	Outline = 2,
	ZIndex = 73,
	Parent = reveal,
})
local revealDone = false
reveal.Activated:Connect(function()
	revealDone = true
end)

local function showReveal(result)
	local aura = Config.AURAS_BY_ID[result.Aura]
	PetView.releaseAll(revealPet)
	for _, child in ipairs(revealPet:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	local view = PetView.take(result.Pet)
	view.Size = UDim2.fromScale(1, 1)
	view.ZIndex = 72
	view.Parent = revealPet
	for _, ray in ipairs(rayFrames) do
		ray.BackgroundColor3 = aura.Color
	end
	revealAura.Text = aura.Name
	revealAura.TextColor3 = aura.Color:Lerp(Ui.WHITE, 0.3)
	revealBoosts.Text = Config.displayName(result.Pet) .. "  ·  " .. boostText(aura)
	reveal.Visible = true
	revealDone = false
	Effects.jingle(if (table.find(Config.AURAS, aura) or 1) >= 4 then 5 else 3)
	if (table.find(Config.AURAS, aura) or 1) >= 5 then
		Effects.confetti(60)
	end
	if not Ui.reduced() then
		revealScale.Scale = 0.3
		TweenService:Create(revealScale, TweenInfo.new(0.45, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	end
	task.spawn(function()
		local start = os.clock()
		while reveal.Visible and not revealDone and os.clock() - start < 4 do
			revealRays.Rotation = (revealRays.Rotation + 0.5) % 360
			task.wait()
		end
		reveal.Visible = false
		PetView.releaseAll(revealPet)
	end)
end

-- Showing ------------------------------------------------------------------------------------------

-- pets that can go in: any size, no aura yet
local function candidates(data)
	local list = {}
	for name, n in pairs(data.Pets) do
		if n > 0 and Config.petInfo(name) and not Config.petAura(name) then
			table.insert(list, name)
		end
	end
	table.sort(list, function(a, b)
		local ready = (data.Pets[a] >= Config.AURA_COPIES) ~= (data.Pets[b] >= Config.AURA_COPIES)
		if ready then
			return data.Pets[a] >= Config.AURA_COPIES
		end
		return Config.petPower(a) > Config.petPower(b)
	end)
	return list
end

function AuraMachine.select(name)
	AuraMachine.Selected = name
	refresh()
end

function refresh()
	local data = State.Data
	if not data or not modal.Visible then
		return
	end
	local list = candidates(data)
	if AuraMachine.Selected and (data.Pets[AuraMachine.Selected] or 0) <= 0 then
		AuraMachine.Selected = nil
	end
	PetView.releaseAll(grid)
	for _, child in ipairs(grid:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	for i, name in ipairs(list) do
		local cell = Ui.new("Frame", {
			Name = name,
			LayoutOrder = i,
			BackgroundTransparency = 1,
			ZIndex = 33,
			Parent = grid,
		})
		local tile = PetTile.new({ Name = name, Width = TILE, Amount = data.Pets[name], Parent = cell })
		PetTile.setSelected(tile, name == AuraMachine.Selected)
		tile.Frame.Activated:Connect(function()
			Effects.play("Click", 1.2, 0.04)
			AuraMachine.select(name)
		end)
		local have = data.Pets[name]
		Ui.new("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, 0),
			Size = UDim2.new(1, 0, 0, 16),
			Font = Ui.FONT,
			TextScaled = false,
			TextSize = 12,
			TextColor3 = if have >= Config.AURA_COPIES then Ui.SUCCESS else Ui.MUTED,
			Text = math.min(have, Config.AURA_COPIES) .. " / " .. Config.AURA_COPIES,
			ZIndex = 34,
			Parent = cell,
		})
	end
	empty.Visible = #list == 0
	-- the picked pet
	PetView.releaseAll(pickHolder)
	for _, child in ipairs(pickHolder:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	local name = AuraMachine.Selected
	if name then
		PetTile.new({ Name = name, Width = 110, Hover = false, Parent = pickHolder })
		local have = data.Pets[name] or 0
		pickName.Text = name
		pickCount.Text = "You have " .. have .. " / " .. Config.AURA_COPIES .. " needed"
		pickCount.TextColor3 = if have >= Config.AURA_COPIES then Ui.SUCCESS else Ui.DANGER
		Ui.setStyle(fuseButton, if have >= Config.AURA_COPIES then "purple" else "disabled")
	else
		pickName.Text = "Pick a pet"
		pickCount.Text = "Tap one of your pets"
		pickCount.TextColor3 = Ui.MUTED
		Ui.setStyle(fuseButton, "disabled")
	end
end

-- Fuses the picked pet (the server checks and picks the aura)
local fusing = false
function AuraMachine.fuse()
	local name, data = AuraMachine.Selected, State.Data
	if fusing or not name or not data or (data.Pets[name] or 0) < Config.AURA_COPIES then
		return
	end
	fusing = true
	local result = fuseFunction:InvokeServer(name)
	AuraMachine.LastResult = result
	fusing = false
	if type(result) == "table" and result.Aura then
		showReveal(result)
	end
	refresh()
end

function AuraMachine.open()
	Screen.open(modal)
	refresh()
end

State.remote("AuraOpen").OnClientEvent:Connect(AuraMachine.open)
State.watch(function()
	refresh()
end)

return AuraMachine
