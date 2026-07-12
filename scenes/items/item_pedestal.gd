extends Node2D
## Item pedestal: grants its ItemDef on touch via GameState.apply_item (ITM-2).

@export var item: ItemDef

var _taken: bool = false

@onready var touch_area: Area2D = $TouchArea
@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	touch_area.body_entered.connect(_on_body_entered)
	if item == null:
		item = _pick_item()


## Deterministic per run seed and room (NFR-4).
func _pick_item() -> ItemDef:
	var pool: Array[String] = [
		"res://resources/items/overclocked_coil.tres",
		"res://resources/items/dense_plating.tres",
		"res://resources/items/plasma_focus.tres",
	]
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([GameState.rng_seed, "pedestal"])
	return load(pool[rng.randi_range(0, pool.size() - 1)])


func _on_body_entered(body: Node2D) -> void:
	if _taken or item == null or not body.is_in_group("player"):
		return
	_taken = true
	GameState.apply_item(item)
	sprite.visible = false
	touch_area.set_deferred("monitoring", false)
