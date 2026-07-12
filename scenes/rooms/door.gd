extends Area2D
## Door: locked = solid (Blocker on) + closed visual; unlocked = trigger for room transition.

signal player_entered(direction: Vector2i)

const COLOR_LOCKED := Color(0.6, 0.2, 0.15)
const COLOR_OPEN := Color(0.2, 0.7, 0.4)

@export var direction: Vector2i = Vector2i.UP

var locked: bool = true
var disabled: bool = false  # no neighbor room behind this wall — permanently sealed

@onready var blocker_shape: CollisionShape2D = $Blocker/CollisionShape2D
@onready var visual: ColorRect = $Visual


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
	visual.color = Color(0.25, 0.28, 0.34)  # blend into the wall


func _apply_state() -> void:
	blocker_shape.set_deferred("disabled", not locked)
	visual.color = COLOR_LOCKED if locked else COLOR_OPEN


func _on_body_entered(body: Node2D) -> void:
	if not locked and body.is_in_group("player"):
		player_entered.emit(direction)
