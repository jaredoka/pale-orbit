# Pale Orbit — agent guide

Space-themed roguelike: Binding of Isaac gameplay, Enter the Gungeon pixel art. Godot 4, typed GDScript. Desktop first (WASD move, arrow keys shoot); must stay mobile-safe.

## Read before working
1. `HANDOFF.md` — game design, scope, milestones
2. `docs/ARCHITECTURE.md` — **authoritative** names, scene trees, signals, folders. Follow exactly; if a change is needed, update the doc in the same commit.
3. `docs/REQUIREMENTS.md` — requirement IDs + acceptance criteria
4. `docs/TASKS.md` — the backlog. Work one task at a time, in dependency order.

## GitFlow (mandatory every session)
Follow `docs/GITFLOW.md`: work on `feature/tXX-*` branches off `develop`, merge `--no-ff` after verification, cut `release/mX` per milestone to `main` (tagged). Never commit to `main` directly. Remote: https://github.com/jaredoka/pale-orbit

## Hard rules
- Input via InputMap actions only — never poll raw keys (NFR-2).
- `FloorGenerator` is pure logic (no node access), deterministic per seed — don't break its unit tests (GEN-2).
- Items are `ItemDef` `.tres` Resources applied through `GameState.apply_item()` — no hardcoded item effects.
- Pooled projectiles: never `queue_free()` or instantiate at fire time.
- All cross-scene communication via `GameState` signals — no node-path reaching between scenes.
- Rendering: 480×270, nearest filter, integer scaling, pixel snap. Don't touch these settings.

## Verification
Use the `godot-verify` skill after every task (parse check, headless tests in `tests/`, play verification). Art tasks use the `pixel-art-sheets` skill (palette and sheet spec live there). A task is done only when its cited requirement ACs pass.

## High-fidelity art (pixel-art-32)
For detailed one-off art beyond programmatic sheets (bosses, portraits, key art), use the user-level `pixel-art-32` skill (Claude-written Pillow drawing → optional cleanup → post-process). In this repo: output **PNG** (not WebP) with `--png`, place finals under `assets/sprites/` per `docs/ARCHITECTURE.md`, keep intermediates (`art/raw`, `art/cutout`) out of git, match the project palette from `pixel-art-sheets` where sizes overlap, and apply the standard Godot import settings (nearest filter, no mipmaps). Animated sheets remain `pixel-art-sheets` territory.
