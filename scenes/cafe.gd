extends Node2D

signal customer_left

var slot_1_occupied = 0
var slot_2_occupied = 0
var slot_3_occupied = 0
var slot_1_assigned = false
var slot_2_assigned = false
var slot_3_assigned = false

func customer_served():
	customer_left.emit()

func get_slot():
	if not slot_1_assigned:
		slot_1_assigned = true
		return $Slot1.global_position
	if not slot_2_assigned:
		slot_2_assigned = true
		return $Slot2.global_position
	if not slot_3_assigned:
		slot_3_assigned = true
		return $Slot3.global_position
	return null

func _on_slot_1_body_entered(body: Node2D) -> void:
	if not multiplayer.is_server():
		return

	if body.is_in_group("Customer"):
		slot_1_occupied += 1

func _on_slot_1_body_exited(body: Node2D) -> void:
	if not multiplayer.is_server():
		return

	if body.is_in_group("Customer"):
		slot_1_occupied -= 1
		if slot_1_occupied == 0:
			slot_1_assigned = false

func _on_slot_2_body_entered(body: Node2D) -> void:
	if not multiplayer.is_server():
		return

	if body.is_in_group("Customer"):
		slot_2_occupied += 1

func _on_slot_2_body_exited(body: Node2D) -> void:
	if not multiplayer.is_server():
		return

	if body.is_in_group("Customer"):
		slot_2_occupied -= 1
		if slot_2_occupied == 0:
			slot_2_assigned = false

func _on_slot_3_body_entered(body: Node2D) -> void:
	if not multiplayer.is_server():
		return

	if body.is_in_group("Customer"):
		slot_3_occupied += 1

func _on_slot_3_body_exited(body: Node2D) -> void:
	if not multiplayer.is_server():
		return

	if body.is_in_group("Customer"):
		slot_3_occupied -= 1
		if slot_3_occupied == 0:
			slot_3_assigned = false
