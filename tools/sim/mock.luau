-- A small fake Roblox environment, just enough to run the server code and
-- catch runtime errors. Math types are real; instances store properties.

-- Vector3 -------------------------------------------------------------------
local V3 = {}
V3.__index = function(v, k)
	if k == "Magnitude" then
		return math.sqrt(v.X * v.X + v.Y * v.Y + v.Z * v.Z)
	elseif k == "Unit" then
		local m = math.sqrt(v.X * v.X + v.Y * v.Y + v.Z * v.Z)
		if m == 0 then
			return v
		end
		return Vector3.new(v.X / m, v.Y / m, v.Z / m)
	end
	return V3[k]
end
local function isV(x)
	return type(x) == "table" and getmetatable(x) == V3
end
Vector3 = {}
function Vector3.new(x, y, z)
	return setmetatable({ X = x or 0, Y = y or 0, Z = z or 0 }, V3)
end
Vector3.zero = Vector3.new(0, 0, 0)
Vector3.one = Vector3.new(1, 1, 1)
V3.__add = function(a, b)
	assert(isV(a) and isV(b), "Vector3 + non-Vector3")
	return Vector3.new(a.X + b.X, a.Y + b.Y, a.Z + b.Z)
end
V3.__sub = function(a, b)
	assert(isV(a) and isV(b), "Vector3 - non-Vector3")
	return Vector3.new(a.X - b.X, a.Y - b.Y, a.Z - b.Z)
end
V3.__mul = function(a, b)
	if type(a) == "number" then
		a, b = b, a
	end
	if type(b) == "number" then
		return Vector3.new(a.X * b, a.Y * b, a.Z * b)
	end
	assert(isV(b), "Vector3 * bad type")
	return Vector3.new(a.X * b.X, a.Y * b.Y, a.Z * b.Z)
end
V3.__div = function(a, b)
	assert(type(b) == "number", "Vector3 / non-number")
	return Vector3.new(a.X / b, a.Y / b, a.Z / b)
end
V3.__unm = function(a)
	return Vector3.new(-a.X, -a.Y, -a.Z)
end
V3.__eq = function(a, b)
	return a.X == b.X and a.Y == b.Y and a.Z == b.Z
end
function V3.Lerp(a, b, t)
	return a + (b - a) * t
end
function V3.Dot(a, b)
	return a.X * b.X + a.Y * b.Y + a.Z * b.Z
end
function V3.Cross(a, b)
	return Vector3.new(a.Y * b.Z - a.Z * b.Y, a.Z * b.X - a.X * b.Z, a.X * b.Y - a.Y * b.X)
end

-- CFrame (rotation matrix rows r, position p) --------------------------------
local CF = {}
local function isCF(x)
	return type(x) == "table" and getmetatable(x) == CF
end
local function mk(p, r)
	return setmetatable({ p = p, r = r }, CF)
end
local I = { { 1, 0, 0 }, { 0, 1, 0 }, { 0, 0, 1 } }
local function mulR(a, b)
	local c = {}
	for i = 1, 3 do
		c[i] = {}
		for j = 1, 3 do
			c[i][j] = a[i][1] * b[1][j] + a[i][2] * b[2][j] + a[i][3] * b[3][j]
		end
	end
	return c
end
local function apply(r, v)
	return Vector3.new(
		r[1][1] * v.X + r[1][2] * v.Y + r[1][3] * v.Z,
		r[2][1] * v.X + r[2][2] * v.Y + r[2][3] * v.Z,
		r[3][1] * v.X + r[3][2] * v.Y + r[3][3] * v.Z
	)
end
CFrame = {}
function CFrame.new(x, y, z)
	if x == nil then
		return mk(Vector3.zero, I)
	end
	if isV(x) then
		return mk(x, I)
	end
	assert(type(x) == "number" and type(y) == "number" and type(z) == "number", "CFrame.new bad args")
	return mk(Vector3.new(x, y, z), I)
end
function CFrame.Angles(rx, ry, rz)
	assert(type(rx) == "number" and type(ry) == "number" and type(rz) == "number", "CFrame.Angles needs numbers")
	local cx, sx, cy, sy, cz, sz = math.cos(rx), math.sin(rx), math.cos(ry), math.sin(ry), math.cos(rz), math.sin(rz)
	local X = { { 1, 0, 0 }, { 0, cx, -sx }, { 0, sx, cx } }
	local Y = { { cy, 0, sy }, { 0, 1, 0 }, { -sy, 0, cy } }
	local Z = { { cz, -sz, 0 }, { sz, cz, 0 }, { 0, 0, 1 } }
	return mk(Vector3.zero, mulR(mulR(X, Y), Z))
end
function CFrame.lookAt(at, target, up)
	assert(isV(at) and isV(target), "CFrame.lookAt needs Vector3s")
	up = up or Vector3.new(0, 1, 0)
	local look = (target - at).Unit
	local right = look:Cross(up).Unit
	if right.Magnitude < 0.5 then
		right = Vector3.new(1, 0, 0)
	end
	local up2 = right:Cross(look)
	local back = -look
	return mk(at, {
		{ right.X, up2.X, back.X },
		{ right.Y, up2.Y, back.Y },
		{ right.Z, up2.Z, back.Z },
	})
end
CF.__index = function(c, k)
	if k == "Position" then
		return c.p
	elseif k == "X" then
		return c.p.X
	elseif k == "Y" then
		return c.p.Y
	elseif k == "Z" then
		return c.p.Z
	elseif k == "Rotation" then
		return mk(Vector3.zero, c.r)
	elseif k == "LookVector" then
		return Vector3.new(-c.r[1][3], -c.r[2][3], -c.r[3][3])
	elseif k == "RightVector" then
		return Vector3.new(c.r[1][1], c.r[2][1], c.r[3][1])
	elseif k == "UpVector" then
		return Vector3.new(c.r[1][2], c.r[2][2], c.r[3][2])
	end
	return CF[k]
end
CF.__mul = function(a, b)
	assert(isCF(a), "CFrame * : left is not a CFrame")
	if isV(b) then
		return a.p + apply(a.r, b)
	end
	assert(isCF(b), "CFrame * : right is not a CFrame or Vector3")
	return mk(a.p + apply(a.r, b.p), mulR(a.r, b.r))
end
CF.__add = function(a, b)
	assert(isCF(a) and isV(b), "CFrame + needs Vector3")
	return mk(a.p + b, a.r)
end
CF.__sub = function(a, b)
	assert(isCF(a) and isV(b), "CFrame - needs Vector3")
	return mk(a.p - b, a.r)
end
-- Gram-Schmidt on the rotation's columns
function ORTHONORMALIZE(c)
	local r = c.r
	local x = Vector3.new(r[1][1], r[2][1], r[3][1])
	local y = Vector3.new(r[1][2], r[2][2], r[3][2])
	if x.Magnitude < 1e-9 or y.Magnitude < 1e-9 then
		return c
	end
	x = x.Unit
	y = (y - x * x:Dot(y)).Unit
	local z = x:Cross(y)
	return mk(c.p, { { x.X, y.X, z.X }, { x.Y, y.Y, z.Y }, { x.Z, y.Z, z.Z } })
end
function CF.Lerp(a, b, t)
	return mk(a.p:Lerp(b.p, t), b.r)
end
function CF.ToObjectSpace(a, b)
	return a:Inverse() * b
end
function CF.Inverse(c)
	local t = { { c.r[1][1], c.r[2][1], c.r[3][1] }, { c.r[1][2], c.r[2][2], c.r[3][2] }, { c.r[1][3], c.r[2][3], c.r[3][3] } }
	return mk(-apply(t, c.p), t)
end

-- Color3 and friends ----------------------------------------------------------
local C3 = {}
C3.__index = C3
Color3 = {}
function Color3.new(r, g, b)
	assert(type(r) == "number" and type(g) == "number" and type(b) == "number", "Color3.new needs numbers")
	return setmetatable({ R = r, G = g, B = b }, C3)
end
function Color3.fromRGB(r, g, b)
	assert(r and g and b and r <= 255 and g <= 255 and b <= 255 and r >= 0 and g >= 0 and b >= 0, "fromRGB out of range")
	return Color3.new(r / 255, g / 255, b / 255)
end
function Color3.fromHSV(h, s, v)
	assert(h >= 0 and h <= 1 and s >= 0 and s <= 1 and v >= 0 and v <= 1, "fromHSV out of range")
	return Color3.new(v, v, v)
end
function C3.ToHSV(c)
	return 0.3, 0.5, math.max(c.R, c.G, c.B)
end
function C3.ToHex(c)
	return string.format("%02x%02x%02x", c.R * 255, c.G * 255, c.B * 255)
end
function C3.Lerp(a, b, t)
	assert(getmetatable(b) == C3, "Color3:Lerp needs a Color3")
	return Color3.new(a.R + (b.R - a.R) * t, a.G + (b.G - a.G) * t, a.B + (b.B - a.B) * t)
end

local function valueType(name)
	local t = {}
	t.new = function(...)
		return { __type = name, ... }
	end
	return t
end
UDim = {}
function UDim.new(scale, offset)
	return { Scale = scale or 0, Offset = offset or 0 }
end
local U2 = {}
U2.__index = U2
UDim2 = {}
function UDim2.new(xs, xo, ys, yo)
	for _, v in ipairs({ xs or 0, xo or 0, ys or 0, yo or 0 }) do
		assert(type(v) == "number" and v == v, "UDim2 needs numbers")
	end
	return setmetatable({ X = UDim.new(xs, xo), Y = UDim.new(ys, yo) }, U2)
end
function UDim2.fromOffset(x, y)
	return UDim2.new(0, x, 0, y)
end
function UDim2.fromScale(x, y)
	return UDim2.new(x, 0, y, 0)
end
U2.__add = function(a, b)
	return UDim2.new(a.X.Scale + b.X.Scale, a.X.Offset + b.X.Offset, a.Y.Scale + b.Y.Scale, a.Y.Offset + b.Y.Offset)
end
U2.__sub = function(a, b)
	return UDim2.new(a.X.Scale - b.X.Scale, a.X.Offset - b.X.Offset, a.Y.Scale - b.Y.Scale, a.Y.Offset - b.Y.Offset)
end
local V2 = {}
V2.__index = V2
Vector2 = {}
function Vector2.new(x, y)
	return setmetatable({ X = x or 0, Y = y or 0 }, V2)
end
V2.__add = function(a, b) return Vector2.new(a.X + b.X, a.Y + b.Y) end
V2.__sub = function(a, b) return Vector2.new(a.X - b.X, a.Y - b.Y) end
V2.__mul = function(a, b)
	if type(a) == "number" then a, b = b, a end
	return Vector2.new(a.X * b, a.Y * b)
end
V2.__div = function(a, b) return Vector2.new(a.X / b, a.Y / b) end
function V2.Lerp(a, b, t)
	return Vector2.new(a.X + (b.X - a.X) * t, a.Y + (b.Y - a.Y) * t)
end
V2.__index = function(v, k)
	if k == "Magnitude" then return math.sqrt(v.X * v.X + v.Y * v.Y) end
	return V2[k]
end
ColorSequenceKeypoint = valueType("ColorSequenceKeypoint")
NumberSequence = valueType("NumberSequence")
NumberSequenceKeypoint = valueType("NumberSequenceKeypoint")
ColorSequence = valueType("ColorSequence")
NumberRange = valueType("NumberRange")
TweenInfo = valueType("TweenInfo")
RaycastParams = {}
function RaycastParams.new()
	return {}
end
Region3 = {}
function Region3.new(a, b)
	assert(isV(a) and isV(b), "Region3.new needs Vector3s")
	return {
		ExpandToGrid = function(self, n)
			assert(n == 4, "ExpandToGrid resolution")
			return self
		end,
	}
end

-- Enum: any Enum.X.Y is a unique value
Enum = setmetatable({}, {
	__index = function(t, group)
		local g = setmetatable({}, {
			__index = function(gt, name)
				local v = { EnumType = group, Name = name }
				rawset(gt, name, v)
				return v
			end,
		})
		rawset(t, group, g)
		return g
	end,
})

-- Random
local RandomMT = {}
RandomMT.__index = RandomMT
Random = {}
local seedCounter = 0
function Random.new(seed)
	seedCounter += 1
	if seed then
		math.randomseed(seed)
	end
	return setmetatable({ s = seed or seedCounter }, RandomMT)
end
function RandomMT:NextNumber(a, b)
	-- Luau's own generator (a simple LCG here had correlated draws and
	-- skewed the rarity statistics)
	local u = math.random()
	if a == nil then
		return u
	end
	assert(type(a) == "number" and type(b) == "number", "NextNumber bad args")
	return a + (b - a) * u
end
function RandomMT:NextInteger(a, b)
	assert(a <= b, "NextInteger min > max")
	return math.floor(self:NextNumber(a, b + 0.999999))
end

-- Instances --------------------------------------------------------------------
STATS = { Parts = 0, ByClass = {}, Errors = {} }

local function signal()
	local callbacks = {}
	return {
		Connect = function(self, fn)
			assert(type(fn) == "function", "Connect needs a function")
			table.insert(callbacks, fn)
			return { Disconnect = function() end }
		end,
		Wait = function() end,
		Fire = function(self, ...)
			for _, fn in ipairs(callbacks) do
				task.spawn(fn, ...)
			end
		end,
	}
end

local BASEPART = { Part = true, WedgePart = true, SpawnLocation = true, CornerWedgePart = true, MeshPart = true, TrussPart = true }
local GUI = { Frame = true, TextLabel = true, TextButton = true, ScrollingFrame = true, ImageLabel = true }
local SIGNALS = {
	MouseClick = true, Triggered = true, Event = true, OnServerEvent = true, OnClientEvent = true, PlayerAdded = true,
	PlayerRemoving = true, Changed = true, Activated = true, MouseEnter = true, MouseLeave = true,
	MouseButton1Down = true, MouseButton1Up = true, Heartbeat = true, RenderStepped = true, CharacterAdded = true,
	ChildAdded = true, ChildRemoved = true,
}

local InstMT = {}
local methods = {}

function methods:IsA(class)
	if self.ClassName == class then
		return true
	end
	if class == "BasePart" then
		return BASEPART[self.ClassName] == true
	end
	if class == "GuiObject" then
		return GUI[self.ClassName] == true
	end
	if class == "Instance" then
		return true
	end
	return false
end
function methods:GetChildren()
	local list = {}
	for _, c in ipairs(rawget(self, "_children")) do
		table.insert(list, c)
	end
	return list
end
function methods:GetDescendants()
	local list = {}
	local function walk(x)
		for _, c in ipairs(rawget(x, "_children")) do
			table.insert(list, c)
			walk(c)
		end
	end
	walk(self)
	return list
end
function methods:FindFirstChild(name)
	for _, c in ipairs(rawget(self, "_children")) do
		if c.Name == name then
			return c
		end
	end
	return nil
end
methods.WaitForChild = function(self, name)
	local c = methods.FindFirstChild(self, name)
	assert(c, "WaitForChild would hang forever: " .. tostring(name) .. " in " .. tostring(self.Name))
	return c
end
function methods:FindFirstChildOfClass(class)
	for _, c in ipairs(rawget(self, "_children")) do
		if c.ClassName == class then
			return c
		end
	end
	return nil
end
function methods:FindFirstChildWhichIsA(class)
	for _, c in ipairs(rawget(self, "_children")) do
		if c:IsA(class) then
			return c
		end
	end
	return nil
end
function methods:SetAttribute(k, v)
	rawget(self, "_attrs")[k] = v
end
function methods:GetAttribute(k)
	return rawget(self, "_attrs")[k]
end
function methods:Destroy()
	self.Parent = nil
end
function methods:ClearAllChildren()
	for _, c in ipairs(self:GetChildren()) do
		c.Parent = nil
	end
end
function methods:GetPivot()
	assert(self.ClassName == "Model" or BASEPART[self.ClassName], "GetPivot on " .. self.ClassName)
	if self.ClassName == "Model" then
		-- like Roblox: with a PrimaryPart the pivot is that part's pivot
		-- (its CFrame * PivotOffset) and WorldPivot is ignored
		local primary = rawget(self, "_props").PrimaryPart
		if primary then
			return primary.CFrame * (rawget(primary, "_props").PivotOffset or CFrame.new())
		end
		if rawget(self, "_props").WorldPivot then
			return rawget(self, "_props").WorldPivot
		end
		local first = self:FindFirstChildWhichIsA("BasePart")
		return if first then first.CFrame else CFrame.new()
	end
	return self.CFrame
end
function methods:PivotTo(cf)
	assert(isCF(cf), "PivotTo needs a CFrame")
	rawget(self, "_props").DrawnAt = cf
	-- like Roblox: every part moves with the pivot
	if self.ClassName == "Model" then
		local delta = cf * self:GetPivot():Inverse()
		for _, d in ipairs(self:GetDescendants()) do
			if BASEPART[d.ClassName] then
				d.CFrame = delta * d.CFrame
			end
		end
		if not rawget(self, "_props").PrimaryPart then
			rawget(self, "_props").WorldPivot = cf
		end
	else
		self.CFrame = cf
	end
end
function methods:ScaleTo(n)
	assert(self.ClassName == "Model", "ScaleTo on non-model")
	assert(type(n) == "number" and n > 0, "ScaleTo needs a positive number")
	assert(#self:GetDescendants() > 0, "ScaleTo on an empty model errors in Roblox")
	-- parts scale about the pivot
	local pivot = self:GetPivot()
	local ratio = n / (rawget(self, "_props").Scale or 1)
	rawget(self, "_props").Scale = n
	for _, d in ipairs(self:GetDescendants()) do
		if BASEPART[d.ClassName] then
			local rel = pivot:ToObjectSpace(d.CFrame)
			d.CFrame = pivot * CFrame.new(rel.Position * ratio) * rel.Rotation
			d.Size = d.Size * ratio
			-- a part's pivot offset scales with it (so the model's pivot stays put)
			local offset = rawget(d, "_props").PivotOffset
			if offset then
				rawget(d, "_props").PivotOffset = CFrame.new(offset.Position * ratio) * offset.Rotation
			end
		end
	end
end
function methods:GetBoundingBox()
	local lo, hi
	for _, d in ipairs(self:GetDescendants()) do
		if BASEPART[d.ClassName] then
			local half = d.Size / 2
			local r = math.max(half.X, half.Y, half.Z)
			local p = d.CFrame.Position
			local a, b = p - Vector3.new(r, r, r), p + Vector3.new(r, r, r)
			lo = if lo then Vector3.new(math.min(lo.X, a.X), math.min(lo.Y, a.Y), math.min(lo.Z, a.Z)) else a
			hi = if hi then Vector3.new(math.max(hi.X, b.X), math.max(hi.Y, b.Y), math.max(hi.Z, b.Z)) else b
		end
	end
	assert(lo, "GetBoundingBox on an empty model")
	return CFrame.new((lo + hi) / 2), hi - lo
end
function methods:GetExtentsSize()
	return Vector3.new(4, 5, 4)
end
function methods:Clone()
	return Instance.new(self.ClassName)
end
-- terrain: every fill is remembered so raycasts can find the real surface
TERRAIN_OPS = {}
function methods:FillBlock(cf, size, mat)
	assert(isCF(cf) and isV(size) and type(mat) == "table", "FillBlock args")
	local p = cf.Position
	table.insert(TERRAIN_OPS, { Kind = "block", X0 = p.X - size.X / 2, X1 = p.X + size.X / 2, Z0 = p.Z - size.Z / 2, Z1 = p.Z + size.Z / 2, Y0 = p.Y - size.Y / 2, Y1 = p.Y + size.Y / 2, Air = mat.Name == "Air" })
end
function methods:FillBall(center, radius, mat)
	assert(isV(center) and type(radius) == "number" and type(mat) == "table", "FillBall args")
	table.insert(TERRAIN_OPS, { Kind = "ball", C = center, R = radius, Air = mat.Name == "Air" })
end
function methods:FillCylinder(cf, height, radius, mat)
	assert(isCF(cf) and type(height) == "number" and type(radius) == "number" and type(mat) == "table", "FillCylinder args")
	local p = cf.Position
	table.insert(TERRAIN_OPS, { Kind = "cylinder", C = p, R = radius, Y0 = p.Y - height / 2, Y1 = p.Y + height / 2, Air = mat.Name == "Air" })
end
-- the surface height at (x, z) after all the fills, or nil
-- Roblox's real terrain surface doesn't come out at exactly Y = 0 (in the
-- game it was 1.63), so the mock's ground sits a little higher too: code
-- that assumes Y = 0 fails here the way it fails in Roblox
TERRAIN_OFFSET = 1.63
function TERRAIN_HEIGHT(x, z)
	local h = nil
	for _, op in ipairs(TERRAIN_OPS) do
		local inside, top, bottom = false, nil, nil
		if op.Kind == "block" then
			inside = x >= op.X0 and x <= op.X1 and z >= op.Z0 and z <= op.Z1
			top, bottom = op.Y1, op.Y0
		elseif op.Kind == "ball" then
			local d = math.sqrt((x - op.C.X) ^ 2 + (z - op.C.Z) ^ 2)
			if d < op.R then
				inside = true
				local rise = math.sqrt(op.R ^ 2 - d ^ 2)
				top, bottom = op.C.Y + rise, op.C.Y - rise
			end
		else
			inside = math.sqrt((x - op.C.X) ^ 2 + (z - op.C.Z) ^ 2) < op.R
			top, bottom = op.Y1, op.Y0
		end
		if inside then
			if op.Air then
				if h and h > bottom then
					h = math.min(h, bottom)
				end
			else
				h = math.max(h or -math.huge, top)
			end
		end
	end
	return h and h + TERRAIN_OFFSET
end
function methods:Raycast(origin, direction, params)
	assert(isV(origin) and isV(direction), "Raycast needs Vector3s")
	local h = TERRAIN_HEIGHT(origin.X, origin.Z)
	if h and h <= origin.Y and h >= origin.Y + direction.Y then
		return { Position = Vector3.new(origin.X, h, origin.Z), Normal = Vector3.new(0, 1, 0), Instance = workspace.Terrain }
	end
	return nil
end
function methods:BulkMoveTo(parts, cframes, mode)
	assert(type(parts) == "table" and type(cframes) == "table" and #parts == #cframes, "BulkMoveTo lists")
	for i, p in ipairs(parts) do
		assert(getmetatable(cframes[i]) ~= nil, "BulkMoveTo needs CFrames")
		p.CFrame = cframes[i]
	end
end
function methods:ReplaceMaterial(region, res, from, to)
	assert(type(region) == "table" and res == 4 and type(from) == "table" and type(to) == "table", "ReplaceMaterial args")
end
function methods:SetMaterialColor(mat, color)
	assert(type(mat) == "table" and getmetatable(color) == C3, "SetMaterialColor args")
end
-- services
PLAYERS = {}
function methods:GetPlayers()
	return table.clone(PLAYERS)
end
function methods:GetDataStore()
	return { GetAsync = function() error("no API access") end, SetAsync = function() end }
end
function methods:GetOrderedDataStore()
	return { GetSortedAsync = function() error("no API access") end, SetAsync = function() end }
end
local TAGS = {} -- [tag] = { instances }
local TAG_SIGNALS = {}
local function tagSignals(tag)
	TAG_SIGNALS[tag] = TAG_SIGNALS[tag] or { Added = signal(), Removed = signal() }
	return TAG_SIGNALS[tag]
end
function methods:AddTag(inst, tag)
	assert(type(tag) == "string" and getmetatable(inst) == InstMT, "AddTag")
	TAGS[tag] = TAGS[tag] or {}
	table.insert(TAGS[tag], inst)
	rawget(inst, "_attrs")["__tag_" .. tag] = true
	tagSignals(tag).Added:Fire(inst)
end
function methods:GetTagged(tag)
	local list = {}
	for _, inst in ipairs(TAGS[tag] or {}) do
		if rawget(inst, "_props").Parent then
			table.insert(list, inst)
		end
	end
	return list
end
function methods:GetInstanceAddedSignal(tag)
	return tagSignals(tag).Added
end
function methods:GetInstanceRemovedSignal(tag)
	return tagSignals(tag).Removed
end
function methods:Create(inst, info, goals)
	assert(getmetatable(inst) == InstMT, "Tween target must be an Instance")
	assert(type(goals) == "table", "Tween goals")
	return { Play = function() end, Cancel = function() end, Completed = signal() }
end
function methods:GetPlayerByUserId()
	return nil
end
function methods:FireClient(player, ...)
	if self.ClassName == "RemoteEvent" then
		self.OnClientEvent:Fire(...)
	end
end
function methods:FireAllClients(...)
	self.OnClientEvent:Fire(...)
end
function methods:InvokeServer(...)
	assert(self.ClassName == "RemoteFunction", "InvokeServer on " .. self.ClassName)
	assert(self.OnServerInvoke, "no server handler for " .. self.Name)
	return self.OnServerInvoke(LOCAL_PLAYER, ...)
end
function methods:GetAttributeChangedSignal(name)
	assert(type(name) == "string", "GetAttributeChangedSignal")
	return self.Changed
end
function methods:GetPropertyChangedSignal(name)
	assert(type(name) == "string", "GetPropertyChangedSignal")
	return self.Changed
end
function methods:WorldToViewportPoint(v)
	assert(isV(v), "WorldToViewportPoint needs a Vector3")
	return Vector3.new(400, 300, 10), true
end
function methods:Play() end
function methods:Stop() end
function methods:ClearAllChildren()
	for _, c in ipairs(self:GetChildren()) do
		c.Parent = nil
	end
end
function methods:GetScale()
	return 1
end
function methods:GetServerTimeNow()
	return CLOCK
end
function methods:BindToClose(fn)
	assert(type(fn) == "function", "BindToClose")
end
function methods:LoadCharacter() end
function methods:Emit(n)
	assert(self.ClassName == "ParticleEmitter", "Emit on " .. self.ClassName)
end
function methods:GetNameFromUserIdAsync()
	return "Player"
end
function methods:Fire(...)
	-- BindableEvents: fire the Event signal's callbacks
	if self.ClassName == "BindableEvent" then
		self.Event:Fire(...)
	end
end

InstMT.__index = function(self, k)
	local props = rawget(self, "_props")
	if props[k] ~= nil then
		return props[k]
	end
	if k == "Position" and props.CFrame then
		return props.CFrame.Position
	end
	if k == "AbsolutePosition" or k == "AbsoluteSize" then
		return Vector2.new(100, 50)
	end
	if k == "ViewportSize" then
		return Vector2.new(1280, 760)
	end
	if methods[k] then
		return methods[k]
	end
	if SIGNALS[k] then
		local s = signal()
		props[k] = s
		return s
	end
	for _, c in ipairs(rawget(self, "_children")) do
		if c.Name == k then
			return c
		end
	end
	return nil
end
InstMT.__newindex = function(self, k, v)
	local props = rawget(self, "_props")
	if k == "Parent" then
		local old = props.Parent
		if old then
			local list = rawget(old, "_children")
			for i, c in ipairs(list) do
				if c == self then
					table.remove(list, i)
					break
				end
			end
		end
		if v then
			assert(getmetatable(v) == InstMT, "Parent must be an Instance")
			table.insert(rawget(v, "_children"), self)
		end
		props.Parent = v
		-- tell listeners (only if someone connected, like Roblox)
		if old and rawget(old, "_props").ChildRemoved then
			rawget(old, "_props").ChildRemoved:Fire(self)
		end
		if v and rawget(v, "_props").ChildAdded then
			rawget(v, "_props").ChildAdded:Fire(self)
		end
		return
	end
	if k == "CFrame" then
		assert(isCF(v), "CFrame property must be a CFrame (" .. tostring(self.Name) .. ")")
		-- like Roblox, a part's rotation is kept orthonormal (so tiny float
		-- errors from moving things every frame never build up)
		v = ORTHONORMALIZE(v)
	elseif k == "Size" and BASEPART[self.ClassName] then
		assert(isV(v), "Part Size must be a Vector3")
		assert(v.X >= 0 and v.Y >= 0 and v.Z >= 0, "negative part size on " .. tostring(self.Name))
		assert(v.X == v.X and v.Y == v.Y and v.Z == v.Z, "NaN part size")
	elseif k == "Color" and BASEPART[self.ClassName] then
		assert(getmetatable(v) == C3, "Part Color must be a Color3")
	elseif (k == "Material" or k == "Shape") then
		assert(type(v) == "table" and v.EnumType, k .. " must be an Enum")
	elseif k == "PrimaryPart" and v ~= nil then
		assert(BASEPART[v.ClassName], "PrimaryPart must be a part")
	end
	props[k] = v
end

Instance = {}
function Instance.new(class, parent)
	local inst = setmetatable({ _props = { ClassName = class, Name = class }, _children = {}, _attrs = {} }, InstMT)
	if BASEPART[class] then
		STATS.Parts += 1
		rawget(inst, "_props").CFrame = CFrame.new()
		rawget(inst, "_props").Size = Vector3.new(4, 1, 2)
		rawget(inst, "_props").Color = Color3.new(0.5, 0.5, 0.5)
		rawget(inst, "_props").Transparency = 0
	end
	if GUI[class] then
		local props = rawget(inst, "_props")
		props.BackgroundTransparency = 0
		props.Visible = true
		props.Rotation = 0
		props.Position = UDim2.new(0, 0, 0, 0)
		props.Size = UDim2.new(0, 100, 0, 100)
		props.TextTransparency = 0
		props.Text = ""
	end
	if class == "UIScale" then
		rawget(inst, "_props").Scale = 1
	end
	if class == "Camera" then
		rawget(inst, "_props").FieldOfView = 70
	end
	if class == "Humanoid" then
		rawget(inst, "_props").CameraOffset = Vector3.zero
	end
	STATS.ByClass[class] = (STATS.ByClass[class] or 0) + 1
	if parent then
		inst.Parent = parent
	end
	return inst
end

local services = {}
game = Instance.new("DataModel")
function methods:GetService(name)
	if not services[name] then
		local s = Instance.new(name)
		s.Name = name
		s.Parent = game
		services[name] = s
	end
	return services[name]
end
workspace = game:GetService("Workspace")
local terrain = Instance.new("Terrain")
terrain.Name = "Terrain"
terrain.Parent = workspace
rawset(rawget(workspace, "_props"), "Terrain", terrain)

-- task: a fake clock. Threads that wait are resumed by STEP(dt).
CLOCK = 0
local realOs = os
os = setmetatable({ clock = function() return CLOCK end, time = function() return math.floor(CLOCK) + 1000000 end }, { __index = realOs })
local timers = {} -- { Wake, Thread, Args }
task = {}
local function resume(co, ...)
	local ok, err = coroutine.resume(co, ...)
	if not ok then
		table.insert(STATS.Errors, "thread: " .. tostring(err) .. "\n" .. debug.traceback(co))
	end
end
function task.spawn(fn, ...)
	local co = if type(fn) == "thread" then fn else coroutine.create(fn)
	resume(co, ...)
	return co
end
function task.wait(n)
	local co = coroutine.running()
	if not coroutine.isyieldable() then
		return 0
	end
	table.insert(timers, { Wake = CLOCK + (n or 0.03), Thread = co })
	coroutine.yield()
	return n or 0
end
function task.delay(n, fn, ...)
	table.insert(timers, { Wake = CLOCK + (n or 0), Thread = coroutine.create(fn), Args = table.pack(...) })
end
function STEP(dt)
	CLOCK += dt
	local due = {}
	for i = #timers, 1, -1 do
		if timers[i].Wake <= CLOCK then
			table.insert(due, table.remove(timers, i))
		end
	end
	for _, t in ipairs(due) do
		if t.Args then
			resume(t.Thread, table.unpack(t.Args, 1, t.Args.n))
		else
			resume(t.Thread)
		end
	end
end
function task.defer(fn, ...)
	return task.spawn(fn, ...)
end
function warn(...) end
function typeof(x)
	if isV(x) then
		return "Vector3"
	elseif isCF(x) then
		return "CFrame"
	end
	return type(x)
end
