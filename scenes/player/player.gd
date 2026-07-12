extends CharacterBody2D
## Player: 8-dir movement from move_* actions. Shooting added in T04.


func _physics_process(_delta: float) -> void:
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = dir * GameState.stats.speed
	move_and_slide()
