extends Area2D
## Life-support cell (heart pickup). Heals on touch; if HP is full the pickup
## remains (ITM-1). heal_amount: 0.5 = half cell, 1.0 = full cell.

@export var heal_amount: float = 0.5

@onready var visual: Sprite2D = $Visual


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	visual.texture = load("res://assets/ui/heart_full.png" if heal_amount >= 1.0
			else "res://assets/ui/heart_half.png")


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if GameState.current_hp >= GameState.max_hp:
		return  # stays on the floor
	GameState.heal_player(heal_amount)
	AudioManager.play_sfx(&"pickup")
	queue_free()
