extends Area2D
## Pooled projectile shared by player and enemies (faction set per fire).
## Never freed — deactivates back into the pool on wall hit, hurtbox hit, or max range.

const LAYER_PLAYER_SHOTS := 1 << 3
const LAYER_ENEMY_SHOTS := 1 << 4
const MASK_WALLS := 1 << 0
const MASK_PLAYER := 1 << 1
const MASK_ENEMIES := 1 << 2

var active: bool = false
var direction: Vector2 = Vector2.RIGHT
var speed: float = 200.0
var damage: float = 1.0
var max_range: float = 180.0
var faction: StringName = &"player"

var _traveled: float = 0.0

static var _shared_frames: SpriteFrames = null

@onready var anim: AnimatedSprite2D = $Anim


func _ready() -> void:
	if _shared_frames == null:
		_shared_frames = SpriteSheets.build({
			&"plasma": {path = "res://assets/sprites/fx/plasma_bolt_2.png", frames = 2, fps = 8.0},
			&"acid": {path = "res://assets/sprites/fx/acid_glob_2.png", frames = 2, fps = 8.0},
		})
	anim.sprite_frames = _shared_frames
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	deactivate()


func activate(config: Dictionary) -> void:
	position = config.position
	direction = (config.direction as Vector2).normalized()
	speed = config.speed
	damage = config.damage
	max_range = config.range
	faction = config.faction
	scale = Vector2.ONE * float(config.get("scale", 1.0))
	anim.play(&"plasma" if faction == &"player" else &"acid")
	if faction == &"player":
		collision_layer = LAYER_PLAYER_SHOTS
		collision_mask = MASK_WALLS | MASK_ENEMIES
	else:
		collision_layer = LAYER_ENEMY_SHOTS
		collision_mask = MASK_WALLS | MASK_PLAYER
	_traveled = 0.0
	active = true
	visible = true
	set_physics_process(true)
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)


func deactivate() -> void:
	active = false
	visible = false
	set_physics_process(false)
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)


func _physics_process(delta: float) -> void:
	var step := direction * speed * delta
	position += step
	_traveled += step.length()
	if _traveled >= max_range:
		deactivate()


func _on_body_entered(body: Node2D) -> void:
	if not active:
		return
	# Damage is applied here (single source of hit logic): deactivating first
	# would race the target's own overlap checks and drop the hit.
	if faction == &"player" and body.has_method("take_damage"):
		body.take_damage(damage)
	elif faction == &"enemy" and body.is_in_group("player"):
		body.take_hit(damage)
	deactivate()


func _on_area_entered(_area: Area2D) -> void:
	if active:
		deactivate()
