---
name: pixel-art-sheets
description: Generate Enter-the-Gungeon-style pixel-art sprite sheets (PNG) for Pale Orbit — palette, sizes, frame counts, strip layout, Pillow generation approach, and Godot import settings. Use for all M4 art tasks (T20–T22).
---

# Generating Pale Orbit sprite sheets

## Style rules (Gungeon-inspired, space/alien theme)
- Characters 16–24 px tall, drawn on a fixed pixel grid — every asset at the same pixel density.
- Big readable silhouettes, large expressive eyes (2×2 or 3×2 px whites with 1 px pupil), 1 px dark outline (not pure black — use `#1a1622`).
- Squash-and-stretch: run cycles compress 1 px on contact frames, stretch 1 px on airborne frames; enemies pulse/breathe in idle.
- Light source top-left: 1-shade highlight on top-left edges, 1-shade shadow bottom-right.

## Palette (fixed — do not invent colors)
| Role | Hex ramp |
|---|---|
| Outline / darkest | `#1a1622` |
| Hull grays (tiles, armor) | `#2b2938 → #454358 → #6b6884 → #9b97b0` |
| Player suit | `#c7cbd8` (suit), `#e8443f` (accent stripe), `#f5d76e` (visor) |
| Alien flesh | `#4a2d4e → #7a3b6d → #b3508a` |
| Acid green (alien shots, biomass) | `#3f7d20 → #6abe30 → #b6f34c` |
| Plasma cyan (player shots, consoles) | `#1b6f8a → #2fc6e0 → #a8f0ff` |
| Warning orange (telegraphs, FX) | `#c9401a → #f07f2d → #ffd166` |
| White flash / highlights | `#ffffff`, `#f0eef7` |

## Sheet spec (matches ART-1/ART-2 in docs/REQUIREMENTS.md)
- PNG, RGBA, transparent background. Horizontal strip, frames left→right, uniform frame size (e.g. 24×24 per frame → `player_run_6.png` is 144×24).
- Frame counts: idle 2f, run 6f, hit 2f, death 4f. Projectiles 2f spin/pulse. FX (muzzle flash 3f, impact 4f, death-poof 5f).
- Naming `<entity>_<anim>_<framecount>.png`; folders per HANDOFF §4 (`assets/sprites/player/`, `assets/sprites/enemies/<name>/`, `assets/tiles/`, ...).
- Directional characters: separate `_down`, `_up`, `_side` strips for run (side is flipped in-engine for left); enemies may be single-facing if their design reads omnidirectionally (blobs, turrets).
- Tileset: 16×16 tiles in one `station_tileset.png` atlas — floor plates (2 variants), wall top/face, corners, vents, console (2f glow handled as alt tile), biomass overlay tiles (4).

## Generation approach (Python + Pillow)
Write generator scripts in `tools/spritegen/` (one per entity, shared `palette.py` + `canvas.py` helpers), run with `python tools/spritegen/gen_player.py`. Rules:
- Draw programmatically pixel-by-pixel / with small primitive helpers (ellipse-ish blobs, symmetry mirroring) — never scale down large images (kills the pixel grid).
- `Image.new("RGBA", (w*frames, h))`, paste per-frame canvases; save with no interpolation.
- Keep generators in the repo — art is regenerable and tweakable by re-running scripts. Commit both scripts and PNGs.
- Iterate: generate → view (`start file.png` opens Windows viewer, but you can Read the PNG directly to inspect it) → adjust. **Read every generated sheet back** to check silhouette, palette compliance, and outline before wiring it into scenes.

## Godot import settings
For every imported texture: filter **Nearest** (inherited from project default — verify), Mipmaps **off**, Fix Alpha Border **on**. Animations wired via `AnimatedSprite2D`/`SpriteFrames` at: idle 4 fps, run 10 fps, hit 12 fps, death 10 fps (no loop on hit/death).

## Definition of done per art task
1. Sheets exist at spec'd paths/names/sizes; palette-only colors (spot-check by reading the image).
2. Read back each PNG and confirm it visually reads as its entity at 1× — if it's mush, iterate before integrating.
3. In-game: animations play at listed fps, pixels stay crisp at 3× window (ART-3), and the user confirms the style read.
