extends EnemyBase
## Hive Queen (BOS-1/2): P1 radial 8-shot spreads every 2 s + Skitterer spawns.
## P2 (≤50% HP, T16): roar telegraph, 12-shot spreads every 1.2 s, telegraphed charge.

const SKITTERER_SCENE := "res://scenes/enemies/Skitterer.tscn"
const DRIFT_SPEED := 15.0
const SHOT_SPEED := 90.0
const SHOT_DAMAGE := 0.5
const SHOT_RANGE := 400.0
const SPAWN_INTERVAL := 6.0
const SPAWN_CAP := 4

var _spread_timer: float = 0.0
var _spawn_timer: float = 0.0
var _minions: Array[EnemyBase] = []

@onready var hp_bar: Node2D = $HpBar


func _behave(delta: float) -> void:
	var target := _player()
	if target == null:
		velocity = Vector2.ZERO
		return
	velocity = (target.global_position - global_position).normalized() * DRIFT_SPEED

	_spread_timer += delta
	if _spread_timer >= 2.0:
		_spread_timer = 0.0
		_fire_spread(8)

	_spawn_timer += delta
	if _spawn_timer >= SPAWN_INTERVAL:
		_spawn_timer = 0.0
		_spawn_skitterers()
	hp_bar.queue_redraw()


func _fire_spread(count: int) -> void:
	for i in count:
		var angle := TAU * i / count
		GameState.projectile_pool.fire({
			position = global_position,
			direction = Vector2.from_angle(angle),
			speed = SHOT_SPEED,
			damage = SHOT_DAMAGE,
			range = SHOT_RANGE,
			faction = &"enemy",
		})


func _spawn_skitterers() -> void:
	_minions = _minions.filter(func(m: EnemyBase) -> bool: return is_instance_valid(m))
	for i in 2:
		if _minions.size() >= SPAWN_CAP:
			return
		var minion: EnemyBase = load(SKITTERER_SCENE).instantiate()
		minion.position = position + Vector2(-24 if i == 0 else 24, 20)
		get_parent().add_child(minion)
		_minions.append(minion)
		spawned.emit(minion)
