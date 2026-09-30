# Hatch Incremental

A solo pet RNG game on Roblox. Hit **ROLL**, see what pet you get, chase the
rare ones and climb the global **Most Rolls** leaderboard.

## How it plays

**Roll pets → build a stronger team → pets fight the living coins on their
own → earn coins → buy upgrades → roll better pets → repeat.**

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
- **The hatch show:** the world darkens and blurs, a strip of pet cards races
  past and slows down onto your pet (shaking harder as it slows), the result
  waits as a glowing silhouette, then pops out in 3D with rays, sparkles, its
  name, rarity, power and size. The show grows with rarity: rare pets get
  rays and a jingle, legendary+ a flash and confetti, Huge a gold flash, a
  "HUGE!" banner and a camera kick, and Titanic a jackpot of its own (dark
  then rainbow flash, rainbow rays and rings, waves of confetti, camera
  shake and zoom). Click to skip; after the first few hatches it's quicker,
  and auto rolling uses a fast version. Pressing Roll during a show skips
  ahead instead of stacking rolls. Every 10th roll
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
- **Rebirth (8 levels):** needs the coins AND a certain animal (any size;
  Lion, Griffin, Polar Bear, Yeti, Frost Dragon, Kitsune, Dragon, Galaxy
  Whale). Each one gives, forever and stacking: **Luck x1.5** and **Money
  +200%** (rebirth 3 = luck x3.4 and coins x7; rebirth 8 = x25.6 and x17).
  You keep pets, upgrades and the Index. In the simulator rebirth 1 comes
  at ~1.6 h, rebirth 4 ~17 h, rebirth 7 ~47 h.
- **Leaderboards:** Strongest Pet, Playtime and Rebirths in the Forest;
  Most Rolls in the Top panel.

### Progression (balanced with `tools/economy/simulate.py`)

| | Time for an active player | Pets |
| --- | --- | --- |
| World 1 (Forest) | 0-7 min | hundreds → millions |
| World 2 (Sahara) | ~7-22 min | millions → hundreds of millions |
| World 3 (Frozen Peaks) | ~22-40 min | hundreds of millions |
| World 4 (Sakura Jungle) | from ~40 min | around 1B |
| Endgame | hours | Huge Glitch ~480B (a few hours maxed); **Titanic Glitch ~4.8T**, about 1 in 1.5M rolls fully maxed |

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

Every screen shares one friendly cartoon style: a round bubbly font, candy
gradient buttons with a dark outline and a shine, panels with a thick white
border, a soft shadow, a coloured title ribbon with an icon, a round close
button, and the world blurred behind. The upgrade tree is a real tree on a
grassy hill (what unlocks what), with big icon nodes, level bars, cost
pills, padlocks and MAX crowns, a detail panel, and a pop, sparkles and
"+1 level" text on every purchase. The rebirth screen shows Rebirth X / 8
with stars, YOU LOSE vs YOU GAIN, and both requirements with ticks (the
animal in 3D). Settings: damage numbers, full hatch animation, sounds. Sounds use built-in Roblox sounds; swap them in
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

**Testing:** rebirths cost no coins (the animal is still needed) and every area is open (see CLAUDE.md, restore before release).

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
| `tools/sim/` | Runs the server and client on a fake Roblox and plays through a 52-point checklist |
| `tools/economy/simulate.py` | Simulates players to check the progression targets |
