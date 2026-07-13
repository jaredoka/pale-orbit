"""Plasma blaster v4: bigger handgun (~12px long) so cosmetic skins have
room for detail, still a compact pistol held with two clasped hands.

HANDGUN SKIN CONVENTION v2: 16x16 frame, gun points RIGHT, pivot at pixel
(7, 8) pinned to the Gun node origin, muzzle tip at x = 14 (7px forward).
Hands drawn on the sprite in suit color. Skins may be multi-frame strips
(frames side by side, each 16x16 following the same convention).
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


def draw_handgun(grid, put, rect):
    """Shared base handgun geometry (skins recolor/decorate around this)."""
    rect(3, 6, 11, 9, H1)          # slide
    rect(3, 6, 11, 6, H2)          # top-edge light
    rect(11, 7, 13, 8, H0)         # barrel
    put(14, 8, H1)                 # muzzle tip (x = 14)
    put(3, 5, H3)                  # rear sight
    rect(5, 10, 6, 11, SUIT)       # support hand
    rect(8, 10, 9, 10, SUIT)       # trigger hand wrapped over


def outline(grid):
    solid = [[grid[y][x] is not None for x in range(G)] for y in range(G)]
    for y in range(G):
        for x in range(G):
            if not solid[y][x]:
                continue
            if any(not (0 <= x + dx < G and 0 <= y + dy < G and solid[y + dy][x + dx])
                   for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                grid[y][x] = OUT


def render(grid):
    img = Image.new("RGBA", (G * F, G * F), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    for y in range(G):
        for x in range(G):
            if grid[y][x]:
                d.rectangle([x * F, y * F, x * F + F - 1, y * F + F - 1], fill=grid[y][x])
    return img


def make_grid():
    grid = [[None] * G for _ in range(G)]

    def put(x, y, c):
        if 0 <= x < G and 0 <= y < G:
            grid[y][x] = c

    def rect(x0, y0, x1, y1, c):
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                put(x, y, c)
    return grid, put, rect


if __name__ == "__main__":
    grid, put, rect = make_grid()
    draw_handgun(grid, put, rect)
    # plasma cell glow on the slide
    rect(5, 7, 7, 8, CY0)
    put(6, 7, CY1); put(5, 7, CY2)
    outline(grid)
    root = os.path.join(os.path.dirname(__file__), "..")
    os.makedirs(os.path.join(root, "raw"), exist_ok=True)
    render(grid).save(os.path.join(root, "raw", "gun_plasma_blaster_v4.png"))
    print("saved raw v4")
