# The classic bacon hair head, drawn in a 100-wide box (x -50..50, the head
# from y 0 to 100), placed with translate + scale. Returns (behind, front):
# the hair's back volume (drawn before the head) and the head itself with
# the hair's front locks and the default smile.
INK = "#1d2140"
H, HL, HD = "#c8641e", "#f0a060", "#7e3a10"

def bacon_head(cx, top, width, skin_fill):
    s = width / 100.0
    t = f'translate({cx} {top}) scale({s})'
    behind = f'''<g transform="{t}">
<path d="M -60,62 Q -68,22 -46,-2 Q -20,-24 12,-20 Q 48,-18 62,4 Q 72,30 64,62 Q 56,52 50,58 L -50,58 Q -56,54 -60,62 Z" fill="url(#baconHair)" stroke="{INK}" stroke-width="5" stroke-linejoin="round"/>
</g>'''
    front = f'''<g transform="{t}">
<rect x="-50" y="0" width="100" height="100" rx="22" fill="{skin_fill}" stroke="{INK}" stroke-width="6"/>
<path d="M -58,48 Q -70,14 -48,-6 Q -42,-20 -26,-18 Q -16,-32 2,-26 Q 18,-34 34,-22 Q 52,-20 58,-2 Q 70,14 62,38 Q 56,30 50,34 Q 48,22 38,24 Q 32,38 20,32 Q 12,20 0,26 Q -8,40 -20,34 Q -28,24 -38,32 Q -44,42 -52,40 Q -54,44 -58,48 Z" fill="url(#baconHair)" stroke="{INK}" stroke-width="5" stroke-linejoin="round"/>
<path d="M -56,36 Q -70,52 -62,66 Q -68,78 -60,90 Q -54,80 -48,82 Q -44,68 -48,58 Q -42,48 -46,40 Z" fill="url(#baconHair)" stroke="{INK}" stroke-width="5" stroke-linejoin="round"/>
<path d="M 56,30 Q 70,46 62,62 Q 68,74 62,88 Q 56,78 50,80 Q 46,66 50,56 Q 44,46 46,36 Z" fill="url(#baconHair)" stroke="{INK}" stroke-width="5" stroke-linejoin="round"/>
<path d="M -42,0 Q -24,-14 -4,-12" stroke="{HL}" stroke-width="5" fill="none" stroke-linecap="round"/>
<path d="M 8,-16 Q 28,-20 44,-6" stroke="{HL}" stroke-width="5" fill="none" stroke-linecap="round"/>
<path d="M -50,22 Q -30,4 -8,8" stroke="{HL}" stroke-width="4" fill="none" stroke-linecap="round"/>
<path d="M 4,8 Q 26,0 50,16" stroke="{HL}" stroke-width="4" fill="none" stroke-linecap="round"/>
<path d="M -20,34 Q -18,16 -6,4" stroke="{HD}" stroke-width="3.2" fill="none" stroke-linecap="round"/>
<path d="M 20,32 Q 18,16 28,4" stroke="{HD}" stroke-width="3.2" fill="none" stroke-linecap="round"/>
<path d="M 38,24 Q 42,10 50,4" stroke="{HD}" stroke-width="3" fill="none" stroke-linecap="round"/>
<path d="M -38,32 Q -36,18 -26,10" stroke="{HD}" stroke-width="3" fill="none" stroke-linecap="round"/>
<path d="M -4,-20 Q 6,-6 2,10" stroke="{HD}" stroke-width="3" fill="none" stroke-linecap="round" opacity="0.8"/>
<path d="M -60,52 Q -64,64 -58,76" stroke="{HL}" stroke-width="3.5" fill="none" stroke-linecap="round"/>
<path d="M 60,48 Q 64,60 58,72" stroke="{HL}" stroke-width="3.5" fill="none" stroke-linecap="round"/>
<ellipse cx="-16" cy="56" rx="5.5" ry="9" fill="#111111"/>
<ellipse cx="16" cy="56" rx="5.5" ry="9" fill="#111111"/>
<path d="M -21,72 Q 0,86 21,72" stroke="#111111" stroke-width="3.6" fill="none" stroke-linecap="round"/>
</g>'''
    return behind, front

HAIR_GRADIENT = f'<linearGradient id="baconHair" x1="0" y1="0" x2="0.4" y2="1"><stop offset="0" stop-color="#e48a40"/><stop offset="0.55" stop-color="{H}"/><stop offset="1" stop-color="#9a4614"/></linearGradient>'
