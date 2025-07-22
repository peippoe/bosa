extends RigidBody3D

var pop_time := 0.0

func _ready():
	pass
	#await get_tree().create_timer(0.5).timeout
	#queue_free()

func pop():
	print("POP TIMING: %d" % Utility.get_pop_timing(pop_time))
	$AnimationPlayer.play("pop")
	freeze = true
	$waterbloon.visible = false
	$CollisionShape3D.disabled = true
	await $AnimationPlayer.animation_finished
	queue_free()
