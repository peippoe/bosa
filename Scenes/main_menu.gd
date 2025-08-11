extends Node3D

var highlighted


func _ready():
	await get_tree().process_frame
	$Mainmenuu.play()
	#await get_tree().create_timer(.5).timeout
	await get_tree().create_timer(.05).timeout
	$AnimationPlayer.play("loop")

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
			"Play": GameManager.change_scene("res://Scenes/Levels/level_1.tscn")
			"MapEditor": GameManager.change_scene("res://MapEditor/Parts/map_editor.tscn")
			"Exit": get_tree().quit()
			"Test": GameManager.change_scene("res://Scenes/test_scene.tscn")
