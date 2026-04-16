extends CharacterBody2D


const SPEED = 50.0

@export var peer_id = -1
@export var direction = Vector2.ZERO
@export var cafe = ""
@export var holding = ""
var facing = null
var mouse_target = null

func init(initial_peer_id, initial_cafe, initial_global_position):
	peer_id = initial_peer_id
	cafe = initial_cafe
	global_position = initial_global_position

func _ready():
	$AnimatedSprite2D.play("idle")

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
	elif event is InputEventScreenTouch:
		if event.pressed:
			mouse_target = event.position
		else:
			mouse_target = null
	elif event is InputEventScreenDrag:
		mouse_target = event.position

func _physics_process(_delta: float) -> void:
	if holding == "beans":
		$Beans.visible = true
		$Coffee.visible = false
		$Waste.visible = false
		$Grapes.visible = false
		$Wine.visible = false
		$Newspaper.visible = false
	elif holding == "coffee":
		$Beans.visible = false
		$Coffee.visible = true
		$Waste.visible = false
		$Grapes.visible = false
		$Wine.visible = false
		$Newspaper.visible = false
	elif holding == "waste":
		$Beans.visible = false
		$Coffee.visible = false
		$Waste.visible = true
		$Grapes.visible = false
		$Wine.visible = false
		$Newspaper.visible = false
	elif holding == "newspaper":
		$Beans.visible = false
		$Coffee.visible = false
		$Waste.visible = false
		$Grapes.visible = false
		$Wine.visible = false
		$Newspaper.visible = true
	elif holding == "grapes":
		$Beans.visible = false
		$Coffee.visible = false
		$Waste.visible = false
		$Grapes.visible = true
		$Wine.visible = false
		$Newspaper.visible = false
	elif holding == "wine":
		$Beans.visible = false
		$Coffee.visible = false
		$Waste.visible = false
		$Grapes.visible = false
		$Wine.visible = true
		$Newspaper.visible = false
	else:
		$Beans.visible = false
		$Coffee.visible = false
		$Waste.visible = false
		$Grapes.visible = false
		$Wine.visible = false
		$Newspaper.visible = false

	if direction != Vector2.ZERO:
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

	velocity = direction * SPEED
	move_and_slide()

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
