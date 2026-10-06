class_name UIGame extends Control

@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var button_start: Button = $VBoxContainer/button_start
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
	button_start.pressed.connect(on_start)
	GM.level_changed.connect(on_level_changed)
	GM.lives_changed.connect(on_lives_changed)
	GM.mode_changed.connect(on_game_mode_changed)
	SS.stats.highscore_changed.connect(on_hichscore_changed)
	SS.stats.score_changed.connect(on_score_changed)
	
	label_highscore.text = "%02d" % SS.stats.highscore

func on_game_mode_changed(mode: GM.Mode) -> void:
	match mode:
		GM.Mode.OVER:
			button_start.show()

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

func on_start() -> void:
	button_start.hide()
	GM.reset.emit(GM.ResetType.GAME)
	audio_stream_player.play()
	await audio_stream_player.finished
	GM.mode = GM.Mode.PLAYING
