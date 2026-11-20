"""Builds the Linux console font: IBM VGA 8x16 as a PSF2 with a Unicode table.

The 256 glyphs of code page 437 come from IBM VGA, then Latin Extended-A (so
ő, ű and the rest of Hungarian and Central Europe), then a few more the
installer's TUI draws (rounded box corners, bullets, quotes, a check mark),
taken from IBM VGA where it has them and from GNU Unifont where not. Glyphs
Unifont only has 16 pixels wide are skipped; their codepoints are mapped onto
the nearest narrow glyph instead (a check mark onto the square-root sign).
The kernel takes up to 512.

    python3 console-font.py OUT.psf IBM.ttf UNIFONT.otf
"""

import struct
import sys

from fontTools.ttLib import TTFont
from PIL import Image, ImageDraw, ImageFont

out, ibm_path, unifont_path = sys.argv[1:4]

LOW = "\0☺☻♥♦♣♠•◘○◙♂♀♪♫☼►◄↕‼¶§▬↨↑↓→←∟↔▲▼"
cp437 = list(LOW) + [chr(i) for i in range(0x20, 0x7F)] + ["⌂"]
cp437 += list(bytes(range(0x80, 0x100)).decode("cp437"))
assert len(cp437) == 256

latin_ext_a = [chr(i) for i in range(0x100, 0x180)]
extras = list("╭╮╯╰┏┓┗┛━┃…‘’“”–—‹›‰€№™●◦▪▫✗") + [
    chr(i) for i in range(0x2500, 0x2580)
]
# Narrow stand-ins for codepoints no glyph is drawn for.
aliases = {"✓": "√", "✔": "√", "❯": "›", "❮": "‹", "—": "—", "‐": "-", "−": "-"}

ibm = ImageFont.truetype(ibm_path, 16)
uni = ImageFont.truetype(unifont_path, 16)
ibm_cmap = set(TTFont(ibm_path, lazy=True).getBestCmap())
uni_cmap = set(TTFont(unifont_path, lazy=True).getBestCmap())


def bitmap(font, ch):
    """The glyph as 16 rows of 8 bits, or None if it is wider than 8 pixels."""
    if font.getlength(ch) > 8:
        return None
    img = Image.new("1", (8, 16), 0)
    d = ImageDraw.Draw(img)
    d.fontmode = "1"
    d.text((0, 0), ch, font=font, fill=1, anchor="la")
    return bytes(
        sum(1 << (7 - x) for x in range(8) if img.getpixel((x, y))) for y in range(16)
    )


glyphs, table, seen = [], [], {}


def add(ch, bits):
    seen[ch] = len(glyphs)
    glyphs.append(bits)
    table.append([ch])


for ch in cp437:
    if ch == "\0":
        add(ch, bytes(16))  # glyph 0 is blank, not .notdef
    else:
        add(ch, bitmap(ibm, ch) if ord(ch) in ibm_cmap else bitmap(uni, ch))
for ch in latin_ext_a + extras:
    if len(glyphs) >= 512 or ch in seen:
        continue
    if ord(ch) in ibm_cmap:
        bits = bitmap(ibm, ch)
    elif ord(ch) in uni_cmap:
        bits = bitmap(uni, ch)
    else:
        continue
    if bits is not None and any(bits):
        add(ch, bits)
for ch, target in aliases.items():
    if ch not in seen and target in seen:
        table[seen[target]].append(ch)

body = b"".join(glyphs)
unicode_table = b"".join(
    b"".join(c.encode("utf-8") for c in chars) + b"\xff" for chars in table
)
header = struct.pack("<4s7I", b"\x72\xb5\x4a\x86", 0, 32, 1, len(glyphs), 16, 16, 8)
with open(out, "wb") as f:
    f.write(header + body + unicode_table)
print(f"{len(glyphs)} glyphs", file=sys.stderr)
