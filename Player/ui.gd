extends Control





# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var vel = $"..".velocity
	%Label.text = "vel: %.2f" % (vel.length() - abs(vel.y))
