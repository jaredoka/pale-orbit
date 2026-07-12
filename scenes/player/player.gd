extends CharacterBody2D
## Player: 8-dir movement (move_*), 4-dir shooting (shoot_*), health via GameState,
## 1.0 s i-frames with sprite blink after any hit (PLR-4).

const IFRAME_TIME := 1.0

var projectile_pool: ProjectilePool

var _iframes: float = 0.0

@onready var shoot_timer: Timer = $ShootTimer
@onready var sprite: AnimatedSprite2D = $Anim
@onready var hurtbox: Area2D = $HurtBox

const SHEETS := "res://assets/sprites/player/"


func _ready() -> void:
	sprite.sprite_frames = SpriteSheets.build({
		&"idle": {path = SHEETS + "player_idle_2.png", frames = 2, fps = 4.0},
		&"run_down": {path = SHEETS + "player_run_down_6.png", frames = 6, fps = 10.0},
		&"run_up": {path = SHEETS + "player_run_up_6.png", frames = 6, fps = 10.0},
		&"run_side": {path = SHEETS + "player_run_side_6.png", frames = 6, fps = 10.0},
		&"hit": {path = SHEETS + "player_hit_2.png", frames = 2, fps = 12.0, loop = false},
		&"death": {path = SHEETS + "player_death_4.png", frames = 4, fps = 10.0, loop = false},
	})
	sprite.play(&"idle")
	var muzzle: AnimatedSprite2D = $Muzzle
	muzzle.sprite_frames = SpriteSheets.build({
		&"flash": {path = "res://assets/sprites/fx/muzzle_flash_3.png", frames = 3, fps = 20.0, loop = false},
	})
	muzzle.animation_finished.connect(func() -> void: muzzle.visible = false)
	muzzle.visible = false


func _update_anim(dir: Vector2) -> void:
	if sprite.animation == &"hit" and sprite.is_playing():
		return
	if dir == Vector2.ZERO:
		sprite.play(&"idle")
	elif absf(dir.x) >= absf(dir.y):
		sprite.play(&"run_side")
		sprite.flip_h = dir.x < 0.0
	else:
		sprite.flip_h = false
		sprite.play(&"run_up" if dir.y < 0.0 else &"run_down")

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
	_update_anim(dir)
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
			AudioManager.play_sfx(&"shoot")
			_flash_muzzle(SHOOT_ACTIONS[action])
			return


func _flash_muzzle(dir: Vector2) -> void:
	var muzzle: AnimatedSprite2D = $Muzzle
	muzzle.position = dir * 10.0
	muzzle.visible = true
	muzzle.play(&"flash")


func _update_iframes(delta: float) -> void:
	if _iframes > 0.0:
		_iframes -= delta
		sprite.visible = fmod(_iframes, 0.2) > 0.1  # blink
		if _iframes <= 0.0:
			sprite.visible = true


## Poll overlaps so standing inside an enemy re-damages once per i-frame window.
## (Enemy projectiles damage via projectile.gd body contact.)
func _check_contact_damage() -> void:
	for body in hurtbox.get_overlapping_bodies():
		var dmg: float = body.get(&"contact_damage") if body.get(&"contact_damage") != null else 0.0
		if dmg > 0.0:
			take_hit(dmg)
			return


func take_hit(amount: float) -> void:
	if _iframes > 0.0:
		return
	GameState.damage_player(amount)
	_iframes = IFRAME_TIME
	sprite.play(&"hit")
	AudioManager.play_sfx(&"hurt")
