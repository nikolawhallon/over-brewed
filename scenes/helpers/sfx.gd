extends Node

var player := AudioStreamPlayer.new()

func _ready():
	add_child(player)

@rpc("any_peer", "call_local", "reliable")
func announce_play_sfx(path: String) -> void:
	player.stream = load(path)
	player.play()
