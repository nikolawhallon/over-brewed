extends Area2D


func init(initial_global_position):
	global_position = initial_global_position

func _on_body_entered(body: Node2D) -> void:
	if not multiplayer.is_server():
		return

	if body.is_in_group("Barista"):
		if body.holding == "":
			body.holding = "newspaper"
			var arena = NodeUtils.get_first_ancestor_in_group_for_node(self, "Arena")
			for peer in NodeUtils.get_first_ancestor_in_group_for_node(self, "App").get_peer_ids_for_match(arena.match_id):
				if peer == 1:
					continue
				Sfx.announce_play_sfx.rpc_id(peer, "assets/sfx/sfx_swat.wav")

			Sfx.announce_play_sfx("assets/sfx/sfx_swat.wav")
			call_deferred("queue_free")
