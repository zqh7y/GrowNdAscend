"""Simulates an active player to check the economy against the targets
(the animals are read from Config.luau; like the game, every animal can
come out anywhere but animals from worlds ahead are WORLD_PENALTY x rarer
per world, and each world has its own luck):
   ~40 min to World 4 with ~1B pets there; best Titanic ~5T (endgame).
   Rebirths (8, coins + an animal each) spread over many hours.
Usage: python3 tools/economy/simulate.py [runs]
Keep the numbers here in sync with src/shared/Config.luau (Config is the
source of truth; this mirrors it so the curve can be tested quickly)."""
import math, random, sys

# --- mirrors Config.luau -------------------------------------------------------
import os, re
_config = open(os.path.join(os.path.dirname(__file__), "../../src/shared/Config.luau")).read()
# (odds, world) for every animal, read straight from Config.luau
_rows = re.findall(r'Name = "([^"]+)", Odds = (\d+), World = (\d+)', _config)
PETS = [(int(o), int(w)) for _, o, w in _rows]
ODDS_OF = {n: int(o) for n, o, _ in _rows}
WORLD_PENALTY = float(re.search(r'WORLD_PENALTY = ([\d.]+)', _config).group(1))
WORLD_LUCK = [float(x) for x in re.findall(r'Luck = ([\d.]+), -- rolling here', _config)]
REBIRTHS = [(float(c), ODDS_OF[n]) for c, n in re.findall(r'\{ Cost = ([\d.e]+), Pet = "([^"]+)" \}', _config)]
REBIRTH_LUCK, REBIRTH_COINS = 1.5, 2
PET_ODDS = [o for o, _ in PETS]
def base_power(odds):  # Config.basePower
    return 1e6 * (odds / 1000) ** 1.17
SIZES = [(1, 1), (100, 10), (1000, 100)]  # (1 in chance, power multiplier)

UP = {  # id: (value(level), cost(level), max)
    "Coins":     (lambda l: 1.35 ** l,            lambda l: 40 * 3.1 ** l, 20),
    "Damage":    (lambda l: 1.35 ** l,            lambda l: 60 * 3.1 ** l, 20),
    "Luck":      (lambda l: 1.25 ** l,            lambda l: 150 * 3.4 ** l, 25),
    "RollSpeed": (lambda l: max(0.35, 1 - 0.05 * l), lambda l: 80 * 3.3 ** l, 13),
    "Rolls":     (lambda l: 1 + l,                lambda l: 3e3 * 60 ** l, 4),
    "AutoHatch": (lambda l: l,                    lambda l: [400, 2e5, 5e7][l], 3),
    "SizeLuck":  (lambda l: 1.12 ** l,            lambda l: 1e5 * 4 ** l, 15),
    "Slots":     (lambda l: 3 + l,                lambda l: [2e3, 5e6, 5e9][l], 3),
}
WORLDS = [  # (coin health, coins per break, unlock cost)
    (5e3, 20, 0),
    (6e7, 400, 4e3),
    (4e9, 2.5e4, 6e5),
    (2.5e11, 1.5e6, 2.2e8),
]
HIT_EVERY = 0.6
OVERHEAD = 1.6  # seconds per coin for running over, retargeting, hops
BONUS_EVERY, BONUS_LUCK = 10, 2

def pet_luck(odds, size):  # Config.petLuck (added up, then 1 + sum)
    return math.log10(odds) * 0.05 * [1, 2, 4][size]

# --- one player ------------------------------------------------------------------
def run(minutes=60, seed=1, verbose=False, rebirth=False):
    rng = random.Random(seed)
    lv = {k: 0 for k in UP}
    val = lambda k: UP[k][0](lv[k])
    coins, world, rolls, rebirths = 0.0, 1, 0, 0
    hatched = set()
    pets = []  # (power, odds, size)
    team = []
    log = {}
    t = 0.0
    roll_clock = 0.0
    def refresh_team():
        nonlocal team
        team = sorted(pets, key=lambda p: -p[0])[: int(val("Slots"))]
    while t < minutes * 60:
        # rolling (clicking until auto hatch, then automatic)
        cycle = val("RollSpeed") + (0.45 if lv["AutoHatch"] < 2 else 0)
        eff = 0.6 if lv["AutoHatch"] == 0 else 1.0
        roll_clock += eff
        while roll_clock >= cycle:
            roll_clock -= cycle
            for _ in range(int(val("Rolls"))):
                rolls += 1
                bonus = BONUS_LUCK if rolls % BONUS_EVERY == 0 else 1
                luck = val("Luck") * (1 + sum(pet_luck(o, s) for _, o, s in team)) * bonus
                luck *= REBIRTH_LUCK ** rebirths * WORLD_LUCK[world - 1]
                odds = 2
                for o, w in reversed(PETS[1:]):
                    if rng.random() < luck / (o * WORLD_PENALTY ** max(0, w - world)):
                        odds = o
                        break
                hatched.add(odds)
                size = 0
                for i in (2, 1):
                    if rng.random() < val("SizeLuck") * bonus / SIZES[i][0]:
                        size = i
                        break
                pets.append((base_power(odds) * SIZES[size][1], odds, size))
            pets = sorted(pets, key=lambda p: -p[0])[:60]
            refresh_team()
        # fighting in the newest world
        hp, reward, _ = WORLDS[world - 1]
        dps = sum(p[0] for p in team) * val("Damage") / HIT_EVERY
        if dps > 0:
            kill = hp / dps + OVERHEAD
            coins += reward * val("Coins") * (1 + REBIRTH_COINS * rebirths) / kill
        # spending: unlock the next world first, else the cheapest upgrade
        # that isn't more than half of what the next world costs
        if world < 4 and coins >= WORLDS[world][2]:
            coins -= WORLDS[world][2]
            world += 1
            log[world] = (t / 60, max(p[0] for p in pets), dict(lv))
            if verbose:
                print(f"  World {world} at {t/60:5.1f} min, best pet {fmt(max(p[0] for p in pets))}, team {fmt(sum(p[0] for p in team))}")
        # rebirth: all 8 need the coins and the animal
        if rebirth and world == 4 and rebirths < len(REBIRTHS):
            cost, pet_odds = REBIRTHS[rebirths]
            if coins >= cost and pet_odds in hatched:
                rebirths += 1
                coins, world = 0.0, 1
                log["R%d" % rebirths] = (t / 60, max(p[0] for p in pets))
                if verbose:
                    print(f"  Rebirth {rebirths} at {t/60:6.1f} min ({t/3600:.1f} h), best pet {fmt(max(p[0] for p in pets))}")
        nxt = WORLDS[world][2] if world < 4 else (REBIRTHS[rebirths][0] if rebirth and rebirths < len(REBIRTHS) else float("inf"))
        while True:
            options = [(UP[k][1](lv[k]), k) for k in UP if lv[k] < UP[k][2]]
            options = [o for o in options if o[0] <= coins and (o[0] <= 0.5 * nxt or world == 4)]
            if not options:
                break
            cost, k = min(options)
            coins -= cost
            lv[k] += 1
            refresh_team()
        t += 1
        if t == 40 * 60:
            log["40"] = (world, max(p[0] for p in pets), sum(p[0] for p in team), dict(lv), rolls)
    return log, pets, lv, rolls

def fmt(n):
    for s, d in (("T", 1e12), ("B", 1e9), ("M", 1e6), ("K", 1e3)):
        if n >= d:
            return f"{n/d:.2f}{s}"
    return f"{n:.0f}"

if __name__ == "__main__":
    runs = int(sys.argv[1]) if len(sys.argv) > 1 and sys.argv[1].isdigit() else 5
    print("pet power: " + ", ".join(fmt(base_power(o)) for o in PET_ODDS))
    print("best Titanic:", fmt(base_power(PET_ODDS[-1]) * SIZES[2][1]))
    w4 = []
    for seed in range(runs):
        print(f"run {seed}:")
        log, pets, lv, rolls = run(seed=seed, verbose=True)
        w, best, team, lv40, r40 = log["40"]
        print(f"  at 40 min: world {w}, best pet {fmt(best)}, team {fmt(team)}, rolls {r40}, upgrades {lv40}")
        if 4 in log:
            w4.append(log[4][0])
    if w4:
        print(f"World 4 reached at {sum(w4)/len(w4):.1f} min on average ({len(w4)}/{runs} runs)")
    if "--rebirth" in sys.argv:
        hours = float(sys.argv[sys.argv.index("--rebirth") + 1]) if len(sys.argv) > sys.argv.index("--rebirth") + 1 else 30
        print(f"rebirth run ({hours:.0f} hours):")
        log, pets, lv, rolls = run(minutes=hours * 60, seed=7, verbose=True, rebirth=True)
    # endgame: everything maxed, a team of strong Huge/Titanic pets
    luck = UP["Luck"][0](UP["Luck"][2]) * (1 + 6 * pet_luck(1e6, 1))
    size = UP["SizeLuck"][0](UP["SizeLuck"][2])
    per_sec = UP["Rolls"][0](UP["Rolls"][2]) / UP["RollSpeed"][0](UP["RollSpeed"][2])
    for name, odds, s_i in (("Huge Glitch", 1e7, 1), ("Titanic 1-in-1M animal", 1e6, 2), ("Titanic Glitch (5T)", 1e7, 2)):
        chance = min(1, luck / odds) * size / SIZES[s_i][0]
        print(f"endgame {name}: {fmt(base_power(odds) * SIZES[s_i][1])} power, 1 in {fmt(1/chance)} rolls = {1/chance/per_sec/3600:.1f} hours of auto rolling")
