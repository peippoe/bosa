extends AudioStreamPlayer

var prev_visible_chars := 0


func _process(delta):
	if get_parent().visible_characters == prev_visible_chars: return
	if get_parent().get_parsed_text()[get_parent().visible_characters-1] == " ": return
	
	var temp = prev_visible_chars
	prev_visible_chars = get_parent().visible_characters
	if get_parent().visible_characters < temp and get_parent().visible_characters != -1: return
	if temp == -1: return
	self.pitch_scale = randf_range(0.9, 1.1)
	play()
