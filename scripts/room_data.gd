class_name RoomData
extends RefCounted
## FloorGenerator output: one grid room.

var coord: Vector2i
var type: FloorGenerator.RoomType
var doors: Array[Vector2i] = []  # occupied neighbor coords


func _init(p_coord: Vector2i, p_type: FloorGenerator.RoomType = FloorGenerator.RoomType.NORMAL) -> void:
	coord = p_coord
	type = p_type
