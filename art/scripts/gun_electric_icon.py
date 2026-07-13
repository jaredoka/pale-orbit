"""Electric handgun SHOP ICON (IAP prototype): 64x64 detailed render of the
electric skin for shop/inventory UI — this is where the cosmetic detail
lives; the in-game sprite stays 16x16. 6-color ramps, full grip visible."""
from PIL import Image, ImageDraw
import os

F = 8
G = 64

OUT  = (0x00, 0x00, 0x00, 255)
H0   = (0x2b, 0x29, 0x38, 255)
H1   = (0x45, 0x43, 0x58, 255)
H2   = (0x6b, 0x68, 0x84, 255)
H3   = (0x9b, 0x97, 0xb0, 255)
CY0  = (0x1b, 0x6f, 0x8a, 255)
CY1  = (0x2f, 0xc6, 0xe0, 255)
CY2  = (0xa8, 0xf0, 0xff, 255)
WHITE = (0xF0, 0xEE, 0xF7, 255)

grid = [[None] * G for _ in range(G)]

def put(x, y, c):
    if 0 <= x < G and 0 <= y < G:
        grid[y][x] = c

def rect(x0, y0, x1, y1, c):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            put(x, y, c)

# slide (long, chunky) with layered shading
rect(8, 22, 42, 34, H1)
rect(8, 22, 42, 24, H2)
rect(8, 22, 42, 22, H3)
rect(8, 32, 42, 34, H0)
# barrel + muzzle
rect(42, 25, 54, 31, H0)
rect(54, 26, 56, 30, H1)
# energy cell window (glowing core)
rect(16, 25, 27, 31, CY0)
rect(18, 26, 25, 30, CY1)
rect(20, 27, 23, 29, CY2)
put(21, 28, WHITE); put(22, 28, WHITE)
# vents on the slide
for x in (31, 34, 37):
    rect(x, 25, x, 30, H0)
# rear sight
rect(8, 19, 10, 22, H3)
# grip (visible in the icon; hands cover it in-game)
rect(12, 34, 22, 52, H1)
rect(12, 34, 14, 52, H0)
rect(20, 34, 22, 52, H2)
rect(12, 50, 22, 52, H0)
# trigger guard
rect(24, 34, 30, 36, H0)
rect(28, 36, 30, 40, H0)

# 1px black outline
solid = [[grid[y][x] is not None for x in range(G)] for y in range(G)]
for y in range(G):
    for x in range(G):
        if not solid[y][x]:
            continue
        if any(not (0 <= x + dx < G and 0 <= y + dy < G and solid[y + dy][x + dx])
               for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
            grid[y][x] = OUT

# electricity seeping out — arcs outside the silhouette, after outlining
for x, y, c in [(45, 20, CY1), (47, 18, CY2), (50, 33, CY1), (52, 35, CY2),
                (58, 24, CY2), (59, 28, WHITE), (12, 16, CY1), (14, 14, CY2),
                (6, 30, CY2), (4, 27, CY1), (26, 55, CY1), (28, 57, CY2),
                (44, 36, CY2), (30, 17, CY2)]:
    put(x, y, c)

img = Image.new("RGBA", (G * F, G * F), (0, 0, 0, 0))
d = ImageDraw.Draw(img)
for y in range(G):
    for x in range(G):
        if grid[y][x]:
            d.rectangle([x * F, y * F, x * F + F - 1, y * F + F - 1], fill=grid[y][x])

root = os.path.join(os.path.dirname(__file__), "..")
os.makedirs(os.path.join(root, "raw"), exist_ok=True)
img.save(os.path.join(root, "raw", "gun_electric_icon_v1.png"))

final = img.resize((G, G), Image.BOX)
r, g, b, a = final.split()
a = a.point(lambda v: 255 if v >= 128 else 0)
final = Image.merge("RGBA", (r, g, b, a))
dst = os.path.join(root, "..", "assets", "ui", "shop_gun_electric_64.png")
final.save(dst)
print("wrote", dst)
