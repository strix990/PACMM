extends SceneTree
## Draws the arcade-style "PACMANIA" title logo into res://ui/game/logo.png.
## Run from the project folder:  godot --headless --path . -s tools/make_logo.gd
## Chunky pixel letters (7x7 grid with double-width vertical strokes, scaled up) in Pac-Man's yellow,
## with a dark outline.

const TEXT: String = 'PACMANIA'
const GLYPH_W: int = 7
const GLYPH_H: int = 7
const SCALE: Vector2i = Vector2i(3, 4) # screen pixels per letter-grid cell (x, y)
const LETTER_GAP: int = 4
const OUTLINE: int = 2
const OUTPUT: String = 'res://ui/game/logo.png'

## The same yellow as the Pac-Man sprite (entities/pacman/pacman.png).
const LETTER_COLOR: Color = Color('#ffff00')
const OUTLINE_COLOR: Color = Color('#160a33')

const GLYPHS: Dictionary = {
	'P': ['1111110', '1100011', '1100011', '1111110', '1100000', '1100000', '1100000'],
	'A': ['0111110', '1100011', '1100011', '1111111', '1100011', '1100011', '1100011'],
	'C': ['0111111', '1100000', '1100000', '1100000', '1100000', '1100000', '0111111'],
	'M': ['1100011', '1110111', '1111111', '1101011', '1100011', '1100011', '1100011'],
	'N': ['1100011', '1110011', '1111011', '1101111', '1100111', '1100011', '1100011'],
	'I': ['1111110', '0011000', '0011000', '0011000', '0011000', '0011000', '1111110'],
}

func _initialize() -> void:
	var cols: int = GLYPH_W * SCALE.x
	var rows: int = GLYPH_H * SCALE.y
	var text_w: int = TEXT.length() * cols + (TEXT.length() - 1) * LETTER_GAP
	var pad: int = OUTLINE
	var w: int = text_w + 2 * pad
	var h: int = rows + 2 * pad

	# letter mask in image coordinates
	var mask: Dictionary = {}
	for i in TEXT.length():
		var glyph: Array = GLYPHS[TEXT[i]]
		var x0: int = pad + i * (cols + LETTER_GAP)
		for gy in GLYPH_H:
			for gx in GLYPH_W:
				if glyph[gy][gx] == '1':
					for sy in SCALE.y:
						for sx in SCALE.x:
							mask[Vector2i(x0 + gx * SCALE.x + sx, pad + gy * SCALE.y + sy)] = true

	# outline: everything within OUTLINE pixels of a letter
	var outlined: Dictionary = {}
	for p: Vector2i in mask:
		for dy in range(-OUTLINE, OUTLINE + 1):
			for dx in range(-OUTLINE, OUTLINE + 1):
				outlined[p + Vector2i(dx, dy)] = true

	var img: Image = Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for p: Vector2i in outlined:
		put(img, p, OUTLINE_COLOR)
	for p: Vector2i in mask:
		put(img, p, LETTER_COLOR)

	img.save_png(ProjectSettings.globalize_path(OUTPUT))
	print('wrote %s (%dx%d)' % [OUTPUT, w, h])
	quit()

func put(img: Image, p: Vector2i, color: Color) -> void:
	if p.x >= 0 and p.y >= 0 and p.x < img.get_width() and p.y < img.get_height():
		img.set_pixelv(p, color)
