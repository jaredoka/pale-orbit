"""Pale Orbit fixed palette (pixel-art-sheets skill). Do not invent colors."""

PAL = {
    "outline": "#1a1622",
    "hull0": "#2b2938", "hull1": "#454358", "hull2": "#6b6884", "hull3": "#9b97b0",
    "suit": "#c7cbd8", "accent": "#e8443f", "visor": "#f5d76e",
    "flesh0": "#4a2d4e", "flesh1": "#7a3b6d", "flesh2": "#b3508a",
    "acid0": "#3f7d20", "acid1": "#6abe30", "acid2": "#b6f34c",
    "cyan0": "#1b6f8a", "cyan1": "#2fc6e0", "cyan2": "#a8f0ff",
    "warn0": "#c9401a", "warn1": "#f07f2d", "warn2": "#ffd166",
    "white": "#ffffff", "hi": "#f0eef7",
}


def rgba(hex_color: str, a: int = 255) -> tuple:
    h = hex_color.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)
