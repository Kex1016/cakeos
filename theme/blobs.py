"""One still frame of the haiiro Blobs background, as a PNG.

The same simulation as the design system's Blobs component and the hecate
shell's live background (6px cells, metaballs r^2/(d^2+0.01) summed within 3r,
merging conserves area up to a radius of 24 cells, dithered with a 4x4 Bayer
matrix in three tones: base ground, overlay halo, highlight-med core), run for
a few simulated seconds from a fixed seed so the same arguments always give the
same picture, then scaled up with nearest-neighbour.

    python3 blobs.py out.png WIDTH HEIGHT [SEED] [CELL]
"""

import math
import random
import sys

import numpy as np
from PIL import Image

BASE = (0x19, 0x17, 0x24)
HALO = (0x26, 0x23, 0x3A)
CORE = (0x40, 0x3D, 0x52)
BAYER = (
    np.array([0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]).reshape(4, 4) + 0.5
) / 16


def simulate(w, h, rnd, seconds=40.0):
    target = max(6, min(60, round(w * h / 700)))
    blobs = []

    def radius():
        return 2 + rnd.random() ** 2 * 7

    def add(x, y, r, ang):
        s = rnd.uniform(1.5, 6)
        blobs.append([x, y, r, math.cos(ang) * s, math.sin(ang) * s])

    def spawn():
        r = radius()
        side = rnd.randrange(4)
        m = 3 * r
        if side == 0:
            x, y = -m, rnd.uniform(0, h)
        elif side == 1:
            x, y = w + m, rnd.uniform(0, h)
        elif side == 2:
            x, y = rnd.uniform(0, w), -m
        else:
            x, y = rnd.uniform(0, w), h + m
        add(x, y, r, math.atan2(h / 2 - y, w / 2 - x) + rnd.uniform(-0.6, 0.6))

    for _ in range(target):
        add(rnd.uniform(0, w), rnd.uniform(0, h), radius(), rnd.uniform(0, math.tau))

    def step(dt):
        for b in blobs:
            b[0] += b[3] * dt
            b[1] += b[4] * dt
        i = 0
        while i < len(blobs):
            j = i + 1
            while j < len(blobs):
                a, c = blobs[i], blobs[j]
                d = math.hypot(a[0] - c[0], a[1] - c[1])
                nr = math.sqrt(a[2] ** 2 + c[2] ** 2)
                if d <= max(a[2], c[2]) and nr <= 24:
                    wa, wc = a[2] ** 2, c[2] ** 2
                    ww = wa + wc
                    a[0] = (a[0] * wa + c[0] * wc) / ww
                    a[1] = (a[1] * wa + c[1] * wc) / ww
                    a[3] = (a[3] * wa + c[3] * wc) / ww
                    a[4] = (a[4] * wa + c[4] * wc) / ww
                    s = math.hypot(a[3], a[4])
                    if s < 1e-3:
                        ang = rnd.uniform(0, math.tau)
                        a[3], a[4], s = math.cos(ang), math.sin(ang), 1
                    if s < 1.5:
                        a[3] *= 1.5 / s
                        a[4] *= 1.5 / s
                    a[2] = nr
                    del blobs[j]
                else:
                    j += 1
            i += 1
        for k in range(len(blobs) - 1, -1, -1):
            x, y, r, vx, vy = blobs[k]
            m = 3 * r + 2
            if (
                (x < -m and vx <= 0)
                or (x > w + m and vx >= 0)
                or (y < -m and vy <= 0)
                or (y > h + m and vy >= 0)
            ):
                del blobs[k]
        while len(blobs) < target * 0.85:
            spawn()

    for _ in range(int(seconds * 10)):
        step(0.1)
    return blobs


def field(w, h, blobs):
    f = np.zeros((h, w), dtype=np.float32)
    ys, xs = np.mgrid[0:h, 0:w]
    for x, y, r, _, _ in blobs:
        R = 3 * r
        x0, x1 = max(0, math.floor(x - R)), min(w - 1, math.ceil(x + R))
        y0, y1 = max(0, math.floor(y - R)), min(h - 1, math.ceil(y + R))
        if x0 > x1 or y0 > y1:
            continue
        dx = xs[y0 : y1 + 1, x0 : x1 + 1] + 0.5 - x
        dy = ys[y0 : y1 + 1, x0 : x1 + 1] + 0.5 - y
        f[y0 : y1 + 1, x0 : x1 + 1] += r * r / (dx * dx + dy * dy + 0.01)
    return f


def render(width, height, seed=7, cell=6):
    w, h = -(-width // cell), -(-height // cell)
    f = field(w, h, simulate(w, h, random.Random(seed)))
    t = np.tile(BAYER, (-(-h // 4), -(-w // 4)))[:h, :w]
    halo = (f - 0.3) / 0.75
    core = (f - 0.9) / 0.5
    img = np.empty((h, w, 3), dtype=np.uint8)
    img[:] = BASE
    img[halo > t] = HALO
    img[core > t] = CORE
    big = Image.fromarray(img).resize((w * cell, h * cell), Image.NEAREST)
    return big.crop((0, 0, width, height))


if __name__ == "__main__":
    out, width, height = sys.argv[1], int(sys.argv[2]), int(sys.argv[3])
    seed = int(sys.argv[4]) if len(sys.argv) > 4 else 7
    cell = int(sys.argv[5]) if len(sys.argv) > 5 else 6
    render(width, height, seed, cell).save(out)
