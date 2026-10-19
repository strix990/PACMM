class_name ItemHolder extends Node
## A player's one-item inventory (Mario Kart style) and the effects of using items.
## Added in code as a child of Pac-Man and of the ghosts (only the versus ghost gets items).
## The owner provides get_item_actions() -> Array[String] with the input actions that use the item.

enum Item {
	NONE,
	SPEED,
	DASH,
	WALL_WALK,
	BOMB,
}

const SPEED_BOOST_MULTIPLIER: float = 1.5
const SPEED_BOOST_TIME: float = 5.0
const DASH_MULTIPLIER: float = 5.0
const DASH_TIME: float = 0.15
const WALL_WALK_TIME: float = 5.0
const STUN_TIME: float = 2.0
const WALL_WALK_MODULATE: Color = Color(1, 1, 1, 0.5)
const STUN_MODULATE: Color = Color(0.5, 0.5, 0.5)

## Loaded on use (not preloaded) so the bomb, which knows about Pac-Man and ghosts, isn't a load cycle.
const BOMB_SCENE_PATH: String = 'res://entities/items/bomb.tscn'
## Item icons: strips of ICON_FRAME_SIZE square animation frames, looped in the HUD item slot.
const ICONS: Dictionary = {
	Item.SPEED: preload('res://entities/items/item_speed.png'),
	Item.DASH: preload('res://entities/items/item_dash.png'),
	Item.WALL_WALK: preload('res://entities/items/item_wall_walk.png'),
	Item.BOMB: preload('res://entities/items/item_bomb.png'),
}
const ICON_FRAME_SIZE: int = 16
const ICON_FRAME_TIME: float = 0.15
## Frames each icon loops through (the bomb's last frame is its explosion, used by the bomb itself).
const ICON_LOOPS: Dictionary = {
	Item.SPEED: [0, 1, 2],
	Item.DASH: [0, 1, 2],
	Item.WALL_WALK: [0, 1, 2],
	Item.BOMB: [0, 1],
}

## The part of the item's icon strip to show after `time` seconds of animation.
static func get_icon_region(item: Item, time: float) -> Rect2:
	var frames: Array = ICON_LOOPS[item]
	var frame: int = frames[int(time / ICON_FRAME_TIME) % frames.size()]
	return Rect2(frame * ICON_FRAME_SIZE, 0, ICON_FRAME_SIZE, ICON_FRAME_SIZE)

var held: Item = Item.NONE:
	set(h):
		if h == held:
			return
		held = h
		held_changed.emit(h)
var traveller: GridTraveller
var boost_time: float = 0.0
var dash_time: float = 0.0
var wall_walk_time: float = 0.0
var stun_time: float = 0.0

signal held_changed(item: Item)

func _ready() -> void:
	traveller = get_parent()
	GM.reset.connect(on_reset)

func _process(delta: float) -> void:
	if GM.mode != GM.Mode.PLAYING:
		return
	if held != Item.NONE and !traveller.stunned:
		for action: String in traveller.get_item_actions():
			if Input.is_action_just_pressed(action):
				use()
				break
	tick(delta)

## What the item box gives: one of the 4 items or a stun, each with the same chance.
func roll() -> void:
	var outcome: int = randi() % 5
	if outcome == 4:
		stun()
	else:
		held = [Item.SPEED, Item.DASH, Item.WALL_WALK, Item.BOMB][outcome]

func stun() -> void:
	stun_time = STUN_TIME
	traveller.stunned = true
	update_look()

func use() -> void:
	match held:
		Item.SPEED:
			boost_time = SPEED_BOOST_TIME
		Item.DASH:
			dash_time = DASH_TIME
		Item.WALL_WALK:
			wall_walk_time = WALL_WALK_TIME
			traveller.can_pass_walls = true
		Item.BOMB:
			var bomb: Bomb = load(BOMB_SCENE_PATH).instantiate()
			bomb.grid = traveller.grid
			bomb.position = traveller.grid.get_coords_from_tile(traveller.tile)
			traveller.get_parent().add_child(bomb)
	held = Item.NONE
	update_speed()
	update_look()

func tick(delta: float) -> void:
	boost_time = maxf(boost_time - delta, 0.0)
	dash_time = maxf(dash_time - delta, 0.0)
	if wall_walk_time > 0.0:
		wall_walk_time -= delta
		if wall_walk_time <= 0.0:
			end_wall_walk()
	if stun_time > 0.0:
		stun_time -= delta
		if stun_time <= 0.0:
			traveller.stunned = false
			update_look()
	update_speed()

func end_wall_walk() -> void:
	wall_walk_time = 0.0
	traveller.can_pass_walls = false
	traveller.snap_to_walkable_tile()
	update_look()

func update_speed() -> void:
	traveller.speed_multiplier = (SPEED_BOOST_MULTIPLIER if boost_time > 0.0 else 1.0) * (DASH_MULTIPLIER if dash_time > 0.0 else 1.0)

func update_look() -> void:
	if traveller.stunned:
		traveller.modulate = STUN_MODULATE
	elif traveller.can_pass_walls:
		traveller.modulate = WALL_WALK_MODULATE
	else:
		traveller.modulate = Color.WHITE

## Ends every active effect (e.g. when a ghost gets eaten while using an item).
func clear_effects() -> void:
	boost_time = 0.0
	dash_time = 0.0
	stun_time = 0.0
	traveller.stunned = false
	if wall_walk_time > 0.0:
		end_wall_walk()
	update_speed()
	update_look()

func on_reset(_type: GM.ResetType) -> void:
	held = Item.NONE
	clear_effects()
