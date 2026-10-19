class_name Bomb extends Node2D
## Bomberman-style bomb: blinks for FUSE_TIME, then a + shaped blast (stopped by walls) that
## hits everyone in it while the flames last: Pac-Men die (even the one who placed it) and
## ghosts are sent home as eyes.

const FUSE_TIME: float = 2.0
## Blast length in tiles in each direction.
const RANGE: int = 3
const FLAME_TIME: float = 0.5
const FLAME_OUTER_COLOR: Color = Color('#ff7a1a')
const FLAME_INNER_COLOR: Color = Color('#ffe14a')
## Sprite frames (entities/items/item_bomb.png): two fuse frames, then the explosion.
const FUSE_FRAMES: Array[int] = [0, 1]
const EXPLOSION_FRAME: int = 2

var grid: Grid2D
var time: float = 0.0
var exploded: bool = false
var blast_tiles: Array[Vector2i] = []
## The tile this bomb blocks until it explodes.
var bomb_tile: Vector2i
var blocking: bool = false
## How far the fuse animation has got (in frames); it speeds up as the fuse burns down.
var fuse_phase: float = 0.0

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D

func _ready() -> void:
	GM.reset.connect(func(_type: GM.ResetType) -> void: queue_free())
	bomb_tile = grid.get_tile_from_coords(position)
	grid.add_bomb(bomb_tile)
	blocking = true

func _exit_tree() -> void:
	stop_blocking()

func stop_blocking() -> void:
	if blocking:
		blocking = false
		grid.remove_bomb(bomb_tile)

func _process(delta: float) -> void:
	if GM.mode != GM.Mode.PLAYING:
		return
	time += delta
	if !exploded:
		# the fuse flickers faster and faster as it burns down
		fuse_phase += delta / lerpf(0.25, 0.05, time / FUSE_TIME)
		sprite_2d.frame = FUSE_FRAMES[int(fuse_phase) % FUSE_FRAMES.size()]
		if time >= FUSE_TIME:
			explode()
		return
	hit_everyone_in_blast()
	if time >= FUSE_TIME + FLAME_TIME:
		queue_free()

func explode() -> void:
	exploded = true
	# the explosion frame sits on the bomb's tile, on top of the flames, while they last
	sprite_2d.frame = EXPLOSION_FRAME
	stop_blocking()
	var center: Vector2i = bomb_tile
	blast_tiles = [center]
	for direction: Vector2i in GridTraveller.INPUT_DIRECTIONS.values():
		for i in range(1, RANGE + 1):
			var t: Vector2i = center + direction * i
			if grid.is_wall(t):
				break
			blast_tiles.append(t)
	audio_stream_player_2d.play()
	queue_redraw()
	hit_everyone_in_blast()

func hit_everyone_in_blast() -> void:
	for pacman: Pacman in get_tree().get_nodes_in_group('pacmen'):
		if pacman.is_active() and blast_tiles.has(pacman.tile):
			pacman.die()
	for ghost: Ghost in get_tree().get_nodes_in_group('ghosts'):
		if ghost.is_active() and !ghost.eaten and ghost.house_state == Ghost.HouseState.NONE and blast_tiles.has(ghost.tile):
			ghost.send_home()

func _draw() -> void:
	if !exploded:
		return
	var size: float = grid.tile_map_layer.tile_set.tile_size.x
	for t: Vector2i in blast_tiles:
		var center: Vector2 = to_local(grid.to_global(grid.get_coords_from_tile(t)))
		draw_rect(Rect2(center - Vector2(size, size) / 2.0, Vector2(size, size)), FLAME_OUTER_COLOR)
		draw_rect(Rect2(center - Vector2(size, size) / 4.0, Vector2(size, size) / 2.0), FLAME_INNER_COLOR)
