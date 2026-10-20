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

## Forgets everything worked out from the walls (call after the map changes, see MapLoader).
func reset_map_data() -> void:
	_row_extents.clear()
	_playable.clear()
	bomb_tiles.clear()

## A tile the corridors can reach (Pac-Man's start); the playfield is everything reachable from it.
@export var playable_seed: Vector2i = Vector2i(14, 26)

## The playfield: every tile reachable through the corridors (tunnels included), not the ghost
## house and not the empty space around the maze. Computed once.
var _playable: Dictionary = {}

func is_playable(tile: Vector2i) -> bool:
	if _playable.is_empty():
		_playable[playable_seed] = true
		var queue: Array[Vector2i] = [playable_seed]
		while !queue.is_empty():
			var cell: Vector2i = queue.pop_front()
			for direction: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
				var next: Vector2i = cell + direction
				# tunnels wrap around between x = -2 and x = tiles_x + 2 (see GridTraveller)
				if next.x < -2:
					next.x = tiles_x + 2
				elif next.x > tiles_x + 2:
					next.x = -2
				if next.y < 0 or next.y >= tiles_y or _playable.has(next) or is_wall(next) or is_in_house(next):
					continue
				_playable[next] = true
				queue.append(next)
	return _playable.has(tile)

func get_nearest_playable_tile(from: Vector2i) -> Vector2i:
	is_playable(from) # makes sure the playfield is computed
	var best: Vector2i = playable_seed
	for cell: Vector2i in _playable:
		if Vector2(cell).distance_squared_to(from) < Vector2(best).distance_squared_to(from):
			best = cell
	return best

## Tiles holding a bomb that hasn't exploded yet (tile -> number of bombs). Like in Bomberman,
## nobody can walk onto them; see GridTraveller.is_tile_walkable.
var bomb_tiles: Dictionary = {}

func add_bomb(tile: Vector2i) -> void:
	bomb_tiles[tile] = bomb_tiles.get(tile, 0) + 1

func remove_bomb(tile: Vector2i) -> void:
	if !bomb_tiles.has(tile):
		return
	bomb_tiles[tile] -= 1
	if bomb_tiles[tile] <= 0:
		bomb_tiles.erase(tile)

func has_bomb(tile: Vector2i) -> bool:
	return bomb_tiles.has(tile)
