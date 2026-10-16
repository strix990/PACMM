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

func is_wall(tile: Vector2i) -> bool:
	var tile_data: TileData = get_tiledata_from_tile(tile)
	return tile_data != null and tile_data.has_custom_data('type') and tile_data.get_custom_data('type') == 'wall'

## The ghost house (walls and inside), in tiles. Wall walking never ends inside it.
@export var house_rect: Rect2i = Rect2i(10, 15, 8, 5)

## For each maze row: the leftmost and rightmost wall tile (x, y of the Vector2i).
var _row_extents: Dictionary = {}

## Is this tile within the maze's outer walls? (Used to keep wall walking inside the maze.)
func is_inside_maze(tile: Vector2i) -> bool:
	if _row_extents.is_empty():
		for cell: Vector2i in tile_map_layer.get_used_cells():
			var e: Vector2i = _row_extents.get(cell.y, Vector2i(cell.x, cell.x))
			_row_extents[cell.y] = Vector2i(mini(e.x, cell.x), maxi(e.y, cell.x))
	if !_row_extents.has(tile.y):
		return false
	var extent: Vector2i = _row_extents[tile.y]
	return tile.x >= extent.x and tile.x <= extent.y

func is_in_house(tile: Vector2i) -> bool:
	return house_rect.has_point(tile)
