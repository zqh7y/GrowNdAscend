"""Simulates an active player to check the progression against the targets.

The loop: fight enemies -> coins + EXP -> level up -> hatch pets -> upgrade
-> unlock worlds -> rebirth (keeps worlds) -> stronger -> chase big pets.

Targets (an active player, rolling all the time):
   World 2 ~20-30 min, World 3 ~1.5-2 h, World 4 ~5-6 h (a milestone),
   Rebirth 1 (level 50) before World 4, later rebirths far apart,
   best pet a Titanic Glitch ~5T.

Everything about worlds, rebirths, levels and animals is read from
src/shared/Config.luau; the upgrade tree is mirrored in UP below (keep it in
sync with Config.UPGRADES).
Usage: python3 tools/economy/simulate.py [runs] [--hours H]
"""
import math, os, random, re, sys

_config = open(os.path.join(os.path.dirname(__file__), "../../src/shared/Config.luau")).read()

def num(pattern):
    return float(re.search(pattern, _config).group(1))

_rows = re.findall(r'Name = "([^"]+)", Odds = (\d+), World = (\d+)', _config)
PETS = [(int(o), int(w)) for _, o, w in _rows]
ODDS_OF = {n: int(o) for n, o, _ in _rows}
WORLD_PENALTY = num(r'WORLD_PENALTY = ([\d.]+)')
# (health, coins, exp, unlock cost, luck) for each world, from Config.AREAS
WORLDS = []
for block in re.findall(r'Name = "[^"]+",\s*Luck = ([\d.]+).*?Cost = ([\d.e]+),.*?Health = ([\d.e]+), Coins = ([\d.e]+), Exp = ([\d.e]+)', _config, re.S):
    luck, cost, hp, coins, exp = map(float, block)
    WORLDS.append((hp, coins, exp, cost, luck))
REBIRTHS = [(float(c), int(l)) for c, l in re.findall(r'\{ Cost = ([\d.e]+), Level = (\d+) \}', _config)]
REBIRTH_LUCK, REBIRTH_COINS = num(r'REBIRTH_LUCK = ([\d.]+)'), num(r'REBIRTH_COINS = ([\d.]+)')
LEVEL_BASE, LEVEL_GROWTH = num(r'LEVEL_BASE = ([\d.]+)'), num(r'LEVEL_GROWTH = ([\d.]+)')

def exp_to_next(level):  # Config.expToNext
    return math.floor(LEVEL_BASE * LEVEL_GROWTH ** (level - 1) + 0.5)

def base_power(odds):  # Config pet power
    return 1e6 * (odds / 1000) ** 1.17

SIZES = [(1, 1), (100, 10), (1000, 100)]  # (1 in chance, power multiplier)

UP = {  # id: (value(level), cost(level), max)  -- mirrors Config.UPGRADES
    "Coins":     (lambda l: 1.35 ** l,            lambda l: 60 * 3.4 ** l, 20),
    "Damage":    (lambda l: 1.35 ** l,            lambda l: 90 * 3.4 ** l, 20),
    "Luck":      (lambda l: 1.25 ** l,            lambda l: 250 * 3.7 ** l, 25),
    "RollSpeed": (lambda l: max(0.35, 1 - 0.05 * l), lambda l: 120 * 3.6 ** l, 13),
    "Rolls":     (lambda l: 1 + l,                lambda l: 2e4 * 80 ** l, 4),
    "AutoHatch": (lambda l: l,                    lambda l: [600, 1e6][l], 2),
    "SizeLuck":  (lambda l: 1.12 ** l,            lambda l: 1e6 * 4.5 ** l, 15),
    "Slots":     (lambda l: 3 + l,                lambda l: [1e4, 5e7, 2e11][l], 3),
}
HIT_EVERY = 0.6
OVERHEAD = 1.6  # seconds per enemy: running over, retargeting, its hops
BONUS_EVERY, BONUS_LUCK = 10, 2
CHAIN_CHANCE, CHAIN_MAX = 1 / 6, 1024  # the luck chain (Config.nextChain)
MAX_LUCK = num(r'MAX_LUCK = ([\d.e]+)')

def pet_luck(odds, size):  # Config.petLuck (added up, then 1 + sum)
    return math.log10(odds) * 0.05 * [1, 2, 4][size]

def fmt(n):
    for s, d in (("Qa", 1e15), ("T", 1e12), ("B", 1e9), ("M", 1e6), ("K", 1e3)):
        if n >= d:
            return f"{n/d:.2f}{s}"
    return f"{n:.0f}"

def hm(seconds):
    return f"{seconds/3600:.1f} h" if seconds >= 3600 else f"{seconds/60:.0f} min"

def run(hours=8, seed=1, verbose=False):
    rng = random.Random(seed)
    lv = {k: 0 for k in UP}
    val = lambda k: UP[k][0](lv[k])
    coins, unlocked, rolls, rebirths = 0.0, 1, 0, 0
    level, exp = 1, 0.0
    pets, team = [], []
    log = {}
    roll_clock = 0.0
    chain = 1
    def refresh_team():
        nonlocal team
        team = sorted(pets, key=lambda p: -p[0])[: int(val("Slots"))]
    t = 0
    while t < hours * 3600:
        world = unlocked  # farm and roll in the best world you have
        hp, reward, exp_per, _, world_luck = WORLDS[world - 1]
        # rolling: auto roll is free; quick hatches (Auto Hatch 1) cut the show
        cycle = val("RollSpeed") + (0.45 if lv["AutoHatch"] < 1 else 0)
        roll_clock += 1.0
        while roll_clock >= cycle:
            roll_clock -= cycle
            multiplier = chain
            chain = min(chain * 2, CHAIN_MAX) if rng.random() < CHAIN_CHANCE else 1
            for _ in range(int(val("Rolls"))):
                rolls += 1
                bonus = BONUS_LUCK if rolls % BONUS_EVERY == 0 else 1
                luck = val("Luck") * (1 + sum(pet_luck(o, s) for _, o, s in team)) * bonus
                luck = min(luck * REBIRTH_LUCK ** rebirths * world_luck * multiplier, MAX_LUCK)
                odds = 2
                for o, w in reversed(PETS[1:]):
                    if rng.random() < luck / (o * WORLD_PENALTY ** max(0, w - world)):
                        odds = o
                        break
                size = 0
                for i in (2, 1):
                    if rng.random() < val("SizeLuck") * bonus / SIZES[i][0]:
                        size = i
                        break
                pets.append((base_power(odds) * SIZES[size][1], odds, size))
            pets = sorted(pets, key=lambda p: -p[0])[:60]
            refresh_team()
        # fighting: coins and EXP
        dps = sum(p[0] for p in team) * val("Damage") / HIT_EVERY
        if dps > 0:
            per_kill = hp / dps + OVERHEAD
            coins += reward * val("Coins") * (1 + REBIRTH_COINS * rebirths) / per_kill
            exp += exp_per / per_kill
            while exp >= exp_to_next(level):
                exp -= exp_to_next(level)
                level += 1
        # goals: the next world first, then a rebirth (worlds are kept)
        if unlocked < len(WORLDS) and coins >= WORLDS[unlocked][3]:
            coins -= WORLDS[unlocked][3]
            unlocked += 1
            log["W%d" % unlocked] = t
            if verbose:
                print(f"  World {unlocked} at {hm(t)}  (level {level}, rebirths {rebirths}, best pet {fmt(max(p[0] for p in pets))})")
        if rebirths < len(REBIRTHS):
            cost, need = REBIRTHS[rebirths]
            next_world = WORLDS[unlocked][3] if unlocked < len(WORLDS) else float("inf")
            if coins >= cost and level >= need and not (coins >= next_world):
                coins = 0.0
                rebirths += 1
                log["R%d" % rebirths] = t
                if verbose:
                    print(f"  Rebirth {rebirths} at {hm(t)}  (level {level}, world {unlocked})")
        # upgrades: the cheapest one, never more than half of the next goal
        goals = []
        if unlocked < len(WORLDS):
            goals.append(WORLDS[unlocked][3])
        if rebirths < len(REBIRTHS):
            goals.append(REBIRTHS[rebirths][0])
        cap = 0.5 * min(goals) if goals else float("inf")
        while True:
            options = [(UP[k][1](lv[k]), k) for k in UP if lv[k] < UP[k][2]]
            options = [o for o in options if o[0] <= coins and o[0] <= cap]
            if not options:
                break
            cost, k = min(options)
            coins -= cost
            lv[k] += 1
            refresh_team()
        t += 1
    log["level"] = level
    log["rebirths"] = rebirths
    log["upgrades"] = dict(lv)
    log["best"] = max(p[0] for p in pets) if pets else 0
    return log

if __name__ == "__main__":
    args = sys.argv[1:]
    runs = int(args[0]) if args and args[0].isdigit() else 3
    hours = float(args[args.index("--hours") + 1]) if "--hours" in args else 8
    print("worlds (hp, coins, exp, cost):", [(fmt(w[0]), fmt(w[1]), w[2], fmt(w[3])) for w in WORLDS])
    print("rebirths (cost, level):", [(fmt(c), l) for c, l in REBIRTHS])
    print("EXP to reach level 50 / 75 / 110 / 575:", ", ".join(fmt(sum(exp_to_next(l) for l in range(1, n))) for n in (50, 75, 110, 575)))
    marks = {}
    for seed in range(runs):
        print(f"run {seed} ({hours:.0f} h):")
        log = run(hours=hours, seed=seed, verbose=True)
        print(f"  end: level {log['level']}, rebirths {log['rebirths']}, best pet {fmt(log['best'])}, upgrades {log['upgrades']}")
        for k, v in log.items():
            if isinstance(v, int) and (k.startswith("W") or k.startswith("R")):
                marks.setdefault(k, []).append(v)
    for k in sorted(marks, key=lambda k: (k[0], int(k[1:]))):
        v = marks[k]
        print(f"{k}: {hm(sum(v)/len(v))} on average ({len(v)}/{runs} runs)")
