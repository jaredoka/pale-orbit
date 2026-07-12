extends EnemyBase
## Skitterer: fast chaser; brief overshoot lunge when within 48 px (ENM-1).

const CHASE_SPEED := 55.0
const LUNGE_SPEED := 120.0
const LUNGE_RANGE := 48.0
const LUNGE_TIME := 0.35
const LUNGE_COOLDOWN := 1.2

var _lunge_timer: float = 0.0
var _cooldown: float = 0.0
var _lunge_dir: Vector2 = Vector2.ZERO


func _behave(delta: float) -> void:
	var target := _player()
	if target == null:
		velocity = Vector2.ZERO
		return
	_cooldown = maxf(_cooldown - delta, 0.0)
	if _lunge_timer > 0.0:
		_lunge_timer -= delta
		velocity = _lunge_dir * LUNGE_SPEED  # keeps direction → overshoots
		return
	var to_player := target.global_position - global_position
	if to_player.length() < LUNGE_RANGE and _cooldown <= 0.0:
		_lunge_dir = to_player.normalized()
		_lunge_timer = LUNGE_TIME
		_cooldown = LUNGE_COOLDOWN
		velocity = _lunge_dir * LUNGE_SPEED
	else:
		velocity = velocity.move_toward(to_player.normalized() * CHASE_SPEED, 300.0 * delta)
