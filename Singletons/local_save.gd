extends Node

var save : Dictionary = {
	"scores_classic": {},
	"scores_timetrial": {},
	"playtime": 0.0,
}


func _ready():
	if not FileAccess.file_exists("user://save.json"):
		_save()
	else:
		_load()
	
	var timer = Timer.new()
	self.add_child(timer)
	timer.one_shot = false
	timer.wait_time = 1.0
	timer.start()
	timer.timeout.connect(func a():
		if GameManager.in_editor: return
		if get_tree().current_scene and get_tree().current_scene.name == "MainMenu": return
		save["playtime"] += 1
	)

func _exit_tree():
	_save()

func _save():
	var file = FileAccess.open("user://save.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save, "\t"))
		file.close()
	else:
		push_error("Failed to write to JSON")

func _load():
	var file = FileAccess.open("user://save.json", FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed: push_error("PARSE FAILED"); return
	
	save = parsed
