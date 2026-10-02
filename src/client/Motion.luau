-- Animates map decorations on the client: parts or models tagged "Spin" turn
-- around one of their own axes, parts tagged "Bob" float up and down. The server
-- only tags them (see World/Build), so the motion is smooth and free.
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local spinning = {} -- [part] = { Origin = CFrame, Angle = radians turned so far }
local bobbing = {} -- [part] = { Origin = CFrame }

local function getCFrame(thing)
	return if thing:IsA("Model") then thing:GetPivot() else thing.CFrame
end
local function setCFrame(thing, cframe)
	if thing:IsA("Model") then
		thing:PivotTo(cframe)
	else
		thing.CFrame = cframe
	end
end

local function track(list)
	return function(thing)
		if thing:IsA("BasePart") or thing:IsA("Model") then
			list[thing] = { Origin = getCFrame(thing), Angle = 0 }
		end
	end
end
local function untrack(list)
	return function(part)
		list[part] = nil
	end
end

for tag, list in pairs({ Spin = spinning, Bob = bobbing }) do
	for _, part in ipairs(CollectionService:GetTagged(tag)) do
		track(list)(part)
	end
	CollectionService:GetInstanceAddedSignal(tag):Connect(track(list))
	CollectionService:GetInstanceRemovedSignal(tag):Connect(untrack(list))
end

local AXES = {
	X = function(a)
		return CFrame.Angles(a, 0, 0)
	end,
	Y = function(a)
		return CFrame.Angles(0, a, 0)
	end,
	Z = function(a)
		return CFrame.Angles(0, 0, a)
	end,
}

RunService.RenderStepped:Connect(function(dt)
	local t = os.clock()
	for part, spin in pairs(spinning) do
		-- the speed can change (the fusion machine speeds up), so keep adding
		spin.Angle += math.rad(part:GetAttribute("SpinSpeed") or 0) * dt
		if not bobbing[part] then -- (a part that also bobs is placed below)
			local rotate = AXES[part:GetAttribute("SpinAxis") or "Y"] or AXES.Y
			setCFrame(part, spin.Origin * rotate(spin.Angle))
		end
	end
	for part, bob in pairs(bobbing) do
		local origin = bob.Origin
		local spin = spinning[part]
		if spin then
			-- spinning and bobbing: turn first, then float
			local rotate = AXES[part:GetAttribute("SpinAxis") or "Y"] or AXES.Y
			origin = spin.Origin * rotate(spin.Angle)
		end
		local height = part:GetAttribute("BobHeight") or 0.5
		local speed = part:GetAttribute("BobSpeed") or 1
		local phase = bob.Origin.Position.X * 0.37 + bob.Origin.Position.Z * 0.21 -- so they don't all move together
		setCFrame(part, origin + Vector3.new(0, math.sin(t * speed * 2 + phase) * height, 0))
	end
end)

return {}
