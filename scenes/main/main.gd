extends Node2D
## Run orchestrator. Until T12: loads the temporary TestRoom and starts a run.

const TEST_ROOM := preload("res://scenes/rooms/TestRoom.tscn")

@onready var room_holder: Node2D = $RoomHolder
@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Camera2D
@onready var projectile_layer: Node2D = $ProjectileLayer

var projectile_pool: ProjectilePool


func _ready() -> void:
	GameState.start_run()
	projectile_pool = ProjectilePool.new(projectile_layer)
	player.projectile_pool = projectile_pool
	room_holder.add_child(TEST_ROOM.instantiate())
	player.position = Vector2(240, 135)
	camera.position = Vector2(240, 135)
