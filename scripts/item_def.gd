class_name ItemDef
extends Resource
## Data-driven passive item: stat deltas applied via GameState.apply_item().

@export var id: StringName
@export var display_name: String
@export var description: String
@export var icon: Texture2D

@export var speed_add: float = 0.0
@export var fire_rate_mult: float = 1.0
@export var damage_add: float = 0.0
@export var shot_speed_add: float = 0.0
@export var range_add: float = 0.0
@export var max_hp_add: float = 0.0
