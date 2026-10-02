-- The rebirth perk pads (one in each world, built by World.buildPerkPad):
-- under each floating card, "Owned" in green once you have enough rebirths
-- (they're never spent), or "Need 3 rebirths (you have 1)". The first time
-- you get a perk, a toast says so.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Screen = require(script.Parent.Screen)
local State = require(script.Parent.State)

local Perks = {}

local folder = workspace:WaitForChild("Map"):WaitForChild("Perks", 10)
local known = nil -- the rebirths we last showed (to notice new perks)

local function statusOf(index)
	local pad = folder and folder:FindFirstChild("PerkPad" .. index)
	local gui = pad and pad:FindFirstChild("Status")
	return gui and gui:FindFirstChild("Text")
end

function Perks.refresh()
	local data = State.Data
	if not data then
		return
	end
	local rebirths = data.Rebirths or 0
	for index, perk in ipairs(Config.PERKS) do
		local label = statusOf(index)
		if label then
			if rebirths >= perk.Rebirths then
				label.Text = "Owned"
				label.TextColor3 = Color3.fromRGB(130, 255, 150)
			else
				label.Text = string.format("Need %d rebirth%s (you have %d)", perk.Rebirths, if perk.Rebirths == 1 then "" else "s", rebirths)
				label.TextColor3 = Color3.new(1, 1, 1)
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
