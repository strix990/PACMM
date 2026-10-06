class_name Pacman extends GridTraveller

@export var audio_stream_death_1: AudioStream
@export var audio_stream_death_2: AudioStream

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
	collectable_2d.collected.connect(on_collectable_collected)
	collector_2d.collected.connect(on_collector_collected)
	# keep the eat-ghost sound playing during the eaten-ghost freeze (tree paused)
	collector_2d.audio_stream_player_2d.process_mode = Node.PROCESS_MODE_ALWAYS
	GM.mode_changed.connect(on_game_mode_changed)
	GM.reset.connect(on_reset)

func get_input() -> void:
	for direction in input_direction_map:
		if Input.is_action_pressed(direction):
			tile_direction = input_direction_map[direction]
			look_direction = tile_direction

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
			

func on_reset(_type: GM.ResetType) -> void:
	global_position = spawn_point
	tile = grid.get_tile_from_coords(global_position)
	tile_direction = tile_direction_reset
	look_direction = tile_direction
