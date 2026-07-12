extends Node2D
## Room: locks doors while enemies live, opens on clear, persists via GameState.cleared
## (RM-1, RM-2). setup(data) must be called before add_child; doors without a
## generated neighbor are sealed. Forwards door triggers to Main via door_entered.

signal door_entered(direction: Vector2i)

const TELEGRAPH_TIME := 0.4

var data: RoomData = null
var coord: Vector2i = Vector2i.ZERO

var _alive: int = 0
var _started: bool = false

@onready var doors: Array[Node] = $Doors.get_children()
@onready var spawns: Node2D = $Spawns


func setup(p_data: RoomData) -> void:
	data = p_data
	coord = p_data.coord


func _ready() -> void:
	for door in doors:
		if data != null and not data.doors.has(coord + door.direction):
			door.disable()
		else:
			door.player_entered.connect(func(dir: Vector2i) -> void: door_entered.emit(dir))
	if GameState.cleared.get(coord, false) or _is_safe_room():
		GameState.cleared[coord] = true
		_open_all()
	else:
		_start_encounter()


func _is_safe_room() -> bool:
	if data == null:
		return false
	return data.type == FloorGenerator.RoomType.START \
			or data.type == FloorGenerator.RoomType.TREASURE \
			or data.type == FloorGenerator.RoomType.BOSS  # boss arrives in T15


func _start_encounter() -> void:
	var markers := spawns.get_children()
	if markers.is_empty():
		_clear_room()
		return
	_lock_all()
	await get_tree().create_timer(TELEGRAPH_TIME).timeout  # telegraph poof window
	for marker in markers:
		var scene: PackedScene = load(marker.get_meta("enemy_scene"))
		var enemy: EnemyBase = scene.instantiate()
		enemy.position = marker.position
		add_child(enemy)
		_register(enemy)
	_started = true
	if _alive == 0:
		_clear_room()


func _register(enemy: EnemyBase) -> void:
	_alive += 1
	enemy.died.connect(_on_enemy_died)
	enemy.spawned.connect(_register)


func _on_enemy_died(_enemy: EnemyBase) -> void:
	_alive -= 1
	if _started and _alive <= 0:
		_clear_room()


func _clear_room() -> void:
	_open_all()
	GameState.cleared[coord] = true
	GameState.room_cleared.emit(coord)


func _lock_all() -> void:
	for door in doors:
		door.lock()


func _open_all() -> void:
	for door in doors:
		door.open()
