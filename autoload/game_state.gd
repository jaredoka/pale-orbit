extends Node
## GameState singleton — owns run state. Stub until T02.

signal hp_changed(current: float, max: float)
signal player_died
signal item_collected(item: Resource)
signal room_entered(coord: Vector2i)
signal room_cleared(coord: Vector2i)
signal boss_defeated
signal run_won
