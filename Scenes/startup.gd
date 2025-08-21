extends Control

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		GameManager.change_scene("res://Scenes/main_menu.tscn")
