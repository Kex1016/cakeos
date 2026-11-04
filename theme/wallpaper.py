"""Draws the default CakeOS wallpaper as SVG from a palette (theme/palette.nix as JSON).

Material You shapes (a scalloped "cookie", clovers, pills, a ring and a dot
grid) in the palette's container roles over its surface. Deterministic: the same
palette always gives the same picture.

    python3 wallpaper.py palette.json > wallpaper.svg
"""

import json
import math
import sys

W, H = 3840, 2160


def polar_path(cx, cy, radius_at, rotation=0.0, steps=720):
    points = []
    for i in range(steps):
        t = 2 * math.pi * i / steps
        r = radius_at(t)
        a = t + math.radians(rotation)
        points.append(f"{cx + r * math.cos(a):.1f},{cy + r * math.sin(a):.1f}")
    return "M" + " L".join(points) + " Z"


def cookie(cx, cy, r, lobes, depth, rotation=0.0):
    return polar_path(cx, cy, lambda t: r * (1 + depth * math.cos(lobes * t)), rotation)


def clover(cx, cy, r, leaves, rotation=0.0):
    return polar_path(cx, cy, lambda t: r * (0.72 + 0.28 * abs(math.cos(leaves * t / 2))), rotation)


def pill(cx, cy, length, thickness, angle):
    return (
        f'<rect x="{cx - length / 2:.1f}" y="{cy - thickness / 2:.1f}" '
        f'width="{length:.1f}" height="{thickness:.1f}" rx="{thickness / 2:.1f}" '
        f'transform="rotate({angle} {cx} {cy})"'
    )


def main():
    c = json.load(open(sys.argv[1]))["colors"]

    dots = []
    for row in range(7):
        for col in range(9):
            x = 2520 + col * 64
            y = 1500 + row * 64
            dots.append(f'<circle cx="{x}" cy="{y}" r="9"/>')

    svg = f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">
  <defs>
    <linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="{c['surface_container_low']}"/>
      <stop offset="1" stop-color="{c['surface_container_lowest']}"/>
    </linearGradient>
  </defs>
  <rect width="{W}" height="{H}" fill="url(#bg)"/>
  <path d="{cookie(3260, 380, 760, 12, 0.055, 8)}" fill="{c['primary_container']}"/>
  <path d="{cookie(3260, 380, 430, 12, 0.055, 8)}" fill="{c['primary']}" fill-opacity="0.16"/>
  <path d="{clover(420, 1880, 640, 4, 20)}" fill="{c['tertiary_container']}" fill-opacity="0.85"/>
  {pill(1150, 2010, 980, 260, -32)} fill="{c['secondary_container']}"/>
  {pill(1500, 260, 760, 200, 28)} fill="{c['secondary_container']}" fill-opacity="0.7"/>
  <circle cx="300" cy="300" r="170" fill="{c['tertiary']}" fill-opacity="0.22"/>
  <path d="{cookie(3540, 1800, 300, 6, 0.1, 15)}" fill="{c['primary']}" fill-opacity="0.85"/>
  <circle cx="2210" cy="1990" r="110" fill="none" stroke="{c['outline_variant']}" stroke-width="22"/>
  <g fill="{c['outline_variant']}" fill-opacity="0.8">{''.join(dots)}</g>
</svg>
"""
    sys.stdout.write(svg)


if __name__ == "__main__":
    main()
