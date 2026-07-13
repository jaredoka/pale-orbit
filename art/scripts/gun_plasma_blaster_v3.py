"""Plasma blaster v3: compact HANDGUN held with two hands clasped under it
(no visible grip handle — the hands cover it). Gun points RIGHT.

SKIN CONVENTION (for future swappable handgun designs): 16x16 texture,
pivot at pixel (7, 8) pinned to the Gun node origin, muzzle tip at x = 12
(5px forward of the pivot). Any future handgun skin (flaming, electric, ...)
drawn to this convention drops in with zero code changes.
"""
from PIL import Image, ImageDraw
import os

F = 8
G = 16

OUT  = (0x00, 0x00, 0x00, 255)
H0   = (0x2b, 0x29, 0x38, 255)
H1   = (0x45, 0x43, 0x58, 255)
H2   = (0x6b, 0x68, 0x84, 255)
H3   = (0x9b, 0x97, 0xb0, 255)
CY0  = (0x1b, 0x6f, 0x8a, 255)
CY1  = (0x2f, 0xc6, 0xe0, 255)
CY2  = (0xa8, 0xf0, 0xff, 255)
SUIT = (0xc7, 0xcb, 0xd8, 255)

grid = [[None] * G for _ in range(G)]

def put(x, y, c):
    if 0 <= x < G and 0 <= y < G:
        grid[y][x] = c

def rect(x0, y0, x1, y1, c):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            put(x, y, c)

# compact pistol slide centered on pivot (7, 8)
rect(5, 7, 10, 9, H1)
rect(5, 7, 10, 7, H2)          # top-edge light
rect(10, 8, 11, 8, H0)         # stub barrel
put(12, 8, H1)                 # muzzle tip (x = 12)
# plasma cell glow on the slide
put(7, 8, CY1); put(6, 8, CY2); put(8, 9, CY0)
# rear sight nub
put(5, 6, H3)
# two hands clasped together under the pistol grip
rect(6, 10, 7, 11, SUIT)       # support hand
rect(8, 10, 9, 10, SUIT)       # trigger hand wrapped over

# full 1px black outline
solid = [[grid[y][x] is not None for x in range(G)] for y in range(G)]
for y in range(G):
    for x in range(G):
        if not solid[y][x]:
            continue
        if any(not (0 <= x + dx < G and 0 <= y + dy < G and solid[y + dy][x + dx])
               for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
            grid[y][x] = OUT

img = Image.new("RGBA", (G * F, G * F), (0, 0, 0, 0))
d = ImageDraw.Draw(img)
for y in range(G):
    for x in range(G):
        c = grid[y][x]
        if c:
            d.rectangle([x * F, y * F, x * F + F - 1, y * F + F - 1], fill=c)

root = os.path.join(os.path.dirname(__file__), "..")
os.makedirs(os.path.join(root, "raw"), exist_ok=True)
img.save(os.path.join(root, "raw", "gun_plasma_blaster_v3.png"))
print("saved raw v3")
