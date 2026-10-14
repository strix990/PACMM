class_name RedGhost extends Ghost

func get_tile_target_during_chase() -> Vector2i:
	return get_target_pacman().tile
