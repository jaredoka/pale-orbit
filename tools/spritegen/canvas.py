"""Frame/strip helpers: string pixel maps -> PNG horizontal strips (no scaling)."""
from PIL import Image

from palette import PAL, rgba


def frame_from_map(rows: list[str], key: dict[str, str], size: tuple[int, int],
                   dy: int = 0) -> Image.Image:
    """rows: strings of palette-key chars ('.' = transparent). Centered in size."""
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    w = max(len(r) for r in rows)
    ox = (size[0] - w) // 2
    oy = (size[1] - len(rows)) // 2 + dy
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch != ".":
                img.putpixel((ox + x, oy + y), rgba(PAL[key[ch]]))
    return img


def whiteout(img: Image.Image) -> Image.Image:
    """Hit-flash: every opaque non-outline pixel -> white."""
    out = img.copy()
    outline = rgba(PAL["outline"])
    for y in range(out.height):
        for x in range(out.width):
            p = out.getpixel((x, y))
            if p[3] > 0 and p != outline:
                out.putpixel((x, y), rgba(PAL["white"]))
    return out


def disc(img: Image.Image, cx: int, cy: int, r: float, color: str) -> None:
    c = rgba(PAL[color])
    for y in range(img.height):
        for x in range(img.width):
            if (x - cx) ** 2 + (y - cy) ** 2 <= r * r:
                img.putpixel((x, y), c)


def ring(img: Image.Image, cx: int, cy: int, r: float, color: str) -> None:
    c = rgba(PAL[color])
    for y in range(img.height):
        for x in range(img.width):
            d2 = (x - cx) ** 2 + (y - cy) ** 2
            if (r - 0.8) ** 2 <= d2 <= (r + 0.8) ** 2:
                img.putpixel((x, y), c)


def save_strip(frames: list[Image.Image], path: str) -> None:
    w, h = frames[0].size
    strip = Image.new("RGBA", (w * len(frames), h), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        strip.paste(f, (i * w, 0))
    strip.save(path)
    print("wrote", path, strip.size)
