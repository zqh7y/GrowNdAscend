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
