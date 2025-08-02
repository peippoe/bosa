extends RigidBody3D

var pop_time := 0.0

func _ready():
	var mat1 = $ShrinkingRing.get_active_material(0).duplicate()
	$ShrinkingRing.set_surface_override_material(0, mat1)
	var mat2 = $ConstantRing.get_active_material(0).duplicate()
	$ConstantRing.set_surface_override_material(0, mat2)
	
	$AnimationPlayer.play("fadein")


func pop():
	$AnimationPlayer.play("pop")
	freeze = true
	$waterbloon.hide()
	$Ring2.hide()
	$ShrinkingRing.hide()
	$ConstantRing.hide()
	$CollisionShape3D.disabled = true
	await $AnimationPlayer.animation_finished
	queue_free()
