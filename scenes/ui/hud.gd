extends Control
## HUD hearts row (top-left): full/half/empty drawn as placeholder shapes until M4.
## Reacts to GameState.hp_changed (UI-1).

const HEART_SIZE := 8.0
const HEART_GAP := 2.0
const COLOR_FULL := Color(0.9, 0.2, 0.25)
const COLOR_EMPTY := Color(0.25, 0.25, 0.3)

var _current: float = 0.0
var _max: float = 0.0


func _ready() -> void:
	GameState.hp_changed.connect(_on_hp_changed)
	_on_hp_changed(GameState.current_hp, GameState.max_hp)


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
