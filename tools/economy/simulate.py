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

_rows = re.findall(r'Name = "([^"]+)", Odds = (\d+), World = (\d+).*?Stats = \{ Speed = ([\d.]+), Luck = ([\d.]+), Coins = ([\d.]+), Damage = ([\d.]+), Exp = ([\d.]+) \}', _config)
PETS = [(int(o), int(w)) for _, o, w, *_ in _rows]
ODDS_OF = {n: int(o) for n, o, *_ in _rows}
# per-pet multipliers by odds: (luck, coins, damage, exp)
STATS_OF = {int(o): tuple(map(float, (l, c, d, e))) for _, o, _, _sp, l, c, d, e in _rows}
WORLD_PENALTY = num(r'WORLD_PENALTY = ([\d.]+)')
# (health, coins, exp, unlock cost, luck) for each world, from Config.AREAS
WORLDS = []
for block in re.findall(r'Name = "[^"]+",\s*Luck = ([\d.]+).*?Cost = ([\d.e]+),.*?Health = ([\d.e]+), Coins = ([\d.e]+), Exp = ([\d.e]+)', _config, re.S):
    luck, cost, hp, coins, exp = map(float, block)
    WORLDS.append((hp, coins, exp, cost, luck))
# rebirth perks (Config.PERKS): (rebirths needed, stat, multiplier)
PERKS = [(int(r), st, float(v)) for r, st, v in re.findall(r'\{ Area = \d+, Rebirths = (\d+), Stat = "(\w+)", Value = ([\d.]+)', _config)]

def perk(stat, rebirths):  # Config.perkValue
    value = 1.0
    for need, st, v in PERKS:
        if st == stat and rebirths >= need:
            value *= v
    return value

REBIRTHS = [(float(c), int(l)) for c, l in re.findall(r'\{ Cost = ([\d.e]+), Level = (\d+) \}', _config)]
REBIRTH_LUCK, REBIRTH_COINS = num(r'REBIRTH_LUCK = ([\d.]+)'), num(r'REBIRTH_COINS = ([\d.]+)')
LEVEL_BASE, LEVEL_GROWTH = num(r'LEVEL_BASE = ([\d.]+)'), num(r'LEVEL_GROWTH = ([\d.]+)')

# Index milestones (Config.MILESTONES): (size index 0-2, count, coins, boost, id)
MILESTONES = []
for kind, count, coins_m, boost, mid in re.findall(r'\{ Id = "([a-z]+)\d+", Count = (\d+), Coins = ([\d.e]+), Boost = (\d+) \}()', _config):
    pass
for mid, kind, count, coins_m, boost in re.findall(r'\{ Id = "([^"]+)", Size = (\d), Count = (\d+), Coins = ([\d.e]+), Boost = (\d+)', _config):
    MILESTONES.append((int(kind) - 1, int(count), float(coins_m), int(boost), mid))

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
# the Luck Board (read from Config.LUCK_BOARD): each row multiplies luck by
# Per per level; a row needs the row before at BOARD_UNLOCK levels
BOARD = re.findall(r'\{ Id = "([a-z]+)", Name = "[^"]+", Icon = "[a-z]+", Color = [^}]+\), Per = ([\d.]+), Max = (\d+), BaseCost = ([\d.e]+), Growth = ([\d.]+) \}', _config)
BOARD_UNLOCK = int(num(r'BOARD_UNLOCK = (\d+)'))
BOARD_IDS = []
for bid, per, mx, base, growth in BOARD:
    per, mx, base, growth = float(per), int(mx), float(base), float(growth)
    UP["B_" + bid] = ((lambda p: lambda l: p ** l)(per), (lambda b, g: lambda l: b * g ** l)(base, growth), mx)
    BOARD_IDS.append("B_" + bid)

def board_ok(lv, key):  # Config.canBoard (the row before needs BOARD_UNLOCK levels)
    i = BOARD_IDS.index(key)
    return i == 0 or lv[BOARD_IDS[i - 1]] >= BOARD_UNLOCK

HIT_EVERY = 0.6
OVERHEAD = 1.6  # seconds per enemy: running over, retargeting, its hops
BONUS_EVERY, BONUS_LUCK = 10, 2
CHAIN_CHANCE, CHAIN_MAX = 1 / 12, 1024  # luck boosts (Config.BOOST_CHANCE, Config.nextChain)
MAX_HIT = num(r'MAX_HIT = ([\d.]+)')
MAX_LUCK = num(r'MAX_LUCK = ([\d.e]+)')

SIZE_STAT = [1, 2, 4]  # Huge/Titanic multiply the bonus part

def pet_bonus(odds, size, k):  # Config.petStat - 1; k: 0 luck, 1 coins, 2 damage, 3 exp
    return (STATS_OF[odds][k] - 1) * SIZE_STAT[size]

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
    found = [set(), set(), set()]  # animals discovered per size (normal/huge/titanic)
    earned = 0.0  # coins earned per second (for reporting)
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
            boosts = 0
            for _ in range(int(val("Rolls"))):
                rolls += 1
                bonus = BONUS_LUCK if rolls % BONUS_EVERY == 0 else 1
                if rng.random() < CHAIN_CHANCE:  # a x2 luck boost instead of a pet
                    boosts += 1
                    continue
                board = 1.0
                for key in BOARD_IDS:
                    board *= val(key)
                luck = val("Luck") * board * (1 + sum(pet_bonus(o, s, 0) for _, o, s in team)) * bonus
                luck = min(luck * REBIRTH_LUCK ** rebirths * world_luck * multiplier * perk("Luck", rebirths), MAX_LUCK)
                odds = 2
                for o, w in reversed(PETS[1:]):
                    if rng.random() < min(luck / (o * WORLD_PENALTY ** max(0, w - world)), MAX_HIT):
                        odds = o
                        break
                size = 0
                for i in (2, 1):
                    if rng.random() < val("SizeLuck") * bonus / SIZES[i][0]:
                        size = i
                        break
                pets.append((base_power(odds) * SIZES[size][1], odds, size))
                if odds not in found[size]:
                    found[size].add(odds)
                    for m in MILESTONES:
                        if m[0] == size and len(found[size]) >= m[1] and m[4] not in log:
                            log[m[4]] = t
                            coins += m[2]
                            chain = min(chain * m[3], CHAIN_MAX) if m[3] > 1 else chain
                            if verbose:
                                print(f"    milestone {m[4]} at {hm(t)}: +{fmt(m[2])} coins (income {fmt(earned * 60)}/min)")
            chain = min(multiplier * 2 ** boosts, CHAIN_MAX) if boosts else 1
            pets = sorted(pets, key=lambda p: -p[0])[:60]
            refresh_team()
        # fighting: coins and EXP
        dps = sum(p[0] * (1 + pet_bonus(p[1], p[2], 2)) for p in team) * val("Damage") * perk("Damage", rebirths) / HIT_EVERY
        if dps > 0:
            per_kill = hp / dps + OVERHEAD
            coin_team = 1 + sum(pet_bonus(o, s, 1) for _, o, s in team)
            exp_team = 1 + sum(pet_bonus(o, s, 3) for _, o, s in team)
            earned = reward * val("Coins") * (1 + REBIRTH_COINS * rebirths) * coin_team * perk("Coins", rebirths) / per_kill
            coins += earned
            exp += exp_per * exp_team * perk("Exp", rebirths) / per_kill
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
                log["levelR%d" % rebirths] = level
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
            options = [(UP[k][1](lv[k]), k) for k in UP if lv[k] < UP[k][2] and (k not in BOARD_IDS or board_ok(lv, k))]
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
