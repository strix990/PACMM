class_name MapLoader extends Node
## Builds the level from a map file (see Maps): walls, ghost house door, the off-screen walls
## around tunnels, pellets, power pellets, the ghosts' tunnel slow-down zones and the maze drawing.
## On every new game or level it picks the map: single player and co-op cycle through the maps
## level by level, versus plays GM.versus_map.
## Must come before the pellet spawners in the scene, so the map is set up before they respawn.

const WALL_ATLAS: Vector2i = Vector2i(1, 0)
const DOOR_ATLAS: Vector2i = Vector2i(1, 1)
## How many tiles the walls beside a tunnel reach off-screen (travellers wrap at x = -2 / tiles_x + 2).
const TUNNEL_WALL_REACH: int = 4
const TUNNEL_ZONE_SIZE: Vector2 = Vector2(52, 8)
## Centres (x) of the left and right tunnel slow-down zones.
const TUNNEL_ZONE_X: Array[float] = [-6.0, 230.0]

@export var grid: Grid2D
@export var maze_outline: MazeOutline
@export var pellet_spawner: PelletSpawner
@export var power_pellet_spawner: PelletSpawner
@export var tunnel: Tunnel

var current_map: int = -1

func _ready() -> void:
	GM.reset.connect(on_reset)
	load_map(0)

func on_reset(type: GM.ResetType) -> void:
	# losing a life keeps the map
	if type == GM.ResetType.LIFE:
		return
	if GM.game_type == GM.GameType.VERSUS:
		load_map(GM.versus_map)
	else:
		load_map((GM.level - 1) % Maps.MAPS.size())

func load_map(index: int) -> void:
	current_map = index
	var rows: PackedStringArray = Maps.get_rows(index)
	var layer: TileMapLayer = grid.tile_map_layer
	layer.clear()
	var pellets: Array[Vector2i] = []
	var power_pellets: Array[Vector2i] = []
	for y in rows.size():
		for x in rows[y].length():
			var cell: Vector2i = Vector2i(x, Maps.FIRST_ROW + y)
			match rows[y][x]:
				'#': layer.set_cell(cell, 0, WALL_ATLAS)
				'-': layer.set_cell(cell, 0, DOOR_ATLAS)
				'.': pellets.append(cell)
				'o': power_pellets.append(cell)

	var tunnel_rows: Array[int] = find_tunnel_rows()
	# off-screen walls above and below each tunnel, so nothing can leave the tunnel sideways
	for y in tunnel_rows:
		for dy in [-1, 1]:
			if tunnel_rows.has(y + dy):
				continue
			for i in TUNNEL_WALL_REACH:
				layer.set_cell(Vector2i(-1 - i, y + dy), 0, WALL_ATLAS)
				layer.set_cell(Vector2i(grid.tiles_x + i, y + dy), 0, WALL_ATLAS)
	grid.reset_map_data()

	pellet_spawner.set_spawn_cells(pellets)
	power_pellet_spawner.set_spawn_cells(power_pellets)
	GM.pellets_total = pellets.size() + power_pellets.size()
	update_tunnel_zones.call_deferred(tunnel_rows)
	maze_outline.queue_redraw()

## Rows where a corridor reachable from Pac-Man's start touches the left edge.
func find_tunnel_rows() -> Array[int]:
	var seen: Dictionary = {grid.playable_seed: true}
	var queue: Array[Vector2i] = [grid.playable_seed]
	var rows: Array[int] = []
	while !queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		if cell.x == 0 and !rows.has(cell.y):
			rows.append(cell.y)
		for direction: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var next: Vector2i = cell + direction
			if next.x < 0 or next.x >= grid.tiles_x or next.y < 0 or next.y >= grid.tiles_y:
				continue
			if seen.has(next) or grid.tile_map_layer.get_cell_source_id(next) != -1:
				continue
			seen[next] = true
			queue.append(next)
	rows.sort()
	return rows

## The ghosts slow down in tunnels: one zone on each side per tunnel row.
func update_tunnel_zones(tunnel_rows: Array[int]) -> void:
	for child in tunnel.get_children():
		if child is CollisionShape2D:
			tunnel.remove_child(child)
			child.queue_free()
	for y in tunnel_rows:
		var centre_y: float = grid.to_global(grid.get_coords_from_tile(Vector2i(0, y))).y
		for x in TUNNEL_ZONE_X:
			var zone: CollisionShape2D = CollisionShape2D.new()
			var shape: RectangleShape2D = RectangleShape2D.new()
			shape.size = TUNNEL_ZONE_SIZE
			zone.shape = shape
			tunnel.add_child(zone)
			zone.global_position = Vector2(x, centre_y)
