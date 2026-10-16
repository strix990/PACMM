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
		
		# tunnel wrap: tiles -2 and tiles_x + 2 are the same spot, so stepping past either edge
		# (also when turning around right after a wrap) continues from the other side
		if tile.x + td.x >= grid.tiles_x + 2:
			tile.x = -2
			global_position = grid.get_coords_from_tile(tile)
		elif tile.x + td.x <= -2:
			tile.x = grid.tiles_x + 2
			global_position = grid.get_coords_from_tile(tile)
		
		coords_move_to = grid.get_coords_from_tile(tile + td)
@onready var tile_direction_next: Vector2i = tile_direction

signal tile_direction_changed(tile_direction: Vector2i)

# item effects (see ItemHolder)
## Multiplies the normal speed (speed boost, dash).
var speed_multiplier: float = 1.0
## Wall walk: walls inside the maze count as walkable.
var can_pass_walls: bool = false
## Stunned travellers don't read input or move.
var stunned: bool = false

const INPUT_DIRECTIONS: Dictionary[String, Vector2i] = {
	'up': Vector2i.UP,
	'left': Vector2i.LEFT,
	'down': Vector2i.DOWN,
	'right': Vector2i.RIGHT,
}

## Returns the directions currently held for the given input action prefixes
## (e.g. ['p1_', 'p2_'] reads p1_up, p1_left, ..., p2_right).
static func read_input_directions(prefixes: Array[String]) -> Array[Vector2i]:
	var directions: Array[Vector2i] = []
	for prefix in prefixes:
		for action in INPUT_DIRECTIONS:
			if Input.is_action_pressed(prefix + action):
				directions.append(INPUT_DIRECTIONS[action])
	return directions

func _process(_delta: float) -> void:
	tile = grid.get_tile_from_coords(global_position)
	if global_position == coords_move_to:
		tile_direction = tile_direction_next

func get_speed() -> float:
	return speed

## The speed to move with right now: the normal speed with item effects applied.
func get_current_speed() -> float:
	return get_speed() * speed_multiplier

## After wall walking: if standing in a wall (or in the ghost house), jump to the nearest
## walkable tile outside the house.
func snap_to_walkable_tile() -> void:
	var queue: Array[Vector2i] = [tile]
	var seen: Dictionary = {tile: true}
	while !queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		if is_tile_walkable(cell) and !grid.is_in_house(cell):
			# already fine: on open floor and heading to open floor
			if cell == tile and is_tile_walkable(grid.get_tile_from_coords(coords_move_to)):
				return
			global_position = grid.get_coords_from_tile(cell)
			coords_move_to = global_position
			tile = cell
			return
		for direction: Vector2i in INPUT_DIRECTIONS.values():
			var next: Vector2i = cell + direction
			if !seen.has(next) and grid.is_inside_maze(next):
				seen[next] = true
				queue.append(next)

func calculate_tile_direction_next() -> Vector2i:
	if grid == null or tile_direction == Vector2i.ZERO:
		return Vector2i.ZERO
	return tile_direction if is_tile_walkable(tile + tile_direction) else Vector2i.ZERO

func is_tile_walkable(t: Vector2i) -> bool:
	if can_pass_walls and grid.is_inside_maze(t):
		return true
	return !grid.is_wall(t)
