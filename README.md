# Hatch Incremental

A solo pet RNG game on Roblox. Hit **ROLL**, see what pet you get, chase the
rare ones and climb the global **Most Rolls** leaderboard.

## How it plays

- **ROLL** (bottom middle): one roll a second, each giving a random pet.
  There are 20 pets, from Dog (1 in 2) to Glitch (1 in 10,000,000).
  Rolls of 1 in 1,000 or rarer get a full-screen reveal. Every 10th roll has
  2x luck, and auto roll unlocks after 50 rolls.
- **Pets:** equip up to 3. They follow you, add luck to rolls, and add their
  power to every hit on a breakable (rarer = stronger).
- **Coins:** tap breakables to hit them. Each area has its own, worth more
  and tougher than the last.
- **Areas:** pay coins at the glowing gate to unlock the next area.
- **Fusion machine** (Sahara): put in 5 of the same pet, wait for the timer
  (it keeps running while you're offline), collect a **Huge** version with
  10x power and 2x luck.
- **Rebirth:** reset coins and areas for +50% coins forever. Pets are kept.
- **Leaderboards:** Strongest Pet, Most Playtime and Most Rebirths stand in
  the Forest; Most Rolls is in the TOP panel.

## The map

Four areas in a straight line along +X (200 studs each), with invisible walls
on both sides (|Z| = 72) and at both ends. The whole map is built by
`src/server/World` when the server starts.

| Area | Theme | Breakable | Unlock |
| --- | --- | --- | --- |
| 1 Forest | Grass, trees, flowers, grass tufts, a fountain on each side, hills around the sides and back, the 3 leaderboards | Small trees (12 HP, 3 coins) | Free |
| 2 Sahara | Sand, dunes, 3 pyramids, Cleopatra's temple and statue, the fusion machine, Western Wall-style limestone walls | Cactuses (150 HP, 25 coins) | 300 |
| 3 Frozen Peaks | Snow, a frozen sea on both sides with ice floes and icebergs, an igloo, ice walls, crystals, pines, snowfall | Ice cubes (1.5K HP, 200 coins) | 6K |
| 4 Sakura Jungle | Cherry blossoms with falling petals, bamboo, stone path, torii gates, stone lanterns, koi pond, pagoda, low Japanese walls | Sushi (15K HP, 1.8K coins) | 100K |

Tip: for extra 2D grass on the terrain, select **Workspace → Terrain** in
Studio and turn on **Decoration**.

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
| `src/shared/Config.luau` | Pets, odds, luck, pet power, huge pets, areas, rebirths, formatting |
| `src/server/PlayerData.luau` | Loading, saving, playtime, sending state to the client |
| `src/server/World/` | Builds the map: `init` (terrain, walls, gates, spawn), `Build` (helpers), one module per area |
| `src/server/Breakables.luau` | Spawning breakables, hits, coins, respawning |
| `src/server/Progress.luau` | Area gates and rebirths |
| `src/server/Fusion.luau` | The fusion machine |
| `src/server/Rolling.luau` | Rolls (server picks the pet), equipping |
| `src/server/Leaderboards.luau` | The 4 global leaderboards (OrderedDataStores) |
| `src/client/init.client.luau` | All the screens: stats, roll, pets, top, rebirth, fusion, toasts |
| `src/client/Pets.luau` | Equipped pets following you (huges are 2x size) |
| `src/client/Ui.luau` | UI theme, buttons and drawn icons |
