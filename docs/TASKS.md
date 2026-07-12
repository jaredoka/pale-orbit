# Pale Orbit — Task Backlog (Vertical Slice)

Execute in ID order unless dependencies say otherwise. Per task: **Deps** (task IDs), **Reqs** (REQUIREMENTS.md IDs), **Files**, **Verify** (run via the `godot-verify` skill). **Model**: Sonnet = well-specified build work; Opus = algorithmic/creative work.

Status legend: `[ ]` todo · `[~]` in progress · `[x]` done. Update this file as tasks complete.

## M0 — Scaffold & player

- [x] **T01 · Project scaffold + settings** — Sonnet · Deps: — · Reqs: ART-3, NFR-2
  Create Godot project with settings table from ARCHITECTURE §1, folder layout §2, empty autoloads registered, InputMap actions §8.
  Files: `project.godot`, `autoload/game_state.gd`, `autoload/audio_manager.gd` (stubs)
  Verify: project opens headless with no errors (`godot --headless --path . --quit-after 2`); InputMap actions listed in project.godot.

- [x] **T02 · GameState core** — Sonnet · Deps: T01 · Reqs: PLR-3, ITM-3
  Implement `PlayerStats` + `ItemDef` Resources, GameState properties/signals/methods per ARCHITECTURE §3, `resources/stats/base_player_stats.tres`.
  Files: `scripts/player_stats.gd`, `scripts/item_def.gd`, `autoload/game_state.gd`
  Verify: headless test `tests/test_game_state.gd` — damage/heal clamping, `player_died` once, `apply_item` stat math.

- [x] **T03 · Player movement** — Sonnet · Deps: T01 · Reqs: PLR-1
  Player scene per ARCHITECTURE §5; placeholder rectangle sprite; test room scene with walls (`scenes/rooms/TestRoom.tscn`, temporary).
  Verify: play — WASD 8-dir, normalized diagonals, wall sliding.

- [x] **T04 · Shooting + projectile pool** — Sonnet · Deps: T02, T03 · Reqs: PLR-2, NFR-1
  `ProjectilePool` (§6), Projectile scene, 4-dir arrow-key shooting from stats; collision layers table §7.
  Verify: play — hold arrows while moving; projectiles die on walls/range; no node count growth over 30 s of firing (pool works).

## M1 — Combat & rooms

- [x] **T05 · Player health + i-frames** — Sonnet · Deps: T02, T03 · Reqs: PLR-3, PLR-4
  HurtBox, `GameState.damage_player`, 1 s i-frames with blink.
  Verify: play vs. a placeholder damage zone — one hit/second max, blink visible.

- [x] **T06 · HUD hearts** — Sonnet · Deps: T05 · Reqs: UI-1
  HUD in CanvasLayer, full/half/empty heart icons (placeholder), reacts to `hp_changed`.
  Verify: play — hearts track damage/heal including halves.

- [x] **T07 · EnemyBase + Skitterer** — Sonnet · Deps: T04, T05 · Reqs: ENM-1, ENM-5
  Base class per §5 (hp, hurtbox, flash, `died`), Skitterer chase+lunge.
  Verify: play in test room — kill it, take contact damage from it.

- [x] **T08 · Spitter + Bio-turret** — Sonnet · Deps: T07 · Reqs: ENM-2, ENM-3
  Enemy projectiles use the pool with `enemy_shots` faction.
  Verify: play — standoff behavior, burst timing, acid shots hurt player.

- [x] **T09 · Blob (splitter)** — Sonnet · Deps: T07 · Reqs: ENM-4
  Split-once on death; children register with room alive-count.
  Verify: play — kill blob → 2 small blobs → no further splits.

- [x] **T10 · Room lock/clear cycle** — Sonnet · Deps: T07 · Reqs: RM-1, RM-2
  Real `Room.tscn` + `Door.tscn` per §5; spawn markers; lock on entry, open on clear, `room_cleared`; cleared registry in GameState. Retire TestRoom.
  Verify: play — doors lock, clear opens them, Blob children keep room locked (with T09).

## M2 — Floor generation

- [ ] **T11 · FloorGenerator + unit tests** — **Opus** · Deps: T01 · Reqs: GEN-1..4, NFR-4
  Pure-logic generator per §4 + `RoomData`; full headless test suite (determinism, connectivity, dead-end invariants over 100 seeds).
  Files: `scripts/floor_generator.gd`, `scripts/room_data.gd`, `tests/test_floor_generator.gd`
  Verify: `godot --headless --script res://tests/test_floor_generator.gd` exits 0.

- [ ] **T12 · Main orchestrator + room instancing** — Sonnet · Deps: T10, T11 · Reqs: RM-3
  `Main.tscn` per §5: generate floor from `GameState.rng_seed` (support `--seed=` arg), instance START, wire doors to transitions, reposition player, camera snap.
  Verify: play with `--seed=42` twice — same layout; walk the whole floor.

- [ ] **T13 · Spawn layouts** — Sonnet · Deps: T10, T12 · Reqs: RM-4
  ≥4 hand-made NORMAL layouts mixing archetypes, chosen by seeded RNG.
  Verify: play two seeds — layout variety; same seed reproduces layouts.

- [ ] **T14 · Treasure & boss room shells** — Sonnet · Deps: T12 · Reqs: GEN-3, ITM-2 (partial)
  TREASURE room with pedestal (item wiring in T17), BOSS room shell (boss in T15); distinct door frames/tiles for special rooms (placeholder tint ok).
  Verify: play — furthest dead-end is boss room, treasure room has a pedestal.

## M3 — Boss, items, game flow

- [ ] **T15 · Hive Queen phase 1** — **Opus** · Deps: T12, T14 · Reqs: BOS-1
  Radial spreads (pool), Skitterer spawns with cap, boss HP bar (simple).
  Verify: play — pattern timings per spec; boss killable.

- [ ] **T16 · Hive Queen phase 2 + tuning** — **Opus** · Deps: T15 · Reqs: BOS-2, BOS-3
  Phase transition at 50%, roar telegraph, 12-shot spreads, telegraphed line charge; `boss_defeated` on death. Playtest-tune to be winnable at base stats.
  Verify: user playtests — beats it at base stats within a few attempts; transition fires once.

- [ ] **T17 · Pickups + item pedestal** — Sonnet · Deps: T02, T14 · Reqs: ITM-1, ITM-2, ITM-3, UI-1
  Heart pickups (half/full, remain when HP full), pedestal grants ItemDef, 3 item `.tres` files, HUD item icons.
  Verify: play — each item's stat change is measurable; overheal impossible.

- [ ] **T18 · Heart drops** — Sonnet · Deps: T10, T17 · Reqs: ITM-1
  Seeded ~15% half-heart drop chance on room clear.
  Verify: play several rooms — drops occur; same seed → same drops.

- [ ] **T19 · Win/lose flow** — Sonnet · Deps: T05, T16 · Reqs: UI-2, UI-3
  GameOver + WinScreen, gameplay freeze, `restart` → fresh run with new seed and fully reset GameState.
  Verify: die → restart → stats/items/HP/floor all reset; win → victory screen.

## M4 — Art & juice (use `pixel-art-sheets` skill)

- [ ] **T20 · Sprite generator toolkit + player sheets** — **Opus** · Deps: T19 · Reqs: ART-1, ART-2
  `tools/spritegen/` (palette.py, canvas.py, gen_player.py); player idle/run(3 facings)/hit/death; wire AnimatedSprite2D.
  Verify: read PNGs back for style/palette compliance; in-game animations at spec fps; user approves the look.

- [ ] **T21 · Enemy + boss sheets** — **Opus** · Deps: T20 · Reqs: ART-1, ART-2
  Sheets for 4 archetypes + Hive Queen (both phases' tint/telegraph frames); wire animations.
  Verify: as T20; silhouettes distinguishable at 1×.

- [ ] **T22 · Tileset, items, FX, UI art** — **Opus** · Deps: T20 · Reqs: ART-1, ART-2, ART-3
  Station tileset (+biomass), heart/item icons, muzzle/impact/poof FX, door frames, heart HUD icons; retile rooms.
  Verify: full-run screenshot review with user; pixel grid uniform everywhere.

- [ ] **T23 · SFX + juice pass** — Sonnet · Deps: T20 · Reqs: ENM-5, NFR-1
  AudioManager real impl, SFX (shoot/hit/death/door/pickup/boss roar — generated or CC0), subtle screen shake, hit-flash shader, death poofs.
  Verify: play — every listed event has audible/visible feedback; 60 fps under projectile stress (NFR-1).

- [ ] **T24 · Slice acceptance pass** — **Opus** · Deps: T21, T22, T23 · Reqs: all
  Walk every requirement's AC; fix gaps; confirm HANDOFF "definition of done": full run spawn→item→boss kill with final art, no crashes.
  Verify: checklist of every requirement ID with pass/fail; user does a full playthrough.

## Icebox (M5 — post-slice, do not start)
Mobile touch joysticks + Android/iOS export presets · gamepad bindings + remapping UI · item synergies · coins/keys/bombs/shop economy · secret rooms · minimap · meta unlocks · music.
