extends Control

@onready var time_label = %TimeLabel
@onready var timeline = %Timeline
@onready var scene = %Scene


func _on_spawn_target_pressed():
	var a = Vector3(1, 1, 1)
	
	UtilityFunctions.spawn_entity("res://Editor/gizmo_target.tscn", scene, a, 5)




func _on_timeline_scrolling():
	var new_step = 0.01
	if Input.is_action_pressed("ctrl"):
		new_step = 1
	elif Input.is_action_pressed("shift"):
		new_step = 0.1
	
	timeline.step = new_step
	
	
	time_label.text = str(timeline.value)
