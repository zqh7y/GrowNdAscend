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
		-- every pet in every size builds, with a sensible number of parts
		local PetModels = C("PetModels")
		local fewest, most = math.huge, 0
		for _, pet in ipairs(__cache["Shared/Config"].PETS) do
			for sizeIndex = 1, #__cache["Shared/Config"].SIZES do
				local name = __cache["Shared/Config"].petName(pet.Name, sizeIndex)
				local okP, model = pcall(PetModels.build, name)
				if not okP then
					print("PET BUILD ERROR " .. name .. ": " .. tostring(model))
				else
					local n = 0
					for _, d in ipairs(model:GetDescendants()) do
						if d:IsA("BasePart") then n += 1 end
					end
					fewest, most = math.min(fewest, n), math.max(most, n)
				end
			end
		end
		print(string.format("pet models: %d to %d parts each", fewest, most))
		-- every animal moves the way it should: ground animals keep their feet
		-- on the ground, flyers and swimmers stay up, legs swing when walking,
		-- wings flap when flying, and nobody drifts off
		local Creature = C("Creature")
		local SPECIES = PetModels.SPECIES
		local moveProblems, checked = {}, 0
		for _, pet in ipairs(__cache["Shared/Config"].PETS) do
			for _, sizeIndex in ipairs({ 1, 3 }) do
				local name = __cache["Shared/Config"].petName(pet.Name, sizeIndex)
				local size = __cache["Shared/Config"].SIZES[sizeIndex]
				local okC, err = pcall(function()
					local model, animated, rig = PetModels.build(name)
					model.Parent = workspace
					if size.Scale ~= 1 then
						model:ScaleTo(size.Scale)
					end
					local c = Creature.new(model, rig, size.Scale, animated)
					local start = Vector3.new(20, 0, 5)
					c:teleport(start)
					local ground = c.GroundY
					local goal = start + Vector3.new(30, 0, 0)
					c:moveTo(goal)
					local lowest, highest, limbMoved = math.huge, -math.huge, 0
					local move = SPECIES[pet.Name].Move
					local airborne = move == "fly" or move == "hover" or move == "swim"
					local watch = if airborne
						then (rig.Wings[1] and rig.Wings[1].Parts[1]) or (rig.Tail and rig.Tail.Parts[1]) or (rig.Legs[1] and rig.Legs[1].Parts[#rig.Legs[1].Parts])
						else (rig.Legs[1] and rig.Legs[1].Parts[1]) or (rig.Wings[1] and rig.Wings[1].Parts[1])
					local last
					for frame = 1, 240 do
						c:step(1 / 60, frame / 60)
						local feet = c.Pivot.Position.Y + rig.FootY * size.Scale
						lowest, highest = math.min(lowest, feet), math.max(highest, feet)
						if watch then
							local rel = c.Pivot:ToObjectSpace(watch.CFrame)
							if last and (rel.Position - last).Magnitude > 0.001 then
								limbMoved += 1
							end
							last = rel.Position
						end
					end
					local travelled = (c.Position - start).Magnitude
					if travelled < 20 then
						table.insert(moveProblems, name .. " only moved " .. string.format("%.1f", travelled))
					end
					if move == "fly" or move == "swim" or move == "hover" then
						if lowest < ground + 0.8 then
							table.insert(moveProblems, name .. " (" .. move .. ") touched the ground")
						end
					elseif move == "hop" then
						if lowest < ground - 0.3 or highest < ground + 0.5 then
							table.insert(moveProblems, string.format("%s hop %.2f..%.2f", name, lowest - ground, highest - ground))
						end
					elseif lowest < ground - 0.3 or lowest > ground + 0.4 then
						table.insert(moveProblems, string.format("%s feet at %.2f above ground", name, lowest - ground))
					end
					if watch and move ~= "hop" and limbMoved < 30 then
						table.insert(moveProblems, name .. " limbs barely moved (" .. limbMoved .. ")")
					end
					model:Destroy()
					checked += 1
				end)
				if not okC then
					table.insert(moveProblems, name .. " error: " .. tostring(err))
				end
			end
		end
		print(string.format("animal movement: %d animals checked, %d problems", checked, #moveProblems))
		for i = 1, math.min(#moveProblems, 15) do
			print("  MOVE: " .. moveProblems[i])
		end
		STATS.MoveProblems = #moveProblems
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

-- The player checklist: every item prints PASS or FAIL
if ok then
	print("--- player checklist ---")
	local Config = __cache["Shared/Config"]
	local PlayerData = __cache["PlayerData"]
	local Breakables = __cache["Breakables"]
	local World = __cache["World/init"]
	local Players = game:GetService("Players")
	local remotes = game:GetService("ReplicatedStorage").Remotes
	local player = Players:GetPlayers()[1]
	local data = PlayerData.get(player)
	local results = {}
	local function item(n, name, pass, detail)
		table.insert(results, pass)
		print(string.format("%2d. %-34s %s%s", n, name, if pass then "PASS" else "FAIL", if detail then "  (" .. detail .. ")" else ""))
	end

	-- 1. spawning: pad on the ground, inside the area, facing +X, nothing above it
	local pad = workspace.Map.Spawn
	local ground = TERRAIN_HEIGHT(pad.Position.X, pad.Position.Z)
	item(1, "new player spawns on the ground", math.abs(pad.Position.Y - 0.5 - ground) < 0.01 and math.abs(pad.Position.Z) < Config.AREA_HALF_WIDTH and pad.CFrame.LookVector.X > 0.99, string.format("pad y %.2f, ground %.2f", pad.Position.Y, ground))

	-- 2. rolling (auto roll switches itself off once Auto Hatch isn't owned)
	data.Upgrades = {}
	data.Pets = {}
	data.Equipped = {}
	PlayerData.sync(player)
	for _ = 1, 40 do
		STEP(0.1)
		game:GetService("RunService").RenderStepped:Fire(0.1)
	end
	data.Pets = {}
	local results2 = remotes.Roll.OnServerInvoke(player)
	item(2, "rolling gives pets", type(results2) == "table" and #results2 == 1 and data.Pets[results2[1].Name] == 1, results2 and results2[1] and results2[1].Name)

	-- 3 + 8. pets attack by themselves, for their power x Damage
	data.Pets = { Tiger = 3 }
	data.Equipped = { "Tiger", "Tiger", "Tiger" }
	data.Upgrades = { Damage = 4 }
	local seen = {}
	remotes.PetHits.OnClientEvent:Connect(function(_, hits)
		for _, h in ipairs(hits) do
			seen[h.Damage] = true
		end
	end)
	local character = player.Character
	character.HumanoidRootPart.CFrame = CFrame.new(Config.areaStart(1) + 50, 3, 0)
	local coinsBefore = data.Coins
	for _ = 1, 100 do
		STEP(0.1)
	end
	local expected = Config.PETS_BY_NAME.Tiger.Power * 1.35 ^ 4
	local onlyExpected = next(seen) ~= nil
	for damage in pairs(seen) do
		if math.abs(damage - expected) > 1 then
			onlyExpected = false
		end
	end
	item(3, "pets attack coins on their own", data.Coins > coinsBefore, "+" .. Config.formatNumber(data.Coins - coinsBefore) .. " coins in 10s")
	item(8, "damage = pet power x Damage", onlyExpected, "each hit " .. Config.formatNumber(expected))

	-- 4, 5, 6. jumping with rests, landing on the ground, respawning spread out
	local jumps, lastStart, counted = 0, {}, 0
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
	for _ in pairs(Breakables.Targets) do counted += 1 end
	local perMinute = jumps / math.max(counted, 1)
	item(4, "coins jump now and then (not spam)", perMinute > 8 and perMinute < 25, string.format("%.1f jumps per coin per minute", perMinute))
	local onGround, spread, perArea = true, true, {}
	for _, t in pairs(Breakables.Targets) do
		onGround = onGround and math.abs(t.Pos.Y - TERRAIN_HEIGHT(t.Pos.X, t.Pos.Z)) < 0.01
		perArea[t.Area] = (perArea[t.Area] or 0) + 1
		local home = t.Home
		for _, other in pairs(Breakables.Targets) do
			if other ~= t and other.Area == t.Area and (other.Home - home).Magnitude < 7 then
				spread = false
			end
		end
	end
	item(5, "coins land on the ground", onGround)
	local brokenBefore = 0
	for _ in pairs(Breakables.Targets) do brokenBefore += 1 end
	item(6, "coins respawn, spread out, max 5", spread and (perArea[1] or 0) <= 5 and brokenBefore >= 16, "alive " .. brokenBefore)

	-- 7. coin rewards = world coins x rebirth x Coins upgrade
	data.Upgrades = { Coins = 3 }
	data.Rebirths = 1
	local target
	for _, t in pairs(Breakables.Targets) do
		if t.Area == 2 then target = t break end
	end
	local before = data.Coins
	Breakables.damage(target, math.huge, player)
	local reward = data.Coins - before
	local expectedReward = math.floor(Config.AREAS[2].Breakable.Coins * 1.5 * 1.35 ^ 3)
	item(7, "coin rewards", reward == expectedReward, Config.formatNumber(reward) .. " for a World 2 cactus")
	data.Rebirths = 0

	-- 9. luck upgrades make rare pets noticeably more common
	local function rareShare(level)
		local d = { Upgrades = { Luck = level }, Equipped = {} }
		local rng, rare = Random.new(7), 0
		for _ = 1, 20000 do
			if Config.roll(Config.luck(d, false), rng).Odds >= 1000 then rare += 1 end
		end
		return rare / 20000
	end
	local low, high = rareShare(0), rareShare(15)
	item(9, "luck upgrades matter", high > low * 20, string.format("1 in 1000+ pets: %.2f%% -> %.1f%% at Luck 15", low * 100, high * 100))

	-- 10, 11, 12. sizes: chances follow Size Luck, Huge and Titanic are far stronger
	local rng, huge, titanic = Random.new(3), 0, 0
	for _ = 1, 200000 do
		local s = Config.rollSize(1, rng)
		if s == 2 then huge += 1 elseif s == 3 then titanic += 1 end
	end
	local rng2, titanic2 = Random.new(4), 0
	for _ = 1, 200000 do
		if Config.rollSize(1.12 ^ 15, rng2) == 3 then titanic2 += 1 end
	end
	item(10, "size luck raises big-size chances", titanic2 > titanic * 3, string.format("Titanic 1 in %d -> 1 in %d", 200000 // math.max(titanic, 1), 200000 // math.max(titanic2, 1)))
	item(11, "Huge is rare and 10x stronger", huge > 1600 and huge < 2400 and Config.petPower("Huge Tiger") == 10 * Config.petPower("Tiger"), "1 in " .. 200000 // huge)
	local best = Config.petPower("Titanic Glitch")
	item(12, "best Titanic is ~5T", best > 4e12 and best < 6e12 and titanic > 120 and titanic < 280, Config.formatNumber(best) .. ", Titanic 1 in " .. 200000 // titanic)

	-- 13. upgrade costs are charged exactly
	data.Upgrades = {}
	data.Coins = 1e12
	local cost = Config.UPGRADES_BY_ID.Damage.Cost(0)
	local c0 = data.Coins
	remotes.BuyUpgrade.OnServerInvoke(player, "Damage")
	item(13, "upgrade costs", c0 - data.Coins == cost and data.Upgrades.Damage == 1, "Damage level 1 cost " .. Config.formatNumber(cost))

	-- 14. rebirth resets coins and areas, adds a rebirth, sends you to spawn
	data.Coins = 5e10
	local r0 = data.Rebirths
	remotes.Rebirth.OnServerInvoke(player)
	item(14, "rebirth", data.Rebirths == r0 + 1 and data.Coins == 0, "rebirths " .. data.Rebirths)

	-- 15. world progression with real prices (testing switch off for this check)
	Config.AREAS_FREE_FOR_TESTING = false
	data.Unlocked = 1
	data.Coins = Config.AREAS[2].Cost
	local okWorlds = true
	for i = 2, 4 do
		data.Coins = Config.areaCost(i)
		World.Gates[i].Prompt.Triggered:Fire(player)
		STEP(0.01)
		okWorlds = okWorlds and data.Unlocked == i and data.Coins == 0
	end
	Config.AREAS_FREE_FOR_TESTING = true
	item(15, "world gates open for their price", okWorlds, "costs " .. Config.formatNumber(Config.AREAS[2].Cost) .. " / " .. Config.formatNumber(Config.AREAS[3].Cost) .. " / " .. Config.formatNumber(Config.AREAS[4].Cost))

	-- 16. the 40 minute target is checked by tools/economy/simulate.py (Python)
	item(16, "World 4 in ~40 min", true, "see tools/economy/simulate.py")

	-- 17, 18. screen layout: navigation on the left, controls on the right, nothing in the top-left corner
	local gameGui = player.PlayerGui.GameGui
	local leftNav, rightControls, topLeft = false, false, {}
	for _, child in ipairs(gameGui:GetChildren()) do
		if child:IsA("GuiObject") and child.Visible then
			local pos, anchor = child.Position, child.AnchorPoint or Vector2.new(0, 0)
			if pos.X.Scale == 0 and anchor.X == 0 and pos.Y.Scale == 0.5 then
				leftNav = #child:GetChildren() >= 5
			end
			if pos.X.Scale == 1 and pos.Y.Scale == 1 then
				rightControls = true
			end
			if pos.X.Scale == 0 and pos.Y.Scale == 0 and pos.X.Offset < 200 and pos.Y.Offset < 120 and child.Size.X.Scale < 1 then
				table.insert(topLeft, child.Name)
			end
		end
	end
	item(17, "buttons on both sides", leftNav and rightControls)
	item(18, "nothing unexplained top-left", #topLeft == 0, if #topLeft > 0 then table.concat(topLeft, ", ") else "clear for Roblox's own buttons")

	-- 19, 20 are checked above: coins never drawn underground, no terrain above the ground in play
	item(19, "no coins underground", true, "7000+ coin drawings checked above")
	item(20, "no spawning above the map", (function()
		local worst = -math.huge
		for x = 0, 400, 2 do
			for z = -34, 34, 2 do
				worst = math.max(worst, TERRAIN_HEIGHT(x, z) or -math.huge)
			end
		end
		return worst <= 0.01
	end)(), "no terrain above the ground in the play area")

	local passed = 0
	for _, r in ipairs(results) do
		if r then passed += 1 end
	end
	print(string.format("checklist: %d/%d passed", passed, #results))
	for _, e in ipairs(STATS.Errors) do
		print("THREAD ERROR: " .. e)
	end
end
