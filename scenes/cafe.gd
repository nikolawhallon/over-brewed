extends Node2D

signal customer_left

var slot_1_customer_path = NodePath()
var slot_2_customer_path = NodePath()
var slot_3_customer_path = NodePath()

func customer_served():
	customer_left.emit()

func get_slot(customer_path):
	if slot_1_customer_path.is_empty():
		slot_1_customer_path = customer_path
		return $Slot1.global_position
	if slot_2_customer_path.is_empty():
		slot_2_customer_path = customer_path
		return $Slot2.global_position
	if slot_3_customer_path.is_empty():
		slot_3_customer_path = customer_path
		return $Slot3.global_position
	return null

func release_slot(customer_path):
	if slot_1_customer_path == customer_path:
		slot_1_customer_path = NodePath()
	elif slot_2_customer_path == customer_path:
		slot_2_customer_path = NodePath()
	elif slot_3_customer_path == customer_path:
		slot_3_customer_path = NodePath()
