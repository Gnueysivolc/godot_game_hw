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

# ------------------------
# PLAYER SETTINGS
# ------------------------

var player_move_speed: int = 300
var player_default_facing_direction: Vector2 = Vector2(0, 1)
var debug_inventory_upgrade_amount: int = 1

# ------------------------
# SCORE
# ------------------------

var score: float = 0.0

signal inventory_upgraded
signal global_value_modified(key: String, old_value: Variant, new_value: Variant)
signal global_modifiers_toggled(enabled: bool)

var modifiers_enabled: bool = true

const _MODIFIABLE_DEFAULTS := {
	"total_inventory_slots": 6,
	"unlocked_inventory_slots": 2,
	"max_active_orders": 3,
	"order_spawn_interval": 5.0,
	"order_time_limit": 30.0,
	"order_length_min": 3,
	"order_length_max": 6,
	"debug_time_limit": 15.0,
	"player_move_speed": 300,
	"debug_inventory_upgrade_amount": 1,
	"score": 0.0,
}

const _MODIFIABLE_LIMITS := {
	"total_inventory_slots": {"min": 1, "max": 24},
	"unlocked_inventory_slots": {"min": 0, "max": 24},
	"max_active_orders": {"min": 1, "max": 10},
	"order_spawn_interval": {"min": 0.1, "max": 120.0},
	"order_time_limit": {"min": 0.1, "max": 600.0},
	"order_length_min": {"min": 1, "max": 6},
	"order_length_max": {"min": 1, "max": 6},
	"debug_time_limit": {"min": 0.1, "max": 600.0},
	"player_move_speed": {"min": 0, "max": 1000},
	"debug_inventory_upgrade_amount": {"min": 0, "max": 6},
	"score": {"min": 0.0, "max": 10000000.0},
}


func _ready() -> void:
	reset_modifiable_values()


func increase_inventory_size(amount: int):
	unlocked_inventory_slots = clamp(
		unlocked_inventory_slots + amount,
		0,
		total_inventory_slots
	)
	
	inventory_upgraded.emit()
	print("Inventory upgraded to:", unlocked_inventory_slots)


func set_modifiers_enabled(enabled: bool) -> void:
	modifiers_enabled = enabled
	if not modifiers_enabled:
		reset_modifiable_values()
	global_modifiers_toggled.emit(modifiers_enabled)


func reset_modifiable_values() -> void:
	for key in _MODIFIABLE_DEFAULTS.keys():
		set(key, _MODIFIABLE_DEFAULTS[key])
	_post_apply_safety()


func modify_value(key: String, operation: String, amount: float) -> bool:
	if not modifiers_enabled:
		print("Global modifiers are disabled. Enable them first.")
		return false

	if not _MODIFIABLE_DEFAULTS.has(key):
		push_warning("Unknown or non-modifiable global key: %s" % key)
		return false

	var old_value: Variant = get(key)
	if not (old_value is int or old_value is float):
		push_warning("Key is not numeric and cannot be modified: %s" % key)
		return false

	var base_value: float = float(old_value)
	var result: float = base_value
	var op := operation.to_lower()

	match op:
		"add", "+":
			result = base_value + amount
		"minus", "subtract", "-":
			result = base_value - amount
		"multiply", "mult", "*", "x":
			result = base_value * amount
		"divide", "/":
			if is_zero_approx(amount):
				push_warning("Cannot divide by zero.")
				return false
			result = base_value / amount
		_:
			push_warning("Unknown operation: %s" % operation)
			return false

	if old_value is int:
		set(key, int(round(result)))
	else:
		set(key, result)

	_post_apply_safety()
	var new_value: Variant = get(key)
	global_value_modified.emit(key, old_value, new_value)
	print("Global modified:", key, "|", old_value, "->", new_value)
	return true


func get_modifiable_keys() -> Array[String]:
	var keys: Array[String] = []
	for key in _MODIFIABLE_DEFAULTS.keys():
		keys.append(String(key))
	return keys


func _post_apply_safety() -> void:
	_apply_limits()
	total_inventory_slots = max(total_inventory_slots, 1)
	unlocked_inventory_slots = clamp(unlocked_inventory_slots, 0, total_inventory_slots)
	order_length_min = max(order_length_min, 1)
	order_length_max = max(order_length_max, order_length_min)
	player_move_speed = max(player_move_speed, 0)
	debug_inventory_upgrade_amount = max(debug_inventory_upgrade_amount, 0)
	order_spawn_interval = max(order_spawn_interval, 0.1)
	order_time_limit = max(order_time_limit, 0.1)


func _apply_limits() -> void:
	for key in _MODIFIABLE_LIMITS.keys():
		if not _MODIFIABLE_DEFAULTS.has(key):
			continue
		var limits: Dictionary = _MODIFIABLE_LIMITS[key]
		var value: Variant = get(key)
		if value is int:
			var min_v: int = int(limits.get("min", value))
			var max_v: int = int(limits.get("max", value))
			set(key, int(clamp(int(value), min_v, max_v)))
		elif value is float:
			var min_f: float = float(limits.get("min", value))
			var max_f: float = float(limits.get("max", value))
			set(key, clamp(value, min_f, max_f))
	
	
	
	
	
	
