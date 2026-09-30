# Hatch Incremental

A solo pet RNG game on Roblox. Hit **ROLL**, see what pet you get, chase the
rare ones and climb the global **Most Rolls** leaderboard.

## How it plays

- **🎲 ROLL** (bottom middle): one roll a second, each giving a random pet.
  There are 20 pets, from Dog (1 in 2) to Glitch (1 in 10,000,000).
- Rarities: Common, Uncommon, Rare, Epic, Legendary, Mythic, Secret.
  Rolls of **1 in 1,000 or rarer** get a full-screen reveal.
- **✨ Bonus roll:** every 10th roll has 2x luck.
- **🎒 Pets:** see every pet (unfound ones show as ??? with their odds) and
  **equip up to 3**. Equipped pets follow you and add luck; rarer pets add
  more (a 1 in 1,000 pet is +45%).
- **🔁 Auto roll** unlocks after 50 rolls.
- **🏆 Top Rollers:** global leaderboard of total rolls.

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
| `src/shared/Config.luau` | Pets, odds, rarities, luck, the roll itself, formatting |
| `src/server/PlayerData.luau` | Loading and saving (every 60s and on leave) |
| `src/server/Rolling.luau` | Rolls (server picks the pet), equipping |
| `src/server/Leaderboard.luau` | Global Most Rolls board (OrderedDataStore) |
| `src/client/init.client.luau` | Roll button, reveal, auto roll, pets panel, leaderboard |
| `src/client/Pets.luau` | Equipped pets following you |
| `src/client/Ui.luau` | UI helpers |
