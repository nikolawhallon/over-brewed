extends CharacterBody2D


const SPEED = 30.0
@export var direction = Vector2.ZERO
var target = null
var cafe_path = NodePath()
var spawn_area_path = NodePath()

enum State {
	VOID,
	COMMUTING,
	ENTERING,
	WAITING,
	LEAVING
}

@export var state = State.VOID
@export var desire = ""

func init(initial_global_position, initial_spawn_area_path, initial_target, initial_desire):
	global_position = initial_global_position
	spawn_area_path = initial_spawn_area_path
	target = initial_target
	desire = initial_desire
	state = State.COMMUTING

func get_opposite_spawn_area_random_position() -> Vector2:
	var arena = NodeUtils.get_first_ancestor_in_group_for_node(self, "Arena")
	var left_spawn_area = arena.get_node("LeftCustomerSpawnArea")
	var right_spawn_area = arena.get_node("RightCustomerSpawnArea")

	if spawn_area_path == left_spawn_area.get_path():
		return right_spawn_area.get_random_position()
	else:
		return left_spawn_area.get_random_position()

func _physics_process(_delta: float) -> void:
	if state != State.LEAVING and desire == "coffee":
		$Bubble.visible = true
		$Coffee.visible = true
		$Wine.visible = false
	elif state != State.LEAVING and desire == "wine":
		$Bubble.visible = true
		$Coffee.visible = false
		$Wine.visible = true
	else:
		$Bubble.visible = false
		$Coffee.visible = false
		$Wine.visible = false

	if state == State.WAITING:
		if $WaitTimer.is_stopped():
			$WaitTimer.start()
		$TimerProgress.visible = true
		var progress = (1.0 - $WaitTimer.time_left / $WaitTimer.wait_time) * 100
		$TimerProgress.value = progress
	else:
		$TimerProgress.visible = false

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

		if state == State.LEAVING:
			velocity = direction * SPEED * 2
		else:
			velocity = direction * SPEED
		move_and_slide()

		if global_position.distance_to(target) < 8:
			target = null
			$WaitTimer.wait_time = randi_range(30, 60)
			state = State.WAITING
	else:
		direction = Vector2.ZERO

func _on_area_2d_body_entered(body: Node2D) -> void:
	if not multiplayer.is_server():
		return

	if state == State.WAITING and body.is_in_group("Barista"):
		if body.holding == desire:
			body.holding = ""
			var cafe = get_node(cafe_path)
			cafe.customer_left.emit(desire)
			cafe.release_slot(self.get_path())
			target = get_opposite_spawn_area_random_position()
			state = State.LEAVING
			var arena = NodeUtils.get_first_ancestor_in_group_for_node(self, "Arena")
			for peer in NodeUtils.get_first_ancestor_in_group_for_node(self, "App").get_peer_ids_for_match(arena.match_id):
				if peer == 1:
					continue
				Sfx.announce_play_sfx.rpc_id(peer, "assets/sfx/sfx_served.wav")

			Sfx.announce_play_sfx("assets/sfx/sfx_served.wav")
	if state != State.LEAVING and body.is_in_group("Barista"):
		if body.holding == "newspaper":
			if state == State.WAITING:
				var cafe = get_node(cafe_path)
				cafe.customer_left.emit(false)
				cafe.release_slot(self.get_path())
			target = get_opposite_spawn_area_random_position()
			state = State.LEAVING
			var arena = NodeUtils.get_first_ancestor_in_group_for_node(self, "Arena")
			for peer in NodeUtils.get_first_ancestor_in_group_for_node(self, "App").get_peer_ids_for_match(arena.match_id):
				if peer == 1:
					continue
				Sfx.announce_play_sfx.rpc_id(peer, "assets/sfx/sfx_hit.wav")

			Sfx.announce_play_sfx("assets/sfx/sfx_hit.wav")

	if state == State.COMMUTING and body.is_in_group("Barista"):
		var arena = NodeUtils.get_first_ancestor_in_group_for_node(self, "Arena")
		if body.cafe == "left":
			var cafe = arena.get_node("LeftCafe")
			cafe_path = cafe.get_path()
			var new_target = cafe.get_slot(self.get_path())
			if new_target != null:
				target = new_target
				state = State.ENTERING
				for peer in NodeUtils.get_first_ancestor_in_group_for_node(self, "App").get_peer_ids_for_match(arena.match_id):
					if peer == 1:
						continue
					Sfx.announce_play_sfx.rpc_id(peer, "assets/sfx/sfx_invited.wav")

				Sfx.announce_play_sfx("assets/sfx/sfx_invited.wav")
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
		cafe.customer_left.emit(false)
		cafe.release_slot(self.get_path())
	target = get_opposite_spawn_area_random_position()
	state = State.LEAVING
