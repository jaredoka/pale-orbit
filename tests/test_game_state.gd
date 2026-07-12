extends SceneTree
## Headless tests for GameState stat math, damage/heal clamping, item application.
## Run: godot --headless --path . --script res://tests/test_game_state.gd

var _failures: int = 0
var _died_count: int = 0


func _init() -> void:
	var gs: Node = load("res://autoload/game_state.gd").new()
	gs.player_died.connect(func() -> void: _died_count += 1)

	gs.start_run(1234)
	_check(gs.rng_seed == 1234, "seed stored")
	_check(gs.current_hp == 3.0 and gs.max_hp == 3.0, "starts at full base HP")
	_check(gs.stats.speed == 90.0 and gs.stats.fire_rate == 2.5, "base stats loaded")

	# damage / heal clamping
	gs.damage_player(0.5)
	_check(gs.current_hp == 2.5, "half-heart damage")
	gs.heal_player(10.0)
	_check(gs.current_hp == 3.0, "heal clamps at max_hp")
	gs.damage_player(99.0)
	_check(gs.current_hp == 0.0, "damage clamps at 0")
	_check(_died_count == 1, "player_died emitted once")
	gs.damage_player(1.0)
	_check(_died_count == 1, "player_died not re-emitted when dead")

	# apply_item stat math
	gs.start_run(1)
	var item: ItemDef = load("res://scripts/item_def.gd").new()
	item.fire_rate_mult = 1.4
	item.damage_add = 2.0
	item.speed_add = -15.0
	item.max_hp_add = 1.0
	gs.damage_player(1.0)
	gs.apply_item(item)
	_check(is_equal_approx(gs.stats.fire_rate, 3.5), "fire_rate mult")
	_check(is_equal_approx(gs.stats.damage, 5.5), "damage add")
	_check(is_equal_approx(gs.stats.speed, 75.0), "speed add (negative)")
	_check(gs.max_hp == 4.0, "max_hp container added")
	_check(gs.current_hp == 3.0, "max_hp_add heals by the added amount")
	_check(gs.collected_items.size() == 1, "item recorded")

	# restart resets everything
	gs.start_run(2)
	_check(gs.collected_items.is_empty() and gs.current_hp == 3.0 and is_equal_approx(gs.stats.fire_rate, 2.5), "start_run resets state")

	gs.free()
	print("FAILURES: %d" % _failures)
	quit(1 if _failures > 0 else 0)


func _check(cond: bool, label: String) -> void:
	if not cond:
		push_error("FAIL: " + label)
		_failures += 1
