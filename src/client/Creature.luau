-- Animal movement, shared by the pets and the wild animals of the ambient
-- life. Each animal moves the way it really would (its species row in
-- PetModels says how):
--   walk     on the ground, legs swinging in diagonal pairs, faster = longer strides
--   hop      bunnies and frogs: a hop, a short rest, another hop
--   waddle   ducks, penguins, seals: short steps with a side-to-side rock
--   fly      birds and dragons: flapping wings at flying height, gliding when slow
--   hover    low and buzzing (scarab, glitch)
--   swim     fish and whales float and glide, tail beating up and down
--   slither  snakes: the body waves side to side along the ground
-- Ground animals stay on the ground (a raycast against the terrain and the
-- map, never pets, players or coins), turn smoothly towards where they go,
-- and when idle they breathe, wag their tails and now and then look around.
--
--   local c = Creature.new(model, rig, scale, animated)  -- model built at the origin, already scaled
--   c:moveTo(position, speedMultiplier)  -- where the feet should go (nil = stay)
--   c:face(position)                     -- look at this while standing (nil = don't)
--   c:step(dt, t)                        -- once per frame
--   c:lunge()                            -- a hit
--   c:teleport(position)
-- Birds can also land: set c.FixedGround to a perch height (a treetop) and
-- c.Landed = true, and they fold their wings and stand there; c.Height
-- is how high a flyer flies above the ground.
local Creature = {}
Creature.__index = Creature

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Include
local function refreshFilter()
	local list = { workspace.Terrain }
	local map = workspace:FindFirstChild("Map")
	if map then
		table.insert(list, map)
	end
	rayParams.FilterDescendantsInstances = list
end
refreshFilter()
workspace.ChildAdded:Connect(function(child)
	if child.Name == "Map" then
		refreshFilter()
	end
end)

-- The ground under (x, z), searching from `fromY` down; nil if there's none
function Creature.ground(x, z, fromY)
	local hit = workspace:Raycast(Vector3.new(x, fromY + 4, z), Vector3.new(0, -40, 0), rayParams)
	return hit and hit.Position.Y
end

local HEIGHTS = { fly = 4.5, hover = 1.6, swim = 2.4 } -- above the ground, before scaling
local STRIDE = 2.4 -- studs per full leg cycle at scale 1

local function angleTo(from, to)
	return (to - from + math.pi) % (math.pi * 2) - math.pi
end

function Creature.new(model, rig, scale, animated)
	local self = setmetatable({}, Creature)
	self.Model = model
	self.Rig = rig
	self.Scale = scale
	self.Move = rig.Move
	self.BaseSpeed = rig.Speed
	self.Animated = animated or {}
	self.Position = Vector3.zero -- the feet (or the spot under a flyer)
	self.Yaw = 0
	self.Speed = 0 -- current speed, eased
	self.Gait = 0 -- leg phase, advances with distance walked
	self.Goal = nil
	self.GoalSpeed = 1
	self.Facing = nil
	self.Lunge = 0
	self.HopT = nil -- 0..1 while in a hop
	self.HopRest = 0
	self.Idle = 0 -- seconds standing still
	self.Glance = 0 -- current look-around yaw
	self.GlanceGoal = 0
	self.NextGlance = math.random() * 4 + 2
	self.Seed = math.random() * 100
	self.GroundY = 0
	self.NextRay = 0
	self.Height = (HEIGHTS[rig.Move] or 0) * scale ^ 0.6
	self.Altitude = self.Height -- eases towards Height (or 0 when landed)
	self.Landed = false
	self.FixedGround = nil

	-- where every part sits relative to the pivot, and how each one moves
	local s = scale
	local parts, offsets, joints = {}, {}, {}
	local function add(part, joint)
		if offsets[part] then
			joints[part] = joint or joints[part]
			return
		end
		table.insert(parts, part)
		offsets[part] = part.CFrame
		joints[part] = joint
	end
	for _, leg in ipairs(rig.Legs) do
		for _, part in ipairs(leg.Parts) do
			add(part, { Kind = if leg.Segment then "segment" else "leg", At = leg.Hip * s, Phase = leg.Phase, Segment = leg.Segment })
		end
	end
	for _, wing in ipairs(rig.Wings) do
		for _, part in ipairs(wing.Parts) do
			add(part, { Kind = if wing.Fin then "fin" else "wing", At = wing.Shoulder * s, Side = wing.Side })
		end
	end
	if rig.Tail then
		for _, part in ipairs(rig.Tail.Parts) do
			add(part, { Kind = if rig.Tail.Vertical then "fluke" else "tail", At = rig.Tail.Base * s })
		end
	end
	for i, entry in ipairs(self.Animated) do
		entry.Phase = i * 0.7
		if entry.Kind == "spin" or entry.Kind == "orbit" or entry.Kind == "flap" then
			add(entry.Part, { Kind = entry.Kind, Speed = entry.Speed, Side = entry.Side })
		end
	end
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			add(part)
		end
	end
	self.Parts = parts
	self.Offsets = offsets
	self.Joints = joints
	self.CFrames = table.create(#parts)
	self.FootY = rig.FootY * s -- the feet, below the pivot
	return self
end

function Creature:teleport(position)
	self.Position = position
	self.GroundY = self.FixedGround or Creature.ground(position.X, position.Z, position.Y) or position.Y
	self.Position = Vector3.new(position.X, self.GroundY, position.Z)
	self.Altitude = if self.Landed then 0 else self.Height
end

function Creature:moveTo(position, speedMultiplier)
	self.Goal = position
	self.GoalSpeed = speedMultiplier or 1
end

function Creature:face(position)
	self.Facing = position
end

function Creature:lunge()
	self.Lunge = 1
	if self.Move == "hop" or self.Move == "walk" or self.Move == "waddle" then
		self.HopT = self.HopT or 0
	end
end

function Creature:airborne()
	return self.Move == "fly" or self.Move == "hover" or self.Move == "swim"
end

-- One frame of movement and animation
function Creature:step(dt, t)
	local s = self.Scale
	local speed = self.BaseSpeed * s ^ 0.3 * self.GoalSpeed

	-- where to go
	local want = 0
	local dir = nil
	if self.Goal then
		local flat = Vector3.new(self.Goal.X - self.Position.X, 0, self.Goal.Z - self.Position.Z)
		local distance = flat.Magnitude
		local stop = 0.6 * s
		if distance > stop then
			dir = flat / distance
			-- slow down on arrival
			want = speed * math.clamp((distance - stop) / (2.5 * s), 0.25, 1)
		end
	end

	-- hoppers only move while in the air
	local hop = 0
	if self.Move == "hop" then
		if self.HopT then
			self.HopT += dt / 0.42
			hop = math.sin(math.min(self.HopT, 1) * math.pi)
			if self.HopT >= 1 then
				self.HopT = nil
				self.HopRest = if want > 0 then 0.08 else 0.6
			end
		else
			self.HopRest -= dt
			if self.HopRest <= 0 and (want > 0 or (self.Idle > 3 and math.random() < dt * 0.15)) then
				self.HopT = 0
			end
		end
		want = if self.HopT then want * 1.7 else 0
	elseif self.HopT then
		-- a little jump (on a hit)
		self.HopT += dt / 0.35
		hop = math.sin(math.min(self.HopT, 1) * math.pi) * 0.6
		if self.HopT >= 1 then
			self.HopT = nil
		end
	end

	self.Speed += (want - self.Speed) * math.min(dt * (if want > self.Speed then 6 else 9), 1)
	local moving = math.clamp(self.Speed / math.max(speed, 1), 0, 1.6)
	if dir and self.Speed > 0.05 then
		local stepDistance = self.Speed * dt
		self.Position += dir * stepDistance
		self.Gait += stepDistance / (STRIDE * s) * math.pi * 2
		local targetYaw = math.atan2(-dir.X, -dir.Z)
		self.Yaw += angleTo(self.Yaw, targetYaw) * math.min(dt * 8, 1)
		self.Idle = 0
		self.Glance, self.GlanceGoal = self.Glance * (1 - math.min(dt * 6, 1)), 0
	else
		self.Idle += dt
		if self.Facing then
			local flat = Vector3.new(self.Facing.X - self.Position.X, 0, self.Facing.Z - self.Position.Z)
			if flat.Magnitude > 0.1 then
				self.Yaw += angleTo(self.Yaw, math.atan2(-flat.X, -flat.Z)) * math.min(dt * 6, 1)
			end
		end
		-- now and then, look around
		self.NextGlance -= dt
		if self.NextGlance <= 0 then
			self.GlanceGoal = if self.GlanceGoal == 0 and not self.Facing then (math.random() - 0.5) * 1.6 else 0
			self.NextGlance = if self.GlanceGoal ~= 0 then 0.9 + math.random() else 2.5 + math.random() * 4
		end
		self.Glance += (self.GlanceGoal - self.Glance) * math.min(dt * 3, 1)
	end

	-- stay on the ground (checked a few times a second)
	self.NextRay -= dt
	if self.FixedGround then
		self.GroundY = self.FixedGround
	elseif self.NextRay <= 0 then
		self.NextRay = 0.12
		local y = Creature.ground(self.Position.X, self.Position.Z, self.GroundY + 2)
		if y then
			self.GroundY = y
		end
	end
	local y = self.Position.Y + (self.GroundY - self.Position.Y) * math.min(dt * (if self:airborne() then 3 else 12), 1)
	self.Position = Vector3.new(self.Position.X, y, self.Position.Z)

	-- the body
	self.Lunge = math.max(self.Lunge - dt * 4, 0)
	local lift, pitch, roll = 0, 0, 0
	local phase = self.Gait
	local move = self.Move
	if self.Landed and (move == "fly" or move == "hover") then
		move = "waddle" -- perched or walking about: wings folded
	end
	self.Altitude += ((if self.Landed then 0 else self.Height) - self.Altitude) * math.min(dt * 1.5, 1)
	if move == "walk" then
		lift = math.abs(math.sin(phase)) * 0.12 * s * math.min(moving, 1) + math.sin(t * 2 + self.Seed) * 0.03 * s
		pitch = -math.sin(phase * 2) * 0.03 * moving
	elseif move == "waddle" then
		roll = math.sin(phase * 0.5) * 0.18 * math.min(moving, 1)
		lift = self.Altitude + math.abs(math.sin(phase * 0.5)) * 0.1 * s * math.min(moving, 1)
	elseif move == "hop" then
		lift = hop * 1.3 * s ^ 0.7
		pitch = if self.HopT then (0.5 - self.HopT) * 0.5 else 0
	elseif move == "fly" then
		lift = self.Altitude + math.sin(t * 2 + self.Seed) * 0.35 * s
		pitch = -0.18 * math.min(moving, 1)
		roll = math.sin(t * 0.9 + self.Seed) * 0.08
	elseif move == "hover" then
		lift = self.Altitude + math.sin(t * 3 + self.Seed) * 0.2 * s
		pitch = -0.1 * math.min(moving, 1)
	elseif move == "swim" then
		lift = self.Altitude + math.sin(t * 1.6 + self.Seed) * 0.3 * s
		roll = math.sin(t * 1.2 + self.Seed) * 0.07
		pitch = math.cos(t * 1.6 + self.Seed) * 0.06
	elseif move == "slither" then
		lift = 0
	end
	lift += hop * (if move == "hop" then 0 else 0.8 * s)
	local forward = Vector3.new(-math.sin(self.Yaw), 0, -math.cos(self.Yaw))
	local base = self.Position + forward * self.Lunge * 1.2 * s + Vector3.new(0, lift - self.FootY, 0)
	local pivot = CFrame.new(base) * CFrame.Angles(0, self.Yaw + self.Glance, 0) * CFrame.Angles(pitch - self.Lunge * 0.15, 0, roll)
	self.Pivot = pivot

	-- the parts
	local gaitAmount = math.min(moving, 1.3)
	local flapSpeed = if move == "hover" then 28 else 9 + math.min(moving, 1) * 5
	local flying = move == "fly" or move == "hover"
	for i, part in ipairs(self.Parts) do
		local offset = self.Offsets[part]
		local joint = self.Joints[part]
		local cf
		if not joint then
			cf = pivot * offset
		else
			local kind = joint.Kind
			local rotation
			if kind == "leg" then
				local angle
				if move == "hover" then
					angle = 0.4 + math.sin(t * 4 + joint.Phase) * 0.25 -- dangling
				elseif flying then
					angle = 0.7 -- tucked in flight
				elseif move == "swim" then
					angle = math.sin(t * 3 + joint.Phase) * 0.35 -- tentacles
				elseif move == "hop" then
					angle = if self.HopT then -math.sin(self.HopT * math.pi) * 0.8 else 0
				elseif move == "waddle" then
					angle = math.sin(phase * 0.5 + joint.Phase) * 0.5 * math.min(gaitAmount, 1)
				else
					angle = math.sin(phase + joint.Phase) * 0.65 * gaitAmount
				end
				rotation = CFrame.Angles(angle, 0, 0)
			elseif kind == "wing" then
				local angle
				if flying then
					-- flap hard when moving, glide in slow beats when not
					local beat = if move == "hover" then 0.45 else 0.35 + math.min(moving, 1) * 0.4
					angle = math.sin(t * flapSpeed + self.Seed) * beat + 0.1
				elseif move == "waddle" then
					angle = 0.15 + math.sin(phase * 0.5) * 0.12 * gaitAmount -- flippers paddle
				else
					angle = math.sin(t * 1.5 + self.Seed) * 0.04 -- folded, breathing
				end
				rotation = CFrame.Angles(0, 0, angle * joint.Side)
			elseif kind == "fin" then
				rotation = CFrame.Angles(0, 0, math.sin(t * 3 + self.Seed) * 0.3 * joint.Side)
			elseif kind == "tail" then
				local wag = if self.Idle > 0.3 then math.sin(t * 7 + self.Seed) * 0.35 else math.sin(phase) * 0.15
				rotation = CFrame.Angles(0, wag, 0)
			elseif kind == "fluke" then
				rotation = CFrame.Angles(math.sin(t * (3 + moving * 3) + self.Seed) * 0.35, 0, 0)
			elseif kind == "segment" then
				-- a travelling wave down the body
				local wave = math.sin(phase * 0.8 - joint.Segment * 0.9 + t * 1.5) * 0.45 * s * (0.35 + math.min(moving, 1) * 0.65)
				cf = pivot * CFrame.new(wave * (joint.Segment + 1) / 4, 0, 0) * offset
			elseif kind == "spin" then
				cf = pivot * offset * CFrame.Angles(t * joint.Speed, 0, 0)
			elseif kind == "orbit" then
				cf = pivot * CFrame.Angles(0, t * joint.Speed, 0) * offset
			elseif kind == "flap" then
				cf = pivot * offset * CFrame.Angles(0, 0, math.sin(t * 5) * 0.25 * joint.Side)
			end
			if rotation then
				local at = joint.At
				cf = pivot * CFrame.new(at) * rotation * CFrame.new(-at) * offset
			end
		end
		self.CFrames[i] = cf
	end
	workspace:BulkMoveTo(self.Parts, self.CFrames, Enum.BulkMoveMode.FireCFrameChanged)

	-- glowing bits
	for _, entry in ipairs(self.Animated) do
		if entry.Kind == "pulse" then
			entry.Part.Transparency = 0.15 + (math.sin(t * 4 + entry.Phase) * 0.5 + 0.5) * 0.35
		elseif entry.Kind == "rainbow" then
			entry.Part.Color = Color3.fromHSV((t * 0.25 + entry.Phase * 0.1) % 1, 0.6, 1)
		end
	end
end

return Creature
