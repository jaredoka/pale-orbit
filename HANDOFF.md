# PALE ORBIT — Project Handoff Document

> Space-themed roguelike. **Binding of Isaac** gameplay, **Enter the Gungeon** art style.
> Status: design approved, execution pack written, implementation not yet started.
> Last updated: 2026-07-12.

**Documents index** (read in this order when picking up work):
1. This file — game design, scope, milestones
2. [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) — authoritative technical spec: scene trees, autoload APIs, signals, collision layers, conventions
3. [`docs/REQUIREMENTS.md`](docs/REQUIREMENTS.md) — testable requirements with acceptance criteria (IDs cited by tasks)
4. [`docs/TASKS.md`](docs/TASKS.md) — dependency-ordered backlog T01–T24 with per-task verification and model recommendations
5. [`.claude/CLAUDE.md`](.claude/CLAUDE.md) — agent guide + hard rules; skills: [`godot-verify`](.claude/skills/godot-verify/SKILL.md), [`pixel-art-sheets`](.claude/skills/pixel-art-sheets/SKILL.md)

---

## 1. Project Overview

**Working title:** Pale Orbit
**Pitch:** A lone explorer fights room by room through the alien-infested decks of a derelict station in decaying orbit. Each run the station reconfigures itself — new deck layouts, new alien threats, new salvaged tech.

- **Genre:** Top-down twin-stick roguelike (procedural runs, permadeath)
- **Gameplay inspiration:** The Binding of Isaac — room-grid floors, doors that lock during combat, stat-modifying pickups, half-heart health economy
- **Art inspiration:** Enter the Gungeon — chunky expressive pixel art, saturated accents on dark backgrounds, squash-and-stretch animation, punchy FX
- **Theme:** Sci-fi horror-lite. Rooms are ship compartments, corridors, and airlocks. Enemies are alien creatures; the floor boss is an alien monstrosity.

## 2. Confirmed Decisions

| Decision | Choice |
|---|---|
| Engine | **Godot 4** (GDScript) |
| Platform priority | **Desktop first**; mobile (touch, virtual joysticks) later — architecture must stay mobile-safe from day one |
| Controls (v1) | **WASD** = movement, **Arrow Keys** = directional shooting (classic Isaac scheme); gamepad later |
| v1 scope | **Vertical slice**: one floor, ~8–10 procedurally arranged rooms, 3–4 enemy types, item pickups, one boss |
| Art pipeline | **Generate pixel-art sprite sheets (PNG)** in Gungeon style as part of the build; placeholders allowed until M4 |
| Must-have mechanics | Twin-stick shooting + room-by-room clearing with locking doors |
| Deferred mechanics | Item synergies, full heart/coin/key/bomb economy, secret rooms, meta unlocks |

## 3. Gameplay Design (Isaac-inspired)

### Core loop
Enter room → doors lock → clear all aliens → doors open → explore adjacent rooms → find treasure → defeat boss → floor complete (run won, for the slice).

### Player
- 8-directional movement (WASD), 4-directional projectile shooting (Arrow Keys)
- Stats: **speed, fire rate, damage, shot speed, range** — all modifiable by items
- Health: hearts with **half-heart granularity**; brief invincibility frames + hit flash on damage
- Death = run over → game-over screen → restart run

### Floor generation
- Isaac-style **grid-based layout**: random-walk placement of ~8–10 rooms on a grid from a start room; dead-end furthest from start becomes the **boss room**, another dead-end becomes the **treasure room**
- Room types (v1): Start (safe), Normal (combat), Treasure (1 free item), Boss
- Doors connect adjacent grid rooms; camera snaps per room (one room per screen)

### Enemies (v1 — alien archetypes)
| Enemy | Behavior |
|---|---|
| Skitterer | Facehugger-like chaser; fast, melee contact damage |
| Spitter | Ranged alien; keeps distance, lobs acid projectiles |
| Bio-turret | Wall/floor-mounted growth; stationary, fires bursts at player |
| Blob | Gelatinous splitter; slow, splits into 2 smaller blobs on death |

**Boss:** Hive Queen (brood mother). Phase 1: projectile spreads + spawns Skitterers. Phase 2 (≤50% HP): faster patterns + charge attack.

### Pickups & items (v1)
- **Life-support cells** (heart refills, half and full)
- 2–3 passive **alien tech modules** proving the item pipeline, e.g.:
  - *Overclocked Coil* — +fire rate
  - *Dense Plating* — +1 heart container, −speed
  - *Plasma Focus* — +damage, larger shots

## 4. Art Direction (Gungeon-inspired)

### Look
- Chunky pixel art; character sprites ~**16–24 px** tall, rendered at integer scale only
- Dark sci-fi tiles: hull plating, vents, cabling, glowing consoles, creeping alien biomass — with **saturated neon accents** (acid green, plasma cyan, warning orange) popping against desaturated darks
- Gungeon-style personality: big expressive eyes, exaggerated squash-and-stretch run cycles, characters lean into movement direction
- Juicy FX: muzzle flash, impact bursts, death poofs, screen shake (subtle), hit-flash white

### Sprite sheet spec
- Format: PNG, transparent background, frames in a horizontal strip per animation (or grid per character)
- Frame counts: **idle 2f, run 6f, hit 2f, death 4f**; projectiles/FX 2–4f
- Naming: `<entity>_<anim>_<framecount>.png` → e.g. `player_run_6.png`, `skitterer_idle_2.png`
- Folder layout:
  ```
  assets/sprites/player/
  assets/sprites/enemies/<enemy_name>/
  assets/sprites/boss/
  assets/sprites/items/
  assets/sprites/fx/
  assets/tiles/          (station tileset + biomass variants)
  assets/ui/
  ```

### Rendering settings (Godot)
- Base viewport **480×270**, stretch mode `canvas_items`, aspect `keep`, **integer scaling**
- Texture filtering: **nearest** (project default); 2D pixel snap on
- No rotation-blur on sprites; flip-h for facing, dedicated frames for up/down

## 5. Technical Architecture (Godot 4)

### Project structure
```
res://
  project.godot
  autoload/            GameState.gd, FloorGenerator.gd, AudioManager.gd
  scenes/
    player/            Player.tscn (+ Projectile.tscn)
    enemies/           one scene per archetype; shared Enemy base script
    boss/              HiveQueen.tscn
    rooms/             Room.tscn + room content layouts; Door.tscn
    items/             Pickup.tscn, ItemPedestal.tscn
    ui/                HUD.tscn (hearts, minimap later), GameOver.tscn, Win.tscn
  scripts/             shared logic (stats resource, item definitions as Resources)
  assets/              per §4 folder layout
```

### Key rules
- **Input only via InputMap actions** (`move_up/down/left/right`, `shoot_up/down/left/right`) — never poll raw keys, so touch joysticks and gamepad bind later with zero code changes
- Items as Godot **Resources** (stat deltas + icon), applied to a central player stats object — this is the seed of the synergy system
- **Object pooling** for projectiles (player + enemy) — mobile performance budget from day one
- UI anchored and scalable; no hover-only or keyboard-only interactions in menus
- Floor generator is pure logic (testable without scenes): grid in → room graph out

## 6. Milestones

- **M0** — Godot project scaffold, rendering settings, InputMap; player movement + shooting in one test room (placeholder art)
- **M1** — Enemy archetypes, contact/projectile damage, hearts HP, room door locking/unlocking on clear
- **M2** — Floor generation, room transitions with camera snap, treasure/boss room placement
- **M3** — Hive Queen boss (2 phases), pickups + 2–3 item modules, win/lose flow
- **M4** — Generated Gungeon-style sprite sheets replace placeholders; SFX, screen shake, hit-flash, juice pass
- **M5 (post-slice)** — Mobile: touch virtual joysticks + Android/iOS export presets; then synergy items, full heart/coin/key economy, secret rooms

**Definition of done (vertical slice):** a full run — spawn → clear rooms → find an item → beat the Hive Queen — is playable start to finish on desktop with final art, no crashes.

## 7. Open Questions (decide later, not blockers)

- Meta-progression (unlockable characters/items between runs?)
- Audio direction (dark ambient vs. synthwave; music source)
- Control remapping UI and gamepad bindings
- Distribution (itch.io first? Steam? mobile stores?) and monetization
- Final title confirmation ("Pale Orbit")
