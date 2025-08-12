extends Node3D



func _ready():
	Playback.setup()

func _process(delta):
	%Timer.text = str(Playback.playhead).pad_decimals(2)
