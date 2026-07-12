extends Node2D
## Simple boss HP bar drawn above the Hive Queen sprite.

const WIDTH := 48.0
const HEIGHT := 4.0


func _draw() -> void:
	var boss: EnemyBase = get_parent()
	draw_rect(Rect2(-WIDTH / 2.0, 0, WIDTH, HEIGHT), Color(0.15, 0.15, 0.2))
	var frac: float = clampf(boss.hp / boss.max_hp, 0.0, 1.0)
	draw_rect(Rect2(-WIDTH / 2.0, 0, WIDTH * frac, HEIGHT), Color(0.85, 0.25, 0.3))
