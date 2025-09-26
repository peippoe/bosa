extends Area3D





func _on_body_entered(body):
	var speed = body.velocity.length() + 15.0
	body.velocity = speed * -global_basis.z + Vector3.UP * 5.0
