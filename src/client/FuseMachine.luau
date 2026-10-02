-- The Fuse Machine screen (opened at the machine in the Sakura Jungle).
--   LEFT    your pets that can be fused (Normal and Huge, no aura), as tiles
--           with a "37 / 100" under each (ready ones first); tap one to pick it.
--   RIGHT   the pet you picked, an arrow down to what it becomes (its Huge
--           or Titanic), "You have 37 / 100", and the FUSE button.
-- Fusing turns 100 of a Normal pet into 1 Huge of it, and 20 Huge into 1
-- Titanic (Config.FUSE; the server checks: server/Fuse.luau). A reveal
-- shows the new pet growing out of a burst of light.
local TweenService = game:GetService("TweenService")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local Effects = require(script.Parent.Effects)
local PetTile = require(script.Parent.PetTile)
local PetView = require(script.Parent.PetView)
local Screen = require(script.Parent.Screen)
local State = require(script.Parent.State)
local Ui = require(script.Parent.Ui)

local FuseMachine = {}

local fuseFunction = State.remote("Fuse")

local PINK = Color3.fromRGB(236, 84, 136)
local WIDTH, HEIGHT = 900, 600
local SIDE_W = 300
local LIST_W = WIDTH - 48 - SIDE_W - 16
local modal, box = Screen.modal(WIDTH, HEIGHT, "Fuse")
FuseMachine.Modal = modal
Screen.title(box, "Fuse Machine")
Screen.subtitle(box, Config.FUSE.HugeFrom .. " of a pet → its HUGE  ·  " .. Config.FUSE.TitanicFrom .. " Huge → its TITANIC")

FuseMachine.Selected = nil
FuseMachine.LastResult = nil -- for the simulator: the server's answer
local refresh

-- Your pets (left) ----------------------------------------------------------------------------

local TILE = 96
local grid = Screen.scrollList(box, 30, Ui.new("UIGridLayout", {
	CellSize = UDim2.fromOffset(TILE, math.floor(TILE * PetTile.ASPECT) + 18),
	CellPadding = UDim2.fromOffset(8, 8),
	SortOrder = Enum.SortOrder.LayoutOrder,
}))
grid.Size = UDim2.new(0, LIST_W, 1, -30)
FuseMachine.Grid = grid
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

-- The picked pet and what it becomes (right) ----------------------------------------------------

local side = Ui.new("Frame", {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, 0, 0, 30),
	Size = UDim2.new(0, SIDE_W, 1, -30),
	BackgroundColor3 = Color3.fromRGB(255, 242, 248),
	ZIndex = 32,
	Parent = box,
}, { Ui.corner(18), Ui.padding(14) })
Ui.stroke(Color3.fromRGB(250, 200, 225), 1.5, 0).Parent = side

local PICK = 92
local pickHolder = Ui.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.fromScale(0.5, 0),
	Size = UDim2.fromOffset(PICK, math.floor(PICK * PetTile.ASPECT)),
	BackgroundTransparency = 1,
	ZIndex = 33,
	Parent = side,
})
local pickName = Ui.chunky({
	Position = UDim2.fromOffset(0, math.floor(PICK * PetTile.ASPECT) + 2),
	Size = UDim2.new(1, 0, 0, 22),
	TextSize = 18,
	Text = "Pick a pet",
	Outline = 2,
	ZIndex = 34,
	Parent = side,
})
local arrow = Ui.chunky({
	Position = UDim2.fromOffset(0, math.floor(PICK * PetTile.ASPECT) + 24),
	Size = UDim2.new(1, 0, 0, 26),
	TextSize = 26,
	Text = "▼",
	Colors = { PINK, Color3.fromRGB(255, 150, 190) },
	Outline = 2,
	ZIndex = 34,
	Parent = side,
})
local resultTop = math.floor(PICK * PetTile.ASPECT) + 52
local resultHolder = Ui.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, resultTop),
	Size = UDim2.fromOffset(PICK, math.floor(PICK * PetTile.ASPECT)),
	BackgroundTransparency = 1,
	ZIndex = 33,
	Parent = side,
})
local resultName = Ui.chunky({
	Position = UDim2.fromOffset(0, resultTop + math.floor(PICK * PetTile.ASPECT) + 2),
	Size = UDim2.new(1, 0, 0, 22),
	TextSize = 18,
	Text = "",
	Outline = 2,
	ZIndex = 34,
	Parent = side,
})

-- "You have 37 / 100" with a pink bar
local progressTop = resultTop + math.floor(PICK * PetTile.ASPECT) + 30
local pickCount = Ui.new("TextLabel", {
	Position = UDim2.fromOffset(0, progressTop),
	Size = UDim2.new(1, 0, 0, 18),
	Font = Ui.FONT,
	TextScaled = false,
	TextSize = 14,
	TextColor3 = Ui.MUTED,
	Text = "",
	ZIndex = 34,
	Parent = side,
})
local bar = Ui.new("Frame", {
	Position = UDim2.fromOffset(10, progressTop + 22),
	Size = UDim2.new(1, -20, 0, 10),
	BackgroundColor3 = Color3.fromRGB(250, 215, 232),
	ZIndex = 34,
	Parent = side,
}, { Ui.corner(0.5) })
local barFill = Ui.new("Frame", {
	Size = UDim2.fromScale(0, 1),
	BackgroundColor3 = PINK,
	ZIndex = 35,
	Parent = bar,
}, { Ui.corner(0.5) })
FuseMachine.Bar = barFill

local fuseButton = Ui.button({
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, 0),
	Size = UDim2.new(1, 0, 0, 52),
	Radius = 18,
	Icon = "spark",
	Text = "FUSE",
	TextSize = 20,
	ZIndex = 36,
	Parent = side,
}, function()
	FuseMachine.fuse()
end, "disabled")
FuseMachine.FuseButton = fuseButton

-- The reveal -------------------------------------------------------------------------------------

local reveal = Ui.new("TextButton", {
	Name = "Reveal",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.fromRGB(40, 14, 36),
	BackgroundTransparency = 0.15,
	AutoButtonColor = false,
	Text = "",
	Visible = false,
	ZIndex = 70,
	Parent = box,
}, { Ui.corner(22) })
FuseMachine.Reveal = reveal
local revealRays = Ui.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.42),
	Size = UDim2.fromOffset(440, 440),
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
local revealTitle = Ui.chunky({
	Name = "Title",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.fromScale(0.5, 0.7),
	Size = UDim2.fromOffset(640, 46),
	TextSize = 42,
	Outline = 3,
	ZIndex = 73,
	Parent = reveal,
})
local revealSub = Ui.chunky({
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.fromScale(0.5, 0.8),
	Size = UDim2.fromOffset(640, 26),
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
	local pet, size = Config.petInfo(result)
	PetView.releaseAll(revealPet)
	for _, child in ipairs(revealPet:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	local view = PetView.take(result)
	view.Size = UDim2.fromScale(1, 1)
	view.ZIndex = 72
	view.Parent = revealPet
	for _, ray in ipairs(rayFrames) do
		ray.BackgroundColor3 = size.Color
	end
	revealTitle.Text = string.upper(result) .. "!"
	revealTitle.TextColor3 = size.Color:Lerp(Ui.WHITE, 0.25)
	revealSub.Text = string.format("Power %s  ·  %dx stronger than a %s", Config.formatNumber(Config.petPower(result)), size.Power // (if size.Index == 3 then Config.SIZES[2].Power else 1), if size.Index == 3 then "Huge " .. pet.Name else pet.Name)
	reveal.Visible = true
	revealDone = false
	Effects.jingle(if size.Index == 3 then 5 else 4)
	Effects.confetti(if size.Index == 3 then 80 else 40)
	if not Ui.reduced() then
		revealScale.Scale = 0.3
		TweenService:Create(revealScale, TweenInfo.new(0.5, Enum.EasingStyle.Back), { Scale = 1 }):Play()
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

-- Showing ----------------------------------------------------------------------------------------

-- pets that can go in (Normal and Huge, no aura): ready ones first, then the
-- closest to ready, then the strongest
local function candidates(data)
	local list = {}
	for name, n in pairs(data.Pets) do
		if n > 0 and Config.fuseResult(name) then
			table.insert(list, name)
		end
	end
	local function progress(name)
		local _, need = Config.fuseResult(name)
		return math.min(data.Pets[name] / need, 1)
	end
	table.sort(list, function(a, b)
		local pa, pb = progress(a), progress(b)
		if pa ~= pb then
			return pa > pb
		end
		return Config.petPower(a) > Config.petPower(b)
	end)
	return list
end
FuseMachine.candidates = candidates

function FuseMachine.select(name)
	FuseMachine.Selected = name
	refresh()
end

local function clear(holder)
	PetView.releaseAll(holder)
	for _, child in ipairs(holder:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

function refresh()
	local data = State.Data
	if not data or not modal.Visible then
		return
	end
	local list = candidates(data)
	if FuseMachine.Selected and (data.Pets[FuseMachine.Selected] or 0) <= 0 then
		FuseMachine.Selected = nil
	end
	clear(grid)
	for i, name in ipairs(list) do
		local cell = Ui.new("Frame", {
			Name = name,
			LayoutOrder = i,
			BackgroundTransparency = 1,
			ZIndex = 33,
			Parent = grid,
		})
		local tile = PetTile.new({ Name = name, Width = TILE, Amount = data.Pets[name], Parent = cell })
		PetTile.setSelected(tile, name == FuseMachine.Selected)
		tile.Frame.Activated:Connect(function()
			Effects.play("Click", 1.2, 0.04)
			FuseMachine.select(name)
		end)
		local have = data.Pets[name]
		local _, need = Config.fuseResult(name)
		Ui.new("TextLabel", {
			Name = "Progress",
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, 0),
			Size = UDim2.new(1, 0, 0, 16),
			Font = Ui.FONT,
			TextScaled = false,
			TextSize = 12,
			TextColor3 = if have >= need then Ui.SUCCESS else Ui.MUTED,
			Text = math.min(have, need) .. " / " .. need,
			ZIndex = 34,
			Parent = cell,
		})
	end
	empty.Visible = #list == 0
	-- the picked pet and what it becomes
	clear(pickHolder)
	clear(resultHolder)
	local name = FuseMachine.Selected
	if name then
		local result, need = Config.fuseResult(name)
		local have = data.Pets[name] or 0
		PetTile.new({ Name = name, Width = PICK, Hover = false, Parent = pickHolder })
		PetTile.new({ Name = result, Width = PICK, Hover = false, Parent = resultHolder })
		pickName.Text = need .. " × " .. name
		resultName.Text = "1 × " .. result
		arrow.Visible = true
		pickCount.Text = "You have " .. have .. " / " .. need
		pickCount.TextColor3 = if have >= need then Ui.SUCCESS else Ui.MUTED
		barFill.Size = UDim2.fromScale(math.clamp(have / need, 0, 1), 1)
		bar.Visible = true
		Ui.setStyle(fuseButton, if have >= need then "magenta" else "disabled")
	else
		pickName.Text = "Pick a pet"
		resultName.Text = ""
		arrow.Visible = false
		pickCount.Text = "Tap one of your pets"
		pickCount.TextColor3 = Ui.MUTED
		bar.Visible = false
		Ui.setStyle(fuseButton, "disabled")
	end
end

-- Fuses the picked pet (the server checks)
local fusing = false
function FuseMachine.fuse()
	local name, data = FuseMachine.Selected, State.Data
	if fusing or not name or not data then
		return
	end
	local result, need = Config.fuseResult(name)
	if not result or (data.Pets[name] or 0) < need then
		return
	end
	fusing = true
	local got = fuseFunction:InvokeServer(name)
	FuseMachine.LastResult = got
	fusing = false
	if type(got) == "string" then
		showReveal(got)
		-- keep the pick if there are enough left for another
		if (State.Data.Pets[name] or 0) < need then
			FuseMachine.Selected = got
		end
	end
	refresh()
end

function FuseMachine.open()
	Screen.open(modal)
	refresh()
end

-- The circle in front of the machine: standing on it opens the screen and
-- keeps it open (another panel you open yourself is left alone); stepping
-- off closes it. Closed with the X, it stays closed until you step off and
-- back on.
local player = game:GetService("Players").LocalPlayer
local circlePart = nil
local dismissed = false
local openedHere = false
FuseMachine.OnCircle = false

local function findCircle()
	if not (circlePart and circlePart.Parent) then
		local map = workspace:FindFirstChild("Map")
		circlePart = map and map:FindFirstChild("FuseCircle", true)
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

function FuseMachine.check()
	local circle = findCircle()
	if not circle then
		return
	end
	local on = standingOn(circle)
	FuseMachine.OnCircle = on
	if on then
		local other = Screen.current()
		if not isOpen() and not dismissed and (other == nil or other == modal) then
			FuseMachine.open()
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
		if FuseMachine.OnCircle then
			dismissed = true
		end
	end)
end

local since = 0
game:GetService("RunService").Heartbeat:Connect(function(dt)
	since += dt
	if since >= 0.15 then
		since = 0
		FuseMachine.check()
	end
end)
State.watch(function()
	refresh()
end)

return FuseMachine
