"""Enemy sheets: skitterer, spitter, bio_turret, blob (16x16) + hive_queen (32x32).
Each gets idle 2f, run 6f, hit 2f, death 4f per ART-1."""
import os

import PIL.Image as I

from canvas import frame_from_map, whiteout, disc, ring, save_strip

OUT = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "sprites")

KEY = {
    "o": "outline", "f": "flesh1", "F": "flesh2", "d": "flesh0",
    "a": "acid1", "A": "acid2", "g": "acid0",
    "w": "hi", "p": "outline", "h": "hull1", "H": "hull2",
    "r": "warn1", "y": "warn2",
}

SKITTERER = [  # low wide facehugger, big single eye
    "................",
    "................",
    "................",
    "....oooooo......",
    "..oofFFFFfoo....",
    ".ofFFwwpFFFfo...",
    ".ofFFwwpFFFfo...",
    "..ofFFFFFFfo....",
    ".o.offffffo.o...",
    "o.o.o....o.o.o..",
    "................",
    "................",
]
SPITTER = [  # upright alien, acid sac belly
    "....oooo........",
    "...offffo.......",
    "..ofwpwpfo......",
    "..offffffo......",
    "...offffo.......",
    "..offaaffo......",
    ".offaAAaffo.....",
    ".offaAAaffo.....",
    "..offaaffo......",
    "...offffo.......",
    "...of..fo.......",
    "...oo..oo.......",
]
BIO_TURRET = [  # mounted growth with acid orifice
    "................",
    "....oooooo......",
    "...offffffo.....",
    "..offaAAaffo....",
    ".offaAggAaffo...",
    ".offaAggAaffo...",
    ".offfaAAafffo...",
    "ohffffffffffho..",
    "ohhHHHHHHHHhho..",
    "oooooooooooooo..",
    "................",
    "................",
]
BLOB = [  # gelatinous mound with two eyes
    "................",
    "................",
    "....oooooo......",
    "..ooaAAAAaoo....",
    ".oaAAwpAwpAao...",
    ".oaAAwpAwpAao...",
    "oaAAAAAAAAAAao..",
    "oaaAAAAAAAAaao..",
    "ogaaAAAAAAaago..",
    ".oggaaaaaaggo...",
    "..oooooooooo....",
    "................",
]
QUEEN = [  # 26-wide brood mother in 32x32: crown spikes, many eyes, egg sac
    "....o....oo....o..........",
    "...ofo..offo..ofo.........",
    "..offfooffffoofffo........",
    ".offfffffffffffffffo......",
    ".offFFFFFFFFFFFFffo.......",
    "offFFwpwFFFFwpwFFffo......",
    "offFFwwwFFFFwwwFFffo......",
    "offFFFFFFwpwFFFFFffo......",
    "offFFFFFFwwwFFFFFffo......",
    ".offFFFFFFFFFFFFffo.......",
    ".offdddddddddddddfo.......",
    "offdddaaaaaaaadddffo......",
    "offddaAAAAAAAAaddffo......",
    "offddaAAAAAAAAaddffo......",
    "offddaAAAAAAAAaddffo......",
    ".offddaaaaaaaaddffo.......",
    "..offdddddddddffo.........",
    "...offo..oo..offo.........",
    "..o.o..o....o..o.o........",
]


def sheets(name, rows, size, folder, move="bob"):
    base = frame_from_map(rows, KEY, size, 0)
    up = frame_from_map(rows, KEY, size, -1)
    dn = frame_from_map(rows, KEY, size, 1)
    idle = [base, dn]
    if move == "bob":
        run = [base, up, base, dn, base, up]
    else:  # scuttle: horizontal wiggle
        left = frame_from_map(["." + r[:-1] for r in rows], KEY, size, 0)
        right = frame_from_map([r[1:] + "." for r in rows], KEY, size, 0)
        run = [base, left, base, right, base, left]
    hit = [whiteout(base), base]
    cx, cy = size[0] // 2, size[1] // 2
    d1 = frame_from_map(rows, KEY, size, 2)
    d2 = I.new("RGBA", size, (0, 0, 0, 0))
    disc(d2, cx, cy, size[0] * 0.18, "acid1")
    d3 = I.new("RGBA", size, (0, 0, 0, 0))
    ring(d3, cx, cy, size[0] * 0.28, "acid0")
    d4 = I.new("RGBA", size, (0, 0, 0, 0))
    for dx, dy in [(-5, -3), (5, -5), (6, 4), (-6, 5), (0, -7)]:
        px, py = cx + dx, cy + dy
        if 0 <= px < size[0] and 0 <= py < size[1]:
            d4.putpixel((px, py), (106, 190, 48, 255))
    death = [d1, d2, d3, d4]
    dest = os.path.join(OUT, folder)
    os.makedirs(dest, exist_ok=True)
    save_strip(idle, os.path.join(dest, f"{name}_idle_2.png"))
    save_strip(run, os.path.join(dest, f"{name}_run_6.png"))
    save_strip(hit, os.path.join(dest, f"{name}_hit_2.png"))
    save_strip(death, os.path.join(dest, f"{name}_death_4.png"))


def main():
    sheets("skitterer", SKITTERER, (16, 16), "enemies/skitterer", move="scuttle")
    sheets("spitter", SPITTER, (16, 16), "enemies/spitter")
    sheets("bio_turret", BIO_TURRET, (16, 16), "enemies/bio_turret")
    sheets("blob", BLOB, (16, 16), "enemies/blob")
    sheets("hive_queen", QUEEN, (32, 32), "boss")


if __name__ == "__main__":
    main()
