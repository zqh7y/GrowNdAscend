-- run the server startup (builds the map, spawns breakables, starts loops)
local ok, err = xpcall(require, debug.traceback, server)
print(if ok then "server started OK" else "SERVER ERROR: " .. tostring(err))
for _, e in ipairs(STATS.Errors) do
	print("THREAD ERROR: " .. e)
end
-- Ground and spawn checks (the fake terrain knows the real surface heights)
local World = __cache["World/init"]
local Config = __cache["Shared/Config"]
local function check(ok2, message)
	if not ok2 then
		print("GROUND ERROR: " .. message)
	end
end
if World then
	local total = Config.AREA_LENGTH * #Config.AREAS
	-- nothing sticks up out of the playable strip
	local worst = -math.huge
	for x = 0, total, 2 do
		for z = -Config.AREA_HALF_WIDTH + 1, Config.AREA_HALF_WIDTH - 1, 2 do
			worst = math.max(worst, TERRAIN_HEIGHT(x, z) or -math.huge)
		end
	end
	check(worst <= 0.01, "terrain sticks up to " .. worst .. " inside the playable strip")
	print(string.format("highest terrain inside the playable strip: %.2f", worst))
	-- the spawn pad and every area's spawn point sit on the ground
	local pad = workspace.Map.Spawn
	local ground = TERRAIN_HEIGHT(pad.Position.X, pad.Position.Z)
	check(math.abs(pad.Position.Y - 0.5 - ground) < 0.01, "spawn pad isn't on the ground")
	for i, cf in ipairs(World.Spawns) do
		local g = TERRAIN_HEIGHT(cf.Position.X, cf.Position.Z)
		check(g and math.abs(cf.Position.Y - 3 - g) < 0.01, "area " .. i .. " spawn point isn't on the ground")
		check(math.abs(cf.Position.Z) < Config.AREA_HALF_WIDTH and cf.Position.X > Config.areaStart(i), "area " .. i .. " spawn point is outside the area")
	end
	print("spawn pad at", pad.Position.X, pad.Position.Y, pad.Position.Z, "ground", ground)
	-- breakable spots are on flat ground
	for i, area in ipairs(World.Areas) do
		for _, spot in ipairs(area.Spots) do
			check(math.abs(spot.Y - TERRAIN_HEIGHT(spot.X, spot.Z)) < 0.01, "area " .. i .. " spot not on the ground")
		end
		print(string.format("area %d: %d breakable spots on flat ground", i, #area.Spots))
	end
	-- every coin model builds, for every world, with many seeds
	local Coins = __cache["Shared/Coins"]
	local before = STATS.Parts
	for i = 1, #Config.AREAS do
		for seed = 1, 40 do
			local okB, errB = pcall(Coins.build, i, Instance.new("Folder"), seed)
			if not okB then
				print("COIN BUILD ERROR area " .. i .. ": " .. tostring(errB))
				break
			end
		end
	end
	STATS.Parts = before
	local map = workspace:FindFirstChild("Map")
	for _, f in ipairs(map:GetChildren()) do
		local n = 0
		for _, d in ipairs(f:GetDescendants()) do
			if d:IsA("BasePart") then n += 1 end
		end
		print(string.format("%-28s %5d parts", f.Name, n))
	end
	print("fusion machine:", World.Fusion and "ok" or "MISSING", "boards:", World.Boards.Strongest and World.Boards.Playtime and World.Boards.Rebirths and "ok" or "MISSING")
end
print("total parts created:", STATS.Parts)
-- which props cost the most parts
local map = workspace:FindFirstChild("Map")
for _, area in ipairs(map:GetChildren()) do
	if area.Name:find("Area") then
		local byName = {}
		for _, d in ipairs(area:GetDescendants()) do
			if d:IsA("BasePart") then
				local top = d
				while top.Parent and top.Parent.Parent ~= area and top.Parent.Parent and top.Parent.Parent.Parent ~= area do
					top = top.Parent
				end
				local name = if top.Parent then top.Parent.Name else "?"
				byName[name] = (byName[name] or 0) + 1
			end
		end
		local list = {}
		for n, c in pairs(byName) do table.insert(list, { n, c }) end
		table.sort(list, function(a, b) return a[2] > b[2] end)
		local line = area.Name .. ": "
		for i = 1, math.min(7, #list) do line ..= list[i][1] .. "=" .. list[i][2] .. " " end
		print(line)
	end
end

-- A player joins, stands in the Forest with pets, and plays for a while
if ok then
	local Players = game:GetService("Players")
	local remotes = game:GetService("ReplicatedStorage").Remotes
	local player = Instance.new("Player")
	player.Name = "Tester"
	rawget(player, "_props").UserId = 1
	rawget(player, "_props").DisplayName = "Tester"
	local character = Instance.new("Model")
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Parent = character
	root.CFrame = CFrame.new(50, 3, 0)
	rawget(player, "_props").Character = character
	player.Parent = Players
	table.insert(PLAYERS, player)
	Players.PlayerAdded:Fire(player)
	STEP(0.1)
	local PlayerData = __cache["PlayerData"]
	local data = PlayerData.get(player)
	assert(data, "player data didn't load")
	local function check(ok2, message)
		if not ok2 then
			print("GAME ERROR: " .. message)
		end
	end
	data.Pets = { Dog = 5, Cat = 1, ["Huge Tiger"] = 1 }
	data.Equipped = { "Dog", "Cat", "Huge Tiger" }

	-- roll, buy upgrades, equip best, fuse
	local function invoke(name, ...)
		local fn = remotes:FindFirstChild(name).OnServerInvoke
		local okI, result = pcall(fn, player, ...)
		if not okI then
			print("REMOTE ERROR " .. name .. ": " .. tostring(result))
		end
		return result
	end
	data.Coins = 1e7
	for _, id in ipairs({ "Coins", "Coins", "Damage", "Luck", "RollSpeed", "RollSpeed", "Rolls", "AutoHatch", "SizeLuck", "Slots" }) do
		invoke("BuyUpgrade", id)
	end
	local rolled = 0
	for _ = 1, 30 do
		STEP(1)
		local results = invoke("Roll")
		if type(results) == "table" then
			rolled += #results
		end
	end
	print("rolled " .. rolled .. " pets in 30 rolls (rolls at once: " .. __cache["Shared/Config"].rollsAtOnce(data) .. ")")
	invoke("EquipBest")
	print("equipped after EquipBest: " .. table.concat(data.Equipped, ", "))
	data.Pets.Dog = 5
	print("fuse start:", invoke("FuseStart", "Dog"), "fusion:", data.Fusion and data.Fusion.Pet)
	STEP(100)
	print("fuse collect:", invoke("FuseCollect"))

	-- fight for 60 seconds
	data.Equipped = { "Dog", "Cat", "Huge Tiger" }
	local coinsBefore = data.Coins
	local Breakables = __cache["Breakables"]
	local broken = 0
	local count = 0
	for _ in pairs(Breakables.Targets) do count += 1 end
	local jumps, lastStart = 0, {}
	for _ = 1, 600 do
		STEP(0.1)
		for id, t in pairs(Breakables.Targets) do
			local start = t.Data:GetAttribute("HopStart")
			if start ~= lastStart[id] then
				jumps += 1
				lastStart[id] = start
			end
		end
	end
	print(string.format("jumps per coin per minute: %.1f", jumps / count))
	local count2 = 0
	for _ in pairs(Breakables.Targets) do count2 += 1 end
	print(string.format("fought 60s: coins +%d, living coins %d -> %d, pet target %s", data.Coins - coinsBefore, count, count2, tostring(player:GetAttribute("PetTarget"))))
	-- did the coins jump, land on the ground, and stay spread out?
	local hopped, perArea = 0, {}
	for _, t in pairs(Breakables.Targets) do
		if (t.Pos - t.Home).Magnitude > 0.1 then hopped += 1 end
		check((t.Pos - t.Home).Magnitude < 20, "a coin wandered too far")
		check(math.abs(t.Pos.Y - TERRAIN_HEIGHT(t.Pos.X, t.Pos.Z)) < 0.01, "a coin landed off the ground")
		local from = t.Data:GetAttribute("HopFrom")
		check(math.abs(from.Y - TERRAIN_HEIGHT(from.X, from.Z)) < 0.01, "a coin jumped from off the ground")
		perArea[t.Area] = (perArea[t.Area] or 0) + 1
	end
	print("coins away from their home spot:", hopped)
	for i = 1, 4 do
		check((perArea[i] or 0) <= 5, "too many coins in area " .. i)
	end
	print("living coins per area:", perArea[1], perArea[2], perArea[3], perArea[4])
end
for _, e in ipairs(STATS.Errors) do
	print("THREAD ERROR: " .. e)
end

-- The client: load it as the same player, then play through every screen
if ok then
	print("--- client ---")
	local Players = game:GetService("Players")
	local remotes = game:GetService("ReplicatedStorage").Remotes
	local player = Players:GetPlayers()[1]
	LOCAL_PLAYER = player
	rawget(Players, "_props").LocalPlayer = player
	local gui = Instance.new("PlayerGui")
	gui.Name = "PlayerGui"
	gui.Parent = player
	local camera = Instance.new("Camera")
	camera.CFrame = CFrame.new(50, 20, 30)
	rawget(workspace, "_props").CurrentCamera = camera
	local RunService = game:GetService("RunService")
	local function frames(n)
		for _ = 1, n do
			STEP(1 / 60)
			RunService.RenderStepped:Fire(1 / 60)
		end
	end

	local okC, errC = xpcall(require, debug.traceback, client)
	print(if okC then "client started OK" else "CLIENT ERROR: " .. tostring(errC))
	if okC then
		local PlayerData = __cache["PlayerData"]
		local data = PlayerData.get(player)
		data.Coins = 5e6
		data.Pets = { Dog = 7, Cat = 2, ["Huge Tiger"] = 1, ["Titanic Dragon"] = 1 }
		data.Equipped = { "Dog", "Huge Tiger", "Titanic Dragon" }
		data.Fusion = nil
		PlayerData.sync(player)
		frames(30)
		local function try(name, fn, ...)
			print("  step: " .. name)
			-- run it like Roblox would (its own thread), advancing time until it's done
			local errorsBefore = #STATS.Errors
			local co = task.spawn(fn, ...)
			for _ = 1, 3000 do
				if coroutine.status(co) == "dead" then
					break
				end
				frames(1)
			end
			if coroutine.status(co) ~= "dead" then
				print("  (still running after 50s: " .. name .. ")")
			end
			for i = errorsBefore + 1, #STATS.Errors do
				print("CLIENT ERROR in " .. name .. ": " .. STATS.Errors[i])
			end
			frames(20)
		end
		local C = function(name) return __cache["Client/" .. name] end
		try("PetsPanel.open", C("PetsPanel").open)
		try("UpgradeTree.open", C("UpgradeTree").open)
		try("UpgradeTree.select", C("UpgradeTree").select, "SizeLuck")
		try("UpgradeTree.buy", C("UpgradeTree").buy)
		for _, id in ipairs({ "Coins", "RollSpeed", "AutoHatch", "Luck", "SizeLuck", "Damage", "Damage", "Slots" }) do
			try("buy " .. id, function()
				C("UpgradeTree").select(id)
				C("UpgradeTree").buy()
			end)
		end
		print("upgrades now:", data.Upgrades.Coins, data.Upgrades.AutoHatch, data.Upgrades.Slots)
		try("Panels.openTop", C("Panels").openTop)
		try("Panels.openRebirth", C("Panels").openRebirth)
		try("Panels.openSettings", C("Panels").openSettings)
		try("Roll.roll", C("Roll").roll)
		try("Roll.bigReveal titanic", C("Roll").bigReveal, "Glitch", 3)
		try("Roll.toggleAuto", C("Roll").toggleAuto)
		try("fusion open", function()
			remotes.FusionOpen:FireClient(player)
		end)
		try("fuse", function()
			remotes.FuseStart.OnServerInvoke(player, "Dog")
			PlayerData.sync(player)
		end)
		try("equip best", function()
			remotes.EquipBest:InvokeServer()
		end)
		-- fight with the client watching: pets run, hit, coins break
		local before = data.Coins
		for _ = 1, 20 do
			frames(30)
		end
		print(string.format("client fight 10s: coins +%d, pets equipped %d", data.Coins - before, #data.Equipped))
		-- no living coin is ever drawn below the ground, over many frames
		local lowest, checked = math.huge, 0
		for _ = 1, 400 do
			frames(1)
			for _, model in ipairs(workspace.LivingCoins:GetChildren()) do
				local at = model.DrawnAt
				if at then
					local ground = TERRAIN_HEIGHT(at.Position.X, at.Position.Z)
					lowest = math.min(lowest, at.Position.Y - ground)
					checked += 1
				end
			end
		end
		print(string.format("coin drawings checked: %d, lowest above ground: %.3f", checked, lowest))
		if lowest < -0.01 then
			print("GAME ERROR: a living coin was drawn underground")
		end
		try("Effects.coins", C("Effects").coins, Vector3.new(10, 2, 0), 12345)
		try("Effects.confetti", C("Effects").confetti, 10)
		frames(200)
	end
	for _, e in ipairs(STATS.Errors) do
		print("THREAD ERROR: " .. e)
	end
end
