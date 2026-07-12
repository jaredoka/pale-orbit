extends EnemyBase
## Blob: slow chaser; splits once into 2 half-scale blobs on death (ENM-4).
## Children are emitted via `spawned` so the room's alive-count stays correct.

const SPEED := 30.0

@export var can_split: bool = true


func _behave(_delta: float) -> void:
	var target := _player()
	velocity = Vector2.ZERO if target == null \
			else (target.global_position - global_position).normalized() * SPEED


func _die() -> void:
	if can_split:
		for offset: Vector2 in [Vector2(-8, 0), Vector2(8, 0)]:
			var child: EnemyBase = load("res://scenes/enemies/Blob.tscn").instantiate()
			child.can_split = false
			child.max_hp = max_hp * 0.4
			child.scale = Vector2(0.5, 0.5)
			child.global_position = global_position + offset
			get_parent().add_child(child)
			spawned.emit(child)
	super()
