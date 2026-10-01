# Hatch Incremental (GrowNdAscend repo)

Solo pet RNG game for Roblox, synced into Studio with Rojo. See README.md
for how it plays and where the code lives.

## ⚠️ BEFORE THE FINAL VERSION

- **BEFORE THE FINAL VERSION: Rebirth is currently free for testing. Restore
  the normal rebirth requirements before releasing the final version of the
  game.** Set `Config.REBIRTH_FREE_FOR_TESTING = false` in
  `src/shared/Config.luau`. While it's on, rebirths cost no coins (the
  required level and the max of 8 still apply); the real costs are in
  `Config.REBIRTHS`.
- **BEFORE THE FINAL VERSION: Area unlocks currently cost 0 coins for
  testing (TEMPORARY). Restore the intended coin costs (25K / 12M / 130B,
  in `Config.AREAS[i].Cost`) before releasing the final version of the
  game.** Set `Config.AREA_COST_FOR_TESTING = nil` in
  `src/shared/Config.luau`. The gates, borders, signs ("0 COINS (TEST)")
  and unlock buttons work as normal while testing; you just pay nothing.
- **BEFORE THE FINAL VERSION: every join currently re-locks the areas
  (only World 1 open) so the locked gates can be inspected (TEMPORARY).**
  Set `Config.RELOCK_AREAS_FOR_TESTING = false`. Saves from older test
  builds may have every area unlocked, so also reset player data (change
  the DataStore name in `PlayerData.luau`) before release.

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
- The sim ends with a 94-point player checklist (spawning, rolling, pets
  fighting, levels and EXP, rebirth keeping worlds, the full and compact hatches, flex
  rolls never faking a result, coin jumps/landings/respawns, rewards, damage, luck, sizes,
  upgrades, rebirth, world gates, screen layout, ground, animal movement,
  Inventory/Index and its categories, ambient life, hatching anywhere and
  world odds, every rebirth rule, 5 targets fought in every world, and the
  hatch show step by step, the ROLL + AUTO buttons, the dense inventory with side details
  and Equip Best). It must say "checklist: 94/94 passed". It takes
  a few minutes; run it in the background. The harness runs as one big
  function: wrap new test blocks in `do ... end` or Luau runs out of local
  registers (limit 200).
- Economy: `python3 tools/economy/simulate.py 3 --hours 10` simulates an
  active player (it reads worlds, rebirths, levels and animals from
  Config; only the upgrade tree is mirrored in its UP table). Targets:
  World 2 ~25 min, World 3 ~1.5 h, Rebirth 1 ~3 h, World 4 ~6 h; best pet
  Titanic Glitch ~5T.
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
- Art direction: the world is bright, toy-like and highly detailed
  (`Build.part` turns every material except Glass, Neon and ForceField into
  SmoothPlastic). The UI is clean, minimal and friendly: white rounded
  panels, soft shadows (`Ui.shadow`), whitespace, solid colourful buttons,
  rounded titles (`Ui.FONT_DISPLAY`). No neon, glowing borders, menu
  particles or tech decoration (`Ui.brackets`/`Ui.accentLine` are no-ops).
- Numbers: always `Config.formatNumber` (K, M, B, T, Qd, Qn, Sx ...) for
  coins, power, costs, rewards, damage, EXP, leaderboards. Never print long
  digit strings.
- Pets (`PetModels.luau`) are blocky: build them from `chunk` (rounded
  blocks) and `box`, never balls. Keep the rig contract (Legs/Wings/Tail,
  an accurate FootY) and the rarity/Huge/Titanic accessories in `dress`.
  Friendly, original designs only.
- Targeting: pets only fight enemies in the player's current world
  (`Combat.pickTarget` → `Breakables.near(pos, radius, area)`); the client
  hides other worlds' enemies (`Living.playerArea`). New worlds need nothing
  extra.
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
- Odds: every animal can hatch in every world (`Config.worldOdds`,
  `WORLD_PENALTY` per world ahead, `AREAS[i].Luck`). Never lock an animal
  to a world. The server rolls with the world the player stands in.
- Rebirths: `Config.REBIRTHS` (cost + level per rebirth, 8 of them). A
  rebirth resets coins only: never worlds, pets, upgrades, Index or level.
  Levels: EXP per enemy is `AREAS[i].Breakable.Exp`, the curve is
  `LEVEL_BASE x LEVEL_GROWTH ^ (level - 1)` (10 EXP for level 1 -> 2,
  then 1.1x per level; `Config.addExp`). Luck
  x1.5 and coins +200% per rebirth are computed from the rebirth count
  (`rebirthLuck`, `coinMultiplier`), so they always stack. Rerun
  `simulate.py 0 --rebirth 70` after changing them.
- The hatch (`Hatch.luau`) must never get stuck: it runs protected and
  always cleans up (camera, bush, spinner). Pressing Roll during a hatch
  skips; it never stacks. The server decides every result first and sends
  the exact luck/size luck/world it used; the client only shows it. Each
  roll is a pet or a luck boost (`Config.rollResult`); boosts multiply
  into `data.LuckChain` (`Config.nextChain`), are used up by the next spin,
  and Rolling.luau does it all in one go (no yields). The reel is VERTICAL
  (items fall top to bottom, tested) and always at the bottom (`Hatch.play(results, fast, world, mode,
  auto)`, mode "compact" or "full"). The odds on the pets come from
  `Config.chanceOf`, which follows `Config.rollResult` step by step: change
  one, change the other (the sim checks them against 1M real rolls). The
  boost is applied inside `Config.luck`.
- The hatch reel container (`Hatch.Spinner`) is anchored at one spot and
  must never be moved, resized or tweened during a spin (only the cards
  inside move; the sim checks every frame). An earlier slide-in/out tween
  made it drift and snap when rolls came quickly.
- Odds: every step of a roll hits at most `Config.MAX_HIT` (99%), so every
  animal has a non-zero chance in every world at any luck (tested).
- Roll controls: `Roll.buildControls` makes two `Ui.dockButton`s side by
  side, same style as the left navigation (`Roll.DOCK_SIZE` is the row):
  ROLL slightly bigger, gold with a white ring (ready bar inside, R key,
  caption SKIP during a hand hatch) and AUTO (grey / green, caption
  `Roll.AutoCaption`). Invisible row, no panel. The user wants them like
  the other buttons, only a little special; don't build a panel or dock. While auto rolls the button stays still and says ROLL.
  Compact/full is the "Big hatch reveals" setting (`State.Settings.FullHatch`).
- Inventory: columns come from the width (`Inventory.columnsFor`); the
  details panel only exists while a pet is selected (`Inventory.select`)
  and is filled in place. "Newest" sorts by `data.Obtained[name]` (the roll
  number when it was first hatched, set in Rolling).
- Equip Best: one rule, `Config.bestTeam(data)` (sorted by `Config.petDps`,
  then Luck, then Coins; copies up to min(owned, slots)); the server's
  EquipBest returns { Changed, Added, Equipped }. The client action is
  `Inventory.equipBest()` (toast), used by Inventory and the Upgrade Tree.
- Collection rewards: `Config.MILESTONES` (Size, Count, Coins, Boost); the
  server pays them in `Progress.luau` (ClaimMilestone), marking
  `data.Milestones[id]` first, so each is paid once. Coin amounts are tuned
  with `simulate.py` (it applies them); keep W2/W3/W4 on target.
- Animation: use `Ui.appear`, `Ui.pop`, `Effects.flash` and quick Quint
  easing; check `Ui.reduced()` (Settings → Reduced motion) before
  bounces, shakes or camera moves. The luck pill (Roll.LuckPill) lives in
  the coin pill; the boost badge (Roll.BoostBadge) next to the Roll button
  in `Screen.Controls`. No large text in the middle of the screen.
- Pet stats: every row in `Config.PETS` has `Stats` (Speed, Luck, Coins,
  Damage, Exp). Read them with `Config.petStat(name, stat)` (sizes scale
  the bonus) and `Config.teamStat(data, stat)` (equipped bonuses added up:
  1 + sum of (stat - 1)). Luck = existing luck x teamStat Luck; coins via
  `Config.coinGain`, EXP via `Config.expGain`, damage via
  `Config.hitDamage`, speed in Pets.luau. New pets need a Stats table. Huge/Titanic get the bush cutscene (once per
  `Hatch.CUTSCENE_COOLDOWN` on auto). Flex rolls are visual only.
  The Roll/Auto/mode buttons live in `Screen.Controls`, a ScreenGui above
  everything; keep them there.
- UI style lives in `Ui.luau` (fonts, button styles incl. colours) and
  `Screen.modal(width, height, theme)` (ribbon, border, shadow, blur); new
  screens use those so everything looks the same.
- Every target is logged to Output at start (`[Targets] ...`) and the client
  prints how many it drew; check those first if targets seem missing.
- Pivots: Roblox ignores Model.WorldPivot once a PrimaryPart is set. Use
  `Build.setPivot(model, part, cframe)` to put a model's pivot somewhere.
  Living coins don't use the pivot or Model:ScaleTo at all: Living.luau
  places every part from its measured offset to the feet (BulkMoveTo), so
  they always stand on the ground. At start the client prints the lowest
  part of any target ("[Targets] lowest part ...") to Output; the sim
  checks every part of every coin against the ground.
