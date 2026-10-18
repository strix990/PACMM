class_name UIGame extends Control

@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var character_select: CharacterSelect = $CharacterSelect
@onready var vboxcontainer_menu: VBoxContainer = $VBoxContainer/vboxcontainer_menu
@onready var label_result: Label = $VBoxContainer/vboxcontainer_menu/label_result
@onready var button_single: Button = $VBoxContainer/vboxcontainer_menu/button_single
@onready var button_coop: Button = $VBoxContainer/vboxcontainer_menu/button_coop
@onready var button_versus: Button = $VBoxContainer/vboxcontainer_menu/button_versus
@onready var hboxcontainer_item_p2: HBoxContainer = $VBoxContainer/hboxcontainer_bottom/margincontainer_items/HBoxContainer/hboxcontainer_item_p2
@onready var texturerect_item_p1: TextureRect = $VBoxContainer/hboxcontainer_bottom/margincontainer_items/HBoxContainer/hboxcontainer_item_p1/panel_item_p1/texturerect_item_p1
@onready var texturerect_item_p2: TextureRect = $VBoxContainer/hboxcontainer_bottom/margincontainer_items/HBoxContainer/hboxcontainer_item_p2/panel_item_p2/texturerect_item_p2
@onready var label_highscore: Label = $VBoxContainer/hboxcontainer_top/margincontainer_highscore/VBoxContainer/label_highscore
@onready var label_level: Label = $VBoxContainer/hboxcontainer_top/margincontainer_level/VBoxContainer/label_level
@onready var label_score: Label = $VBoxContainer/hboxcontainer_top/margincontainer_score/VBoxContainer/label_score
@onready var texturerect_life_1: TextureRect = $VBoxContainer/hboxcontainer_bottom/margincontainer_lives/HBoxContainer/texturerect_life_1
@onready var texturerect_life_2: TextureRect = $VBoxContainer/hboxcontainer_bottom/margincontainer_lives/HBoxContainer/texturerect_life_2
@onready var texturerect_life_3: TextureRect = $VBoxContainer/hboxcontainer_bottom/margincontainer_lives/HBoxContainer/texturerect_life_3
@onready var texturerect_life_4: TextureRect = $VBoxContainer/hboxcontainer_bottom/margincontainer_lives/HBoxContainer/texturerect_life_4
@onready var texturerect_life_5: TextureRect = $VBoxContainer/hboxcontainer_bottom/margincontainer_lives/HBoxContainer/texturerect_life_5
@onready var texturerect_life_6: TextureRect = $VBoxContainer/hboxcontainer_bottom/margincontainer_lives/HBoxContainer/texturerect_life_6
@onready var texturerect_life_7: TextureRect = $VBoxContainer/hboxcontainer_bottom/margincontainer_lives/HBoxContainer/texturerect_life_7
@onready var texturerect_life_8: TextureRect = $VBoxContainer/hboxcontainer_bottom/margincontainer_lives/HBoxContainer/texturerect_life_8

func _ready() -> void:
	button_single.pressed.connect(on_single_player)
	button_coop.pressed.connect(open_character_select.bind(GM.GameType.COOP))
	button_versus.pressed.connect(open_character_select.bind(GM.GameType.VERSUS))
	character_select.start_requested.connect(on_start)
	character_select.back_requested.connect(func() -> void: vboxcontainer_menu.show())
	GM.level_changed.connect(on_level_changed)
	GM.lives_changed.connect(on_lives_changed)
	GM.mode_changed.connect(on_game_mode_changed)
	SS.stats.highscore_changed.connect(on_hichscore_changed)
	SS.stats.score_changed.connect(on_score_changed)
	
	label_highscore.text = "%02d" % SS.stats.highscore
	
	# every player's inventory (both Pac-Men and the versus ghost) updates the item slots
	for traveller in get_tree().get_nodes_in_group('pacmen') + get_tree().get_nodes_in_group('ghosts'):
		traveller.item_holder.held_changed.connect(func(_item: ItemHolder.Item) -> void: update_item_slots())

func on_game_mode_changed(mode: GM.Mode) -> void:
	match mode:
		GM.Mode.OVER:
			match GM.winner:
				'pacman': label_result.text = "PAC-MAN WINS"
				'ghost': label_result.text = "GHOST WINS"
				_: label_result.text = "GAME OVER"
			label_result.show()
			vboxcontainer_menu.show()

func on_lives_changed(lives: int) -> void:
	texturerect_life_1.visible = lives >= 1
	texturerect_life_2.visible = lives >= 2
	texturerect_life_3.visible = lives >= 3
	texturerect_life_4.visible = lives >= 4
	texturerect_life_5.visible = lives >= 5
	texturerect_life_6.visible = lives >= 6
	texturerect_life_7.visible = lives >= 7
	texturerect_life_8.visible = lives >= 8

func on_level_changed(level: int) -> void:
	label_level.text = "%d" % level

func on_hichscore_changed(highscore: int) -> void:
	label_highscore.text = "%02d" % highscore

func on_score_changed(score: int) -> void:
	label_score.text = "%02d" % score

## The inventory shown in player 1's or player 2's item slot for the current game type.
func get_player_item_holder(player: int) -> ItemHolder:
	for pacman: Pacman in get_tree().get_nodes_in_group('pacmen'):
		if pacman.player == player and pacman.is_active():
			return pacman.item_holder
	if player == 2 and GM.game_type == GM.GameType.VERSUS:
		for ghost: Ghost in get_tree().get_nodes_in_group('ghosts'):
			if ghost.name == GM.versus_ghost:
				return ghost.item_holder
	return null

func update_item_slots() -> void:
	var slots: Array[TextureRect] = [texturerect_item_p1, texturerect_item_p2]
	for i in slots.size():
		var holder: ItemHolder = get_player_item_holder(i + 1)
		slots[i].texture = ItemHolder.ICONS.get(holder.held) if holder != null else null
	hboxcontainer_item_p2.visible = GM.game_type != GM.GameType.SINGLE

## Single player always plays the classic Pac-Man.
func on_single_player() -> void:
	GM.pacman_skins[0] = 0
	on_start(GM.GameType.SINGLE)

func open_character_select(game_type: GM.GameType) -> void:
	vboxcontainer_menu.hide()
	character_select.open(game_type)

func on_start(game_type: GM.GameType) -> void:
	vboxcontainer_menu.hide()
	label_result.hide()
	GM.game_type = game_type
	update_item_slots()
	# the lives icons show player 1's Pac-Man (all lives icons share this texture)
	texturerect_life_1.texture.atlas = PacmanSkins.get_sheet(GM.pacman_skins[0])
	GM.reset.emit(GM.ResetType.GAME)
	audio_stream_player.play()
	await audio_stream_player.finished
	GM.mode = GM.Mode.PLAYING
