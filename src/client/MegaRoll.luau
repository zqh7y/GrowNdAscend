-- The Mega Roll pad in the Sahara: a sign over the pile of dice shows
-- the roll waiting for you ("x50,000 Roll!", a random insanely high luck
-- multiplier) and "Claim in 19m 26s" until it's ready. When it's ready the
-- sign says so; step on the pad and the roll goes into your Inventory's
-- Boosts, to use whenever you like (client/Boosts.luau).
-- The server builds the pad (World.buildMegaRoll) and gives the roll
-- (Rolling.megaRoll); this draws the sign and claims it.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local Effects = require(script.Parent.Effects)
local Screen = require(script.Parent.Screen)
local State = require(script.Parent.State)
local Ui = require(script.Parent.Ui)

local MegaRoll = {}

local player = Players.LocalPlayer
local megaFunction = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("MegaRoll")
local model = workspace:WaitForChild("Map"):WaitForChild("MegaRoll")
local signPart = model:WaitForChild("Sign")
local padPart = model:WaitForChild("Pad")

local DARK = Color3.fromRGB(24, 30, 70)

-- the sign: big white "x50,000 Roll!" and the timer under it
local sign = Ui.new("BillboardGui", {
	Name = "MegaRollSign",
	Adornee = signPart,
	Size = UDim2.fromScale(16, 5),
	LightInfluence = 0,
	MaxDistance = 140,
	AlwaysOnTop = false,
	ResetOnSpawn = false,
	Parent = player:WaitForChild("PlayerGui"),
})
MegaRoll.Sign = sign

local function outlined(props, thickness)
	local label = Ui.new("TextLabel", props)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextStrokeTransparency = 1
	Ui.new("UIStroke", { Color = DARK, Thickness = thickness, LineJoinMode = Enum.LineJoinMode.Round, Parent = label })
	return label
end

MegaRoll.Title = outlined({
	Name = "Title",
	Size = UDim2.fromScale(1, 0.58),
	Text = "",
	TextColor3 = Ui.WHITE,
	Parent = sign,
}, 4)
MegaRoll.Timer = outlined({
	Name = "Timer",
	Position = UDim2.fromScale(0, 0.6),
	Size = UDim2.fromScale(1, 0.36),
	Text = "",
	TextColor3 = Color3.fromRGB(150, 220, 255),
	Parent = sign,
}, 3)
local titleScale = Ui.new("UIScale", { Parent = MegaRoll.Title })

local claiming = false
local wasReady = nil

local function remaining(data)
	return (data.MegaReady or 0) - workspace:GetServerTimeNow()
end

-- redraws the sign from the player's data
function MegaRoll.refresh()
	local data = State.Data
	if not data or not data.MegaMult then
		MegaRoll.Title.Text = "Mega Roll"
		MegaRoll.Timer.Text = ""
		return
	end
	MegaRoll.Title.Text = "x" .. Config.commas(data.MegaMult) .. " Roll!"
	local left = remaining(data)
	local ready = left <= 0
	if ready then
		MegaRoll.Timer.Text = "Ready! Step on the pad"
		MegaRoll.Timer.TextColor3 = Color3.fromRGB(130, 255, 150)
	else
		MegaRoll.Timer.Text = "Claim in " .. Config.countdown(left)
		MegaRoll.Timer.TextColor3 = Color3.fromRGB(150, 220, 255)
	end
	-- the moment it becomes ready: a little pop
	if ready and wasReady == false and not Ui.reduced() then
		titleScale.Scale = 1.25
		TweenService:Create(titleScale, TweenInfo.new(0.5, Enum.EasingStyle.Back), { Scale = 1 }):Play()
		Effects.play("Click", 1.3)
	end
	wasReady = ready
end

-- true if the character stands on the pad
local function onPad()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return false
	end
	local p = padPart.Position
	local flat = Vector3.new(root.Position.X - p.X, 0, root.Position.Z - p.Z)
	return flat.Magnitude <= Config.MEGA_ROLL.Radius
end

-- claims the Mega Roll (if it's ready and you're on the pad); plays the show
function MegaRoll.claim()
	local data = State.Data
	if claiming or not data or not data.MegaMult or remaining(data) > 0 then
		return false
	end
	claiming = true
	local ok, mega = pcall(megaFunction.InvokeServer, megaFunction)
	local got = ok and type(mega) == "number"
	if got then
		MegaRoll.LastClaim = mega
		Screen.toast("x" .. Config.commas(mega) .. " Luck Roll added to your Inventory (Boosts)!", "success")
		Effects.jingle(3)
	end
	claiming = false
	MegaRoll.refresh()
	return got
end

-- checks the pad: claim when standing on it with the roll ready
function MegaRoll.check()
	MegaRoll.refresh()
	if onPad() then
		task.spawn(MegaRoll.claim)
	end
end

local since = 0
RunService.Heartbeat:Connect(function(dt)
	since += dt
	if since >= 0.25 then
		since = 0
		MegaRoll.check()
	end
end)
State.watch(MegaRoll.refresh)
MegaRoll.refresh()

return MegaRoll
