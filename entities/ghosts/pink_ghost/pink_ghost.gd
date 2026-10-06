class_name PinkGhost extends Ghost

const TILES_AHEAD_OF_PACMAN: int = 4

func get_tile_target_during_chase() -> Vector2i:
	return pacman.tile + (pacman.look_direction * TILES_AHEAD_OF_PACMAN)
