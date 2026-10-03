# Big rainbow "1/999,999,999" chance number, like the RNG game thumbnails.
INK = "#1d2140"
RAINBOW = ["#ff3b5c", "#ff8a1f", "#ffd21f", "#4fe05a", "#1fd2ff", "#4f6bff", "#c04fff"]

def defs(gid):
    stops = "".join(f'<stop offset="{i/(len(RAINBOW)-1):.3f}" stop-color="{c}"/>' for i, c in enumerate(RAINBOW))
    return (f'<linearGradient id="{gid}" x1="0" y1="0" x2="1" y2="0">{stops}</linearGradient>'
            f'<linearGradient id="{gid}Shine" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff" stop-opacity="0.75"/>'
            f'<stop offset="0.42" stop-color="#fff" stop-opacity="0.2"/><stop offset="0.46" stop-color="#fff" stop-opacity="0"/>'
            f'<stop offset="0.8" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="0.22"/></linearGradient>')

def clover(x, y, s):
    leaf = "M0,0 C-16,-6 -26,-26 -14,-36 C-6,-42 0,-34 0,-28 C0,-34 6,-42 14,-36 C26,-26 16,-6 0,0 Z"
    leaves = "".join(f'<path d="{leaf}" transform="rotate({a})" fill="#3fd25a" stroke="{INK}" stroke-width="5" stroke-linejoin="round"/>' for a in (0, 90, 180, 270))
    shines = "".join(f'<ellipse cx="-6" cy="-26" rx="4" ry="6" transform="rotate({a})" fill="#c8ffb0" opacity="0.8"/>' for a in (0, 90, 180, 270))
    return (f'<g transform="translate({x} {y}) scale({s}) rotate(-12)">'
            f'<path d="M4,6 Q12,30 4,44" stroke="{INK}" stroke-width="13" fill="none" stroke-linecap="round"/>'
            f'<path d="M4,6 Q12,30 4,44" stroke="#2fa845" stroke-width="5" fill="none" stroke-linecap="round"/>'
            f'{leaves}{shines}<circle r="6" fill="#2fa845" stroke="{INK}" stroke-width="3"/></g>')

def chance(text, x, y, size, rot, gid, depth=None, anchor="middle"):
    depth = depth if depth is not None else max(3, round(size * 0.09))
    sw = size * 0.17
    t = lambda dy, fill, extra="": (f'<text x="0" y="{dy}" font-family="Lilita" font-size="{size}" text-anchor="{anchor}" '
                                   f'fill="{fill}" {extra}>{text}</text>')
    g = [t(depth + size * 0.05, "#0a0f2e", f'stroke="#0a0f2e" stroke-width="{sw}" stroke-linejoin="round" opacity="0.35"')]
    for d in range(depth, 0, -max(1, depth // 6)):
        g.append(t(d, "#2a1a6b", f'stroke="{INK}" stroke-width="{sw}" stroke-linejoin="round" paint-order="stroke"'))
    g.append(t(0, f"url(#{gid})", f'stroke="{INK}" stroke-width="{sw}" stroke-linejoin="round" paint-order="stroke"'))
    g.append(t(0, f"url(#{gid}Shine)"))
    return f'<g transform="translate({x} {y}) rotate({rot})">' + "".join(g) + '</g>'
