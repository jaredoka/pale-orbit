class_name EnemyBase
extends CharacterBody2D
## Abstract enemy base: HP, hit flash, died signal, sheet-driven animation.
## Archetypes override _behave(delta). Projectiles apply damage via take_damage().

signal died(enemy: EnemyBase)
signal spawned(enemy: EnemyBase)  # death-spawned children (Blob) — room re-registers

@export var max_hp: float = 10.0
@export var contact_damage: float = 0.5
@export var sheet_dir: String = ""  # e.g. "res://assets/sprites/enemies/skitterer/"
@export var entity: String = ""     # sheet prefix, e.g. "skitterer"
@export var hitbox_from_sprite: bool = false  # derive collision from the idle frame's opaque pixels

var hp: float

@onready var sprite: AnimatedSprite2D = $Anim
@onready var hurtbox: Area2D = $HurtBox


func _ready() -> void:
	hp = max_hp
	if entity != "":
		sprite.sprite_frames = SpriteSheets.build({
			&"idle": {path = sheet_dir + entity + "_idle_2.png", frames = 2, fps = 4.0},
			&"run": {path = sheet_dir + entity + "_run_6.png", frames = 6, fps = 10.0},
			&"hit": {path = sheet_dir + entity + "_hit_2.png", frames = 2, fps = 12.0, loop = false},
			&"death": {path = sheet_dir + entity + "_death_4.png", frames = 4, fps = 10.0, loop = false},
		})
		sprite.play(&"idle")
		if hitbox_from_sprite:
			_fit_hitbox_to_sprite()


## Replaces the placeholder rect shapes with polygons traced from the idle
## frame's opaque pixels, so collision always matches the current sheet art.
func _fit_hitbox_to_sprite() -> void:
	var tex: Texture2D = sprite.sprite_frames.get_frame_texture(&"idle", 0)
	if tex == null:
		return
	var img: Image = tex.get_image()
	if img == null:
		return
	var bitmap := BitMap.new()
	bitmap.create_from_image_alpha(img)
	var polys := bitmap.opaque_to_polygons(Rect2i(Vector2i.ZERO, img.get_size()), 2.0)
	if polys.is_empty():
		return
	$CollisionShape2D.disabled = true
	$HurtBox/HurtShape.disabled = true
	var offset := -Vector2(img.get_size()) / 2.0
	for poly: PackedVector2Array in polys:
		var pts := PackedVector2Array()
		for p: Vector2 in poly:
			pts.append(p + offset)
		var body_poly := CollisionPolygon2D.new()
		body_poly.polygon = pts
		add_child(body_poly)
		var hurt_poly := CollisionPolygon2D.new()
		hurt_poly.polygon = pts
		hurtbox.add_child(hurt_poly)


func _physics_process(delta: float) -> void:
	_behave(delta)
	move_and_slide()
	if sprite.sprite_frames != null:
		if velocity.length_squared() > 4.0:
			sprite.play(&"run")
			if absf(velocity.x) > 1.0:
				sprite.flip_h = velocity.x < 0.0
		else:
			sprite.play(&"idle")


func take_damage(amount: float) -> void:
	if hp <= 0.0:
		return
	hp -= amount
	_flash()
	if hp <= 0.0:
		_die()


func _flash() -> void:
	sprite.modulate = Color(8.0, 8.0, 8.0)
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.12)


func _die() -> void:
	_spawn_death_fx()
	died.emit(self)
	queue_free()


func _spawn_death_fx() -> void:
	if sprite.sprite_frames == null or not sprite.sprite_frames.has_animation(&"death"):
		return
	var fx := AnimatedSprite2D.new()
	fx.sprite_frames = sprite.sprite_frames
	fx.global_position = global_position
	fx.flip_h = sprite.flip_h
	fx.scale = scale
	get_parent().add_child(fx)
	fx.play(&"death")
	fx.animation_finished.connect(fx.queue_free)
	AudioManager.play_sfx(&"enemy_death")


func _behave(_delta: float) -> void:
	pass


func _player() -> Node2D:
	return get_tree().get_first_node_in_group("player")
