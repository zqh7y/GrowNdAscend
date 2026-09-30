-- Makes the living coins (tagged "Living" by the server) look alive: they
-- hop along the arcs the server picks (HopFrom -> HopTo at HopStart), squash
-- when they land and stretch when they jump, turn to face where they're
-- going, breathe and wobble while waiting, grow in when they appear, and
-- flash and shake when a pet hits them.
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local Living = {}

local HOP_HEIGHT = 2.6
local NEAR = 160 -- only animate coins this close to the camera every frame

-- [model] = { Home = CFrame, Yaw, Scale, Shake, Flash, Highlight, Phase }
local tracked = {}
local byId = {} -- [id] = model

local function track(model)
	if not model:IsA("Model") or tracked[model] then
		return
	end
	local pivot = model:GetPivot()
	tracked[model] = {
		Home = pivot,
		Yaw = 0,
		Scale = 1,
		Shake = 0,
		Phase = math.random() * 10,
	}
	local id = model:GetAttribute("Id")
	if id then
		byId[id] = model
	end
end

local function untrack(model)
	local info = tracked[model]
	if info and info.Highlight then
		info.Highlight:Destroy()
	end
	tracked[model] = nil
	local id = model:GetAttribute("Id")
	if id and byId[id] == model then
		byId[id] = nil
	end
end

for _, model in ipairs(CollectionService:GetTagged("Living")) do
	track(model)
end
CollectionService:GetInstanceAddedSignal("Living"):Connect(track)
CollectionService:GetInstanceRemovedSignal("Living"):Connect(untrack)

-- Where a coin is right now (its feet), as drawn, or nil if it's gone
function Living.position(id)
	local model = byId[id]
	local info = model and tracked[model]
	return info and info.Position
end

-- The coin's model by id
function Living.model(id)
	return byId[id]
end

-- A pet landed a hit: flash white and shake a little
function Living.hit(id, strength)
	local model = byId[id]
	local info = model and tracked[model]
	if not info then
		return
	end
	info.Shake = math.min(info.Shake + 0.35 * (strength or 1), 0.6)
	if not info.Highlight then
		local highlight = Instance.new("Highlight")
		highlight.FillColor = Color3.new(1, 1, 1)
		highlight.OutlineTransparency = 1
		highlight.FillTransparency = 1
		highlight.DepthMode = Enum.HighlightDepthMode.Occluded
		highlight.Parent = model
		info.Highlight = highlight
	end
	info.Flash = 1
end

-- where a hop is at time t (0..1): along the line, up an arc
local function hopPosition(from, to, t)
	local flat = from:Lerp(to, t)
	return flat + Vector3.new(0, math.sin(t * math.pi) * HOP_HEIGHT, 0)
end

-- uniform scale through a hop: crouch before, stretch in the air, squash on landing
local function hopScale(t, sinceLanding)
	if t < 0 then
		return 1
	elseif t < 1 then
		return 1 + math.sin(t * math.pi) * 0.08
	end
	-- landed: a quick squash that springs back
	return 1 - math.exp(-sinceLanding * 10) * math.sin(sinceLanding * 22) * 0.12
end

RunService.RenderStepped:Connect(function(dt)
	local now = Workspace:GetServerTimeNow()
	local clock = os.clock()
	local cameraPos = Workspace.CurrentCamera.CFrame.Position
	for model, info in pairs(tracked) do
		if not model.Parent then
			continue
		end
		local from = model:GetAttribute("HopFrom") or info.Home.Position
		local to = model:GetAttribute("HopTo") or from
		local start = model:GetAttribute("HopStart") or 0
		local t = (now - start) / Config.HOP_TIME
		local position = if t >= 0 and t < 1 then hopPosition(from, to, t) else to
		info.Position = position

		-- far away coins only update now and then
		local far = (position - cameraPos).Magnitude > NEAR
		info.Skip = (info.Skip or 0) + 1
		if far and info.Skip % 10 ~= 0 then
			continue
		end

		-- face the way it's hopping
		local direction = to - from
		if direction.Magnitude > 0.1 then
			local goalYaw = math.atan2(-direction.X, -direction.Z)
			local diff = (goalYaw - info.Yaw + math.pi) % (math.pi * 2) - math.pi
			info.Yaw += diff * math.min(dt * 10, 1)
		end

		-- idle breathing and wobble, plus hit shake
		local breathe = math.sin(clock * 3 + info.Phase) * 0.025
		local wobble = math.sin(clock * 2.2 + info.Phase) * math.rad(4)
		info.Shake = math.max(info.Shake - dt * 2.5, 0)
		local shake = math.sin(clock * 60) * info.Shake * math.rad(12)
		model:PivotTo(CFrame.new(position) * CFrame.Angles(0, info.Yaw, 0) * CFrame.Angles(0, 0, wobble + shake))

		-- grow in when new, then squash and stretch with the hops
		local born = model:GetAttribute("Born") or 0
		local grow = math.clamp((now - born) / 0.5, 0.05, 1)
		local scale = grow * (hopScale(t, (t - 1) * Config.HOP_TIME) + breathe)
		if math.abs(scale - info.Scale) > 0.015 then
			info.Scale = scale
			model:ScaleTo(math.max(scale, 0.05))
		end

		-- fade the hit flash
		if info.Flash then
			info.Flash = math.max(info.Flash - dt * 6, 0)
			info.Highlight.FillTransparency = 1 - info.Flash * 0.7
			if info.Flash == 0 then
				info.Flash = nil
			end
		end
	end
end)

return Living
