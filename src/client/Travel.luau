-- Teleport: the screen dims (not all the way: the game shows through) and
-- every world lies on it as a photo, like snapshots on a table: a white
-- frame tilted a little, a picture of the world from above, its number and
-- its name. Hover one and it straightens and grows; tap it to go there.
-- The world you're in has a "YOU'RE HERE" pin; locked worlds are darker
-- with a lock and their price. Tap the dark around them (or X) to close.
--
-- The photos are real: each one is a ViewportFrame with a copy of that
-- world's bigger props (trees, buildings, rocks...) on a ground of its
-- colour, seen from above at an angle. They're made the first time you
-- open the screen (and again if a world hadn't loaded yet).
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local Effects = require(script.Parent.Effects)
local Screen = require(script.Parent.Screen)
local State = require(script.Parent.State)
local Ui = require(script.Parent.Ui)

local Travel = {}

local teleportFunction = State.remote("Teleport")
local player = Players.LocalPlayer

local CARD_W, CARD_H = 220, 250
local DIM = 0.35 -- how see-through the dark is (the game shows through)
Travel.DIM = DIM
local PHOTO = 196
-- the ground colour of each world, under the props in its photo
local GROUNDS = {
	Color3.fromRGB(110, 210, 80),
	Color3.fromRGB(255, 220, 140),
	Color3.fromRGB(240, 248, 255),
	Color3.fromRGB(125, 215, 105),
	Color3.fromRGB(120, 98, 92),
}

-- The screen ----------------------------------------------------------------------------------------

local gui = Ui.new("ScreenGui", {
	Name = "TravelGui",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	DisplayOrder = 30,
	Enabled = false,
	Parent = player:WaitForChild("PlayerGui"),
})
pcall(function()
	gui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets -- (clear of a phone's notch)
end)
-- everything shrinks to fit the screen (the photos need ~1300 x 760 units;
-- a phone in landscape is much smaller)
local fitScale = Ui.new("UIScale", { Parent = gui })
Travel.FitScale = fitScale
function Travel.fitFor(size)
	return math.min(1, size.X / 1300, size.Y / 760)
end
local function fit()
	-- (on phones 85% of that, like every panel: Screen.panelScale)
	fitScale.Scale = Travel.fitFor(workspace.CurrentCamera.ViewportSize) * Screen.panelScale()
end
fit()
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)

-- the dim: dark, but the game still shows through; tapping it closes
local dim = Ui.new("TextButton", {
	Name = "Dim",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.fromRGB(10, 14, 30),
	BackgroundTransparency = DIM,
	AutoButtonColor = false,
	Text = "",
	Parent = gui,
})
dim.Activated:Connect(function()
	Travel.close()
end)
Travel.Modal = gui
Travel.Dim = dim

Ui.chunky({
	Name = "Title",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 40),
	Size = UDim2.fromOffset(600, 64),
	TextSize = 60,
	Text = "TELEPORT",
	Rotation = -2,
	Outline = 4,
	ZIndex = 5,
	Parent = gui,
})
Ui.new("TextLabel", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 104),
	Size = UDim2.fromOffset(600, 24),
	BackgroundTransparency = 1,
	Font = Ui.FONT,
	TextSize = 18,
	TextColor3 = Color3.fromRGB(220, 226, 245),
	Text = "Pick a world to go there",
	ZIndex = 5,
	Parent = gui,
})
-- the X
local close = Ui.new("TextButton", {
	Name = "Close",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -30, 0, 34),
	Size = UDim2.fromOffset(54, 54),
	BackgroundTransparency = 1,
	Text = "",
	ZIndex = 6,
	Parent = gui,
})
for _, angle in ipairs({ 45, -45 }) do
	Ui.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, 0, 0, 14),
		Rotation = angle,
		BackgroundColor3 = Color3.fromRGB(240, 52, 60),
		ZIndex = 7,
		Parent = close,
	}, { Ui.corner(5), Ui.new("UIStroke", { Color = Ui.OUTLINE, Thickness = 3, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }) })
end
close.Activated:Connect(function()
	Travel.close()
end)

-- the photos lie in a row (wrapping on small screens)
local table_ = Ui.new("Frame", {
	Name = "Photos",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.56),
	Size = UDim2.new(1, -80, 0, CARD_H * 2 + 40),
	BackgroundTransparency = 1,
	ZIndex = 5,
	Parent = gui,
}, {
	Ui.new("UIGridLayout", {
		CellSize = UDim2.fromOffset(CARD_W, CARD_H),
		CellPadding = UDim2.fromOffset(26, 30),
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
	}),
})

Travel.Rows = {}

for i, area in ipairs(Config.AREAS) do
	local tilt = if i % 2 == 0 then 3 else -3
	-- the card is a holder (for the grid) with the tilted photo inside
	local holder = Ui.new("Frame", {
		Name = "World" .. i,
		LayoutOrder = i,
		BackgroundTransparency = 1,
		ZIndex = 5,
		Parent = table_,
	})
	local card = Ui.new("TextButton", {
		Name = "Card",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
		Rotation = tilt,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		AutoButtonColor = false,
		Text = "",
		ZIndex = 6,
		Parent = holder,
	}, { Ui.corner(10) })
	local scale = Ui.new("UIScale", { Parent = card })
	-- a soft shadow under the photo
	Ui.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 6, 0.5, 10),
		Size = UDim2.fromScale(1, 1),
		Rotation = tilt,
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.6,
		ZIndex = 5,
		Parent = holder,
	}, { Ui.corner(10) })
	-- the picture
	local photo = Ui.new("ViewportFrame", {
		Name = "Photo",
		Position = UDim2.fromOffset((CARD_W - PHOTO) / 2, 12),
		Size = UDim2.fromOffset(PHOTO, PHOTO - 36),
		BackgroundColor3 = GROUNDS[i] or area.Color,
		Ambient = Color3.fromRGB(190, 190, 200),
		LightColor = Color3.fromRGB(255, 250, 235),
		LightDirection = Vector3.new(-1, -2, -0.6),
		ZIndex = 7,
		Parent = card,
	}, { Ui.corner(6) })
	-- dark veil and lock for locked worlds
	local veil = Ui.new("Frame", {
		Name = "Locked",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(15, 18, 35),
		BackgroundTransparency = 0.35,
		Visible = false,
		ZIndex = 8,
		Parent = photo,
	}, { Ui.corner(6) })
	Ui.icon("lock", 44, Color3.new(1, 1, 1), { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.45), ZIndex = 9, Parent = veil })
	-- the world's number in a coloured badge on the corner
	local badge = Ui.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(18, 16),
		Size = UDim2.fromOffset(38, 38),
		BackgroundColor3 = area.Color,
		ZIndex = 10,
		Parent = card,
	}, { Ui.corner(0.5), Ui.stroke(Color3.new(1, 1, 1), 3, 0) })
	Ui.new("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Font = Enum.Font.FredokaOne,
		TextSize = 22,
		TextColor3 = Color3.new(1, 1, 1),
		Text = tostring(i),
		ZIndex = 11,
		Parent = badge,
	})
	-- the "you're here" pin
	local here = Ui.new("TextLabel", {
		Name = "Here",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 6, 0, -8),
		Size = UDim2.fromOffset(104, 26),
		BackgroundColor3 = Color3.fromRGB(80, 200, 110),
		Font = Ui.FONT_TITLE,
		TextSize = 12,
		TextColor3 = Color3.new(1, 1, 1),
		Text = "YOU'RE HERE",
		Visible = false,
		ZIndex = 11,
		Parent = card,
	}, { Ui.corner(13), Ui.stroke(Color3.new(1, 1, 1), 2, 0) })
	-- the name, written under the picture, and what tapping does
	local name = Ui.chunky({
		Name = "WorldName",
		Position = UDim2.fromOffset(8, PHOTO - 18),
		Size = UDim2.new(1, -16, 0, 30),
		TextSize = 24,
		Text = area.Name,
		Colors = { area.Color:Lerp(Color3.new(0, 0, 0), 0.1), area.Color:Lerp(Color3.new(1, 1, 1), 0.3) },
		Outline = 2.5,
		ZIndex = 9,
		Parent = card,
	})
	local status = Ui.new("TextLabel", {
		Name = "Status",
		Position = UDim2.fromOffset(8, PHOTO + 14),
		Size = UDim2.new(1, -16, 0, 18),
		BackgroundTransparency = 1,
		Font = Ui.FONT,
		TextSize = 13,
		TextColor3 = Ui.MUTED,
		Text = "",
		ZIndex = 9,
		Parent = card,
	})
	-- hover: straighten and grow
	card.MouseEnter:Connect(function()
		if Ui.reduced() then
			return
		end
		TweenService:Create(card, TweenInfo.new(0.18, Enum.EasingStyle.Quint), { Rotation = 0 }):Play()
		TweenService:Create(scale, TweenInfo.new(0.18, Enum.EasingStyle.Back), { Scale = 1.08 }):Play()
	end)
	card.MouseLeave:Connect(function()
		TweenService:Create(card, TweenInfo.new(0.2, Enum.EasingStyle.Quint), { Rotation = tilt }):Play()
		TweenService:Create(scale, TweenInfo.new(0.2, Enum.EasingStyle.Quint), { Scale = 1 }):Play()
	end)
	card.Activated:Connect(function()
		Travel.go(i)
	end)
	Travel.Rows[i] = { Button = card, Name = name, Status = status, Photo = photo, Locked = veil, Here = here, Parts = 0 }
end

-- The photos ------------------------------------------------------------------------------------------

local function areaFolder(i)
	local map = workspace:FindFirstChild("Map")
	return map and map:FindFirstChild("Area" .. i .. "_" .. Config.AREAS[i].Name:gsub(" ", ""))
end

-- Builds world i's photo: its bigger props on a ground of its colour, seen
-- from above at an angle. Returns how many parts went in.
function Travel.buildPhoto(i)
	local row = Travel.Rows[i]
	local photo = row.Photo
	for _, child in ipairs(photo:GetChildren()) do
		if child:IsA("BasePart") or child:IsA("Model") or child:IsA("Camera") then
			child:Destroy()
		end
	end
	local x0 = Config.areaStart(i)
	local center = Vector3.new(x0 + Config.AREA_LENGTH / 2, 0, 0)
	local ground = Instance.new("Part")
	ground.Anchored = true
	ground.Size = Vector3.new(Config.AREA_LENGTH + 60, 1, Config.AREA_HALF_WIDTH * 2 + 60)
	ground.CFrame = CFrame.new(center + Vector3.new(0, Config.GROUND_Y - 0.5, 0))
	ground.Color = GROUNDS[i] or Config.AREAS[i].Color
	ground.Material = Enum.Material.SmoothPlastic
	ground.Parent = photo
	local count = 0
	local folder = areaFolder(i)
	if folder then
		for _, part in ipairs(folder:GetDescendants()) do
			if count >= 900 then
				break
			end
			if part:IsA("BasePart") and part.Transparency < 0.9 and math.max(part.Size.X, part.Size.Y, part.Size.Z) >= 1.6 then
				local p = part.Position
				if math.abs(p.X - center.X) < Config.AREA_LENGTH / 2 + 25 and math.abs(p.Z) < Config.AREA_HALF_WIDTH + 25 then
					local copy = part:Clone()
					for _, child in ipairs(copy:GetChildren()) do
						child:Destroy()
					end
					copy.Anchored = true
					copy.Parent = photo
					count += 1
				end
			end
		end
	end
	local camera = Instance.new("Camera")
	camera.FieldOfView = 40
	camera.CFrame = CFrame.lookAt(center + Vector3.new(-62, 150, 70), center + Vector3.new(4, 0, 2))
	camera.Parent = photo
	photo.CurrentCamera = camera
	row.Parts = count
	return count
end

local building = false
local function buildPhotos()
	if building then
		return
	end
	building = true
	for i, row in ipairs(Travel.Rows) do
		-- (again if the world hadn't loaded on this screen yet)
		if row.Parts < 100 then
			pcall(Travel.buildPhoto, i)
			task.wait()
		end
	end
	building = false
end

-- Showing and going ---------------------------------------------------------------------------------

local function currentArea()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root then Config.areaAt(root.Position.X) else 1
end

function Travel.refresh()
	local unlocked = (State.Data and State.Data.Unlocked) or 1
	local here = currentArea()
	for i, r in ipairs(Travel.Rows) do
		r.Here.Visible = i == here
		r.Locked.Visible = i > unlocked
		if i == here then
			r.Status.Text = "You're here"
		elseif i <= unlocked then
			r.Status.Text = "Tap to teleport"
		else
			r.Status.Text = "🔒 Locked · " .. Config.areaCostText(i)
		end
	end
end

function Travel.open()
	Travel.refresh()
	gui.Enabled = true
	if not Ui.reduced() then
		dim.BackgroundTransparency = 1
		TweenService:Create(dim, TweenInfo.new(0.25), { BackgroundTransparency = DIM }):Play()
		table_.Position = UDim2.fromScale(0.5, 0.62)
		TweenService:Create(table_, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Position = UDim2.fromScale(0.5, 0.56) }):Play()
	end
	task.spawn(buildPhotos)
end

function Travel.close()
	gui.Enabled = false
end

-- Teleports to world `i` (if it's open), closing the screen
function Travel.go(i)
	local unlocked = (State.Data and State.Data.Unlocked) or 1
	if i > unlocked then
		Effects.play("Click", 0.7)
		Screen.toast("Unlock " .. Config.AREAS[i].Name .. " first!", "danger")
		return false
	end
	Effects.play("Click", 1.1, 0.05)
	local ok, moved = pcall(teleportFunction.InvokeServer, teleportFunction, i)
	if ok and moved then
		Travel.close()
		Effects.flash(Color3.new(1, 1, 1), 0.35)
		return true
	end
	return false
end

State.watch(Travel.refresh)

return Travel
