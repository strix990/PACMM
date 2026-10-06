class_name SaveSystem extends Node
## The global save system.
##
## A simple global system for saving data.[br]
## This should be added as a global script named [param SaveSystem].[br]
## It's then reachable by all other components under that name.

#region CONSTANTS
## Name of the config file.
const CONFIG_FILE_PATH: String = 'user://config_data.tres'
## Name of the stats file.
const STATS_FILE_PATH: String = 'user://stats_data.tres'
#endregion

#region VARIABLES
## In-game configs data.
var config: ConfigData = ConfigData.new()
## In-game stats data.
var stats: StatsData = StatsData.new()
#endregion

#region FUNCTIONS
func _ready() -> void:
	load_stats()
	load_config()
	
	stats.game_booted_count += 1
	save_stats()

func _notification(what):
	# make sure to always save before closing down the game
	# NOTIFICATION_WM_GO_BACK_REQUEST is used for an android back-button
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_WM_GO_BACK_REQUEST:
		save_stats()
		get_tree().quit()

## Saves the stats data.
func save_stats():
	ResourceSaver.save(stats, STATS_FILE_PATH)

## Saves the config data.
func save_config():
	ResourceSaver.save(config, CONFIG_FILE_PATH)

## Loads the stats data.
func load_stats():
	if ResourceLoader.exists(STATS_FILE_PATH):
		stats = ResourceLoader.load(STATS_FILE_PATH).duplicate(true)

## Loads the config data.
func load_config():
	if ResourceLoader.exists(CONFIG_FILE_PATH):
		config = ResourceLoader.load(CONFIG_FILE_PATH).duplicate(true)
#endregion
