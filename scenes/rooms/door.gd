extends Area2D
## Door: locked = solid (Blocker on) + closed visual; unlocked = trigger for room transition.

signal player_entered(direction: Vector2i)

const TEX_CLOSED := preload("res://assets/tiles/door_closed.png")
const TEX_OPEN := preload("res://assets/tiles/door_open.png")

@export var direction: Vector2i = Vector2i.UP

var locked: bool = true
var disabled: bool = false  # no neighbor room behind this wall — permanently sealed

@onready var blocker_shape: CollisionShape2D = $Blocker/CollisionShape2D
@onready var visual: Sprite2D = $Visual


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_apply_state()


func lock() -> void:
	locked = true
	_apply_state()


func open() -> void:
	if disabled:
		return
	locked = false
	_apply_state()


func disable() -> void:
	disabled = true
	locked = true
	_apply_state()
	visual.modulate = Color(0.45, 0.45, 0.5)  # sealed: darkened into the wall


func _apply_state() -> void:
	blocker_shape.set_deferred("disabled", not locked)
	visual.texture = TEX_CLOSED if locked else TEX_OPEN


func _on_body_entered(body: Node2D) -> void:
	if not locked and body.is_in_group("player"):
		player_entered.emit(direction)
