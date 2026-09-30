# Usage: python3 tools/sim/bundle.py . && luau tools/sim/run.luau
# Bundles the game's server code into one Luau file that runs on the mock.
import os, sys
root = sys.argv[1]
here = os.path.dirname(os.path.abspath(__file__))
out = [open(os.path.join(here, "mock.luau")).read()]
out.append("local __src = {}\nlocal __cache = {}\n")
mods = {}
def add(key, path):
    src = open(path).read()
    mods[key] = path
    out.append(f"__src[{key!r}] = function(script)\n{src}\nend\n")
add("Config", f"{root}/src/shared/Config.luau")
for f in sorted(os.listdir(f"{root}/src/server")):
    p = f"{root}/src/server/{f}"
    if f.endswith(".luau"):
        add(f.replace(".server.luau", "").replace(".luau", ""), p)
for f in sorted(os.listdir(f"{root}/src/server/World")):
    add("World/" + f.replace(".luau", ""), f"{root}/src/server/World/{f}")
for f in sorted(os.listdir(f"{root}/src/client")):
    if f.endswith(".luau"):
        add("Client/" + f.replace(".client.luau", "").replace(".luau", ""), f"{root}/src/client/{f}")
out.append(r'''
local realRequire = require
function require(m)
	local key = m:GetAttribute("__key")
	assert(key, "require of a non-module: " .. tostring(m.Name))
	if __cache[key] == nil then
		__cache[key] = __src[key](m)
		if __cache[key] == nil then __cache[key] = false end
	end
	return __cache[key]
end
local function module(name, parent, key)
	local m = Instance.new(if key == "init" then "Script" else "ModuleScript")
	m.Name = name
	m.Parent = parent
	m:SetAttribute("__key", key)
	return m
end
local rs = game:GetService("ReplicatedStorage")
local shared = Instance.new("Folder"); shared.Name = "Shared"; shared.Parent = rs
module("Config", shared, "Config")
local sss = game:GetService("ServerScriptService")
local server = module("Server", sss, "init")
''')
for key in mods:
    if key in ("Config", "init"): continue
    if key.startswith("World/") or key.startswith("Client/"):
        continue
    out.append(f'module({key!r}, server, {key!r})\n')
out.append('local world = module("World", server, "World/init")\n')
for key in mods:
    if key.startswith("World/") and key != "World/init":
        out.append(f'module({key[6:]!r}, world, {key!r})\n')
out.append('local client = module("Client", game:GetService("StarterPlayer"), "Client/init")\n')
for key in mods:
    if key.startswith("Client/") and key != "Client/init":
        out.append(f'module({key[7:]!r}, client, {key!r})\n')
out.append(open(os.path.join(here, "harness.luau")).read())
open(os.path.join(here, "run.luau"), "w").write("\n".join(out))
