# Game art

- `icon.png` (512x512): the game icon. A dice character with a rainbow luck ring and a bacon hair kid waving beside it, on a blue sunburst, with a NEW ribbon.
- `thumbnail.png` (1920x1080): the game thumbnail. A bacon hair player throwing a glowing dice, a parade of pets (cat, bunny, dog, penguin, dragon) on green hills, and the ROLL PETS RNG title.

Upload them on the Roblox Creator Hub: your game -> Configure -> Places -> the icon, and Thumbnails.

The sources are in `source/` (SVG drawn in `icon.html`, and `thumb2.py` writes `thumbnail.html`; both use the Lilita One font). Render with headless Chromium:
`headless_shell --window-size=512,512 --screenshot=icon.png file://.../icon.html`
