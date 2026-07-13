"""Drone boss v4: redrawn on a native 32-pixel grid (game frame size) so the
1px pure-black outline survives post-processing crisply. Fat-pixel factor 8x
-> 256x256 working canvas, integer downscale to 32."""
from PIL import Image, ImageDraw
import os

F = 8
G = 32

OUT   = (0x00, 0x00, 0x00, 255)   # pure black outline (project-wide rule)
H0    = (0x2b, 0x29, 0x38, 255)
H1    = (0x45, 0x43, 0x58, 255)
H2    = (0x6b, 0x68, 0x84, 255)
H3    = (0x9b, 0x97, 0xb0, 255)
FL0   = (0x4a, 0x2d, 0x4e, 255)
FL1   = (0x7a, 0x3b, 0x6d, 255)
FL2   = (0xb3, 0x50, 0x8a, 255)
ACID0 = (0x3f, 0x7d, 0x20, 255)
ACID1 = (0x6a, 0xbe, 0x30, 255)
ACID2 = (0xb6, 0xf3, 0x4c, 255)
WHITE = (0xf0, 0xee, 0xf7, 255)

grid = [[None] * G for _ in range(G)]

def put(x, y, c):
    if 0 <= x < G and 0 <= y < G:
        grid[y][x] = c

def ellipse(cx, cy, rx, ry, c):
    for y in range(G):
        for x in range(G):
            if ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 <= 1.0:
                put(x, y, c)

# silhouette: dome hull with side pods and flesh tendrils (half of v3 coords)
ellipse(16, 14, 11, 8, H1)
ellipse(16, 12, 9, 5, H2)
ellipse(16, 10, 6, 2, H3)
ellipse(5, 17, 3, 4, H1); ellipse(27, 17, 3, 4, H1)
ellipse(5, 15, 2, 2, H2); ellipse(27, 15, 2, 2, H2)
# under-hull shadow band
for y in range(18, 22):
    for x in range(G):
        if grid[y][x] in (H1, H2):
            grid[y][x] = H0
# tendrils (2 wide so the flesh ramp survives the outline pass)
for i, tx in enumerate((11, 14, 17, 20, 23)):
    length = (5, 7, 8, 6, 4)[i]
    for y in range(21, 21 + length):
        t = (y - 21) / length
        c = FL0 if t > 0.66 else (FL1 if t > 0.33 else FL2)
        put(tx, y, c); put(tx + 1, y, c)
# central acid eye
ellipse(16, 15, 4, 3, ACID0)
ellipse(16, 14, 3, 2, ACID1)
put(15, 14, ACID2); put(16, 14, ACID2)
put(15, 13, WHITE)
# rivets
for x in (10, 13, 19, 22):
    put(x, 17, H3)

# full 1px black outline: every opaque pixel touching transparency/border
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
out = os.path.join(root, "raw", "drone_boss_v4.png")
img.save(out)
print("saved", out)
