extends EnemyBase
## Hive Queen (BOS-1/2/3): P1 radial 8-shot spreads every 2 s + Skitterer spawns.
## P2 at ≤50% HP: roar telegraph once, then 12-shot spreads every 1.2 s and a
## line charge at the player every 5 s with a 0.6 s telegraph.

const SKITTERER_SCENE := "res://scenes/enemies/Skitterer.tscn"
const DRIFT_SPEED := 15.0
const SHOT_SPEED := 90.0
const SHOT_DAMAGE := 0.5
const SHOT_RANGE := 400.0
const SPAWN_INTERVAL := 6.0
const SPAWN_CAP := 4

const ROAR_TIME := 0.8
const P1_SPREAD_INTERVAL := 2.0
const P2_SPREAD_INTERVAL := 1.2
const CHARGE_INTERVAL := 5.0
const CHARGE_TELEGRAPH := 2.0
const CHARGE_SPEED := 230.0
const CHARGE_TIME := 0.55

enum Phase { ONE, ROAR, TWO }

var phase: Phase = Phase.ONE

var _spread_timer: float = 0.0
var _spawn_timer: float = 0.0
var _roar_timer: float = 0.0
var _charge_timer: float = 0.0
var _telegraph_timer: float = 0.0
var _charging_timer: float = 0.0
var _charge_dir: Vector2 = Vector2.ZERO
var _minions: Array[EnemyBase] = []

@onready var hp_bar: Node2D = $HpBar


func _behave(delta: float) -> void:
	var target := _player()
	if target == null:
		velocity = Vector2.ZERO
		return
	hp_bar.queue_redraw()

	if phase == Phase.ONE and hp <= max_hp * 0.5:
		phase = Phase.ROAR
		_roar_timer = ROAR_TIME
		sprite.modulate = Color(3.0, 1.2, 1.2)  # roar telegraph tint
		AudioManager.play_sfx(&"roar")

	match phase:
		Phase.ONE:
			velocity = (target.global_position - global_position).normalized() * DRIFT_SPEED
			_tick_spread(delta, P1_SPREAD_INTERVAL, 8)
			_tick_spawns(delta)
		Phase.ROAR:
			velocity = Vector2.ZERO
			_roar_timer -= delta
			if _roar_timer <= 0.0:
				sprite.modulate = Color.WHITE
				phase = Phase.TWO
				_charge_timer = 0.0
		Phase.TWO:
			_tick_spread(delta, P2_SPREAD_INTERVAL, 12)
			_tick_spawns(delta)
			_tick_charge(delta, target)


func _tick_spread(delta: float, interval: float, count: int) -> void:
	_spread_timer += delta
	if _spread_timer >= interval:
		_spread_timer = 0.0
		_fire_spread(count)


func _tick_spawns(delta: float) -> void:
	_spawn_timer += delta
	if _spawn_timer >= SPAWN_INTERVAL:
		_spawn_timer = 0.0
		_spawn_skitterers()


func _tick_charge(delta: float, target: Node2D) -> void:
	if _charging_timer > 0.0:
		_charging_timer -= delta
		velocity = _charge_dir * CHARGE_SPEED
		if _charging_timer <= 0.0:
			sprite.modulate = Color.WHITE
		return
	if _telegraph_timer > 0.0:
		velocity = Vector2.ZERO
		_telegraph_timer -= delta
		if _telegraph_timer <= 0.0:
			sprite.modulate = Color.WHITE
			_charge_dir = (target.global_position - global_position).normalized()
			_charging_timer = CHARGE_TIME
		return
	velocity = (target.global_position - global_position).normalized() * DRIFT_SPEED
	_charge_timer += delta
	if _charge_timer >= CHARGE_INTERVAL:
		_charge_timer = 0.0
		_telegraph_timer = CHARGE_TELEGRAPH
		sprite.modulate = Color(3.0, 2.0, 0.8)  # charge telegraph tint


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
		var spawn_pos := position + Vector2(-24 if i == 0 else 24, 20)
		minion.position = Vector2(
			clampf(spawn_pos.x, 32.0, 448.0), clampf(spawn_pos.y, 32.0, 238.0))
		get_parent().add_child(minion)
		_minions.append(minion)
		spawned.emit(minion)
