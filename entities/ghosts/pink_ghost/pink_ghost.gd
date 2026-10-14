class_name PinkGhost extends Ghost

const TILES_AHEAD_OF_PACMAN: int = 4

func get_tile_target_during_chase() -> Vector2i:
	var target: Pacman = get_target_pacman()
	return target.tile + (target.look_direction * TILES_AHEAD_OF_PACMAN)
