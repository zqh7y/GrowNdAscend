-- Feedback effects: sounds, damage numbers, coins popping out of broken
-- living coins and flying into the coin counter, and confetti.
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local Ui = require(script.Parent.Ui)
local Screen = require(script.Parent.Screen)
local State = require(script.Parent.State)

local Effects = {}

-- Sounds ------------------------------------------------------------------------------

-- Built-in Roblox sounds, so nothing needs uploading. Swap any id for a
-- Creator Store sound ("rbxassetid://123...") to change it.
Effects.SOUNDS = {
	Coin = "rbxasset://sounds/electronicpingshort.wav",
	Hit = "rbxasset://sounds/snap.mp3",
	Click = "rbxasset://sounds/button.wav",
	Roll = "rbxasset://sounds/button.wav",
}

local sounds = {}
for name, id in pairs(Effects.SOUNDS) do
	local sound = Instance.new("Sound")
	sound.Name = name
	sound.SoundId = id
	sound.Volume = 0.5
	sound.Parent = SoundService
	sounds[name] = sound
end

local lastPlayed = {}
-- Plays a sound (at most every `gap` seconds), pitched by `pitch`
function Effects.play(name, pitch, gap)
	if not State.Settings.Sounds or not sounds[name] then
		return
	end
	local now = os.clock()
	if gap and lastPlayed[name] and now - lastPlayed[name] < gap then
		return
	end
	lastPlayed[name] = now
	local sound = sounds[name]:Clone()
	sound.PlaybackSpeed = pitch or 1
	sound.Parent = SoundService
	sound:Play()
	task.delay(2, function()
		sound:Destroy()
	end)
end

-- a rising "ding ding ding!" for rare pets, made from the coin sound
function Effects.jingle(notes)
	for k = 0, (notes or 3) - 1 do
		task.delay(k * 0.11, Effects.play, "Coin", 1 + k * 0.25)
	end
end

-- Things floating in the world ------------------------------------------------------------

local function worldLabel(position, text, color, size, rise, duration)
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Size = Vector3.one
	anchor.CFrame = CFrame.new(position)
	anchor.Parent = Workspace
	local billboard = Ui.new("BillboardGui", {
		Size = UDim2.fromOffset(160, 44),
		AlwaysOnTop = true,
		MaxDistance = 90,
		Adornee = anchor,
		Parent = anchor,
	})
	local label = Ui.new("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		TextScaled = false,
		TextSize = size,
		Text = text,
		TextColor3 = color,
		TextStrokeColor3 = Color3.fromRGB(20, 20, 40),
		TextStrokeTransparency = 0.2,
		Parent = billboard,
	})
	local scale = Ui.new("UIScale", { Scale = 0.4, Parent = label })
	TweenService:Create(scale, TweenInfo.new(0.18, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	TweenService:Create(billboard, TweenInfo.new(duration, Enum.EasingStyle.Quad), { StudsOffsetWorldSpace = Vector3.new(0, rise, 0) }):Play()
	TweenService:Create(label, TweenInfo.new(duration * 0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, duration * 0.5), {
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	}):Play()
	task.delay(duration, function()
		anchor:Destroy()
	end)
end

-- A damage number over something a pet hit; colour shows the pet's size
function Effects.damage(position, amount, sizeIndex)
	if not State.Settings.DamageNumbers then
		return
	end
	local size = Config.SIZES[sizeIndex or 1]
	local jitter = Vector3.new(math.random(-10, 10) / 10, math.random(0, 10) / 10, math.random(-10, 10) / 10)
	worldLabel(position + jitter, Config.formatNumber(amount), if sizeIndex and sizeIndex > 1 then size.Color else Color3.new(1, 1, 1), 20 + (sizeIndex or 1) * 3, 3, 0.7)
end

-- A burst of bits when a living coin breaks
function Effects.burst(position, color)
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Size = Vector3.one
	anchor.CFrame = CFrame.new(position)
	anchor.Parent = Workspace
	for _, spec in ipairs({ { color, 26, 0.7 }, { Ui.GOLD, 14, 0.5 }, { Color3.new(1, 1, 1), 8, 0.4 } }) do
		local emitter = Instance.new("ParticleEmitter")
		emitter.Color = ColorSequence.new(spec[1])
		emitter.Size = NumberSequence.new(spec[3], 0)
		emitter.Lifetime = NumberRange.new(0.5, 0.9)
		emitter.Speed = NumberRange.new(10, 20)
		emitter.SpreadAngle = Vector2.new(180, 180)
		emitter.Acceleration = Vector3.new(0, -30, 0)
		emitter.Rate = 0
		emitter.Parent = anchor
		emitter:Emit(spec[2])
	end
	task.delay(1.2, function()
		anchor:Destroy()
	end)
end

-- A soft full-screen flash that fades out (rebirths, big moments)
function Effects.flash(color, seconds)
	local veil = Ui.new("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = color or Color3.new(1, 1, 1),
		BackgroundTransparency = if Ui.reduced() then 0.7 else 0.2,
		ZIndex = 90,
		Parent = Screen.Gui,
	})
	game:GetService("TweenService"):Create(veil, TweenInfo.new(seconds or 0.4, Enum.EasingStyle.Quad), { BackgroundTransparency = 1 }):Play()
	task.delay((seconds or 0.4) + 0.05, function()
		veil:Destroy()
	end)
end

-- Coins flying into the counter ---------------------------------------------------------

Effects.CoinTarget = nil -- the HUD's coin icon (set by the HUD)
Effects.CoinLanded = Instance.new("BindableEvent") -- fires as each flying coin arrives

function Effects.coins(position, amount)
	worldLabel(position, "+" .. Config.formatNumber(amount), Ui.GOLD, 28, 5, 1.1)
	Effects.play("Coin", 1 + math.random() * 0.15, 0.05)

	local camera = Workspace.CurrentCamera
	local screenPos, onScreen = camera:WorldToViewportPoint(position)
	local target = Effects.CoinTarget
	if not onScreen or not target then
		return
	end
	local scale = Screen.Gui:FindFirstChildOfClass("UIScale").Scale
	local goal = target.AbsolutePosition + target.AbsoluteSize / 2
	for k = 1, math.min(3 + math.floor(math.log10(amount + 1)), 7) do
		local coin = Ui.new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(screenPos.X / scale + math.random(-30, 30), screenPos.Y / scale + math.random(-30, 30)),
			Size = UDim2.fromOffset(18, 18),
			BackgroundColor3 = Ui.GOLD,
			ZIndex = 50,
			Parent = Screen.Gui,
		}, { Ui.corner(0.5), Ui.stroke(Color3.fromRGB(255, 240, 180), 2) })
		local fly = TweenService:Create(coin, TweenInfo.new(0.55 + k * 0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.fromOffset(goal.X / scale, goal.Y / scale),
			Size = UDim2.fromOffset(12, 12),
		})
		fly.Completed:Connect(function()
			coin:Destroy()
			Effects.CoinLanded:Fire()
		end)
		task.delay(k * 0.03, function()
			fly:Play()
		end)
	end
end

-- Confetti for big moments ---------------------------------------------------------------

local CONFETTI = {
	Color3.fromRGB(255, 90, 170), Color3.fromRGB(255, 205, 50), Color3.fromRGB(80, 220, 255),
	Color3.fromRGB(120, 230, 120), Color3.fromRGB(180, 120, 255),
}

function Effects.confetti(count, zIndex)
	if Ui.reduced() then
		count = math.ceil(count / 4)
	end
	for _ = 1, count do
		local piece = Ui.new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(math.random(), 0, -0.05, 0),
			Size = UDim2.fromOffset(math.random(8, 14), math.random(12, 20)),
			Rotation = math.random(0, 360),
			BackgroundColor3 = CONFETTI[math.random(1, #CONFETTI)],
			ZIndex = zIndex or 45,
			Parent = Screen.Gui,
		}, { Ui.corner(3) })
		local duration = math.random(18, 30) / 10
		TweenService:Create(piece, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.new(piece.Position.X.Scale + math.random(-15, 15) / 100, 0, 1.1, 0),
			Rotation = piece.Rotation + math.random(-360, 360),
		}):Play()
		task.delay(duration, function()
			piece:Destroy()
		end)
	end
end

return Effects
