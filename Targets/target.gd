extends RigidBody3D

var pop_time := 0.0

func _ready():
	pass
	#await get_tree().create_timer(0.5).timeout
	#queue_free()

func pop():
	$AnimationPlayer.play("pop")
	freeze = true
	$waterbloon.hide()
	$Ring2.hide()
	$CollisionShape3D.disabled = true
	await $AnimationPlayer.animation_finished
	queue_free()
