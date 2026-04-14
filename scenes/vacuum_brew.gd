extends Area2D


enum State {
	EMPTY,
	BREWING,
	BREWED,
	BURNT
}

@export var state = State.EMPTY

func _physics_process(_delta: float) -> void:
	if state == State.EMPTY:
		$AnimatedSprite2D.play("empty")
		$TimerProgress.visible = false
	if state == State.BREWING:
		$AnimatedSprite2D.play("brewing")
		$TimerProgress.visible = true
		var progress = (1.0 - $BrewTimer.time_left / $BrewTimer.wait_time) * 100
		$TimerProgress.value = progress
	if state == State.BREWED:
		$AnimatedSprite2D.play("brewed")
		$TimerProgress.visible = true
		var progress = (1.0 - $BurnTimer.time_left / $BurnTimer.wait_time) * 100
		$TimerProgress.value = progress
	if state == State.BURNT:
		$AnimatedSprite2D.play("burnt")
		$TimerProgress.visible = false

func _on_body_entered(body: Node2D) -> void:
	if not multiplayer.is_server():
		return

	if body.is_in_group("Barista"):
		if state == State.EMPTY and body.holding == "beans":
			state = State.BREWING
			$BrewTimer.start()
			body.holding = ""
		if state == State.BREWED and body.holding == "":
			state = State.EMPTY
			$BurnTimer.stop()
			body.holding = "coffee"
		if state == State.BURNT and body.holding == "":
			state = State.EMPTY
			body.holding = "waste"

func _on_brew_timer_timeout() -> void:
	if not multiplayer.is_server():
		return

	state = State.BREWED
	$BurnTimer.start()

func _on_burn_timer_timeout() -> void:
	if not multiplayer.is_server():
		return

	state = State.BURNT
