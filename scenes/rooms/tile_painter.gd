class_name TilePainter
extends RefCounted
## Builds the room's visual TileMapLayer from station_tileset.png (T22).
## Collision stays on the Room's StaticBody2D walls; tiles are visual only.

const ATLAS := "res://assets/tiles/station_tileset.png"
const TILE := 16
# atlas columns: 0 floor plain, 1 floor plate, 2 wall, 3 vent, 4 console, 5 biomass
const COLS_W := 30
const COLS_H := 17


static func paint(room_seed: int) -> TileMapLayer:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE, TILE)
	var src := TileSetAtlasSource.new()
	src.texture = load(ATLAS)
	src.texture_region_size = Vector2i(TILE, TILE)
	for i in 6:
		src.create_tile(Vector2i(i, 0))
	ts.add_source(src, 0)

	var layer := TileMapLayer.new()
	layer.tile_set = ts
	layer.z_index = -10
	var rng := RandomNumberGenerator.new()
	rng.seed = room_seed
	for y in COLS_H:
		for x in COLS_W:
			var col := 0
			if x == 0 or y == 0 or x == COLS_W - 1 or y == COLS_H - 1:
				col = 2  # wall
			else:
				var roll := rng.randf()
				if roll < 0.06:
					col = 1  # plate variant
				elif roll < 0.09:
					col = 3  # vent
				elif roll < 0.11:
					col = 5  # biomass
				elif roll < 0.115 and y == 1:
					col = 4  # console on the top wall row
			layer.set_cell(Vector2i(x, y), 0, Vector2i(col, 0))
	return layer
