-- The client's copy of the player's data, the local settings, and the
-- remotes. Every screen reads from here and listens to State.Changed.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local State = {}

State.Data = nil -- latest data from the server (nil until it loads)
State.ClockOffset = 0 -- server os.time() minus ours, for the fusion timer
State.Changed = Instance.new("BindableEvent") -- fires with no arguments after new data
State.Settings = {
	DamageNumbers = true,
	FullHatch = false, -- false: the compact hatch row at the top; true: the big centred hatch
	Reveals = true, -- the spin before a roll's result shows
	Sounds = true,
}

local remotes = ReplicatedStorage:WaitForChild("Remotes")
function State.remote(name)
	return remotes:WaitForChild(name)
end

State.remote("State").OnClientEvent:Connect(function(data)
	State.Data = data
	State.ClockOffset = data.ServerTime - os.time()
	State.Changed:Fire()
end)

-- Runs fn now if data is loaded, and every time it changes
function State.watch(fn)
	if State.Data then
		task.spawn(fn)
	end
	return State.Changed.Event:Connect(fn)
end

return State
