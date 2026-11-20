"""Shared pixel-drawing helpers for the boot art (GRUB theme, syslinux splash).

Text is drawn glyph by glyph in IBM VGA 8x16 (or its 2x face, or Jacquard 24
for titles), without anti-aliasing, and any glyph the face lacks comes from GNU
Unifont, so a missing letter still lands on the same 8x16 pixel grid. Colours
come from the haiiro palette (theme/haiiro.nix as JSON).
"""

import json

from fontTools.ttLib import TTFont
from PIL import Image, ImageDraw, ImageFont


def load_palette(path):
    with open(path) as f:
        return json.load(f)


def rgb(hexcode, alpha=255):
    h = hexcode.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), alpha)


def mix(a, b, t):
    """a over b at opacity t, both #rrggbb."""
    ca, cb = rgb(a), rgb(b)
    return "#%02x%02x%02x" % tuple(round(ca[i] * t + cb[i] * (1 - t)) for i in range(3))


class Face:
    """A TrueType face plus the codepoints it has, for per-glyph fallback."""

    def __init__(self, path, size):
        self.font = ImageFont.truetype(path, size)
        self.cmap = set(TTFont(path, lazy=True).getBestCmap())

    def has(self, ch):
        return ord(ch) in self.cmap


class Type:
    """A face with fallbacks: draws and measures text, glyph by glyph."""

    def __init__(self, *faces):
        self.faces = faces

    def face(self, ch):
        for f in self.faces:
            if f.has(ch):
                return f
        return self.faces[0]

    def width(self, text):
        return sum(self.face(c).font.getlength(c) for c in text)

    def draw(self, img, x, y, text, fill, shadow=None):
        """Draw text with its top at y. `shadow` is (dx, dy, colour)."""
        d = ImageDraw.Draw(img)
        d.fontmode = "1"
        for pass_ in ([shadow] if shadow else []) + [None]:
            cx = x
            for ch in text:
                f = self.face(ch).font
                if pass_:
                    d.text((cx + pass_[0], y + pass_[1]), ch, font=f, fill=pass_[2], anchor="la")
                else:
                    d.text((cx, y), ch, font=f, fill=fill, anchor="la")
                cx += f.getlength(ch)
        return x + self.width(text)


def double_frame(w, h, pine, surface):
    """A haiiro window: 5px double frame (2 + 1 + 2) in pine over a surface fill."""
    img = Image.new("RGBA", (w, h), rgb(surface))
    px = img.load()
    for y in range(h):
        for x in range(w):
            m = min(x, y, w - 1 - x, h - 1 - y)
            if m < 2 or 3 <= m < 5:
                px[x, y] = rgb(pine)
    return img


def slice9(img, edge):
    """Cut an image into GRUB's nine pixmap pieces with `edge`-sized margins."""
    w, h = img.size
    xs = [0, edge, w - edge, w]
    ys = [0, edge, h - edge, h]
    names = ["nw", "n", "ne", "w", "c", "e", "sw", "s", "se"]
    out = {}
    for i, name in enumerate(names):
        r, c = divmod(i, 3)
        out[name] = img.crop((xs[c], ys[r], xs[c + 1], ys[r + 1]))
    return out
