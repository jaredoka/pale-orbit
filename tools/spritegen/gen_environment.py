"""Environment art: station tileset atlas, heart/item icons, projectile + FX sheets,
door frames (T22)."""
import os

import PIL.Image as I

from canvas import frame_from_map, disc, ring, save_strip
from palette import PAL, rgba

ROOT = os.path.join(os.path.dirname(__file__), "..", "..", "assets")

KEY = {
    "o": "outline", "0": "hull0", "1": "hull1", "2": "hull2", "3": "hull3",
    "a": "acid1", "A": "acid2", "g": "acid0",
    "c": "cyan1", "C": "cyan2", "b": "cyan0",
    "r": "warn0", "R": "warn1", "y": "warn2", "w": "hi",
    "f": "flesh1", "F": "flesh2", "d": "flesh0",
}


def tile(rows):
    return frame_from_map(rows, KEY, (16, 16), 0)


FLOOR0 = ["0000000000000000"] * 16
FLOOR1 = [r for r in FLOOR0]
FLOOR1 = ["0000000000000000",
          "0111111111111110",
          "0100000000000010"] + ["0100000000000010"] * 11 + [
          "0111111111111110",
          "0000000000000000"]
WALL = (["2222222222222222",
         "3333333333333333"] +
        ["1111111111111111"] * 5 +
        ["1110111111101111"] +
        ["1111111111111111"] * 6 +
        ["0000000000000000"] * 2)
VENT = (["0000000000000000"] * 4 +
        ["0002222222220000",
         "0002111111120000",
         "0002222222220000",
         "0002111111120000",
         "0002222222220000",
         "0002111111120000",
         "0002222222220000"] +
        ["0000000000000000"] * 5)
CONSOLE = (["0000000000000000"] * 3 +
           ["0022222222220000",
            "0021bbbbbb120000",
            "0021bccccb120000",
            "0021bcCCcb120000",
            "0021bccccb120000",
            "0021bbbbbb120000",
            "0022222222220000"] +
           ["0000000000000000"] * 6)
BIOMASS = (["0000000000000000"] * 3 +
           ["0000gg0000000000",
            "000gaag000000000",
            "00gaAAag00000000",
            "00gaAAaag0000000",
            "000gaaaag0g00000",
            "0000ggaagag00000",
            "000000ggag000000",
            "00000000g0000000"] +
           ["0000000000000000"] * 5)


def tileset():
    tiles = [tile(FLOOR0), tile(FLOOR1), tile(WALL), tile(VENT),
             tile(CONSOLE), tile(BIOMASS)]
    atlas = I.new("RGBA", (16 * len(tiles), 16), (0, 0, 0, 0))
    for i, t in enumerate(tiles):
        atlas.paste(t, (i * 16, 0))
    dest = os.path.join(ROOT, "tiles")
    os.makedirs(dest, exist_ok=True)
    atlas.save(os.path.join(dest, "station_tileset.png"))
    print("wrote station_tileset.png", atlas.size)


HEART_FULL = ["..oo.oo.",
              ".orrorro",
              "orrrrrro",
              "orrRrrro",
              ".orrrro.",
              "..orro..",
              "...oo...",
              "........"]


def hearts():
    key = dict(KEY)
    key["r"] = "accent"
    key["R"] = "hi"
    full = frame_from_map(HEART_FULL, key, (8, 8), 0)
    half = full.copy()
    for y in range(8):
        for x in range(4, 8):
            p = half.getpixel((x, y))
            if p[3] > 0 and p != rgba(PAL["outline"]):
                half.putpixel((x, y), rgba(PAL["hull1"]))
    empty = full.copy()
    for y in range(8):
        for x in range(8):
            p = empty.getpixel((x, y))
            if p[3] > 0 and p != rgba(PAL["outline"]):
                empty.putpixel((x, y), rgba(PAL["hull1"]))
    dest = os.path.join(ROOT, "ui")
    os.makedirs(dest, exist_ok=True)
    for name, img in [("heart_full", full), ("heart_half", half), ("heart_empty", empty)]:
        img.save(os.path.join(dest, name + ".png"))
    print("wrote heart icons")


COIL = ["....oooo....",
        "..oobbbboo..",
        ".obccccccbo.",
        ".obcCwwCcbo.",
        ".obcCwwCcbo.",
        ".obccccccbo.",
        "..oobbbboo..",
        "....oooo....",
        "....o..o....",
        "...obccbo...",
        "....oooo....",
        "............"]
PLATING = ["....oooo....",
           "..oo3333oo..",
           ".o33RRRR33o.",
           ".o3RyyyyR3o.",
           ".o3RyyyyR3o.",
           ".o33RRRR33o.",
           "..o333333o..",
           "..o333333o..",
           "...o3333o...",
           "....o33o....",
           ".....oo.....",
           "............"]
FOCUS = ["....oooo....",
         "..oogggg....",
         ".ogaaAAago..",
         ".oaAAwwAAo..",
         ".oaAwwwwAo..",
         ".oaAAwwAAo..",
         ".ogaaAAago..",
         "..oogggg....",
         "....oooo....",
         "............",
         "............",
         "............"]


def items():
    dest = os.path.join(ROOT, "sprites", "items")
    os.makedirs(dest, exist_ok=True)
    for name, rows in [("overclocked_coil", COIL), ("dense_plating", PLATING),
                       ("plasma_focus", FOCUS)]:
        frame_from_map(rows, KEY, (12, 12), 0).save(
            os.path.join(dest, "item_" + name + ".png"))
    # pedestal base
    ped = frame_from_map(
        ["............",
         "............",
         "............",
         "............",
         "............",
         "...o2222o...",
         "...o1221o...",
         "....o11o....",
         "....o11o....",
         "...o2222o...",
         "..o333333o..",
         "..oooooooo.."], KEY, (12, 18), 3)
    ped.save(os.path.join(dest, "pedestal.png"))
    print("wrote item icons + pedestal")


def projectiles_fx():
    dest = os.path.join(ROOT, "sprites", "fx")
    os.makedirs(dest, exist_ok=True)
    for name, core, glow in [("plasma_bolt", "cyan2", "cyan1"), ("acid_glob", "acid2", "acid1")]:
        frames = []
        for r in (1.6, 2.2):
            f = I.new("RGBA", (8, 8), (0, 0, 0, 0))
            disc(f, 4, 4, r + 0.7, glow)
            disc(f, 4, 4, r - 0.4, core)
            frames.append(f)
        save_strip(frames, os.path.join(dest, f"{name}_2.png"))
    # muzzle flash 3f, impact 4f, poof 5f
    mf = []
    for r in (1.5, 2.5, 1.2):
        f = I.new("RGBA", (12, 12), (0, 0, 0, 0))
        disc(f, 6, 6, r, "cyan2")
        ring(f, 6, 6, r + 1.2, "cyan1")
        mf.append(f)
    save_strip(mf, os.path.join(dest, "muzzle_flash_3.png"))
    imp = []
    for i, r in enumerate((1.5, 2.6, 3.6, 4.4)):
        f = I.new("RGBA", (14, 14), (0, 0, 0, 0))
        (disc if i < 2 else ring)(f, 7, 7, r, "cyan1" if i % 2 else "cyan2")
        imp.append(f)
    save_strip(imp, os.path.join(dest, "impact_4.png"))
    poof = []
    for i, r in enumerate((2, 3.5, 4.5, 5.2, 5.8)):
        f = I.new("RGBA", (16, 16), (0, 0, 0, 0))
        (disc if i < 2 else ring)(f, 8, 8, r, "hi" if i < 2 else "hull3")
        poof.append(f)
    save_strip(poof, os.path.join(dest, "poof_5.png"))


def doors():
    dest = os.path.join(ROOT, "tiles")
    os.makedirs(dest, exist_ok=True)
    closed = frame_from_map(
        ["oooooooooooooooooooooooooooooooo",
         "o22222222222222222222222222222o.",
         "o21111111111111111111111111112o.",
         "o2111rr1111111rrrr1111111rr112o.",
         "o2111rr1111111rrrr1111111rr112o.",
         "o21111111111111111111111111112o.",
         "o2111111111111oooo111111111112o.",
         "o21111111111o211112o1111111112o.",
         "o21111111111o211112o1111111112o.",
         "o2111111111111oooo111111111112o.",
         "o21111111111111111111111111112o.",
         "o21111111111111111111111111112o.",
         "o21111111111111111111111111112o.",
         "o22222222222222222222222222222o.",
         "oooooooooooooooooooooooooooooooo",
         "................................"], KEY, (32, 16), 0)
    open_door = frame_from_map(
        ["oooooooooooooooooooooooooooooooo",
         "o2222oo.................oo2222o.",
         "o2111ao.................oa1112o.",
         "o2111ao.................oa1112o.",
         "o2111ao.................oa1112o.",
         "o2111ao.................oa1112o.",
         "o2111ao.................oa1112o.",
         "o2111ao.................oa1112o.",
         "o2111ao.................oa1112o.",
         "o2111ao.................oa1112o.",
         "o2111ao.................oa1112o.",
         "o2111ao.................oa1112o.",
         "o2111ao.................oa1112o.",
         "o2222oo.................oo2222o.",
         "oooooooooooooooooooooooooooooooo",
         "................................"], KEY, (32, 16), 0)
    closed.save(os.path.join(dest, "door_closed.png"))
    open_door.save(os.path.join(dest, "door_open.png"))
    print("wrote door frames")


if __name__ == "__main__":
    tileset()
    hearts()
    items()
    projectiles_fx()
    doors()
