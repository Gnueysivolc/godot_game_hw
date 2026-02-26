extends Node

# ------------------------
# INVENTORY SETTINGS
# ------------------------

var total_inventory_slots: int = 6
var unlocked_inventory_slots: int = 2

# ------------------------
# ORDER SYSTEM SETTINGS
# ------------------------

var max_active_orders: int = 3
var order_spawn_interval: float = 5.0
var order_time_limit: float = 30.0
var order_length_min: int = 3
var order_length_max: int = 6

var allowed_order_items: Array[ItemTypes.ItemType] = [
	ItemTypes.ItemType.RED_PILL,
	ItemTypes.ItemType.BLUE_PILL,
	ItemTypes.ItemType.GREEN_PILL,
	ItemTypes.ItemType.PURPLE_PILL,
	ItemTypes.ItemType.RED_INJECTION,
	ItemTypes.ItemType.BLUE_INJECTION,
	ItemTypes.ItemType.GREEN_INJECTION,
	ItemTypes.ItemType.PURPLE_INJECTION
]

# Debug test order spawn
var debug_time_limit: float = 15.0
var debug_order_sequence: Array[ItemTypes.ItemType] = [
	ItemTypes.ItemType.RED_PILL,
	ItemTypes.ItemType.BLUE_PILL,
	ItemTypes.ItemType.GREEN_PILL
]

signal inventory_upgraded


func increase_inventory_size(amount: int):
	unlocked_inventory_slots = clamp(
		unlocked_inventory_slots + amount,
		0,
		total_inventory_slots
	)
	
	inventory_upgraded.emit()
	print("Inventory upgraded to:", unlocked_inventory_slots)
	
	
	
	
	
	
