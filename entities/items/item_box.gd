class_name ItemBox extends Node2D
## Mario Kart style item box at a fixed spot: appears SPAWN_DELAY seconds into a game and
## again SPAWN_DELAY seconds after it was taken. Taken by any human player with an empty
## inventory (Pac-Men, and the ghost in versus); gives an item or a stun (see ItemHolder.roll).

const SPAWN_DELAY: float = 15.0
## How fast the box cycles through colours (hue turns per second).
const HUE_SPEED: float = 0.5

var available: bool = false
var countdown: float = SPAWN_DELAY

@onready var area_2d: Area2D = $Area2D
@onready var sprite_2d: Sprite2D = $Sprite2D

func _ready() -> void:
	GM.reset.connect(on_reset)
	set_available(false)

func _process(delta: float) -> void:
	if GM.mode != GM.Mode.PLAYING:
		return
	if !available:
		countdown -= delta
		if countdown <= 0.0:
			set_available(true)
		return
	sprite_2d.modulate = Color.from_hsv(fmod(Time.get_ticks_msec() / 1000.0 * HUE_SPEED, 1.0), 0.5, 1.0)
	# checked every frame (not just on enter) so a player who used their item while
	# standing on the box can still take it
	for area: Area2D in area_2d.get_overlapping_areas():
		var holder: ItemHolder = get_holder(area.get_parent())
		if holder != null and holder.held == ItemHolder.Item.NONE:
			holder.roll()
			set_available(false)
			countdown = SPAWN_DELAY
			return

## The inventory of whoever this is, if they are a player that can take items.
func get_holder(node: Node) -> ItemHolder:
	if node is Pacman and node.is_active():
		return node.item_holder
	if node is Ghost and node.player_controlled and !node.eaten:
		return node.item_holder
	return null

func set_available(a: bool) -> void:
	available = a
	visible = a
	area_2d.monitoring = a

func on_reset(type: GM.ResetType) -> void:
	# losing a life keeps the box as it was; a new game or level starts the countdown again
	if type == GM.ResetType.LIFE:
		return
	set_available(false)
	countdown = SPAWN_DELAY
