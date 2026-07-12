extends Control
## Game Over / Win screen behavior: shown while the tree is paused;
## `restart` starts a fresh run (UI-2/UI-3). GameState fully resets in start_run().


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("restart"):
		get_tree().paused = false
		get_tree().reload_current_scene()
