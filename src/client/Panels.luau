-- The smaller panels: Top Rollers (leaderboard), Rebirth and Settings.
-- (The Pet Aura Machine has its own screen: AuraMachine.luau.)
local Players = game:GetService("Players")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local Ui = require(script.Parent.Ui)
local Rebirth = require(script.Parent.Rebirth)
local Screen = require(script.Parent.Screen)
local State = require(script.Parent.State)
local Effects = require(script.Parent.Effects)

local Panels = {}
local player = Players.LocalPlayer



local function clear(list)
	for _, child in ipairs(list:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
end

-- Top Rollers -----------------------------------------------------------------------------

local topModal, topBox = Screen.modal(520, 600, "Top")
Screen.title(topBox, "Top Rollers")
local myRank = Screen.subtitle(topBox, "")
local topList = Screen.scrollList(topBox, 70, Ui.new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }))
Panels.Rank = nil -- the player's rank, for the dock label

local MEDALS = { Ui.GOLD, Color3.fromRGB(200, 210, 225), Color3.fromRGB(225, 150, 95) }
Panels.RankChanged = Instance.new("BindableEvent")

State.remote("Leaderboard").OnClientEvent:Connect(function(entries)
	clear(topList)
	local rank
	for i, entry in ipairs(entries) do
		local mine = entry.UserId == player.UserId
		if mine then
			rank = i
		end
		local row = Ui.new("Frame", {
			LayoutOrder = i,
			Size = UDim2.new(1, 0, 0, 46),
			BackgroundColor3 = Ui.GLASS_LIGHT,
			BackgroundTransparency = if mine then 0.05 else 0.4,
			ZIndex = 32,
			Parent = topList,
		}, { Ui.corner(6) })
		if mine then
			Ui.stroke(Ui.PRIMARY_B, 1.5, 0.2).Parent = row
		end
		Ui.new("TextLabel", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 10, 0.5, 0),
			Size = UDim2.fromOffset(30, 30),
			BackgroundTransparency = if MEDALS[i] then 0 else 1,
			BackgroundColor3 = MEDALS[i] or Ui.GLASS,
			TextScaled = false,
			TextSize = 15,
			Text = tostring(i),
			TextColor3 = if MEDALS[i] then Color3.fromRGB(20, 20, 35) else Ui.MUTED,
			ZIndex = 33,
			Parent = row,
		}, { Ui.corner(0.5) })
		-- their avatar, round, next to the name
		Ui.new("ImageLabel", {
			Name = "Avatar",
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 48, 0.5, 0),
			Size = UDim2.fromOffset(34, 34),
			BackgroundColor3 = Color3.fromRGB(225, 230, 242),
			Image = if type(entry.UserId) == "number" and entry.UserId > 0 then "rbxthumb://type=AvatarHeadShot&id=" .. entry.UserId .. "&w=150&h=150" else "",
			ZIndex = 33,
			Parent = row,
		}, { Ui.corner(0.5) })
		Ui.new("TextLabel", {
			Position = UDim2.fromOffset(90, 0),
			Size = UDim2.new(1, -236, 1, 0),
			Font = Ui.FONT_MEDIUM,
			TextScaled = false,
			TextSize = 17,
			Text = entry.Name,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 33,
			Parent = row,
		})
		Ui.new("TextLabel", {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -14, 0, 0),
			Size = UDim2.new(0, 140, 1, 0),
			TextScaled = false,
			TextSize = 17,
			Text = Config.formatNumber(entry.Rolls),
			TextColor3 = if mine then Ui.PRIMARY_A else Ui.TEXT,
			TextXAlignment = Enum.TextXAlignment.Right,
			ZIndex = 33,
			Parent = row,
		})
	end
	myRank.Text = if rank then "You're #" .. rank .. " in the world for total rolls" else "Keep rolling to get on the board"
	Panels.Rank = rank
	Panels.RankChanged:Fire()
end)

function Panels.openTop()
	Screen.open(topModal)
end

-- Rebirth (its own screen now: Rebirth.luau) ---------------------------------------------------

function Panels.openRebirth()
	Rebirth.open()
end

-- Settings ---------------------------------------------------------------------------------

local settingsModal, settingsBox = Screen.modal(440, 480, "Settings")
Screen.title(settingsBox, "Settings")
local SETTINGS = {
	{ Key = "DamageNumbers", Name = "Damage numbers" },
	{ Key = "FullHatch", Name = "Big hatch reveals" },
	{ Key = "Reveals", Name = "Slow first hatches" },
	{ Key = "Sounds", Name = "Sounds" },
	{ Key = "ReducedMotion", Name = "Reduced motion" },
}
for i, setting in ipairs(SETTINGS) do
	local y = 60 + (i - 1) * 62
	Ui.new("TextLabel", {
		Position = UDim2.fromOffset(0, y + 10),
		Size = UDim2.new(1, -120, 0, 24),
		TextScaled = false,
		TextSize = 18,
		Text = setting.Name,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 32,
		Parent = settingsBox,
	})
	local toggle
	toggle = Ui.button({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, y),
		Size = UDim2.fromOffset(100, 44),
		Radius = 22,
		Text = if State.Settings[setting.Key] then "ON" else "OFF",
		TextSize = 16,
		ZIndex = 33,
		Parent = settingsBox,
	}, function()
		State.Settings[setting.Key] = not State.Settings[setting.Key]
		Ui.setText(toggle, if State.Settings[setting.Key] then "ON" else "OFF")
		Ui.setStyle(toggle, if State.Settings[setting.Key] then "success" else "glass")
		Effects.play("Click")
	end, if State.Settings[setting.Key] then "success" else "glass")
end

function Panels.openSettings()
	Screen.open(settingsModal)
end

return Panels
