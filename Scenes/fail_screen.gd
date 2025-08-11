extends Control


func _ready():
	%Retry.pressed.connect(
		func retry():
			GameManager.change_scene(get_tree().current_scene.scene_file_path)
	)
	
	%MainMenu.pressed.connect(
		func main_menu():
			GameManager.change_scene("res://Scenes/main_menu.tscn")
	)
