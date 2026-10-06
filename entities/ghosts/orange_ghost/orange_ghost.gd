class_name OrangeGhost extends Ghost

## 8 tiles away (8 pixels x 8 tiles)
const DISTANCE_FROM_PACMAN: float = 64

func get_tile_target_during_chase() -> Vector2i:
	if global_position.distance_to(pacman.global_position) < DISTANCE_FROM_PACMAN:
		return tile_target_scatter
	return pacman.tile
