class_name EnemyBase
extends CharacterBody2D
## Abstract enemy base: HP, hurtbox vs player_shots, hit flash, died signal.
## Archetypes override _behave(delta).

signal died(enemy: EnemyBase)
signal spawned(enemy: EnemyBase)  # death-spawned children (Blob) — room re-registers

@export var max_hp: float = 10.0
@export var contact_damage: float = 0.5

var hp: float

@onready var sprite: Sprite2D = $Sprite2D
@onready var hurtbox: Area2D = $HurtBox


func _ready() -> void:
	hp = max_hp


func _physics_process(delta: float) -> void:
	_behave(delta)
	move_and_slide()


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
	died.emit(self)
	queue_free()


func _behave(_delta: float) -> void:
	pass


func _player() -> Node2D:
	return get_tree().get_first_node_in_group("player")
