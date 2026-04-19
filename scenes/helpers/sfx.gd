extends Node

@rpc("any_peer", "call_local", "reliable")
func announce_play_sfx(path: String) -> void:
	var player := AudioStreamPlayer.new()
	player.stream = load(path)
	add_child(player)
	player.play()
	player.finished.connect(func(): player.queue_free())
