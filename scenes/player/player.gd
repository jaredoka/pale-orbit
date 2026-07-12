extends CharacterBody2D
## Player: 8-dir movement (move_*), 4-dir shooting (shoot_*), health via GameState,
## 1.0 s i-frames with sprite blink after any hit (PLR-4).

const IFRAME_TIME := 1.0

var projectile_pool: ProjectilePool

var _iframes: float = 0.0

@onready var shoot_timer: Timer = $ShootTimer
@onready var sprite: Sprite2D = $Sprite2D
@onready var hurtbox: Area2D = $HurtBox

const SHOOT_ACTIONS := {
	&"shoot_up": Vector2.UP,
	&"shoot_down": Vector2.DOWN,
	&"shoot_left": Vector2.LEFT,
	&"shoot_right": Vector2.RIGHT,
}


func _physics_process(delta: float) -> void:
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = dir * GameState.stats.speed
	move_and_slide()
	_try_shoot()
	_update_iframes(delta)
	if _iframes <= 0.0:
		_check_contact_damage()


func _try_shoot() -> void:
	if projectile_pool == null or not shoot_timer.is_stopped():
		return
	for action: StringName in SHOOT_ACTIONS:
		if Input.is_action_pressed(action):
			projectile_pool.fire({
				position = global_position,
				direction = SHOOT_ACTIONS[action],
				speed = GameState.stats.shot_speed,
				damage = GameState.stats.damage,
				range = GameState.stats.range,
				faction = &"player",
				scale = GameState.stats.shot_scale,
			})
			shoot_timer.start(1.0 / GameState.stats.fire_rate)
			return


func _update_iframes(delta: float) -> void:
	if _iframes > 0.0:
		_iframes -= delta
		sprite.visible = fmod(_iframes, 0.2) > 0.1  # blink
		if _iframes <= 0.0:
			sprite.visible = true


## Poll overlaps so standing inside an enemy re-damages once per i-frame window.
func _check_contact_damage() -> void:
	for body in hurtbox.get_overlapping_bodies():
		var dmg: float = body.get(&"contact_damage") if body.get(&"contact_damage") != null else 0.0
		if dmg > 0.0:
			_take_hit(dmg)
			return
	for area in hurtbox.get_overlapping_areas():
		if area.get(&"active") and area.get(&"faction") == &"enemy":
			area.deactivate()
			_take_hit(area.damage)
			return


func _take_hit(amount: float) -> void:
	GameState.damage_player(amount)
	_iframes = IFRAME_TIME
