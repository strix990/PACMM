class_name Ghost extends GridTraveller

#region ENUMS
enum HouseState {
	NONE,
	GOING_IN,
	GOING_OUT,
	WAITING,
}
#endregion

#region CONSTANTS
const DIRECTION_MAP: Dictionary[String, Vector2i] = {
	'up': Vector2i.UP,
	'left': Vector2i.LEFT,
	'down': Vector2i.DOWN,
	'right': Vector2i.RIGHT,
}
const FRIGHTEN_ALMOST_OVER_TIME: float = 2.0
const POINTS_DEFAULT: int = 200
## Versus balance: the player-controlled ghost is this much faster than a normal ghost.
const VERSUS_SPEED_MULTIPLIER: float = 1.1
## After being eaten, the versus ghost leaves the house after this long.
const PLAYER_HOUSE_WAIT_TIME: float = 0.05
## Once half of the level's pellets are eaten, every ghost gets this much faster (all modes).
const HALF_PELLETS_SPEED_MULTIPLIER: float = 1.05
const POINTS_LABEL_COLOR: Color = Color('#ff0000')
## How long the game freezes (and shows the points) after eating a ghost.
const POINTS_LABEL_TIME: float = 1.0
const POINTS_LABEL_THEME: Theme = preload('res://config/theme/default_theme.tres')
#endregion

#region VARIABLES
## Number of eaten-ghost freezes in progress (two ghosts can be eaten in the same frame).
static var freeze_count: int = 0
@export var house_center_point: Vector2 = Vector2(112, 140)
@export var house_entrance_point: Vector2 = Vector2(112, 116)
@export var house_state_reset: HouseState = HouseState.NONE:
	set(hsr):
		if !HouseState.values().has(hsr) or hsr == house_state_reset:
			return
		house_state_reset = hsr
@export var house_waiting_point: Vector2 = Vector2(112, 140)
@export var pacman: Pacman
@export var spawn_point: Vector2 = Vector2.ZERO
@export var tile_target_scatter: Vector2i = Vector2i.ZERO

@onready var animatedsprite_2d_default: AnimatedSprite2D = $animatedsprite2d_default
@onready var animatedsprite_2d_eaten: AnimatedSprite2D = $animatedsprite2d_eaten
@onready var animatedsprite_2d_frightened: AnimatedSprite2D = $animatedsprite2d_frightened
@onready var area_2d_tunnel_trigger: Area2D = $area2d_tunnel_trigger
@onready var collectable_2d: Collectable2D = $Collectable2D
@onready var collector_2d: Collector2D = $Collector2D
@onready var timer_frighten: Timer = $timer_frighten
@onready var timer_house: Timer = $timer_house

var frighten: bool = false:
	set(f):
		if f == frighten:
			return
		frighten = f
		GM.ghosts_frightened += 1 if f else -1
		animatedsprite_2d_frightened.visible = f
		animatedsprite_2d_default.visible = !f
		collectable_2d.disabled = !f
		if !eaten:
			collector_2d.disabled = f
		points = POINTS_DEFAULT
		if f and !player_controlled:
			tile_direction = -tile_direction
		animatedsprite_2d_frightened.play('left')
var house_state: HouseState = house_state_reset:
	set(hs):
		if !HouseState.values().has(hs) or hs == house_state:
			return
		house_state = hs
		match hs:
			HouseState.WAITING:
				if timer_house and GM.mode == GM.Mode.PLAYING:
					timer_house.start()
var house_target_point: Vector2 = Vector2.ZERO:
	set(htp):
		house_target_point = htp
		tile_direction = global_position.direction_to(htp).round()
		match house_state:
			HouseState.GOING_IN:
				if global_position == house_waiting_point:
					house_state = HouseState.WAITING
					eaten = false
			HouseState.GOING_OUT:
				if htp == Vector2.ZERO:
					tile_direction = DIRECTION_MAP['left']
					house_state = HouseState.NONE
var eaten: bool = false:
	set(t):
		if t == eaten:
			return
		eaten = t
		GM.ghosts_returning += 1 if t else -1
		var points_earned: int = points
		if t:
			# eyes can't catch Pac-Man (a bombed ghost wasn't frightened, so this wasn't off yet)
			collector_2d.disabled = true
			if !bombed:
				SS.stats.score += points
				SS.stats.ghosts_eaten += 1
				SS.save_stats()
		else:
			collector_2d.disabled = false
		# to keep things simple, just always set frighten to false at this point
		frighten = false
		animatedsprite_2d_default.visible = !t
		animatedsprite_2d_eaten.visible = t
		if t:
			if item_holder:
				item_holder.clear_effects()
			# a player ghost may be standing still: pick the eyes' way home right away instead of
			# waiting for the next tile (which never comes when not moving)
			tile_direction_next = calculate_tile_direction_next()
			if !bombed:
				freeze_and_show_points(points_earned)
var in_tunnel: bool = false
var mode: GM.GhostMode = GM.ghost_mode:
	set(m):
		if !GM.GhostMode.values().has(m) or m == mode:
			return
		if !player_controlled:
			tile_direction = -tile_direction
		mode = m
var points: int = POINTS_DEFAULT
## Steered by player 2 instead of the AI: the ghost chosen for versus (GM.versus_ghost).
var player_controlled: bool = false
## The house timer as set up in the scene (the versus ghost leaves the house right away instead).
var house_wait_time: float
var item_holder: ItemHolder
## Set while being sent home by a bomb: no points and no freeze for that.
var bombed: bool = false
var tile_target: Vector2i = Vector2i.ZERO:
	set(tt):
		if tt == tile_target:
			return
		tile_target = tt
#endregion

#region FUNCTIONS
func _process(delta: float) -> void:
	if GM.mode != GM.Mode.PLAYING or stunned:
		return
	
	super(delta)
	
	if player_controlled and !eaten and house_state == HouseState.NONE:
		for direction in read_input_directions(['p2_']):
			tile_direction = direction
	
	if house_state != HouseState.NONE:
		if house_target_point == Vector2.ZERO:
			house_target_point = get_next_house_target_point()
		global_position = global_position.move_toward(house_target_point, delta * get_current_speed())
		if global_position == house_target_point:
			house_target_point = get_next_house_target_point()
		return
	
	if global_position != coords_move_to:
		global_position = global_position.move_toward(coords_move_to, delta * get_current_speed())
		if eaten:
			if tile == grid.get_tile_from_coords(house_entrance_point):
				house_state = HouseState.GOING_IN
	
	if frighten and timer_frighten.time_left <= FRIGHTEN_ALMOST_OVER_TIME and animatedsprite_2d_frightened.animation != &'flash':
		animatedsprite_2d_frightened.play('flash')

func _ready() -> void:
	area_2d_tunnel_trigger.area_entered.connect(on_tunnel_trigger_area_entered)
	area_2d_tunnel_trigger.area_exited.connect(on_tunnel_trigger_area_exited)
	collectable_2d.collected.connect(on_collected)
	GM.frighten_ghosts.connect(on_frighten_ghosts)
	GM.mode_changed.connect(on_game_mode_changed)
	GM.reset.connect(on_reset)
	SS.stats.ghosts_eaten_changed.connect(on_ghosts_eaten_changed)
	add_to_group('ghosts')
	house_wait_time = timer_house.wait_time
	item_holder = ItemHolder.new()
	add_child(item_holder)
	tile_direction_changed.connect(on_tile_direction_changed)
	timer_frighten.timeout.connect(on_timer_frighten_timeout)
	timer_house.timeout.connect(on_timer_house_timeout)
	
	coords_move_to = grid.get_coords_from_tile(tile + tile_direction)
	house_state = house_state_reset
	on_tile_direction_changed(tile_direction)

func calculate_tile_direction_next() -> Vector2i:
	# the player ghost keeps going straight until steered (eaten eyes still find home by themselves)
	if player_controlled and !eaten:
		return super()
	if frighten:
		return get_tile_direction_while_frightened()
	if eaten:
		tile_target = grid.get_tile_from_coords(house_entrance_point)
		return get_tile_direction_next_from_tile_target()
	
	mode = GM.ghost_mode
	if mode == GM.GhostMode.SCATTER:
		tile_target = tile_target_scatter
	if mode == GM.GhostMode.CHASE:
		tile_target = get_tile_target_during_chase()
	return get_tile_direction_next_from_tile_target()

func get_next_house_target_point() -> Vector2:
	match house_state:
		HouseState.GOING_IN:
			if house_target_point == Vector2.ZERO:
				return house_entrance_point
			elif house_target_point == house_entrance_point:
				return house_center_point
			elif house_target_point == house_center_point:
				return house_waiting_point
		HouseState.GOING_OUT:
			if ![house_center_point, house_entrance_point].has(house_target_point):
				return house_center_point
			elif house_target_point == house_center_point:
				return house_entrance_point
			elif house_target_point == house_entrance_point:
				return Vector2.ZERO
		HouseState.WAITING:
			var above: Vector2 = Vector2(house_waiting_point.x, house_waiting_point.y - 4)
			var below: Vector2 = Vector2(house_waiting_point.x, house_waiting_point.y + 4)
			return above if house_target_point != above else below
	return Vector2.ZERO

## Item effects, the versus bonus for the player-controlled ghost and the half-pellets speed-up.
func get_current_speed() -> float:
	var multiplier: float = VERSUS_SPEED_MULTIPLIER if player_controlled else 1.0
	if GM.pellets_eaten >= GM.pellets_total / 2:
		multiplier *= HALF_PELLETS_SPEED_MULTIPLIER
	return super() * multiplier

func get_speed() -> float:
	if eaten:
		return speed * 2.0
	match GM.level:
		1:
			if in_tunnel:
				return speed * 0.4
			elif GM.ghosts_frightened > 0:
				return speed * 0.5 
			return speed * 0.75
		2, 3, 4:
			if in_tunnel:
				return speed * 0.45
			elif GM.ghosts_frightened > 0:
				return speed * 0.55
			return speed * 0.85
		5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20:
			if in_tunnel:
				return speed * 0.5
			elif GM.ghosts_frightened > 0:
				return speed * 0.6
			return speed * 0.95
		_:
			if in_tunnel:
				return speed * 0.5
			return speed * 0.95

func get_tile_direction_next_from_tile_target() -> Vector2i:
	if grid == null:
		return Vector2i.ZERO
	var next_tile_direction: Vector2i = Vector2i.ZERO
	for direction: Vector2i in DIRECTION_MAP.values():
		# ignore the direction from which the ghost came from
		if direction == -tile_direction:
			continue
		# ignore if the tile direction is not walkable
		if !is_tile_walkable(tile + direction):
			continue
		# if no next direction has been set yet: set it
		if next_tile_direction == Vector2i.ZERO:
			next_tile_direction = direction
			continue
		# override the next tile direction with this one only if it is closer
		if (tile + direction).distance_to(tile_target) < (tile + next_tile_direction).distance_to(tile_target):
			next_tile_direction = direction
	# if no next tile direction was set: walk back as last resort
	return next_tile_direction if next_tile_direction != Vector2i.ZERO else -tile_direction

func get_tile_direction_while_frightened() -> Vector2i:
	var directions_except_backwards = DIRECTION_MAP.values().filter(
		func (d: Vector2i): return d != -tile_direction
	)
	
	var random_direction = directions_except_backwards.pick_random()
	if is_tile_walkable(tile + random_direction):
		return random_direction
	
	for direction: Vector2i in DIRECTION_MAP.values():
		# ignore the direction from which the ghost came from
		if direction == -tile_direction:
			continue
		if is_tile_walkable(tile + direction):
			return direction
	# if no next tile direction was set: walk back as last resort
	return -tile_direction

func get_tile_target_during_chase() -> Vector2i:
	return tile_target_scatter

## The Pac-Man this ghost chases: the nearest one still in play (co-op has two).
func get_target_pacman() -> Pacman:
	var target: Pacman = pacman
	for p: Pacman in get_tree().get_nodes_in_group('pacmen'):
		if !p.is_active():
			continue
		if target == null or !target.is_active() or global_position.distance_to(p.global_position) < global_position.distance_to(target.global_position):
			target = p
	return target

func is_active() -> bool:
	return GM.game_type != GM.GameType.VERSUS or name == GM.versus_ghost

## Like the arcade: freeze the game for a moment and show the points earned for eating this
## ghost where it was caught, with Pac-Man and the eaten ghost hidden meanwhile.
func freeze_and_show_points(amount: int) -> void:
	var label: Label = Label.new()
	label.theme = POINTS_LABEL_THEME
	label.text = str(amount)
	label.add_theme_font_size_override('font_size', 8)
	label.add_theme_color_override('font_color', POINTS_LABEL_COLOR)
	label.z_index = 10
	get_parent().add_child(label)
	label.reset_size()
	label.global_position = (global_position - label.size / 2.0).round()

	freeze_count += 1
	get_tree().paused = true
	for p: Pacman in get_tree().get_nodes_in_group('pacmen'):
		p.visible = false
	animatedsprite_2d_eaten.visible = false
	# scene tree timers keep running while the tree is paused
	await get_tree().create_timer(POINTS_LABEL_TIME).timeout
	label.queue_free()
	animatedsprite_2d_eaten.visible = eaten
	freeze_count -= 1
	if freeze_count == 0:
		get_tree().paused = false
		for p: Pacman in get_tree().get_nodes_in_group('pacmen'):
			p.visible = p.is_active()

func on_collected() -> void:
	eaten = true

## Hit by a bomb: back to the house as eyes, without points or the eaten freeze.
func send_home() -> void:
	bombed = true
	eaten = true
	bombed = false

func get_item_actions() -> Array[String]:
	if player_controlled:
		return ['p2_item']
	return []

func on_game_mode_changed(m: GM.Mode) -> void:
	match m:
		GM.Mode.PLAYING:
			if house_state == HouseState.WAITING:
				timer_house.start()
		GM.Mode.DEATH:
			await get_tree().create_timer(1.0).timeout
			visible = false
			process_mode = Node.PROCESS_MODE_DISABLED
			

func on_frighten_ghosts(time: float) -> void:
	# ghosts sitting out a versus match would stay frightened forever (their timer is disabled),
	# keeping everyone at frightened speed
	if eaten or !is_active():
		return
	frighten = true
	timer_frighten.start(time)
	animatedsprite_2d_frightened.play('left')

func on_ghosts_eaten_changed(_pt: int) -> void:
	if !eaten and frighten:
		points *= 2

func on_tile_direction_changed(td: Vector2i) -> void:
	if DIRECTION_MAP.values().has(td):
		animatedsprite_2d_default.play(DIRECTION_MAP.find_key(td))
		animatedsprite_2d_eaten.play(DIRECTION_MAP.find_key(td))
		if animatedsprite_2d_frightened.animation != &'flash':
			animatedsprite_2d_frightened.play(DIRECTION_MAP.find_key(td))

func on_timer_frighten_timeout() -> void:
	frighten = false

func on_timer_house_timeout() -> void:
	if house_state == HouseState.WAITING:
		house_state = HouseState.GOING_OUT

func on_tunnel_trigger_area_entered(area: Area2D) -> void:
	if area is Tunnel:
		in_tunnel = true

func on_tunnel_trigger_area_exited(area: Area2D) -> void:
	if area is Tunnel:
		in_tunnel = false

func on_reset(_type: GM.ResetType) -> void:
	player_controlled = GM.game_type == GM.GameType.VERSUS and name == GM.versus_ghost
	timer_house.wait_time = PLAYER_HOUSE_WAIT_TIME if player_controlled else house_wait_time
	# in versus the AI ghosts sit the match out (hidden, disabled, no collisions)
	visible = is_active()
	process_mode = Node.PROCESS_MODE_INHERIT if is_active() else Node.PROCESS_MODE_DISABLED
	frighten = false
	eaten = false
	# the versus ghost always starts outside the house, at its entrance, whatever its colour
	global_position = house_entrance_point if player_controlled else spawn_point
	house_state = HouseState.NONE if player_controlled else house_state_reset
	house_target_point = Vector2i.ZERO
	points = POINTS_DEFAULT
	tile = grid.get_tile_from_coords(global_position)
	tile_direction = Vector2i.LEFT if player_controlled else tile_direction_reset
	tile_target = Vector2i.ZERO
#endregion
