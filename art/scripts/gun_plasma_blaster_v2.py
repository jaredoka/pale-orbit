"""Plasma blaster v2: two-handed hold. No grip handle (the hands cover it);
two suit-colored hands are drawn on the sprite so they rotate with the gun.
Gun points RIGHT. PIVOT CONVENTION: receiver center at grid (7, 8) — the
Player pins this pixel to the gun node origin. Muzzle tip at x=15, so the
muzzle sits ~8px forward of the pivot."""
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

# receiver centered on pivot (7, 8)
rect(3, 7, 11, 10, H1)
rect(3, 7, 11, 7, H2)          # top-edge light
rect(11, 8, 14, 9, H0)         # barrel
put(15, 8, H1)                 # muzzle tip
# plasma cell
rect(6, 8, 8, 9, CY0)
put(7, 8, CY1); put(6, 8, CY2)
# rear sight nub
put(3, 6, H3)
# two hands gripping under the receiver (fore hand + trigger hand)
rect(9, 11, 10, 11, SUIT)
rect(4, 11, 5, 11, SUIT)

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
img.save(os.path.join(root, "raw", "gun_plasma_blaster_v2.png"))
print("saved raw v2")
