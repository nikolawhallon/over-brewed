extends CharacterBody2D


const SPEED = 50.0
@export var direction = Vector2.ZERO
var target = null
var spawn_area_path = NodePath()

func init(initial_global_position, initial_spawn_area_path, initial_target):
	global_position = initial_global_position
	spawn_area_path = initial_spawn_area_path
	target = initial_target

func _physics_process(_delta: float) -> void:
	if not multiplayer.is_server():
		return

	if target != null:
		direction = (target - global_position).normalized()

		velocity = direction * SPEED
		move_and_slide()
	else:
		direction = Vector2.ZERO

	if global_position.distance_to(Vector2.ZERO) > 480:
		print("freeing mailman")
		call_deferred("queue_free")
