extends Node3D

var highlighted


func _ready():
	$PlayPanel.hide()
	await get_tree().process_frame
	$Mainmenuu.play()
	#await get_tree().create_timer(.5).timeout
	await get_tree().create_timer(.05).timeout
	$AnimationPlayer.play("loop")
	
	$PlayPanel/Control/HBoxContainer/VBoxContainer/Button2.pressed.connect(func a(): GameManager.play_map("res://Scenes/Beatmaps/tutorial2.json"))
	$PlayPanel/Control/HBoxContainer/VBoxContainer/Button.pressed.connect(func a(): GameManager.play_map("res://Scenes/Beatmaps/test_level.json"))

func raycast_result(event):
	var from = %Camera3D.project_ray_origin(event.position)
	var to = from + %Camera3D.project_ray_normal(event.position) * 100
	
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = true
	var result = space_state.intersect_ray(query)
	
	return result

func _input(event):
	if event is InputEventMouseMotion:
		var result = raycast_result(event)
		
		
		var r = null
		if result: r = result.collider
		
		if r == highlighted: return
		
		
		if highlighted: highlighted.position.y -= 0.1; highlighted.scale = Vector3.ONE
		
		highlighted = r
		if r: r.position.y += 0.1; r.scale = Vector3.ONE * 1.2
	
	
	if event is InputEventMouseButton and event.pressed and event.button_index == 1:
		if not highlighted: return
		match highlighted.name:
			"Play":
				$PlayPanel.show()
				$PlayPanel/ColorRect.show()
				$PlayPanel/ColorRect.modulate = Color(1,1,1,0)
				$PlayPanel/Control.modulate = Color(1,1,1,0)
				var tween = get_tree().create_tween().set_trans(Tween.TRANS_SINE)
				tween.tween_property(%Camera3D, "rotation", Vector3(0, -PI/2, 0), .3)
				tween.set_parallel(true)
				tween.tween_property($PlayPanel/ColorRect, "modulate", Color(1,1,1,1), .1)
				tween.set_parallel(false)
				tween.tween_property($PlayPanel/ColorRect, "modulate", Color(1,1,1,0), .2)
				tween.set_parallel(true)
				tween.tween_property($PlayPanel/Control, "modulate", Color(1,1,1,1), .1)
				
			"Back":
				var tween = get_tree().create_tween().set_trans(Tween.TRANS_SINE)
				tween.tween_property(%Camera3D, "rotation", Vector3(0, 0, 0), .3)
				tween.set_parallel(true)
				tween.tween_property($PlayPanel/ColorRect, "modulate", Color(1,1,1,1), .1)
				tween.set_parallel(false)
				tween.tween_property($PlayPanel/ColorRect, "modulate", Color(1,1,1,0), .2)
				tween.set_parallel(true)
				tween.tween_callback($PlayPanel.hide)
				
			"MapEditor": GameManager.change_scene("res://MapEditor/Parts/map_editor.tscn")
			"Exit": get_tree().quit()
			"Test": GameManager.change_scene("res://Scenes/test_scene.tscn")
