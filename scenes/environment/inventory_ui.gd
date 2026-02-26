extends CanvasLayer
class_name InventoryUI

@onready var items_vbox = $Control/MarginContainer/VBoxContainer
@onready var lock_vbox = $lock/VBoxContainer
@onready var orders_hbox = $OrdersHBox

var slot_scene = preload("res://GUI/inventory/invetory_slot.tscn")
var lock_scene = preload("res://GUI/inventory/lock.tscn")
var order_card_scene = preload("res://order/ordercard.tscn")

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

@export var max_active_orders: int = 3
@export var order_spawn_interval: float = 10.0
@export var order_time_limit: float = 15.0
@export var order_length_min: int = 3
@export var order_length_max: int = 5

@export var allowed_order_items: Array[ItemTypes.ItemType] = [
	ItemTypes.ItemType.RED_PILL,
	ItemTypes.ItemType.BLUE_PILL,
	ItemTypes.ItemType.GREEN_PILL,
	ItemTypes.ItemType.PURPLE_PILL,
	ItemTypes.ItemType.RED_INJECTION,
	ItemTypes.ItemType.BLUE_INJECTION,
	ItemTypes.ItemType.GREEN_INJECTION,
	ItemTypes.ItemType.PURPLE_INJECTION
]

var order_spawn_elapsed := 0.0


func _ready():
	randomize()
	update_locks()
	Global.inventory_upgraded.connect(update_locks)
	_try_spawn_order()


func _process(delta: float) -> void:
	order_spawn_elapsed += delta
	if order_spawn_elapsed >= order_spawn_interval:
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
	var success := false

	if order_card != null:
		success = order_card.submit_item(slot.item_type)

	# Submit station should consume one item per interaction.
	slot.queue_free()
	items.remove_at(0)

	return success


func submit_top_item_to_orders() -> bool:
	if items.is_empty():
		return false

	var slot = items[0]
	var item_type: ItemTypes.ItemType = slot.item_type
	var success := false

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
	if active_orders.size() >= max_active_orders:
		return false

	if sequence.is_empty():
		return false

	var duration: float = order_time_limit if time_limit <= 0 else time_limit
	_create_order(sequence, duration)
	return true


func _try_spawn_order() -> void:
	if active_orders.size() >= max_active_orders:
		return

	if allowed_order_items.is_empty():
		return

	var count: int = randi_range(order_length_min, order_length_max)
	count = min(count, 6) # scene has six slot icons
	count = max(count, 1)

	var sequence: Array[ItemTypes.ItemType] = []
	for i in range(count):
		sequence.append(allowed_order_items.pick_random())

	_create_order(sequence, order_time_limit)


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
	print("Order completed successfully.")
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
