-- Keeping you in the game:
--   No reset: the Roblox menu's "Reset Character" is turned off (StarterGui
--   SetCore "ResetButtonCallback" false; retried until the core UI is ready).
--   No AFK kick: Roblox disconnects players after about 20 idle minutes.
--   When Roblox says you've gone idle (Player.Idled, after ~2 minutes), the
--   game presses a virtual mouse button for you, which resets that timer, so
--   you can stay AFK (auto roll, pets fighting) as long as you like.
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

local Session = {}

Session.ResetDisabled = false
Session.IdleNudges = 0 -- (for the simulator)

-- turns off the reset button (the core UI may not be ready right at the start)
task.spawn(function()
	for _ = 1, 40 do
		local ok = pcall(StarterGui.SetCore, StarterGui, "ResetButtonCallback", false)
		if ok then
			Session.ResetDisabled = true
			return
		end
		task.wait(0.5)
	end
end)

-- a virtual click whenever Roblox says you've been idle
function Session.nudge()
	Session.IdleNudges += 1
	pcall(function()
		local VirtualUser = game:GetService("VirtualUser")
		VirtualUser:CaptureController()
		VirtualUser:ClickButton2(Vector2.new())
	end)
end

Players.LocalPlayer.Idled:Connect(Session.nudge)

return Session
