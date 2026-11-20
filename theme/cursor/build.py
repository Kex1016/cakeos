"""Build the haiiro Xcursor theme (and optionally a preview sheet) from shapes.py.

    python3 build.py <out-dir>                 # <out-dir>/share/icons/haiiro
    python3 build.py --preview <file.png>      # every shape at 24/48 and 32/64
    python3 build.py --check <out-dir>         # read the built theme back

Standard library only. Each art pixel becomes a square block of device pixels,
copied as-is (nearest neighbour), so there is nothing to smooth.
"""

import os
import struct
import sys
import zlib

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import shapes  # noqa: E402

THEME = "haiiro"

# haiiro tokens (Rosé Pine main), as in the design system's tokens.json.
PALETTE = {
    "K": 0x191724,  # color-base: outline
    "W": 0xE0DEF4,  # color-text: fill
    "F": 0x9CCFD8,  # color-foam: crosshair centre, spinner trail
    "P": 0x31748F,  # color-pine: spinner trail
    "M": 0x6E6A86,  # color-muted: resting spinner blocks
    "L": 0xEB6F92,  # color-love: not-allowed
}

# Nominal size -> device pixels per art pixel. 24 draws one device pixel per
# art pixel, like the VGA font at 16px; 48 is 24 at 2x. 32 is the "large" size
# at 1x, and 64/96 are 32/48 at 2x, 72 is 24 at 3x. A size never gets a
# fractional scale: that is what would blur or unevenly stretch the pixels.
SIZES = {24: 1, 32: 2, 48: 2, 64: 4, 72: 3, 96: 4}

FRAME_MS = 120  # one step of the wait/progress spinners

# file name -> frames ([(rows, hotspot)]).
CURSORS = {
    "default": [shapes.ARROW],
    "pointer": [shapes.POINTER],
    "grab": [shapes.GRAB],
    "grabbing": [shapes.GRABBING],
    "text": [shapes.TEXT],
    "vertical-text": [shapes.VERTICAL_TEXT],
    "crosshair": [shapes.CROSSHAIR],
    "move": [shapes.MOVE],
    "ns-resize": [shapes.NS],
    "ew-resize": [shapes.EW],
    "nwse-resize": [shapes.NWSE],
    "nesw-resize": [shapes.NESW],
    "col-resize": [shapes.COL_RESIZE],
    "row-resize": [shapes.ROW_RESIZE],
    "not-allowed": [shapes.NOT_ALLOWED],
    "wait": shapes.WAIT,
    "progress": shapes.PROGRESS,
}

# Alias -> file it links to: CSS / cursor-shape-v1 names, then the X core and
# Qt/legacy names (including the hashes some toolkits ask for).
ALIASES = {
    # default
    "left_ptr": "default",
    "arrow": "default",
    "top_left_arrow": "default",
    "context-menu": "default",
    "help": "default",
    "question_arrow": "default",
    "whats_this": "default",
    "left_ptr_help": "default",
    "5c6cd98b3f3ebcb1f9c7f1c204630408": "default",
    "d9ce0ab605698f320427677b458ad60b": "default",
    "alias": "default",
    "copy": "default",
    "dnd-none": "default",
    "dnd-move": "default",
    "dnd-copy": "default",
    "dnd-link": "default",
    "dnd-ask": "default",
    "link": "default",
    "zoom-in": "crosshair",
    "zoom-out": "crosshair",
    "cell": "crosshair",
    "plus": "crosshair",
    "X_cursor": "default",
    "x-cursor": "default",
    # pointer
    "hand": "pointer",
    "hand1": "pointer",
    "hand2": "pointer",
    "pointing_hand": "pointer",
    "e29285e634086352946a0e7090d73106": "pointer",
    "9d800788f1b08800ae810202380a0822": "pointer",
    # grab
    "openhand": "grab",
    "fleur-open": "grab",
    "closedhand": "grabbing",
    "dnd-drag": "grabbing",
    # text
    "xterm": "text",
    "ibeam": "text",
    # crosshair
    "cross": "crosshair",
    "tcross": "crosshair",
    "cross_reverse": "crosshair",
    "diamond_cross": "crosshair",
    # move
    "fleur": "move",
    "all-scroll": "move",
    "size_all": "move",
    "4498f0e0c1937ffe01fd06f973665830": "move",
    "9081237383d90e509aa00f00170e968f": "move",
    # resize: an edge gets the double arrow along its axis
    "n-resize": "ns-resize",
    "s-resize": "ns-resize",
    "top_side": "ns-resize",
    "bottom_side": "ns-resize",
    "sb_v_double_arrow": "ns-resize",
    "v_double_arrow": "ns-resize",
    "double_arrow": "ns-resize",
    "size_ver": "ns-resize",
    "00008160000006810000408080010102": "ns-resize",
    "split_v": "row-resize",
    "sb_v_double_arrow_split": "row-resize",
    "e-resize": "ew-resize",
    "w-resize": "ew-resize",
    "left_side": "ew-resize",
    "right_side": "ew-resize",
    "sb_h_double_arrow": "ew-resize",
    "h_double_arrow": "ew-resize",
    "size_hor": "ew-resize",
    "028006030e0e7ebffc7f7070c0600140": "ew-resize",
    "split_h": "col-resize",
    "nw-resize": "nwse-resize",
    "se-resize": "nwse-resize",
    "top_left_corner": "nwse-resize",
    "bottom_right_corner": "nwse-resize",
    "size_fdiag": "nwse-resize",
    "bd_double_arrow": "nwse-resize",
    "ne-resize": "nesw-resize",
    "sw-resize": "nesw-resize",
    "top_right_corner": "nesw-resize",
    "bottom_left_corner": "nesw-resize",
    "size_bdiag": "nesw-resize",
    "fd_double_arrow": "nesw-resize",
    # not-allowed
    "no-drop": "not-allowed",
    "dnd-no-drop": "not-allowed",
    "forbidden": "not-allowed",
    "crossed_circle": "not-allowed",
    "circle": "not-allowed",
    "03b6e0fcb3499374a867c041f52298f0": "not-allowed",
    # busy
    "watch": "wait",
    "left_ptr_watch": "progress",
    "half-busy": "progress",
    "08e8e1c95fe2fc01f976f1e063a24ccd": "progress",
    "3ecb610c1bf2410f44200f48c40d3599": "progress",
}


def render(frame, size):
    """One frame at a nominal size: (argb rows, hotspot in device pixels)."""
    rows, (hx, hy) = frame
    u = SIZES[size]
    assert len(rows) * u <= size and len(rows[0]) * u <= size
    px = [[0] * size for _ in range(size)]
    for y, r in enumerate(rows):
        for x, c in enumerate(r):
            if c == ".":
                continue
            argb = 0xFF000000 | PALETTE[c]
            for dy in range(u):
                for dx in range(u):
                    px[y * u + dy][x * u + dx] = argb
    # The hotspot sits on the middle of its art pixel (its corner at u = 1).
    return px, (hx * u + u // 2, hy * u + u // 2)


def xcursor(frames):
    """Encode an Xcursor file: every size, every frame."""
    images = []
    for size in sorted(SIZES):
        for frame in frames:
            px, (hx, hy) = render(frame, size)
            delay = FRAME_MS if len(frames) > 1 else 0
            header = struct.pack(
                "<9I", 36, 0xFFFD0002, size, 1, size, size, hx, hy, delay
            )
            body = b"".join(struct.pack(f"<{size}I", *r) for r in px)
            images.append((size, header + body))
    ntoc = len(images)
    out = struct.pack("<4sIII", b"Xcur", 16, 0x10000, ntoc)
    pos = 16 + ntoc * 12
    toc = b""
    for size, chunk in images:
        toc += struct.pack("<III", 0xFFFD0002, size, pos)
        pos += len(chunk)
    return out + toc + b"".join(c for _, c in images)


def write_theme(prefix):
    root = os.path.join(prefix, "share", "icons", THEME)
    cursors = os.path.join(root, "cursors")
    os.makedirs(cursors, exist_ok=True)
    for name, frames in CURSORS.items():
        with open(os.path.join(cursors, name), "wb") as f:
            f.write(xcursor(frames))
    for alias, target in ALIASES.items():
        assert target in CURSORS, (alias, target)
        if alias in CURSORS:
            continue
        os.symlink(target, os.path.join(cursors, alias))
    with open(os.path.join(root, "index.theme"), "w") as f:
        f.write(
            "[Icon Theme]\n"
            f"Name={THEME}\n"
            "Comment=Square pixel cursors in the haiiro palette\n"
        )
    # Some XWayland and Qt paths only read cursor.theme.
    with open(os.path.join(root, "cursor.theme"), "w") as f:
        f.write(f"[Icon Theme]\nInherits={THEME}\n")


def png(path, px, scale=1):
    """Write an RGBA PNG of `px` (ARGB ints, 0 = transparent)."""
    h, w = len(px) * scale, len(px[0]) * scale
    raw = bytearray()
    for r in px:
        line = bytearray(b"\x00")
        for v in r:
            rgba = bytes(((v >> 16) & 255, (v >> 8) & 255, v & 255, v >> 24))
            line += rgba * scale
        raw += bytes(line) * scale

    def chunk(t, d):
        return struct.pack(">I", len(d)) + t + d + struct.pack(">I", zlib.crc32(t + d))

    with open(path, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n")
        f.write(chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0)))
        f.write(chunk(b"IDAT", zlib.compress(bytes(raw), 9)))
        f.write(chunk(b"IEND", b""))


def preview(path, bg=(0x191724, 0xE0DEF4), scale=2):
    """A sheet: a band per size on color-base and on color-text, with every
    cursor and every spinner frame, so 1x (24, 32) and 2x (48, 64) sit together."""
    names = list(CURSORS)
    cols = sum(len(CURSORS[n]) for n in names)
    pad = 4
    sizes = [24, 48, 32, 64]
    width = cols * (max(sizes) + pad) + pad
    height = sum(2 * (s + pad) for s in sizes) + pad
    sheet = [[0xFF000000 | bg[0]] * width for _ in range(height)]
    y0 = pad
    for size in sizes:
        for band, colour in enumerate(bg):
            top = y0 + band * (size + pad)
            for yy in range(top - pad // 2, top + size + pad // 2):
                sheet[yy] = [0xFF000000 | colour] * width
            x0 = pad
            for n in names:
                for frame in CURSORS[n]:
                    px, (hx, hy) = render(frame, size)
                    for y in range(size):
                        for x in range(size):
                            if px[y][x]:
                                sheet[top + y][x0 + x] = px[y][x]
                    x0 += max(sizes) + pad
        y0 += 2 * (size + pad)
    png(path, sheet, scale)


def check(prefix):
    """Parse every built cursor back and check it is what render() promises:
    one image per size and frame, square, at its nominal size, every pixel
    either fully opaque or fully transparent, and drawn in whole art pixels."""
    cursors = os.path.join(prefix, "share", "icons", THEME, "cursors")
    names = sorted(os.listdir(cursors))
    for name in names:
        path = os.path.join(cursors, name)
        if os.path.islink(path):
            assert os.readlink(path) in CURSORS, (name, os.readlink(path))
            continue
        data = open(path, "rb").read()
        magic, hsize, _, ntoc = struct.unpack_from("<4sIII", data)
        assert magic == b"Xcur" and hsize == 16, name
        seen = {}
        for i in range(ntoc):
            typ, nominal, pos = struct.unpack_from("<III", data, 16 + 12 * i)
            assert typ == 0xFFFD0002, name
            _, _, sub, _, w, h, hx, hy, delay = struct.unpack_from("<9I", data, pos)
            assert sub == nominal == w == h, (name, nominal, w, h)
            assert hx < w and hy < h, (name, nominal)
            px = struct.unpack_from(f"<{w * h}I", data, pos + 36)
            assert all(p >> 24 in (0, 255) for p in px), (name, nominal, "alpha")
            u = SIZES[nominal]
            for y in range(h):
                for x in range(w):
                    p = px[y * w + x]
                    assert p == px[(y - y % u) * w + (x - x % u)], (name, nominal, x, y)
            seen[nominal] = seen.get(nominal, 0) + 1
        frames = len(CURSORS[name])
        assert seen == {s: frames for s in SIZES}, (name, seen)
    missing = set(CURSORS) | set(ALIASES)
    assert missing <= set(names), missing - set(names)
    print(f"{len(names)} cursors ok ({len(CURSORS)} drawn, sizes {sorted(SIZES)})")


if __name__ == "__main__":
    if sys.argv[1] == "--preview":
        preview(sys.argv[2])
    elif sys.argv[1] == "--check":
        check(sys.argv[2])
    else:
        write_theme(sys.argv[1])
