extends EnemyBase
## Bio-turret: stationary growth; aimed 3-shot burst every 2.5 s; no contact damage (ENM-3).

const BURST_INTERVAL := 2.5
const BURST_COUNT := 3
const BURST_GAP := 0.12
const SHOT_SPEED := 130.0
const SHOT_DAMAGE := 0.5
const SHOT_RANGE := 300.0

var _timer: float = 0.0
var _burst_left: int = 0
var _burst_gap_timer: float = 0.0


func _behave(delta: float) -> void:
	velocity = Vector2.ZERO
	var target := _player()
	if target == null:
		return
	if _burst_left > 0:
		_burst_gap_timer -= delta
		if _burst_gap_timer <= 0.0:
			_shoot_at(target)
			_burst_left -= 1
			_burst_gap_timer = BURST_GAP
		return
	_timer += delta
	if _timer >= BURST_INTERVAL:
		_timer = 0.0
		_burst_left = BURST_COUNT
		_burst_gap_timer = 0.0


func _shoot_at(target: Node2D) -> void:
	GameState.projectile_pool.fire({
		position = global_position,
		direction = (target.global_position - global_position).normalized(),
		speed = SHOT_SPEED,
		damage = SHOT_DAMAGE,
		range = SHOT_RANGE,
		faction = &"enemy",
	})
