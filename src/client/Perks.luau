-- The rebirth perk pads (one in each world, built by World.buildPerkPad):
-- the status pill on each pad's sign turns green and says "Owned" once you
-- have enough rebirths (they're never spent); before that it's grey with
-- "Need 3 rebirths (1/3)" and a bar filling up. The first time you get a
-- perk, a toast says so.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Screen = require(script.Parent.Screen)
local State = require(script.Parent.State)

local Perks = {}

local folder = workspace:WaitForChild("Map"):WaitForChild("Perks", 10)
local known = nil -- the rebirths we last showed (to notice new perks)

local function signOf(index)
	local pad = folder and folder:FindFirstChild("PerkPad" .. index)
	return pad and pad:FindFirstChild("Status")
end

local function statusOf(index)
	local gui = signOf(index)
	return gui and gui:FindFirstChild("Text")
end

local DARK = Color3.fromRGB(46, 50, 80)
local GREEN = Color3.fromRGB(56, 200, 110)
local GREY = Color3.fromRGB(236, 239, 247)

function Perks.refresh()
	local data = State.Data
	if not data then
		return
	end
	local rebirths = data.Rebirths or 0
	for index, perk in ipairs(Config.PERKS) do
		local gui = signOf(index)
		local label = statusOf(index)
		if label then
			local owned = rebirths >= perk.Rebirths
			local pill = gui:FindFirstChild("Pill")
			local bar = gui:FindFirstChild("Bar")
			local fill = bar and bar:FindFirstChild("Fill")
			if owned then
				label.Text = "Owned"
				label.TextColor3 = Color3.new(1, 1, 1)
			else
				label.Text = string.format("Need %d rebirth%s (%d/%d)", perk.Rebirths, if perk.Rebirths == 1 then "" else "s", rebirths, perk.Rebirths)
				label.TextColor3 = DARK
			end
			if pill then
				pill.BackgroundColor3 = if owned then GREEN else GREY
			end
			if bar then
				bar.Visible = not owned
			end
			if fill then
				fill.Size = UDim2.fromScale(math.clamp(rebirths / perk.Rebirths, 0, 1), 1)
			end
		end
		-- a new perk since last time
		if known and known < perk.Rebirths and rebirths >= perk.Rebirths then
			Screen.toast(string.format("New perk: %s (%s)!", perk.Name, Config.perkText(perk)), "success")
		end
	end
	known = rebirths
end
Perks.statusOf = statusOf

State.watch(Perks.refresh)
Perks.refresh()

return Perks
