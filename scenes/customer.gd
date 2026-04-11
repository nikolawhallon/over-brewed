extends CharacterBody2D


const SPEED = 50.0
@export var direction = Vector2.ZERO
var target = null
var cafe_path = NodePath()

enum State {
	VOID,
	COMMUTING,
	ENTERING,
	WAITING,
	LEAVING
}

var state = State.VOID

func init(initial_global_position, initial_target):
	global_position = initial_global_position
	target = initial_target
	state = State.COMMUTING

func _physics_process(_delta: float) -> void:
	if direction != Vector2.ZERO:
		$AnimatedSprite2D.play("move")
	else:
		$AnimatedSprite2D.play("idle")

	if direction.x < 0.0:
		$AnimatedSprite2D.flip_h = true
	elif direction.x > 0.0:
		$AnimatedSprite2D.flip_h = false

	if not multiplayer.is_server():
		return

	if target != null:
		direction = (target - global_position).normalized()

		velocity = direction * SPEED
		move_and_slide()

		if global_position.distance_to(target) < 8:
			target = null
			$WaitTimer.start()
			state = State.WAITING
	else:
		direction = Vector2.ZERO

	if global_position.distance_to(Vector2.ZERO) > 320:
		print("freeing customer")
		queue_free()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if not multiplayer.is_server():
		return

	if state != State.COMMUTING:
		return

	if body.is_in_group("Barista"):
		var arena = NodeUtils.get_first_ancestor_in_group_for_node(self, "Arena")
		if body.cafe == "left":
			var cafe = arena.get_node("LeftCafe")
			cafe_path = cafe.get_path()
			var new_target = cafe.get_slot(self.get_path())
			if new_target != null:
				target = new_target
				state = State.ENTERING
		elif body.cafe == "right":
			var cafe = arena.get_node("RightCafe")
			cafe_path = cafe.get_path()
			var new_target = cafe.get_slot(self.get_path())
			if new_target != null:
				target = new_target
				state = State.ENTERING

func _on_wait_timer_timeout() -> void:
	if not multiplayer.is_server():
		return

	if not cafe_path.is_empty():
		var cafe = get_node(cafe_path)
		cafe.customer_served()
		cafe.release_slot(self.get_path())

	target = Vector2(640, 0)
	state = State.LEAVING
