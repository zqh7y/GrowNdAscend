-- Small helpers for building the map out of parts.
local Build = {}

local DEFAULTS = {
	Anchored = true,
	CanCollide = true,
	CastShadow = true,
	TopSurface = Enum.SurfaceType.Smooth,
	BottomSurface = Enum.SurfaceType.Smooth,
	Material = Enum.Material.SmoothPlastic,
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
	p.Parent = parent
	return p
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
