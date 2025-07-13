extends Control





# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var player = $".."
	var vel = player.velocity
	var debug_text = "vel: %.2s \n" % str(vel)
	debug_text += "sliding: %s" % player.sliding
	%Label.text = debug_text
	
