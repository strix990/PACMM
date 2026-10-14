class_name Pacman extends GridTraveller

@export var audio_stream_death_1: AudioStream
@export var audio_stream_death_2: AudioStream
## 1 or 2. Player 2 only plays in co-op and uses the arrow keys.
@export var player: int = 1
@export var tint: Color = Color.WHITE
## Start position/direction in co-op (Vector2.ZERO / Vector2i.ZERO = same as single player).
@export var coop_spawn_point: Vector2 = Vector2.ZERO
@export var coop_tile_direction_reset: Vector2i = Vector2i.ZERO

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var collectable_2d: Collectable2D = $Collectable2D
@onready var collector_2d: Collector2D = $Collector2D
@onready var spawn_point: Vector2 = global_position

var input_direction_map: Dictionary[String, Vector2i] = {
	'up': Vector2i.UP,
	'left': Vector2i.LEFT,
	'down': Vector2i.DOWN,
	'right': Vector2i.RIGHT,
}
var look_direction: Vector2i = Vector2.ZERO:
	set(ld):
		if ![Vector2i.ZERO, Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT].has(ld):
			return
		look_direction = ld
		if ld == Vector2i.ZERO or !input_direction_map.values().has(ld):
			animated_sprite_2d.play('default')
		else:
			animated_sprite_2d.play(input_direction_map.find_key(ld))
var skip_next_frame: bool = false
## True while this Pac-Man plays its death (in co-op the other one just disappears).
var dying: bool = false
func _process(delta: float) -> void:
	if GM.mode != GM.Mode.PLAYING:
		return
	if skip_next_frame:
		skip_next_frame = false
		return
	
	super(delta)
	get_input()
	if global_position != coords_move_to:
		global_position = global_position.move_toward(coords_move_to, delta * speed)
	# like the arcade, Pac-Man stops chomping while blocked by a wall
	var blocked: bool = global_position == coords_move_to and tile_direction_next == Vector2i.ZERO
	if blocked and animated_sprite_2d.is_playing():
		animated_sprite_2d.pause()
	elif !blocked and !animated_sprite_2d.is_playing():
		animated_sprite_2d.play()

func _ready() -> void:
	add_to_group('pacmen')
	animated_sprite_2d.self_modulate = tint
	set_active(is_active())
	collectable_2d.collected.connect(on_collectable_collected)
	collector_2d.collected.connect(on_collector_collected)
	# keep the eat-ghost sound playing during the eaten-ghost freeze (tree paused)
	collector_2d.audio_stream_player_2d.process_mode = Node.PROCESS_MODE_ALWAYS
	GM.mode_changed.connect(on_game_mode_changed)
	GM.reset.connect(on_reset)

func get_input() -> void:
	for direction in read_input_directions(get_input_prefixes()):
		tile_direction = direction
		look_direction = tile_direction

func get_input_prefixes() -> Array[String]:
	if player == 2:
		return ['p2_']
	# alone, Pac-Man can be steered with both WASD and the arrow keys
	if GM.game_type == GM.GameType.SINGLE:
		return ['p1_', 'p2_']
	return ['p1_']

func is_active() -> bool:
	return player == 1 or GM.game_type == GM.GameType.COOP

## An inactive Pac-Man is hidden and disabled, which also takes its collision areas out of the game.
func set_active(active: bool) -> void:
	visible = active
	process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED

func get_speed() -> float:
	match GM.level:
		1:
			if GM.ghosts_frightened > 0:
				return speed * 0.9
			return speed * 0.8
		2, 3, 4:
			if GM.ghosts_frightened > 0:
				return speed * 0.95
			return speed * 0.9
		5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20:
			return speed
		_:
			if GM.ghosts_frightened > 0:
				return speed
			return speed * 0.9

func on_collectable_collected() -> void:
	# in co-op, if both Pac-Men are caught at once only one life is lost
	if GM.mode != GM.Mode.PLAYING:
		return
	dying = true
	GM.mode = GM.Mode.DEATH
	animated_sprite_2d.pause()
	await get_tree().create_timer(1.0).timeout
	animated_sprite_2d.play('death')
	audio_stream_player_2d.stream = audio_stream_death_1
	audio_stream_player_2d.play()
	await animated_sprite_2d.animation_finished
	if audio_stream_player_2d.playing:
		await audio_stream_player_2d.finished
	if audio_stream_death_2 != null:
		audio_stream_player_2d.stream = audio_stream_death_2
		audio_stream_player_2d.play()
		await audio_stream_player_2d.finished
	GM.lives -= 1

func on_collector_collected(collectable: Collectable2D) -> void:
	match collectable.identifier:
		'pellet', 'power_pellet':
			# skip 1 frame every time a pellet is eaten
			skip_next_frame = true

func on_game_mode_changed(mode: GM.Mode) -> void:
	match mode:
		GM.Mode.PLAYING:
			look_direction = tile_direction
		GM.Mode.DEATH:
			# the other Pac-Man disappears like the ghosts while this one plays its death
			if !dying:
				await get_tree().create_timer(1.0).timeout
				if GM.mode == GM.Mode.DEATH:
					visible = false

func on_reset(_type: GM.ResetType) -> void:
	dying = false
	var coop: bool = GM.game_type == GM.GameType.COOP
	global_position = coop_spawn_point if coop and coop_spawn_point != Vector2.ZERO else spawn_point
	tile = grid.get_tile_from_coords(global_position)
	tile_direction = coop_tile_direction_reset if coop and coop_tile_direction_reset != Vector2i.ZERO else tile_direction_reset
	look_direction = tile_direction
	set_active(is_active())
