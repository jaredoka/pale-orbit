"""Build the four boss animation sheets (idle_2, run_6, hit_2, death_4) at
64x64 frames from the drone_boss v3 raw (64-grid art, black outline).
Direct integer BOX downscale (512 -> 64) keeps every art pixel crisp —
no trim/fit step, which would break the 1:1 grid mapping."""
from PIL import Image
import os

S = 64
root = os.path.join(os.path.dirname(__file__), "..", "..")
raw = Image.open(os.path.join(root, "art", "raw", "drone_boss_v3.png")).convert("RGBA")
src = raw.resize((S, S), Image.BOX)
r, g, b, a = src.split()
a = a.point(lambda v: 255 if v >= 128 else 0)
src = Image.merge("RGBA", (r, g, b, a))
out_dir = os.path.join(root, "assets", "sprites", "boss")

def shifted(dy: int) -> Image.Image:
    f = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    f.paste(src, (0, dy))
    return f

def flashed() -> Image.Image:
    f = src.copy()
    px = f.load()
    for y in range(S):
        for x in range(S):
            r_, g_, b_, a_ = px[x, y]
            if a_ > 0:
                px[x, y] = (240, 238, 247, 255)
    return f

def faded(alpha: float) -> Image.Image:
    f = src.copy()
    px = f.load()
    for y in range(S):
        for x in range(S):
            r_, g_, b_, a_ = px[x, y]
            if a_ > 0:
                px[x, y] = (r_, g_, b_, int(a_ * alpha))
    return f

def sheet(name: str, frames: list) -> None:
    im = Image.new("RGBA", (S * len(frames), S), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        im.paste(f, (i * S, 0))
    path = os.path.join(out_dir, name)
    im.save(path)
    print("wrote", path)

sheet("drone_boss_idle_2.png", [shifted(0), shifted(-1)])
sheet("drone_boss_run_6.png", [shifted(0), shifted(-1), shifted(-2), shifted(-1), shifted(0), shifted(1)])
sheet("drone_boss_hit_2.png", [flashed(), shifted(0)])
sheet("drone_boss_death_4.png", [shifted(0), faded(0.75), faded(0.5), faded(0.25)])
