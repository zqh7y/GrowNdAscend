# Grow N Ascend

A solo incremental Roblox game. Train your pet, watch it grow, ascend to
evolve it, and flex the **Strongest Pet** on the global leaderboard.

## How it plays

- **Tap TRAIN!** to earn ⚡ Energy.
- **Buy trainers** (Treat Bowl → Cosmic Nexus) that earn Energy every second.
  Every 25 of a trainer doubles its output.
- **Stronger Taps** make each tap worth more, plus a share of your Energy/sec.
- Your **pet grows** as you earn: it gets bigger and its 💪 Power goes up.
- **Ascend** once you've earned 1M Energy in a run: energy, trainers and taps
  reset, you get ⭐ Stars (+10% Energy and Power each, forever) and your pet
  **evolves**: Sprout Pup → Fluffball → Brawler → Guardian → Titan →
  Celestial → Cosmic Beast → Godbeast.
- **Offline earnings:** trainers keep working at half speed while you're
  away (up to 8 hours).
- **🏆 Top Pets:** a global leaderboard of the strongest pets ever.

## Solo servers

Every player gets their own server, so the game feels offline, but progress
saves and the leaderboard is global. In Studio: **Game Settings → Places →
Server Size = 1** (after publishing), and turn on **Security → Enable Studio
Access to API Services** to test saving and the leaderboard in Studio.

## Setup (Rojo)

```bash
aftman install          # installs Rojo 7.7.0
rojo serve              # then connect from the Rojo plugin in Studio
```

Or build a place file: `rojo build -o GrowNdAscend.rbxlx`

## Code

| Path | What it does |
| --- | --- |
| `src/shared/Config.luau` | All numbers and formulas (trainers, costs, stars, forms, formatting) |
| `src/server/PlayerData.luau` | Loading, saving (every 60s and on leave) |
| `src/server/Game.luau` | Taps, trainers, buying, ascending, offline earnings |
| `src/server/Leaderboard.luau` | Global Strongest Pet board (OrderedDataStore) |
| `src/client/init.client.luau` | HUD, trainer shop, pet card, popups, leaderboard |
| `src/client/Pet.luau` | The pet that follows you, grows and evolves |
| `src/client/Ui.luau` | UI helpers |

The server owns every number; the client only asks to tap, buy or ascend.
