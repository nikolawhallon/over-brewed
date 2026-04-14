extends Node2D


signal leave_requested

var match_id = null

enum State {
	VOID,
	STARTING,
	PLAYING,
	GAME_OVER
}

var state = State.VOID
var left_score = 0
var right_score = 0

func _process(_delta: float) -> void:
	if state == State.STARTING:
		state = State.PLAYING

	if Input.is_action_just_pressed("leave"):
		emit_signal("leave_requested")

	if not multiplayer.is_server():
		return

func _input(event):
	if event is InputEventJoypadButton:
		for barista in NodeUtils.get_nodes_in_group_for_node(self, "Barista"):
			if barista.peer_id == multiplayer.get_unique_id():
				return

		request_spawn_barista.rpc_id(1)

	if event is InputEventKey and event.is_pressed():
		if event.keycode == KEY_SPACE or event.keycode == KEY_UP or event.keycode == KEY_DOWN or event.keycode == KEY_LEFT or event.keycode == KEY_RIGHT:
			for barista in NodeUtils.get_nodes_in_group_for_node(self, "Barista"):
				if barista.peer_id == multiplayer.get_unique_id():
					return

			request_spawn_barista.rpc_id(1)

@rpc("any_peer", "reliable")
func announce_start_game(_random_seed, _peers):
	state = State.STARTING

@rpc("any_peer", "call_local", "reliable")
func request_spawn_barista():
	var cafe = "left"
	for barista in NodeUtils.get_nodes_in_group_for_node(self, "Barista"):
		if barista.cafe == "left":
			cafe = "right"

	var barista = load("res://scenes/barista.tscn").instantiate()
	barista.init(multiplayer.get_remote_sender_id(), cafe, Vector2.ZERO)
	$Replicated.add_child(barista, true)

@rpc("authority", "reliable")
func announce_update_left_score(new_score: int) -> void:
	left_score = new_score
	$CanvasLayer/LeftContainer/LeftScore.text = "LEFT: %d" % left_score

@rpc("authority", "reliable")
func announce_update_right_score(new_score: int) -> void:
	right_score = new_score
	$CanvasLayer/RightContainer/RightScore.text = "RIGHT: %d" % right_score

func _on_customer_timer_timeout() -> void:
	if not multiplayer.is_server():
		return

	var customer = load("res://scenes/customer.tscn").instantiate()
	var desire = "coffee"
	if randf() > 0.5:
		desire = "wine"
	customer.init(Vector2(-320, 96), Vector2(640, 96), desire)
	$Replicated.add_child(customer, true)

func _on_left_cafe_customer_left(served) -> void:
	if not multiplayer.is_server():
		return

	if not served:
		return

	if served == "coffee":
		left_score += 1
	elif served == "wine":
		left_score += 2
	for peer in NodeUtils.get_first_ancestor_in_group_for_node(self, "App").get_peer_ids_for_match(match_id):
		if peer == 1:
			continue
		announce_update_left_score.rpc_id(peer, left_score)

	announce_update_left_score(left_score)

func _on_right_cafe_customer_left(served) -> void:
	if not multiplayer.is_server():
		return

	if not served:
		return

	if served == "coffee":
		right_score += 1
	elif served == "wine":
		right_score += 2
	for peer in NodeUtils.get_first_ancestor_in_group_for_node(self, "App").get_peer_ids_for_match(match_id):
		if peer == 1:
			continue
		announce_update_right_score.rpc_id(peer, right_score)

	announce_update_right_score(right_score)

func _on_power_up_timer_timeout() -> void:
	if not multiplayer.is_server():
		return

	var power_ups = NodeUtils.get_nodes_in_group_for_node(self, "PowerUp")
	
	if len(power_ups) > 0:
		return

	var mailman = load("res://scenes/mailman.tscn").instantiate()
	mailman.init(Vector2(-320, -104), Vector2(640, -104))
	$Replicated.add_child(mailman, true)
