class_name CharacterSelect extends Control
## Character select for co-op and versus, opened from the main menu.
## Co-op: both players pick a Pac-Man skin (not the same one). Versus: player 1 picks a Pac-Man
## skin and player 2 picks which ghost to play.
## Keyboard: P1 A/D + Space, P2 left/right + Enter (Space/Enter again once both are ready starts
## the game; moving un-readies). The mouse works too. Esc goes back.

signal start_requested(game_type: GM.GameType)
signal back_requested

const BLUE: Color = Color('#1b3bb0')
const BLUE_HOVER: Color = Color('#2d52d6')
const GREY: Color = Color('#3a3a4a')
const PANEL_BORDER: Color = Color('#ffe14a')
const READY_BORDER: Color = Color('#4ae36a')
const HIGHLIGHT_BORDER: Color = Color.WHITE
const TAKEN_MODULATE: Color = Color(1, 1, 1, 0.3)
const PREVIEW_FRAME_TIME: float = 0.12
const PREVIEW_SIZE: Vector2 = Vector2(64, 64)
const OPTION_SIZE: float = 18.0
const GHOSTS: Array[Dictionary] = [
	{'name': 'RED', 'node': 'RedGhost', 'sheet': 'res://entities/ghosts/red_ghost/red_ghost.png'},
	{'name': 'PINK', 'node': 'PinkGhost', 'sheet': 'res://entities/ghosts/pink_ghost/pink_ghost.png'},
	{'name': 'CYAN', 'node': 'CyanGhost', 'sheet': 'res://entities/ghosts/cyan_ghost/cyan_ghost.png'},
	{'name': 'ORANGE', 'node': 'OrangeGhost', 'sheet': 'res://entities/ghosts/orange_ghost/orange_ghost.png'},
]
## Ghost sheet cells facing right (two wobble frames).
const GHOST_PREVIEW_CELLS: Array[int] = [6, 7]

var game_type: GM.GameType = GM.GameType.COOP
## Per player: {kind: 'pacman'/'ghost', index, ready, and its nodes}.
var players: Array[Dictionary] = []
var anim_time: float = 0.0
var button_start: Button

func _ready() -> void:
	hide()

## Shows the screen for co-op or versus, starting from the last choices.
func open(type: GM.GameType) -> void:
	game_type = type
	for child in get_children():
		child.queue_free()
	players.clear()
	build()
	show()
	get_viewport().gui_release_focus()

func _process(delta: float) -> void:
	if !visible:
		return
	anim_time += delta
	for p in players.size():
		var player: Dictionary = players[p]
		var prefix: String = 'p%d_' % (p + 1)
		if Input.is_action_just_pressed(prefix + 'left'):
			move(p, -1)
		elif Input.is_action_just_pressed(prefix + 'right'):
			move(p, 1)
		if Input.is_action_just_pressed(prefix + 'item'):
			press_select(p)
		update_preview(player)
	if Input.is_action_just_pressed('ui_cancel'):
		back_requested.emit()
		hide()

#region choices
func option_count(p: int) -> int:
	return GHOSTS.size() if players[p]['kind'] == 'ghost' else PacmanSkins.SKINS.size()

## In co-op the two Pac-Men can't use the same skin: whatever the other player has readied is taken.
func is_taken(p: int, index: int) -> bool:
	if game_type != GM.GameType.COOP:
		return false
	var other: Dictionary = players[1 - p]
	return other['ready'] and other['index'] == index

func move(p: int, step: int) -> void:
	var player: Dictionary = players[p]
	player['ready'] = false
	player['index'] = posmod(player['index'] + step, option_count(p))
	refresh()

func choose(p: int, index: int) -> void:
	players[p]['ready'] = false
	players[p]['index'] = index
	refresh()

func press_select(p: int) -> void:
	if can_start():
		start()
		return
	var player: Dictionary = players[p]
	if player['ready']:
		player['ready'] = false
	elif !is_taken(p, player['index']):
		player['ready'] = true
	refresh()

func can_start() -> bool:
	return players.all(func(player: Dictionary) -> bool: return player['ready'])

func start() -> void:
	GM.pacman_skins[0] = players[0]['index']
	if players[1]['kind'] == 'ghost':
		GM.versus_ghost = GHOSTS[players[1]['index']]['node']
	else:
		GM.pacman_skins[1] = players[1]['index']
	hide()
	start_requested.emit(game_type)
#endregion

#region drawing
func refresh() -> void:
	for p in players.size():
		var player: Dictionary = players[p]
		player['panel'].add_theme_stylebox_override('panel', box_style(Color.BLACK, READY_BORDER if player['ready'] else PANEL_BORDER, 6))
		player['label_name'].text = get_option_name(p, player['index'])
		player['preview_frames'] = get_preview_frames(player['kind'], player['index'])
		player['button'].text = 'READY' if player['ready'] else 'SELECT'
		player['button'].disabled = is_taken(p, player['index'])
		for i in player['options'].size():
			var option: Panel = player['options'][i]
			var border: Color = HIGHLIGHT_BORDER if i == player['index'] else BLUE
			if i == player['index'] and player['ready']:
				border = READY_BORDER
			option.add_theme_stylebox_override('panel', box_style(BLUE, border, 3))
			option.modulate = TAKEN_MODULATE if is_taken(p, i) else Color.WHITE
	button_start.disabled = !can_start()

func update_preview(player: Dictionary) -> void:
	var step: int = int(anim_time / PREVIEW_FRAME_TIME)
	var frames: Array[Texture2D] = player['preview_frames']
	if player['kind'] == 'pacman':
		player['preview'].texture = frames[[0, 1, 2, 1][step % 4]]
	else:
		player['preview'].texture = frames[(step / 2) % frames.size()]

func get_option_name(p: int, index: int) -> String:
	if players[p]['kind'] == 'ghost':
		return GHOSTS[index]['name']
	return PacmanSkins.SKINS[index]['name']

func get_icon(kind: String, index: int) -> Texture2D:
	if kind == 'ghost':
		return PacmanSkins.get_cell(load(GHOSTS[index]['sheet']), GHOST_PREVIEW_CELLS[0])
	return PacmanSkins.get_icon(index)

func get_preview_frames(kind: String, index: int) -> Array[Texture2D]:
	if kind == 'ghost':
		var frames: Array[Texture2D] = []
		for cell in GHOST_PREVIEW_CELLS:
			frames.append(PacmanSkins.get_cell(load(GHOSTS[index]['sheet']), cell))
		return frames
	return PacmanSkins.get_preview_frames(index)

func box_style(bg: Color, border: Color, radius: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	return style
#endregion

#region building the screen (sized for the 224x288 game screen)
func build() -> void:
	var background: ColorRect = ColorRect.new()
	background.color = Color.BLACK
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var title: Label = make_label('CO-OP' if game_type == GM.GameType.COOP else 'VERSUS', 16)
	title.add_theme_stylebox_override('normal', box_style(BLUE, BLUE, 3))
	place(title, Vector2(62, 4), Vector2(100, 24))

	for p in 2:
		var kind: String = 'ghost' if game_type == GM.GameType.VERSUS and p == 1 else 'pacman'
		var index: int = 0
		if kind == 'ghost':
			index = GHOSTS.find_custom(func(g: Dictionary) -> bool: return g['node'] == GM.versus_ghost)
		else:
			index = GM.pacman_skins[p]
		players.append(build_column(p, kind, maxi(index, 0), 6 + p * 112))
	# co-op: don't start both on the same skin
	if game_type == GM.GameType.COOP and players[0]['index'] == players[1]['index']:
		players[1]['index'] = (players[0]['index'] + 1) % PacmanSkins.SKINS.size()

	button_start = make_button('START', 16)
	place(button_start, Vector2(72, 196), Vector2(80, 24))
	button_start.pressed.connect(start)
	var button_back: Button = make_button('BACK', 8)
	place(button_back, Vector2(88, 226), Vector2(48, 15))
	button_back.pressed.connect(func() -> void:
		back_requested.emit()
		hide())
	var hint: Label = make_label('P1  A D  SPACE      P2  ARROWS  ENTER', 8)
	hint.modulate = Color(1, 1, 1, 0.6)
	place(hint, Vector2(0, 250), Vector2(224, 11))
	refresh()

func build_column(p: int, kind: String, index: int, x: float) -> Dictionary:
	var player: Dictionary = {'kind': kind, 'index': index, 'ready': false, 'options': [], 'preview_frames': []}
	place(make_label('P%d' % (p + 1), 16), Vector2(x, 29), Vector2(100, 22))

	var panel: Panel = Panel.new()
	place(panel, Vector2(x, 52), Vector2(100, 114))
	player['panel'] = panel
	var preview: TextureRect = TextureRect.new()
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	place(preview, Vector2((100 - PREVIEW_SIZE.x) / 2.0, 6), PREVIEW_SIZE, panel)
	player['preview'] = preview
	var label_name: Label = make_label('', 8)
	place(label_name, Vector2(0, 72), Vector2(100, 11), panel)
	player['label_name'] = label_name

	var count: int = GHOSTS.size() if kind == 'ghost' else PacmanSkins.SKINS.size()
	var gap: float = 1.0 if count > 4 else 4.0
	var row_width: float = count * OPTION_SIZE + (count - 1) * gap
	for i in count:
		var option: Panel = Panel.new()
		place(option, Vector2((100 - row_width) / 2.0 + i * (OPTION_SIZE + gap), 88), Vector2(OPTION_SIZE, OPTION_SIZE), panel)
		option.mouse_filter = Control.MOUSE_FILTER_STOP
		option.gui_input.connect(func(event: InputEvent) -> void:
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				choose(p, i))
		var icon: TextureRect = TextureRect.new()
		icon.texture = get_icon(kind, i)
		icon.position = Vector2(1, 1)
		icon.size = Vector2(16, 16)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		option.add_child(icon)
		player['options'].append(option)

	var button: Button = make_button('SELECT', 8)
	place(button, Vector2(x + 22, 172), Vector2(56, 15))
	button.pressed.connect(func() -> void: press_select(p))
	player['button'] = button
	return player

## Adds the control first and sizes it after: sized before entering the tree, a control works out
## its minimum size from the default theme (bigger font) and never shrinks back.
func place(control: Control, at: Vector2, size: Vector2, parent: Control = self) -> void:
	parent.add_child(control)
	control.position = at
	control.size = size

func make_label(text: String, font_size: int) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override('font_size', font_size)
	return label

func make_button(text: String, font_size: int) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override('font_size', font_size)
	button.add_theme_stylebox_override('normal', box_style(BLUE, BLUE, 3))
	button.add_theme_stylebox_override('hover', box_style(BLUE_HOVER, BLUE_HOVER, 3))
	button.add_theme_stylebox_override('pressed', box_style(BLUE_HOVER, Color.WHITE, 3))
	button.add_theme_stylebox_override('disabled', box_style(GREY, GREY, 3))
	return button
#endregion
