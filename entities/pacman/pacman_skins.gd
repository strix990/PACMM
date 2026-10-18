class_name PacmanSkins
## The selectable Pac-Man skins. Every in-game sheet uses the layout of entities/pacman/pacman.png:
## 16x16 cells, 0 lives icon | 1 closed | 2,3 right | 4,5 left | 6,7 up | 8,9 down | 10.. death.
## Custom skins come from Aseprite files via tools/import_skins.py, which also writes a full-size
## (32x32) preview strip (closed, half, wide) for the character select screen.

const CELL: int = 16
const FIRST_DEATH_CELL: int = 10
const SKINS: Array[Dictionary] = [
	{'name': 'CLASSIC', 'sheet': 'res://entities/pacman/pacman.png', 'preview': ''},
	{'name': 'STYLISH PAC', 'sheet': 'res://entities/pacman/skins/stylish.png', 'preview': 'res://entities/pacman/skins/stylish_preview.png'},
	{'name': 'HALLOPAC', 'sheet': 'res://entities/pacman/skins/hallopac.png', 'preview': 'res://entities/pacman/skins/hallopac_preview.png'},
	{'name': 'SHARKPAC', 'sheet': 'res://entities/pacman/skins/sharkpac.png', 'preview': 'res://entities/pacman/skins/sharkpac_preview.png'},
	{'name': 'SPIDEYPAC', 'sheet': 'res://entities/pacman/skins/spideypac.png', 'preview': 'res://entities/pacman/skins/spideypac_preview.png'},
]

static func get_sheet(skin: int) -> Texture2D:
	return load(SKINS[skin]['sheet'])

static func get_cell(texture: Texture2D, cell: int, size: int = CELL) -> AtlasTexture:
	var atlas: AtlasTexture = AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = Rect2(cell * size, 0, size, size)
	return atlas

## Small icon: facing right, mouth half open.
static func get_icon(skin: int) -> AtlasTexture:
	return get_cell(get_sheet(skin), 2)

static func get_lives_icon(skin: int) -> AtlasTexture:
	return get_cell(get_sheet(skin), 0)

## Closed, half and wide open, facing right: full size for custom skins, 16px for classic.
static func get_preview_frames(skin: int) -> Array[Texture2D]:
	var frames: Array[Texture2D] = []
	var preview: String = SKINS[skin]['preview']
	if preview.is_empty():
		var sheet: Texture2D = get_sheet(skin)
		for cell in [1, 2, 3]:
			frames.append(get_cell(sheet, cell))
	else:
		var texture: Texture2D = load(preview)
		var size: int = texture.get_height()
		for cell in 3:
			frames.append(get_cell(texture, cell, size))
	return frames

## The animations Pac-Man's AnimatedSprite2D plays, built from the skin's sheet.
static func build_sprite_frames(skin: int) -> SpriteFrames:
	var sheet: Texture2D = get_sheet(skin)
	var frames: SpriteFrames = SpriteFrames.new()
	frames.set_animation_speed('default', 10.0)
	frames.add_frame('default', get_cell(sheet, 1))
	var first_cell: Dictionary = {'right': 2, 'left': 4, 'up': 6, 'down': 8}
	for direction: String in first_cell:
		var half: int = first_cell[direction]
		frames.add_animation(direction)
		frames.set_animation_speed(direction, 16.0)
		for cell in [1, half, half + 1, half]:
			frames.add_frame(direction, get_cell(sheet, cell))
	frames.add_animation('death')
	frames.set_animation_speed('death', 7.5)
	frames.set_animation_loop('death', false)
	for cell in range(FIRST_DEATH_CELL, sheet.get_width() / CELL):
		frames.add_frame('death', get_cell(sheet, cell))
	frames.add_frame('death', null, 4.0)
	return frames
