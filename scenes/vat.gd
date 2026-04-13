extends Area2D


enum State {
	EMPTY,
	BREWING,
	BREWED,
	SPOILED
}

@export var state = State.EMPTY

func _physics_process(_delta: float) -> void:
	if state == State.EMPTY:
		$AnimatedSprite2D.play("empty")
	if state == State.BREWING:
		$AnimatedSprite2D.play("brewing")
	if state == State.BREWED:
		$AnimatedSprite2D.play("brewed")
	if state == State.SPOILED:
		$AnimatedSprite2D.play("spoiled")

func _on_body_entered(body: Node2D) -> void:
	if not multiplayer.is_server():
		return

	if body.is_in_group("Barista"):
		if state == State.EMPTY and body.holding == "grapes":
			state = State.BREWING
			$BrewTimer.start()
			body.holding = ""
		if state == State.BREWED and body.holding == "":
			state = State.EMPTY
			$SpoilTimer.stop()
			body.holding = "wine"
		if state == State.SPOILED and body.holding == "":
			state = State.EMPTY
			body.holding = "waste"

func _on_brew_timer_timeout() -> void:
	if not multiplayer.is_server():
		return

	state = State.BREWED
	$SpoilTimer.start()

func _on_spoil_timer_timeout() -> void:
	if not multiplayer.is_server():
		return

	state = State.SPOILED
