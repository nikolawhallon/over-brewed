extends Area2D


func _on_body_entered(body: Node2D) -> void:
	if not multiplayer.is_server():
		return

	if body.is_in_group("Barista"):
		if body.holding == "":
			body.holding = "grapes"

			var arena = NodeUtils.get_first_ancestor_in_group_for_node(self, "Arena")
			for peer in NodeUtils.get_first_ancestor_in_group_for_node(self, "App").get_peer_ids_for_match(arena.match_id):
				if peer == 1:
					continue
				Sfx.announce_play_sfx.rpc_id(peer, "assets/sfx/sfx_grapes.wav")

			Sfx.announce_play_sfx("assets/sfx/sfx_grapes.wav")
