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
var time_left = 180

func _ready():
	if not multiplayer.is_server():
		return

	for peer in NodeUtils.get_first_ancestor_in_group_for_node(self, "App").get_peer_ids_for_match(match_id):
		if peer == 1:
			continue
		announce_update_time_left.rpc_id(peer, time_left)

	announce_update_time_left(time_left)

func _process(_delta: float) -> void:
	if state == State.STARTING:
		state = State.PLAYING
		if multiplayer.is_server():
			var skin_types = [1, 2, 3, 4]
			skin_types.shuffle()

			for peer in NodeUtils.get_first_ancestor_in_group_for_node(self, "App").get_peer_ids_for_match(match_id):
				if DisplayServer.get_name() == "headless" and peer == 1:
					continue
				var num_baristas = len(NodeUtils.get_nodes_in_group_for_node(self, "Barista"))
				var skin_type = skin_types[num_baristas % len(skin_types)]
				print(skin_type)

				if num_baristas % 2 == 0:
					var barista = load("res://scenes/barista.tscn").instantiate()
					barista.init(peer, "left", $LeftCafe.position + Vector2(0, - num_baristas / 2 * 16), skin_type)
					$Replicated.add_child(barista, true)
				else:
					var barista = load("res://scenes/barista.tscn").instantiate()
					barista.init(peer, "right", $RightCafe.position + Vector2(0, - num_baristas / 2 * 16), skin_type)
					$Replicated.add_child(barista, true)

	if Input.is_action_just_pressed("leave") and state == State.GAME_OVER:
		print(state)
		$CanvasLayer/LobbyButtonContainer/LobbyButton.pressed.emit()

	if not multiplayer.is_server():
		return

@rpc("any_peer", "reliable")
func announce_start_game(_random_seed, _peers):
	state = State.STARTING

@rpc("authority", "reliable")
func announce_update_left_score(new_score: int) -> void:
	left_score = new_score
	$CanvasLayer/LeftContainer/LeftScore.text = "LEFT: %d" % left_score
	$CanvasLayer/TotalContainer/TotalScore.text = "TOTAL: %d" % (left_score + right_score)

@rpc("authority", "reliable")
func announce_update_right_score(new_score: int) -> void:
	right_score = new_score
	$CanvasLayer/RightContainer/RightScore.text = "RIGHT: %d" % right_score
	$CanvasLayer/TotalContainer/TotalScore.text = "TOTAL: %d" % (left_score + right_score)

@rpc("authority", "reliable")
func announce_update_time_left(new_time_left: int) -> void:
	time_left = new_time_left
	$CanvasLayer/TimeLeftContainer/TimeLeftLabel.text = "%d" % time_left
	if time_left == 0:
		state = State.GAME_OVER
		$CanvasLayer/LobbyButtonContainer.visible = true
		$CanvasLayer/LobbyButtonContainer/LobbyButton.grab_focus()

func _on_customer_timer_timeout() -> void:
	if not multiplayer.is_server():
		return

	if state == State.GAME_OVER:
		return

	var customer = load("res://scenes/customer.tscn").instantiate()
	var desire = "coffee"
	var spawn_area = $LeftCustomerSpawnArea
	var target_area = $RightCustomerSpawnArea
	if randf() > 0.5:
		desire = "wine"
	if randf() > 0.5:
		spawn_area = $RightCustomerSpawnArea
		target_area = $LeftCustomerSpawnArea
	var initial_global_position = spawn_area.get_random_position()
	var target = target_area.get_random_position()
	customer.init(initial_global_position, spawn_area.get_path(), target, desire)
	$Replicated.add_child(customer, true)

func _on_left_cafe_customer_left(served) -> void:
	if not multiplayer.is_server():
		return

	if not served:
		return

	var new_score = left_score
	
	if served == "coffee":
		new_score = left_score + 1
	elif served == "wine":
		new_score = left_score + 2
	for peer in NodeUtils.get_first_ancestor_in_group_for_node(self, "App").get_peer_ids_for_match(match_id):
		if peer == 1:
			continue
		announce_update_left_score.rpc_id(peer, new_score)

	announce_update_left_score(new_score)

func _on_right_cafe_customer_left(served) -> void:
	if not multiplayer.is_server():
		return

	if not served:
		return

	var new_score = right_score
	
	if served == "coffee":
		new_score = right_score + 1
	elif served == "wine":
		new_score = right_score + 2
	for peer in NodeUtils.get_first_ancestor_in_group_for_node(self, "App").get_peer_ids_for_match(match_id):
		if peer == 1:
			continue
		announce_update_right_score.rpc_id(peer, new_score)

	announce_update_right_score(new_score)

func _on_power_up_timer_timeout() -> void:
	if not multiplayer.is_server():
		return

	if state == State.GAME_OVER:
		return

	var power_ups = NodeUtils.get_nodes_in_group_for_node(self, "PowerUp")
	
	if len(power_ups) > 0:
		return

	var spawn_area = $LeftMailmanSpawnArea
	var target_area = $RightMailmanSpawnArea
	if randf() > 0.5:
		spawn_area = $RightMailmanSpawnArea
		target_area = $LeftMailmanSpawnArea
	var initial_global_position = spawn_area.get_random_position()
	var target = target_area.get_random_position()

	var mailman = load("res://scenes/mailman.tscn").instantiate()
	mailman.init(initial_global_position, spawn_area.get_path(), target)
	$Replicated.add_child(mailman, true)

func _on_game_timer_timeout() -> void:
	if not multiplayer.is_server():
		return

	if time_left == 0:
		return

	var new_time_left = time_left - 1
	for peer in NodeUtils.get_first_ancestor_in_group_for_node(self, "App").get_peer_ids_for_match(match_id):
		if peer == 1:
			continue
		announce_update_time_left.rpc_id(peer, new_time_left)

	announce_update_time_left(new_time_left)

func _on_lobby_button_pressed() -> void:
	emit_signal("leave_requested")
