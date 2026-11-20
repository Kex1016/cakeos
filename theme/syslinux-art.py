"""Draws the haiiro splash for the ISO's BIOS (syslinux) menu: an 800x600 picture.

vesamenu.c32 prints the entries in its built-in 8x16 VGA font on top of this
picture, in cells of 8x16 pixels, so the picture carries everything else: the
live-blobs sky, the title, prompt line and narration, and a haiiro Window sized
around where the entries land (see systems/installer/theme.nix for the
`MENU` geometry that has to agree with the numbers here).

    python3 syslinux-art.py OUT.png PALETTE.json IBM.ttf JACQUARD.ttf UNIFONT.otf
"""

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from blobs import render as render_blobs  # noqa: E402
from PIL import Image, ImageDraw  # noqa: E402
from pixel import Face, Type, double_frame, load_palette, mix, rgb  # noqa: E402

out, palette_path, ibm_path, jacquard_path, unifont_path = sys.argv[1:6]
c = load_palette(palette_path)

ibm = Type(Face(ibm_path, 16), Face(unifont_path, 16))
title_face = Type(Face(jacquard_path, 72), Face(ibm_path, 72))

W, H = 800, 600
WIN_X, WIN_Y, WIN_W = 80, 192, 640  # panel-width
FIRST_ROW_Y = 216  # where vesamenu puts the first entry (rows sit 8px down: 8 + 16 * 13)
ROWS = 6
EDGE, PAD = 5, 8
foot_y = FIRST_ROW_Y + ROWS * 16 + 8  # hairline
WIN_H = foot_y - WIN_Y + 1 + 8 + 16 + 8 + PAD

hairline = mix(c["text"], c["surface"], 0.25)
muted_ink = mix(c["text"], c["surface"], 0.55)

img = render_blobs(W, H).convert("RGBA")

# header: title, prompt line, narration
tw = int(title_face.width("cakeos"))
title_face.draw(img, (W - tw) // 2, 24, "cakeos", rgb(c["text"]), shadow=(5, 5, rgb(c["base"])))
parts = [
    ("@", c["love"]), (" ", None), ("~/boot", c["foam"]), (" ", None),
    ("»", c["rose"]), (" ", None), ("./wake.sh", c["iris"]),
]
x = (W - int(sum(ibm.width(t) for t, _ in parts))) // 2
for t, col in parts:
    if col:
        ibm.draw(img, x, 120, t, rgb(col), shadow=(1, 1, rgb(c["base"])))
    x += int(ibm.width(t))
narr = "The computer hums. Choose how to wake it."
ibm.draw(img, (W - int(ibm.width(narr))) // 2, 144, narr, rgb(c["rose"]), shadow=(1, 1, rgb(c["base"])))

# the window, its notched label and its footer of key hints
win = double_frame(WIN_W, WIN_H, c["pine"], c["surface"])
d = ImageDraw.Draw(win)
fy = foot_y - WIN_Y
d.rectangle([EDGE + PAD, fy, WIN_W - EDGE - PAD - 1, fy], fill=rgb(hairline))
label = "syslinux: ~/boot"
nw = int(ibm.width(label)) + 16
d.rectangle([24, 0, 24 + nw - 1, 15], fill=rgb(c["surface"]))
ibm.draw(win, 32, 0, label, rgb(c["foam"]))
hx = EDGE + PAD
for key, text in (("enter", "boot"), ("tab", "edit")):
    kw = int(ibm.width(key)) + 8
    d.rectangle([hx, fy + 7, hx + kw - 1, fy + 7 + 17], outline=rgb(muted_ink))
    ibm.draw(win, hx + 4, fy + 8, key, rgb(c["subtle"]))
    ibm.draw(win, hx + kw + 8, fy + 8, text, rgb(muted_ink))
    hx += kw + 8 + int(ibm.width(text)) + 24
img.alpha_composite(win, (WIN_X, WIN_Y))

img.convert("RGB").save(out)
