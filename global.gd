extends Node

# ------------------------
# INVENTORY SETTINGS
# ------------------------

var total_inventory_slots: int = 6
var unlocked_inventory_slots: int = 2

signal inventory_upgraded


func increase_inventory_size(amount: int):
	unlocked_inventory_slots = clamp(
		unlocked_inventory_slots + amount,
		0,
		total_inventory_slots
	)
	
	inventory_upgraded.emit()
	print("Inventory upgraded to:", unlocked_inventory_slots)
	
	
	
	
	
	
