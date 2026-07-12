# Pale Orbit — Technical Architecture (Godot 4, GDScript)

Companion to `../HANDOFF.md` §5. This is the authoritative structural spec: implementing agents must follow the names, signals, and layouts here exactly. If a change is genuinely needed, update this document in the same commit.

## 1. Engine & project settings

Godot **4.x** (latest stable 4.3+), GDScript only, typed GDScript throughout.

`project.godot` settings checklist (task T01):

| Setting | Value |
|---|---|
| `display/window/size/viewport_width` / `height` | 480 × 270 |
| `display/window/size/window_width_override` / `height` | 1440 × 810 (3× default window) |
| `display/window/stretch/mode` | `canvas_items` |
| `display/window/stretch/aspect` | `keep` |
| `display/window/stretch/scale_mode` | `integer` |
| `rendering/textures/canvas_textures/default_texture_filter` | `Nearest` |
| `rendering/2d/snap/snap_2d_transforms_to_pixel` | `true` |
| `rendering/2d/snap/snap_2d_vertices_to_pixel` | `true` |
| `physics/common/physics_ticks_per_second` | 60 |

## 2. Folder layout

```
res://
  project.godot
  autoload/
    game_state.gd          # GameState singleton
    audio_manager.gd       # AudioManager singleton
  scenes/
    main/Main.tscn          main.gd            # run orchestrator
    player/Player.tscn      player.gd
    player/Projectile.tscn  projectile.gd      # shared by player & enemies (config differs)
    enemies/EnemyBase.tscn  enemy_base.gd      # abstract base; never instanced directly
    enemies/Skitterer.tscn  skitterer.gd
    enemies/Spitter.tscn    spitter.gd
    enemies/BioTurret.tscn  bio_turret.gd
    enemies/Blob.tscn       blob.gd
    boss/HiveQueen.tscn     hive_queen.gd
    rooms/Room.tscn         room.gd
    rooms/Door.tscn         door.gd
    items/Pickup.tscn       pickup.gd          # hearts (life-support cells)
    items/ItemPedestal.tscn item_pedestal.gd   # holds an ItemDef
    ui/HUD.tscn             hud.gd
    ui/GameOver.tscn        game_over.gd
    ui/WinScreen.tscn       win_screen.gd
  scripts/
    floor_generator.gd     # class_name FloorGenerator — pure logic, NOT an autoload node
    player_stats.gd        # class_name PlayerStats (Resource)
    item_def.gd            # class_name ItemDef (Resource)
    projectile_pool.gd     # class_name ProjectilePool
    room_data.gd           # class_name RoomData (RefCounted) — generator output
  resources/
    items/                 # .tres ItemDef files
    stats/base_player_stats.tres
  assets/                  # see HANDOFF §4 for sprite layout
  tests/                   # GDScript unit tests for pure logic (see godot-verify skill)
```

Conventions: `snake_case` files, `PascalCase` class names and scenes, one `class_name` per file, typed signatures (`func take_damage(amount: float) -> void`). No `@onready` chains into other scenes — communicate via signals or GameState.

## 3. Autoloads (registered in this order)

### `GameState` (`autoload/game_state.gd`)
Owns run state. **The only global mutable state in the game.**

```gdscript
# Properties
var stats: PlayerStats            # current run stats (duplicated from base .tres at run start)
var current_hp: float             # in half-hearts internally? NO — float hearts, 0.5 granularity
var max_hp: float
var collected_items: Array[ItemDef]
var rng_seed: int                 # set at run start; passed to FloorGenerator
var current_room: Vector2i        # grid coord of active room
var floor_rooms: Dictionary       # { Vector2i: RoomData } — set by Main; HUD minimap reads it

# Signals (global event bus — emit here, never node-to-node across scenes)
signal hp_changed(current: float, max: float)
signal player_died
signal item_collected(item: ItemDef)
signal room_entered(coord: Vector2i)
signal room_cleared(coord: Vector2i)
signal boss_defeated
signal run_won

# Methods
func start_run(seed: int = -1) -> void       # -1 = randomize
func apply_item(item: ItemDef) -> void       # applies stat deltas, emits item_collected
func damage_player(amount: float) -> void    # clamps, emits hp_changed / player_died
func heal_player(amount: float) -> void
```

### `AudioManager` (`autoload/audio_manager.gd`)
`func play_sfx(name: StringName) -> void`, `func play_music(name: StringName) -> void`. Pool of 8 `AudioStreamPlayer`s. Stub with no-ops until M4.

**Note:** `FloorGenerator` is **not** an autoload — it is a pure `RefCounted` class instantiated by `Main` so it stays unit-testable headless.

## 4. Floor generation (`scripts/floor_generator.gd`)

Pure logic, deterministic: same seed → same floor. No node/scene access.

```gdscript
class_name FloorGenerator

enum RoomType { START, NORMAL, TREASURE, BOSS }

# RoomData (scripts/room_data.gd):
#   coord: Vector2i, type: RoomType, doors: Array[Vector2i]  (neighbor coords)

func generate(seed: int, room_count: int = 9) -> Dictionary:
    # returns { Vector2i: RoomData }
```

Algorithm (Isaac-style):
1. Place START at `(0,0)`. Random-walk on a grid using `RandomNumberGenerator` seeded with `seed`: repeatedly pick a random existing room, pick a random cardinal neighbor; add it if unoccupied, until `room_count` rooms exist (reject candidates that would create a 2×2 block — keeps corridor feel).
2. Compute BFS distance from START. The **dead-end (exactly 1 neighbor) with max distance** becomes BOSS. Next-furthest dead-end becomes TREASURE. If fewer than 2 dead-ends exist, regenerate with `seed + 1` (bounded to 20 attempts, then relax the dead-end constraint for TREASURE).
3. `doors` on each RoomData lists occupied neighbor coords.

Unit tests (`tests/test_floor_generator.gd`): determinism (same seed twice → identical output), room count, connectivity (BFS reaches all rooms), boss is a dead-end, exactly one START/BOSS/TREASURE.

## 5. Scene contracts

### `Main.tscn`
```
Main (Node2D) [main.gd]
├── RoomHolder (Node2D)        # active Room instance is a child here
├── Player (Player.tscn instance)
├── Camera2D                   # snaps to room center on room_entered
├── ProjectileLayer (Node2D)   # pooled projectiles live here (survive room swaps)
└── UILayer (CanvasLayer)
    └── HUD (HUD.tscn instance)
```
`main.gd`: calls `GameState.start_run()`, runs `FloorGenerator.generate()`, instantiates the START room, handles room transitions (on player entering a Door: free/hide old room, instance new room, reposition player just inside the matching door, tween/snap camera, emit `GameState.room_entered`). Listens for `player_died` → GameOver, `boss_defeated` → WinScreen (slice = 1 floor, so boss kill wins the run).

### `Player.tscn`
```
Player (CharacterBody2D, layer=player)
├── Sprite2D (or AnimatedSprite2D from M4)
├── CollisionShape2D
├── ShootTimer (Timer)         # wait_time derived from stats.fire_rate
└── HurtBox (Area2D)           # monitors enemy & enemy_shot layers
```
- Movement: 8-dir from `move_*` actions, `velocity = dir * stats.speed`, `move_and_slide()`.
- Shooting: 4-dir from `shoot_*` actions (arrow keys); while held and `ShootTimer` ready, request a projectile from the pool with `stats.damage / shot_speed / range`.
- Damage: on HurtBox contact call `GameState.damage_player()`; 1.0 s i-frames (sprite blink, HurtBox disabled).
- Player reads/writes **only** `GameState.stats` — never local stat copies.

### `EnemyBase.tscn` / `enemy_base.gd`
```
EnemyBase (CharacterBody2D, layer=enemies)
├── Sprite2D
├── CollisionShape2D
└── HurtBox (Area2D)           # monitors player_shots
```
```gdscript
class_name EnemyBase
signal died(enemy: EnemyBase)
@export var max_hp: float = 10.0
@export var contact_damage: float = 0.5     # half a heart
func take_damage(amount: float) -> void     # flash white, die at 0
func _behave(delta: float) -> void          # overridden per archetype
```
Archetypes override `_behave`:
- **Skitterer**: accelerate toward player; brief overshoot lunge when within 48 px.
- **Spitter**: keep 96–128 px distance (approach/retreat), fire an acid projectile every 1.5 s.
- **BioTurret**: static; 3-shot burst aimed at player every 2.5 s; `contact_damage = 0`.
- **Blob**: slow chase; on death spawn 2 half-scale blobs (once — small blobs don't split). Room's alive-count must account for spawned children.

### `Room.tscn` / `room.gd`
```
Room (Node2D)
├── TileMapLayer (walls + floor; walls on layer=walls) — placeholder until M4: StaticBody2D wall segments + ColorRect visuals (T22 retiles with the real tileset)
├── Doors (Node2D)             # up to 4 Door instances, positioned N/E/S/W
└── (spawn layouts are LAYOUTS constants in room.gd, picked by seeded RNG — no marker nodes)
```
- `func setup(data: RoomData) -> void` — enables doors matching `data.doors`, populates enemies for NORMAL/BOSS, pedestal for TREASURE.
- On player entry with living enemies: close/lock all doors, spawn enemies (0.4 s telegraph poof), track `died` signals (and Blob spawns). When count hits 0 → open doors, emit `GameState.room_cleared`. Cleared rooms stay cleared (`GameState` keeps a `cleared: Dictionary[Vector2i, bool]`).
- `Door`: Area2D; locked = solid + closed sprite; unlocked = trigger that tells Main to transition.
- v1 ships 4–6 hand-made spawn layouts for NORMAL rooms; `setup` picks one via the seeded RNG.

### `HiveQueen.tscn` (extends EnemyBase)
- `max_hp = 250`. Phase 1: radial 8-shot spreads every 2 s + spawn 2 Skitterers every 6 s (cap 4 alive). Phase 2 at ≤50% HP: brief roar telegraph, then spreads every 1.2 s become 12-shot, plus a line-charge attack at the player every 5 s (telegraphed 0.6 s). On death emit `died`; the boss Room emits `GameState.boss_defeated` when its clear cycle completes (spawned Skitterers must also be dead).

## 6. Projectiles & pooling

`Main` creates the pool and assigns it to `GameState.projectile_pool`; player and enemies fire through that reference (no node-path reaching).

`ProjectilePool` (plain class) pre-instantiates **64 player + 64 enemy** projectiles under `ProjectileLayer`, all inactive. `func fire(config: Dictionary) -> void` activates one (position, direction, speed, damage, range, faction). Projectile deactivates on: wall hit, hurtbox hit, or traveled distance > range. **Never `queue_free()` pooled projectiles; never instantiate at fire time.**

## 7. Collision layers

| # | Layer name | Collides with (mask) |
|---|---|---|
| 1 | `walls` | — |
| 2 | `player` | walls |
| 3 | `enemies` | walls, enemies |
| 4 | `player_shots` | walls, enemies |
| 5 | `enemy_shots` | walls, player |
| 6 | `pickups` | player |

Contact damage via Area2D overlap (player HurtBox monitoring `enemies` + `enemy_shots`), not physics collision.

## 8. Input

InputMap actions only — **never poll raw keycodes** (mobile/gamepad depend on this):
`move_up/down/left/right` → W/S/A/D; `shoot_up/down/left/right` → arrow keys; `pause` → Esc; `restart` → R (on death/win screens).

## 9. Data-driven items

`ItemDef` (Resource): `id: StringName`, `display_name: String`, `description: String`, `icon: Texture2D`, and stat deltas `speed_add`, `fire_rate_mult`, `damage_add`, `shot_speed_add`, `range_add`, `max_hp_add`, `shot_scale_mult: float` (Plasma Focus's larger shots). `GameState.apply_item()` folds deltas into `stats` (additive first, then multiplicative) and heals any `max_hp_add`.

`PlayerStats` (Resource): `speed = 90.0` px/s, `fire_rate = 2.5` shots/s, `damage = 3.5`, `shot_speed = 200.0` px/s, `range = 180.0` px, `max_hp = 3.0` hearts.

v1 items (`resources/items/*.tres`): `overclocked_coil` (fire_rate ×1.4), `dense_plating` (+1 max_hp, −15 speed), `plasma_focus` (+2 damage, projectile scale 1.5×).

## 10. Mobile-safe rules (enforced from T01)

1. InputMap only (§8) — touch joysticks bind later without code changes.
2. All UI in `CanvasLayer` with anchors; min touch target 48 px at final scale; no hover-only UI.
3. Projectile pooling (§6); target 60 fps with 100 live projectiles + 12 enemies.
4. No per-frame allocations in `_process`/`_physics_process` hot paths.
5. Integer scaling only; test window resize doesn't distort pixels.
