"""pixel-art-32 test sprite: hulking alien sentry drone, boss64 target.
Working canvas 512x512 = 8x fat-pixel grid over 64x64. Project palette from pixel-art-sheets."""
from PIL import Image, ImageDraw
import os

F = 8          # fat-pixel factor (512 / 64)
G = 64         # target grid

OUT   = (0x00, 0x00, 0x00, 255)   # outline
H0    = (0x2b, 0x29, 0x38, 255)   # hull ramp (6-color for boss64)
H1    = (0x45, 0x43, 0x58, 255)
H2    = (0x6b, 0x68, 0x84, 255)
H3    = (0x9b, 0x97, 0xb0, 255)
FL0   = (0x4a, 0x2d, 0x4e, 255)   # alien flesh ramp
FL1   = (0x7a, 0x3b, 0x6d, 255)
FL2   = (0xb3, 0x50, 0x8a, 255)
ACID0 = (0x3f, 0x7d, 0x20, 255)   # acid green (eye / core)
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

# --- silhouette block-out: hunched dome drone with side pods and dangling flesh ---
ellipse(32, 28, 22, 16, H1)              # main dome hull
ellipse(32, 24, 18, 10, H2)              # upper hull light band
ellipse(32, 20, 12, 5, H3)               # top sheen
# side weapon pods
ellipse(11, 34, 6, 8, H1); ellipse(53, 34, 6, 8, H1)
ellipse(11, 31, 4, 4, H2); ellipse(53, 31, 4, 4, H2)
# under-hull shadow band
for y in range(36, 44):
    for x in range(G):
        if grid[y][x] in (H1, H2):
            grid[y][x] = H0
# dangling alien flesh tendrils beneath
for i, tx in enumerate((22, 28, 34, 40, 46)):
    length = (10, 14, 16, 13, 9)[i]
    for y in range(42, 42 + length):
        w = 3 if y < 48 else 2
        for x in range(tx - w // 2, tx - w // 2 + w):
            t = (y - 42) / length
            put(x, y, FL0 if t > 0.66 else (FL1 if t > 0.33 else FL2))
# central acid eye
ellipse(32, 30, 7, 6, ACID0)
ellipse(32, 29, 5, 4, ACID1)
ellipse(31, 28, 2, 2, ACID2)
put(30, 27, WHITE)
# pod muzzles
for px_ in (11, 53):
    put(px_, 41, OUT); put(px_, 40, ACID1)
# rivet details on hull band
for x in (20, 26, 38, 44):
    put(x, 35, H3)

# --- 1 fat-pixel outline around everything opaque ---
solid = [[grid[y][x] is not None for x in range(G)] for y in range(G)]
for y in range(G):
    for x in range(G):
        if not solid[y][x]:
            continue
        if any(not (0 <= x+dx < G and 0 <= y+dy < G and solid[y+dy][x+dx])
               for dx, dy in ((1,0),(-1,0),(0,1),(0,-1))):
            grid[y][x] = OUT

# --- render fat pixels to 512x512 RGBA ---
img = Image.new("RGBA", (G * F, G * F), (0, 0, 0, 0))
d = ImageDraw.Draw(img)
for y in range(G):
    for x in range(G):
        c = grid[y][x]
        if c:
            d.rectangle([x*F, y*F, x*F+F-1, y*F+F-1], fill=c)

root = os.path.join(os.path.dirname(__file__), "..")
os.makedirs(os.path.join(root, "raw"), exist_ok=True)
out = os.path.join(root, "raw", "drone_boss_v3.png")
img.save(out)
print("saved", out)
