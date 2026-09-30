-- Little 3D previews of pets for the Inventory and the Index: a
-- ViewportFrame with the pet's model, turned three-quarters to the camera.
-- A "silhouette" preview is the same animal in solid dark (not found yet).
-- Previews are cached by name, so reopening a panel doesn't rebuild models;
-- take one with PetView.take(name, silhouette) and give it back with
-- PetView.release(view) before its cell is destroyed.
local PetModels = require(script.Parent.PetModels)

local PetView = {}

local free = {} -- [key] = { ViewportFrame }

local function key(name, silhouette)
	return name .. (if silhouette then "#" else "")
end

local function build(name, silhouette)
	local view = Instance.new("ViewportFrame")
	view.BackgroundTransparency = 1
	view.Ambient = Color3.fromRGB(190, 190, 210)
	view.LightColor = Color3.fromRGB(255, 250, 240)
	view.LightDirection = Vector3.new(-0.5, -1, -0.7)
	if silhouette then
		view.ImageColor3 = Color3.fromRGB(12, 14, 32)
		view.ImageTransparency = 0.1
	end
	local model = PetModels.build(name, silhouette)
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("ParticleEmitter") or d:IsA("Light") then
			d:Destroy()
		end
	end
	model:PivotTo(CFrame.Angles(0, math.rad(-35), 0))
	model.Parent = view
	local camera = Instance.new("Camera")
	camera.FieldOfView = 30
	-- the model's pet size is already part of the model; frame it to fit
	local _, size = model:GetBoundingBox()
	local radius = math.max(size.X, size.Y, size.Z) * 0.62
	local distance = radius / math.tan(math.rad(camera.FieldOfView / 2))
	camera.CFrame = CFrame.lookAt(Vector3.new(0, radius * 0.25, -distance), Vector3.new(0, 0, 0))
	camera.Parent = view
	view.CurrentCamera = camera
	view:SetAttribute("Key", key(name, silhouette))
	return view
end

function PetView.take(name, silhouette)
	local list = free[key(name, silhouette)]
	local view = list and table.remove(list)
	return view or build(name, silhouette)
end

function PetView.release(view)
	local k = view:GetAttribute("Key")
	view.Parent = nil
	free[k] = free[k] or {}
	table.insert(free[k], view)
end

-- Gives back every preview inside `container` (before clearing it)
function PetView.releaseAll(container)
	for _, d in ipairs(container:GetDescendants()) do
		if d:IsA("ViewportFrame") and d:GetAttribute("Key") then
			PetView.release(d)
		end
	end
end

return PetView
