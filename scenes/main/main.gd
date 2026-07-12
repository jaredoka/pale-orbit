extends Node2D
## Run orchestrator: generates the floor from GameState.rng_seed, instances rooms,
## handles door transitions with camera snap (RM-3). Supports `-- --seed=N`.

const ROOM_SCENE := preload("res://scenes/rooms/Room.tscn")
const GAME_OVER_SCENE := preload("res://scenes/ui/GameOver.tscn")
const WIN_SCENE := preload("res://scenes/ui/WinScreen.tscn")
const ROOM_SIZE := Vector2(480, 270)
const DOOR_INSET := 30.0

const DOOR_LOCAL := {
	Vector2i(0, -1): Vector2(240, 8),
	Vector2i(0, 1): Vector2(240, 262),
	Vector2i(1, 0): Vector2(472, 135),
	Vector2i(-1, 0): Vector2(8, 135),
}

var floor_rooms: Dictionary = {}
var projectile_pool: ProjectilePool
var _current_room_node: Node2D = null

@onready var room_holder: Node2D = $RoomHolder
@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Camera2D
@onready var projectile_layer: Node2D = $ProjectileLayer


func _ready() -> void:
	GameState.start_run(_seed_from_args())
	projectile_pool = ProjectilePool.new(projectile_layer)
	GameState.projectile_pool = projectile_pool
	player.projectile_pool = projectile_pool
	floor_rooms = FloorGenerator.new().generate(GameState.rng_seed)
	GameState.floor_rooms = floor_rooms
	GameState.player_died.connect(_on_player_died)
	GameState.boss_defeated.connect(_on_boss_defeated)
	GameState.hp_changed.connect(_on_hp_changed_shake)
	_enter_room(Vector2i.ZERO, Vector2i.ZERO)


var _shake_time: float = 0.0
var _shake_amp: float = 0.0
var _prev_hp: float = -1.0


func _process(delta: float) -> void:
	if _shake_time > 0.0:
		_shake_time -= delta
		camera.offset = Vector2(
			randf_range(-_shake_amp, _shake_amp), randf_range(-_shake_amp, _shake_amp))
		if _shake_time <= 0.0:
			camera.offset = Vector2.ZERO


func shake(duration: float, amplitude: float) -> void:
	_shake_time = duration
	_shake_amp = amplitude


func _on_hp_changed_shake(current: float, _max_hp: float) -> void:
	if _prev_hp >= 0.0 and current < _prev_hp:
		shake(0.25, 3.0)  # subtle hit shake
	_prev_hp = current


func _on_player_died() -> void:
	_show_end_screen(GAME_OVER_SCENE)


func _on_boss_defeated() -> void:
	shake(0.5, 5.0)
	GameState.run_won.emit()
	_show_end_screen(WIN_SCENE)


func _show_end_screen(scene: PackedScene) -> void:
	$UILayer.add_child(scene.instantiate())
	get_tree().paused = true


func _seed_from_args() -> int:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--seed="):
			return int(arg.trim_prefix("--seed="))
	return -1


func _enter_room(coord: Vector2i, entry_dir: Vector2i) -> void:
	if _current_room_node != null:
		_current_room_node.queue_free()
	projectile_pool.deactivate_all()

	var room: Node2D = ROOM_SCENE.instantiate()
	room.setup(floor_rooms[coord])
	room.position = Vector2(coord) * ROOM_SIZE
	room.door_entered.connect(_on_door_entered)
	room_holder.add_child(room)
	_current_room_node = room

	var room_origin: Vector2 = room.position
	if entry_dir == Vector2i.ZERO:
		player.global_position = room_origin + ROOM_SIZE / 2.0
	else:
		var entry_door: Vector2 = DOOR_LOCAL[-entry_dir]
		player.global_position = room_origin + entry_door + Vector2(entry_dir) * DOOR_INSET
	camera.position = room_origin + ROOM_SIZE / 2.0

	GameState.current_room = coord
	GameState.room_entered.emit(coord)


func _on_door_entered(direction: Vector2i) -> void:
	# Door triggers arrive mid-physics-flush; defer so the room swap doesn't
	# mutate physics state while queries are flushing.
	_enter_room.call_deferred(GameState.current_room + direction, direction)
