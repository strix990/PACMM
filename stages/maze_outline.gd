class_name MazeOutline extends Node2D
## Draws the maze in arcade Pac-Man style: thin blue outlines around the wall tiles of the
## (hidden) TileMapLayer, plus a pink bar for the ghost house door.
## The TileMapLayer stays the source of truth for walls; this node only draws it.

const DOOR_ATLAS_COORDS: Vector2i = Vector2i(1, 1)

@export var tile_map_layer: TileMapLayer
@export var wall_color: Color = Color("#2121de")
@export var door_color: Color = Color("#ffb8de")
## Distance (in pixels) of the outline from the open side of a wall tile.
@export var inset: int = 2

func _ready() -> void:
	queue_redraw()

func is_door(cell: Vector2i) -> bool:
	return tile_map_layer.get_cell_source_id(cell) != -1 and tile_map_layer.get_cell_atlas_coords(cell) == DOOR_ATLAS_COORDS

func is_wall(cell: Vector2i) -> bool:
	return tile_map_layer.get_cell_source_id(cell) != -1 and !is_door(cell)

var _rects: Array = []

func line(x: int, y: int, w: int, h: int, color: Color = wall_color) -> void:
	_rects.append([Rect2(x, y, w, h), color])

func _draw() -> void:
	for r in get_rects():
		draw_rect(r[0], r[1])

## Returns [Rect2, Color] pairs, in this node's local coordinates, that make up the maze drawing.
func get_rects() -> Array:
	_rects = []
	if tile_map_layer == null:
		return _rects
	var size: int = tile_map_layer.tile_set.tile_size.x
	var d: int = inset
	var far: int = size - 1 - d # outline position measured from the opposite side
	for cell: Vector2i in tile_map_layer.get_used_cells():
		var origin: Vector2 = tile_map_layer.position + tile_map_layer.map_to_local(cell) - Vector2(size, size) / 2.0
		var x: int = int(origin.x)
		var y: int = int(origin.y)
		if is_door(cell):
			line(x, y + size / 2 - 1, size, 2, door_color)
			continue

		var up: bool = !is_wall(cell + Vector2i.UP)
		var down: bool = !is_wall(cell + Vector2i.DOWN)
		var left: bool = !is_wall(cell + Vector2i.LEFT)
		var right: bool = !is_wall(cell + Vector2i.RIGHT)

		# straight edges: shortened at convex corners, running to the tile edge otherwise
		var x0: int = x + d if left else x
		var x1: int = x + far if right else x + size - 1
		var y0: int = y + d if up else y
		var y1: int = y + far if down else y + size - 1
		if up: line(x0, y + d, x1 - x0 + 1, 1)
		if down: line(x0, y + far, x1 - x0 + 1, 1)
		if left: line(x + d, y0, 1, y1 - y0 + 1)
		if right: line(x + far, y0, 1, y1 - y0 + 1)

		# concave corners: both neighbours are walls but the diagonal is open
		if !up and !left and !is_wall(cell + Vector2i(-1, -1)):
			line(x + d, y, 1, d + 1)
			line(x, y + d, d + 1, 1)
		if !up and !right and !is_wall(cell + Vector2i(1, -1)):
			line(x + far, y, 1, d + 1)
			line(x + far, y + d, size - far, 1)
		if !down and !left and !is_wall(cell + Vector2i(-1, 1)):
			line(x + d, y + far, 1, size - far)
			line(x, y + far, d + 1, 1)
		if !down and !right and !is_wall(cell + Vector2i(1, 1)):
			line(x + far, y + far, 1, size - far)
			line(x + far, y + far, size - far, 1)
	return _rects
