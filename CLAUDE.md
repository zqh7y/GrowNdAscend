# Hatch Incremental (GrowNdAscend repo)

Solo pet RNG game for Roblox, synced into Studio with Rojo. See README.md
for how it plays and where the code lives.

## ⚠️ BEFORE THE FINAL VERSION

- **BEFORE THE FINAL VERSION: Rebirth is currently free for testing. Restore
  the normal rebirth requirements before releasing the final version of the
  game.** Set `Config.REBIRTH_FREE_FOR_TESTING = false` in
  `src/shared/Config.luau` (the normal cost is 1M coins x (rebirths + 1)).
- **BEFORE THE FINAL VERSION: All areas are currently free and their gates
  are open for testing. Restore the normal area costs (4K / 600K / 220M
  coins) before releasing the final version of the game.** Set
  `Config.AREAS_FREE_FOR_TESTING = false` in `src/shared/Config.luau`.
  Saves made while testing keep every area unlocked, so also reset player
  data (change the DataStore name in `PlayerData.luau`) before release.

## Notes for working on this project

- Check changes by compiling every file with `luau-compile` and running
  `luau-analyze` (only Roblox globals like `game`, `Enum`, `Vector3` should
  come up as unknown).
- `tools/sim` runs the whole server startup (map build, breakables,
  leaderboards, fusion machine) on a small fake Roblox environment, to catch
  runtime errors outside Studio and print part counts per area:
  `python3 tools/sim/bundle.py . && luau tools/sim/run.luau`. It must print
  "server started OK". It checks types and sizes, not how things look.
- The sim also plays as a fake player: rolls, buys upgrades, fuses, opens
  every panel and lets the pets fight. Every step must run without a
  "CLIENT ERROR" or "THREAD ERROR". Extend `tools/sim/harness.luau` when
  adding features.
- The sim ends with a 24-point player checklist (spawning, rolling, pets
  fighting, coin jumps/landings/respawns, rewards, damage, luck, sizes,
  upgrades, rebirth, world gates, screen layout, ground, animal movement,
  Inventory/Index, ambient life and its caps). It must say
  "checklist: 24/24 passed".
- Economy: `python3 tools/economy/simulate.py` simulates active players.
  Targets: World 4 around 40 minutes with ~1B pets; the best pet (Titanic
  Glitch) ~5T and an extreme jackpot. It mirrors the numbers in
  `Config.luau`, so change both together and rerun it.
- Ground: the playable strip is flat terrain at Y = 0 (terrain above it is
  cleared after building). Put things on the ground with
  `World.groundAt`/`World.flatGround`, never an assumed Y.
- Living coins: the server keeps data records only
  (ReplicatedStorage.LivingCoins); the client builds and animates the
  models from `shared/Coins.luau`. Keep it that way so their behaviour
  never depends on streaming or on being attacked.
- The HUD ignores the top bar inset: keep the top-left corner empty
  (Roblox's menu and chat buttons are there).
- Keep the map around 8-9K parts in total (the sim prints the counts).
- Gameplay numbers live in `Config`: add pets to `PETS`, sizes to `SIZES`,
  upgrade branches to `UPGRADES` (the upgrade tree draws itself from it).
  Don't hard-code sizes or upgrade ids elsewhere.
- The server owns positions and health of living coins and all combat;
  the client only animates (Living.luau, Pets.luau) from the coin records
  and the PetHits / CoinPop events.
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
- Animals: every species row lives in `PetModels.SPECIES` (body, features,
  Move and Speed). Movement is `Creature.luau`, shared by pets and wild
  animals; don't add a second follow system. New animals need a species row.
- The Index counts base animals only (70); Huge/Titanic don't count.
  `data.Discovered` is set when an animal is first hatched.
- Ambient life (`Ambient.luau`) is client-only and capped: MAX_ANIMALS,
  per-world caps in `Ambient.WORLDS`, one visitor at a time. Only the
  player's current world is alive; things spawn out of view and are
  removed when far or when the player changes world. Keep it that way for
  performance. Background sound loops per world are empty hooks
  (`Ambient.LOOPS`) for Creator Store ambience ids.
