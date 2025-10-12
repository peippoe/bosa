extends Node3D


var playtest_ghost_timer

func _ready():
	Playback.setup()
	
	if GameManager.editor_playtest:
		playtest_ghost_timer = Timer.new()
		self.add_child(playtest_ghost_timer)
		playtest_ghost_timer.wait_time = 0.1
		playtest_ghost_timer.timeout.connect(playtest_ghost)
		playtest_ghost_timer.start()

func _process(delta):
	%Timer.text = str(Playback.playhead).pad_decimals(2)

func playtest_ghost():
	var player = get_tree().get_first_node_in_group("player")
	var pos = player.global_position
	GameManager.playtest_ghost_positions.append(pos)
	#print("POSIT POSITEDDDDDDDDDDDDDDDDDDDDDDDDD %d" % GameManager.playtest_ghost_positions.size())
