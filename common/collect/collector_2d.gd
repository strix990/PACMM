class_name Collector2D
extends Area2D
## A simple component to make anything a collector.

enum AudioOrder {
	RANDOM,
	DESCENDING,
	ASCENDING
}

#region VARIABLES
## The identifiers for the collectables this collector can collect.
@export var audio_order: AudioOrder = AudioOrder.RANDOM
@export var collectable_identifiers: Array[String] = []
@export var disabled: bool = false

## The collision shape for the collector.
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
## The audio stream player respoinsible to play the specific audio for a collected collectable.
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D
#endregion

#region SIGNALS
signal collected(collectable: Collectable2D)
#endregion

#region FUNCTIONS
func _ready() -> void:
	area_entered.connect(func(area: Area2D):
		if disabled:
			return
		if area is Collectable2D:
			if area.identifier in collectable_identifiers and !area.disabled:
				area.collect()
				play_audio(area)
				collected.emit(area)
	)

## Used to play the audio fetched from the collectable when collected.
func play_audio(collectable: Collectable2D) -> void:
	if AudioOrder.RANDOM:
		audio_stream_player_2d.stream = collectable.get_audio()
	elif AudioOrder.DESCENDING:
		audio_stream_player_2d.stream = collectable.get_next_audio(audio_stream_player_2d.stream)
	if audio_stream_player_2d.stream != null:
		audio_stream_player_2d.play()
#endregion
