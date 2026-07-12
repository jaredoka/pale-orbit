extends Control
## HUD hearts row (top-left): full/half/empty drawn as placeholder shapes until M4.
## Reacts to GameState.hp_changed (UI-1).

const HEART_SIZE := 8.0
const HEART_GAP := 2.0
const COLOR_FULL := Color(0.9, 0.2, 0.25)
const COLOR_EMPTY := Color(0.25, 0.25, 0.3)

const ITEM_COLORS := {
	&"overclocked_coil": Color(0.3, 0.9, 1.0),   # plasma cyan
	&"dense_plating": Color(1.0, 0.6, 0.2),      # warning orange
	&"plasma_focus": Color(0.5, 1.0, 0.3),       # acid green
}

var _current: float = 0.0
var _max: float = 0.0
var _items: Array[ItemDef] = []


const MAP_CELL := Vector2(10, 7)
const MAP_GAP := 2.0
const MAP_MARGIN := 16.0

const MAP_COLORS := {
	FloorGenerator.RoomType.START: Color(0.35, 0.4, 0.45),
	FloorGenerator.RoomType.NORMAL: Color(0.3, 0.32, 0.38),
	FloorGenerator.RoomType.TREASURE: Color(0.75, 0.6, 0.2),
	FloorGenerator.RoomType.BOSS: Color(0.7, 0.2, 0.25),
}


func _ready() -> void:
	GameState.hp_changed.connect(_on_hp_changed)
	GameState.item_collected.connect(_on_item_collected)
	GameState.room_entered.connect(func(_c: Vector2i) -> void: queue_redraw())
	GameState.room_cleared.connect(func(_c: Vector2i) -> void: queue_redraw())
	_on_hp_changed(GameState.current_hp, GameState.max_hp)


func _on_item_collected(item: ItemDef) -> void:
	_items.append(item)
	queue_redraw()


func _on_hp_changed(current: float, maximum: float) -> void:
	_current = current
	_max = maximum
	queue_redraw()


func _draw() -> void:
	for i in int(ceilf(_max)):
		var x := i * (HEART_SIZE + HEART_GAP)
		draw_rect(Rect2(x, 0, HEART_SIZE, HEART_SIZE), COLOR_EMPTY)
		var fill := clampf(_current - i, 0.0, 1.0)
		if fill >= 1.0:
			draw_rect(Rect2(x, 0, HEART_SIZE, HEART_SIZE), COLOR_FULL)
		elif fill >= 0.5:
			draw_rect(Rect2(x, 0, HEART_SIZE / 2.0, HEART_SIZE), COLOR_FULL)
	# item icons row under the hearts (placeholder squares until M4 icons)
	for j in _items.size():
		var color: Color = ITEM_COLORS.get(_items[j].id, Color.WHITE)
		draw_rect(Rect2(j * (HEART_SIZE + HEART_GAP), HEART_SIZE + 4, HEART_SIZE, HEART_SIZE), color)
	_draw_minimap()


## Top-right minimap: one cell per room, current room highlighted (player position).
func _draw_minimap() -> void:
	var rooms: Dictionary = GameState.floor_rooms
	if rooms.is_empty():
		return
	var min_c := Vector2i(999, 999)
	var max_c := Vector2i(-999, -999)
	for c: Vector2i in rooms:
		min_c = Vector2i(mini(min_c.x, c.x), mini(min_c.y, c.y))
		max_c = Vector2i(maxi(max_c.x, c.x), maxi(max_c.y, c.y))
	var grid_w := (max_c.x - min_c.x + 1) * (MAP_CELL.x + MAP_GAP)
	var origin := Vector2(size.x - MAP_MARGIN - grid_w, 0)
	for c: Vector2i in rooms:
		var cell := origin + Vector2(c - min_c) * (MAP_CELL + Vector2(MAP_GAP, MAP_GAP))
		var color: Color = MAP_COLORS[rooms[c].type]
		if GameState.cleared.get(c, false):
			color = color.lightened(0.15)
		draw_rect(Rect2(cell, MAP_CELL), color)
		if c == GameState.current_room:
			draw_rect(Rect2(cell, MAP_CELL), Color.WHITE, false, 1.0)
			draw_rect(Rect2(cell + MAP_CELL / 2.0 - Vector2(1, 1), Vector2(2, 2)), Color.WHITE)
