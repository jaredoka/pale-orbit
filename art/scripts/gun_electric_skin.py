"""Electric handgun cosmetic skin (IAP prototype): 2-frame 16x16 strip
following the handgun skin convention v2 (see gun_plasma_blaster_v4.py).
Electric-blue recolor of the base handgun plus crackling arc pixels that
spill OUTSIDE the silhouette, alternating between frames.
Also emits the matching electric projectile bolt (2f, 8x8 frames)."""
from PIL import Image
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from gun_plasma_blaster_v4 import (G, F, OUT, H0, H1, H2, CY0, CY1, CY2, SUIT,
                                   draw_handgun, outline, render, make_grid)

WHITE = (0xF0, 0xEE, 0xF7, 255)

ARCS = [
    # frame 1: arcs off the barrel and slide top
    [(12, 5, CY2), (13, 4, CY1), (4, 4, CY1), (15, 7, CY2), (10, 11, CY1), (2, 8, CY2)],
    # frame 2: different arc positions so it crackles
    [(11, 4, CY1), (15, 9, CY2), (2, 5, CY2), (7, 4, CY1), (12, 11, CY2), (14, 6, WHITE)],
]


def electric_frame(arcs):
    grid, put, rect = make_grid()
    draw_handgun(grid, put, rect)
    # recolor: energized slide band + white-hot cell
    rect(5, 7, 7, 8, CY1)
    put(6, 7, WHITE); put(5, 7, CY2)
    rect(11, 7, 13, 7, CY0)        # charged barrel
    outline(grid)
    # arcs go on AFTER the outline pass — they float outside the silhouette
    for x, y, c in arcs:
        put(x, y, c)
    return render(grid)


def bolt_frame(diag):
    """8x8 electric bolt: white-hot core with cyan arcs, alternating diagonal."""
    g = [[None] * 8 for _ in range(8)]
    g[3][3] = WHITE; g[3][4] = WHITE; g[4][3] = CY2; g[4][4] = WHITE
    if diag:
        g[2][2] = CY1; g[5][5] = CY1; g[1][4] = CY2; g[6][3] = CY2
    else:
        g[2][5] = CY1; g[5][2] = CY1; g[4][6] = CY2; g[3][1] = CY2
    img = Image.new("RGBA", (8 * F, 8 * F), (0, 0, 0, 0))
    from PIL import ImageDraw
    d = ImageDraw.Draw(img)
    for y in range(8):
        for x in range(8):
            if g[y][x]:
                d.rectangle([x * F, y * F, x * F + F - 1, y * F + F - 1], fill=g[y][x])
    return img


def strip(frames, cell):
    s = Image.new("RGBA", (cell * len(frames), cell), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        s.paste(f.resize((cell, cell), Image.BOX), (i * cell, 0))
    r, g, b, a = s.split()
    a = a.point(lambda v: 255 if v >= 128 else 0)
    return Image.merge("RGBA", (r, g, b, a))


if __name__ == "__main__":
    root = os.path.join(os.path.dirname(__file__), "..", "..")
    gun = strip([electric_frame(a) for a in ARCS], 16)
    gun.save(os.path.join(root, "assets", "sprites", "player", "gun_electric_2.png"))
    bolt = strip([bolt_frame(True), bolt_frame(False)], 8)
    bolt.save(os.path.join(root, "assets", "sprites", "fx", "electric_bolt_2.png"))
    print("wrote gun_electric_2.png (32x16) and electric_bolt_2.png (16x8)")
