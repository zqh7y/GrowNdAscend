-- Boost zones: every Config.BOOST_ZONE.Every seconds a big glowing circle
-- appears somewhere in a world where a player is, for BOOST_ZONE.Lasts
-- seconds. Standing in it multiplies your Luck or your Coins (the zone says
-- which, and by how much: a random x2 ... x10). Leaving it, or the zone
-- running out, ends the boost. The boost lives on the session data
-- (data.ZoneLuck / data.ZoneCoins, read by Config.luck and Config.coinGain)
-- and is cleared on join.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local Build = require(ReplicatedStorage.Shared.Build)
local PlayerData = require(script.Parent.PlayerData)
local World = require(script.Parent.World)

local notifyEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Notify")

local BoostZones = {}
BoostZones.Enabled = true -- (the simulator turns the timer off)
BoostZones.Active = {} -- the zones on the map now
local random = Random.new()

local LOOKS = {
	Luck = { Color = Color3.fromRGB(90, 220, 120), Dark = Color3.fromRGB(20, 90, 40), Word = "LUCK" },
	Coins = { Color = Color3.fromRGB(255, 200, 50), Dark = Color3.fromRGB(120, 70, 0), Word = "COINS" },
}
BoostZones.LOOKS = LOOKS

local folder = Build.folder(workspace:WaitForChild("Map"), "BoostZones")

local function now()
	return workspace:GetServerTimeNow()
end

-- (for the simulator) swap the random source
function BoostZones.setRandom(source)
	random = source or Random.new()
end

-- a random multiplier from Config.BOOST_ZONE.Multipliers ({ value, weight })
local function pickMultiplier()
	local total = 0
	for _, m in ipairs(Config.BOOST_ZONE.Multipliers) do
		total += m[2]
	end
	local r = random:NextNumber() * total
	for _, m in ipairs(Config.BOOST_ZONE.Multipliers) do
		r -= m[2]
		if r <= 0 then
			return m[1]
		end
	end
	return Config.BOOST_ZONE.Multipliers[1][1]
end

-- a free, flat spot in world `area` (or the middle of the path)
function BoostZones.findSpot(area)
	local r = Config.BOOST_ZONE.Radius
	local x0 = Config.areaStart(area)
	local half = Config.AREA_HALF_WIDTH
	for _ = 1, 40 do
		local x = random:NextNumber(x0 + r + 6, x0 + Config.AREA_LENGTH - r - 6)
		local z = random:NextNumber(-half + r + 3, half - r - 3)
		local free = World.flatGround(x, z, r * 0.8)
		if free then
			-- nothing big standing there (best effort)
			local ok, parts = pcall(function()
				local params = OverlapParams.new()
				params.FilterType = Enum.RaycastFilterType.Exclude
				params.FilterDescendantsInstances = { workspace.Terrain, folder }
				return workspace:GetPartBoundsInBox(CFrame.new(x, (World.groundAt(x, z) or 0) + 4, z), Vector3.new(r * 1.6, 6, r * 1.6), params)
			end)
			if not ok or type(parts) ~= "table" or #parts == 0 then
				return Vector3.new(x, World.groundAt(x, z) or 0, z)
			end
		end
	end
	local x = x0 + Config.AREA_LENGTH / 2
	return Vector3.new(x, World.groundAt(x, 0) or 0, 0)
end

local function timerText(seconds)
	seconds = math.max(math.ceil(seconds), 0)
	return string.format("%d:%02d", seconds // 60, seconds % 60)
end

-- Puts a zone on the map: kind "Luck" or "Coins", x`multiplier`, in world
-- `area` (at `at`, or a random free spot). Returns it.
function BoostZones.spawn(area, kind, multiplier, at)
	local cfg = Config.BOOST_ZONE
	kind = kind or cfg.Kinds[random:NextInteger(1, #cfg.Kinds)]
	multiplier = multiplier or pickMultiplier()
	at = at or BoostZones.findSpot(area)
	local look = LOOKS[kind]
	local r = cfg.Radius
	local model = Build.model(folder, "BoostZone")
	-- a see-through puck (tall enough to show over the grass), a white rim and
	-- a faint column of light so you can find it from afar
	local disc = Build.cylinder(model, at - Vector3.new(0, 0.2, 0), 1.3, r * 2, {
		Name = "Zone", Color = look.Color, Transparency = 0.45, CanCollide = false, CastShadow = false,
	})
	Build.cylinder(model, at - Vector3.new(0, 0.2, 0), 1.2, r * 2 + 0.8, {
		Name = "Rim", Color = Color3.fromRGB(255, 255, 255), Transparency = 0.3, CanCollide = false, CastShadow = false,
	})
	local column = Build.cylinder(model, at, 40, r * 2 - 1, {
		Name = "Column", Color = look.Color, Transparency = 0.86, CanCollide = false, CastShadow = false,
	})
	-- the disc breathes
	TweenService:Create(disc, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Transparency = 0.65 }):Play()
	TweenService:Create(column, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Transparency = 0.93 }):Play()
	-- the sign: "x5 LUCK" and the time left
	local anchor = Build.part(model, { Name = "Sign", Size = Vector3.one, CFrame = CFrame.new(at + Vector3.new(0, 9, 0)), Transparency = 1, CanCollide = false, CastShadow = false })
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromScale(14, 5)
	gui.MaxDistance = 220
	gui.LightInfluence = 0
	gui.Adornee = anchor
	gui.Parent = anchor
	local labels = {}
	for k, name in ipairs({ "Title", "Timer" }) do
		local label = Instance.new("TextLabel")
		label.Name = name
		label.BackgroundTransparency = 1
		label.Position = UDim2.fromScale(0, if k == 1 then 0 else 0.6)
		label.Size = UDim2.fromScale(1, if k == 1 then 0.6 else 0.38)
		label.Font = Enum.Font.FredokaOne
		label.TextScaled = true
		label.TextColor3 = if k == 1 then look.Color else Color3.new(1, 1, 1)
		label.Text = if k == 1 then string.format("x%d %s", multiplier, look.Word) else timerText(cfg.Lasts)
		local stroke = Instance.new("UIStroke")
		stroke.Color = look.Dark
		stroke.Thickness = if k == 1 then 4 else 3
		stroke.Parent = label
		label.Parent = gui
		labels[name] = label
	end
	local zone = {
		Kind = kind,
		Multiplier = multiplier,
		Area = area,
		Center = at,
		Ends = now() + cfg.Lasts,
		Model = model,
		Title = labels.Title,
		Timer = labels.Timer,
	}
	table.insert(BoostZones.Active, zone)
	for _, player in ipairs(Players:GetPlayers()) do
		notifyEvent:FireClient(player, string.format("A x%d %s zone appeared in %s for %d minutes!", multiplier, look.Word, Config.AREAS[area].Name, cfg.Lasts // 60), "success")
	end
	return zone
end

-- the zone a player stands in (the best one if they overlap), or nil
local function zoneOf(player)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root then
		return {}
	end
	local best = {}
	for _, zone in ipairs(BoostZones.Active) do
		local d = Vector3.new(root.Position.X - zone.Center.X, 0, root.Position.Z - zone.Center.Z).Magnitude
		if d <= Config.BOOST_ZONE.Radius and math.abs(root.Position.Y - zone.Center.Y) < 12 then
			if (best[zone.Kind] or 1) < zone.Multiplier then
				best[zone.Kind] = zone.Multiplier
			end
		end
	end
	return best
end

-- Updates everything: zones that ran out go away, every player gets the
-- boost of the zone they stand in (or none). `time` is for the simulator.
function BoostZones.update(time)
	local t = time or now()
	for i = #BoostZones.Active, 1, -1 do
		local zone = BoostZones.Active[i]
		if t >= zone.Ends then
			zone.Model:Destroy()
			table.remove(BoostZones.Active, i)
		else
			zone.Timer.Text = timerText(zone.Ends - t)
		end
	end
	for _, player in ipairs(Players:GetPlayers()) do
		local data = PlayerData.get(player)
		if data then
			local inside = zoneOf(player)
			local luck, coins = inside.Luck, inside.Coins
			if data.ZoneLuck ~= luck or data.ZoneCoins ~= coins then
				local entered = (luck and luck ~= data.ZoneLuck) or (coins and coins ~= data.ZoneCoins)
				data.ZoneLuck, data.ZoneCoins = luck, coins
				if entered then
					notifyEvent:FireClient(player, string.format("Boost zone: x%d %s while you stand here!", luck or coins, if luck then "Luck" else "Coins"), "success")
				end
				PlayerData.sync(player)
			end
		end
	end
end

-- picks where the next zone goes: the world a random player is in
local function nextArea()
	local players = Players:GetPlayers()
	if #players == 0 then
		return nil
	end
	return PlayerData.worldOf(players[random:NextInteger(1, #players)])
end

-- boosts never carry over between visits
PlayerData.Loaded.Event:Connect(function(player)
	local data = PlayerData.get(player)
	if data then
		data.ZoneLuck, data.ZoneCoins = nil, nil
	end
end)

BoostZones.NextAt = now() + Config.BOOST_ZONE.Every
task.spawn(function()
	while true do
		task.wait(0.25)
		if BoostZones.Enabled then
			if now() >= BoostZones.NextAt then
				BoostZones.NextAt = now() + Config.BOOST_ZONE.Every
				local area = nextArea()
				if area then
					BoostZones.spawn(area)
				end
			end
			BoostZones.update()
		end
	end
end)

return BoostZones
