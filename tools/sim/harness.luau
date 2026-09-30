-- run the server startup (builds the map, spawns breakables, starts loops)
local ok, err = xpcall(require, debug.traceback, server)
print(if ok then "server started OK" else "SERVER ERROR: " .. tostring(err))
for _, e in ipairs(STATS.Errors) do
	print("THREAD ERROR: " .. e)
end
-- try every area's breakable many times (all the random variants)
local World = __cache["World/init"]
if World then
	local before = STATS.Parts
	for i, area in ipairs(World.Areas) do
		local folder = Instance.new("Folder")
		for k = 1, 60 do
			local okB, errB = pcall(area.Module.breakable, folder, Vector3.new(10, 0, 5), Random.new(k))
			if not okB then
				print("BREAKABLE ERROR area " .. i .. ": " .. tostring(errB))
				break
			end
		end
		print(string.format("area %d: %d breakable spots", i, #area.Spots))
	end
	STATS.Parts = before
	-- parts per area
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
	print("rolled " .. rolled .. " pets in 30 rolls (rolls at once: " .. __cache["Config"].rollsAtOnce(data) .. ")")
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
	for _ = 1, 600 do
		STEP(0.1)
	end
	local count2 = 0
	for _ in pairs(Breakables.Targets) do count2 += 1 end
	print(string.format("fought 60s: coins +%d, living coins %d -> %d, pet target %s", data.Coins - coinsBefore, count, count2, tostring(player:GetAttribute("PetTarget"))))
	-- did the coins hop?
	local hopped = 0
	for _, t in pairs(Breakables.Targets) do
		if (t.Pos - t.Home).Magnitude > 0.1 then hopped += 1 end
		assert((t.Pos - t.Home).Magnitude < 20, "a coin wandered too far")
	end
	print("coins away from home spot:", hopped)
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
		try("Effects.coins", C("Effects").coins, Vector3.new(10, 2, 0), 12345)
		try("Effects.confetti", C("Effects").confetti, 10)
		frames(200)
	end
	for _, e in ipairs(STATS.Errors) do
		print("THREAD ERROR: " .. e)
	end
end
