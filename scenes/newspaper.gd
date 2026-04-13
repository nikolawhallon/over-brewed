extends Area2D


func init(initial_global_position):
	global_position = initial_global_position

func _on_body_entered(body: Node2D) -> void:
	if not multiplayer.is_server():
		return

	if body.is_in_group("Barista"):
		if body.holding == "":
			body.holding = "newspaper"
			queue_free()
