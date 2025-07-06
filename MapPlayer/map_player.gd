extends Node3D

func _ready():
	Playback.setup()
	Playback.playback_speed = 1.0

func _process(delta):
	%Timer.text = str(Playback.playhead).pad_decimals(2)
