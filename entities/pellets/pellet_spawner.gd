class_name PelletSpawner extends Spawner2D

var spawn_point_cells: Array[Vector2i] = []
var tile_map_layer: TileMapLayer = null

func _ready() -> void:
	GM.reset.connect(on_reset)
	
	tile_map_layer = get_tile_map_layer()
	spawn_point_cells = tile_map_layer.get_used_cells()
	tile_map_layer.clear()
	on_reset(GM.ResetType.GAME)

func get_tile_map_layer() -> TileMapLayer:
	for child in get_children():
		if child is not TileMapLayer:
			continue
		return child
	assert(false, 'Missing a TileMapLayer node as a child to the PelletSpawner.')
	return null

func on_reset(type: GM.ResetType) -> void:
	if ![GM.ResetType.GAME, GM.ResetType.LEVEL].has(type):
		return
	despawn_all()
	for cell in spawn_point_cells:
		spawn(tile_map_layer.map_to_local(cell))
