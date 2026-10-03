-- The Pet Upgrades stand by the spawn in the Forest: three of your pets
-- stand on its podiums (your team first, then your strongest other pets;
-- the arrows on the sign show the next three), each with its name and level
-- over its head and an UPGRADE button with the price on the green button in
-- front. Clicking it levels that pet up (every copy of it) with coins, up to
-- level 10: the server checks and charges (server/PetLevels.luau), what a
-- level does is in Config (petStat, levelPower). The stand itself is built
-- by the server (World/Forest.luau, "PetUpgrader").
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local Effects = require(script.Parent.Effects)
local PetModels = require(script.Parent.PetModels)
local State = require(script.Parent.State)
local Ui = require(script.Parent.Ui)

local PetUpgrader = {}

local player = Players.LocalPlayer
local upgradeFunction = State.remote("UpgradePet")

local stand = workspace:WaitForChild("Map"):FindFirstChild("PetUpgrader", true)
PetUpgrader.Stand = stand
PetUpgrader.Page = 1
PetUpgrader.Slots = {} -- [1..3] = { Name, Model, Lift, Info, Level, Next, Button }
PetUpgrader.LastResult = nil -- (for the simulator: the server's answer)

local folder = Instance.new("Folder")
folder.Name = "PetUpgraderPets"
folder.Parent = workspace

-- Every pet that can stand on the podiums, in order: the team (each kind
-- once, in slot order), then the rest you own, strongest first
function PetUpgrader.list()
	local data = State.Data
	local list, seen = {}, {}
	if not data then
		return list
	end
	for _, name in ipairs(data.Equipped or {}) do
		if not seen[name] and (data.Pets[name] or 0) > 0 then
			seen[name] = true
			table.insert(list, name)
		end
	end
	local rest = {}
	for name, count in pairs(data.Pets or {}) do
		if not seen[name] and type(count) == "number" and count > 0 and Config.petInfo(name) then
			table.insert(rest, name)
		end
	end
	table.sort(rest, function(a, b)
		local pa, pb = Config.petPower(a) * Config.levelPower(Config.petLevel(data, a)), Config.petPower(b) * Config.levelPower(Config.petLevel(data, b))
		if pa ~= pb then
			return pa > pb
		end
		return a < b
	end)
	for _, name in ipairs(rest) do
		table.insert(list, name)
	end
	return list
end

local function pages()
	return math.max(1, math.ceil(#PetUpgrader.list() / 3))
end

local refresh

-- Levels the pet on podium i up (asks the server)
function PetUpgrader.upgrade(i)
	local slot = PetUpgrader.Slots[i]
	if not slot or not slot.Name then
		return false
	end
	local ok, level = pcall(upgradeFunction.InvokeServer, upgradeFunction, slot.Name)
	local result = ok and level or false
	PetUpgrader.LastResult = result
	if result then
		Effects.play("Coin", 1.3, 0.05)
		local podium = stand and stand:FindFirstChild("Podium" .. i, true)
		if podium then
			Effects.burst(podium.Position + Vector3.new(0, 3, 0), Color3.fromRGB(110, 230, 120))
		end
		slot.Pop = 0.35
	end
	refresh()
	return result
end

-- the guis over each podium and on each button
for i = 1, 3 do
	local podium = stand and stand:FindFirstChild("Podium" .. i, true)
	local buttonPart = stand and stand:FindFirstChild("Button" .. i, true)
	local info = Ui.new("BillboardGui", {
		Name = "PetUpgradeInfo" .. i,
		Size = UDim2.fromOffset(190, 66),
		StudsOffsetWorldSpace = Vector3.new(0, 7.2, 0),
		LightInfluence = 0,
		MaxDistance = 70,
		ResetOnSpawn = false,
		Adornee = podium,
		Parent = player:WaitForChild("PlayerGui"),
	})
	local nameLabel = Ui.chunky({
		Name = "PetName",
		Size = UDim2.new(1, 0, 0, 24),
		TextSize = 22,
		Text = "",
		Parent = info,
	})
	local levelLabel = Ui.chunky({
		Name = "Level",
		Position = UDim2.fromOffset(0, 24),
		Size = UDim2.new(1, 0, 0, 22),
		TextSize = 20,
		Text = "",
		Colors = { Color3.fromRGB(255, 240, 120), Color3.fromRGB(255, 170, 40) },
		Parent = info,
	})
	local nextLabel = Ui.chunky({
		Name = "Next",
		Position = UDim2.fromOffset(0, 46),
		Size = UDim2.new(1, 0, 0, 18),
		Font = Enum.Font.FredokaOne,
		TextSize = 15,
		Text = "",
		TextColor3 = Color3.fromRGB(190, 255, 190),
		Parent = info,
	})
	local buttonGui = Ui.new("BillboardGui", {
		Name = "PetUpgradeButton" .. i,
		Size = UDim2.fromOffset(150, 46),
		StudsOffsetWorldSpace = Vector3.new(0, 1.8, 0),
		LightInfluence = 0,
		MaxDistance = 50,
		Active = true,
		ResetOnSpawn = false,
		Adornee = buttonPart,
		Parent = player.PlayerGui,
	})
	local button = Ui.button({
		Size = UDim2.fromScale(1, 1),
		Radius = 16,
		Text = "UPGRADE",
		Icon = "coin",
		TextSize = 18,
		Parent = buttonGui,
	}, function()
		PetUpgrader.upgrade(i)
	end, "success")
	PetUpgrader.Slots[i] = { Info = info, NameLabel = nameLabel, Level = levelLabel, Next = nextLabel, ButtonGui = buttonGui, Button = button, Podium = podium }
end

-- the arrows on the sign: the next / previous three pets
local signPart = stand and stand:FindFirstChild("Sign", true)
local pager = Ui.new("BillboardGui", {
	Name = "PetUpgradePages",
	Size = UDim2.fromOffset(170, 40),
	StudsOffsetWorldSpace = Vector3.new(0, -2.6, 0),
	LightInfluence = 0,
	MaxDistance = 60,
	Active = true,
	ResetOnSpawn = false,
	Adornee = signPart,
	Parent = player.PlayerGui,
})
PetUpgrader.Pager = pager
local function arrow(text, x, step)
	return Ui.button({
		AnchorPoint = Vector2.new(x, 0),
		Position = UDim2.fromScale(x, 0),
		Size = UDim2.fromOffset(44, 40),
		Radius = 14,
		Text = text,
		TextSize = 20,
		Parent = pager,
	}, function()
		PetUpgrader.Page = (PetUpgrader.Page - 1 + step) % pages() + 1
		refresh()
	end, "primary")
end
arrow("<", 0, -1)
arrow(">", 1, 1)
local pageLabel = Ui.chunky({
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(70, 30),
	TextSize = 20,
	Text = "1/1",
	Parent = pager,
})
PetUpgrader.PageLabel = pageLabel

-- puts a pet's model on podium i (or clears it)
local function place(slot, name)
	if slot.Name == name then
		return
	end
	if slot.Model then
		slot.Model:Destroy()
		slot.Model = nil
	end
	slot.Name = name
	if not name then
		return
	end
	local _, size = Config.petInfo(name)
	local model = PetModels.build(name)
	-- big enough to see, not taller than the arch
	local scale = math.min(size.Scale, 2) * 1.35
	pcall(function()
		model:ScaleTo(scale)
	end)
	slot.Lift = 1.5 * scale
	pcall(function()
		local box, extent = model:GetBoundingBox()
		local pivot = model:GetPivot()
		slot.Lift = pivot.Position.Y - (box.Position.Y - extent.Y / 2)
	end)
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanQuery = false
		end
	end
	model.Parent = folder
	slot.Model = model
	slot.Pop = 0.35
end

function refresh()
	local data = State.Data
	if not data then
		return
	end
	local list = PetUpgrader.list()
	local count = pages()
	PetUpgrader.Page = math.clamp(PetUpgrader.Page, 1, count)
	pageLabel.Text = PetUpgrader.Page .. "/" .. count
	pager.Enabled = count > 1
	for i, slot in ipairs(PetUpgrader.Slots) do
		local name = list[(PetUpgrader.Page - 1) * 3 + i]
		place(slot, name)
		slot.Info.Enabled = name ~= nil
		slot.ButtonGui.Enabled = name ~= nil
		if name then
			local level = Config.petLevel(data, name)
			slot.NameLabel.Text = Config.displayName(name)
			slot.Level.Text = "LV " .. level .. " / " .. Config.PET_LEVEL_MAX
			if level >= Config.PET_LEVEL_MAX then
				slot.Next.Text = "Max level! x" .. string.format("%.1f", Config.levelPower(level)) .. " power"
				Ui.setText(slot.Button, "MAX")
				Ui.setStyle(slot.Button, "disabled")
			else
				local cost = Config.petLevelCost(name, level)
				slot.Next.Text = string.format("x%.1f -> x%.1f power, stats up", Config.levelPower(level), Config.levelPower(level + 1))
				Ui.setText(slot.Button, Config.formatNumber(cost))
				Ui.setStyle(slot.Button, if data.Coins >= cost then "success" else "disabled")
			end
		end
	end
end
PetUpgrader.refresh = refresh

-- the pets turn slowly and bob on their podiums (and pop when upgraded)
local clock = 0
RunService.Heartbeat:Connect(function(dt)
	clock += dt
	for i, slot in ipairs(PetUpgrader.Slots) do
		local model, podium = slot.Model, slot.Podium
		if model and podium then
			local pop = 0
			if slot.Pop and slot.Pop > 0 then
				slot.Pop = math.max(slot.Pop - dt, 0)
				pop = math.sin(slot.Pop / 0.35 * math.pi) * 1.2
			end
			local top = podium.Position + Vector3.new(0, podium.Size.X / 2 + (slot.Lift or 1.5) + 0.1 + pop + math.abs(math.sin(clock * 2 + i)) * 0.25, 0)
			local face = Vector3.new(top.X, top.Y, 0) - top
			local look = if face.Magnitude > 0.01 then face.Unit else Vector3.new(0, 0, -1)
			local turn = math.sin(clock * 0.8 + i * 2) * 0.35
			model:PivotTo(CFrame.lookAt(top, top + look) * CFrame.Angles(0, turn, 0))
		end
	end
end)

State.watch(refresh)
refresh()

return PetUpgrader
