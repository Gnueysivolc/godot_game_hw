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
var box_respawn_time: float = 5.0
var wave_target_base_score: float = 1000.0
var wave_target_growth_multiplier: float = 1.5
var game_time_limit: float = 180.0

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
var win_score_threshold: float = 100000.0

# ------------------------
# LIFE
# ------------------------

var max_lives: int = 5
var current_lives: int = 5
var selected_difficulty: String = "easy"

signal inventory_upgraded
signal lives_changed(current: int, max_value: int)
signal pause_toggled(paused: bool)
signal global_value_modified(key: String, old_value: Variant, new_value: Variant)
signal global_modifiers_toggled(enabled: bool)

var modifiers_enabled: bool = true

const _MODIFIABLE_DEFAULTS := {
	"total_inventory_slots": 6,
	"unlocked_inventory_slots": 2,
	"max_active_orders": 3,
	"order_spawn_interval": 5.0,
	"order_time_limit": 30.0,
	"order_length_min": 1,
	"order_length_max": 2,
	"box_respawn_time": 8.0,
	"wave_target_base_score": 10000.0,
	"wave_target_growth_multiplier": 1.7,
	"game_time_limit": 240,
	"debug_time_limit": 15.0,
	"player_move_speed": 300,
	"debug_inventory_upgrade_amount": 1,
	"score": 0.0,
	"win_score_threshold": 100000.0,
	"max_lives": 5,
	"current_lives": 5,
}

const _MODIFIABLE_LIMITS := {
	"total_inventory_slots": {"min": 1, "max": 24},
	"unlocked_inventory_slots": {"min": 0, "max": 24},
	"max_active_orders": {"min": 1, "max": 10},
	"order_spawn_interval": {"min": 0.1, "max": 120.0},
	"order_time_limit": {"min": 0.1, "max": 600.0},
	"order_length_min": {"min": 1, "max": 6},
	"order_length_max": {"min": 1, "max": 6},
	"box_respawn_time": {"min": 0.1, "max": 60.0},
	"wave_target_base_score": {"min": 1.0, "max": 1000000000.0},
	"wave_target_growth_multiplier": {"min": 1.0, "max": 10.0},
	"game_time_limit": {"min": 5.0, "max": 7200.0},
	"debug_time_limit": {"min": 0.1, "max": 600.0},
	"player_move_speed": {"min": 50, "max": 2000},
	"debug_inventory_upgrade_amount": {"min": 0, "max": 6},
	"score": {"min": 0.0, "max": 10000000.0},
	"win_score_threshold": {"min": 1.0, "max": 1000000000.0},
	"max_lives": {"min": 1, "max": 12},
	"current_lives": {"min": 0, "max": 12},
}

const _DIFFICULTY_PRESETS := {
	"easy": {
		"order_time_limit": 45.0,
		"max_lives": 5,
		"unlocked_inventory_slots": 3,
		"win_score_threshold": 60000.0,
	},
	"medium": {
		"order_time_limit": 25.0,
		"max_lives": 3,
		"unlocked_inventory_slots": 2,
	},
	"hard": {
		"order_time_limit": 15.0,
		"max_lives": 1,
		"unlocked_inventory_slots": 1,
	},
}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process_input(true)
	_ensure_keyboard_movement_bindings()
	_ensure_test_pause_binding()
	reset_modifiable_values()


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key_event: InputEventKey = event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	if not event.is_action_pressed("test"):
		return
	if not _is_gameplay_scene_active():
		return
	toggle_pause()


func toggle_pause() -> void:
	var tree: SceneTree = get_tree()
	if tree == null:
		return
	tree.paused = not tree.paused
	pause_toggled.emit(tree.paused)
	print("Pause toggled. Paused:", tree.paused)


func _is_gameplay_scene_active() -> bool:
	var tree: SceneTree = get_tree()
	if tree == null:
		return false
	var scene: Node = tree.current_scene
	if scene == null:
		return false
	return scene.scene_file_path == "res://scenes/environment/clinic_map.tscn"


func _ensure_keyboard_movement_bindings() -> void:
	_ensure_action_has_key("up", KEY_W)
	_ensure_action_has_key("down", KEY_S)
	_ensure_action_has_key("left", KEY_A)
	_ensure_action_has_key("right", KEY_D)


func _ensure_action_has_key(action_name: String, key: Key) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)

	var events: Array[InputEvent] = InputMap.action_get_events(action_name)
	for event in events:
		if event is InputEventKey:
			var key_event: InputEventKey = event as InputEventKey
			if key_event.keycode == key or key_event.physical_keycode == key:
				return

	var add_event: InputEventKey = InputEventKey.new()
	add_event.keycode = key
	add_event.physical_keycode = key
	InputMap.action_add_event(action_name, add_event)


func _ensure_test_pause_binding() -> void:
	if not InputMap.has_action("test"):
		InputMap.add_action("test")

	var events: Array[InputEvent] = InputMap.action_get_events("test")
	for event in events:
		if event is InputEventMouseButton:
			InputMap.action_erase_event("test", event)

	_ensure_action_has_key("test", KEY_T)


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


func reset_lives() -> void:
	current_lives = max_lives
	lives_changed.emit(current_lives, max_lives)


func add_life(amount: int = 1) -> void:
	current_lives = clamp(current_lives + max(amount, 0), 0, max_lives)
	lives_changed.emit(current_lives, max_lives)


func lose_life(amount: int = 1) -> void:
	current_lives = clamp(current_lives - max(amount, 0), 0, max_lives)
	lives_changed.emit(current_lives, max_lives)


func reset_modifiable_values() -> void:
	for key in _MODIFIABLE_DEFAULTS.keys():
		set(key, _MODIFIABLE_DEFAULTS[key])
	_post_apply_safety()
	selected_difficulty = "easy"


func apply_difficulty_preset(difficulty_id: String) -> bool:
	var normalized: String = difficulty_id.to_lower()
	if not _DIFFICULTY_PRESETS.has(normalized):
		push_warning("Unknown difficulty preset: %s" % difficulty_id)
		return false

	reset_modifiable_values()

	var preset: Dictionary = _DIFFICULTY_PRESETS[normalized]
	for key in preset.keys():
		if _MODIFIABLE_DEFAULTS.has(key):
			set(key, preset[key])

	_post_apply_safety()
	selected_difficulty = normalized
	reset_lives()
	inventory_upgraded.emit()

	print(
		"Difficulty preset applied: ", selected_difficulty,
		" | order_time_limit=", order_time_limit,
		" | max_lives=", max_lives,
		" | unlocked_inventory_slots=", unlocked_inventory_slots
	)
	return true


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
	var op: String = operation.to_lower()

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
	box_respawn_time = max(box_respawn_time, 0.1)
	player_move_speed = max(player_move_speed, 0)
	debug_inventory_upgrade_amount = max(debug_inventory_upgrade_amount, 0)
	order_spawn_interval = max(order_spawn_interval, 0.1)
	order_time_limit = max(order_time_limit, 0.1)
	wave_target_base_score = max(wave_target_base_score, 1.0)
	wave_target_growth_multiplier = max(wave_target_growth_multiplier, 1.0)
	game_time_limit = max(game_time_limit, 5.0)
	win_score_threshold = max(win_score_threshold, 1.0)
	max_lives = max(max_lives, 1)
	current_lives = clamp(current_lives, 0, max_lives)


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
	
	
	
	
	
	
