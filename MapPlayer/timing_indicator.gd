extends Control

const TIMING_INDICATOR_POINT = preload("res://MapPlayer/timing_indicator_point.tscn")

func _ready():
	var max_value = Settings.POP_TIMING_WINDOWS[3]
	
	%Great.size.x = Settings.POP_TIMING_WINDOWS[2] / max_value * self.size.x
	%Great.position.x = (%Ok.size.x - %Great.size.x) / 2.0
	
	%Sick.size.x = Settings.POP_TIMING_WINDOWS[1] / max_value * self.size.x
	%Sick.position.x = (%Ok.size.x - %Sick.size.x) / 2.0


func display_point_on_indicator(timing):
	#if absf(timing) > Settings.POP_TIMING_WINDOWS[3]: push_error("MISSED TOO BADLY TO SHOW"); return
	
	var new_point = TIMING_INDICATOR_POINT.instantiate()
	add_child(new_point)
	new_point.position.x = remap(timing, -Settings.POP_TIMING_WINDOWS[3], Settings.POP_TIMING_WINDOWS[3], 0.0, self.size.x)
	
	#print("POINT DISPLAYED AT %f" % new_point.position.x)
