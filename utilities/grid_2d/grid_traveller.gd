class_name GridTraveller extends Node2D

@export var grid: Grid2D = null
@export var speed: float = 75.75:
	get = get_speed
@export var tile_direction_reset: Vector2i = Vector2i.ZERO

@onready var tile: Vector2i = Vector2i.ZERO if grid == null else grid.get_tile_from_coords(global_position):
	set(t):
		if t == tile:
			return
		tile = t
		tile_direction_next = calculate_tile_direction_next()
@onready var coords_move_to: Vector2 = global_position
@onready var tile_direction: Vector2i = tile_direction_reset:
	set(td):
		if ![Vector2i.ZERO, Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT].has(td):
			return
		if td == Vector2i.ZERO and td == tile_direction:
			return
		if grid == null or !is_tile_walkable(tile + td):
			return
		
		tile_direction = td
		tile_direction_changed.emit(td)
		
		if tile.x + td.x == grid.tiles_x + 2:
			tile.x = -2
			global_position = grid.get_coords_from_tile(tile)
		elif tile.x + td.x == -2:
			tile.x = grid.tiles_x + 2
			global_position = grid.get_coords_from_tile(tile)
		
		coords_move_to = grid.get_coords_from_tile(tile + td)
@onready var tile_direction_next: Vector2i = tile_direction

signal tile_direction_changed(tile_direction: Vector2i)

func _process(_delta: float) -> void:
	tile = grid.get_tile_from_coords(global_position)
	if global_position == coords_move_to:
		tile_direction = tile_direction_next

func get_speed() -> float:
	return speed

func calculate_tile_direction_next() -> Vector2i:
	if grid == null or tile_direction == Vector2i.ZERO:
		return Vector2i.ZERO
	return tile_direction if is_tile_walkable(tile + tile_direction) else Vector2i.ZERO

func is_tile_walkable(t: Vector2i) -> bool:
	var tile_data: TileData = grid.get_tiledata_from_tile(t)
	if tile_data != null and tile_data.has_custom_data('type'):
		match tile_data.get_custom_data('type'):
			'wall':
				return false
	return true
