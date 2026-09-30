-- The smaller panels: Top Rollers (leaderboard), Rebirth, the Fusion machine
-- (opened from the machine itself) and Settings.
local Players = game:GetService("Players")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local Ui = require(script.Parent.Ui)
local Rebirth = require(script.Parent.Rebirth)
local Screen = require(script.Parent.Screen)
local State = require(script.Parent.State)
local Effects = require(script.Parent.Effects)
local Roll = require(script.Parent.Roll)

local Panels = {}
local player = Players.LocalPlayer

local function commas(n)
	local digits = tostring(math.floor(n))
	return (digits:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", ""))
end

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
		}, { Ui.corner(14) })
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
		Ui.new("TextLabel", {
			Position = UDim2.fromOffset(54, 0),
			Size = UDim2.new(1, -200, 1, 0),
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
			Text = commas(entry.Rolls),
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

-- Fusion machine ------------------------------------------------------------------------------

local fusionModal, fusionBox = Screen.modal(560, 540, "Fusion")
Screen.title(fusionBox, "Pet Fusion")
Screen.subtitle(fusionBox, "Put in " .. Config.FUSE_COPIES .. " of the same pet, get 1 of the next size up")

local fusingCard = Ui.new("Frame", {
	Position = UDim2.fromOffset(0, 88),
	Size = UDim2.new(1, 0, 0, 190),
	BackgroundColor3 = Ui.GLASS_LIGHT,
	BackgroundTransparency = 0.3,
	Visible = false,
	ZIndex = 32,
	Parent = fusionBox,
}, { Ui.corner(18), Ui.padding(18) })
local fusingName = Ui.new("TextLabel", {
	Size = UDim2.new(1, 0, 0, 30),
	TextScaled = false,
	TextSize = 26,
	TextColor3 = Ui.GOLD,
	ZIndex = 33,
	Parent = fusingCard,
})
local fusingTimer = Ui.new("TextLabel", {
	Position = UDim2.fromOffset(0, 52),
	Size = UDim2.new(1, 0, 0, 22),
	Font = Ui.FONT_MEDIUM,
	TextScaled = false,
	TextSize = 18,
	TextColor3 = Ui.MUTED,
	ZIndex = 33,
	Parent = fusingCard,
})
local barBack = Ui.new("Frame", {
	Position = UDim2.fromOffset(0, 86),
	Size = UDim2.new(1, 0, 0, 12),
	BackgroundColor3 = Ui.GLASS,
	ZIndex = 33,
	Parent = fusingCard,
}, { Ui.corner(0.5) })
local bar = Ui.new("Frame", {
	Size = UDim2.fromScale(0, 1),
	BackgroundColor3 = Color3.new(1, 1, 1),
	ZIndex = 34,
	Parent = barBack,
}, { Ui.corner(0.5), Ui.new("UIGradient", { Color = ColorSequence.new(Ui.PRIMARY_A, Ui.PRIMARY_B) }) })
local collectButton = Ui.button({
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, 0),
	Size = UDim2.new(1, 0, 0, 52),
	Radius = 18,
	Text = "COLLECT",
	TextSize = 20,
	ZIndex = 34,
	Parent = fusingCard,
}, function()
	local result = State.remote("FuseCollect"):InvokeServer()
	if result then
		Screen.close(fusionModal)
		local pet, size = Config.petInfo(result)
		task.spawn(Roll.bigReveal, pet.Name, size.Index)
	end
end, "disabled")

local fuseList = Screen.scrollList(fusionBox, 76, Ui.new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }))
local fuseEmpty = Ui.new("TextLabel", {
	Position = UDim2.fromOffset(0, 132),
	Size = UDim2.new(1, 0, 0, 20),
	Font = Ui.FONT_MEDIUM,
	TextScaled = false,
	TextSize = 16,
	Text = "Get " .. Config.FUSE_COPIES .. " of the same pet to fuse it",
	TextColor3 = Ui.MUTED,
	ZIndex = 33,
	Parent = fusionBox,
})

local function nextSizeName(name)
	local pet, size = Config.petInfo(name)
	if size.Index >= #Config.SIZES then
		return nil
	end
	return Config.petName(pet.Name, size.Index + 1)
end

local function refreshFusion()
	local data = State.Data
	if not data then
		return
	end
	local fusion = data.Fusion
	fusingCard.Visible = fusion ~= nil
	fuseList.Visible = fusion == nil
	if fusion then
		fuseEmpty.Visible = false
		local total = Config.fuseTime(fusion.Pet)
		local left = math.max(fusion.Ends - (os.time() + State.ClockOffset), 0)
		fusingName.Text = (nextSizeName(fusion.Pet) or fusion.Pet):upper()
		fusingTimer.Text = if left > 0 then string.format("Ready in %d:%02d", left // 60, left % 60) else "Ready!"
		bar.Size = UDim2.fromScale(1 - left / total, 1)
		Ui.setStyle(collectButton, if left > 0 then "disabled" else "primary")
		return
	end
	clear(fuseList)
	local names = {}
	for name, n in pairs(data.Pets) do
		if n >= Config.FUSE_COPIES and nextSizeName(name) then
			table.insert(names, name)
		end
	end
	table.sort(names, function(a, b)
		return Config.petPower(a) > Config.petPower(b)
	end)
	for i, name in ipairs(names) do
		local _, size = Config.petInfo(name)
		local result = nextSizeName(name)
		local row = Ui.new("Frame", {
			LayoutOrder = i,
			Size = UDim2.new(1, 0, 0, 58),
			BackgroundColor3 = Ui.GLASS_LIGHT,
			BackgroundTransparency = 0.35,
			ZIndex = 32,
			Parent = fuseList,
		}, { Ui.corner(14), Ui.stroke(Config.SIZES[size.Index + 1].Color, 1.5, 0.4) })
		Ui.new("TextLabel", {
			Position = UDim2.fromOffset(16, 8),
			Size = UDim2.new(1, -170, 0, 22),
			TextScaled = false,
			TextSize = 18,
			Text = name .. "  →  " .. result,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 33,
			Parent = row,
		})
		local seconds = Config.fuseTime(name)
		Ui.new("TextLabel", {
			Position = UDim2.fromOffset(16, 32),
			Size = UDim2.new(1, -170, 0, 16),
			Font = Ui.FONT_MEDIUM,
			TextScaled = false,
			TextSize = 13,
			Text = "x" .. data.Pets[name] .. " owned  ·  " .. string.format("%d:%02d", seconds // 60, seconds % 60)
				.. "  ·  " .. Config.formatNumber(Config.petPower(result)) .. " power",
			TextColor3 = Ui.MUTED,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 33,
			Parent = row,
		})
		Ui.button({
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -10, 0.5, 0),
			Size = UDim2.fromOffset(130, 40),
			Radius = 14,
			Text = "FUSE " .. Config.FUSE_COPIES,
			TextSize = 15,
			ZIndex = 34,
			Parent = row,
		}, function()
			State.remote("FuseStart"):InvokeServer(name)
		end, "primary")
	end
	fuseEmpty.Visible = #names == 0
end

State.remote("FusionOpen").OnClientEvent:Connect(function()
	Screen.open(fusionModal)
	refreshFusion()
end)

task.spawn(function()
	while true do
		task.wait(0.5)
		if fusionModal.Visible and State.Data and State.Data.Fusion then
			refreshFusion()
		end
	end
end)

-- Settings ---------------------------------------------------------------------------------

local settingsModal, settingsBox = Screen.modal(440, 340, "Settings")
Screen.title(settingsBox, "Settings")
local SETTINGS = {
	{ Key = "DamageNumbers", Name = "Damage numbers" },
	{ Key = "Reveals", Name = "Full hatch animation" },
	{ Key = "Sounds", Name = "Sounds" },
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
		Text = "ON",
		TextSize = 16,
		ZIndex = 33,
		Parent = settingsBox,
	}, function()
		State.Settings[setting.Key] = not State.Settings[setting.Key]
		Ui.setText(toggle, if State.Settings[setting.Key] then "ON" else "OFF")
		Ui.setStyle(toggle, if State.Settings[setting.Key] then "success" else "glass")
		Effects.play("Click")
	end, "success")
end

function Panels.openSettings()
	Screen.open(settingsModal)
end

State.watch(function()
	if fusionModal.Visible then
		refreshFusion()
	end
end)

return Panels
