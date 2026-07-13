"""Player sprite sheets: idle 2f, run down/up/side 6f, hit 2f, death 4f. 24x24 frames."""
import os

from canvas import frame_from_map, whiteout, disc, ring, save_strip

SIZE = (24, 24)
OUT = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "sprites", "player")

KEY = {
    "o": "outline", "s": "suit", "S": "hull3", "r": "accent",
    "p": "outline", "w": "hi", "g": "hull1", "c": "cyan1",
    # alien head
    "F": "flesh1", "f": "flesh2", "d": "flesh0", "a": "acid1", "e": "acid2",
}

# 16 wide x 18 tall body (legs appended per pose, 3 rows).
# Alien hero: flesh dome head, antennae with acid tips, big acid eyes; keeps
# the white hero suit on the torso so the player reads distinct from enemies.
BODY_DOWN = [
    "....e......e....",
    "....o......o....",
    "...oFFFFFFFFo...",
    "..oFfFFFFFFfFo..",
    "..oFaaFFFFaaFo..",
    "..oFapFFFFapFo..",
    "..oFFFFFFFFFFo..",
    "...oFFFFFFFo....",
    "..ossssssssso...",
    ".osssrrrrssso...",
    ".osssrrrrsssso..",
    ".osssssssssso...",
    ".osSssssssSso...",
    "..osssssssso....",
    "...osssssso.....",
]
BODY_UP = [
    "....e......e....",
    "....o......o....",
    "...oFFFFFFFFo...",
    "..oFffFFFFFFFo..",
    "..oFFFFFFFFFFo..",
    "..oFFFFdddFFFo..",
    "..oFFFFFFFFFFo..",
    "...oFFFFFFFo....",
    "..ossssssssso...",
    ".ossgggggssso...",
    ".ossgggggsssso..",
    ".ossgggggssso...",
    ".osSssssssSso...",
    "..osssssssso....",
    "...osssssso.....",
]
BODY_SIDE = [
    ".....e..........",
    ".....o..........",
    "...oFFFFFFFo....",
    "..oFfFFFFFFFo...",
    "..oFFFaaaaFFo...",
    "..oFFFappaFFo...",
    "..oFFFFFFFFFo...",
    "...oFFFFFFo.....",
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


BLANK = "................"
HEAD_ROWS = 8  # rows 0-7 = antennae + head + neck; torso starts at row 8


def head_only(body):
    """Head rows in place, torso/legs blanked — same canvas position as full body."""
    return body[:HEAD_ROWS] + [BLANK] * (len(body) - HEAD_ROWS) + [BLANK] * 3


def body_only(body):
    """Torso rows in place, head blanked. Legs appended by pose()."""
    return [BLANK] * HEAD_ROWS + body[HEAD_ROWS:]


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
    # Headless body sheets — the head is a separate overlay sprite so it can
    # face the shoot direction independently of the movement direction.
    b_down, b_up, b_side = body_only(BODY_DOWN), body_only(BODY_UP), body_only(BODY_SIDE)
    idle = [pose(b_down, "stand", 0), pose(b_down, "stand", 1)]  # breathe
    save_strip(idle, os.path.join(OUT, "player_body_idle_2.png"))
    save_strip(run_cycle(b_down), os.path.join(OUT, "player_body_run_down_6.png"))
    save_strip(run_cycle(b_up), os.path.join(OUT, "player_body_run_up_6.png"))
    save_strip(run_cycle(b_side), os.path.join(OUT, "player_body_run_side_6.png"))
    base = pose(b_down, "stand", 0)
    save_strip([whiteout(base), base], os.path.join(OUT, "player_body_hit_2.png"))
    # Head overlays (one frame each; side flipped in-engine for left)
    for name, body in (("down", BODY_DOWN), ("up", BODY_UP), ("side", BODY_SIDE)):
        save_strip([frame_from_map(head_only(body), KEY, SIZE, 0)],
                   os.path.join(OUT, "player_head_%s.png" % name))
    # Death stays a full composite (head+body) — Head/Gun overlays hide on death.
    save_strip(death_frames(), os.path.join(OUT, "player_death_4.png"))


if __name__ == "__main__":
    main()
