extends Node2D
## Room: locks doors while enemies live, opens on clear, persists via GameState.cleared
## (RM-1, RM-2). setup(data) must be called before add_child; doors without a
## generated neighbor are sealed. Forwards door triggers to Main via door_entered.

signal door_entered(direction: Vector2i)

const TELEGRAPH_TIME := 0.4

const SKITTERER := "res://scenes/enemies/Skitterer.tscn"
const SPITTER := "res://scenes/enemies/Spitter.tscn"
const BIO_TURRET := "res://scenes/enemies/BioTurret.tscn"
const BLOB := "res://scenes/enemies/Blob.tscn"

## Hand-made NORMAL-room spawn layouts (RM-4); picked by seeded RNG in _pick_layout().
const LAYOUTS: Array = [
	[  # pincer skitterers + backline spitter
		{pos = Vector2(90, 70), scene = SKITTERER},
		{pos = Vector2(90, 200), scene = SKITTERER},
		{pos = Vector2(390, 135), scene = SPITTER},
	],
	[  # turret nest guarded by a blob
		{pos = Vector2(240, 70), scene = BIO_TURRET},
		{pos = Vector2(240, 200), scene = BIO_TURRET},
		{pos = Vector2(120, 135), scene = BLOB},
	],
	[  # blob wall with skitterer flanker
		{pos = Vector2(200, 135), scene = BLOB},
		{pos = Vector2(280, 135), scene = BLOB},
		{pos = Vector2(400, 60), scene = SKITTERER},
	],
	[  # crossfire: spitters in opposite corners, turret center
		{pos = Vector2(80, 60), scene = SPITTER},
		{pos = Vector2(400, 210), scene = SPITTER},
		{pos = Vector2(240, 135), scene = BIO_TURRET},
	],
	[  # swarm rush
		{pos = Vector2(380, 70), scene = SKITTERER},
		{pos = Vector2(410, 135), scene = SKITTERER},
		{pos = Vector2(380, 200), scene = SKITTERER},
		{pos = Vector2(100, 135), scene = SPITTER},
	],
]

var data: RoomData = null
var coord: Vector2i = Vector2i.ZERO

var _alive: int = 0
var _started: bool = false

@onready var doors: Array[Node] = $Doors.get_children()


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
	var layout: Array = _pick_layout()
	if layout.is_empty():
		_clear_room()
		return
	_lock_all()
	await get_tree().create_timer(TELEGRAPH_TIME).timeout  # telegraph poof window
	for entry: Dictionary in layout:
		var scene: PackedScene = load(entry.scene)
		var enemy: EnemyBase = scene.instantiate()
		enemy.position = entry.pos
		add_child(enemy)
		_register(enemy)
	_started = true
	if _alive == 0:
		_clear_room()


## Deterministic per run seed and room coord (NFR-4).
func _pick_layout() -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([GameState.rng_seed, coord])
	return LAYOUTS[rng.randi_range(0, LAYOUTS.size() - 1)]


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
