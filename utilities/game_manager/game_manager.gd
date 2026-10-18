class_name GameManager extends Node

const LIVES_MIN: int = 0
const LIVES_MAX: int = 8
const LIVES_START: int = 3
## Versus balance: Pac-Man starts with fewer lives against a human ghost.
const VERSUS_LIVES_START: int = 2
## Pellets (incl. power pellets) in a level; eating them all clears the level.
const PELLETS_PER_LEVEL: int = 244
## Versus is a single maze played with this level's speeds, frightened time and ghost schedule.
const VERSUS_LEVEL: int = 5

enum GhostMode {
	CHASE,
	SCATTER,
}
enum Mode {
	NONE,
	PLAYING,
	CLEAR,
	DEATH,
	WAIT,
	OVER,
}
enum ResetType {
	GAME,
	LEVEL,
	LIFE,
}
enum GameType {
	SINGLE,
	## two Pac-Men against the AI ghosts, sharing score and lives
	COOP,
	## Pac-Man against a single player-controlled ghost
	VERSUS,
}

## Set by the menu before a new game starts.
var game_type: GameType = GameType.SINGLE
## Who won the last versus game: 'pacman' or 'ghost' (empty otherwise).
var winner: String = ''

var pellets_eaten: int = 0:
	set(mc):
		if pellets_eaten < 0 or mc == pellets_eaten:
			return
		pellets_eaten = mc
		if mc == PELLETS_PER_LEVEL:
			if game_type == GameType.VERSUS:
				winner = 'pacman'
				mode = Mode.OVER
				return
			GM.mode = GM.Mode.CLEAR
			await get_tree().create_timer(1.0).timeout
			level += 1
var ghosts_frightened: int = 0:
	set(pf):
		if pf < 0 or pf == ghosts_frightened:
			return
		ghosts_frightened = pf
		ghosts_frightened_changed.emit(pf)
var ghost_mode: GhostMode = GhostMode.SCATTER:
	set(pm):
		if !GhostMode.values().has(pm) or ghost_mode == pm:
			return
		ghost_mode = pm
		ghost_mode_changed.emit(pm)
var ghosts_returning: int = 0:
	set(pr):
		if pr < 0 or pr == ghosts_returning:
			return
		ghosts_returning = pr
		ghosts_returning_changed.emit(pr)
var level: int = 1:
	set(l):
		if l < 1 or l == level:
			return
		level = l
		level_changed.emit(l)
		if mode == Mode.NONE:
			return
		
		reset.emit(ResetType.LEVEL)
		await get_tree().create_timer(1.0).timeout
		mode = Mode.PLAYING
var lives: int = 3:
	set(l):
		if l < LIVES_MIN or l > LIVES_MAX or l == lives:
			return
		lives = l
		lives_changed.emit(l)
		if mode == Mode.NONE:
			return
		
		if l > LIVES_MIN:
			reset.emit(ResetType.LIFE)
			await get_tree().create_timer(1.0).timeout
			mode = Mode.PLAYING
		else:
			if game_type == GameType.VERSUS:
				winner = 'ghost'
			mode = Mode.OVER
var mode: Mode = Mode.NONE:
	set(m):
		if !Mode.values().has(m) or m == mode:
			return
		mode = m
		mode_changed.emit(m)
var power_pellets_eaten: int = 0

signal ghosts_frightened_changed(amount: int)
signal ghost_mode_changed(ghost_mode: GhostMode)
signal ghosts_returning_changed(amount: int)
signal frighten_ghosts(time: float)
signal level_changed(level: int)
signal lives_changed(lives: int)
signal mode_changed(mode: Mode)
signal reset(type: ResetType)

func _ready() -> void:
	reset.connect(on_reset)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed('dev_frighten_ghosts'):
		frighten_ghosts.emit(PowerPellet.get_time())
	elif event.is_action_pressed('dev_frighten_ghosts_default'):
		frighten_ghosts.emit(10.0)
	if event.is_action_pressed('dev_lives_decrease'):
		lives -= 1
	elif event.is_action_pressed('dev_lives_increase'):
		lives += 1
	if event.is_action_pressed('dev_mode_none'):
		mode = Mode.NONE
	if event.is_action_pressed('dev_mode_playing'):
		mode = Mode.PLAYING
	if event.is_action_pressed('dev_mode_over'):
		mode = Mode.OVER
	if event.is_action_pressed('dev_reset_level'):
		reset.emit(ResetType.LEVEL)
	elif event.is_action_pressed('dev_reset_game'):
		reset.emit(ResetType.GAME)

func on_reset(type: ResetType) -> void:
	SS.save_stats()
	if type == ResetType.LIFE:
		return
	pellets_eaten = 0
	mode = Mode.NONE
	power_pellets_eaten = 0
	if type == ResetType.GAME:
		winner = ''
		level = VERSUS_LEVEL if game_type == GameType.VERSUS else 1
		lives = VERSUS_LIVES_START if game_type == GameType.VERSUS else LIVES_START
		SS.stats.score = 0
