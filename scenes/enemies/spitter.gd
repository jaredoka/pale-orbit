extends EnemyBase
## Spitter: keeps 96–128 px standoff, lobs an acid projectile every 1.5 s (ENM-2).

const SPEED := 45.0
const MIN_DIST := 96.0
const MAX_DIST := 128.0
const FIRE_INTERVAL := 1.5
const SHOT_SPEED := 110.0
const SHOT_DAMAGE := 0.5
const SHOT_RANGE := 260.0

var _fire_timer: float = 0.0


func _behave(delta: float) -> void:
	var target := _player()
	if target == null:
		velocity = Vector2.ZERO
		return
	var to_player := target.global_position - global_position
	var dist := to_player.length()
	if dist < MIN_DIST:
		velocity = -to_player.normalized() * SPEED
	elif dist > MAX_DIST:
		velocity = to_player.normalized() * SPEED
	else:
		velocity = Vector2.ZERO
	_fire_timer += delta
	if _fire_timer >= FIRE_INTERVAL:
		_fire_timer = 0.0
		GameState.projectile_pool.fire({
			position = global_position,
			direction = to_player.normalized(),
			speed = SHOT_SPEED,
			damage = SHOT_DAMAGE,
			range = SHOT_RANGE,
			faction = &"enemy",
		})
