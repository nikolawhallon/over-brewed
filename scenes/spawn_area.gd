extends Area2D


func get_random_position() -> Vector2:
	var collision_shape = $CollisionShape2D
	var shape = collision_shape.shape as RectangleShape2D
	var size = shape.size

	var random_x = randf_range(-size.x / 2, size.x / 2)
	var random_y = randf_range(-size.y / 2, size.y / 2)

	return global_position + Vector2(random_x, random_y)

func _on_body_entered(body: Node2D) -> void:
	if not multiplayer.is_server():
		return

	if body.is_in_group("Customer") or body.is_in_group("Mailman"):
		if body.spawn_area_path != get_path():
			body.call_deferred("queue_free")
