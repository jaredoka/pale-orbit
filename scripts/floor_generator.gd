class_name FloorGenerator
extends RefCounted
## Pure-logic Isaac-style floor generator. Deterministic per seed; no node access (GEN-1..4).

enum RoomType { START, NORMAL, TREASURE, BOSS }

const CARDINALS: Array[Vector2i] = [
	Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT,
]
const MAX_ATTEMPTS := 20


## Returns { Vector2i: RoomData }. Same seed → identical floor.
func generate(gen_seed: int, room_count: int = 9) -> Dictionary:
	for attempt in MAX_ATTEMPTS:
		var result := _try_generate(gen_seed + attempt, room_count, false)
		if not result.is_empty():
			return result
	# Bounded regeneration exhausted: relax the dead-end constraint for TREASURE.
	return _try_generate(gen_seed + MAX_ATTEMPTS, room_count, true)


func _try_generate(s: int, room_count: int, relaxed: bool) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = s
	var cells: Array[Vector2i] = [Vector2i.ZERO]  # ordered for deterministic picks
	var occupied := {Vector2i.ZERO: true}
	var guard := 0
	while cells.size() < room_count and guard < 2000:
		guard += 1
		var from: Vector2i = cells[rng.randi_range(0, cells.size() - 1)]
		var cand: Vector2i = from + CARDINALS[rng.randi_range(0, 3)]
		if occupied.has(cand) or _would_make_block(cand, occupied):
			continue
		cells.append(cand)
		occupied[cand] = true
	if cells.size() < room_count:
		return {}

	# BFS distances from START.
	var dist := {Vector2i.ZERO: 0}
	var queue: Array[Vector2i] = [Vector2i.ZERO]
	while not queue.is_empty():
		var cur: Vector2i = queue.pop_front()
		for dir in CARDINALS:
			var n: Vector2i = cur + dir
			if occupied.has(n) and not dist.has(n):
				dist[n] = dist[cur] + 1
				queue.append(n)

	# Dead-ends (exactly 1 occupied neighbor), excluding START; furthest first.
	var dead_ends: Array[Vector2i] = []
	for c in cells:
		if c != Vector2i.ZERO and _neighbor_count(c, occupied) == 1:
			dead_ends.append(c)
	dead_ends.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return dist[a] > dist[b] if dist[a] != dist[b] else (a < b))

	if dead_ends.is_empty():
		return {}
	var boss: Vector2i = dead_ends[0]
	var treasure := Vector2i.ZERO
	if dead_ends.size() >= 2:
		treasure = dead_ends[1]
	elif relaxed:
		# Furthest non-start, non-boss room regardless of dead-end status.
		var others: Array[Vector2i] = cells.filter(
			func(c: Vector2i) -> bool: return c != Vector2i.ZERO and c != boss)
		others.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
			return dist[a] > dist[b] if dist[a] != dist[b] else (a < b))
		treasure = others[0]
	else:
		return {}

	var rooms := {}
	for c in cells:
		var type := RoomType.NORMAL
		if c == Vector2i.ZERO:
			type = RoomType.START
		elif c == boss:
			type = RoomType.BOSS
		elif c == treasure:
			type = RoomType.TREASURE
		var data := RoomData.new(c, type)
		for dir in CARDINALS:
			if occupied.has(c + dir):
				data.doors.append(c + dir)
		rooms[c] = data
	return rooms


func _would_make_block(cand: Vector2i, occupied: Dictionary) -> bool:
	# Adding cand must not complete any 2×2 square of occupied cells.
	for corner: Vector2i in [
		cand, cand + Vector2i.LEFT, cand + Vector2i.UP, cand + Vector2i(-1, -1),
	]:
		var count := 0
		for offset: Vector2i in [Vector2i.ZERO, Vector2i.RIGHT, Vector2i.DOWN, Vector2i(1, 1)]:
			var cell := corner + offset
			if cell == cand or occupied.has(cell):
				count += 1
		if count == 4:
			return true
	return false


func _neighbor_count(c: Vector2i, occupied: Dictionary) -> int:
	var n := 0
	for dir in CARDINALS:
		if occupied.has(c + dir):
			n += 1
	return n
