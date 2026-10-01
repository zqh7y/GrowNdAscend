# Roll Pets RNG

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
- **The hatch:** the server rolls first (each roll is a pet or a luck
  boost, plus the exact luck it used); the screen only shows that result.
  - **The reel** is vertical and sits at the bottom of the screen, by hand
    and on auto: a soft frosted tray (10% opacity), fixed in one spot
    (it never moves during a spin; only the cards inside do), where small
    white cards (the pet on the left, its **complete, exact chance** in a
    pill on the right, e.g. "1 in 12.5K") fall from the top to the bottom
    and ease to a stop on your result. Two little notches on the tray's
    edges mark the middle slot; the card that stops there lifts and takes
    a coloured outline (gold for rare results), then the tray fades away.
    Luck boosts are green cards with a clover. The chances come from the
    same luck, size luck and world the server rolled with
    (`Config.chanceOf`); no rarity names.
  - **Luck boosts** are real results: every roll has a 1 in 12 chance of
    being a **x2 LUCK** instead of a pet. It applies to your next roll and
    is used up by it. Boosts stack by multiplying: hatch x2 → next roll x2;
    hatch another x2 during that roll → next roll x4, then x8, x16 … up to
    x1024. A small clover badge above the Roll, Auto and mode buttons shows it ("×8"):
    filled green while a roll is using it, white with a gold edge while
    it's waiting for your next roll; it pops when it grows and shrinks
    away when it's used up.
  - **Controls:** a big blue **ROLL** button (or the R key) with a slim bar
    that fills while the next roll gets ready, and an **AUTO** on/off button
    (">>" icon) to its left. A hatch can't be skipped. Bigger hatch
    reveals can be turned on in Settings ("Big hatch reveals"). The server keeps the waiting boost in
    your saved data, so rejoining doesn't lose it, and rapid presses can't
    use it twice.
  - **Big hatch reveals** (Settings): a bigger reel with a silhouette moment,
    then a centred reveal where the pet rises large with its name, exact
    chance and power counting up. About 1 full hatch in 30 is a **flex
    roll**: a Huge or Titanic slides past ("Huge Dragon?!"); the reel still
    stops on what you actually rolled.
  - **Huge and Titanic: the bush cutscene.** The camera glides onto a bush
    a little ahead of you, the bush rustles harder and harder for about 2
    seconds, then your pet jumps out towards the screen with light and
    sound, and the reveal shows it with its exact chance. Only for a pet
    you really rolled; it can't be skipped. On auto it plays at
    most once every 90 seconds; in between, a short reveal.
  - **Crazy pulls** (a Mythic or Secret animal) get their own show: dark
    screen, heartbeats with rings of light, rainbow cracks, a flash, then
    "INSANE PULL!".

  The ROLL button and AUTO switch sit on their own layer above
  everything, so they always work. Every 10th roll has 2x luck.
- **Feel:** panels fade and rise in, and ease away on close; cards in the
  Inventory and Index grow in one after another; equipping pops the card
  and a soft poof appears where the pet joins (or leaves) your team; a
  rebirth flashes the screen; walking into another world slides a small
  banner with its name down under the HUD. **Settings → Reduced motion**
  turns off bounces, shakes, camera kicks and most confetti.
- **Every animal hatches in every world**: animals from later worlds are
  much rarer in earlier ones (25x per world ahead) but never impossible,
  and no single step of a roll is ever certain (`Config.MAX_HIT`), so even
  huge luck can't make any animal impossible. Index cards show the exact
  chance of your next roll where you stand and say "Hatches in every
  world".
- **Inventory (My Pets):** a dense collection grid of small cards (about
  5-8 per row, worked out from the space available): the pet, its name, an
  "x3" badge for copies and a green check when equipped; the card's soft
  colour is its rarity. Cards grow a little on hover. Tap one and a details
  panel slides in on the right while the grid stays visible beside it: a
  big preview, name, rarity and size, power, damage per second, the five
  multipliers, how many you have / use, and one Equip / Unequip button.
  Tapping another pet updates the panel in place; X closes it and the grid
  takes the full width again. Tabs: All, Normal, Huge, Titanic, Equipped;
  a small Sort menu: Power, Newest (when you first got it), Rarity.
- **Equip Best** (Inventory and Upgrade Tree): equips the team that really
  deals the most damage (power x Damage upgrade x the pet's own Damage
  stat, `Config.bestTeam`), not just the highest shown power; ties go to
  luck, then coins. It respects your slots, uses copies only as many as
  you own (Normal, Huge and Titanic alike) and drops weaker pets. A small
  toast says what was equipped, or "Team already optimized".
- **Your Team** (top of the screen): each equipped pet in a round chip with
  its damage per second and its share of the team's damage under it
  ("1.2K · 45%"); the shares always add up to 100%.
- **Pet stats:** every animal has its own five multipliers (its `Stats` in
  `Config.PETS`), shown on its Inventory card: **Speed** (how fast it
  moves), **Luck**, **Coins**, **Damage** (its own hits) and **EXP**. Every
  animal has a baseline that grows with rarity plus one specialty (Fox,
  Bunny, Kitsune: luck; Piglet, Hamster, Tanuki: coins; Wolf, Tiger,
  Dragon: damage; Owl, Sphinx, Crane: EXP; Cheetah, Falcon: speed). Huge
  doubles a pet's bonuses and Titanic quadruples them (not Speed). Luck,
  Coins and EXP bonuses of the equipped pets **add up** first:

      pet luck   = 1 + sum of (each equipped pet's Luck - 1)
      final luck = existing luck x pet luck

  where existing luck = Luck upgrade x rebirths x world x 10th-roll bonus x
  luck boost. A 1.1x and a 1.3x pet make 1.4x; with existing luck x5 that
  is x7. Coins and EXP work the same way (team bonus x everything else).
- **Your luck** sits right next to your coins: a small green pill "🍀 ×7.4"
  with exactly the luck your next roll uses (`Config.luck`). Hover or tap
  it for the breakdown (upgrade, pets, rebirths, world, boost, bonus
  roll). It updates the moment you equip a pet, get a boost or walk into
  another world.
- **Upgrade tree** (the tree button): Coins, Damage, Luck, Roll Speed, Rolls
  at Once, Auto Hatch (auto roll → quick reveals → auto-equip best), Size
  Luck and Pet Slots. Some branches unlock after others. It's a scrollable
  board that grows up from START, with rounded connectors that fill with a
  branch's colour once it's unlocked. Each upgrade is a card with its icon,
  "Lv 4 / 20" and a slim bar, and its price always visible in a pill:
  grey padlock + requirement (locked), price (not enough yet), green price
  pill and a gently breathing outline (affordable), gold MAX (maxed).
  Cards lift on hover and press on click; buying squashes and pops the
  card, fills its bar, flashes its connector, bursts sparkles and floats
  "+1 level" up. The side panel shows the selected upgrade in full (now →
  next, level pips, BUY).
- **Collection rewards** in the Index: discovering animals unlocks
  surprise rewards (5, 10, 15 … 70 animals, the first Huge and Titanic
  animals, and more). A small card under the categories shows how close
  the next one is ("18 / 20 animals"); when one is reached it turns gold,
  the Index button gets a gold dot and a CLAIM button appears. Claiming
  opens a gift that wobbles, pops open and shows exactly what the server
  gave (coins and/or a luck boost that multiplies your waiting boost).
  Each reward can only be claimed once (saved with your data).
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
- **Rebirth (8 levels):** needs the coins AND a level (16, 34, 52, 64, 70,
  75, 82, 88): the first after about 10 minutes, the 8th after about 3 hours. It's a prestige: only your coins reset; worlds, pets,
  upgrades, the Index and your level stay. Each one gives, forever and
  stacking: **Luck x1.5** and **Money +200%** (rebirth 3 = luck x3.4 and
  coins x7; rebirth 8 = x25.6 and x17).
- **Leaderboards:** Strongest Pet, Playtime and Rebirths in the Forest;
  Most Rolls in the Top panel.

### Progression (balanced with `tools/economy/simulate.py`)

| | Time for an active player |
| --- | --- |
| Rebirth 1 (level 16) | ~11 min |
| World 2 (Sahara) | ~16 min |
| Rebirths 2 / 3 | ~26 / 48 min |
| World 3 (Frozen Peaks) | ~37 min |
| Rebirths 4 / 5 / 6 | ~1.1 / 1.5 / 1.9 h |
| World 4 (Sakura Jungle) | ~2 h |
| Rebirths 7 / 8 | ~2.3 / 2.9 h |
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
Rebirth, Settings; the leaderboards live in the Forest), and two buttons at
the bottom right made like the navigation buttons (rounded square, icon,
caption under it): ROLL a bit bigger and blue, and AUTO to its left (white
"AUTO OFF" / green "AUTO ON" with a status dot), each with a soft shadow
and a faint shine; nothing drawn behind them. The compact/full hatch
choice lives in Settings, so the middle stays clear for the fights. The
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
| 2 Sahara | Oasis with palms and reeds, pyramids with gold capstones and a sphinx, Cleopatra's temple (pylon gate with a winged sun disk, lotus columns, painted friezes, obelisks, fire braziers, guardian sphinxes, her statue), the fusion machine (spinning rings, glowing pipes, hopper, output pad, console with a screen), a camel, pottery, Western Wall-style walls with raised stone faces | Saguaro, barrel and prickly pear cactuses (120M HP, 600 coins) | 25K |
| 3 Frozen Peaks | Snow with ice patches, a frozen sea (cracks, fishing holes, pressure ridges, floes, icebergs, penguins), a snow-brick igloo, a snowman and a sled, an ice arch with icicles, ice walls, crystal clusters, snow-laden pines, snowy rocks, snowfall | Ice cubes: clear, with a fish, with a gem, stacked (30B HP, 40K coins) | 12M |
| 4 Sakura Jungle | Twisted and weeping cherry trees with falling petals, red maples, bamboo, ferns, hydrangeas and azaleas, stepping-stone path, torii gates, stone lanterns, koi pond with a red arched bridge and a bamboo spout, a five-tier pagoda, Japanese walls with tile roofs and round windows | Sushi with happy faces: salmon, tuna, egg, maki (12T HP, 3M coins) | 130B |

The fusion machine shows its state: slow rings when idle, fast rings and
lots of sparkles while fusing (the orb takes the pet's colour and grows), and
a golden beam of light when a huge pet is ready.

**Testing (temporary):** rebirths cost no coins (the level is still needed), area unlocks cost 0 coins (the gates still start locked and are unlocked at the gate as normal), and every join re-locks the areas so the gates can be seen (see CLAUDE.md, restore before release).

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
