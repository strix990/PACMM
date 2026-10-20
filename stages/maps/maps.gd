class_name Maps
## The playable mazes. Each map is a text file in this folder: 31 lines of 28 characters, one per
## tile, for grid rows 3 to 33 (rows 0-2 and 34-35 are the HUD).
##   #  wall          .  pellet          o  power pellet
##   -  ghost house door                 (space)  empty floor, or nothing outside the maze
## The ghost house (columns 10-17, rows 15-19) and Pac-Man's start (row 26, columns 12-15) must
## stay where they are in every map. A corridor reaching the left/right edge becomes a tunnel.
## Map files must also be listed in the export presets' include filter (stages/maps/*.txt).

const MAPS: Array[Dictionary] = [
	{'name': 'MAZE 1', 'file': 'res://stages/maps/maze_1.txt'},
	{'name': 'MAZE 2', 'file': 'res://stages/maps/maze_2.txt'},
	{'name': 'MAZE 3', 'file': 'res://stages/maps/maze_3.txt'},
	{'name': 'MAZE 4', 'file': 'res://stages/maps/maze_4.txt'},
]
const FIRST_ROW: int = 3
const PREVIEW_COLORS: Dictionary = {
	'#': Color('#2121de'),
	'-': Color('#ffb8de'),
	'.': Color('#5a4a48'),
	'o': Color('#ffb8ae'),
}

static var _rows: Dictionary = {}
static var _previews: Dictionary = {}

## The map's lines, top to bottom.
static func get_rows(index: int) -> PackedStringArray:
	if !_rows.has(index):
		var text: String = FileAccess.get_file_as_string(MAPS[index]['file'])
		_rows[index] = text.replace('\r', '').trim_suffix('\n').split('\n')
	return _rows[index]

## A tiny picture of the map (one pixel per tile) for the character select screen.
static func get_preview(index: int) -> Texture2D:
	if !_previews.has(index):
		var rows: PackedStringArray = get_rows(index)
		var image: Image = Image.create(28, rows.size(), false, Image.FORMAT_RGBA8)
		image.fill(Color.BLACK)
		for y in rows.size():
			for x in mini(rows[y].length(), 28):
				if PREVIEW_COLORS.has(rows[y][x]):
					image.set_pixel(x, y, PREVIEW_COLORS[rows[y][x]])
		_previews[index] = ImageTexture.create_from_image(image)
	return _previews[index]
