# The classic Roblox bacon hair head, drawn in a 100-wide box (x -50..50,
# the head from y 0 to 100), placed with translate + scale.
# Returns (behind, front): the hair's back volume (drawn before the head)
# and the head with the hair over it and the default smile.
#
# What makes it the bacon hair: an asymmetric, side-swept fringe falling
# diagonally from the crown across the forehead, chunky pointed locks along
# its edge angled the way it sweeps, one long side lock past the cheek
# flicking outward, a short tuft over the other ear, warm orange-brown with
# dark creases between the locks and light bands along each one.
INK = "#2a1a14"
MID, LIGHT, DARK, DEEP = "#c76a2b", "#eea25f", "#8f4518", "#5e2a0c"


def bacon_head(cx, top, width, skin_fill, outline=True):
    s = width / 100.0
    t = f'translate({cx} {top}) scale({s})'
    sw = 4.5 if outline else 0
    behind = f'''<g transform="{t}">
<path d="M -66,66 Q -78,22 -58,-8 Q -34,-36 4,-35 Q 44,-34 64,-10 Q 76,12 70,46 L 54,50 L -52,66 Z" fill="url(#baconHair)" stroke="{INK}" stroke-width="{sw}" stroke-linejoin="round"/>
</g>'''
    front = f'''<g transform="{t}">
<rect x="-50" y="0" width="100" height="100" rx="22" fill="{skin_fill}" stroke="{INK}" stroke-width="{sw + 1}"/>
<path d="M -42,54 Q -36,60 -30,62 Q -24,50 -16,46 Q -8,54 2,54 Q 6,42 16,38 Q 22,44 30,44 Q 34,32 44,30 Q 50,34 54,44 L 50,20 L -42,40 Z" fill="#000000" opacity="0.13"/>
<path d="M 50,10 Q 74,14 72,46 Q 66,54 57,48 Q 62,32 50,24 Z" fill="url(#baconHair)" stroke="{INK}" stroke-width="{sw}" stroke-linejoin="round"/>
<path d="M 60,40 Q 74,10 56,-14 Q 34,-37 0,-35 Q -38,-35 -61,-10 Q -77,14 -71,44 Q -69,62 -61,76 Q -67,85 -75,89 Q -56,91 -48,78 Q -42,64 -42,50 Q -38,56 -30,58 Q -26,46 -16,42 Q -8,50 2,50 Q 6,38 16,34 Q 22,40 30,40 Q 34,28 44,26 Q 52,30 56,40 Q 58,43 60,40 Z" fill="url(#baconHair)" stroke="{INK}" stroke-width="{sw}" stroke-linejoin="round"/>
<path d="M -2,-32 C -11,-6 -4,20 -16,42" stroke="{DARK}" stroke-width="3.8" fill="none" stroke-linecap="round"/>
<path d="M 26,-28 C 17,-2 26,18 16,34" stroke="{DARK}" stroke-width="3.8" fill="none" stroke-linecap="round"/>
<path d="M 46,-17 C 39,4 48,16 44,26" stroke="{DARK}" stroke-width="3.2" fill="none" stroke-linecap="round"/>
<path d="M -32,-28 C -48,-4 -40,30 -42,50" stroke="{DARK}" stroke-width="3.6" fill="none" stroke-linecap="round"/>
<path d="M -60,4 C -68,26 -62,52 -62,70" stroke="{DEEP}" stroke-width="2.4" fill="none" stroke-linecap="round" opacity="0.6"/>
<path d="M 56,18 C 66,24 66,36 62,44" stroke="{DARK}" stroke-width="2.6" fill="none" stroke-linecap="round" opacity="0.8"/>
<ellipse cx="-17" cy="-10" rx="7" ry="17" fill="{LIGHT}" opacity="0.75" transform="rotate(16 -17 -10)"/>
<ellipse cx="10" cy="-12" rx="7" ry="16" fill="{LIGHT}" opacity="0.75" transform="rotate(12 10 -12)"/>
<ellipse cx="35" cy="-8" rx="5.5" ry="13" fill="{LIGHT}" opacity="0.7" transform="rotate(14 35 -8)"/>
<ellipse cx="-50" cy="14" rx="5" ry="16" fill="{LIGHT}" opacity="0.7" transform="rotate(6 -50 14)"/>
<ellipse cx="-60" cy="58" rx="3.5" ry="9" fill="{LIGHT}" opacity="0.6"/>
<ellipse cx="62" cy="26" rx="3.5" ry="8" fill="{LIGHT}" opacity="0.6"/>
<ellipse cx="-14" cy="-24" rx="10" ry="4" fill="#ffffff" opacity="0.35" transform="rotate(-14 -14 -24)"/>
<ellipse cx="12" cy="-26" rx="8" ry="3.5" fill="#ffffff" opacity="0.3" transform="rotate(-6 12 -26)"/>
<ellipse cx="-14" cy="64" rx="5.5" ry="9" fill="#111111"/>
<ellipse cx="18" cy="64" rx="5.5" ry="9" fill="#111111"/>
<path d="M -19,79 Q 2,92 23,79" stroke="#111111" stroke-width="3.6" fill="none" stroke-linecap="round"/>
</g>'''
    return behind, front


HAIR_GRADIENT = ('<linearGradient id="baconHair" x1="0.2" y1="0" x2="0.5" y2="1">'
                 f'<stop offset="0" stop-color="#df8a45"/><stop offset="0.5" stop-color="{MID}"/><stop offset="1" stop-color="#a14f1c"/></linearGradient>')

if __name__ == "__main__":
    b, f = bacon_head(200, 110, 220, "#f4f4f4")
    open("bacon_test.html", "w").write('<!doctype html><html><body style="margin:0;background:#9fd0ea"><svg width="400" height="400" viewBox="0 0 400 400" xmlns="http://www.w3.org/2000/svg"><defs>' + HAIR_GRADIENT + '</defs>' + b + f + '</svg></body></html>')
