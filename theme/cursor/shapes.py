"""The haiiro cursor shapes, drawn on a 16x16 grid of art pixels.

Legend: '.' transparent, 'K' outline (color-base), 'W' fill (color-text),
'F' color-foam, 'P' color-pine, 'M' color-muted, 'L' color-love (build.py has
the values). Fill drawn without its outline gets one: every
transparent cell that touches a filled cell edge-on becomes 'K' (see outline()),
so only outlines that sit between two fills (finger gaps) are drawn by hand.

Every shape is (rows, hotspot), the hotspot in art pixels (x, y).
"""

GRID = 16


def parse(art):
    rows = [r for r in art.strip("\n").split("\n")]
    width = max(len(r) for r in rows)
    return [list(r.ljust(width, ".")) for r in rows]


def outline(rows):
    """Add a 1-cell outline, 4-connected, around every non-outline fill."""
    h = len(rows) + 2
    w = max(len(r) for r in rows) + 2
    # Pad by one cell on each side so the outline has room, then trim back.
    grid = [["."] * w for _ in range(h)]
    for y, r in enumerate(rows):
        for x, c in enumerate(r):
            grid[y + 1][x + 1] = c
    out = [row[:] for row in grid]
    for y in range(h):
        for x in range(w):
            if grid[y][x] != ".":
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < w and 0 <= ny < h and grid[ny][nx] not in ".K":
                    out[y][x] = "K"
                    break
    return out


def trim(rows, hotspot):
    """Crop transparent margins, moving the hotspot with them."""
    ys = [y for y, r in enumerate(rows) if any(c != "." for c in r)]
    xs = [x for r in rows for x, c in enumerate(r) if c != "."]
    y0, y1, x0, x1 = min(ys), max(ys), min(xs), max(xs)
    rows = [r[x0 : x1 + 1] for r in rows[y0 : y1 + 1]]
    return rows, (hotspot[0] - x0, hotspot[1] - y0)


def shape(art, hotspot, auto=True):
    """Hotspot is given in the art's own coordinates (before outline padding)."""
    rows = parse(art)
    if auto:
        rows = outline(rows)
        hotspot = (hotspot[0] + 1, hotspot[1] + 1)
    rows, hotspot = trim(rows, hotspot)
    assert len(rows) <= GRID and len(rows[0]) <= GRID, (len(rows[0]), len(rows))
    return rows, hotspot


def transpose(s):
    rows, (hx, hy) = s
    return [list(c) for c in zip(*rows)], (hy, hx)


def mirror_x(s):
    rows, (hx, hy) = s
    w = len(rows[0])
    return [r[::-1] for r in rows], (w - 1 - hx, hy)


# --- default arrow -----------------------------------------------------------
# A classic stepped pointer: 45 degree leading edge, tail to the lower right.
ARROW = shape(
    """
K..........
KK.........
KWK........
KWWK.......
KWWWK......
KWWWWK.....
KWWWWWK....
KWWWWWWK...
KWWWWWWWK..
KWWWWWWWWK.
KWWWWWKKKKK
KWWKWWK....
KWK.KWWK...
KK..KWWK...
K....KWWK..
......KK...
""",
    (0, 0),
    auto=False,
)

# --- pointer (link hand) -----------------------------------------------------
POINTER = shape(
    """
.....KK.........
....KWWK........
....KWWK........
....KWWK........
....KWWKKK......
....KWWKWWKKK...
....KWWKWWKWWKK.
.KK.KWWKWWKWWKWK
KWWKKWWKWWKWWKWK
KWWWKWWWWWWWWWWK
.KWWWWWWWWWWWWWK
..KWWWWWWWWWWWWK
..KWWWWWWWWWWWK.
...KWWWWWWWWWWK.
....KWWWWWWWWK..
....KKKKKKKKKK..
""",
    (5, 0),
    auto=False,
)

# --- grab (open hand) and grabbing (closed hand) -----------------------------
GRAB = shape(
    """
.......KK.KK....
......KWWKWWK...
....KKKWWKWWKKK.
...KWWKWWKWWKWWK
...KWWKWWKWWKWWK
...KWWKWWKWWKWWK
.KKKWWKWWKWWKWWK
KWWKWWKWWKWWKWWK
KWWKWWWWWWWWWWWK
.KWWWWWWWWWWWWWK
..KWWWWWWWWWWWWK
..KWWWWWWWWWWWK.
...KWWWWWWWWWWK.
....KWWWWWWWWK..
....KKKKKKKKKK..
""",
    (8, 8),
    auto=False,
)

GRABBING = shape(
    """
....KKKKKKKKKKK.
...KWWKWWKWWKWWK
...KWWKWWKWWKWWK
.KKKKKKKKKWWKWWK
KWWWWWWWKWWWWWWK
.KWWWWWWWWWWWWWK
..KWWWWWWWWWWWWK
..KWWWWWWWWWWWK.
...KWWWWWWWWWWK.
....KKKKKKKKKK..
""",
    (8, 4),
    auto=False,
)

# --- text --------------------------------------------------------------------
TEXT = shape(
    """
KKK.KKK
KWWKWWK
KKKWKKK
..KWK..
..KWK..
..KWK..
..KWK..
..KWK..
..KWK..
..KWK..
..KWK..
..KWK..
..KWK..
KKKWKKK
KWWKWWK
KKK.KKK
""",
    (3, 8),
    auto=False,
)
VERTICAL_TEXT = transpose(TEXT)

# --- crosshair: a plus with a foam centre cell -------------------------------
CROSSHAIR = shape(
    """
......W......
......W......
......W......
......W......
......W......
......W......
WWWWWWFWWWWWW
......W......
......W......
......W......
......W......
......W......
......W......
""",
    (6, 6),
)


# --- resize arrows -----------------------------------------------------------
def _double_v(head, shaft):
    """A vertical double arrow: `head` rows of arrowhead, `shaft` rows of shaft."""
    w = 2 * head - 1
    c = head - 1
    rows = []
    for i in range(head):
        rows.append("".join("W" if abs(x - c) <= i else "." for x in range(w)))
    for _ in range(shaft):
        rows.append("".join("W" if x == c else "." for x in range(w)))
    rows += rows[:head][::-1]
    return "\n".join(rows), (c, len(rows) // 2)


NS = shape(*_double_v(4, 5))
EW = transpose(NS)


def _double_diag():
    n = 13
    g = [["."] * n for _ in range(n)]
    for i in range(5):  # head in the top-left corner, legs along the edges
        for x in range(5 - i):
            g[i][x] = "W"
    for k in range(2, n - 2):  # shaft
        g[k][k] = "W"
    for y in range(n):  # the other head, point-mirrored
        for x in range(n):
            if g[y][x] == "W":
                g[n - 1 - y][n - 1 - x] = "W"
    return "\n".join("".join(r) for r in g), (n // 2, n // 2)


NWSE = shape(*_double_diag())
NESW = mirror_x(NWSE)


def _col_resize():
    # <|| ||>: two bars with a small arrow either side.
    h, w = 11, 13
    g = [["."] * w for _ in range(h)]
    c = h // 2
    for y in range(h):
        g[y][5] = g[y][7] = "W"
    for i, x in enumerate((0, 1, 2)):  # left head pointing left
        for y in range(c - i, c + i + 1):
            g[y][x] = "W"
    g[c][3] = "W"
    for i, x in enumerate((12, 11, 10)):
        for y in range(c - i, c + i + 1):
            g[y][x] = "W"
    g[c][9] = "W"
    return "\n".join("".join(r) for r in g), (6, c)


COL_RESIZE = shape(*_col_resize())
ROW_RESIZE = transpose(COL_RESIZE)


def _move():
    # Four arrows with smaller heads so they don't touch where they meet.
    v, _ = _double_v(3, 7)
    vr = v.split("\n")
    n = len(vr)  # 13
    pad = (n - len(vr[0])) // 2
    g = [list("." * pad + r + "." * pad) for r in vr]
    for y in range(n):
        for x in range(n):
            if g[x][y] == "W":
                g[y][x] = "W"
    return "\n".join("".join(r) for r in g), (n // 2, n // 2)


MOVE = shape(*_move())

# --- not-allowed: a love ring with a slash -----------------------------------


def _not_allowed():
    n = 13
    c = n // 2
    g = [["."] * n for _ in range(n)]
    for y in range(n):
        for x in range(n):
            d2 = (x - c) ** 2 + (y - c) ** 2
            if 4.5**2 <= d2 <= 6.4**2:
                g[y][x] = "L"
            elif d2 < 4.5**2 and abs(x - y) <= 1:
                g[y][x] = "L"
    return "\n".join("".join(r) for r in g), (c, c)


NOT_ALLOWED = shape(*_not_allowed())

# --- wait / progress: a ring of eight blocks, stepping clockwise ------------
RING = [(0, 0), (1, 0), (2, 0), (2, 1), (2, 2), (1, 2), (0, 2), (0, 1)]
# Lit head, two fading trail cells, and the resting colour of the rest.
TRAIL = ["W", "F", "P", "M"]


def _spinner(frame, cell, ring=RING, gap=1):
    """A tile of `cell`-sized blocks, lit in turn along `ring`.

    The big one is 3x3 blocks with the eight outer ones as the ring.
    Everything around and between the blocks, the centre included, is
    outline, so the tile reads as one solid square on any background.
    """
    side = max(max(b) for b in ring) + 1
    n = side * cell + (side + 1) * gap
    g = [["K"] * n for _ in range(n)]
    for i, (bx, by) in enumerate(ring):
        age = (frame - i) % len(ring)
        colour = TRAIL[min(age, len(TRAIL) - 1)]
        for y in range(cell):
            for x in range(cell):
                g[gap + by * (cell + gap) + y][gap + bx * (cell + gap) + x] = colour
    return "\n".join("".join(r) for r in g)


FRAMES = len(RING)
WAIT = [shape(_spinner(f, 3), (6, 6), auto=False) for f in range(FRAMES)]

# The small one beside the arrow: 2x2 blocks, four steps.
SMALL_RING = [(0, 0), (1, 0), (1, 1), (0, 1)]
PROGRESS_FRAMES = len(SMALL_RING)


def _progress(frame):
    rows = [r[:] for r in ARROW[0]]
    size = GRID
    canvas = [["."] * size for _ in range(size)]
    for y, r in enumerate(rows):
        for x, c in enumerate(r):
            canvas[y][x] = c
    spin, _ = shape(_spinner(frame, 2, SMALL_RING), (0, 0), auto=False)
    oy = ox = size - len(spin)
    for y, r in enumerate(spin):
        for x, c in enumerate(r):
            if c != ".":
                canvas[oy + y][ox + x] = c
    return trim(canvas, ARROW[1])


PROGRESS = [_progress(f) for f in range(PROGRESS_FRAMES)]
