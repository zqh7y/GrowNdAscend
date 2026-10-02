-- The boss bar: while you're in a boss world (the Lava Arena), a wide bar
-- under the level shows the boss's name and health, how many coins a second
-- you're making here (great for AFK), and "Next boss in 4s" while it comes
-- back. It slides in a moment after you arrive, so it doesn't sit on top of
-- the world banner.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local Screen = require(script.Parent.Screen)
local State = require(script.Parent.State)
local Ui = require(script.Parent.Ui)

local BossBar = {}

local coinsFolder = ReplicatedStorage:WaitForChild("LivingCoins")
local WIDTH = 440

local bar = Ui.new("Frame", {
	Name = "BossBar",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 186),
	Size = UDim2.fromOffset(WIDTH, 62),
	BackgroundTransparency = 1,
	Visible = false,
	ZIndex = 15,
	Parent = Screen.Gui,
})
BossBar.Frame = bar
local name = Ui.new("TextLabel", {
	Name = "BossName",
	Size = UDim2.new(1, 0, 0, 24),
	BackgroundTransparency = 1,
	Font = Enum.Font.FredokaOne,
	TextSize = 24,
	TextColor3 = Color3.new(1, 1, 1),
	TextStrokeTransparency = 1,
	Text = "",
	ZIndex = 16,
	Parent = bar,
})
Ui.new("UIStroke", { Color = Color3.fromRGB(110, 40, 20), Thickness = 2.5, Parent = name })
local back = Ui.new("Frame", {
	Position = UDim2.fromOffset(0, 27),
	Size = UDim2.new(1, 0, 0, 20),
	BackgroundColor3 = Color3.fromRGB(60, 30, 30),
	ZIndex = 16,
	Parent = bar,
}, { Ui.corner(10), Ui.stroke(Color3.new(1, 1, 1), 2, 0) })
local fill = Ui.new("Frame", {
	Name = "Fill",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.new(1, 1, 1),
	ZIndex = 17,
	Parent = back,
}, {
	Ui.corner(10),
	Ui.new("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(255, 190, 70), Color3.fromRGB(255, 90, 50)) }),
})
local health = Ui.new("TextLabel", {
	Name = "Health",
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBlack,
	TextSize = 13,
	TextColor3 = Color3.new(1, 1, 1),
	TextStrokeColor3 = Color3.fromRGB(60, 20, 10),
	TextStrokeTransparency = 0.3,
	Text = "",
	ZIndex = 18,
	Parent = back,
})
local income = Ui.new("TextLabel", {
	Name = "Income",
	Position = UDim2.fromOffset(0, 49),
	Size = UDim2.new(1, 0, 0, 14),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBold,
	TextSize = 13,
	TextColor3 = Ui.GOLD,
	TextStrokeColor3 = Color3.fromRGB(40, 30, 10),
	TextStrokeTransparency = 0.4,
	Text = "",
	ZIndex = 16,
	Parent = bar,
})
BossBar.Name, BossBar.Fill, BossBar.Health, BossBar.Income = name, fill, health, income

local function currentArea()
	local character = Players.LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root then Config.areaAt(root.Position.X) else 1
end

-- the boss alive in `area` (its data record), or nil
local function bossOf(area)
	for _, data in ipairs(coinsFolder:GetChildren()) do
		if data:GetAttribute("Area") == area then
			return data
		end
	end
	return nil
end

local enteredAt = nil
local samples = {} -- { time, coins } while here, for coins a second
local goneAt = nil

function BossBar.refresh()
	local area = currentArea()
	local boss = Config.AREAS[area].Boss
	if not boss then
		bar.Visible = false
		enteredAt, goneAt = nil, nil
		table.clear(samples)
		return
	end
	local now = os.clock()
	if not enteredAt then
		enteredAt = now
	end
	-- (a moment after arriving, so the world banner shows first)
	if now - enteredAt < 2.5 then
		return
	end
	if not bar.Visible then
		bar.Visible = true
		if not Ui.reduced() then
			bar.Position = UDim2.new(0.5, 0, 0, 170)
			TweenService:Create(bar, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Position = UDim2.new(0.5, 0, 0, 186) }):Play()
		end
	end
	local enemy = Config.AREAS[area].Breakable
	local data = bossOf(area)
	if data then
		goneAt = nil
		local hp, max = data:GetAttribute("Health") or 0, data:GetAttribute("MaxHealth") or 1
		name.Text = string.upper(enemy.Name)
		fill.Size = UDim2.fromScale(math.clamp(hp / max, 0, 1), 1)
		health.Text = Config.formatNumber(math.max(hp, 0)) .. " / " .. Config.formatNumber(max)
	else
		goneAt = goneAt or now
		name.Text = string.upper(enemy.Name) .. " DEFEATED!"
		fill.Size = UDim2.fromScale(0, 1)
		health.Text = string.format("Next boss in %ds", math.max(math.ceil(6 - (now - goneAt)), 0))
	end
	-- coins a second over the last 10 seconds here
	local coins = State.Data and State.Data.Coins
	if coins then
		table.insert(samples, { now, coins })
		while #samples > 1 and now - samples[1][1] > 10 do
			table.remove(samples, 1)
		end
		local first = samples[1]
		local span = now - first[1]
		local rate = if span > 1 then math.max(coins - first[2], 0) / span else 0
		income.Text = if rate > 0 then "+" .. Config.formatNumber(rate) .. " coins / s" else "Your pets fight the boss from anywhere here"
	end
end

task.spawn(function()
	while true do
		task.wait(0.25)
		BossBar.refresh()
	end
end)

return BossBar
