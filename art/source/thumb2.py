# Roll Pets RNG thumbnail (1920x1080): painted cartoon look.
import math, random

random.seed(7)
INK = "#1d2140"
defs = []
_gid = [0]


def hexrgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def rgbhex(c):
    return "#%02x%02x%02x" % tuple(max(0, min(255, int(round(v)))) for v in c)


def mix(a, b, t):
    a, b = hexrgb(a), hexrgb(b)
    return rgbhex([a[i] + (b[i] - a[i]) * t for i in range(3)])


def light(c, t):
    return mix(c, "#ffffff", t)


def dark(c, t):
    return mix(c, "#1a1030", t)


def shade(base, cx="35%", cy="28%", r="80%"):
    """A painted round shading: light top-left, the colour, darker bottom-right."""
    _gid[0] += 1
    gid = "g%d" % _gid[0]
    defs.append(f'<radialGradient id="{gid}" cx="{cx}" cy="{cy}" r="{r}">'
                f'<stop offset="0" stop-color="{light(base, 0.42)}"/>'
                f'<stop offset="0.45" stop-color="{base}"/>'
                f'<stop offset="1" stop-color="{dark(base, 0.32)}"/></radialGradient>')
    return f"url(#{gid})"


def vshade(top, bottom):
    _gid[0] += 1
    gid = "v%d" % _gid[0]
    defs.append(f'<linearGradient id="{gid}" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{top}"/><stop offset="1" stop-color="{bottom}"/></linearGradient>')
    return f"url(#{gid})"


def gloss(x, y, rx, ry, rot=-25, op=0.6):
    return f'<ellipse cx="{x}" cy="{y}" rx="{rx}" ry="{ry}" fill="#ffffff" opacity="{op}" transform="rotate({rot} {x} {y})" filter="url(#soft2)"/>'


def eyes(x, y, s, iris="#3a63ff"):
    out = []
    for side in (-1, 1):
        ex = x + side * 22 * s
        out.append(f'<ellipse cx="{ex}" cy="{y}" rx="{15*s}" ry="{19*s}" fill="{INK}"/>')
        out.append(f'<ellipse cx="{ex}" cy="{y+5*s}" rx="{11*s}" ry="{13*s}" fill="{shade(iris, "50%", "80%", "70%")}"/>')
        out.append(f'<ellipse cx="{ex}" cy="{y+9*s}" rx="{6*s}" ry="{6*s}" fill="{light(iris, 0.4)}" opacity="0.7"/>')
        out.append(f'<circle cx="{ex-5*s}" cy="{y-7*s}" r="{6*s}" fill="#fff"/>')
        out.append(f'<circle cx="{ex+6*s}" cy="{y+7*s}" r="{2.6*s}" fill="#fff"/>')
        out.append(f'<circle cx="{ex+2*s}" cy="{y-11*s}" r="{1.6*s}" fill="#fff"/>')
        out.append(f'<ellipse cx="{x + side*41*s}" cy="{y+21*s}" rx="{11*s}" ry="{6.5*s}" fill="#ff7fa6" opacity="0.75" filter="url(#soft1)"/>')
    out.append(f'<path d="M {x-10*s},{y+24*s} Q {x},{y+38*s} {x+10*s},{y+24*s}" fill="none" stroke="{INK}" stroke-width="{4.2*s}" stroke-linecap="round"/>')
    return "".join(out)


def fur(x, y, s, color, n=5, spread=30):
    out = []
    for k in range(n):
        a = (k / max(1, n - 1) - 0.5) * 1.2
        px, py = x + math.sin(a) * spread * s, y + abs(a) * 6 * s
        out.append(f'<path d="M {px},{py} q {3*s},{-7*s} {1*s},{-12*s}" stroke="{color}" stroke-width="{2.4*s}" fill="none" stroke-linecap="round" opacity="0.55"/>')
    return "".join(out)


def ellipse(x, y, rx, ry, base, sw, extra=""):
    return f'<ellipse cx="{x}" cy="{y}" rx="{rx}" ry="{ry}" fill="{shade(base)}" stroke="{INK}" stroke-width="{sw}" {extra}/>'


def pet(kind, x, y, s, glow):
    g = [f'<circle cx="{x}" cy="{y-80*s}" r="{105*s}" fill="{glow}" opacity="0.55" filter="url(#blur)"/>']
    g.append(f'<ellipse cx="{x}" cy="{y+4*s}" rx="{66*s}" ry="{13*s}" fill="#1f5a26" opacity="0.38" filter="url(#soft1)"/>')
    sw = 7 * s
    if kind == "cat":
        c = "#ffa640"
        g.append(f'<path d="M {x+44*s},{y-34*s} Q {x+98*s},{y-56*s} {x+84*s},{y-112*s}" fill="none" stroke="{INK}" stroke-width="{24*s}" stroke-linecap="round"/><path d="M {x+44*s},{y-34*s} Q {x+98*s},{y-56*s} {x+84*s},{y-112*s}" fill="none" stroke="{c}" stroke-width="{12*s}" stroke-linecap="round"/><path d="M {x+90*s},{y-90*s} L {x+84*s},{y-112*s}" stroke="#fff3df" stroke-width="{12*s}" stroke-linecap="round"/>')
        g.append(ellipse(x, y - 40 * s, 50 * s, 43 * s, c, sw))
        g.append(f'<ellipse cx="{x}" cy="{y-34*s}" rx="{28*s}" ry="{26*s}" fill="#fff3df" opacity="0.95"/>')
        for k in range(3):
            g.append(f'<path d="M {x-46*s+k*6*s},{y-(56-k*12)*s} q {12*s},{-2*s} {18*s},{4*s}" stroke="#e07a1c" stroke-width="{4*s}" fill="none" stroke-linecap="round"/>')
        for side in (-1, 1):
            g.append(f'<ellipse cx="{x+side*22*s}" cy="{y-2*s}" rx="{16*s}" ry="{9*s}" fill="{shade("#fff3df")}" stroke="{INK}" stroke-width="{4.5*s}"/>')
            g.append(f'<path d="M {x+side*45*s},{y-118*s} L {x+side*42*s},{y-172*s} L {x+side*10*s},{y-142*s} Z" fill="{shade(c)}" stroke="{INK}" stroke-width="{sw}" stroke-linejoin="round"/>')
            g.append(f'<path d="M {x+side*38*s},{y-128*s} L {x+side*37*s},{y-158*s} L {x+side*18*s},{y-141*s} Z" fill="#ffb3c2"/>')
        g.append(ellipse(x, y - 110 * s, 60 * s, 52 * s, c, sw))
        for side in (-1, 1):
            for k in range(3):
                g.append(f'<path d="M {x+side*30*s},{y-(152-k*8)*s} l {side*-8*s},{4*s}" stroke="#e07a1c" stroke-width="{4*s}" stroke-linecap="round"/>')
            g.append(f'<path d="M {x+side*44*s},{y-96*s} L {x+side*82*s},{y-104*s} M {x+side*44*s},{y-88*s} L {x+side*82*s},{y-84*s}" stroke="{INK}" stroke-width="{2.6*s}" stroke-linecap="round" opacity="0.8"/>')
        g.append(eyes(x, y - 112 * s, s))
        g.append(f'<path d="M {x-6*s},{y-94*s} L {x+6*s},{y-94*s} L {x},{y-87*s} Z" fill="#ff5c7a"/>')
        g.append(gloss(x - 24 * s, y - 140 * s, 20 * s, 10 * s))
    elif kind == "dog":
        c = "#c98a52"
        g.append(f'<path d="M {x+46*s},{y-46*s} q {26*s},{-6*s} {30*s},{-34*s}" stroke="{INK}" stroke-width="{18*s}" fill="none" stroke-linecap="round"/><path d="M {x+46*s},{y-46*s} q {26*s},{-6*s} {30*s},{-34*s}" stroke="{c}" stroke-width="{8*s}" fill="none" stroke-linecap="round"/>')
        g.append(ellipse(x, y - 40 * s, 52 * s, 44 * s, c, sw))
        g.append(f'<ellipse cx="{x}" cy="{y-34*s}" rx="{28*s}" ry="{26*s}" fill="#f6dcbc"/>')
        for side in (-1, 1):
            g.append(f'<ellipse cx="{x+side*22*s}" cy="{y-2*s}" rx="{17*s}" ry="{9*s}" fill="{shade("#f6dcbc")}" stroke="{INK}" stroke-width="{4.5*s}"/>')
        g.append(ellipse(x, y - 112 * s, 62 * s, 54 * s, c, sw))
        g.append(f'<ellipse cx="{x+24*s}" cy="{y-128*s}" rx="{20*s}" ry="{16*s}" fill="#8a5530" opacity="0.8"/>')
        for side in (-1, 1):
            g.append(f'<ellipse cx="{x+side*60*s}" cy="{y-104*s}" rx="{19*s}" ry="{36*s}" fill="{shade("#8a5530")}" stroke="{INK}" stroke-width="{sw}" transform="rotate({side*-18} {x+side*60*s} {y-104*s})"/>')
        g.append(f'<ellipse cx="{x}" cy="{y-92*s}" rx="{28*s}" ry="{19*s}" fill="#f6dcbc"/>')
        g.append(eyes(x, y - 122 * s, s, "#6b3b1a"))
        g.append(f'<ellipse cx="{x}" cy="{y-101*s}" rx="{10*s}" ry="{7*s}" fill="{INK}"/><ellipse cx="{x-3*s}" cy="{y-103*s}" rx="{3*s}" ry="{2*s}" fill="#fff" opacity="0.8"/>')
        g.append(f'<path d="M {x-8*s},{y-82*s} Q {x},{y-68*s} {x+8*s},{y-82*s} Z" fill="#ff6f8f" stroke="{INK}" stroke-width="{3*s}"/>')
        g.append(f'<path d="M {x-58*s},{y-66*s} Q {x},{y-50*s} {x+58*s},{y-66*s}" stroke="#e43c4f" stroke-width="{9*s}" fill="none" stroke-linecap="round"/><circle cx="{x}" cy="{y-50*s}" r="{8*s}" fill="{shade("#ffd23f")}" stroke="{INK}" stroke-width="{3*s}"/>')
        g.append(gloss(x - 26 * s, y - 142 * s, 20 * s, 10 * s))
    elif kind == "bunny":
        c = "#ffffff"
        for side in (-1, 1):
            g.append(f'<ellipse cx="{x+side*24*s}" cy="{y-190*s}" rx="{16*s}" ry="{50*s}" fill="{shade("#f6f4ff")}" stroke="{INK}" stroke-width="{sw}" transform="rotate({side*10} {x+side*24*s} {y-190*s})"/>')
            g.append(f'<ellipse cx="{x+side*24*s}" cy="{y-188*s}" rx="{7*s}" ry="{35*s}" fill="{shade("#ffb3c8")}" transform="rotate({side*10} {x+side*24*s} {y-188*s})"/>')
        g.append(ellipse(x, y - 38 * s, 48 * s, 41 * s, "#f1efff", sw))
        g.append(f'<circle cx="{x+48*s}" cy="{y-30*s}" r="{14*s}" fill="{shade("#ffffff")}" stroke="{INK}" stroke-width="{4.5*s}"/>')
        for side in (-1, 1):
            g.append(f'<ellipse cx="{x+side*22*s}" cy="{y-2*s}" rx="{17*s}" ry="{9*s}" fill="{shade("#ffffff")}" stroke="{INK}" stroke-width="{4.5*s}"/>')
        g.append(ellipse(x, y - 106 * s, 56 * s, 50 * s, "#fbfaff", sw))
        g.append(eyes(x, y - 108 * s, s, "#e2477a"))
        g.append(f'<path d="M {x-5*s},{y-90*s} L {x+5*s},{y-90*s} L {x},{y-84*s} Z" fill="#ff7aa0"/><rect x="{x-6*s}" y="{y-80*s}" width="{12*s}" height="{8*s}" rx="{2*s}" fill="#ffffff" stroke="{INK}" stroke-width="{2.4*s}"/>')
        g.append(f'<path d="M {x-40*s},{y-150*s} Q {x-26*s},{y-162*s} {x-12*s},{y-152*s}" stroke="#ffb3c8" stroke-width="{7*s}" fill="none" stroke-linecap="round"/><circle cx="{x-8*s}" cy="{y-152*s}" r="{8*s}" fill="{shade("#ff8fb5")}" stroke="{INK}" stroke-width="{3*s}"/>')
        g.append(gloss(x - 24 * s, y - 134 * s, 18 * s, 9 * s))
    elif kind == "penguin":
        c = "#2e3f86"
        for side in (-1, 1):
            g.append(f'<ellipse cx="{x+side*58*s}" cy="{y-70*s}" rx="{14*s}" ry="{36*s}" fill="{shade(c)}" stroke="{INK}" stroke-width="{sw}" transform="rotate({side*-24} {x+side*58*s} {y-70*s})"/>')
        g.append(ellipse(x, y - 70 * s, 60 * s, 74 * s, c, sw))
        g.append(f'<ellipse cx="{x}" cy="{y-56*s}" rx="{42*s}" ry="{54*s}" fill="{shade("#ffffff", "40%", "25%")}"/>')
        g.append(f'<ellipse cx="{x}" cy="{y-122*s}" rx="{40*s}" ry="{28*s}" fill="#ffffff"/>')
        g.append(eyes(x, y - 124 * s, s * 0.85, "#3a63ff"))
        g.append(f'<path d="M {x-13*s},{y-106*s} L {x+13*s},{y-106*s} L {x},{y-91*s} Z" fill="{shade("#ff9b2e")}" stroke="{INK}" stroke-width="{4*s}" stroke-linejoin="round"/>')
        g.append(f'<path d="M {x-58*s},{y-90*s} Q {x},{y-70*s} {x+58*s},{y-90*s} L {x+56*s},{y-76*s} Q {x},{y-56*s} {x-56*s},{y-76*s} Z" fill="{shade("#e43c4f")}" stroke="{INK}" stroke-width="{4.5*s}"/>')
        g.append(f'<rect x="{x+22*s}" y="{y-80*s}" width="{16*s}" height="{38*s}" rx="{4*s}" fill="{shade("#e43c4f")}" stroke="{INK}" stroke-width="{4*s}"/>')
        g.append(f'<path d="M {x-62*s},{y-150*s} Q {x},{y-206*s} {x+62*s},{y-150*s} Z" fill="{shade("#e43c4f")}" stroke="{INK}" stroke-width="{sw}" stroke-linejoin="round"/><rect x="{x-64*s}" y="{y-156*s}" width="{128*s}" height="{16*s}" rx="{8*s}" fill="{shade("#ffffff")}" stroke="{INK}" stroke-width="{4.5*s}"/><circle cx="{x}" cy="{y-188*s}" r="{15*s}" fill="{shade("#ffffff")}" stroke="{INK}" stroke-width="{5*s}"/>')
        for side in (-1, 1):
            g.append(f'<ellipse cx="{x+side*22*s}" cy="{y}" rx="{19*s}" ry="{8*s}" fill="{shade("#ff9b2e")}" stroke="{INK}" stroke-width="{4*s}"/>')
        g.append(gloss(x - 26 * s, y - 118 * s, 16 * s, 26 * s, -15, 0.35))
    elif kind == "dragon":
        c, b = "#ef5040", "#ffd060"
        for side in (-1, 1):
            g.append(f'<path d="M {x+side*40*s},{y-100*s} L {x+side*150*s},{y-200*s} L {x+side*125*s},{y-130*s} L {x+side*165*s},{y-118*s} L {x+side*70*s},{y-62*s} Z" fill="{shade("#ff9a50")}" stroke="{INK}" stroke-width="{sw}" stroke-linejoin="round"/>')
            g.append(f'<path d="M {x+side*44*s},{y-98*s} L {x+side*140*s},{y-188*s} M {x+side*56*s},{y-86*s} L {x+side*150*s},{y-122*s}" stroke="{dark("#ff9a50", 0.3)}" stroke-width="{4*s}" stroke-linecap="round"/>')
        g.append(f'<path d="M {x+50*s},{y-20*s} Q {x+130*s},{y-10*s} {x+120*s},{y-70*s}" fill="none" stroke="{INK}" stroke-width="{26*s}" stroke-linecap="round"/><path d="M {x+50*s},{y-20*s} Q {x+130*s},{y-10*s} {x+120*s},{y-70*s}" fill="none" stroke="{c}" stroke-width="{13*s}" stroke-linecap="round"/><path d="M {x+112*s},{y-66*s} l {14*s},{-22*s} l {6*s},{20*s} z" fill="{b}" stroke="{INK}" stroke-width="{4*s}" stroke-linejoin="round"/>')
        g.append(f'<path d="M {x-70*s},{y-10*s} Q {x-80*s},{y-150*s} {x},{y-170*s} Q {x+80*s},{y-150*s} {x+70*s},{y-10*s} Q {x},{y+10*s} {x-70*s},{y-10*s} Z" fill="{shade(c)}" stroke="{INK}" stroke-width="{sw}" stroke-linejoin="round"/>')
        for k in range(4):
            g.append(f'<path d="M {x-8*s},{y-(166-k*16)*s} l {8*s},{-14*s} l {8*s},{14*s}" fill="{b}" stroke="{INK}" stroke-width="{3.5*s}" stroke-linejoin="round" transform="translate({-40*s+k*3*s} {k*4*s}) rotate(-30 {x} {y-160*s})" opacity="0"/>')
        g.append(f'<ellipse cx="{x}" cy="{y-40*s}" rx="{38*s}" ry="{34*s}" fill="{shade(b)}"/>')
        for k in range(3):
            g.append(f'<path d="M {x-30*s},{y-(26+k*16)*s} Q {x},{y-(20+k*16)*s} {x+30*s},{y-(26+k*16)*s}" fill="none" stroke="#e8a83a" stroke-width="{3*s}"/>')
        for side in (-1, 1):
            g.append(f'<path d="M {x+side*26*s},{y-160*s} L {x+side*44*s},{y-214*s} L {x+side*8*s},{y-172*s} Z" fill="{shade("#fff6dd")}" stroke="{INK}" stroke-width="{5*s}" stroke-linejoin="round"/>')
            g.append(f'<ellipse cx="{x+side*30*s}" cy="{y-4*s}" rx="{22*s}" ry="{10*s}" fill="{shade(c)}" stroke="{INK}" stroke-width="{5*s}"/>')
            for t in (-1, 0, 1):
                g.append(f'<circle cx="{x+side*30*s+t*9*s}" cy="{y+4*s}" r="{3.5*s}" fill="#fff6dd" stroke="{INK}" stroke-width="{2*s}"/>')
        for k in range(5):
            px = x - 20 * s + k * 10 * s
            g.append(f'<circle cx="{px}" cy="{y-(150-abs(k-2)*4)*s}" r="{2.5*s}" fill="{dark(c,0.25)}" opacity="0.6"/>')
        g.append(eyes(x, y - 112 * s, s, "#ffb000"))
        g.append(f'<circle cx="{x+72*s}" cy="{y-112*s}" r="{13*s}" fill="#ffcf5a" opacity="0.9" filter="url(#soft1)"/><circle cx="{x+92*s}" cy="{y-126*s}" r="{8*s}" fill="#fff3b0"/>')
        g.append(gloss(x - 26 * s, y - 142 * s, 22 * s, 10 * s))
    return "".join(g)


def spark(x, y, s, color="#fff8c4"):
    return (f'<g transform="translate({x} {y}) scale({s})"><circle r="14" fill="{color}" opacity="0.5" filter="url(#soft1)"/>'
            f'<path d="M0,-18 C2,-4 4,-2 18,0 C4,2 2,4 0,18 C-2,4 -4,2 -18,0 C-4,-2 -2,-4 0,-18Z" fill="{color}"/></g>')


def cloud(x, y, s):
    return (f'<g transform="translate({x} {y}) scale({s})">'
            '<g fill="#cfe3ff"><ellipse cx="6" cy="14" rx="96" ry="40"/><circle cx="-46" cy="4" r="42"/><circle cx="76" cy="8" r="40"/></g>'
            '<g fill="#ffffff"><ellipse cx="0" cy="0" rx="90" ry="40"/><circle cx="-50" cy="-12" r="42"/><circle cx="20" cy="-40" r="56"/><circle cx="70" cy="-8" r="40"/></g>'
            '<g fill="#ffffff" opacity="0.9"><circle cx="8" cy="-58" r="20"/><circle cx="-60" cy="-26" r="14"/></g></g>')


def tree(x, y, s, far=False):
    if far:
        return f'<g transform="translate({x} {y}) scale({s})" fill="#86b8d9"><rect x="-6" y="-4" width="12" height="40" rx="4"/><circle cx="0" cy="-30" r="36"/><circle cx="-22" cy="-14" r="24"/><circle cx="22" cy="-16" r="24"/></g>'
    return (f'<g transform="translate({x} {y}) scale({s})">'
            f'<rect x="-11" y="-12" width="22" height="64" rx="7" fill="{shade("#a0683a")}" stroke="{INK}" stroke-width="5"/>'
            f'<circle cx="0" cy="-42" r="54" fill="{shade("#45b553")}" stroke="{INK}" stroke-width="5"/>'
            f'<circle cx="-30" cy="-18" r="34" fill="{shade("#3aa14a")}" stroke="{INK}" stroke-width="5"/>'
            f'<circle cx="28" cy="-24" r="34" fill="{shade("#4cbb58")}" stroke="{INK}" stroke-width="5"/>'
            f'<circle cx="-14" cy="-62" r="20" fill="#8be37a" opacity="0.8"/>'
            f'<circle cx="16" cy="-30" r="5" fill="#ff5c6c"/><circle cx="-30" cy="-30" r="5" fill="#ff5c6c"/><circle cx="4" cy="-74" r="5" fill="#ff5c6c"/></g>')


def grass_blades(x0, x1, y_at, count, colors, h=(14, 26)):
    out = []
    for _ in range(count):
        x = random.uniform(x0, x1)
        y = y_at(x) + random.uniform(-2, 8)
        hh = random.uniform(*h)
        lean = random.uniform(-6, 6)
        out.append(f'<path d="M {x-3},{y} Q {x+lean*0.5},{y-hh*0.6} {x+lean},{y-hh} Q {x+1+lean*0.3},{y-hh*0.5} {x+3},{y} Z" fill="{random.choice(colors)}"/>')
    return "".join(out)


def flower(x, y, s, petal):
    out = [f'<g transform="translate({x} {y}) scale({s})"><path d="M0,0 L0,18" stroke="#2f8a3a" stroke-width="3"/>']
    for k in range(5):
        a = k * 72
        out.append(f'<ellipse cx="0" cy="-8" rx="5" ry="8" fill="{petal}" transform="rotate({a})"/>')
    out.append('<circle r="5" fill="#ffd23f"/></g>')
    return "".join(out)


parts = []


def hill_y(x, base, amp, freq, phase):
    return base + math.sin(x * freq + phase) * amp


parts.append('<rect width="1920" height="1080" fill="url(#sky)"/>')
# sun with soft rays
parts.append('<g transform="translate(1730 140)">' + "".join(
    f'<path d="M0,0 L{math.cos(math.radians(a))*700},{math.sin(math.radians(a))*700} L{math.cos(math.radians(a+6))*700},{math.sin(math.radians(a+6))*700} Z" fill="#fff7c2" opacity="0.18"/>'
    for a in range(0, 360, 20)) + '<circle r="170" fill="#fff6a8" opacity="0.55" filter="url(#blur)"/><circle r="90" fill="url(#sun)"/><circle cx="-26" cy="-26" r="26" fill="#ffffff" opacity="0.5"/></g>')
parts.append(cloud(240, 175, 1.25) + cloud(1390, 120, 0.95) + cloud(990, 270, 0.7) + cloud(560, 330, 0.62) + cloud(1880, 330, 0.6))
# far hills (blue haze) with tiny trees
far = "M0,600 " + " ".join(f"L{x},{hill_y(x, 590, 34, 0.004, 1.2):.1f}" for x in range(0, 1921, 40)) + " L1920,1080 L0,1080 Z"
parts.append(f'<path d="{far}" fill="#9fd0ea"/>')
for x in range(40, 1920, 95):
    parts.append(tree(x + random.uniform(-20, 20), hill_y(x, 590, 34, 0.004, 1.2) + 4, random.uniform(0.32, 0.45), True))
# mid hills
mid = "M0,650 C260,530 520,570 760,630 C1000,690 1240,530 1500,570 C1700,600 1820,570 1920,590 L1920,1080 L0,1080 Z"
parts.append(f'<path d="{mid}" fill="{vshade("#93e56c", "#5cbf48")}"/>')
for tx, ty, ts in ((120, 650, 1), (640, 612, 0.82), (1560, 572, 0.92), (1850, 610, 0.72), (360, 600, 0.6)):
    parts.append(tree(tx, ty, ts))
# front ground with the path
front = "M0,770 C320,710 620,750 960,770 C1300,790 1600,730 1920,750 L1920,1080 L0,1080 Z"
parts.append(f'<path d="{front}" fill="{vshade("#72d653", "#3c9e37")}"/>')
parts.append(f'<path d="M760,1080 C820,940 900,860 1010,782 L1080,782 C1010,872 980,962 1000,1080 Z" fill="{vshade("#f6d998", "#e2b56a")}"/>')
for _ in range(26):
    px = random.uniform(800, 1060)
    py = random.uniform(800, 1070)
    if 760 + (1080 - py) * 0.2 < px < 1000 + (py - 780) * 0.05:
        parts.append(f'<ellipse cx="{px}" cy="{py}" rx="{random.uniform(6,14)}" ry="{random.uniform(4,8)}" fill="#c99a58" opacity="0.7"/>')
# grass blades along the hill tops and in the front, and flowers
parts.append(grass_blades(0, 1920, lambda x: 770 - 40 * math.sin(x / 300) * 0 + (0 if x < 0 else 0) + (-60 if 300 < x < 700 else -20 if x > 1200 else -10), 0, ["#3c9e37"]))
parts.append(grass_blades(0, 1920, lambda x: 1080 - random.uniform(0, 260), 420, ["#2f8a33", "#4cb843", "#5fca4c", "#86de69"]))
for _ in range(34):
    x, y = random.uniform(20, 1900), random.uniform(820, 1060)
    if not (740 < x < 1060):
        parts.append(flower(x, y, random.uniform(0.7, 1.2), random.choice(["#ffffff", "#ffd1e6", "#fff38a", "#c9b6ff"])))
# pets parade on the right
for kind, x, y, s, glow in [("dragon", 1600, 700, 1.25, "#ff7ad9"), ("cat", 1130, 930, 1.05, "#7dffa8"), ("bunny", 1330, 950, 1.05, "#7fd2ff"), ("dog", 1530, 930, 1.1, "#c58bff"), ("penguin", 1725, 960, 1.05, "#ffd65c")]:
    parts.append(pet(kind, x, y, s, glow))
from bacon import bacon_head, HAIR_GRADIENT
defs.append(HAIR_GRADIENT)
BACON_BEHIND, BACON_FRONT = bacon_head(92, -10, 146, shade("#f4f4f4", "35%", "25%", "85%"))
# the player: the classic bacon hair (white skin, swept orange-brown bacon
# hair, the default smile, an open black jacket over a blue shirt)
SKIN, HAIR, JACKET, SHIRT, PANTS = "#f4f4f4", "#c8641e", "#26262e", "#2f6fe0", "#2b2b33"
parts.append(f'''<g transform="translate(290 500) scale(1.16)">
<ellipse cx="90" cy="432" rx="160" ry="28" fill="#1f5a26" opacity="0.4" filter="url(#soft1)"/>
{BACON_BEHIND}
<rect x="24" y="300" width="64" height="128" rx="12" fill="{shade(PANTS)}" stroke="{INK}" stroke-width="9"/>
<rect x="94" y="300" width="64" height="128" rx="12" fill="{shade(dark(PANTS, 0.1))}" stroke="{INK}" stroke-width="9"/>
<rect x="16" y="404" width="76" height="30" rx="12" fill="{shade("#3a3a44")}" stroke="{INK}" stroke-width="8"/><rect x="90" y="404" width="76" height="30" rx="12" fill="{shade("#3a3a44")}" stroke="{INK}" stroke-width="8"/>
<rect x="10" y="150" width="162" height="162" rx="18" fill="{shade(JACKET)}" stroke="{INK}" stroke-width="9"/>
<path d="M 62,152 L 120,152 L 116,310 L 66,310 Z" fill="{shade(SHIRT)}"/>
<path d="M 62,152 L 46,196 L 70,206 Z M 120,152 L 136,196 L 112,206 Z" fill="{shade("#3a3a46")}" stroke="{INK}" stroke-width="4" stroke-linejoin="round"/>
<path d="M 64,152 L 66,310 M 118,152 L 116,310" stroke="{INK}" stroke-width="5"/>
<rect x="24" y="162" width="30" height="10" rx="5" fill="#ffffff" opacity="0.18"/>
<g transform="rotate(-24 -6 172)"><rect x="-60" y="160" width="58" height="126" rx="14" fill="{shade(JACKET)}" stroke="{INK}" stroke-width="9"/><rect x="-56" y="270" width="50" height="40" rx="14" fill="{shade(SKIN)}" stroke="{INK}" stroke-width="8"/></g>
<g transform="rotate(-145 184 172)"><rect x="156" y="160" width="58" height="126" rx="14" fill="{shade(JACKET)}" stroke="{INK}" stroke-width="9"/><rect x="160" y="270" width="50" height="40" rx="14" fill="{shade(SKIN)}" stroke="{INK}" stroke-width="8"/></g>
{BACON_FRONT}

</g>''')
# motion trail and the dice
parts.append('<g stroke-linecap="round" fill="none"><path d="M 600 470 Q 680 400 760 400" stroke="#ffffff" stroke-width="12" opacity="0.85"/><path d="M 610 520 Q 690 470 770 470" stroke="#fff6c2" stroke-width="10" opacity="0.8"/><path d="M 600 420 Q 660 350 740 340" stroke="#ffffff" stroke-width="8" opacity="0.7"/></g>')
for k in range(9):
    t = k / 8
    parts.append(spark(620 + t * 150, 470 - math.sin(t * 3) * 40, 0.4 + t * 0.4, "#fff6c2"))
parts.append(f'''<g transform="translate(900 410) rotate(-16)" filter="url(#glow)">
<circle r="180" fill="#fff6a8" opacity="0.65" filter="url(#blur)"/>
<path d="M -110,-60 L -30,-130 L 130,-130 L 50,-60 Z" fill="{vshade("#ffffff", "#dfe8ff")}" stroke="{INK}" stroke-width="10" stroke-linejoin="round"/>
<path d="M 50,-60 L 130,-130 L 130,40 L 50,110 Z" fill="{vshade("#b8c9f5", "#8098dc")}" stroke="{INK}" stroke-width="10" stroke-linejoin="round"/>
<rect x="-110" y="-60" width="160" height="170" rx="22" fill="{shade("#f7faff", "30%", "25%", "90%")}" stroke="{INK}" stroke-width="10"/>
<path d="M -88,-40 Q -60,-50 -20,-46" stroke="#ffffff" stroke-width="10" stroke-linecap="round" fill="none"/>
''' + "".join(f'<circle cx="{px}" cy="{py}" r="17" fill="{shade("#2a3da8", "40%", "35%")}"/><circle cx="{px-5}" cy="{py-5}" r="5" fill="#8fa2ff" opacity="0.8"/>' for px, py in ((-70, -20), (10, -20), (-30, 25), (-70, 70), (10, 70))) +
f'''<ellipse cx="40" cy="-95" rx="16" ry="9" fill="#1f2f8a"/><ellipse cx="90" cy="-20" rx="9" ry="16" fill="#3d4fa8"/><ellipse cx="90" cy="40" rx="9" ry="16" fill="#3d4fa8"/>
</g>''')
for x, y, sz, col in ((780, 255, 1.8, "#fff8c4"), (1060, 300, 1.3, "#ffffff"), (1040, 560, 1.5, "#fff8c4"), (720, 590, 1.0, "#ffffff"), (1180, 470, 1.1, "#fff8c4"), (300, 420, 1.2, "#ffffff"), (1880, 440, 1.4, "#fff8c4"), (1450, 330, 1.0, "#ffffff")):
    parts.append(spark(x, y, sz, col))
# the pet's chance, big and rainbow, above the rare dragon
from chance import chance, defs as chance_defs
parts.append(chance("1/999,999,999", 1488, 392, 122, -4, "odds"))
# the title: 3D extrusion, gradient face, a shine band, sparkles
title = []
for d in range(14, 0, -2):
    title.append(f'<text x="-130" y="{d}" font-family="Lilita" font-size="210" text-anchor="middle" fill="{mix("#b35a00", INK, 0.4)}" stroke="{INK}" stroke-width="22" stroke-linejoin="round" paint-order="stroke">ROLL PETS</text>')
title.append('<text x="-130" y="0" font-family="Lilita" font-size="210" text-anchor="middle" fill="url(#title)" stroke="#1d2140" stroke-width="20" stroke-linejoin="round" paint-order="stroke">ROLL PETS</text>')
title.append('<text x="-130" y="0" font-family="Lilita" font-size="210" text-anchor="middle" fill="url(#shine)">ROLL PETS</text>')
parts.append('<g transform="translate(960 175)">' + "".join(title) + f'''
<g transform="translate(560 30) rotate(-8)">
<rect x="-150" y="-128" width="300" height="170" rx="40" fill="#3b1a7a" stroke="{INK}" stroke-width="16"/>
<rect x="-150" y="-140" width="300" height="170" rx="40" fill="url(#rng)" stroke="{INK}" stroke-width="16"/>
<rect x="-126" y="-124" width="252" height="40" rx="20" fill="#ffffff" opacity="0.28"/>
<text x="0" y="-8" font-family="Lilita" font-size="150" text-anchor="middle" fill="#ffffff" stroke="{INK}" stroke-width="16" stroke-linejoin="round" paint-order="stroke">RNG</text>
</g></g>''')
parts.append(spark(430, 70, 1.4, "#ffffff") + spark(1290, 210, 1.2, "#fff8c4") + spark(860, 40, 0.9, "#ffffff"))
# painted feel: a soft vignette and a fine brush grain over everything
parts.append('<rect width="1920" height="1080" fill="url(#vignette)"/>')
parts.append('<rect width="1920" height="1080" filter="url(#grain)" opacity="0.10"/>')

head = f'''<defs>
<linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#3fb4ff"/><stop offset="0.6" stop-color="#8fd8ff"/><stop offset="1" stop-color="#d6f5ff"/></linearGradient>
<radialGradient id="sun" cx="40%" cy="40%" r="60%"><stop offset="0" stop-color="#fffbd0"/><stop offset="1" stop-color="#ffd23f"/></radialGradient>
<linearGradient id="title" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff59a"/><stop offset="0.5" stop-color="#ffc21f"/><stop offset="1" stop-color="#ff7a00"/></linearGradient>
<linearGradient id="shine" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#ffffff" stop-opacity="0"/><stop offset="0.28" stop-color="#ffffff" stop-opacity="0"/><stop offset="0.3" stop-color="#ffffff" stop-opacity="0.55"/><stop offset="0.42" stop-color="#ffffff" stop-opacity="0.15"/><stop offset="0.44" stop-color="#ffffff" stop-opacity="0"/></linearGradient>
<linearGradient id="rng" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#ff7ae0"/><stop offset="1" stop-color="#7a45ff"/></linearGradient>
<radialGradient id="vignette" cx="50%" cy="50%" r="75%"><stop offset="0.7" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#0a1a40" stop-opacity="0.35"/></radialGradient>
<filter id="blur" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="22"/></filter>
<filter id="soft1" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="2.5"/></filter>
<filter id="soft2" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="1.5"/></filter>
<filter id="glow" x="-30%" y="-30%" width="160%" height="160%"><feGaussianBlur stdDeviation="8" result="b"/><feMerge><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge></filter>
<filter id="grain" x="0" y="0" width="100%" height="100%"><feTurbulence type="fractalNoise" baseFrequency="0.85" numOctaves="2" seed="4"/><feColorMatrix type="saturate" values="0"/></filter>
{"".join(defs)}{chance_defs("odds")}
</defs>'''
svg = '<svg width="1920" height="1080" viewBox="0 0 1920 1080" xmlns="http://www.w3.org/2000/svg">' + head + "".join(parts) + '</svg>'
html = '<!doctype html><html><head><meta charset="utf-8"><style>@font-face{font-family:"Lilita";src:url("lilita.ttf");}html,body{margin:0;padding:0;}svg{display:block;}</style></head><body>' + svg + '</body></html>'
open("thumbnail.html", "w").write(html)
