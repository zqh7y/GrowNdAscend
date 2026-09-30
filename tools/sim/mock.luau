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
function CF.Lerp(a, b, t)
	return mk(a.p:Lerp(b.p, t), b.r)
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
UDim = valueType("UDim")
UDim2 = valueType("UDim2")
UDim2.fromOffset = UDim2.new
UDim2.fromScale = UDim2.new
Vector2 = valueType("Vector2")
NumberSequence = valueType("NumberSequence")
NumberSequenceKeypoint = valueType("NumberSequenceKeypoint")
ColorSequence = valueType("ColorSequence")
NumberRange = valueType("NumberRange")
TweenInfo = valueType("TweenInfo")
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
	return setmetatable({ s = seed or seedCounter }, RandomMT)
end
function RandomMT:NextNumber(a, b)
	self.s = (self.s * 1103515245 + 12345) % 2147483648
	local u = self.s / 2147483648
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
	return {
		Connect = function(self, fn)
			assert(type(fn) == "function", "Connect needs a function")
			return { Disconnect = function() end }
		end,
		Wait = function() end,
		Fire = function() end,
	}
end

local BASEPART = { Part = true, WedgePart = true, SpawnLocation = true, CornerWedgePart = true, MeshPart = true, TrussPart = true }
local GUI = { Frame = true, TextLabel = true, TextButton = true, ScrollingFrame = true, ImageLabel = true }
local SIGNALS = {
	MouseClick = true, Triggered = true, Event = true, OnServerEvent = true, OnClientEvent = true, PlayerAdded = true,
	PlayerRemoving = true, Changed = true, Activated = true, MouseEnter = true, MouseLeave = true,
	MouseButton1Down = true, MouseButton1Up = true, Heartbeat = true, RenderStepped = true, CharacterAdded = true,
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
		if rawget(self, "_props").WorldPivot then
			return rawget(self, "_props").WorldPivot
		end
		if self.PrimaryPart then
			return self.PrimaryPart.CFrame
		end
		local first = self:FindFirstChildWhichIsA("BasePart")
		return if first then first.CFrame else CFrame.new()
	end
	return self.CFrame
end
function methods:PivotTo(cf)
	assert(isCF(cf), "PivotTo needs a CFrame")
end
function methods:ScaleTo(n)
	assert(self.ClassName == "Model", "ScaleTo on non-model")
	assert(type(n) == "number" and n > 0, "ScaleTo needs a positive number")
	assert(#self:GetDescendants() > 0, "ScaleTo on an empty model errors in Roblox")
end
function methods:GetExtentsSize()
	return Vector3.new(4, 5, 4)
end
function methods:Clone()
	return Instance.new(self.ClassName)
end
-- terrain
function methods:FillBlock(cf, size, mat)
	assert(isCF(cf) and isV(size) and type(mat) == "table", "FillBlock args")
end
function methods:FillBall(center, radius, mat)
	assert(isV(center) and type(radius) == "number" and type(mat) == "table", "FillBall args")
end
function methods:FillCylinder(cf, height, radius, mat)
	assert(isCF(cf) and type(height) == "number" and type(radius) == "number" and type(mat) == "table", "FillCylinder args")
end
function methods:ReplaceMaterial(region, res, from, to)
	assert(type(region) == "table" and res == 4 and type(from) == "table" and type(to) == "table", "ReplaceMaterial args")
end
function methods:SetMaterialColor(mat, color)
	assert(type(mat) == "table" and getmetatable(color) == C3, "SetMaterialColor args")
end
-- services
function methods:GetPlayers()
	return {}
end
function methods:GetDataStore()
	return { GetAsync = function() error("no API access") end, SetAsync = function() end }
end
function methods:GetOrderedDataStore()
	return { GetSortedAsync = function() error("no API access") end, SetAsync = function() end }
end
function methods:AddTag(inst, tag)
	assert(type(tag) == "string", "AddTag")
end
function methods:Create()
	return { Play = function() end }
end
function methods:GetPlayerByUserId()
	return nil
end
function methods:FireClient() end
function methods:BindToClose(fn)
	assert(type(fn) == "function", "BindToClose")
end
function methods:LoadCharacter() end
function methods:GetNameFromUserIdAsync()
	return "Player"
end
function methods:FireAllClients() end
function methods:Fire() end

InstMT.__index = function(self, k)
	local props = rawget(self, "_props")
	if props[k] ~= nil then
		return props[k]
	end
	if k == "Position" and props.CFrame then
		return props.CFrame.Position
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
		return
	end
	if k == "CFrame" then
		assert(isCF(v), "CFrame property must be a CFrame (" .. tostring(self.Name) .. ")")
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

-- task: spawned threads run until they wait, then stop (loops run once)
task = {}
function task.spawn(fn, ...)
	local co = coroutine.create(fn)
	local ok, err = coroutine.resume(co, ...)
	if not ok then
		table.insert(STATS.Errors, "task.spawn: " .. tostring(err))
	end
	return co
end
function task.wait()
	if coroutine.isyieldable() then
		coroutine.yield()
	end
	return 0
end
function task.delay() end
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
