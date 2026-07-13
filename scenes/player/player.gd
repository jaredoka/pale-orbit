extends CharacterBody2D
## Player: 8-dir movement (move_*), 4-dir shooting (shoot_*), health via GameState,
## 1.0 s i-frames with sprite blink after any hit (PLR-4).

const IFRAME_TIME := 1.0

var projectile_pool: ProjectilePool

var _iframes: float = 0.0

@onready var shoot_timer: Timer = $ShootTimer
@onready var sprite: AnimatedSprite2D = $Anim
@onready var hurtbox: Area2D = $HurtBox
@onready var gun: AnimatedSprite2D = $Gun
@onready var head: Sprite2D = $Head

const SHEETS := "res://assets/sprites/player/"

# Composable handgun, two-handed hold, cosmetic skins (IAP). Skin convention
# v2 (art/scripts/gun_plasma_blaster_v4.py): 16x16 frames, gun points right,
# hands drawn on the sprite, pivot at pixel (7, 8) pinned to the Gun node
# origin, muzzle tip at x = 14 (7px forward). Skins are cosmetic only: a gun
# strip (1+ frames), a projectile animation, and a shop icon. Equipped via
# GameState.gun_skin.
const GUN_PIVOT := Vector2(7.5, 8.5)
const GUN_MUZZLE_LEN := 7.0
const GUN_CENTER := Vector2(0.0, 3.0)   # held at mid-torso
const GUN_REACH := 4.0                  # pushed toward the aim direction
const GUN_SKINS := {
	&"plasma": {path = SHEETS + "gun_plasma_blaster.png", frames = 1, fps = 1.0,
			projectile = &"plasma"},
	&"electric": {path = SHEETS + "gun_electric_2.png", frames = 2, fps = 6.0,
			projectile = &"electric"},
}

var _projectile_anim: StringName = &"plasma"

var _head_tex: Dictionary = {}
var _aim: Vector2 = Vector2.DOWN  # head + gun direction (shoot dir wins over move dir)
var _bob: float = 0.0  # follows the body's 1px squash frames


func _ready() -> void:
	sprite.sprite_frames = SpriteSheets.build({
		&"idle": {path = SHEETS + "player_body_idle_2.png", frames = 2, fps = 4.0},
		&"run_down": {path = SHEETS + "player_body_run_down_6.png", frames = 6, fps = 10.0},
		&"run_up": {path = SHEETS + "player_body_run_up_6.png", frames = 6, fps = 10.0},
		&"run_side": {path = SHEETS + "player_body_run_side_6.png", frames = 6, fps = 10.0},
		&"hit": {path = SHEETS + "player_body_hit_2.png", frames = 2, fps = 12.0, loop = false},
		&"death": {path = SHEETS + "player_death_4.png", frames = 4, fps = 10.0, loop = false},
	})
	sprite.play(&"idle")
	_head_tex = {
		Vector2.DOWN: load(SHEETS + "player_head_down.png"),
		Vector2.UP: load(SHEETS + "player_head_up.png"),
		Vector2.RIGHT: load(SHEETS + "player_head_side.png"),
		Vector2.LEFT: load(SHEETS + "player_head_side.png"),
	}
	# Death frames are a full composite (head baked in) — hide the overlays.
	sprite.animation_changed.connect(func() -> void:
		var dead := sprite.animation == &"death"
		head.visible = not dead
		gun.visible = not dead)
	var muzzle: AnimatedSprite2D = $Muzzle
	muzzle.sprite_frames = SpriteSheets.build({
		&"flash": {path = "res://assets/sprites/fx/muzzle_flash_3.png", frames = 3, fps = 20.0, loop = false},
	})
	muzzle.animation_finished.connect(func() -> void: muzzle.visible = false)
	muzzle.visible = false
	_equip_gun_skin(GameState.gun_skin)
	sprite.frame_changed.connect(_sync_bob)
	_set_aim(Vector2.DOWN)


func _equip_gun_skin(skin_name: StringName) -> void:
	var skin: Dictionary = GUN_SKINS.get(skin_name, GUN_SKINS[&"plasma"])
	gun.sprite_frames = SpriteSheets.build({
		&"idle": {path = skin.path, frames = skin.frames, fps = skin.fps},
	})
	gun.offset = Vector2(8.0, 8.0) - GUN_PIVOT
	gun.play(&"idle")
	_projectile_anim = skin.projectile


## Head and gun both face `dir` (a cardinal). Gun pivots around the hand
## anchor; aiming up tucks the gun behind the body.
func _set_aim(dir: Vector2) -> void:
	_aim = dir
	head.texture = _head_tex[dir]
	head.flip_h = dir == Vector2.LEFT
	gun.rotation = dir.angle()
	gun.flip_v = dir.x < 0.0  # keep the gun upright when aiming left
	gun.position = GUN_CENTER + dir * GUN_REACH + Vector2(0.0, _bob)
	gun.z_index = -1 if dir == Vector2.UP else 0


## Body squash frames (idle breathe, run contact) shift 1px down; the head
## and gun overlays follow so the character stays one connected piece.
func _sync_bob() -> void:
	var squash := (sprite.animation == &"idle" and sprite.frame == 1) \
			or (sprite.animation in [&"run_down", &"run_up", &"run_side"]
			and sprite.frame in [0, 3])
	_bob = 1.0 if squash else 0.0
	head.position.y = _bob
	gun.position = GUN_CENTER + _aim * GUN_REACH + Vector2(0.0, _bob)


## Shoot direction wins; otherwise face the dominant axis of movement.
func _update_aim(move_dir: Vector2) -> void:
	for action: StringName in SHOOT_ACTIONS:
		if Input.is_action_pressed(action):
			_set_aim(SHOOT_ACTIONS[action])
			return
	if move_dir != Vector2.ZERO:
		var cardinal := Vector2.RIGHT if move_dir.x > 0.0 else Vector2.LEFT
		if absf(move_dir.y) > absf(move_dir.x):
			cardinal = Vector2.DOWN if move_dir.y > 0.0 else Vector2.UP
		if cardinal != _aim:
			_set_aim(cardinal)


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
	_update_aim(dir)
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
				position = gun.global_position + SHOOT_ACTIONS[action] * GUN_MUZZLE_LEN,
				direction = SHOOT_ACTIONS[action],
				speed = GameState.stats.shot_speed,
				damage = GameState.stats.damage,
				range = GameState.stats.range,
				faction = &"player",
				scale = GameState.stats.shot_scale,
				anim = _projectile_anim,
			})
			shoot_timer.start(1.0 / GameState.stats.fire_rate)
			AudioManager.play_sfx(&"shoot")
			_flash_muzzle(SHOOT_ACTIONS[action])
			return


func _flash_muzzle(dir: Vector2) -> void:
	var muzzle: AnimatedSprite2D = $Muzzle
	muzzle.position = gun.position + dir * GUN_MUZZLE_LEN
	muzzle.visible = true
	muzzle.play(&"flash")


func _update_iframes(delta: float) -> void:
	if _iframes > 0.0:
		_iframes -= delta
		var shown := fmod(_iframes, 0.2) > 0.1  # blink
		sprite.visible = shown
		head.visible = shown
		gun.visible = shown
		if _iframes <= 0.0:
			sprite.visible = true
			head.visible = true
			gun.visible = true


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
