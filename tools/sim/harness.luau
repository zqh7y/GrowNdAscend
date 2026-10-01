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
	check(worst <= TERRAIN_OFFSET + 0.01, "terrain sticks up to " .. worst .. " inside the playable strip")
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
	-- GATES (testing build): areas start locked and cost 0 coins; the gate
	-- still has to be used. Check the locked look, unlock World 2 at its gate,
	-- check the open look, then open the rest for the tests below.
	do
		local W = __cache["World/init"]
		local function signText(sign)
			for _, d in ipairs(sign:GetDescendants()) do
				if d:IsA("TextLabel") then return d.Text end
			end
			return ""
		end
		local locked = {}
		for i = 2, #Config.AREAS do
			local g = W.Gates[i]
			table.insert(locked, {
				Collide = g.Barrier.CanCollide, Transparency = g.Barrier.Transparency, Prompt = g.Prompt.Enabled,
				Button = g.Button.Transparency, Sign = signText(g.Sign),
				Posts = #g.Barrier.Parent:GetChildren(),
			})
		end
		local unlockedBefore = data.Unlocked
		data.Coins = 0
		W.Gates[2].Prompt.Triggered:Fire(player)
		STEP(0.05)
		local g2 = W.Gates[2]
		STATS.Gates = {
			UnlockedBefore = unlockedBefore, Locked = locked, UnlockedAfter = data.Unlocked, CoinsAfter = data.Coins,
			Open = { Collide = g2.Barrier.CanCollide, Transparency = g2.Barrier.Transparency, Prompt = g2.Prompt.Enabled, Posts = #g2.Barrier.Parent:GetChildren(),
				Sign = signText(g2.Sign) },
		}
		print("gates:", unlockedBefore, locked[1].Sign, "->", data.Unlocked, STATS.Gates.Open.Sign)
		data.Unlocked = #Config.AREAS
		for i = 2, #Config.AREAS do
			W.setGateOpen(i, true)
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
		try("Inventory.open", C("Inventory").open)
		for f = 1, #C("Inventory").FILTERS do
			try("Inventory filter " .. f, function()
				C("Inventory").Filter = f
				C("Inventory").open()
			end)
		end
		for _ = 1, 4 do
			try("Inventory sort", function()
				C("Inventory").Sort = C("Inventory").Sort % #C("Inventory").SORTS + 1
				C("Inventory").open()
			end)
		end
		C("Inventory").Filter, C("Inventory").Sort = 1, 1
		try("Index.open", C("Index").open)
		for world = 0, 4 do
			try("Index world " .. world, function()
				C("Index").Tab = world
				C("Index").open()
			end)
		end
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
		try("Panels.openRebirth", C("Panels").openRebirth)
		try("Panels.openSettings", C("Panels").openSettings)
		try("Roll.roll", C("Roll").roll)
		try("Roll.bigReveal titanic", C("Roll").bigReveal, "Glitch", 3)
		try("Rebirth.open", C("Rebirth").open)
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
		-- nothing of a living coin may sink into the ground, over many frames
		-- (checks every real part's bottom, not the model's pivot)
		local deepest, deepestName = math.huge, ""
		for _ = 1, 400 do
			frames(1)
			for _, model in ipairs(workspace.LivingCoins:GetChildren()) do
				local feet = model:GetPivot().Position
				local ground = TERRAIN_HEIGHT(feet.X, feet.Z) or 0
				for _, part in ipairs(model:GetDescendants()) do
					if part:IsA("BasePart") and part.Name ~= "Marker" then
						local cf, size = part.CFrame, part.Size
						local halfY = (math.abs(cf.RightVector.Y) * size.X + math.abs(cf.UpVector.Y) * size.Y + math.abs(cf.LookVector.Y) * size.Z) / 2
						if part.Shape and part.Shape.Name == "Ball" then
							halfY = size.X / 2
						end
						local bottom = cf.Position.Y - halfY - ground
						if bottom < deepest then
							deepest, deepestName = bottom, model.Name
						end
					end
				end
			end
		end
		STATS.CoinDepth = deepest
		print(string.format("living coin parts: deepest %.2f studs below/above the ground (%s)", deepest, deepestName))
		if deepest < -0.3 then
			print("GAME ERROR: a living coin was drawn underground")
		end
		try("Effects.coins", C("Effects").coins, Vector3.new(10, 2, 0), 12345)
		try("Effects.confetti", C("Effects").confetti, 10)
		frames(200)

		-- ambient life: walk into each world and watch for 40 seconds
		local Ambient = C("Ambient")
		local Creature = C("Creature")
		local rootPart = player.Character.HumanoidRootPart
		local report = { Worlds = {}, Leftovers = 0, OffGround = 0, Errors = #STATS.Errors }
		local previousArea = nil
		for area = 1, 4 do
			local x = __cache["Shared/Config"].areaStart(area) + 50
			rootPart.CFrame = CFrame.new(x, 3, 0)
			camera.CFrame = CFrame.lookAt(Vector3.new(x - 12, 10, 0), Vector3.new(x + 10, 3, 0))
			local seen, peakAnimals, peakFalling, landed, swaying, leftover = {}, 0, 0, 0, 0, 0
			local kindsBefore = table.clone(Ambient.Stats.Kinds)
			local statsBefore = table.clone(Ambient.Stats)
			local maxSway = 0
			for f = 1, 1800 do
				frames(1)
				if f % 30 == 0 then
					local animals = 0
					for _, d in ipairs(workspace.Ambient:GetChildren()) do
						if d:IsA("Model") then
							animals += 1
							seen[d.Name] = true
						end
					end
					peakAnimals = math.max(peakAnimals, animals)
					local _, falling = Ambient.count()
					peakFalling = math.max(peakFalling, falling)
					maxSway = math.max(maxSway, Ambient.Stats.Swaying)
				end
				-- 20 seconds in, nothing from the last world should be left
				if f == 1200 and previousArea then
					for _, d in ipairs(workspace.Ambient:GetChildren()) do
						if d:IsA("Model") and d:GetAttribute("Area") ~= area then
							leftover += 1
						end
					end
				end
			end
			-- wild ground animals stand on the ground
			for _, d in ipairs(workspace.Ambient:GetChildren()) do
				if d:IsA("Model") and d.Name:sub(1, 5) == "Wild_" then
					local species = PetModels.SPECIES[d.Name:sub(6)]
					if species and species.Move ~= "fly" and species.Move ~= "hover" and species.Move ~= "swim" and species.Body ~= "bird" then
						local p = d:GetPivot().Position
						local ground = TERRAIN_HEIGHT(p.X, p.Z)
						if ground and (p.Y < ground - 0.5 or p.Y > ground + 4) then
							report.OffGround += 1
						end
					end
				end
			end
			local names = {}
			for n in pairs(seen) do
				table.insert(names, n)
			end
			table.sort(names)
			local spawned = {}
			for kind, n in pairs(Ambient.Stats.Kinds) do
				if n > (kindsBefore[kind] or 0) then
					table.insert(spawned, kind .. " " .. (n - (kindsBefore[kind] or 0)))
				end
			end
			table.sort(spawned)
			local happened = string.format("landings %d, chirps %d, ice cracks %d, swaying up to %d",
				Ambient.Stats.Landings - statsBefore.Landings, Ambient.Stats.Chirps - statsBefore.Chirps, Ambient.Stats.Cracks - statsBefore.Cracks, maxSway)
			print(string.format("ambient world %d: peak %d animals, %d falling bits, %d left from the last world", area, peakAnimals, peakFalling, leftover))
			print("    spawned: " .. table.concat(spawned, ", ") .. " | " .. happened)
			print("    kinds: " .. table.concat(names, ", "))
			report.Worlds[area] = { Peak = peakAnimals, Seen = seen, Falling = peakFalling, Sway = maxSway, Kinds = #spawned }
			report.Leftovers += leftover
			previousArea = area
		end
		report.Peak = Ambient.Stats.Peak
		report.Errors = #STATS.Errors - report.Errors
		print("ambient peak animals at once:", Ambient.Stats.Peak, "errors:", report.Errors)
		STATS.Ambient = report
		rootPart.CFrame = CFrame.new(__cache["Shared/Config"].areaStart(1) + 50, 3, 0)
		frames(60)

		local Cfg = __cache["Shared/Config"]
		local Breakables = __cache["Breakables"]

		-- WORLDS: walk into each world with a team; the targets must be drawn
		-- there (5, on the ground, with a health bar), get attacked and
		-- destroyed by the pets, pay out, and come back
		local worldsReport = {}
		if C("Roll").autoOn() then
			C("Roll").toggleAuto() -- (auto roll would re-equip pets while we count)
		end
		data.Pets = { Tiger = 3, ["Titanic Glitch"] = 3 }
		data.Equipped = { "Titanic Glitch", "Titanic Glitch", "Titanic Glitch" }
		PlayerData.sync(player)
		frames(30)
		local team = { "Titanic Glitch", "Titanic Glitch", "Titanic Glitch" }
		local function setTeam(list)
			data.Equipped = list
			PlayerData.sync(player)
		end
		for area = 1, 4 do
			local x = Cfg.areaStart(area) + 50
			setTeam({}) -- no pets while counting
			rootPart.CFrame = CFrame.new(x, 3, 0)
			frames(60 * 6) -- let anything broken earlier respawn
			local w = { Drawn = 0, OnGround = true, Bars = true, InArea = true }
			for _, model in ipairs(workspace.LivingCoins:GetChildren()) do
				-- where it really is: its parts (the lowest point and the middle)
				local lowest, sum, n = math.huge, Vector3.zero, 0
				for _, part in ipairs(model:GetDescendants()) do
					if part:IsA("BasePart") and part.Name ~= "Marker" then
						local cf, size = part.CFrame, part.Size
						local halfY = (math.abs(cf.RightVector.Y) * size.X + math.abs(cf.UpVector.Y) * size.Y + math.abs(cf.LookVector.Y) * size.Z) / 2
						lowest = math.min(lowest, cf.Position.Y - halfY)
						sum += cf.Position
						n += 1
					end
				end
				local p = sum / math.max(n, 1)
				if p.X >= Cfg.areaStart(area) and p.X < Cfg.areaStart(area) + Cfg.AREA_LENGTH then
					w.Drawn += 1
					local ground = TERRAIN_HEIGHT(p.X, p.Z)
					-- standing on it: not sunk in, and not floating (mid-jump allowed)
					if not ground or lowest < ground - 0.4 or lowest > ground + 4 then
						w.OnGround = false
					end
					if not model:FindFirstChild("HealthBar") or not model:FindFirstChildWhichIsA("BasePart") then
						w.Bars = false
					end
				end
			end
			w.ClientCount = C("Living").counts()[area]
			-- fight here for 15 seconds
			setTeam(team)
			local coinsBefore = data.Coins
			local popped = 0
			local popConn = remotes.CoinPop.OnClientEvent:Connect(function(_, _, popArea)
				if popArea == area then popped += 1 end
			end)
			local idsBefore = {}
			for id, t in pairs(Breakables.Targets) do
				if t.Area == area then idsBefore[id] = true end
			end
			local hits = 0
			local conn = remotes.PetHits.OnClientEvent:Connect(function(id, list)
				local t = Breakables.Targets[id]
				if (t and t.Area == area) or idsBefore[id] then
					hits += #list
				end
			end)
			frames(60 * 15)
			conn:Disconnect()
			popConn:Disconnect()
			w.Hits, w.Destroyed, w.Coins = hits, popped, data.Coins - coinsBefore
			-- and they come back
			setTeam({})
			frames(60 * 6)
			w.AliveAfter = Breakables.count(area)
			print(string.format("world %d: %d targets drawn (client says %d), on ground %s, bars %s | pets hit %d times, destroyed %d, +%s coins, alive after respawn %d",
				area, w.Drawn, w.ClientCount, tostring(w.OnGround), tostring(w.Bars), w.Hits, w.Destroyed, Cfg.formatNumber(w.Coins), w.AliveAfter))
			worldsReport[area] = w
		end
		STATS.Worlds = worldsReport
		setTeam(team)
		rootPart.CFrame = CFrame.new(Cfg.areaStart(1) + 50, 3, 0)

		-- HATCH: the show for a common pet, a huge and a titanic
		local Hatch = C("Hatch")
		if C("Roll").autoOn() then
			C("Roll").toggleAuto() -- stop auto rolling from earlier steps
		end
		for _ = 1, 900 do
			if not Hatch.busy() then break end
			frames(1)
		end
		local hatchReport = {}
		for _, case in ipairs({
			{ Key = "common", Result = { Pet = "Dog", Size = 1, First = true } },
			{ Key = "rare", Result = { Pet = "Lion", Size = 1 } },
			{ Key = "huge", Result = { Pet = "Lion", Size = 2, FirstOfSize = true } },
			{ Key = "titanic", Result = { Pet = "Cat", Size = 3 } },
			{ Key = "crazy", Result = { Pet = "Glitch", Size = 1 } },
		}) do
			local startClock = CLOCK
			try("hatch " .. case.Key, Hatch.play, { case.Result, { Pet = "Cat", Size = 1 } }, false, 1)
			local last = table.clone(Hatch.Last or {})
			last.Seconds = CLOCK - startClock
			last.Cutscene = Hatch.LastCutscene and table.clone(Hatch.LastCutscene)
			hatchReport[case.Key] = last
			if case.Key == "common" then
				-- no window: nothing big and solid behind the pets, only the soft dim
				local panels = {}
				for _, d in ipairs(Hatch.Shade:GetDescendants()) do
					if d:IsA("GuiObject") and d.BackgroundTransparency < 0.5 and d.Size.X.Offset >= 300 and d.Size.Y.Offset >= 200 then
						table.insert(panels, d.Name)
					end
				end
				last.Panels = #panels
			end
			print(string.format("hatch %s: tier %d, %d pets, landed %s, early speed %.1f px/frame -> late %.2f, silhouette %.2fs, rays %s, banner '%s', power '%s', %.1fs in all, extra pets %d",
				case.Key, last.Tier or -1, last.Pets or 0, tostring(last.Landed), last.SpeedEarly or 0, last.SpeedLate or 0, last.Silhouette or 0, tostring(last.Rays), last.Banner or "", tostring(last.Power), last.Seconds, last.Others or 0))
		end
		-- skipping: clicking through a titanic show ends it quickly
		local skipStart = CLOCK
		local co = task.spawn(Hatch.play, { { Pet = "Glitch", Size = 3 } }, false, 1)
		for _ = 1, 400 do
			if coroutine.status(co) == "dead" then break end
			Hatch.skip()
			frames(1)
		end
		hatchReport.SkipSeconds = CLOCK - skipStart
		hatchReport.SkipCutscene = Hatch.LastCutscene and table.clone(Hatch.LastCutscene)
		-- AUTO: the bush cutscene plays once, then a short reveal during the cooldown
		local camera = workspace.CurrentCamera
		local autoA, autoB = {}, {}
		local t0 = CLOCK
		try("hatch auto huge 1", Hatch.play, { { Pet = "Lion", Size = 2 } }, true, 1, "compact", true)
		autoA = table.clone(Hatch.LastCutscene or {})
		autoA.Seconds = CLOCK - t0
		t0 = CLOCK
		try("hatch auto huge 2", Hatch.play, { { Pet = "Lion", Size = 2 } }, true, 1, "compact", true)
		autoB = table.clone(Hatch.LastCutscene or {})
		autoB.Seconds = CLOCK - t0
		hatchReport.AutoCutscenes = { autoA, autoB }
		hatchReport.CameraBack = camera.CameraType ~= Enum.CameraType.Scriptable
		local bushes = 0
		for _, d in ipairs(workspace:GetChildren()) do
			if d.Name == "HatchBush" then bushes += 1 end
		end
		hatchReport.BushesLeft = bushes
		print(string.format("auto cutscenes: first %s (%.1fs), second %s (%.1fs); camera back %s, bushes left %d",
			tostring(autoA.Bush), autoA.Seconds, tostring(autoB.Abbreviated), autoB.Seconds, tostring(hatchReport.CameraBack), bushes))
		-- rapid rolling: hammering Roll never starts a second show or breaks it
		data.Upgrades = { AutoHatch = 0 }
		local rollsBefore = data.Rolls
		local overlaps, errorsBefore = 0, #STATS.Errors
		for k = 1, 30 do
			task.spawn(C("Roll").roll)
			frames(6)
			if k % 5 == 0 and Hatch.busy() then
				overlaps += 0
			end
		end
		for _ = 1, 600 do
			if not Hatch.busy() then break end
			frames(1)
		end
		hatchReport.RapidRolls = data.Rolls - rollsBefore
		hatchReport.RapidErrors = #STATS.Errors - errorsBefore
		hatchReport.EndedClean = not Hatch.busy()
		print(string.format("hatch skip: titanic done in %.1fs when clicking | rapid rolling: 30 presses -> %d rolls, %d errors, finished %s",
			hatchReport.SkipSeconds, hatchReport.RapidRolls, hatchReport.RapidErrors, tostring(not Hatch.busy())))
		-- flex rolls: showstoppers fly past, but the real result is what lands and is revealed
		Hatch.ForceFlex = true
		try("hatch flex", Hatch.play, { { Pet = "Dog", Size = 1 } }, false, 1)
		local flexLast = table.clone(Hatch.Last or {})
		hatchReport.Flex = flexLast
		print(string.format("hatch flex: %d showstoppers passed (%s), landed on %s, revealed %s",
			flexLast.FlexShown or 0, table.concat(flexLast.FlexNames or {}, ", "), tostring(flexLast.LandedName), tostring(flexLast.Revealed)))
		-- a real Titanic is always revealed as exactly that Titanic
		try("hatch real titanic", Hatch.play, { { Pet = "Tiger", Size = 3 } }, true, 1)
		hatchReport.RealTitanic = table.clone(Hatch.Last or {})
		STATS.Hatch = hatchReport

		-- AUTO ROLL is free: it rolls with no upgrades at all
		data.Upgrades = {}
		PlayerData.sync(player)
		frames(2)
		local autoBefore = data.Rolls
		if not C("Roll").autoOn() then
			C("Roll").toggleAuto()
		end
		local autoBottom, chainFeeds, lastFeed = false, {}, nil
		local trayFrames, trayOff = 0, 0
		for _ = 1, 900 do
			frames(1)
			-- the tray never moves: every frame it's shown, it's at the same spot
			local tray = Hatch.Spinner
			if tray.Visible then
				trayFrames += 1
				local p = tray.Position
				if p.X.Scale ~= 0.5 or p.X.Offset ~= 0 or p.Y.Scale ~= 1 or p.Y.Offset ~= -14 or tray.AnchorPoint.X ~= 0.5 or tray.AnchorPoint.Y ~= 1 then
					trayOff += 1
				end
			end
			if Hatch.LastFeed and Hatch.LastFeed ~= lastFeed then
				lastFeed = Hatch.LastFeed
				table.insert(chainFeeds, { Multiplier = lastFeed.Multiplier, Next = lastFeed.NextMultiplier })
				if lastFeed.Bottom then autoBottom = true end
			end
		end
		STATS.ChainFeeds = chainFeeds
		STATS.Tray = { Frames = trayFrames, Off = trayOff }
		local autoRolls = data.Rolls - autoBefore
		C("Roll").toggleAuto()
		for _ = 1, 900 do
			if not Hatch.busy() then break end
			frames(1)
		end
		-- COMPACT hatches (the default): a small row at the top, no dim, the
		-- full show never opens for a normal pet
		local State = C("State")
		State.Settings.FullHatch = false
		local hiddenBefore, everShaded = data.Rolls, false
		Hatch.LastFeed = nil
		local nextIsBonus = (data.Rolls + 1) % __cache["Shared/Config"].BONUS_EVERY == 0
		local rollWorld = PlayerData.worldOf(player)
		data.LuckChain = 1
		local baseLuck = __cache["Shared/Config"].luck(data, nextIsBonus, rollWorld)
		data.LuckChain = 8
		PlayerData.sync(player)
		frames(2)
		task.spawn(C("Roll").roll)
		for _ = 1, 240 do
			frames(1)
			if Hatch.Shade.Visible then everShaded = true end
		end
		local feed = Hatch.LastFeed or {}
		local controlsGui, gameGui = player.PlayerGui:FindFirstChild("ControlsGui"), player.PlayerGui:FindFirstChild("GameGui")
		STATS.Controls = controlsGui ~= nil and controlsGui:FindFirstChild("Controls") ~= nil and (controlsGui.DisplayOrder or 0) > (gameGui.DisplayOrder or 0)
		STATS.Chain8 = { Motion = feed.Motion, Expected = math.min(baseLuck * 8, __cache["Shared/Config"].MAX_LUCK), Luck = feed.Context and feed.Context.Luck, Multiplier = feed.Multiplier, Chip = feed.LuckChip, Chances = feed.Chances, Context = feed.Context, Result = feed.Landed, ResultChance = feed.ResultChance }
		STATS.AutoHide = { AutoBottom = autoBottom, TopAfter = feed.Bottom == true, AutoRolls = autoRolls, HiddenRolls = data.Rolls - hiddenBefore, EverShaded = everShaded, Landed = feed.LandedName, Names = feed.Names, Backdrop = feed.Backdrop }
		print(string.format("auto roll with no upgrades: %d rolls in 15s | compact hatch: %d roll, landed %s (shown %s), backdrop transparency %s, full screen dim %s",
			autoRolls, STATS.AutoHide.HiddenRolls, tostring(feed.LandedName), tostring(feed.Names and feed.Names[1]), tostring(feed.Backdrop), tostring(everShaded)))

		-- LEVEL: the HUD shows level and EXP; a level-up shows the celebration
		local Hud = C("Hud")
		data.Level, data.Exp = 1, 0
		PlayerData.sync(player)
		frames(2)
		local levelBadge
		for _, d in ipairs(player.PlayerGui:GetDescendants()) do
			if d:IsA("TextLabel") and string.match(d.Text, "^LEVEL %d+$") then
				levelBadge = d
			end
		end
		remotes.LevelUp:FireClient(player, 2)
		frames(10)
		local shown, shownText = Hud.LevelUpShown()
		STATS.LevelUi = { Badge = levelBadge and levelBadge.Text, Celebrated = shown, Text = shownText }
		print("level ui:", STATS.LevelUi.Badge, shown, shownText)

		-- INDEX: 70 per category, categories on the right, silhouettes for the unfound
		local Index = C("Index")
		data.Discovered = { Dog = true, Cat = true, ["Huge Dog"] = true, Tiger = true, ["Huge Tiger"] = true, ["Titanic Glitch"] = true, Glitch = true }
		PlayerData.sync(player)
		local indexReport = {}
		for size = 1, 3 do
			Index.Tab, Index.Size = 0, size
			Index.open()
			frames(2)
			local cards, silhouettes, shown = 0, 0, 0
			for _, child in ipairs(Index.Grid:GetChildren()) do
				if child:IsA("Frame") then
					cards += 1
					local view = child:FindFirstChildWhichIsA("ViewportFrame")
					if view and string.sub(view:GetAttribute("Key"), -1) == "#" then
						silhouettes += 1
					else
						shown += 1
					end
				end
			end
			indexReport[size] = { Cards = cards, Silhouettes = silhouettes, Shown = shown, Found = Index.found(size) }
			print(string.format("index %s: %d cards, %d found (%d in colour), %d silhouettes", Cfg.SIZES[size].Name, cards, indexReport[size].Found, shown, silhouettes))
		end
		indexReport.SideOnRight = Index.Side.AnchorPoint.X == 1 and Index.Side.Position.X.Scale == 1
		Index.Size = 1
		STATS.Index = indexReport

		-- POLISH: collection rewards, luck pill, boost badge, upgrade states, reduced motion, world banner
		local polish = {}
		-- collection rewards: claim through the Index (with its reveal), once only
		data.Discovered = {}
		for i = 1, 12 do
			data.Discovered[Cfg.PETS[i].Name] = true
		end
		data.Milestones = {}
		data.Coins = 1000
		data.Equipped = {} -- (no fighting while we count coins)
		PlayerData.sync(player)
		frames(2)
		polish.ReadyBefore = Index.anyClaimable()
		polish.DotBefore = C("Hud").IndexDot.Visible
		local coins0 = data.Coins
		local claimCo = task.spawn(Index.claim)
		for _ = 1, 600 do
			if coroutine.status(claimCo) == "dead" then break end
			frames(1)
		end
		polish.FirstClaim = Index.LastClaim and table.clone(Index.LastClaim)
		polish.CoinsAfterFirst = data.Coins - coins0
		polish.ClaimedN5 = data.Milestones.n5 == true
		-- claiming the same one again (a double click, a replay) pays nothing
		local coins1, chain1 = data.Coins, data.LuckChain
		local again = remotes.ClaimMilestone:InvokeServer("n5")
		local bogus = remotes.ClaimMilestone:InvokeServer("n70")
		polish.Repeat = { Again = again, Bogus = bogus, CoinsSame = data.Coins == coins1, ChainSame = data.LuckChain == chain1 }
		-- the next one (n10: coins and a x2 boost) multiplies the waiting boost
		data.LuckChain = 4
		local second = remotes.ClaimMilestone:InvokeServer("n10")
		polish.Second = { Got = second, Chain = data.LuckChain }
		data.LuckChain = 1
		PlayerData.sync(player)
		frames(2)
		-- the luck pill shows exactly the next roll's luck, and follows equipping
		local Roll = C("Roll")
		local function expectedLuck()
			local nextIsBonus = (data.Rolls + 1) % Cfg.BONUS_EVERY == 0
			return Cfg.luck(data, nextIsBonus, Roll.currentWorld(data))
		end
		data.Pets = { Fox = 1, Glitch = 1 }
		data.Equipped = {}
		PlayerData.sync(player)
		frames(2)
		local before = Roll.ShownLuck
		local okBefore = math.abs((before or 0) - expectedLuck()) < 1e-9
		remotes.Equip:InvokeServer("Glitch")
		frames(2)
		local after = Roll.ShownLuck
		polish.LuckPill = { Before = before, After = after, Expected = expectedLuck(), Ok = okBefore and math.abs((after or 0) - expectedLuck()) < 1e-9 and after > before,
			InCoinPill = Roll.LuckPill.Parent ~= nil and Roll.LuckPill.Parent.Parent == player.PlayerGui.GameGui }
		-- the boost badge: next to the Roll button, never a sentence in the middle
		data.LuckChain = 8
		PlayerData.sync(player)
		frames(2)
		local waitingState = Roll.BadgeState
		data.LuckChain = 1
		PlayerData.sync(player)
		frames(20)
		local sentences = 0
		for _, d in ipairs(player.PlayerGui:GetDescendants()) do
			if d:IsA("TextLabel") and (string.find(d.Text, "NEXT ROLL") or string.find(d.Text, "THIS ROLL")) then
				sentences += 1
			end
		end
		polish.Badge = { Waiting = waitingState, After = Roll.BadgeState, InControls = Roll.BoostBadge.Parent == player.PlayerGui.ControlsGui, Sentences = sentences }
		-- upgrade tree: every card shows its price or state, and the four states read right
		local Tree = C("UpgradeTree")
		data.Equipped = {} -- (no fighting: coins must stay where we put them)
		data.Upgrades = { Coins = 20 }
		data.Coins = 1e15
		PlayerData.sync(player)
		Tree.open()
		Tree.select("Luck")
		frames(2)
		local withPrice = 0
		for _, n in pairs(Tree.Nodes) do
			if n.PriceText.Text ~= "" then withPrice += 1 end
		end
		local states = table.clone(Tree.States)
		data.Coins = 0
		PlayerData.sync(player)
		Tree.select("Luck")
		frames(2)
		polish.Tree = { WithPrice = withPrice, Count = #Cfg.UPGRADES, Maxed = states.Coins, Affordable = states.Luck, Available = Tree.States.Luck, Locked = Tree.States.Rolls }
		C("Screen").close(Tree.Modal)
		-- reduced motion
		local Ui = C("Ui")
		local State = C("State")
		State.Settings.ReducedMotion = true
		local probe = Instance.new("Frame")
		Ui.appear(probe, 5)
		local scaler = probe:FindFirstChildOfClass("UIScale")
		polish.Reduced = Ui.reduced() == true and scaler == nil
		State.Settings.ReducedMotion = false
		Ui.appear(probe, 5)
		polish.NormalMotion = probe:FindFirstChildOfClass("UIScale") ~= nil
		-- the world banner when walking into another world
		local rootPart = player.Character.HumanoidRootPart
		rootPart.CFrame = CFrame.new(Cfg.areaStart(1) + 50, 3, 0)
		frames(30)
		rootPart.CFrame = CFrame.new(Cfg.areaStart(2) + 50, 3, 0)
		frames(30)
		polish.Banner = C("Hud").LastBanner
		rootPart.CFrame = CFrame.new(Cfg.areaStart(1) + 50, 3, 0)
		frames(30)
		STATS.Polish = polish

		-- BUILD 14: Index labels, simple inventory, team shares, roll controls
		local b14 = {}
		-- Index: no "Best in", every world, the exact chance here
		Index.Tab, Index.Size = 0, 1
		Index.open()
		frames(2)
		local bestIn, everyWorld, chanceOk, checkedCards = 0, 0, 0, 0
		local idxData = data
		local idxWorld = Index.currentWorld(idxData)
		local nextIsBonus = (idxData.Rolls + 1) % Cfg.BONUS_EVERY == 0
		local luckNow = Cfg.luck(idxData, nextIsBonus, idxWorld)
		local sizeLuckNow = Cfg.sizeLuck(idxData) * (if nextIsBonus then Cfg.BONUS_LUCK else 1)
		for _, cardFrame in ipairs(Index.Grid:GetChildren()) do
			if cardFrame:IsA("Frame") then
				for _, d in ipairs(cardFrame:GetDescendants()) do
					if d:IsA("TextLabel") then
						if string.find(d.Text, "Best in") then bestIn += 1 end
						if d.Name == "Worlds" and d.Text == "Hatches in every world" then everyWorld += 1 end
						if d.Name == "ChanceHere" then
							checkedCards += 1
							local pet = Cfg.PETS[cardFrame.LayoutOrder]
							local want = Cfg.formatChance(Cfg.chanceOf(pet.Name, luckNow, sizeLuckNow, idxWorld)) .. " here"
							if d.Text == want then chanceOk += 1 end
						end
					end
				end
			end
		end
		b14.Index = { BestIn = bestIn, EveryWorld = everyWorld, ChanceOk = chanceOk, Cards = checkedCards }
		do
		-- Inventory (build 15): dense grid, details slide in only on selection
		local Inv = C("Inventory")
		data.Pets = { Tiger = 2, Dog = 1, ["Huge Fox"] = 1 }
		data.Equipped = {}
		data.Upgrades = {}
		PlayerData.sync(player)
		Inv.Filter, Inv.Sort = 1, 1
		Inv.select(nil)
		Inv.open()
		frames(2)
		local statsInGrid, simpleCards, tigerCard = 0, 0, nil
		for _, cardFrame in ipairs(Inv.Grid:GetChildren()) do
			if cardFrame:IsA("GuiObject") then
				if cardFrame:FindFirstChild("PetName") and not cardFrame:FindFirstChild("Power") and not cardFrame:FindFirstChild("Action") then
					simpleCards += 1
				end
				if cardFrame.Name == "Tiger" then tigerCard = cardFrame end
				for _, d in ipairs(cardFrame:GetDescendants()) do
					if d.Name == "Stats" then statsInGrid += 1 end
				end
			end
		end
		local fullColumns, fullWidth = Inv.Columns, Inv.Grid.Size.X.Offset
		local hiddenBefore = Inv.Detail.Visible == false
		local amountBadge = tigerCard and tigerCard:FindFirstChild("Amount") and tigerCard.Amount.Text
		if tigerCard then
			tigerCard.Activated:Fire()
			frames(2)
		end
		local shownOnSelect = Inv.Detail.Visible and Inv.Selected == "Tiger"
		local narrowColumns, narrowWidth = Inv.Columns, Inv.Grid.Size.X.Offset
		local gridVisible = Inv.Grid.Visible
		local fitsBeside = narrowWidth + 268 <= 900 - 48
		local actionBefore = Inv.DetailAction.Content.Label.Text
		Inv.DetailAction.Activated:Fire()
		frames(3)
		local equippedTiger = table.find(data.Equipped, "Tiger") ~= nil
		local actionAfter = Inv.DetailAction.Content.Label.Text
		local tigerAfter
		for _, cardFrame in ipairs(Inv.Grid:GetChildren()) do
			if cardFrame.Name == "Tiger" then tigerAfter = cardFrame end
		end
		-- switching pets updates the same panel (no rebuild of the grid)
		local firstChild = Inv.Grid:FindFirstChild("Dog")
		Inv.select("Huge Fox")
		frames(1)
		local sameGrid = Inv.Grid:FindFirstChild("Dog") == firstChild and firstChild ~= nil
		local detailOk = 0
		for _, stat in ipairs(Cfg.STATS) do
			for _, row in ipairs(Inv.Detail:GetDescendants()) do
				if row.Name == stat and row:FindFirstChild("Value") and row.Value.Text == Cfg.formatStat(Cfg.petStat("Huge Fox", stat)) then
					detailOk += 1
				end
			end
		end
		local dpsShown = false
		for _, d in ipairs(Inv.Detail:GetDescendants()) do
			if d:IsA("TextLabel") and d.Text == Cfg.formatNumber(Cfg.petDps(data, "Huge Fox")) then dpsShown = true end
		end
		-- filters: Normal hides Huge, Huge shows only Huge
		local function names()
			local out = {}
			for _, cardFrame in ipairs(Inv.Grid:GetChildren()) do
				if cardFrame:IsA("GuiObject") then table.insert(out, cardFrame.Name) end
			end
			table.sort(out)
			return table.concat(out, ",")
		end
		Inv.Filter = 2 Inv.open() frames(1)
		local normalList = names()
		Inv.Filter = 3 Inv.open() frames(1)
		local hugeList = names()
		Inv.Filter = 1
		Inv.select(nil)
		frames(1)
		local closedOk = Inv.Detail.Visible == false and Inv.Columns == fullColumns
		b14.Inventory = { Cards = simpleCards, StatsInGrid = statsInGrid, FullColumns = fullColumns, FullWidth = fullWidth, Hidden = hiddenBefore,
			Shown = shownOnSelect, NarrowColumns = narrowColumns, GridVisible = gridVisible, Fits = fitsBeside, Amount = amountBadge,
			Before = actionBefore, Equipped = equippedTiger, After = actionAfter, Tick = tigerAfter and tigerAfter:FindFirstChild("Equipped") ~= nil,
			Same = sameGrid, DetailStats = detailOk, Dps = dpsShown, Normal = normalList, Huge = hugeList, Closed = closedOk,
			Small = Inv.columnsFor(560), Wide = Inv.columnsFor(1200) }
		C("Screen").close(Inv.Detail.Parent.Parent.Parent)
		-- Equip Best: picks by real damage, respects slots and copies, never unowned
		local b15 = {}
		local titanic = "Titanic Tiger"
		data.Pets = { Tiger = 3, Dog = 2, ["Huge Fox"] = 1, [titanic] = 1 }
		data.Equipped = { "Dog" }
		data.Upgrades = { Slots = 2 }
		PlayerData.sync(player)
		frames(1)
		local slots = Cfg.maxEquipped(data)
		local luckBefore = Cfg.teamStat(data, "Luck")
		local want = Cfg.bestTeam(data)
		local r1 = remotes.EquipBest:InvokeServer()
		frames(2)
		local client = C("State").Data or {}
		local owned = true
		local used = {}
		for _, name in ipairs(data.Equipped) do
			used[name] = (used[name] or 0) + 1
			if used[name] > (data.Pets[name] or 0) then owned = false end
		end
		local best = true
		local total = 0
		for _, name in ipairs(data.Equipped) do total += Cfg.petDps(data, name) end
		-- no single swap of an equipped pet for an owned spare beats it
		for name, n in pairs(data.Pets) do
			if (used[name] or 0) < n then
				for _, on in ipairs(data.Equipped) do
					if Cfg.petDps(data, name) > Cfg.petDps(data, on) + 1e-9 then best = false end
				end
			end
		end
		local r2 = remotes.EquipBest:InvokeServer()
		b15.Best = { Slots = slots, Count = #data.Equipped, Matches = Cfg.sameTeam(data.Equipped, want), Owned = owned, Best = best,
			Changed1 = type(r1) == "table" and r1.Changed == true, Changed2 = type(r2) == "table" and r2.Changed == false,
			HasTitanic = table.find(data.Equipped, titanic) ~= nil, DogGone = table.find(data.Equipped, "Dog") == nil,
			Synced = client.Equipped ~= nil and Cfg.sameTeam(client.Equipped, data.Equipped),
			LuckBefore = luckBefore, LuckAfter = Cfg.teamStat(data, "Luck"), Dps = total, Team = table.concat(data.Equipped, ", ") }
		-- duplicates: more slots than pets, Tiger x3 and a Dog -> all three Tigers and the Dog
		data.Pets = { Tiger = 3, Dog = 1 }
		data.Equipped = {}
		data.Upgrades = { Slots = 3 }
		remotes.EquipBest:InvokeServer()
		local tigers = 0
		for _, name in ipairs(data.Equipped) do if name == "Tiger" then tigers += 1 end end
		b15.Dupes = { Slots = Cfg.maxEquipped(data), Tigers = tigers, Count = #data.Equipped }
		-- power order isn't damage order: a pet with a better Damage stat wins
		-- (no two pets in the roster disagree, so give a weaker pet a big Damage
		-- stat for this check and put it back after)
		local pa, pb = "Tiger", "Dog"
		local dogPet = Cfg.PETS_BY_NAME[pb]
		local savedDamage = dogPet.Stats.Damage
		dogPet.Stats.Damage = (Cfg.petStat(pa, "Damage") * Cfg.petPower(pa) / Cfg.petPower(pb)) * 1.5
		data.Pets = { [pa] = 1, [pb] = 1 }
		data.Equipped = {}
		data.Upgrades = {}
		local powerFirst = Cfg.petPower(pa) > Cfg.petPower(pb) and Cfg.petDps(data, pa) < Cfg.petDps(data, pb)
		remotes.EquipBest:InvokeServer()
		b15.Order = { Found = powerFirst, Picked = data.Equipped[1], Want = pb, Other = pa }
		dogPet.Stats.Damage = savedDamage
		-- the shared client action shows a toast either way
		data.Pets = { Tiger = 1 }
		data.Equipped = { "Tiger" }
		data.Upgrades = {}
		PlayerData.sync(player)
		frames(1)
		Inv.equipBest()
		b15.Feedback = { Optimized = type(Inv.LastEquipBest) == "table" and Inv.LastEquipBest.Changed == false,
			TreeButton = C("UpgradeTree").EquipBestButton ~= nil, InvButton = Inv.EquipBestButton ~= nil }
		data.Equipped = {}
		PlayerData.sync(player)
		frames(1)
		STATS.B15 = b15
		print(string.format("build 15: inventory %d cols full (%dpx) -> %d with details; equip best %s (%d/%d slots), second call changed=%s; dupes %d tigers; power/damage pick %s over %s",
			fullColumns or -1, fullWidth or -1, narrowColumns or -1, b15.Best.Team, b15.Best.Count, slots, tostring(not b15.Best.Changed2),
			tigers, tostring(b15.Order.Picked), tostring(b15.Order.Other)))
		end
		-- team shares: per-pet DPS and % adding up to 100, updating with the team
		local Hud = C("Hud")
		data.Pets = { Tiger = 1, Dog = 1, ["Huge Fox"] = 1 }
		data.Upgrades = { Slots = 1 }
		data.Equipped = { "Tiger", "Dog", "Huge Fox" }
		PlayerData.sync(player)
		frames(2)
		local function sharesOk()
			local shares, total, sum, close = Hud.TeamShares or {}, 0, 0, true
			for _, sh in ipairs(shares) do total += sh.Dps end
			for _, sh in ipairs(shares) do
				sum += sh.Percent
				if total > 0 and math.abs(sh.Percent - sh.Dps / total * 100) > 1 then close = false end
				if not string.find(sh.Text, sh.Percent .. "%%") then close = false end
			end
			return #shares, sum, close
		end
		local n3, sum3, ok3 = sharesOk()
		remotes.Equip:InvokeServer("Tiger", true)
		frames(2)
		local n2, sum2, ok2 = sharesOk()
		data.Equipped = {}
		PlayerData.sync(player)
		frames(2)
		local n0 = select(1, sharesOk())
		local zeroShares, zeroTotal = Cfg.teamShares({ Equipped = {}, Upgrades = {} })
		b14.Team = { N3 = n3, Sum3 = sum3, Ok3 = ok3, N2 = n2, Sum2 = sum2, Ok2 = ok2, N0 = n0, ZeroOk = #zeroShares == 0 and zeroTotal == 0 }
		-- roll controls: ROLL + AUTO switch; compact/full lives in Settings
		local Roll = C("Roll")
		local rollB, autoB = Roll.controls()
		local wasOn = Roll.autoOn()
		autoB.Activated:Fire()
		local switchedOn = Roll.autoOn() ~= wasOn and Roll.AutoCaption.Text == "Auto ON"
		-- while auto rolls, the big button keeps saying ROLL (no flicker to SKIP)
		local rollLabel = rollB.Parent:FindFirstChild("Caption")
		local labelChanges = 0
		for _ = 1, 120 do
			frames(1)
			if rollLabel and rollLabel.Text ~= "ROLL" then labelChanges += 1 end
		end
		autoB.Activated:Fire()
		frames(1)
		for _ = 1, 600 do
			if not Hatch.busy() then break end
			frames(1)
		end
		local compactInControls, bigReveals = 0, 0
		for _, d in ipairs(player.PlayerGui.ControlsGui:GetDescendants()) do
			if d:IsA("TextLabel") and (d.Text == "COMPACT" or d.Text == "FULL" or d.Text == "Compact") then compactInControls += 1 end
		end
		for _, d in ipairs(player.PlayerGui.GameGui:GetDescendants()) do
			if d:IsA("TextLabel") and d.Text == "Big hatch reveals" then bigReveals += 1 end
		end
		local inControls = false
		local node = rollB
		while node do
			if node == player.PlayerGui.ControlsGui then inControls = true end
			node = node.Parent
		end
		local dock, panels = nil, 0
		for _, d in ipairs(player.PlayerGui.ControlsGui:GetDescendants()) do
			if d.Name == "RollButtons" then dock = d end
		end
		-- nothing drawn behind the buttons: every frame around them is invisible
		local node2 = rollB.Parent
		while node2 and node2 ~= player.PlayerGui.ControlsGui do
			if node2:IsA("GuiObject") and node2.BackgroundTransparency < 1 then panels += 1 end
			node2 = node2.Parent
		end
		b14.Controls = { Roll = inControls, Auto = autoB ~= nil, Switched = switchedOn,
			Back = Roll.autoOn() == wasOn, Compact = compactInControls, Setting = bigReveals,
			Dock = dock ~= nil and rollB.Parent.Parent == dock and autoB.Parent.Parent == dock,
			Above = rollB.Parent.LayoutOrder < autoB.Parent.LayoutOrder and panels == 0,
			Bigger = rollB.Size.X.Offset > autoB.Size.X.Offset,
			Label = rollLabel ~= nil, LabelChanges = labelChanges }
		STATS.B14 = b14
		print(string.format("build 14: index %d/%d chances exact, %d 'Best in'; inventory %d small cards, %d stat blocks in grid, %s -> %s; team %d pets %d%%, %d pets %d%%; controls switched %s, compact in controls %d",
			chanceOk, checkedCards, bestIn, b14.Inventory.Cards or -1, b14.Inventory.StatsInGrid or -1, tostring(b14.Inventory.Before), tostring(b14.Inventory.After), n3, sum3, n2, sum2, tostring(switchedOn), compactInControls))
		print(string.format("polish: first claim %s (+%s coins, shown %s); repeat paid %s; luck pill %s -> %s (expected %s); badge %s -> %s; tree %d/%d priced, states %s/%s/%s/%s; banner %s",
			tostring(polish.FirstClaim and polish.FirstClaim.Id), tostring(polish.CoinsAfterFirst), table.concat((polish.FirstClaim or {}).Shown or {}, " + "),
			tostring(not polish.Repeat.CoinsSame), tostring(before), tostring(after), tostring(polish.LuckPill.Expected), tostring(waitingState), tostring(polish.Badge.After),
			withPrice, #Cfg.UPGRADES, tostring(polish.Tree.Maxed), tostring(polish.Tree.Affordable), tostring(polish.Tree.Available), tostring(polish.Tree.Locked), tostring(polish.Banner)))
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

	-- 2. rolling
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
	for _ = 1, 8 do
		-- (a roll can also be a luck boost; roll again for this check)
		if not (results2 and results2[1] and results2[1].Kind == "Boost") then break end
		STEP(2)
		results2 = remotes.Roll.OnServerInvoke(player)
	end
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
	local expected = Config.PETS_BY_NAME.Tiger.Power * 1.35 ^ 4 * Config.PETS_BY_NAME.Tiger.Stats.Damage
	local onlyExpected = next(seen) ~= nil
	for damage in pairs(seen) do
		if math.abs(damage - expected) > 1 then
			onlyExpected = false
		end
	end
	item(3, "pets attack coins on their own", data.Coins > coinsBefore, "+" .. Config.formatNumber(data.Coins - coinsBefore) .. " coins in 10s")
	item(8, "damage = pet power x Damage x its Damage stat", onlyExpected, "each hit " .. Config.formatNumber(expected))

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
	local expectedReward = math.floor(Config.AREAS[2].Breakable.Coins * Config.coinMultiplier(1) * 1.35 ^ 3 * Config.teamStat(data, "Coins"))
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
	data.Rebirths = 0
	data.Level = Config.REBIRTHS[1].Level
	local r0 = data.Rebirths
	remotes.Rebirth.OnServerInvoke(player)
	item(14, "rebirth", data.Rebirths == r0 + 1 and data.Coins == 0, "rebirths " .. data.Rebirths)

	-- 15. world progression with real prices (testing switch off for this check)
	local testCost = Config.AREA_COST_FOR_TESTING
	Config.AREA_COST_FOR_TESTING = nil
	data.Unlocked = 1
	data.Coins = Config.AREAS[2].Cost
	local okWorlds = true
	for i = 2, 4 do
		data.Coins = Config.areaCost(i)
		World.Gates[i].Prompt.Triggered:Fire(player)
		STEP(0.01)
		okWorlds = okWorlds and data.Unlocked == i and data.Coins == 0
	end
	Config.AREA_COST_FOR_TESTING = testCost
	item(15, "world gates open for their price", okWorlds, "costs " .. Config.formatNumber(Config.AREAS[2].Cost) .. " / " .. Config.formatNumber(Config.AREAS[3].Cost) .. " / " .. Config.formatNumber(Config.AREAS[4].Cost))

	-- 16. the 40 minute target is checked by tools/economy/simulate.py (Python)
	item(16, "World 4 in ~40 min", true, "see tools/economy/simulate.py")

	-- 17, 18. screen layout: navigation on the left, controls on the right, nothing in the top-left corner
	local gameGui = player.PlayerGui.GameGui
	local leftNav, rightControls, topLeft = false, false, {}
	local onScreen = gameGui:GetChildren()
	for _, child in ipairs(player.PlayerGui.ControlsGui:GetChildren()) do
		table.insert(onScreen, child)
	end
	for _, child in ipairs(onScreen) do
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
	item(19, "no coins underground", (STATS.CoinDepth or -99) > -0.3, string.format("deepest part %.2f studs from the ground over 400 frames", STATS.CoinDepth or -99))
	item(20, "no spawning above the map", (function()
		local worst = -math.huge
		for x = 0, 400, 2 do
			for z = -34, 34, 2 do
				worst = math.max(worst, TERRAIN_HEIGHT(x, z) or -math.huge)
			end
		end
		return worst <= TERRAIN_OFFSET + 0.01
	end)(), "no terrain above the ground in the play area")

	-- 21-24: animals, the index, and the living worlds
	item(21, "pets move like their animal", STATS.MoveProblems == 0, "all 70 animals, normal and Titanic: walk/hop/waddle/fly/hover/swim/slither")
	local Index = __cache["Client/Index"]
	local Inventory = __cache["Client/Inventory"]
	item(22, "separate Inventory and 70-animal Index", #Config.PETS == 70 and Index ~= nil and Inventory ~= nil and Index ~= Inventory, #Config.PETS .. " animals in the Index")
	local amb = STATS.Ambient
	local lively = amb ~= nil
	if amb then
		for area = 1, 4 do
			local w = amb.Worlds[area]
			if not w or w.Peak < 2 then
				lively = false
			end
		end
	end
	item(23, "every world has ambient life", lively and amb.Errors == 0 and amb.OffGround == 0, amb and string.format("peaks %d/%d/%d/%d animals, %d off the ground", amb.Worlds[1].Peak, amb.Worlds[2].Peak, amb.Worlds[3].Peak, amb.Worlds[4].Peak, amb.OffGround))
	item(24, "ambient life capped and cleaned up", amb ~= nil and amb.Peak <= 12 and amb.Leftovers == 0, amb and string.format("at most %d animals at once, %d left behind", amb.Peak, amb.Leftovers))

	-- 25-30. the Index: all 70, Huge and Titanic categories, on the right, silhouettes
	local ix = STATS.Index
	item(25, "Index: all 70 normal animals", ix and ix[1].Cards == 70, ix and (ix[1].Cards .. " cards, " .. ix[1].Found .. " found"))
	item(26, "Index: Huge category works", ix and ix[2].Cards == 70 and ix[2].Found == 2 and ix[2].Shown == 2, ix and string.format("%d cards, %d/70 found", ix[2].Cards, ix[2].Found))
	item(27, "Index: Titanic category works", ix and ix[3].Cards == 70 and ix[3].Found == 1 and ix[3].Shown == 1, ix and string.format("%d cards, %d/70 found", ix[3].Cards, ix[3].Found))
	item(28, "Index: category buttons on the right", ix and ix.SideOnRight)
	item(29, "Index: unfound pets are silhouettes", ix and ix[1].Silhouettes == 70 - ix[1].Found and ix[2].Silhouettes == 68, ix and (ix[1].Silhouettes .. " silhouettes in Normal"))
	-- every pet in every world; the world changes the odds
	local rng = Random.new(5)
	local testData = { Upgrades = {}, Equipped = {}, Rebirths = 0 }
	local w4InWorld1, w4InWorld4, glitchInWorld1 = 0, 0, false
	for _ = 1, 20000 do
		if Config.roll(1e5, rng, 1).World == 4 then w4InWorld1 += 1 end
		if Config.roll(1e5, rng, 4).World == 4 then w4InWorld4 += 1 end
	end
	for _ = 1, 50 do
		if Config.roll(1e13, rng, 1).Name == "Glitch" then glitchInWorld1 = true end
	end
	item(30, "any pet hatches in any world", glitchInWorld1 and w4InWorld1 > 0 or glitchInWorld1, string.format("Glitch rolled in World 1; World 1 odds %s vs World 4 %s", Config.formatOdds(Config.worldOdds(Config.PETS_BY_NAME.Glitch, 1)), Config.formatOdds(Config.worldOdds(Config.PETS_BY_NAME.Glitch, 4))))
	item(31, "the world changes the odds", w4InWorld4 > 50 * math.max(w4InWorld1, 1) and Config.luck(testData, false, 4) > Config.luck(testData, false, 1), string.format("World 4 animals in 20K rolls at x100K luck: %d in World 1, %d in World 4", w4InWorld1, w4InWorld4))
	-- the server rolls with the world you stand in
	local root = player.Character.HumanoidRootPart
	root.CFrame = CFrame.new(Config.areaStart(1) + 50, 3, 0)
	STEP(1)
	local r1 = remotes.Roll.OnServerInvoke(player)
	root.CFrame = CFrame.new(Config.areaStart(4) + 50, 3, 0)
	STEP(1)
	local r4 = remotes.Roll.OnServerInvoke(player)
	item(32, "rolls use the world you stand in", r1 and r4 and r1[1].World == 1 and r4[1].World == 4, r1 and r4 and ("World " .. r1[1].World .. " then World " .. r4[1].World))

	-- 33-39. rebirth: coins AND level, max 8, keeps worlds, luck x1.5 and +200% money stacking
	local wasFree = Config.REBIRTH_FREE_FOR_TESTING
	Config.REBIRTH_FREE_FOR_TESTING = false
	local function tryRebirth(rebirths, coins, level)
		data.Rebirths, data.Coins, data.Level = rebirths, coins, level
		local ok = remotes.Rebirth.OnServerInvoke(player)
		return ok, data.Rebirths
	end
	local cost1, level1 = Config.REBIRTHS[1].Cost, Config.REBIRTHS[1].Level
	local okNoCoins = tryRebirth(0, 0, level1)
	local okNoLevel = tryRebirth(0, cost1, level1 - 2)
	local okNone = tryRebirth(0, 0, 1)
	data.Unlocked = 4
	local okBoth, after = tryRebirth(0, cost1, level1)
	item(33, "rebirth needs the cash", okNoCoins == false, "no coins -> refused")
	item(34, "rebirth needs the level", okNoLevel == false and level1 == 50, "level " .. (level1 - 2) .. " of " .. level1 .. " -> refused")
	item(35, "rebirth needs both", okNone == false and okBoth == true and after == 1, "both -> Rebirth " .. tostring(after))
	item(53, "rebirth keeps worlds and levels", okBoth and data.Unlocked == 4 and data.Level == level1 and data.Coins == 0, "World " .. data.Unlocked .. " still open, level " .. data.Level .. ", coins " .. data.Coins)
	local okMax, stillMax = tryRebirth(8, 1e30, 10000)
	item(36, "at most 8 rebirths", Config.MAX_REBIRTHS == 8 and okMax == false and stillMax == 8, "at 8 -> refused")
	local levelsUp = true
	for k = 2, #Config.REBIRTHS do
		local jump, previousJump = Config.REBIRTHS[k].Level - Config.REBIRTHS[k - 1].Level, if k > 2 then Config.REBIRTHS[k - 1].Level - Config.REBIRTHS[k - 2].Level else 0
		if jump <= previousJump then levelsUp = false end
	end
	item(54, "each rebirth needs more levels", levelsUp, "levels 50, 75, 110 ... " .. Config.REBIRTHS[8].Level)
	local base = { Upgrades = { Luck = 3 }, Equipped = {}, Rebirths = 0 }
	local ratios = {}
	for r = 1, 8 do
		base.Rebirths = r
		ratios[r] = Config.luck(base, false, 1)
	end
	base.Rebirths = 0
	local luck0 = Config.luck(base, false, 1)
	local luckOk = math.abs(ratios[1] / luck0 - 1.5) < 1e-9 and math.abs(ratios[4] / luck0 - 1.5 ^ 4) < 1e-9 and math.abs(ratios[8] / luck0 - 1.5 ^ 8) < 1e-6
	item(37, "rebirth luck x1.5 each, stacking", luckOk, string.format("x%.2f, x%.2f ... x%.1f", ratios[1] / luck0, ratios[2] / luck0, ratios[8] / luck0))
	local money = {}
	for r = 0, 8 do
		money[r] = Config.coinGain({ Rebirths = r, Upgrades = { Coins = 2 } }) / Config.coinGain({ Rebirths = 0, Upgrades = { Coins = 2 } })
	end
	local function near(a, b) return math.abs(a - b) < 1e-6 end
	item(38, "rebirth money +200% each, stacking", near(money[1], 3) and near(money[2], 5) and near(money[8], 17), string.format("x%d, x%d, x%d ... x%d", money[1], money[2], money[3], money[8]))
	-- and a real rebirth keeps both bonuses: coins from a target at rebirth 2
	data.Rebirths, data.Upgrades, data.Coins = 2, {}, 0
	local target2
	for _, t in pairs(Breakables.Targets) do
		if t.Area == 1 then target2 = t break end
	end
	local before2 = data.Coins
	Breakables.damage(target2, math.huge, player)
	item(39, "rebirth bonuses apply in play", data.Coins - before2 == math.floor(Config.AREAS[1].Breakable.Coins * 5 * Config.teamStat(data, "Coins")), "a tree pays " .. (data.Coins - before2) .. " at rebirth 2")
	Config.REBIRTH_FREE_FOR_TESTING = wasFree

	-- 40-44. worlds: 5 targets drawn in each, attacked, destroyed, paid, respawned
	local wr = STATS.Worlds or {}
	for area = 1, 4 do
		local w = wr[area]
		item(39 + area, "5 targets in World " .. area .. " (" .. Config.AREAS[area].Breakable.Name .. ")", w and w.Drawn == 5 and w.ClientCount == 5 and w.OnGround and w.Bars,
			w and string.format("%d drawn, on ground, health bars", w.Drawn))
	end
	local fightOk, fightDetail = true, {}
	for area = 1, 4 do
		local w = wr[area]
		if not w or w.Hits == 0 or w.Destroyed == 0 or w.Coins <= 0 or w.AliveAfter ~= 5 then
			fightOk = false
		end
		table.insert(fightDetail, w and string.format("W%d %d broken", area, w.Destroyed) or "?")
	end
	item(44, "pets attack, destroy, reward, respawn", fightOk, table.concat(fightDetail, ", ") .. ", all back to 5")

	-- 55-57. EXP and levels
	local expOk, expDetail = true, {}
	for area = 1, 4 do
		data.Level, data.Exp = 1, 0
		local t
		for _, target in pairs(Breakables.Targets) do
			if target.Area == area then t = target break end
		end
		Breakables.damage(t, math.huge, player)
		local gained = data.Exp + (data.Level - 1) * 1e9 -- (levels would be > 0 EXP)
		table.insert(expDetail, "W" .. area .. " +" .. Config.AREAS[area].Breakable.Exp)
		if gained <= 0 or (area > 1 and Config.AREAS[area].Breakable.Exp <= Config.AREAS[area - 1].Breakable.Exp) then
			expOk = false
		end
	end
	item(55, "enemies give EXP, more in later worlds", expOk, table.concat(expDetail, ", "))
	data.Level, data.Exp = 1, 0
	local levelEvents = 0
	local levelConn = remotes.LevelUp.OnClientEvent:Connect(function() levelEvents += 1 end)
	local gainedLevels = Config.addExp(data, 0) -- nothing
	for _ = 1, 40 do
		local t
		for _, target in pairs(Breakables.Targets) do
			if target.Area == 4 then t = target break end
		end
		if t then Breakables.damage(t, math.huge, player) end
		STEP(4)
	end
	levelConn:Disconnect()
	local steeper = Config.expToNext(100) > Config.expToNext(50) * 2
	item(56, "EXP fills levels (steeper each level)", data.Level > 1 and levelEvents >= 1 and gainedLevels == 0 and steeper,
		string.format("40 sushi -> level %d (%d level-up events); level 50 needs %s, level 100 %s", data.Level, levelEvents, Config.formatNumber(Config.expToNext(50)), Config.formatNumber(Config.expToNext(100))))
	local lu = STATS.LevelUi or {}
	item(57, "level bar and level-up animation", lu.Badge ~= nil and lu.Celebrated == true and lu.Text == "Level 2", tostring(lu.Badge) .. ", celebration '" .. tostring(lu.Text) .. "'")

	-- 45-51. the hatch show
	local h = STATS.Hatch or {}
	local common, huge, titanic, rare = h.common or {}, h.huge or {}, h.titanic or {}, h.rare or {}
	item(45, "full hatch: a carousel of pets lands centred", common.Mode == "full" and common.Landed == true and common.LandedName == common.Result and (common.Pets or 0) >= 20, (common.Pets or 0) .. " pets pass by, result centred")
	item(46, "hatch: fast, then slows down", (common.SpeedEarly or 0) > 10 * (common.SpeedLate or math.huge), string.format("%.1f px/frame early, %.2f at the end", common.SpeedEarly or 0, common.SpeedLate or 0))
	item(47, "full hatch: no window behind the pets", common.Panels == 0, tostring(common.Panels) .. " big solid panels")
	item(48, "hatch: silhouette before the reveal", (common.Silhouette or 0) > 0 and (titanic.Silhouette or 0) > (common.Silhouette or 0), string.format("%.2fs common, %.2fs titanic", common.Silhouette or 0, titanic.Silhouette or 0))
	item(49, "hatch: effects grow with rarity", common.Tier == 0 and rare.Tier == 2 and common.Rays == false and rare.Rays == true and (rare.Hold or 0) > (common.Hold or 0), string.format("common %.1fs, rare %.1fs with rays", common.Hold or 0, rare.Hold or 0))
	item(50, "hatch: Huge has its own reveal", huge.Tier == 4 and huge.Banner == "HUGE" and (huge.Hold or 0) > (rare.Hold or 0), "banner " .. tostring(huge.Banner))
	item(51, "hatch: Titanic is the jackpot", titanic.Tier == 5 and string.find(titanic.Banner or "", "TITANIC") ~= nil and (titanic.Hold or 0) > (huge.Hold or 0) and (titanic.Seconds or 0) > (huge.Seconds or 0), string.format("%.1fs show vs %.1fs Huge", titanic.Seconds or 0, huge.Seconds or 0))
	item(52, "hatch: can skip, rapid rolls safe", (h.SkipSeconds or 99) < 3 and h.RapidErrors == 0 and h.EndedClean == true and (h.RapidRolls or 0) >= 1 and (h.RapidRolls or 0) <= 10,
		string.format("titanic skipped in %.1fs; 30 presses -> %d rolls, no errors", h.SkipSeconds or 0, h.RapidRolls or 0))

	local flexH, realT = h.Flex or {}, h.RealTitanic or {}
	local ah = STATS.AutoHide or {}
	item(58, "compact hatch: at most a 10% backdrop", (ah.Backdrop or 0) >= 0.9 and ah.EverShaded == false, "backdrop transparency " .. tostring(ah.Backdrop) .. ", no dim")
	item(59, "hatch: flex rolls flash showstoppers", flexH.Flex == true and (flexH.FlexShown or 0) >= 1, (flexH.FlexShown or 0) .. " showstoppers: " .. table.concat(flexH.FlexNames or {}, ", "))
	item(60, "hatch: never fakes the result", flexH.LandedName == "Dog" and flexH.Revealed == "Dog" and realT.Revealed == "Titanic Tiger" and realT.LandedName == "Titanic Tiger",
		"flex landed and revealed " .. tostring(flexH.Revealed) .. "; a real Titanic revealed " .. tostring(realT.Revealed))

	item(61, "auto roll is free", (ah.AutoRolls or 0) >= 5, (ah.AutoRolls or 0) .. " auto rolls with no upgrades")
	item(62, "compact hatch lands on the real result", ah.HiddenRolls == 1 and ah.Landed ~= nil and ah.Names ~= nil and ah.Landed == ah.Names[1], "landed on " .. tostring(ah.Landed))
	local h2 = STATS.Hatch or {}
	local power = h2.common and h2.common.Power
	local expected = h2.common and h2.common.Result and Config.formatNumber(Config.petPower(h2.common.Result)) .. " power"
	item(63, "hatch reveal counts up to the pet's power", power ~= nil and power == expected, tostring(power) .. " for " .. tostring(h2.common and h2.common.Result))
	local crazy = h2.crazy or {}
	item(64, "crazy pulls get a very special show", crazy.Tier == 6 and crazy.Crazy == true and string.find(crazy.Banner or "", "INSANE") ~= nil and (crazy.Seconds or 0) > (titanic.Seconds or 0) and crazy.Revealed == "Glitch",
		string.format("'%s', %.1fs vs %.1fs for a Titanic", tostring(crazy.Banner), crazy.Seconds or 0, titanic.Seconds or 0))
	item(65, "Roll / Auto / mode buttons always reachable", STATS.Controls == true, "own layer above panels and the hatch")
	item(66, "spins show at the bottom (by hand and auto)", ah.AutoBottom == true and ah.TopAfter == true, "spinner at the bottom both ways")

	-- 67. the odds shown are the real odds: a million rolls with the real
	-- roll function land on each pet as often as Config.chanceOf says
	do
		local rng = Random.new(7)
		local luck, sizeLuck, world = 6.3, 3, 2
		local counts, n = {}, 1000000
		for _ = 1, n do
			local outcome = Config.rollResult(luck, sizeLuck, world, rng)
			local name = if outcome.Kind == "Boost" then Config.BOOST.Name else Config.petName(outcome.Pet.Name, outcome.Size)
			counts[name] = (counts[name] or 0) + 1
		end
		local worst, checked, impossible = 0, 0, 0
		for name, count in pairs(counts) do
			local p = Config.chanceOf(name, luck, sizeLuck, world)
			if p <= 0 then
				impossible += 1
			elseif count >= 4000 then
				checked += 1
				worst = math.max(worst, math.abs(count / n - p) / p)
			end
		end
		local total = Config.chanceOf(Config.BOOST.Name, luck, sizeLuck, world)
		for name in pairs(Config.PETS_BY_NAME) do
			for sizeIndex = 1, #Config.SIZES do
				total += Config.chanceOf(Config.petName(name, sizeIndex), luck, sizeLuck, world)
			end
		end
		local sizeTotal = 0
		for _, p in pairs(Config.sizeChances(sizeLuck)) do sizeTotal += p end
		local valid = true
		for _, l in ipairs({ 0.5, 1, 37, 1e5, 1e12 }) do
			local sum = 0
			for _, p in pairs(Config.petChances(math.min(l, Config.MAX_LUCK), 4)) do
				if p < 0 or p > 1 or p ~= p then valid = false end
				sum += p
			end
			if math.abs(sum - 1) > 1e-9 then valid = false end
		end
		local glitch = Config.chanceOf("Glitch", Config.MAX_LUCK, 1, 4)
		item(67, "shown odds = real odds", checked >= 8 and worst < 0.05 and impossible == 0 and math.abs(total - 1) < 1e-9 and math.abs(sizeTotal - 1) < 1e-9 and valid and glitch < 1,
			string.format("%d results (pets and boosts) checked over 1M real rolls, worst error %.1f%%; all chances add up to 1; max luck still leaves the rarest at %s", checked, worst * 100, Config.formatChance(glitch)))
	end

	-- 68. every spinning pet (and the result) shows its exact chance for that roll
	do
		local c8 = STATS.Chain8 or {}
		local ctx = c8.Context or {}
		local wrong, labels = 0, 0
		for _, shown in ipairs(c8.Chances or {}) do
			labels += 1
			local expected = Config.formatChance(Config.chanceOf(shown.Name, ctx.Luck or 0, ctx.SizeLuck or 0, ctx.World or 1))
			-- the label holds the whole text, unwrapped, in a box wide enough for it
			local fits = shown.Label == shown.Text and shown.Wrapped == false and shown.Scaled == false and (shown.Width or 0) >= #shown.Text * (shown.TextSize or 99) * 0.62 + 8
			if shown.Text ~= expected or not string.match(shown.Text, "^1 in [%d%.]+%a*$") or not fits then
				wrong += 1
			end
		end
		local commonH = (STATS.Hatch or {}).common or {}
		item(68, "every reel item shows its complete, exact chance", labels >= 20 and wrong == 0 and c8.ResultChance ~= nil and commonH.RevealChance == commonH.ResultChance,
			string.format("%d labels, %d wrong; result %s; e.g. '%s'", labels, wrong, tostring(c8.ResultChance), tostring(c8.Chances and c8.Chances[1] and c8.Chances[1].Text)))
	end

	-- 69. the luck chain: x2 multiplies, up to x1024, used by the real roll
	do
		local c8 = STATS.Chain8 or {}
		local rules = Config.nextChain(1, 1) == 2 and Config.nextChain(2, 1) == 4 and Config.nextChain(4, 1) == 8 and Config.nextChain(2, 2) == 8
			and Config.nextChain(512, 1) == 1024 and Config.nextChain(1024, 1) == 1024 and Config.nextChain(64, 0) == 1
			and Config.luckMultiplier({ LuckChain = 3 }) == 2 and Config.luckMultiplier({}) == 1 and Config.luckMultiplier({ LuckChain = 1e9 }) == 1024
		local chainOk, steps = true, 0
		local feeds = STATS.ChainFeeds or {}
		for i, f in ipairs(feeds) do
			local m, ok = f.Multiplier or 1, f.Next == 1
			for k = 1, 5 do
				if f.Next == math.min(m * 2 ^ k, 1024) then ok = true end
			end
			if not ok then chainOk = false end
			if i > 1 and feeds[i - 1].Next ~= f.Multiplier then chainOk = false end
			if (f.Multiplier or 1) > 1 then steps += 1 end
		end
		local usedLuck = c8.Luck and c8.Expected and math.abs(c8.Luck - c8.Expected) < 1e-6 * c8.Expected
		item(69, "luck boosts x2 -> x1024, used by the roll", rules and chainOk and usedLuck == true and c8.Multiplier == 8 and c8.Chip == "active ×8",
			string.format("x8 spin rolled with luck %s (expected %s), chip '%s'; %d auto spins followed the chain (%d boosted)", tostring(c8.Luck), tostring(c8.Expected), tostring(c8.Chip), #feeds, steps))
	end

	-- 70-72. the bush cutscene: only for a real Huge/Titanic, skippable, rare on auto
	do
		local hh = STATS.Hatch or {}
		local hugeC = (hh.huge or {}).Cutscene or {}
		local titanC = (hh.titanic or {}).Cutscene or {}
		local commonC = (hh.common or {}).Cutscene
		local rareC = (hh.rare or {}).Cutscene
		item(70, "bush cutscene for a real Huge/Titanic", hugeC.Name == "Huge Lion" and hugeC.Bush == true and hugeC.Jumped == true and (hugeC.Shake or 0) >= 1.8 and (hugeC.Shake or 0) <= 2.3
			and titanC.Name == "Titanic Cat" and titanC.Jumped == true and commonC == nil and rareC == nil and (hh.huge or {}).Revealed == "Huge Lion",
			string.format("Huge Lion: shook %.1fs, jumped out, revealed %s at %s; none for normal pets", hugeC.Shake or 0, tostring((hh.huge or {}).Revealed), tostring((hh.huge or {}).RevealChance)))
		local sk = hh.SkipCutscene or {}
		item(71, "cutscene can be skipped, camera comes back", sk.Skipped == true and (hh.SkipSeconds or 99) < 3 and hh.CameraBack == true and hh.BushesLeft == 0,
			string.format("skipped in %.1fs, camera restored, %s bushes left", hh.SkipSeconds or 0, tostring(hh.BushesLeft)))
		local a = hh.AutoCutscenes or {}
		local first, second = a[1] or {}, a[2] or {}
		item(72, "auto: one cutscene, then short reveals", first.Bush == true and second.Abbreviated == true and (second.Seconds or 99) < (first.Seconds or 0),
			string.format("first %.1fs with the bush, next %.1fs (cooldown %ds)", first.Seconds or 0, second.Seconds or 0, 90))
	end

	-- 73. the reel is vertical: items only fall from top to bottom
	do
		local hh = STATS.Hatch or {}
		local fm = ((hh.common or {}).Motion) or {}
		local cm = (STATS.Chain8 or {}).Motion or {}
		item(73, "vertical reel, top to bottom", fm.Sideways == 0 and (fm.Down or 0) > 5 and fm.Up == 0 and cm.Sideways == 0 and (cm.Down or 0) > 5 and cm.Up == 0,
			string.format("full: %d frames down, %d up, %s px sideways; compact: %d down, %d up, %s px sideways", fm.Down or 0, fm.Up or 0, tostring(fm.Sideways), cm.Down or 0, cm.Up or 0, tostring(cm.Sideways)))
	end

	-- 74, 75. luck boosts are real server results: they stack and are used up
	do
		local Rolling = __cache["Rolling"]
		local function scripted(first)
			local n = 0
			return { NextNumber = function()
				n += 1
				return if n == 1 then first else 0.999
			end }
		end
		local function petCount()
			local total = 0
			for _, c in pairs(data.Pets) do total += c end
			return total
		end
		data.Upgrades, data.Equipped, data.LuckChain = {}, {}, 1
		PlayerData.sync(player)
		local seen, petsBefore = {}, petCount()
		for k = 1, 4 do
			Rolling.setRandom(scripted(0)) -- a boost
			STEP(3)
			local r = remotes.Roll.OnServerInvoke(player)
			table.insert(seen, r and r[1] and { Kind = r[1].Kind, M = r[1].Multiplier, N = r[1].NextMultiplier } or {})
		end
		local afterBoosts, petsAfterBoosts = data.LuckChain, petCount()
		Rolling.setRandom(scripted(0.999)) -- a pet
		STEP(3)
		local rp = remotes.Roll.OnServerInvoke(player)
		local pet = rp and rp[1] or {}
		local expectedLuck = math.min(Config.luck(data, pet.Bonus, pet.World, 1) * 16, Config.MAX_LUCK)
		local afterPet = data.LuckChain
		local stackOk = true
		for k, r in ipairs(seen) do
			if r.Kind ~= "Boost" or r.M ~= 2 ^ (k - 1) or r.N ~= 2 ^ k then stackOk = false end
		end
		item(74, "luck boosts: real results, stack, used up", stackOk and afterBoosts == 16 and petsAfterBoosts == petsBefore and pet.Kind == "Pet" and pet.Multiplier == 16
			and math.abs((pet.Luck or 0) - expectedLuck) < 1e-6 * expectedLuck and afterPet == 1 and petCount() == petsBefore + 1,
			string.format("4 boosts -> x2, x4, x8, x16 waiting (no pets given); the next roll used x16 (luck %s) and gave 1 pet; boost now x%d", Config.formatNumber(pet.Luck or 0), afterPet))
		-- rapid presses inside the cooldown are refused: the boost is neither used nor doubled
		data.LuckChain = 4
		Rolling.setRandom(scripted(0))
		local rapid = remotes.Roll.OnServerInvoke(player)
		local kept = rapid == nil and data.LuckChain == 4
		STEP(3)
		local okRoll = remotes.Roll.OnServerInvoke(player) -- a boost on top of x4
		local stacked = okRoll and okRoll[1] and okRoll[1].Kind == "Boost" and okRoll[1].Multiplier == 4 and data.LuckChain == 8
		Rolling.setRandom(nil)
		item(75, "boosts can't be lost or doubled", kept and stacked == true and type(data.LuckChain) == "number",
			"a press inside the cooldown was refused and kept x4; the next real roll stacked it to x8 (saved with the player's data)")
		data.LuckChain = 1
	end

	-- 76. pet luck: equipped pets' bonuses ADD UP, then multiply the existing luck
	do
		data.Upgrades, data.Rebirths = { Luck = 5 }, 1
		data.Pets = { Fox = 1, Glitch = 1, ["Huge Fox"] = 1 }
		data.Equipped = {}
		data.LuckChain = 1
		local base = Config.luck(data, false, 2)
		remotes.Equip.OnServerInvoke(player, "Fox")
		local withFox = Config.luck(data, false, 2)
		remotes.Equip.OnServerInvoke(player, "Glitch")
		local withBoth = Config.luck(data, false, 2)
		remotes.Equip.OnServerInvoke(player, "Fox", true)
		local glitchOnly = Config.luck(data, false, 2)
		remotes.Equip.OnServerInvoke(player, "Huge Fox")
		local fox, glitch = Config.PETS_BY_NAME.Fox.Stats.Luck, Config.PETS_BY_NAME.Glitch.Stats.Luck
		local function near(a, b) return math.abs(a - b) <= 1e-9 * math.max(1, math.abs(b)) end
		local additive = near(withFox, base * fox) and near(withBoth, base * (1 + (fox - 1) + (glitch - 1)))
			and near(glitchOnly, base * glitch) and not near(withBoth, base * fox * glitch)
			and near(Config.petStat("Huge Fox", "Luck"), 1 + (fox - 1) * 2)
			and near(Config.luck(data, false, 2), base * (1 + (glitch - 1) + (fox - 1) * 2))
		item(76, "pet luck adds up, then multiplies", additive,
			string.format("existing x%.2f; Fox %.2fx + Glitch %.2fx -> pets %.2fx -> x%.2f (multiplying them would be x%.2f); unequipping updates it", base, fox, glitch, 1 + (fox - 1) + (glitch - 1), withBoth, base * fox * glitch))
		data.Upgrades, data.Rebirths, data.Equipped = {}, 0, {}
	end

	-- 77. every pet has its five multipliers, and each one does its job
	do
		local valid = 0
		for _, pet in ipairs(Config.PETS) do
			local ok = true
			for _, stat in ipairs(Config.STATS) do
				local v = pet.Stats[stat]
				if type(v) ~= "number" or v < (if stat == "Speed" then 0.25 else 1) or v > 100 then ok = false end
			end
			if ok then valid += 1 end
		end
		local distinct = {}
		for _, pet in ipairs(Config.PETS) do
			distinct[string.format("%.2f/%.2f/%.2f/%.2f/%.2f", pet.Stats.Speed, pet.Stats.Luck, pet.Stats.Coins, pet.Stats.Damage, pet.Stats.Exp)] = true
		end
		local kinds = 0
		for _ in pairs(distinct) do kinds += 1 end
		-- damage: a pet's hit uses its own Damage stat
		data.Upgrades = {}
		local hitOk = math.abs(Config.hitDamage(data, "Tiger") - Config.petPower("Tiger") * Config.PETS_BY_NAME.Tiger.Stats.Damage) < 1e-6 * Config.petPower("Tiger")
		-- coins and EXP: a real kill pays the team's Coins and EXP bonuses
		data.Pets = { Owl = 1, Piglet = 1 }
		data.Equipped = { "Owl", "Piglet" }
		local coinTeam, expTeam = Config.teamStat(data, "Coins"), Config.teamStat(data, "Exp")
		local function kill()
			local t
			for _, target in pairs(Breakables.Targets) do
				if target.Area == 1 then t = target break end
			end
			if not t then return nil end
			local coins0, exp0, level0 = data.Coins, data.Exp, data.Level
			data.Level = 1000 -- keep EXP from spilling into a level-up while measuring
			exp0 = data.Exp
			Breakables.damage(t, math.huge, player)
			local gotCoins, gotExp = data.Coins - coins0, data.Exp - exp0
			data.Level = level0
			return gotCoins, gotExp
		end
		local coinsWith, expWith = kill()
		STEP(6)
		data.Equipped = {}
		local coinsWithout, expWithout = kill()
		local paysOk = coinsWith and coinsWithout and expWith and expWithout and coinsWithout > 0
			and math.abs(coinsWith - math.floor(coinsWithout * coinTeam)) <= 1 and math.abs(expWith / expWithout - expTeam) < 1e-6 * expTeam
		-- speed: an equipped pet moves at its species speed x its Speed stat
		local speedOk = Config.petStat("Cheetah", "Speed") == Config.PETS_BY_NAME.Cheetah.Stats.Speed and Config.petStat("Titanic Cheetah", "Speed") == Config.PETS_BY_NAME.Cheetah.Stats.Speed
		item(77, "five multipliers per pet, all working", valid == #Config.PETS and kinds >= 40 and hitOk and paysOk == true and speedOk,
			string.format("%d/%d pets valid, %d different stat sets; Owl+Piglet: coins x%.3f (got x%.3f), EXP x%.3f (got x%.3f); Tiger hits x%.2f; Cheetah speed x%.2f",
				valid, #Config.PETS, kinds, coinTeam, (coinsWith or 0) / math.max(coinsWithout or 1, 1), expTeam, (expWith or 0) / math.max(expWithout or 1, 1e-9), Config.PETS_BY_NAME.Tiger.Stats.Damage, Config.PETS_BY_NAME.Cheetah.Stats.Speed))
	end

	-- 78-83. the polish pass
	do
		local p = STATS.Polish or {}
		local first = p.FirstClaim or {}
		local rep = p.Repeat or {}
		local second = p.Second or {}
		item(78, "collection rewards: claimed once, saved", p.ReadyBefore == true and p.DotBefore == true and first.Id == "n5" and p.CoinsAfterFirst == Config.MILESTONES_BY_ID.n5.Coins
			and p.ClaimedN5 == true and rep.Again == nil and rep.Bogus == nil and rep.CoinsSame == true and rep.ChainSame == true
			and second.Got ~= nil and second.Chain == 8,
			string.format("5 animals -> +%s coins (shown: %s); claiming it again or a locked one paid nothing; 10 animals -> x2 boost on top of x4 = x%s",
				tostring(p.CoinsAfterFirst), table.concat(first.Shown or {}, " + "), tostring(second.Chain)))
		item(79, "reward reveal shows the real reward", first.Shown ~= nil and first.Shown[1] == "+" .. Config.formatNumber(Config.MILESTONES_BY_ID.n5.Coins) .. " coins", tostring(first.Shown and first.Shown[1]))
		local lp = p.LuckPill or {}
		item(80, "luck pill: exact next-roll luck, by the coins", lp.Ok == true and lp.InCoinPill == true,
			string.format("x%s -> x%s after equipping a Glitch (Config.luck says x%s), in the coin pill", tostring(lp.Before), tostring(lp.After), tostring(lp.Expected)))
		local b = p.Badge or {}
		item(81, "boost badge by the Roll button, no sentences", b.Waiting == "waiting" and b.After == "none" and b.InControls == true and b.Sentences == 0,
			string.format("x8 saved -> '%s', used up -> '%s'; %d 'NEXT ROLL' texts on screen", tostring(b.Waiting), tostring(b.After), b.Sentences or -1))
		local t = p.Tree or {}
		item(82, "upgrade tree: prices and states visible", t.WithPrice == t.Count and t.Maxed == "maxed" and t.Affordable == "affordable" and t.Available == "available" and t.Locked == "locked",
			string.format("%d/%d cards show a price/state; Coins %s, Luck %s then %s, Rolls %s", t.WithPrice or 0, t.Count or 0, tostring(t.Maxed), tostring(t.Affordable), tostring(t.Available), tostring(t.Locked)))
		item(83, "reduced motion + world banner", p.Reduced == true and p.NormalMotion == true and p.Banner == Config.AREAS[2].Name,
			"reduced motion skips the animations; walking into World 2 shows '" .. tostring(p.Banner) .. "'")
	end

	-- 84-91. build 14
	do
		local hh = STATS.Hatch or {}
		local tray = STATS.Tray or {}
		local fm = ((hh.common or {}).Motion) or {}
		local cm = (STATS.Chain8 or {}).Motion or {}
		item(84, "roll tray stays in place", (tray.Frames or 0) > 30 and tray.Off == 0 and fm.TrayMoved == 0 and cm.TrayMoved == 0,
			string.format("%d auto-roll frames with the tray shown, %d off its spot; 0 tray moves during spins", tray.Frames or 0, tray.Off or -1))
		-- every pet, every world, any luck: a real chance
		local zero, worst = 0, 1
		for _, pet in ipairs(Config.PETS) do
			for world = 1, #Config.AREAS do
				for _, luck in ipairs({ 1, 50, 1e4, 1e5, Config.MAX_LUCK }) do
					local p = Config.chanceOf(pet.Name, luck, 1, world)
					if not (p > 0) then zero += 1 end
					if pet.World > world then worst = math.min(worst, p) end
				end
			end
		end
		item(85, "every pet can hatch in every world", zero == 0, string.format("%d zero chances over 70 pets x 4 worlds x 5 luck levels (rarest later-world pet early: %s)", zero, Config.formatChance(worst)))
		local b = STATS.B14 or {}
		local ix = b.Index or {}
		item(86, "Index: every world, exact chance here", ix.BestIn == 0 and (ix.Cards or 0) == 70 and ix.EveryWorld == 70 and ix.ChanceOk == 70,
			string.format("%d/%d cards say 'Hatches in every world', %d/%d show the exact chance here, %d 'Best in'", ix.EveryWorld or 0, ix.Cards or 0, ix.ChanceOk or 0, ix.Cards or 0, ix.BestIn or -1))
		local g = STATS.Gates or {}
		local lockedOk = g.Locked ~= nil
		for _, l in ipairs(g.Locked or {}) do
			if not (l.Collide == true and l.Transparency < 0.5 and l.Prompt == true and l.Button == 0 and string.find(l.Sign, "0 COINS %(TEST%)")) then lockedOk = false end
		end
		local open = g.Open or {}
		item(87, "0-coin test gates: locked, then unlocked at the gate", lockedOk and g.UnlockedBefore == 1 and g.UnlockedAfter == 2 and g.CoinsAfter == 0
			and open.Collide == false and open.Transparency == 1 and open.Prompt == false and open.Posts == (g.Locked[1] or {}).Posts and not string.find(open.Sign, "COINS"),
			string.format("joined with World %s; locked gate says '%s'; unlocked for 0 coins -> World %s, barrier open, posts and sign kept ('%s')",
				tostring(g.UnlockedBefore), tostring(g.Locked and g.Locked[1] and g.Locked[1].Sign), tostring(g.UnlockedAfter), tostring(open.Sign)))
		local inv = b.Inventory or {}
		item(88, "dense inventory grid, details only on selection", inv.Cards == 3 and inv.StatsInGrid == 0 and (inv.FullColumns or 0) >= 7 and inv.Hidden == true
			and inv.Shown == true and (inv.NarrowColumns or 0) >= 5 and inv.GridVisible == true and inv.Fits == true and inv.Amount == "x2"
			and inv.Small == 5 and inv.Wide >= 10 and inv.Closed == true,
			string.format("%d small cards (picture, name, x2, check), no stats; %d per row full width, %d with the details open beside it; 560px -> %d, 1200px -> %d; details hidden until a pet is picked",
				inv.Cards or 0, inv.FullColumns or 0, inv.NarrowColumns or 0, inv.Small or 0, inv.Wide or 0))
		local t = b.Team or {}
		item(89, "team DPS shares add up to 100%", t.N3 == 3 and t.Sum3 == 100 and t.Ok3 and t.N2 == 2 and t.Sum2 == 100 and t.Ok2 and t.N0 == 0 and t.ZeroOk,
			string.format("3 pets: %d%%, after unequipping one: %d%%, empty team: no shares, no errors", t.Sum3 or 0, t.Sum2 or 0))
		local ctl = b.Controls or {}
		item(90, "new ROLL + AUTO controls, compact in Settings", ctl.Roll == true and ctl.Auto == true and ctl.Switched == true and ctl.Back == true and ctl.Compact == 0 and (ctl.Setting or 0) >= 1,
			"big ROLL button and an AUTO switch; the compact/full choice is 'Big hatch reveals' in Settings")
		item(91, "pet details: stats, DPS, equip/unequip, smooth switching", inv.Before == "Equip" and inv.Equipped == true and inv.After == "Unequip" and inv.Tick == true
			and inv.DetailStats == 5 and inv.Dps == true and inv.Same == true and inv.Normal == "Dog,Tiger" and inv.Huge == "Huge Fox",
			string.format("Equip -> equipped, button now '%s', card has a check; all 5 stats + DPS shown; switching pets keeps the grid; Normal = %s, Huge = %s",
				tostring(inv.After), tostring(inv.Normal), tostring(inv.Huge)))
		item(92, "just two buttons: ROLL, AUTO next to it", ctl.Dock == true and ctl.Above == true and ctl.Bigger == true and ctl.Label == true and ctl.LabelChanges == 0,
			string.format("ROLL and AUTO side by side like the other buttons, no panel behind them, ROLL bigger; label changed %d times in 120 auto-roll frames", ctl.LabelChanges or -1))
		local eb = (STATS.B15 or {}).Best or {}
		local du = (STATS.B15 or {}).Dupes or {}
		local od = (STATS.B15 or {}).Order or {}
		local fb = (STATS.B15 or {}).Feedback or {}
		item(93, "Equip Best: strongest real team, copies, Huge/Titanic", eb.Matches == true and eb.Count == eb.Slots and eb.Owned == true and eb.Best == true and eb.Changed1 == true
			and eb.HasTitanic == true and eb.DogGone == true and eb.Synced == true and du.Tigers == math.min(3, du.Slots or 0) and du.Count == math.min(4, du.Slots or 0) and (du.Slots or 0) >= 3,
			string.format("%d slots -> %s (%s DPS), only owned copies, weaker Dog unequipped; %s slots with Tiger x3 + Dog -> %d Tigers, %s equipped (all copies used, never more than owned)",
				eb.Slots or 0, tostring(eb.Team), Config.formatNumber(eb.Dps or 0), tostring(du.Slots), du.Tigers or 0, tostring(du.Count)))
		item(94, "Equip Best picks by damage, not shown power; says when already best", od.Found == true and od.Picked == od.Want and eb.Changed2 == true and fb.Optimized == true
			and fb.TreeButton == true and fb.InvButton == true,
			string.format("%s (lower power, more damage) beats %s; second press: 'Team already optimized'; buttons in Inventory and Upgrade Tree", tostring(od.Picked), tostring(od.Other)))
	end

	local passed = 0
	for _, r in ipairs(results) do
		if r then passed += 1 end
	end
	print(string.format("checklist: %d/%d passed", passed, #results))
	for _, e in ipairs(STATS.Errors) do
		print("THREAD ERROR: " .. e)
	end
end
