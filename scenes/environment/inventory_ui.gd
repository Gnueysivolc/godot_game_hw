extends CanvasLayer

@onready var items_vbox = $Control/MarginContainer/VBoxContainer
@onready var lock_vbox = $lock/VBoxContainer

var slot_scene = preload("res://GUI/inventory/invetory_slot.tscn")
var lock_scene = preload("res://GUI/inventory/lock.tscn")

var items: Array = []          # stores slot nodes
var lock_nodes: Array = []


func _ready():
	update_locks()
	Global.inventory_upgraded.connect(update_locks)


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
