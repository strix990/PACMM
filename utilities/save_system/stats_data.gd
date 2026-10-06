class_name StatsData extends Resource
## All game stats data.

#region VARIABLES
## How many times has the game been booted?
@export var game_booted_count: int = 0
## How many ghosts have been eaten in total?
@export var ghosts_eaten: int = 0:
	set(pt):
		if pt < 0 or pt == ghosts_eaten:
			return
		ghosts_eaten = pt
		ghosts_eaten_changed.emit(pt)
## The highest score set.
@export var highscore: int = 0:
	set(h):
		if h < 0 or h == highscore:
			return
		highscore = h
		highscore_changed.emit(h)
## The score of the current or last game.
@export var score: int = 0:
	set(s):
		if s < 0 or s == score:
			return
		
		score = s
		score_changed.emit(s)
		
		if s > highscore:
			highscore = s

signal ghosts_eaten_changed(ghosts_eaten: int)
signal highscore_changed(highscore: int)
signal score_changed(score: int)
#endregion
