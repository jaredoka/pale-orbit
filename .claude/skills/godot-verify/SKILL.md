---
name: godot-verify
description: Verify Pale Orbit Godot 4 work without the editor — script parse checks, headless unit tests for pure logic, and launching the game for play verification. Use after completing any task in docs/TASKS.md.
---

# Verifying Godot work headless

## 0. Locate Godot
Try in order: `godot --version`, `godot4 --version`, check `C:\Program Files\Godot\` and `%LOCALAPPDATA%\Programs\Godot\`. If no binary is found, STOP and tell the user to install Godot 4.3+ and put it on PATH — do not fake verification.

## 1. Script parse check (every task)
```
godot --headless --path . --check-only --script res://scenes/player/player.gd
```
Faster whole-project smoke: import + quit —
```
godot --headless --path . --quit-after 2
```
Zero parse errors/warnings-as-errors in output = pass. Any `SCRIPT ERROR` = fail; fix before marking the task done.

## 2. Pure-logic unit tests (FloorGenerator, stats math)
No test framework dependency — tests are plain scripts extending `SceneTree` in `tests/`, run directly:
```
godot --headless --path . --script res://tests/test_floor_generator.gd
```
Test script pattern:
```gdscript
extends SceneTree
func _init() -> void:
    var failures := 0
    failures += _check(FloorGenerator.new().generate(42).size() >= 8, "room count")
    # ... more checks ...
    print("FAILURES: %d" % failures)
    quit(1 if failures > 0 else 0)

func _check(cond: bool, label: String) -> int:
    if not cond: push_error("FAIL: " + label)
    return 0 if cond else 1
```
Exit code 0 = pass. Every task touching `scripts/floor_generator.gd` or `GameState` stat math MUST run these.

## 3. Play verification (gameplay tasks)
```
godot --path .
```
Launches windowed. Verify the task's specific "Verify" line from `docs/TASKS.md` by playing (movement feel, door locking, boss phases). For deterministic checks, run with a fixed seed: `godot --path . -- --seed=42` (Main reads `OS.get_cmdline_user_args()`).

You cannot see the game window — ask the user to play-verify anything visual/feel-based, and state exactly what they should check. Screenshots: `godot --path . --write-movie` is overkill; instead ask the user, or add a temporary debug print confirming the state transition (then remove it).

## 4. Definition of done (every task)
1. §1 parse check passes project-wide.
2. §2 tests pass if pure logic was touched.
3. Task's "Verify" step from `docs/TASKS.md` executed (or explicitly delegated to the user with instructions).
4. `grep` guard for NFR-2: no `Key\.` / `KEY_` input polling in gameplay scripts.
5. Cited requirement IDs' acceptance criteria re-read and satisfied.
