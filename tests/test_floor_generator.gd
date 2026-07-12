extends SceneTree
## Headless tests for FloorGenerator invariants over 100 seeds (GEN-1..4, NFR-4).
## Run: godot --headless --path . --script res://tests/test_floor_generator.gd

var _failures: int = 0


func _init() -> void:
	var generator: FloorGenerator = load("res://scripts/floor_generator.gd").new()

	# GEN-2 determinism
	for s in [1, 42, 999]:
		_check(_snapshot(generator.generate(s)) == _snapshot(generator.generate(s)),
				"seed %d: same seed → identical floor" % s)
	_check(_snapshot(generator.generate(1)) != _snapshot(generator.generate(2)),
			"different seeds differ")

	# GEN-1/3/4 invariants over 100 seeds
	for s in 100:
		var rooms: Dictionary = generator.generate(s, 9)
		var label := "seed %d: " % s
		_check(rooms.size() >= 8 and rooms.size() <= 10, label + "count in [8,10]")
		_check(rooms.has(Vector2i.ZERO), label + "has START at (0,0)")

		var counts := {0: 0, 1: 0, 2: 0, 3: 0}
		for data: RoomData in rooms.values():
			counts[data.type] += 1
		_check(counts[FloorGenerator.RoomType.START] == 1, label + "exactly one START")
		_check(counts[FloorGenerator.RoomType.BOSS] == 1, label + "exactly one BOSS")
		_check(counts[FloorGenerator.RoomType.TREASURE] == 1, label + "exactly one TREASURE")

		# connectivity: BFS from START reaches all
		var seen := {Vector2i.ZERO: true}
		var queue: Array[Vector2i] = [Vector2i.ZERO]
		while not queue.is_empty():
			var cur: Vector2i = queue.pop_front()
			for n: Vector2i in rooms[cur].doors:
				if not seen.has(n):
					seen[n] = true
					queue.append(n)
		_check(seen.size() == rooms.size(), label + "all rooms BFS-reachable")

		# door symmetry + doors = occupied cardinal neighbors
		var doors_ok := true
		var no_2x2 := true
		for data: RoomData in rooms.values():
			for n: Vector2i in data.doors:
				if not rooms.has(n) or not (rooms[n].doors.has(data.coord)):
					doors_ok = false
				if (n - data.coord).length_squared() != 1:
					doors_ok = false
			if rooms.has(data.coord + Vector2i.RIGHT) \
					and rooms.has(data.coord + Vector2i.DOWN) \
					and rooms.has(data.coord + Vector2i(1, 1)):
				no_2x2 = false
			if data.type == FloorGenerator.RoomType.BOSS:
				_check(data.doors.size() == 1, label + "boss is a dead-end")
		_check(doors_ok, label + "door symmetry")
		_check(no_2x2, label + "no 2x2 blocks")

	print("FAILURES: %d" % _failures)
	quit(1 if _failures > 0 else 0)


func _snapshot(rooms: Dictionary) -> String:
	var keys: Array = rooms.keys()
	keys.sort()
	var parts: PackedStringArray = []
	for k: Vector2i in keys:
		var doors: Array = rooms[k].doors.duplicate()
		doors.sort()
		parts.append("%s:%d:%s" % [k, rooms[k].type, doors])
	return ";".join(parts)


func _check(cond: bool, label: String) -> void:
	if not cond:
		push_error("FAIL: " + label)
		_failures += 1
