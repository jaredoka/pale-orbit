extends CharacterBody2D
## Player: 8-dir movement (move_*), 4-dir shooting (shoot_*) from GameState.stats.

var projectile_pool: ProjectilePool

@onready var shoot_timer: Timer = $ShootTimer

const SHOOT_ACTIONS := {
	&"shoot_up": Vector2.UP,
	&"shoot_down": Vector2.DOWN,
	&"shoot_left": Vector2.LEFT,
	&"shoot_right": Vector2.RIGHT,
}


func _physics_process(_delta: float) -> void:
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = dir * GameState.stats.speed
	move_and_slide()
	_try_shoot()


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
			})
			shoot_timer.start(1.0 / GameState.stats.fire_rate)
			return
