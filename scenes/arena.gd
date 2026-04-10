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
var score = 0

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
func announce_start_game(random_seed, _peers):
	state = State.STARTING

@rpc("any_peer", "call_local", "unreliable")
func request_spawn_barista():
	var barista = load("res://scenes/barista.tscn").instantiate()
	barista.init(multiplayer.get_remote_sender_id(), Vector2.ZERO)
	$Replicated.add_child(barista, true)

@rpc("authority", "reliable")
func announce_update_score(new_score: int) -> void:
	score = new_score
	$CanvasLayer/MarginContainer/ScoreLabel.text = "SCORE: %d" % score
