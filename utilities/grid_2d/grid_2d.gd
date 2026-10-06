class_name Grid2D extends Node2D

enum TILE_ALLIGMENT_X {
	LEFT,
	CENTER,
	RIGHT,
}
enum TILE_ALLIGMENT_Y {
	TOP,
	CENTER,
	BOTTOM,
}

@export var tiles_x: int = 28
@export var tiles_y: int = 36

@onready var tile_map_layer: TileMapLayer = $TileMapLayer

func get_coords_from_tile(
		tile: Vector2i,
		alignment_x: TILE_ALLIGMENT_X = TILE_ALLIGMENT_X.CENTER,
		alignment_y: TILE_ALLIGMENT_Y = TILE_ALLIGMENT_Y.CENTER,
	) -> Vector2:
	var coords: Vector2 = tile_map_layer.map_to_local(tile)
	match alignment_x:
		TILE_ALLIGMENT_X.LEFT:
			coords.x -= tile_map_layer.tile_set.tile_size.x / 2.0
		TILE_ALLIGMENT_X.RIGHT:
			coords.x += tile_map_layer.tile_set.tile_size.x / 2.0 - 1
	
	match alignment_y:
		TILE_ALLIGMENT_Y.TOP:
			coords.y -= tile_map_layer.tile_set.tile_size.x / 2.0
		TILE_ALLIGMENT_Y.BOTTOM:
			coords.y += tile_map_layer.tile_set.tile_size.x / 2.0 - 1
	
	return coords
func get_tile_from_coords(coords: Vector2) -> Vector2i:
	return tile_map_layer.local_to_map(coords)

func get_tiledata_from_tile(tile: Vector2i) -> TileData:
	return tile_map_layer.get_cell_tile_data(tile)
