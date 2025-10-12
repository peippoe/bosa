extends Area3D





func _on_body_entered(body):
	if body is not CharacterBody3D: return
	var speed = body.velocity.length() + 18.0
	body.velocity = speed * -global_basis.z.normalized()# + Vector3.UP * 5.0
