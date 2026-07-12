"""Player sprite sheets: idle 2f, run down/up/side 6f, hit 2f, death 4f. 24x24 frames."""
import os

from canvas import frame_from_map, whiteout, disc, ring, save_strip

SIZE = (24, 24)
OUT = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "sprites", "player")

KEY = {
    "o": "outline", "s": "suit", "S": "hull3", "r": "accent",
    "v": "visor", "p": "outline", "w": "hi", "g": "hull1", "c": "cyan1",
}

# 16 wide x 18 tall body (legs appended per pose, 3 rows)
BODY_DOWN = [
    "....oooooo......",
    "...ossssssso....",
    "..osswwssssso...",
    "..ovvvvvvvvso...",
    "..ovppvvppvso...",
    "..ovvvvvvvvso...",
    "..ossssssssso...",
    "...osssssso.....",
    "..ossssssssso...",
    ".osssrrrrssso...",
    ".osssrrrrsssso..",
    ".osssssssssso...",
    ".osSssssssSso...",
    "..osssssssso....",
    "...osssssso.....",
]
BODY_UP = [
    "....oooooo......",
    "...ossssssso....",
    "..osswwssssso...",
    "..ossssssssso...",
    "..ossssssssso...",
    "..ossssssssso...",
    "..ossssssssso...",
    "...osssssso.....",
    "..ossssssssso...",
    ".ossgggggssso...",
    ".ossgggggsssso..",
    ".ossgggggssso...",
    ".osSssssssSso...",
    "..osssssssso....",
    "...osssssso.....",
]
BODY_SIDE = [
    "....oooooo......",
    "...ossssssso....",
    "..osswwsssso....",
    "..osssvvvvvo....",
    "..osssvvppvo....",
    "..osssvvvvvo....",
    "..osssssssso....",
    "...osssssso.....",
    "..ossssssso.....",
    ".osssrrsssso....",
    ".osssrrsssso....",
    ".ossssssssso....",
    ".osSsssssSso....",
    "..ossssssso.....",
    "...ossssso......",
]

LEGS = {
    "stand": ["...osso.osso....",
              "...osso.osso....",
              "...oSSo.oSSo...."],
    "l_fwd": ["..osso..osso....",
              "..osso...osso...",
              "..oSSo...oSSo..."],
    "r_fwd": ["....osso.osso...",
              "...osso...osso..",
              "...oSSo...oSSo.."],
    "tuck":  ["...osso.osso....",
              "...oSSo.oSSo....",
              "................"],
}


def pose(body, legs, dy=0):
    return frame_from_map(body + LEGS[legs], KEY, SIZE, dy)


def run_cycle(body):
    # contact frames squash 1 px down (dy=1), airborne tuck frames lift 1 px
    return [
        pose(body, "l_fwd", 1),
        pose(body, "tuck", 0),
        pose(body, "stand", 0),
        pose(body, "r_fwd", 1),
        pose(body, "tuck", 0),
        pose(body, "stand", 0),
    ]


def death_frames():
    import PIL.Image as I
    f1 = pose(BODY_DOWN, "tuck", 3)
    f2 = frame_from_map(BODY_DOWN[8:], KEY, SIZE, 6)  # collapsed torso
    f3 = I.new("RGBA", SIZE, (0, 0, 0, 0))
    disc(f3, 12, 14, 4, "cyan1")
    ring(f3, 12, 14, 7, "cyan0")
    f4 = I.new("RGBA", SIZE, (0, 0, 0, 0))
    ring(f4, 12, 14, 9, "cyan0")
    for x, y in [(5, 8), (18, 6), (20, 16), (4, 18), (12, 3)]:
        f4.putpixel((x, y), (168, 240, 255, 255))
    return [f1, f2, f3, f4]


def main():
    os.makedirs(OUT, exist_ok=True)
    idle = [pose(BODY_DOWN, "stand", 0), pose(BODY_DOWN, "stand", 1)]  # breathe
    save_strip(idle, os.path.join(OUT, "player_idle_2.png"))
    save_strip(run_cycle(BODY_DOWN), os.path.join(OUT, "player_run_down_6.png"))
    save_strip(run_cycle(BODY_UP), os.path.join(OUT, "player_run_up_6.png"))
    save_strip(run_cycle(BODY_SIDE), os.path.join(OUT, "player_run_side_6.png"))
    base = pose(BODY_DOWN, "stand", 0)
    save_strip([whiteout(base), base], os.path.join(OUT, "player_hit_2.png"))
    save_strip(death_frames(), os.path.join(OUT, "player_death_4.png"))


if __name__ == "__main__":
    main()
