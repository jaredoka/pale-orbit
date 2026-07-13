extends Node
## GameState singleton — owns run state. The only global mutable state in the game.

signal hp_changed(current: float, max: float)
signal player_died
signal item_collected(item: ItemDef)
signal room_entered(coord: Vector2i)
signal room_cleared(coord: Vector2i)
signal boss_defeated
signal run_won

const BASE_STATS_PATH := "res://resources/stats/base_player_stats.tres"

var stats: PlayerStats
var current_hp: float = 0.0
var max_hp: float = 0.0
var collected_items: Array[ItemDef] = []
var rng_seed: int = 0
var projectile_pool: ProjectilePool  # set by Main at run start; shared by player & enemies
var floor_rooms: Dictionary = {}  # { Vector2i: RoomData } — set by Main; read by HUD minimap
var current_room: Vector2i = Vector2i.ZERO
var cleared: Dictionary = {}  # Vector2i -> bool
# Equipped cosmetic gun skin (see GUN_SKINS in player.gd). Cosmetic only —
# never changes stats. &"electric" is the IAP prototype; default is &"plasma".
var gun_skin: StringName = &"electric"

var _dead: bool = false


func start_run(run_seed: int = -1) -> void:
	var base: PlayerStats = load(BASE_STATS_PATH)
	stats = base.duplicate() as PlayerStats
	max_hp = stats.max_hp
	current_hp = max_hp
	collected_items = []
	cleared = {}
	current_room = Vector2i.ZERO
	_dead = false
	rng_seed = run_seed if run_seed != -1 else randi()
	hp_changed.emit(current_hp, max_hp)


func apply_item(item: ItemDef) -> void:
	stats.speed += item.speed_add
	stats.damage += item.damage_add
	stats.shot_speed += item.shot_speed_add
	stats.range += item.range_add
	stats.max_hp += item.max_hp_add
	stats.fire_rate *= item.fire_rate_mult
	stats.shot_scale *= item.shot_scale_mult
	if item.max_hp_add > 0.0:
		max_hp = stats.max_hp
		current_hp = minf(current_hp + item.max_hp_add, max_hp)
	else:
		max_hp = stats.max_hp
		current_hp = minf(current_hp, max_hp)
	collected_items.append(item)
	item_collected.emit(item)
	hp_changed.emit(current_hp, max_hp)


func damage_player(amount: float) -> void:
	if _dead:
		return
	current_hp = maxf(current_hp - amount, 0.0)
	hp_changed.emit(current_hp, max_hp)
	if current_hp <= 0.0:
		_dead = true
		player_died.emit()


func heal_player(amount: float) -> void:
	if _dead:
		return
	current_hp = minf(current_hp + amount, max_hp)
	hp_changed.emit(current_hp, max_hp)
