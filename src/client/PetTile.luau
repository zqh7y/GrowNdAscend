-- One pet tile, the collection look shared by the Inventory and the Index:
-- the pet standing on a hexagon in its rarity's colours (it spills a little
-- over the top), the size under it for Huge/Titanic ("HUGE" in gold,
-- "TITANIC" in pink) and its odds in big outlined letters ("1 in 430K").
-- Copies show as "x3" in the top-right corner, an equipped pet gets a
-- green check in the top-left.
local TweenService = game:GetService("TweenService")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local PetView = require(script.Parent.PetView)
local Ui = require(script.Parent.Ui)

local PetTile = {}

PetTile.ASPECT = 1.18 -- a tile's height / width

-- the colours a pet's hexagon uses: its rarity's, Huge/Titanic get their size's
function PetTile.colorsOf(name)
	local pet, size = Config.petInfo(name)
	local base = if size.Index > 1 then size.Color else Config.rarity(pet.Odds).Color
	return Ui.rarityColors(base)
end

-- the colours for the odds text (lighter on top)
local function oddsColors(name)
	local pet = Config.petInfo(name)
	local rarity = Config.rarity(pet.Odds)
	return rarity.Color, rarity.Color2
end

-- props: Name (pet), Width, Parent, LayoutOrder, ZIndex, Amount (copies),
-- Equipped (bool), Silhouette (bool: not found yet), Odds (text override),
-- Hover (bool, default true). Returns a table: Frame (the TextButton),
-- Hex, View, Odds, Scale.
function PetTile.new(props)
	local name = props.Name
	local width = props.Width or 100
	local z = props.ZIndex or 33
	local frame = Ui.new("TextButton", {
		Name = name,
		LayoutOrder = props.LayoutOrder or 0,
		Size = UDim2.fromOffset(width, math.floor(width * PetTile.ASPECT)),
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
		ZIndex = z,
		Parent = props.Parent,
	})
	local scale = Ui.new("UIScale", { Parent = frame })
	local top, bottom = PetTile.colorsOf(name)
	if props.Silhouette then
		top, bottom = Color3.fromRGB(205, 210, 224), Color3.fromRGB(170, 176, 196)
	end
	local hex = Ui.hexagon({
		Size = math.floor(width * 1.02),
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, math.floor(width * 0.04)),
		Colors = { top, bottom },
		Edge = Color3.fromRGB(255, 255, 255),
		EdgeSize = 3,
		ZIndex = z,
		Parent = frame,
	})
	local view = PetView.take(name, props.Silhouette)
	view.AnchorPoint = Vector2.new(0.5, 0)
	view.Position = UDim2.new(0.5, 0, 0, 0)
	view.Size = UDim2.new(1, 4, 0.78, 0)
	view.ZIndex = z + 1
	view.Parent = frame
	-- the size, for Huge and Titanic
	local _, size = Config.petInfo(name)
	if size.Index > 1 and not props.Silhouette then
		Ui.chunky({
			Name = "SizeTag",
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -math.floor(width * 0.2)),
			Size = UDim2.new(1, 0, 0, math.floor(width * 0.15)),
			TextSize = math.max(10, math.floor(width * 0.14)),
			Text = string.upper(size.Name),
			Colors = { size.Color:Lerp(Ui.WHITE, 0.4), size.Color },
			Outline = 2,
			ZIndex = z + 3,
			Parent = frame,
		})
	end
	-- an aura pet: the aura's name across the top, in its colour
	local aura = Config.petAura(name)
	if aura and not props.Silhouette then
		Ui.chunky({
			Name = "AuraTag",
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, math.floor(width * 0.02)),
			Size = UDim2.new(1, 0, 0, math.floor(width * 0.14)),
			TextSize = math.max(10, math.floor(width * 0.12)),
			Text = string.upper(aura.Name),
			Colors = { aura.Color:Lerp(Ui.WHITE, 0.4), aura.Color },
			Outline = 1.5,
			ZIndex = z + 4,
			Parent = frame,
		})
	end
	-- the odds, big along the bottom
	local oddsTop, oddsBottom = oddsColors(name)
	local odds = Ui.chunky({
		Name = "Odds",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, 0),
		Size = UDim2.new(1, 8, 0, math.floor(width * 0.22)),
		TextSize = math.max(12, math.floor(width * 0.2)),
		Text = props.Odds or Config.shortOdds(Config.oddsOf(name)),
		Colors = { oddsTop, oddsBottom },
		Outline = 2.5,
		ZIndex = z + 3,
		Parent = frame,
	})
	Ui.diagonal(odds, oddsTop, oddsBottom)
	if props.Amount and props.Amount > 1 then
		Ui.chunky({
			Name = "Amount",
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -2, 0, 2),
			Size = UDim2.fromOffset(30, 18),
			TextSize = math.max(11, math.floor(width * 0.15)),
			TextXAlignment = Enum.TextXAlignment.Right,
			Text = "x" .. Config.formatNumber(props.Amount),
			Outline = 2,
			ZIndex = z + 3,
			Parent = frame,
		})
	end
	if props.Equipped then
		local tick = Ui.new("TextLabel", {
			Name = "Equipped",
			Position = UDim2.fromOffset(2, 2),
			Size = UDim2.fromOffset(22, 22),
			BackgroundTransparency = 0,
			BackgroundColor3 = Ui.SUCCESS,
			Font = Ui.FONT,
			TextScaled = false,
			TextSize = 13,
			TextColor3 = Ui.WHITE,
			Text = "✓",
			ZIndex = z + 4,
			Parent = frame,
		}, { Ui.corner(11), Ui.new("UIStroke", { Color = Ui.WHITE, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }) })
		local _ = tick
	end
	if props.Hover ~= false then
		frame.MouseEnter:Connect(function()
			TweenService:Create(scale, TweenInfo.new(0.15, Enum.EasingStyle.Quint), { Scale = if Ui.reduced() then 1 else 1.07 }):Play()
		end)
		frame.MouseLeave:Connect(function()
			TweenService:Create(scale, TweenInfo.new(0.15, Enum.EasingStyle.Quint), { Scale = 1 }):Play()
		end)
	end
	return { Frame = frame, Hex = hex, View = view, Odds = odds, Scale = scale }
end

-- Marks a tile as selected (a dark outline round its hexagon) or not
function PetTile.setSelected(tile, selected)
	local top, bottom = PetTile.colorsOf(tile.Frame.Name)
	Ui.setHexColors(tile.Hex, top, bottom, if selected then Ui.OUTLINE else Ui.WHITE)
end

return PetTile
