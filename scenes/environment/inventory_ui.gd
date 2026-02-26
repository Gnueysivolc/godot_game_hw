extends CanvasLayer
class_name InventoryUI

@onready var items_vbox = $Control/MarginContainer/VBoxContainer
@onready var lock_vbox = $lock/VBoxContainer
@onready var orders_hbox = $OrdersHBox
@onready var score_label: Label = $ScoreLabel
@onready var wave_target_label: Label = $WaveTargetLabel
@onready var game_timer_label: Label = $GameTimerLabel
@onready var wave_popup: WavePopup = $WavePopup
@onready var game_over_popup: GameOverPopup = $GameOverPopup

var slot_scene = preload("res://GUI/inventory/invetory_slot.tscn")
var lock_scene = preload("res://GUI/inventory/lock.tscn")
var order_card_scene = preload("res://order/ordercard.tscn")
const SCORE_BASE: float = 100.0

const RED_PILL_ICON: Texture2D = preload("res://GUI/inventory/items/real_red_pill.png")
const BLUE_PILL_ICON: Texture2D = preload("res://GUI/inventory/items/real_blue_pill.png")
const GREEN_PILL_ICON: Texture2D = preload("res://GUI/inventory/items/real_green_pill.png")
const PURPLE_PILL_ICON: Texture2D = preload("res://GUI/inventory/items/real_purple_pill.png")
const RED_INJECTION_ICON: Texture2D = preload("res://GUI/inventory/items/red_injection.png")
const BLUE_INJECTION_ICON: Texture2D = preload("res://GUI/inventory/items/blue_injection.png")
const GREEN_INJECTION_ICON: Texture2D = preload("res://GUI/inventory/items/green_injection.png")
const PURPLE_INJECTION_ICON: Texture2D = preload("res://GUI/inventory/items/purple_injection.png")
const ORDER_FACE_ICON: Texture2D = preload("res://order/backcard.png")

var items: Array = []          # stores slot nodes
var lock_nodes: Array = []
var active_orders: Array[OrderCard] = []

var order_spawn_elapsed: float = 0.0
var current_wave: int = 1
var current_wave_target_score: float = 0.0
var game_time_left: float = 0.0
var wave_popup_open: bool = false
var game_ended: bool = false
var cured_patients: int = 0
var total_time_used_ratio: float = 0.0


func _ready():
	randomize()
	Global.score = 0.0
	current_wave = 1
	current_wave_target_score = Global.wave_target_base_score
	game_time_left = Global.game_time_limit
	wave_popup_open = false
	game_ended = false
	cured_patients = 0
	total_time_used_ratio = 0.0

	if not wave_popup.buff_chosen.is_connected(_on_wave_buff_chosen):
		wave_popup.buff_chosen.connect(_on_wave_buff_chosen)

	_update_score_label()
	_update_wave_target_label()
	_update_game_timer_label()
	update_locks()
	Global.inventory_upgraded.connect(update_locks)
	_try_spawn_order()


func _process(delta: float) -> void:
	if game_ended:
		return

	game_time_left -= delta
	_update_game_timer_label()

	if game_time_left <= 0.0:
		game_time_left = 0.0
		_update_game_timer_label()
		_end_game()
		return

	if wave_popup_open:
		wave_popup.update_timer_label(game_time_left)
		return

	if Global.score >= current_wave_target_score:
		_show_wave_popup()
		return

	order_spawn_elapsed += delta
	if order_spawn_elapsed >= Global.order_spawn_interval:
		order_spawn_elapsed = 0.0
		_try_spawn_order()


# ---------------------------
# ADD ITEM (ENUM BASED)
# ---------------------------
func add_item(item_type: ItemTypes.ItemType):

	if items.size() >= Global.unlocked_inventory_slots:
		print(items.size())
		print(Global.unlocked_inventory_slots)
		print("Inventory full")
		return

	var slot = slot_scene.instantiate()

	items_vbox.add_child(slot)      # 🔥 ADD FIRST
	items_vbox.move_child(slot, 0)

	slot.set_item(item_type)        # 🔥 THEN SET

	items.insert(0, slot)


# ---------------------------
# USE ITEM (SEND TO ORDER)
# ---------------------------
func use_item():

	if items.is_empty():
		return

	var slot = items[0]
	var item_type = slot.item_type

	# find station automatically
	var station = get_tree().get_first_node_in_group("patient_station")

	if station == null:
		return

	var success = station.submit_item(item_type)

	if success:
		slot.queue_free()
		items.remove_at(0)


func submit_top_item_to_order(order_card: OrderCard) -> bool:
	if items.is_empty():
		return false

	var slot = items[0]
	var success: bool = false

	if order_card != null:
		success = order_card.submit_item(slot.item_type)

	# Submit station should consume one item per interaction.
	slot.queue_free()
	items.remove_at(0)

	return success


func submit_top_item_to_orders() -> bool:
	if game_ended or wave_popup_open:
		return false

	if items.is_empty():
		return false

	var slot = items[0]
	var item_type: ItemTypes.ItemType = slot.item_type
	var success: bool = false

	for order in active_orders:
		if not is_instance_valid(order):
			continue
		if not order.is_active():
			continue
		if order.peek_expected_item() != item_type:
			continue

		success = order.submit_item(item_type)
		if success:
			break

	# Submit station should consume one item per interaction.
	slot.queue_free()
	items.remove_at(0)

	return success


func spawn_debug_order(sequence: Array[ItemTypes.ItemType], time_limit: float = -1.0) -> bool:
	if game_ended:
		return false

	if active_orders.size() >= Global.max_active_orders:
		return false

	if sequence.is_empty():
		return false

	var duration: float = Global.order_time_limit if time_limit <= 0 else time_limit
	_create_order(sequence, duration)
	return true


func _try_spawn_order() -> void:
	if active_orders.size() >= Global.max_active_orders:
		return

	if Global.allowed_order_items.is_empty():
		return

	var count: int = randi_range(Global.order_length_min, Global.order_length_max)
	count = min(count, 6) # scene has six slot icons
	count = max(count, 1)

	var sequence: Array[ItemTypes.ItemType] = []
	for i in range(count):
		sequence.append(Global.allowed_order_items.pick_random())

	_create_order(sequence, Global.order_time_limit)


func _create_order(sequence: Array[ItemTypes.ItemType], time_limit: float) -> void:
	var order: OrderCard = order_card_scene.instantiate()
	_configure_order_visuals(order)

	orders_hbox.add_child(order)
	active_orders.append(order)

	order.completed.connect(_on_order_completed.bind(order))
	order.timed_out.connect(_on_order_timed_out.bind(order))
	order.failed.connect(_on_order_failed.bind(order))

	order.setup(sequence, time_limit)


func _configure_order_visuals(order: OrderCard) -> void:
	order.custom_minimum_size = Vector2(230, 120)

	order.red_icon = RED_PILL_ICON
	order.blue_icon = BLUE_PILL_ICON
	order.green_icon = GREEN_PILL_ICON
	order.purple_icon = PURPLE_PILL_ICON
	order.red_injection_icon = RED_INJECTION_ICON
	order.blue_injection_icon = BLUE_INJECTION_ICON
	order.green_injection_icon = GREEN_INJECTION_ICON
	order.purple_injection_icon = PURPLE_INJECTION_ICON

	order.face_normal = ORDER_FACE_ICON
	order.face_sick = ORDER_FACE_ICON
	order.face_sad = ORDER_FACE_ICON


func _on_order_completed(order: OrderCard) -> void:
	var time_left: float = order.get_time_left()
	var item_count: int = order.get_required_count()
	var duration: float = order.get_duration()
	var time_used_ratio: float = 1.0 - (time_left / duration)
	total_time_used_ratio += clamp(time_used_ratio, 0.0, 1.0)
	cured_patients += 1

	var added_score: float = SCORE_BASE * time_left * float(item_count)
	Global.score += added_score
	_update_score_label()

	print("Order completed successfully.")
	print(
		"Score formula: ", SCORE_BASE, " * ", time_left, " * ", item_count,
		" = ", added_score
	)
	print("Score added: ", added_score, " | Total score: ", Global.score)
	_remove_order(order)


func _on_order_timed_out(order: OrderCard) -> void:
	_remove_order(order)


func _on_order_failed(order: OrderCard) -> void:
	_remove_order(order)


func _remove_order(order: OrderCard) -> void:
	if active_orders.has(order):
		active_orders.erase(order)

	if is_instance_valid(order):
		order.queue_free()


func _update_score_label() -> void:
	score_label.text = "Score: %.1f" % Global.score


func _update_wave_target_label() -> void:
	wave_target_label.text = "Wave %d Target: %.1f" % [current_wave, current_wave_target_score]


func _update_game_timer_label() -> void:
	var clamped: int = max(int(ceil(game_time_left)), 0)
	var mins: int = clamped / 60
	var secs: int = clamped % 60
	game_timer_label.text = "Time: %02d:%02d" % [mins, secs]


func _show_wave_popup() -> void:
	wave_popup_open = true
	wave_popup.show_popup(current_wave, current_wave_target_score, game_time_left)


# important place for changing buff values
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#

func _on_wave_buff_chosen(buff_id: String) -> void:
	match buff_id:
		"more_time":
			Global.modify_value("order_time_limit", "add", 7.0)
		"faster_boxes":
			Global.modify_value("box_respawn_time", "multiply", 0.85)
		"faster_player":
			Global.modify_value("player_move_speed", "add", 100)
		"inventory_up":
			Global.increase_inventory_size(1)
		_:
			push_warning("Unknown buff id: %s" % buff_id)

	current_wave += 1
	current_wave_target_score *= Global.wave_target_growth_multiplier
	Global.order_length_min = min(Global.order_length_min + 1, 6)
	Global.order_length_max = min(Global.order_length_max + 1, 6)
	if Global.order_length_max < Global.order_length_min:
		Global.order_length_max = Global.order_length_min

	_update_wave_target_label()
	wave_popup.hide_popup()
	wave_popup_open = false
	order_spawn_elapsed = 0.0
	_try_spawn_order()


func _end_game() -> void:
	game_ended = true
	wave_popup_open = false
	wave_popup.hide_popup()

	var average_time_used_ratio: float = 1.0
	if cured_patients > 0:
		average_time_used_ratio = total_time_used_ratio / float(cured_patients)

	game_over_popup.show_results(cured_patients, average_time_used_ratio, Global.score)

# ---------------------------
# LOCK SYSTEM (UNCHANGED)
# ---------------------------
func update_locks():

	for lock in lock_nodes:
		lock.queue_free()

	lock_nodes.clear()

	var lock_count = Global.total_inventory_slots - Global.unlocked_inventory_slots

	for i in range(lock_count):
		var lock = lock_scene.instantiate()
		lock_vbox.add_child(lock)
		lock_nodes.append(lock)
