class_name ProjectilePool
extends RefCounted
## Pre-instantiated projectile pool: 64 player + 64 enemy shots under ProjectileLayer.
## Never queue_free() pooled projectiles; never instantiate at fire time (NFR-1).

const PROJECTILE_SCENE := preload("res://scenes/player/Projectile.tscn")
const POOL_SIZE_PER_FACTION := 64

var _pools: Dictionary = {&"player": [], &"enemy": []}


func _init(layer: Node2D) -> void:
	for faction: StringName in _pools:
		for i in POOL_SIZE_PER_FACTION:
			var p := PROJECTILE_SCENE.instantiate()
			layer.add_child(p)
			_pools[faction].append(p)


## config: { position, direction, speed, damage, range, faction }
func fire(config: Dictionary) -> void:
	for p in _pools[config.faction]:
		if not p.active:
			p.activate(config)
			return
	# Pool exhausted: drop the shot rather than allocate.


func deactivate_all() -> void:
	for faction: StringName in _pools:
		for p in _pools[faction]:
			p.deactivate()
