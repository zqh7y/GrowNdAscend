# Hatch Incremental

A solo pet RNG game on Roblox. Hit **ROLL**, see what pet you get, chase the
rare ones and climb the global **Most Rolls** leaderboard.

## How it plays

**Fight enemies → coins + EXP → level up → hatch pets → stronger team →
upgrades → unlock worlds → rebirth (worlds are kept) → stronger still →
chase Huge and Titanic pets.**

- **Living coins (the enemies):** each world's coins are alive: trees,
  cactuses, ice cubes and sushi with happy faces, 5 in every world at all
  times (a watchdog tops them back up), each with a glowing ring, an outline
  in its world's colour, its name, reward and health bar. Studio's Output
  lists where they are (`[Targets] ...`). They rest, jump, land and rest again (about
  every 3-4 seconds), each world in its own way: trees spring straight up,
  cactuses sway and double-bounce, ice cubes slide and spin, sushi flips.
  Five per area, always on the real ground.
- **Pets fight for you:** equipped pets go after the living coin nearest to
  you, all together, and hit it on their own. Stronger pets (rarer, bigger)
  hit harder. Hits show lunges, flashes and damage numbers; a broken coin
  bursts and its coins fly into your counter. No clicking needed.
- **Rolling:** the Roll button gives a random animal (70 animals, 1 in 2 to
  1 in 10,000,000) and a random **size**: Normal, Huge (1 in 100, 10x power)
  or Titanic (1 in 1,000, 100x power). **Every animal can hatch in every
  world**, but animals from worlds ahead of the one you stand in are 25x
  rarer per world (a World 4 animal in World 1: 15,625x rarer), and each
  world adds luck (x1 / x1.2 / x1.45 / x1.75), so later worlds hatch better.
- **The hatch:** right over the game (only a 10% veil, no window), pets
  stream down from the top of the screen, fast and motion-blurred at first,
  bigger in the middle and fading at the edges, each with a rarity glow and
  a shadow, with sparkles drifting up. It slows down, zooms gently, shakes
  more and more, and stops exactly on your pet, which waits as a glowing
  silhouette before popping out in 3D with its name, rarity, power and size.
  Rare pets get rays and jingles, Huge a gold flash and a "HUGE!" banner,
  and Titanic is an event (the lights go down, a heartbeat rise, then a
  rainbow flash, "TITANIC", rings, confetti, screen shake). About 1 roll in
  30 is a **flex roll**: a Huge, Titanic or Secret flies past on the way
  down with a big label, then the column carries on to your real result
  (it's only a show; you get exactly what you rolled). Click to skip; it's
  quicker after the first few hatches and fastest when auto rolling. The
  reveal stands the pet on a holo pad, sweeps a scan line over it and
  counts its power up; a "SO CLOSE" tag marks a much rarer pet that
  stopped right above yours. Every 10th roll
  has 2x luck. Rare pets and big sizes get a full-screen reveal with rays,
  confetti and a jingle (Titanic: rainbow).
- **Upgrade tree** (the tree button): Coins, Damage, Luck, Roll Speed, Rolls
  at Once, Auto Hatch (auto roll → quick reveals → auto-equip best), Size
  Luck and Pet Slots. Some branches unlock after others.
- **Pets are animals:** every species moves like the real thing. Dogs and
  cats trot with their legs going, bunnies and frogs hop, ducks and penguins
  waddle, birds and dragons fly with flapping wings, fish and whales swim
  through the air, snakes slither, scarabs hover. They follow you at their own
  speed (running to catch up), stay on the ground, and when idle they wag,
  breathe and look around (`Creature.luau`).
- **Inventory and Animal Index:** the Inventory shows the pets you own
  (3D previews, size, rarity, power, amount, equipped) with filters and
  sorting. The Index shows all 70 animals: "X / 70 Animals Discovered",
  NORMAL / HUGE / TITANIC buttons on the right (each with its own count;
  Huge and Titanic don't add to the 70), per-world tabs, silhouettes marked
  ??? for what you haven't found, and each animal's odds where you stand.
- **Living worlds:** birds fly across the sky and land on treetops,
  butterflies and bees visit flowers, wild animals wander and cross the
  paths, leaves and petals fall, flowers and bamboo sway, snow falls and ice
  cracks, sand blows, fireflies glow, and now and then a visitor strolls by
  or stops at the fountain. Each world has its own light. Quiet stretches
  alternate with lively ones, everything is capped, and only the world you're
  in is alive (`Ambient.luau`).
- **Fusion machine** (Sahara): 5 of the same pet → 1 of the next size up.
- **Levels:** every enemy you defeat gives EXP (1 / 4 / 15 / 50 per enemy in
  worlds 1-4). Levels get steeper (8 x level^1.5 EXP each) and never reset.
  The level and an EXP bar sit under your team; levelling up shows a big
  "LEVEL UP!" with sparkles and a jingle.
- **Rebirth (8 levels):** needs the coins AND a level (50, 75, 110, 160, 225,
  310, 425, 575). It's a prestige: only your coins reset; worlds, pets,
  upgrades, the Index and your level stay. Each one gives, forever and
  stacking: **Luck x1.5** and **Money +200%** (rebirth 3 = luck x3.4 and
  coins x7; rebirth 8 = x25.6 and x17).
- **Leaderboards:** Strongest Pet, Playtime and Rebirths in the Forest;
  Most Rolls in the Top panel.

### Progression (balanced with `tools/economy/simulate.py`)

| | Time for an active player |
| --- | --- |
| World 2 (Sahara) | ~25 min |
| World 3 (Frozen Peaks) | ~1.5 h |
| Rebirth 1 (level 50) | ~3 h |
| World 4 (Sakura Jungle) | ~6 h, a real milestone |
| Rebirths 2 / 3 / 4 | ~6 / 8 / 14 h |
| Rebirths 5 / 6 / 7 / 8 | ~28 / 52 / 110 / 230 h |
| Best pet | **Titanic Glitch ~4.8T** |

Enemy health, coin rewards, EXP, upgrade costs, world costs and rebirths
all scale together (`python3 tools/economy/simulate.py 3 --hours 10`).

Pet power follows `1M x (odds / 1000)^1.17` (Dog ~700, Tiger 1M, Glitch ~48B),
Huge is x10 and Titanic x100. Luck, Coins and Damage upgrades multiply
(x1.25 / x1.35 per level), so they matter at every stage.

Adding things later is one row each: a pet in `Config.PETS`, a size in
`Config.SIZES` (Giant, Colossal...), an upgrade branch in `Config.UPGRADES`.

## Screen

Coins at the top with YOUR TEAM (equipped pets and damage per second)
under them, colourful navigation down the left (Inventory, Index, Upgrades,
Rebirth, Settings; the leaderboards live in the Forest), and the Roll and
Auto buttons on the right, so the middle stays clear for the fights. The
top-left corner is left for Roblox's own menu buttons.

Every screen shares one sleek futuristic style: dark glass panels with a
thin neon edge in the screen's colour, a neon line along the top, a faint
tech grid, HUD corner brackets, titles in a wide tech font ("// DATABASE"
over "ANIMAL INDEX"), crisp buttons (cyan -> violet on the main actions,
dark glass with neon edges elsewhere), and pets standing on holo pads. The
upgrade tree is a circuit board: neon traces run from a pulsing core to
dark lens-like nodes with neon rings, level bars, costs, padlocks and MAX
tags, with a detail panel and a pop, sparks and "+1 level" text on every
purchase. The rebirth screen shows REBIRTH X / 8 as a segment bar, what
resets vs what you gain, and both requirements as MET / LOCKED with
progress bars. Above the Roll button a luck meter fills 10 segments
towards the 2x bonus roll. **Auto roll is free.** The eye button hides
the hatch animation: results slide in as small cards at the side (a Huge
or Titanic still flashes). Settings: damage numbers, full hatch
animation, sounds. Sounds use built-in Roblox sounds; swap them in
`Effects.SOUNDS`.

## The map

Four compact areas in a straight line along +X (100 x 70 studs each), with
invisible walls on both sides (|Z| = 37), at both ends and on top. The whole
map is built by `src/server/World` when the server starts, in a bright,
toy-like style: smooth plastic in cheerful colours, with glass and neon
accents (realistic materials are swapped out automatically in `Build.part`).

| Area | What's there | Breakable | Unlock |
| --- | --- | --- | --- |
| 1 Forest | Dirt path through the grass, oaks, birches, fruit trees and poplars (root flares, bent trunks, branches, toon-shaded leaves), flower patches (daisies, tulips, bluebells, sunflowers), berry bushes, mushrooms, fallen logs, mossy rocks, two tiered fountains with water streams, hills with a cottage and a windmill, the 3 leaderboards side by side | Hopping fruit trees (5K HP, 20 coins) | Free |
| 2 Sahara | Oasis with palms and reeds, pyramids with gold capstones and a sphinx, Cleopatra's temple (pylon gate with a winged sun disk, lotus columns, painted friezes, obelisks, fire braziers, guardian sphinxes, her statue), the fusion machine (spinning rings, glowing pipes, hopper, output pad, console with a screen), a camel, pottery, Western Wall-style walls with raised stone faces | Saguaro, barrel and prickly pear cactuses (60M HP, 400 coins) | 4K |
| 3 Frozen Peaks | Snow with ice patches, a frozen sea (cracks, fishing holes, pressure ridges, floes, icebergs, penguins), a snow-brick igloo, a snowman and a sled, an ice arch with icicles, ice walls, crystal clusters, snow-laden pines, snowy rocks, snowfall | Ice cubes: clear, with a fish, with a gem, stacked (4B HP, 25K coins) | 600K |
| 4 Sakura Jungle | Twisted and weeping cherry trees with falling petals, red maples, bamboo, ferns, hydrangeas and azaleas, stepping-stone path, torii gates, stone lanterns, koi pond with a red arched bridge and a bamboo spout, a five-tier pagoda, Japanese walls with tile roofs and round windows | Sushi with happy faces: salmon, tuna, egg, maki (250B HP, 1.5M coins) | 220M |

The fusion machine shows its state: slow rings when idle, fast rings and
lots of sparkles while fusing (the orb takes the pet's colour and grows), and
a golden beam of light when a huge pet is ready.

**Testing:** rebirths cost no coins (the level is still needed) and every area is open (see CLAUDE.md, restore before release).

## Solo servers

Every player gets their own server, so it plays like an offline game, but
progress saves and the leaderboard is global. After publishing:
**Game Settings → Places → Server Size = 1**. To test saving and the
leaderboard in Studio: **Game Settings → Security → Enable Studio Access to
API Services**.

## Setup (Rojo)

```bash
aftman install          # installs Rojo 7.7.0
rojo serve              # then connect from the Rojo plugin in Studio
```

## Code

| Path | What it does |
| --- | --- |
| `src/shared/Config.luau` | Pets, rarities, sizes, luck, upgrade tree, combat numbers, areas, formatting |
| `src/server/PlayerData.luau` | Loading, saving, playtime, sending state to the client |
| `src/server/World/` | Builds the map: `init` (terrain, walls, gates, spawn), `Build` (helpers), one module per area |
| `src/server/Breakables.luau` | Living coins: spawning, hopping, health, rewards |
| `src/server/Combat.luau` | Pets automatically fighting the nearest living coin |
| `src/server/Rolling.luau` | Rolls (pet + size), equipping, Equip Best |
| `src/server/Upgrades.luau` | Buying upgrade tree levels |
| `src/server/Progress.luau` | Area gates and rebirths |
| `src/server/Fusion.luau` | The fusion machine |
| `src/server/Leaderboards.luau` | The 4 global leaderboards (OrderedDataStores) |
| `src/client/Hud.luau` | Coins, team bar, the icon dock |
| `src/client/Roll.luau`, `Hatch.luau` | Rolling, the luck chip, auto roll; the hatch show |
| `src/client/UpgradeTree.luau` | The upgrade tree screen |
| `src/client/Rebirth.luau` | The rebirth screen |
| `src/client/Inventory.luau`, `Index.luau`, `PetView.luau` | Inventory, Animal Index, 3D pet previews |
| `src/client/Panels.luau` | Fusion, Settings (and the old Top panel) |
| `src/client/Living.luau`, `Pets.luau` | Living coins hopping, pets following and attacking |
| `src/client/Creature.luau` | How every animal moves (walk, hop, waddle, fly, hover, swim, slither) |
| `src/client/Ambient.luau` | Birds, critters, butterflies, visitors, falling leaves, weather, swaying plants, lighting per world |
| `src/client/Effects.luau` | Sounds, damage numbers, flying coins, confetti |
| `src/client/Ui.luau`, `Screen.luau`, `State.luau` | UI kit and icons, panels and toasts, the client's data |
| `src/shared/Coins.luau`, `Build.luau` | Living coin looks and jump styles; model-building helpers |
| `src/client/PetModels.luau` | All 70 species (body, features, movement) and the tech details by rarity |
| `tools/sim/` | Runs the server and client on a fake Roblox and plays through a 63-point checklist |
| `tools/economy/simulate.py` | Simulates players to check the progression targets |
