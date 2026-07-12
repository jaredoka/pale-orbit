# Pale Orbit — Requirements (Vertical Slice)

Each requirement has an ID, a statement, and acceptance criteria (AC). Tasks in `TASKS.md` cite these IDs; a task is done only when its cited ACs pass. Terms and names are defined in `ARCHITECTURE.md`.

## PLR — Player

- **PLR-1 Movement.** 8-directional movement via `move_*` actions at `stats.speed`.
  AC: diagonals are normalized (no speed boost); player slides along walls; W/A/S/D each work.
- **PLR-2 Shooting.** Holding a `shoot_*` action fires 4-directional projectiles at `stats.fire_rate`, with `stats.damage/shot_speed/range`.
  AC: holding an arrow key fires continuously at the stat rate; projectiles despawn after `range` px or on wall hit; shooting works while moving in a different direction.
- **PLR-3 Health.** Hearts with 0.5 granularity; damage reduces `current_hp`; death at 0.
  AC: half-heart damage renders as a half heart in HUD; `player_died` fires exactly once at 0 HP.
- **PLR-4 I-frames.** 1.0 s invulnerability after taking damage, with sprite blink.
  AC: overlapping two enemies costs at most one hit per second; blink visible; no damage taken during i-frames.

## GEN — Floor generation

- **GEN-1 Layout.** `FloorGenerator.generate(seed)` produces 8–10 connected rooms on a grid via random walk, no 2×2 blocks.
  AC: unit test — all rooms BFS-reachable from START; count in [8,10]; no 2×2 clusters.
- **GEN-2 Determinism.** Same seed → identical floor.
  AC: unit test — two calls with the same seed produce deep-equal output; different seeds differ.
- **GEN-3 Special rooms.** Exactly one START at (0,0), one BOSS at the furthest dead-end, one TREASURE at another dead-end.
  AC: unit test over 100 seeds — invariants hold for every seed (with the bounded-regeneration fallback in ARCHITECTURE §4).
- **GEN-4 Doors.** Each room's `doors` lists exactly its occupied cardinal neighbors.
  AC: unit test — door symmetry (A lists B ⇔ B lists A).

## RM — Rooms & flow

- **RM-1 Lock/clear.** Entering a room with living enemies locks all doors; killing all enemies (including Blob children) opens them and emits `room_cleared`.
  AC: doors visibly close/open; Blob split children keep the room locked until also dead.
- **RM-2 Persistence.** Cleared rooms stay cleared on revisit; no enemy respawn.
  AC: re-entering a cleared room leaves doors open.
- **RM-3 Transitions.** Walking into an unlocked door swaps to the adjacent room; player appears just inside the matching opposite door; camera snaps to the new room.
  AC: no frame where both rooms are visible; player never spawns inside a wall.
- **RM-4 Spawn variety.** NORMAL rooms pick 1 of ≥4 hand-made spawn layouts via the seeded RNG.
  AC: two different NORMAL rooms in a run can have different layouts; same seed → same layouts.

## ENM — Enemies

- **ENM-1 Skitterer.** Chases the player; lunges within 48 px; contact damage 0.5 heart.
- **ENM-2 Spitter.** Maintains 96–128 px standoff; fires an acid projectile every 1.5 s.
- **ENM-3 Bio-turret.** Stationary; aimed 3-shot burst every 2.5 s; no contact damage.
- **ENM-4 Blob.** Slow chaser; on death splits once into 2 half-scale blobs that do not split again.
- **ENM-5 Feedback.** All enemies flash white on hit and play a death effect (poof/frames).
  AC for ENM-1..4: behavior observable in a test room; kill each type with projectiles; damage numbers per ARCHITECTURE defaults; ENM-4 children counted by room lock (see RM-1).

## BOS — Hive Queen

- **BOS-1 Phase 1.** 300 HP; radial 8-shot spread every 2 s; spawns 2 Skitterers every 6 s (cap 4 alive).
- **BOS-2 Phase 2.** At ≤50% HP: roar telegraph, then 12-shot spreads every 1.2 s + telegraphed line charge every 5 s.
- **BOS-3 Victory.** Killing the boss emits `boss_defeated` → win screen (slice ends the run).
  AC: phase transition happens exactly once; charge has a ≥0.5 s visible telegraph; boss fight is winnable with base stats (playtest) and with all 3 items comfortably.

## ITM — Items & pickups

- **ITM-1 Life-support cells.** Heart pickups (half and full variants) heal on touch, never above `max_hp`; full-HP player still collects nothing / pickup remains (choose: remains).
  AC: overheal impossible; pickup stays if HP is full.
- **ITM-2 Tech modules.** Treasure room pedestal grants one of the 3 `ItemDef`s (Overclocked Coil, Dense Plating, Plasma Focus); effect applies immediately via `GameState.apply_item`.
  AC: fire rate/speed/damage measurably change; Dense Plating adds a heart container and current HP; HUD updates.
- **ITM-3 Item pipeline.** Items are `.tres` Resources; adding a 4th item requires no code changes beyond a new `.tres` (unless it needs a new stat hook).
  AC: demonstrated by the 3 items sharing one `ItemDef` script.

## UI — Interface

- **UI-1 HUD.** Hearts row (full/half/empty) top-left, updating on `hp_changed`; item icons appended on `item_collected`.
- **UI-2 Game over.** On `player_died`: freeze gameplay, show Game Over screen, `restart` action starts a new run with a new seed.
- **UI-3 Win.** On `boss_defeated`: show victory screen with restart option.
  AC: HUD readable at 480×270; restart fully resets GameState (stats, items, HP, floor).

## ART — Art & rendering

- **ART-1 Sprite sheets.** Final art per HANDOFF §4 spec: PNG strips, idle 2f / run 6f / hit 2f / death 4f, naming `<entity>_<anim>_<framecount>.png`, folder layout under `assets/`.
- **ART-2 Style.** Gungeon-inspired: 16–24 px characters, dark station tiles with neon accents (acid green / plasma cyan / warning orange), expressive eyes, squash-and-stretch run.
- **ART-3 Rendering.** 480×270 base viewport, nearest filtering, pixel snap, integer scaling only.
  AC: no blurry sprites at any window size; no mixed-resolution pixels (all art on the same pixel grid).

## NFR — Non-functional

- **NFR-1 Performance.** ≥60 fps with 100 live pooled projectiles + 12 enemies on a mid-range desktop.
- **NFR-2 Input abstraction.** No raw keycode polling anywhere (`grep -r "Key\." scripts scenes` finds no input logic hits); all input via InputMap actions.
- **NFR-3 Headless-checkable.** All `.gd` files pass `godot --headless --check-only`-style script validation; pure-logic tests run headless (see `.claude/skills/godot-verify`).
- **NFR-4 Determinism boundary.** All gameplay randomness (floor gen, spawn layout choice) flows from `GameState.rng_seed`; cosmetic randomness (particles) may be unseeded.
