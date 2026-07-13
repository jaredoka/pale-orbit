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
			# Clamp into the room interior so children never spawn inside a wall.
			child.position = Vector2(
				clampf(position.x + offset.x, 32.0, 448.0),
				clampf(position.y + offset.y, 32.0, 238.0))
			# Deferred: _die runs inside a physics callback (projectile hit), and
			# adding a body while the physics server is flushing is an error.
			get_parent().add_child.call_deferred(child)
			spawned.emit(child)
	super()
