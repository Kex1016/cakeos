"""Draws the haiiro GRUB theme: theme.txt and every picture it uses.

The look is the login screen's: live-blobs night sky, a Jacquard 24 title, a
prompt line and one line of narration, and a haiiro Window (5px double pine
frame, a notched label, a hairline footer of key hints) holding the entries,
each a selected-row band with a rose » in front. Everything is pixel-exact at
1:1 (IBM VGA 8x16, doubled to 32px for the entries), so the theme draws the
static parts as pictures and leaves GRUB only the entries, the countdown and
the scrollbar.

    python3 grub-art.py OUT PALETTE.json IBM.ttf JACQUARD.ttf UNIFONT.otf
"""

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from blobs import render as render_blobs  # noqa: E402
from PIL import Image, ImageDraw  # noqa: E402
from pixel import Face, Type, double_frame, load_palette, mix, rgb, slice9  # noqa: E402

out, palette_path, ibm_path, jacquard_path, unifont_path = sys.argv[1:6]
c = load_palette(palette_path)
os.makedirs(out, exist_ok=True)

ibm = Type(Face(ibm_path, 16), Face(unifont_path, 16))
ibm2 = Type(Face(ibm_path, 32), Face(unifont_path, 32))
title_face = Type(Face(jacquard_path, 96), Face(ibm_path, 96))

W = 640  # panel-width: the window
ROW = 40  # one entry
ROWS = 6
PAD = 8  # between the frame and the content
EDGE = 5  # the frame
GAP = 8  # between a Window and what sits next to it
TOP = EDGE + PAD + 8  # clears the notch
BAR_H = 10
BAR_PAD = 9  # transparent rows GRUB adds around a progress bar (it will not go below 28px)
INNER = W - 2 * (EDGE + PAD)

hairline = mix(c["text"], c["surface"], 0.25)
muted_ink = mix(c["text"], c["surface"], 0.55)
track = mix(c["text"], c["base"], 0.14)


def save(img, name):
    img.save(os.path.join(out, name))


# -- background: the blobs, 1920x1200 so the two commonest modes need no scaling
render_blobs(1920, 1200).convert("RGB").save(os.path.join(out, "background.png"))

# -- the window: frame, notch, hairline and key hints, as one picture
menu_h = ROWS * ROW
foot_y = TOP + menu_h + GAP
H = foot_y + 1 + 8 + 16 + 8 + PAD  # hairline, padding, text, padding, bottom
win = double_frame(W, H, c["pine"], c["surface"])
d = ImageDraw.Draw(win)
d.rectangle([EDGE + PAD, foot_y, W - EDGE - PAD - 1, foot_y], fill=rgb(hairline))

# the label notched into the top edge, like `fish: ~/about`
label = "grub: ~/boot"
nx = 24
nw = int(ibm.width(label)) + 16
d.rectangle([nx, 0, nx + nw - 1, 15], fill=rgb(c["surface"]))
ibm.draw(win, nx + 8, 0, label, rgb(c["foam"]))


def keyhint(img, x, y, key, text):
    """A keycap (1px hairline box) and what it does."""
    kw = int(ibm.width(key)) + 8
    d = ImageDraw.Draw(img)
    d.rectangle([x, y, x + kw - 1, y + 17], outline=rgb(muted_ink))
    ibm.draw(img, x + 4, y + 1, key, rgb(c["subtle"]))
    ibm.draw(img, x + kw + 8, y + 1, text, rgb(muted_ink))
    return x + kw + 8 + int(ibm.width(text)) + 24


fx = EDGE + PAD
fy = foot_y + 1 + 6
for key, text in (("enter", "boot"), ("e", "edit"), ("c", "command line")):
    fx = keyhint(win, fx, fy, key, text)
save(win, "window.png")

# -- the header: title, prompt line, narration (transparent, over the blobs)
HEAD_H = 150
head = Image.new("RGBA", (W, HEAD_H), (0, 0, 0, 0))
title = "cakeos"
tw = int(title_face.width(title))
title_face.draw(
    head, (W - tw) // 2, 0, title, rgb(c["text"]), shadow=(6, 6, rgb(c["base"]))
)
parts = [
    ("@", c["love"]), (" ", None), ("~/boot", c["foam"]), (" ", None),
    ("»", c["rose"]), (" ", None), ("./wake.sh", c["iris"]),
]
pw = int(sum(ibm.width(t) for t, _ in parts))
px_ = (W - pw) // 2
for t, col in parts:
    if col:
        ibm.draw(head, px_, 104, t, rgb(col), shadow=(1, 1, rgb(c["base"])))
    px_ += int(ibm.width(t))
narr = "The computer hums. Choose how to wake it."
ibm.draw(
    head, (W - int(ibm.width(narr))) // 2, 128, narr, rgb(c["rose"]),
    shadow=(1, 1, rgb(c["base"])),
)
save(head, "header.png")

# -- window pieces for the terminal box (command line, editor): frame + padding
box = double_frame(3 * (EDGE + PAD) + 2, 3 * (EDGE + PAD) + 2, c["pine"], c["surface"])
for name, piece in slice9(box, EDGE + PAD).items():
    save(piece, f"terminal_box_{name}.png")

# -- the selected row: an overlay band with a rose » in front
SEL_L = 32
w_ = Image.new("RGBA", (SEL_L, ROW), rgb(c["overlay"]))
ibm2.draw(w_, 8, 4, "»", rgb(c["rose"]))
save(w_, "select_w.png")
save(Image.new("RGBA", (1, ROW), rgb(c["overlay"])), "select_c.png")
save(Image.new("RGBA", (8, ROW), rgb(c["overlay"])), "select_e.png")

# -- the countdown bar: a 10px hairline track filled with text colour. GRUB
# gives a progress bar at least 28px, so it is a 9-slice with transparent
# 9px top and bottom pieces and the visible bar in the middle row.
def bar(name, border, fill):
    clear = (0, 0, 0, 0)
    for piece in ("nw", "n", "ne", "sw", "s", "se"):
        save(Image.new("RGBA", (1, BAR_PAD), clear), f"{name}_{piece}.png")
    for piece in ("w", "e"):
        save(Image.new("RGBA", (1, BAR_H), rgb(border)), f"{name}_{piece}.png")
    mid = Image.new("RGBA", (1, BAR_H), rgb(fill))
    mid.putpixel((0, 0), rgb(border))
    mid.putpixel((0, BAR_H - 1), rgb(border))
    save(mid, f"{name}_c.png")


bar("track", c["text"], track)
bar("bar", c["text"], c["text"])

# -- the scrollbar: foam thumb on a muted track, square
for p in ("n", "c", "s"):
    save(Image.new("RGBA", (6, 1), rgb(c["muted"])), f"scroll_track_{p}.png")
    save(Image.new("RGBA", (6, 1), rgb(c["foam"])), f"scroll_thumb_{p}.png")

# -- theme.txt. GRUB paints components last-declared first, so the pictures
# the entries sit on come last.
TOTAL = HEAD_H + GAP + H + 20 + BAR_H
top = f"50%-{TOTAL // 2}"
win_top = HEAD_H + GAP
bar_top = win_top + H + 20 - BAR_PAD
open(os.path.join(out, "theme.txt"), "w").write(f"""\
title-text: ""
desktop-image: "background.png"
desktop-image-scale-method: "crop"
desktop-color: "{c['base']}"
message-font: "IBM Regular 16"
message-color: "{c['text']}"
terminal-font: "IBM Regular 16"
terminal-box: "terminal_box_*.png"
terminal-left: "50%-{W // 2}"
terminal-top: "10%"
terminal-width: "{W}"
terminal-height: "80%"
terminal-border: "{EDGE + PAD}"

+ boot_menu {{
    left = 50%-{INNER // 2}
    top = {top}+{win_top + EDGE + PAD + 8}
    width = {INNER}
    height = {menu_h}
    item_font = "IBM2x Regular 32"
    selected_item_font = "IBM2x Regular 32"
    item_color = "{c['text']}"
    selected_item_color = "{c['text']}"
    selected_item_pixmap_style = "select_*.png"
    item_height = {ROW}
    item_padding = 0
    item_spacing = 0
    icon_width = 0
    icon_height = 0
    item_icon_space = 0
    scrollbar = true
    scrollbar_slice = "center"
    scrollbar_left_pad = 8
    scrollbar_width = 6
    scrollbar_frame = "scroll_track_*.png"
    scrollbar_thumb = "scroll_thumb_*.png"
}}

+ label {{
    id = "__timeout__"
    left = 50%
    top = {top}+{win_top + foot_y + 1 + 8}
    width = {W // 2 - EDGE - PAD - 8}
    height = 16
    text = "booting in %d seconds"
    align = "right"
    font = "IBM Regular 16"
    color = "{muted_ink}"
}}

+ progress_bar {{
    id = "__timeout__"
    left = 50%-{W // 2}
    top = {top}+{bar_top}
    width = {W}
    height = {BAR_H + 2 * BAR_PAD}
    show_text = false
    font = "IBM Regular 16"
    text_color = "{c['text']}"
    bar_style = "track_*.png"
    highlight_style = "bar_*.png"
    highlight_overlay = true
}}

+ image {{
    left = 50%-{W // 2}
    top = {top}+{win_top}
    file = "window.png"
}}

+ image {{
    left = 50%-{W // 2}
    top = {top}
    file = "header.png"
}}
""")
