extends Node2D
## Run orchestrator. Until T12: loads a single Room; floor generation lands in M2.

const ROOM_SCENE := preload("res://scenes/rooms/Room.tscn")

@onready var room_holder: Node2D = $RoomHolder
@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Camera2D
@onready var projectile_layer: Node2D = $ProjectileLayer

var projectile_pool: ProjectilePool


func _ready() -> void:
	GameState.start_run()
	projectile_pool = ProjectilePool.new(projectile_layer)
	GameState.projectile_pool = projectile_pool
	player.projectile_pool = projectile_pool
	room_holder.add_child(ROOM_SCENE.instantiate())
	player.position = Vector2(240, 135)
	camera.position = Vector2(240, 135)
