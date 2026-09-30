-- Small helpers for building models out of parts (the map on the server,
-- living coins on the client).
local Build = {}

local DEFAULTS = {
	Anchored = true,
	CanCollide = true,
	CastShadow = true,
	TopSurface = Enum.SurfaceType.Smooth,
	BottomSurface = Enum.SurfaceType.Smooth,
	Material = Enum.Material.SmoothPlastic,
}

-- The map's look is clean and toy-like: smooth plastic everywhere, with
-- glass (water, ice, domes), neon (glowing bits) and force fields (gates) as
-- the only other materials. Realistic textures (wood grain, slate...) are
-- swapped for smooth plastic.
local KEEP_MATERIAL = {
	[Enum.Material.Glass] = true,
	[Enum.Material.Neon] = true,
	[Enum.Material.ForceField] = true,
}

-- Build.part(parent, { props }) -> anchored Part
function Build.part(parent, props, className)
	local p = Instance.new(className or "Part")
	for k, v in pairs(DEFAULTS) do
		p[k] = v
	end
	for k, v in pairs(props) do
		p[k] = v
	end
	if not KEEP_MATERIAL[p.Material] then
		p.Material = Enum.Material.SmoothPlastic
	end
	p.Parent = parent
	return p
end

-- Sets a model's primary part and puts the model's pivot at `pivot`.
-- (Roblox ignores Model.WorldPivot once a PrimaryPart is set: the pivot is
-- then the primary part's pivot, so it has to be moved with PivotOffset.)
function Build.setPivot(model, primary, pivot)
	model.PrimaryPart = primary
	primary.PivotOffset = primary.CFrame:ToObjectSpace(pivot)
	return model
end

-- Scales a finished model around a point on the ground (so it stays standing
-- on the ground instead of floating or sinking)
function Build.scale(model, ground, factor)
	local primary = model.PrimaryPart
	model.PrimaryPart = nil -- so WorldPivot is used
	model.WorldPivot = CFrame.new(ground)
	model:ScaleTo(factor)
	model.PrimaryPart = primary
	return model
end

-- A cylinder from point a to point b (branches, pipes, bamboo...)
function Build.limb(parent, a, b, diameter, props)
	props = props or {}
	local length = (b - a).Magnitude
	props.Shape = Enum.PartType.Cylinder
	props.Size = Vector3.new(length, diameter, diameter)
	-- lookAt points -Z at b; turning 90 degrees about Y lines the cylinder's X axis up with it
	props.CFrame = CFrame.lookAt((a + b) / 2, b) * CFrame.Angles(0, math.rad(90), 0)
	return Build.part(parent, props)
end

-- Toon-shaded foliage: a few overlapping balls with darker ones underneath
-- and lighter ones on top, so the shape reads nicely from far away
function Build.leafCluster(parent, rng, center, size, color, detail)
	detail = detail or 3 -- balls of each shade; smaller clusters look fine with fewer
	local dark = color:Lerp(Color3.new(0, 0, 0), 0.18)
	local light = color:Lerp(Color3.new(1, 1, 1), 0.22)
	Build.ball(parent, center, size, { Color = Build.vary(rng, color, 0.03) })
	for _ = 1, math.max(detail - 1, 1) do
		local offset = Vector3.new(rng:NextNumber(-0.4, 0.4), rng:NextNumber(-0.35, -0.1), rng:NextNumber(-0.4, 0.4)) * size
		Build.ball(parent, center + offset, size * rng:NextNumber(0.55, 0.7), { Color = Build.vary(rng, dark, 0.03) })
	end
	for _ = 1, detail do
		local offset = Vector3.new(rng:NextNumber(-0.3, 0.3), rng:NextNumber(0.15, 0.32), rng:NextNumber(-0.3, 0.3)) * size
		Build.ball(parent, center + offset, size * rng:NextNumber(0.45, 0.6), { Color = Build.vary(rng, light, 0.03) })
	end
end

-- A cute face for living coins: `cf` is the middle of the face, looking
-- along its -Z (the way the coin hops), `size` scales it
function Build.face(parent, cf, size)
	size = size or 1
	local ink = Color3.fromRGB(45, 45, 70)
	for _, x in ipairs({ -0.38, 0.38 }) do
		Build.ball(parent, (cf * CFrame.new(x * size, 0.1 * size, 0)).Position, 0.42 * size, { Color = ink, CanCollide = false })
		Build.ball(parent, (cf * CFrame.new(x * size - 0.07 * size, 0.2 * size, -0.12 * size)).Position, 0.15 * size, { Color = Color3.new(1, 1, 1), CanCollide = false })
		Build.ball(parent, (cf * CFrame.new(x * size * 1.55, -0.22 * size, 0.05 * size)).Position, 0.34 * size, { Color = Color3.fromRGB(255, 150, 180), CanCollide = false })
	end
	-- a smile: three little dots in a curve
	for k = -1, 1 do
		Build.ball(parent, (cf * CFrame.new(k * 0.16 * size, (-0.32 + math.abs(k) * 0.07) * size, 0)).Position, 0.13 * size, { Color = ink, CanCollide = false })
	end
end

-- A rock made of a few tilted blocks; `cap` (optional) is a colour for moss
-- or snow on top
function Build.rock(parent, rng, base, size, color, cap)
	local model = Build.model(parent, "Rock")
	local pieces = rng:NextInteger(2, 4)
	for k = 1, pieces do
		local s = size * (if k == 1 then 1 else rng:NextNumber(0.45, 0.75))
		local offset = if k == 1 then Vector3.zero else Vector3.new(rng:NextNumber(-0.5, 0.5) * size, 0, rng:NextNumber(-0.5, 0.5) * size)
		local block = Build.part(model, {
			Size = Vector3.new(s * rng:NextNumber(0.9, 1.3), s * rng:NextNumber(0.55, 0.8), s * rng:NextNumber(0.9, 1.2)),
			CFrame = CFrame.new(base + offset + Vector3.new(0, s * 0.22, 0))
				* CFrame.Angles(math.rad(rng:NextNumber(-12, 12)), math.rad(rng:NextNumber(0, 90)), math.rad(rng:NextNumber(-12, 12))),
			Color = Build.vary(rng, color, 0.04),
		})
		if cap and k == 1 then
			Build.part(model, {
				Size = Vector3.new(block.Size.X * 0.85, 0.35, block.Size.Z * 0.85),
				CFrame = block.CFrame * CFrame.new(0, block.Size.Y / 2 + 0.1, 0),
				Color = cap,
				CanCollide = false,
			})
		end
	end
	return model
end

-- Marks a part (or a model, around its pivot) the client spins every frame
-- (the client does the animating, so it's smooth and costs the server
-- nothing). degrees per second, axis in its own space: "X", "Y" or "Z".
local CollectionService = game:GetService("CollectionService")
function Build.spin(part, degreesPerSecond, axis)
	part:SetAttribute("SpinSpeed", degreesPerSecond)
	part:SetAttribute("SpinAxis", axis or "Y")
	CollectionService:AddTag(part, "Spin")
	return part
end

-- Marks a part (or model) the client bobs up and down
function Build.bob(part, height, speed)
	part:SetAttribute("BobHeight", height)
	part:SetAttribute("BobSpeed", speed or 1)
	CollectionService:AddTag(part, "Bob")
	return part
end

function Build.ball(parent, position, diameter, props)
	props = props or {}
	props.Shape = Enum.PartType.Ball
	props.Size = Vector3.new(diameter, diameter, diameter)
	props.CFrame = CFrame.new(position)
	return Build.part(parent, props)
end

-- Upright cylinder standing on `bottom`
function Build.cylinder(parent, bottom, height, diameter, props)
	props = props or {}
	props.Shape = Enum.PartType.Cylinder
	props.Size = Vector3.new(height, diameter, diameter)
	props.CFrame = CFrame.new(bottom + Vector3.new(0, height / 2, 0)) * CFrame.Angles(0, 0, math.rad(90))
	return Build.part(parent, props)
end

-- Block whose bottom-centre sits on `bottom`, turned `yaw` degrees
function Build.block(parent, bottom, size, props, yaw)
	props = props or {}
	props.Size = size
	props.CFrame = CFrame.new(bottom + Vector3.new(0, size.Y / 2, 0)) * CFrame.Angles(0, math.rad(yaw or 0), 0)
	return Build.part(parent, props)
end

function Build.wedge(parent, cframe, size, props)
	props = props or {}
	props.Size = size
	props.CFrame = cframe
	return Build.part(parent, props, "WedgePart")
end

function Build.model(parent, name)
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent
	return m
end

function Build.folder(parent, name)
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

-- Decoration that players walk through and can't click (grass, petals...)
function Build.ghost(p)
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	return p
end

-- A sign: a part with the same text on both faces
function Build.sign(parent, cframe, size, text, textColor, bgColor)
	local board = Build.part(parent, {
		Name = "Sign",
		Size = size,
		CFrame = cframe,
		Color = bgColor,
	})
	for _, face in ipairs({ Enum.NormalId.Front, Enum.NormalId.Back }) do
		local gui = Instance.new("SurfaceGui")
		gui.Face = face
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 40
		gui.LightInfluence = 0.3
		gui.Parent = board
		local label = Instance.new("TextLabel")
		label.Name = "Text"
		label.BackgroundTransparency = 1
		label.Size = UDim2.fromScale(1, 1)
		label.Font = Enum.Font.GothamBlack
		label.TextScaled = true
		label.TextColor3 = textColor
		label.Text = text
		label.Parent = gui
		local pad = Instance.new("UIPadding")
		pad.PaddingTop = UDim.new(0.12, 0)
		pad.PaddingBottom = UDim.new(0.12, 0)
		pad.PaddingLeft = UDim.new(0.04, 0)
		pad.PaddingRight = UDim.new(0.04, 0)
		pad.Parent = label
	end
	return board
end

function Build.setSignText(sign, text)
	for _, gui in ipairs(sign:GetChildren()) do
		if gui:IsA("SurfaceGui") then
			gui.Text.Text = text
		end
	end
end

-- Keeps track of where big decorations are, so breakables and other props
-- don't spawn inside them.
local Space = {}
Space.__index = Space

function Build.space()
	return setmetatable({ circles = {} }, Space)
end

function Space:add(position, radius)
	table.insert(self.circles, { X = position.X, Z = position.Z, R = radius })
end

function Space:free(position, radius)
	for _, c in ipairs(self.circles) do
		local dx, dz = position.X - c.X, position.Z - c.Z
		if dx * dx + dz * dz < (radius + c.R) ^ 2 then
			return false
		end
	end
	return true
end

-- A random free spot in the rectangle (x0..x1, z0..z1) at ground height,
-- or nil if none was found. Marks it as taken.
function Space:find(rng, x0, x1, z0, z1, radius)
	for _ = 1, 40 do
		local p = Vector3.new(rng:NextNumber(x0, x1), 0, rng:NextNumber(z0, z1))
		if self:free(p, radius) then
			self:add(p, radius)
			return p
		end
	end
	return nil
end

-- A colour close to `color`, for natural variety
function Build.vary(rng, color, amount)
	local h, s, v = color:ToHSV()
	amount = amount or 0.06
	return Color3.fromHSV(
		(h + rng:NextNumber(-amount, amount) * 0.3) % 1,
		math.clamp(s + rng:NextNumber(-amount, amount), 0, 1),
		math.clamp(v + rng:NextNumber(-amount, amount), 0, 1)
	)
end

return Build
