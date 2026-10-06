class_name RandomAudioPlayer2D extends AudioStreamPlayer2D

@export var audio_streams: Array[AudioStream] = []

func play_random_audio_and_await_finished(override_streams: Array[AudioStream] = []) -> void:
	if !audio_streams.is_empty():
		stream = audio_streams.pick_random()
	if !override_streams.is_empty():
		stream = override_streams.pick_random()
	pitch_scale = randf_range(0.8, 1.2)
	play()
	await finished
