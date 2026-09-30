-- The ground as the player experiences it: what a ray straight down hits,
-- counting anything solid you could stand on (terrain, the map, and any
-- other floor that's in the place), but never things that move around
-- (living coins, pets, wild animals, characters) or see-through decorations
-- you'd walk through (CanCollide off).
--
-- Living coins, pets and wild animals all stand on this, so they're on
-- whatever surface the player is walking on. At start it also prints what's
-- under the player to Output, to make ground problems easy to spot.
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Ground = {}

local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
params.RespectCanCollide = true

local function refresh()
	local list = {}
	for _, name in ipairs({ "LivingCoins", "Pets", "Ambient" }) do
		local folder = Workspace:FindFirstChild(name)
		if folder then
			table.insert(list, folder)
		end
	end
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character then
			table.insert(list, player.Character)
		end
	end
	params.FilterDescendantsInstances = list
end
refresh()
Workspace.ChildAdded:Connect(refresh)
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(refresh)
end)
for _, player in ipairs(Players:GetPlayers()) do
	player.CharacterAdded:Connect(refresh)
end

-- The ground height under (x, z), looking down from `fromY`; nil if none
function Ground.at(x, z, fromY, depth)
	local hit = Workspace:Raycast(Vector3.new(x, fromY, z), Vector3.new(0, -(depth or 80), 0), params)
	return hit and hit.Position.Y, hit and hit.Instance
end

-- Prints what's under the player: the thing hit, its height, and the
-- terrain's height there (if they differ, something else is the floor)
function Ground.report()
	local character = Players.LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	local p = root.Position
	local y, instance = Ground.at(p.X, p.Z, p.Y + 2, 60)
	local terrainParams = RaycastParams.new()
	terrainParams.FilterType = Enum.RaycastFilterType.Include
	terrainParams.FilterDescendantsInstances = { Workspace.Terrain }
	local terrainHit = Workspace:Raycast(Vector3.new(p.X, p.Y + 2, p.Z), Vector3.new(0, -60, 0), terrainParams)
	local name = "nothing"
	if instance then
		local ok, full = pcall(function()
			return instance:GetFullName()
		end)
		name = if ok then full else instance.Name
	end
	print(string.format("[Ground] you are standing on %s at Y %.2f; terrain there is at Y %s",
		name, y or 0, if terrainHit then string.format("%.2f", terrainHit.Position.Y) else "none"))
	if instance and instance ~= Workspace.Terrain then
		warn("[Ground] you are standing on a part, not the terrain: " .. name .. " (things now stand on it too)")
	end
end

task.delay(6, Ground.report)

return Ground
