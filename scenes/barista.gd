extends CharacterBody2D


const SPEED = 50.0

@export var peer_id = -1
@export var direction = Vector2.ZERO
@export var cafe = ""
@export var holding = ""
@export var skin_type = 1
var facing = null
var mouse_target = null

func init(initial_peer_id, initial_cafe, initial_global_position, initial_skin_type):
	peer_id = initial_peer_id
	cafe = initial_cafe
	global_position = initial_global_position
	skin_type = initial_skin_type

func _ready():
	if $AnimatedSprite2D.material:                                                                                                                        
		$AnimatedSprite2D.material = $AnimatedSprite2D.material.duplicate()                                                                           

	$AnimatedSprite2D.play("idle")
	$Waste.play("default")

	if $AnimatedSprite2D.material:
		if cafe == "right":
			$AnimatedSprite2D.material.set_shader_parameter("apron_color", Color("#333a7f"))

		match skin_type:
			1:
				pass
			2:
				$AnimatedSprite2D.material.set_shader_parameter("hair_color", Color("#122230"))
				$AnimatedSprite2D.material.set_shader_parameter("skin_color", Color("#542730"))
				$AnimatedSprite2D.material.set_shader_parameter("skin_shadow_color", Color("#244a63"))
			3:
				$AnimatedSprite2D.material.set_shader_parameter("hair_color", Color("#f6d995"))
			4:
				$AnimatedSprite2D.material.set_shader_parameter("hair_color", Color("#bb3c63"))
				$AnimatedSprite2D.material.set_shader_parameter("skin_color", Color("#f9b9d8"))
				$AnimatedSprite2D.material.set_shader_parameter("skin_shadow_color", Color("#ed6697"))

	if not multiplayer.is_server():
		return

func _input(event):
	if multiplayer.get_unique_id() != peer_id:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			mouse_target = get_global_mouse_position()
		else:
			mouse_target = null
	elif event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		mouse_target = get_global_mouse_position()

func _physics_process(_delta: float) -> void:
	if holding == "beans":
		$Beans.visible = true
		$Coffee.visible = false
		$Waste.visible = false
		$Grapes.visible = false
		$Wine.visible = false
	elif holding == "coffee":
		$Beans.visible = false
		$Coffee.visible = true
		$Waste.visible = false
		$Grapes.visible = false
		$Wine.visible = false
	elif holding == "waste":
		$Beans.visible = false
		$Coffee.visible = false
		$Waste.visible = true
		$Grapes.visible = false
		$Wine.visible = false
	elif holding == "grapes":
		$Beans.visible = false
		$Coffee.visible = false
		$Waste.visible = false
		$Grapes.visible = true
		$Wine.visible = false
	elif holding == "wine":
		$Beans.visible = false
		$Coffee.visible = false
		$Waste.visible = false
		$Grapes.visible = false
		$Wine.visible = true
	else:
		$Beans.visible = false
		$Coffee.visible = false
		$Waste.visible = false
		$Grapes.visible = false
		$Wine.visible = false

	if holding == "newspaper":
		$AnimatedSprite2D.play("swat")
	elif direction != Vector2.ZERO:
		$AnimatedSprite2D.play("move")
	else:
		$AnimatedSprite2D.play("idle")

	if direction.x < 0.0:
		$AnimatedSprite2D.flip_h = true
	elif direction.x > 0.0:
		$AnimatedSprite2D.flip_h = false

	if multiplayer.get_unique_id() == peer_id:
		var new_direction = calculate_new_direction()

		if new_direction != direction:
			request_update_direction.rpc_id(1, new_direction)

	if not multiplayer.is_server():
		return

	var arena = NodeUtils.get_first_ancestor_in_group_for_node(self, "Arena")
	if arena.state == 3:  # State.GAME_OVER = 3
		return

	velocity = direction * SPEED
	move_and_slide()
	
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()

		if collider and collider.is_in_group("Barista"):
			handle_barista_collision(collider)

func handle_barista_collision(other_barista):
	var this_had_newspaper = holding == "newspaper"
	var other_had_newspaper = other_barista.holding == "newspaper"

	if this_had_newspaper and other_barista.holding != "":
		other_barista.holding = ""
		var arena = NodeUtils.get_first_ancestor_in_group_for_node(self, "Arena")
		for peer in NodeUtils.get_first_ancestor_in_group_for_node(self, "App").get_peer_ids_for_match(arena.match_id):
			if peer == 1:
				continue
			Sfx.announce_play_sfx.rpc_id(peer, "assets/sfx/sfx_hit.wav")

		Sfx.announce_play_sfx("assets/sfx/sfx_hit.wav")
	if other_had_newspaper and holding != "":
		holding = ""
		var arena = NodeUtils.get_first_ancestor_in_group_for_node(self, "Arena")
		for peer in NodeUtils.get_first_ancestor_in_group_for_node(self, "App").get_peer_ids_for_match(arena.match_id):
			if peer == 1:
				continue
			Sfx.announce_play_sfx.rpc_id(peer, "assets/sfx/sfx_hit.wav")

		Sfx.announce_play_sfx("assets/sfx/sfx_hit.wav")

func calculate_new_direction():
	var keyboard_input = Vector2(
		int(Input.is_key_pressed(KEY_RIGHT)) - int(Input.is_key_pressed(KEY_LEFT)),
		int(Input.is_key_pressed(KEY_DOWN)) - int(Input.is_key_pressed(KEY_UP))
	)

	if keyboard_input != Vector2.ZERO:
		return keyboard_input.normalized()

	var stick = Vector2(
		Input.get_joy_axis(0, JOY_AXIS_LEFT_X),
		Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)
	)

	var dpad = Vector2(
		int(Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_RIGHT)) - int(Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_LEFT)),
		int(Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_DOWN)) - int(Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_UP))
	)

	var deadzone = 0.2

	if stick.length() >= deadzone:
		return stick.normalized()

	if dpad != Vector2.ZERO:
		return dpad.normalized()

	if mouse_target != null:
		var direction_to_target = mouse_target - global_position
		var distance_to_target = direction_to_target.length()

		if distance_to_target < 4.0:
			return Vector2.ZERO

		return direction_to_target.normalized()

	return Vector2.ZERO

@rpc("any_peer", "call_local", "unreliable")
func request_update_direction(new_direction):
	if not multiplayer.is_server():
		return

	assert(peer_id == multiplayer.get_remote_sender_id())
	direction = new_direction

	if direction != Vector2.ZERO:
		if direction.x > 0 and abs(direction.x) >= abs(direction.y):
			facing = "right"
		if direction.x < 0 and abs(direction.x) > abs(direction.y):
			facing = "left"
		if direction.y > 0 and abs(direction.y) >= abs(direction.x):
			facing = "down"
		if direction.y < 0 and abs(direction.y) > abs(direction.x):
			facing = "up"

func _on_animated_sprite_2d_animation_looped() -> void:
	if not multiplayer.is_server():
		return
	if $AnimatedSprite2D.animation == "swat":
		var arena = NodeUtils.get_first_ancestor_in_group_for_node(self, "Arena")
		for peer in NodeUtils.get_first_ancestor_in_group_for_node(self, "App").get_peer_ids_for_match(arena.match_id):
			if peer == 1:
				continue
			Sfx.announce_play_sfx.rpc_id(peer, "assets/sfx/sfx_swat.wav")

		Sfx.announce_play_sfx("assets/sfx/sfx_swat.wav")
