# Hatch Incremental (GrowNdAscend repo)

Solo pet RNG game for Roblox, synced into Studio with Rojo. See README.md
for how it plays and where the code lives.

## ⚠️ BEFORE THE FINAL VERSION

- **BEFORE THE FINAL VERSION: Rebirth is currently free for testing. Restore
  the normal rebirth requirements before releasing the final version of the
  game.** Set `Config.REBIRTH_FREE_FOR_TESTING = false` in
  `src/shared/Config.luau` (the normal cost is 1M coins x (rebirths + 1)).

## Notes for working on this project

- Check changes by compiling every file with `luau-compile` and running
  `luau-analyze` (only Roblox globals like `game`, `Enum`, `Vector3` should
  come up as unknown).
- `tools/sim` runs the whole server startup (map build, breakables,
  leaderboards, fusion machine) on a small fake Roblox environment, to catch
  runtime errors outside Studio and print part counts per area:
  `python3 tools/sim/bundle.py . && luau tools/sim/run.luau`. It must print
  "server started OK". It checks types and sizes, not how things look.
- Keep the map around 8-9K parts in total (the sim prints the counts).
- The map is built in code at server start (`src/server/World`). Every area
  is 100 x 70 studs; keep new props inside that footprint.
- Art direction: kid-friendly, bright and highly detailed. `Build.part`
  turns every material except Glass, Neon and ForceField into
  SmoothPlastic, so the whole map stays clean and toy-like.
- No grass pieces on the ground in World 1 (flat or otherwise): the green
  terrain is the grass.
- Areas call `ctx.reserveSpots()` after their big props and before small
  ones (flowers, bushes, rocks), so there's always room for breakables.
- Decorations can spin or bob with `Build.spin` / `Build.bob`; the client
  animates them (`src/client/Motion.luau`).
