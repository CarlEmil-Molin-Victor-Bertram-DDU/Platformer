extends Node2D

@onready var audio_player = $AudioStreamPlayer
@onready var timer = $Timer

func _ready():
	# Use Callable for the signal connection
	timer.connect("timeout", Callable(self, "_on_timer_timeout"))
	play_audio()

func _on_audio_stream_player_finished() -> void:
	timer.start()
	
func play_audio():
	audio_player.play()

func _on_timer_timeout():
	# When the timer times out, play the audio again
	play_audio()


