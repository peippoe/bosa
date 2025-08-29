extends Control

func spawn_floating_text(text : String):
	var new_floating_text = Label.new()
	self.add_child(new_floating_text)
	
	new_floating_text.text = text
	
	var tween = get_tree().create_tween()
	tween.tween_property(new_floating_text, "position", new_floating_text.position - Vector2(0, 10), 2)
	tween.set_parallel(true)
	tween.tween_property(new_floating_text, "modulate", Color(1, 1, 1, 0), 2)
	tween.set_parallel(false)
	tween.tween_callback(new_floating_text.queue_free)
	
	#await get_tree().create_timer(1).timeout
	#
	#new_floating_text.queue_free()
