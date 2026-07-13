"""Composable gun sprite: plasma blaster, 16x16 target, drawn on a native
16-grid at 8x fat pixels (128x128 canvas). Gun points RIGHT (rotated/flipped
in-engine). GRIP CONVENTION: the grip pixel sits at grid (5, 11) — every gun
sprite places its grip there so one hand-offset constant works for all guns.
Palette: hull grays + plasma cyan (pixel-art-sheets), pure black outline."""
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

grid = [[None] * G for _ in range(G)]

def put(x, y, c):
    if 0 <= x < G and 0 <= y < G:
        grid[y][x] = c

def rect(x0, y0, x1, y1, c):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            put(x, y, c)

# body: chunky rectangular receiver, barrel to the right
rect(3, 6, 11, 9, H1)          # receiver
rect(3, 6, 11, 6, H2)          # top-edge light (light source top-left)
rect(11, 7, 14, 8, H0)         # barrel
put(14, 7, H1)                 # muzzle tip
# plasma cell (glowing canister on the receiver)
rect(6, 7, 8, 8, CY0)
put(7, 7, CY1); put(6, 7, CY2)
# grip: down-and-back from the receiver; grip pixel at (5, 11)
rect(4, 10, 5, 12, H0)
put(4, 10, H1)
put(5, 11, H0)                 # <- grip anchor pixel (5, 11)
# rear sight nub
put(3, 5, H3)

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
out = os.path.join(root, "raw", "gun_plasma_blaster_v1.png")
img.save(out)
print("saved", out)
