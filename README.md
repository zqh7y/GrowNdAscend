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
  you in the world you are standing in (never one in another world), all
  together, and hit it on their own. Walk into the next world and they
  switch to its enemies; other worlds' enemies aren't shown. Stronger pets (rarer, bigger)
  hit harder. Hits show lunges, flashes and damage numbers; a broken coin
  bursts and its coins fly into your counter. No clicking needed.
- **Rolling:** the Roll button gives a random animal (70 animals, 1 in 2 to
  1 in 10,000,000) and a random **size**: Normal, Huge (1 in 100, 10x power)
  or Titanic (1 in 1,000, 100x power). **Every animal can hatch in every
  world**, but animals from worlds ahead of the one you stand in are 25x
  rarer per world (a World 4 animal in World 1: 15,625x rarer), and each
  world adds luck (x1 / x1.2 / x1.45 / x1.75), so later worlds hatch better.
- **The hatch** has two modes (the eye button switches them):
  - **Compact** (the default): a small row at the top of the screen, under
    your coins. Pets glide in from the right, the middle one larger, and
    ease to a stop on your pet, which pops with its name and a rarity chip.
    Only a faint pill (10% opacity) sits behind it; the game stays fully
    visible and playable underneath. A Huge or Titanic still gets its big
    reveal.
  - **Full**: the same idea, bigger and centred over a soft dim. A carousel
    of large pets (smaller and fainter towards the sides, soft shadows
    under each) slows down onto your pet, holds a short silhouette, then
    your pet rises large with its name, rarity, odds and its power counting
    up. No windows or boxes: the pets are the show. Effects stay calm and
    grow with rarity: soft sparkles, gentle light rays, a gold glow and
    confetti for Huge, a slow rise with a rainbow glow for Titanic. About 1
    full hatch in 30 is a **flex roll**: a Huge or Titanic slides past the
    middle with a small "Huge Dragon?!" label; it's only a show, the
    carousel always stops on what you actually rolled.

  Click (or press Roll) to skip; hatches get quicker after the first few
  and when auto rolling. Every 10th roll has 2x luck.
- **Upgrade tree** (the tree button): Coins, Damage, Luck, Roll Speed, Rolls
  at Once, Auto Hatch (auto roll → quick reveals → auto-equip best), Size
  Luck and Pet Slots. Some branches unlock after others.
- **Pets are chunky collectibles:** every animal is built from soft
  rounded blocks (a big head on a compact body, short sturdy legs) with its
  own silhouette, ears, tail, markings and face (glossy layered eyes,
  cheeks, a nose and its own mouth); paws have toes and chests layered fur.
  Accessories grow with rarity: a collar with a gold tag, a bandana, an
  adventure satchel, a cape, a gem tag with two gold stars circling, soft
  feathered wings, rainbow trim. Huge pets wear gold (collar, paw cuffs,
  badge, gold sparkles); Titanic pets are collector's trophies with a
  jewelled crown, a gold chest plate with a big gem, a royal ermine cape
  and a warm glow.
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

Every screen shares one clean, friendly style: white rounded panels with
soft shadows and lots of space, a coloured icon tile and a rounded title
on each screen, solid colourful buttons with soft gradients, and no neon,
glow or tech decoration. The upgrade tree shows nodes with level bars,
costs, padlocks and MAX tags, with a detail panel and a pop on every
purchase. The rebirth screen shows REBIRTH X / 8 as a segment bar, what
resets vs what you gain, and both requirements as MET / LOCKED with
progress bars. Under the coins a small chip shows your luck ("Luck x2.50
· 2x in 4"). **Auto roll is free.** Settings: damage numbers, full hatch
animation, sounds. Every number uses one short format everywhere
(`Config.formatNumber`): 1.5K, 2M, 3B, 4T, 5Qd, 6Qn, 7Sx ... never long
digit strings. Sounds use built-in Roblox sounds; swap them in
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
| 2 Sahara | Oasis with palms and reeds, pyramids with gold capstones and a sphinx, Cleopatra's temple (pylon gate with a winged sun disk, lotus columns, painted friezes, obelisks, fire braziers, guardian sphinxes, her statue), the fusion machine (spinning rings, glowing pipes, hopper, output pad, console with a screen), a camel, pottery, Western Wall-style walls with raised stone faces | Saguaro, barrel and prickly pear cactuses (120M HP, 600 coins) | 20K |
| 3 Frozen Peaks | Snow with ice patches, a frozen sea (cracks, fishing holes, pressure ridges, floes, icebergs, penguins), a snow-brick igloo, a snowman and a sled, an ice arch with icicles, ice walls, crystal clusters, snow-laden pines, snowy rocks, snowfall | Ice cubes: clear, with a fish, with a gem, stacked (30B HP, 40K coins) | 6M |
| 4 Sakura Jungle | Twisted and weeping cherry trees with falling petals, red maples, bamboo, ferns, hydrangeas and azaleas, stepping-stone path, torii gates, stone lanterns, koi pond with a red arched bridge and a bamboo spout, a five-tier pagoda, Japanese walls with tile roofs and round windows | Sushi with happy faces: salmon, tuna, egg, maki (12T HP, 3M coins) | 30B |

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
