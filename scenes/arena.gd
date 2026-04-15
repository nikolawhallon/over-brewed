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
		if multiplayer.is_server():
			for peer in NodeUtils.get_first_ancestor_in_group_for_node(self, "App").get_peer_ids_for_match(match_id):
				if DisplayServer.get_name() == "headless" and peer == 1:
					continue
				if len(NodeUtils.get_nodes_in_group_for_node(self, "Barista")) % 2 == 0:
					var barista = load("res://scenes/barista.tscn").instantiate()
					barista.init(peer, "left", $LeftCafe.position)
					$Replicated.add_child(barista, true)
				else:
					var barista = load("res://scenes/barista.tscn").instantiate()
					barista.init(peer, "right", $RightCafe.position)
					$Replicated.add_child(barista, true)

	if Input.is_action_just_pressed("leave"):
		emit_signal("leave_requested")

	if not multiplayer.is_server():
		return

@rpc("any_peer", "reliable")
func announce_start_game(_random_seed, _peers):
	state = State.STARTING

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
