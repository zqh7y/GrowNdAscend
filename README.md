# Hatch Incremental

A solo pet RNG game on Roblox. Hit **ROLL**, see what pet you get, chase the
rare ones and climb the global **Most Rolls** leaderboard.

## How it plays

**Roll pets → build a stronger team → pets fight the living coins on their
own → earn coins → buy upgrades → roll better pets → repeat.**

- **Living coins:** each world's coins are alive: trees, cactuses, ice cubes
  and sushi with happy faces that hop about 5 studs every second or so.
- **Pets fight for you:** equipped pets go after the living coin nearest to
  you, all together, and hit it on their own. Stronger pets (rarer, bigger)
  hit harder. Hits show lunges, flashes and damage numbers; a broken coin
  bursts and its coins fly into your counter. No clicking needed.
- **Rolling:** the Roll button gives a random pet (20 pets, 1 in 2 to
  1 in 10,000,000) and a random **size**: Normal, Huge (1 in 100, 2.5x size,
  10x power) or Titanic (1 in 1,000, 5x size, 100x power). Every 10th roll
  has 2x luck. Rare pets and big sizes get a full-screen reveal with rays,
  confetti and a jingle (Titanic: rainbow).
- **Upgrade tree** (the tree button): Coins, Damage, Luck, Roll Speed, Rolls
  at Once, Auto Hatch (auto roll → quick reveals → auto-equip best), Size
  Luck and Pet Slots. Some branches unlock after others.
- **Fusion machine** (Sahara): 5 of the same pet → 1 of the next size up.
- **Rebirth:** reset coins and areas for +50% coins forever.
- **Leaderboards:** Strongest Pet, Playtime and Rebirths in the Forest;
  Most Rolls in the Top panel.

Adding things later is one row each: a pet in `Config.PETS`, a size in
`Config.SIZES` (Giant, Colossal...), an upgrade branch in `Config.UPGRADES`.

## Screen

Coins at the top, your team and its damage per second at the top left, and
a compact dock of icon buttons at the bottom (Pets, Upgrades, Roll, Auto,
Top, Rebirth, Settings), so the middle stays clear for the fights. Panels
are glassy (about 0.3 transparent). Settings: damage numbers, roll reveal
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
| 1 Forest | Dirt path through the grass, oaks, birches, fruit trees and poplars (root flares, bent trunks, branches, toon-shaded leaves), flower patches (daisies, tulips, bluebells, sunflowers), berry bushes, mushrooms, fallen logs, mossy rocks, two tiered fountains with water streams, hills with a cottage and a windmill, the 3 leaderboards side by side | Hopping fruit trees (12 HP, 3 coins) | Free |
| 2 Sahara | Oasis with palms and reeds, pyramids with gold capstones and a sphinx, Cleopatra's temple (pylon gate with a winged sun disk, lotus columns, painted friezes, obelisks, fire braziers, guardian sphinxes, her statue), the fusion machine (spinning rings, glowing pipes, hopper, output pad, console with a screen), a camel, pottery, Western Wall-style walls with raised stone faces | Saguaro, barrel and prickly pear cactuses (150 HP, 25 coins) | 300 |
| 3 Frozen Peaks | Snow with ice patches, a frozen sea (cracks, fishing holes, pressure ridges, floes, icebergs, penguins), a snow-brick igloo, a snowman and a sled, an ice arch with icicles, ice walls, crystal clusters, snow-laden pines, snowy rocks, snowfall | Ice cubes: clear, with a fish, with a gem, stacked (1.5K HP, 200 coins) | 6K |
| 4 Sakura Jungle | Twisted and weeping cherry trees with falling petals, red maples, bamboo, ferns, hydrangeas and azaleas, stepping-stone path, torii gates, stone lanterns, koi pond with a red arched bridge and a bamboo spout, a five-tier pagoda, Japanese walls with tile roofs and round windows | Sushi with happy faces: salmon, tuna, egg, maki (15K HP, 1.8K coins) | 100K |

The fusion machine shows its state: slow rings when idle, fast rings and
lots of sparkles while fusing (the orb takes the pet's colour and grows), and
a golden beam of light when a huge pet is ready.

**Testing:** rebirth is currently free (see CLAUDE.md, restore before release).

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
| `src/client/Roll.luau` | Rolling, reveal cards, big reveals, auto roll |
| `src/client/UpgradeTree.luau` | The upgrade tree screen |
| `src/client/PetsPanel.luau`, `Panels.luau` | Pets, Top, Rebirth, Fusion, Settings |
| `src/client/Living.luau`, `Pets.luau` | Living coins hopping, pets running and attacking |
| `src/client/Effects.luau` | Sounds, damage numbers, flying coins, confetti |
| `src/client/Ui.luau`, `Screen.luau`, `State.luau` | UI kit and icons, panels and toasts, the client's data |
| `tools/sim/` | Runs the server and client on a fake Roblox to catch errors |
