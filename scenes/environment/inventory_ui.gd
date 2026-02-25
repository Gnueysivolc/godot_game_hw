extends CanvasLayer

@onready var vbox = $Control/MarginContainer/VBoxContainer

var slot_scene = preload("res://GUI/inventory/invetory_slot.tscn")
var lock_scene = preload("res://GUI/inventory/items/lock.tscn")

var items: Array = []
var lock_slots: Array = []


func _ready():
	create_lock_slots()
	update_locks()
	Global.inventory_upgraded.connect(update_locks)


# ------------------------------------
# CREATE LOCK SLOTS
# ------------------------------------
func create_lock_slots():
	for i in Global.total_inventory_slots:
		var lock = lock_scene.instantiate()
		vbox.add_child(lock)
		lock_slots.append(lock)


# ------------------------------------
# ADD ITEM
# ------------------------------------
func add_item(texture: Texture2D):

	if items.size() >= Global.unlocked_inventory_slots:
		print("Inventory full")
		return

	var slot = slot_scene.instantiate()
	slot.set_texture(texture)

	vbox.add_child(slot)
	vbox.move_child(slot, 0)

	items.insert(0, slot)


# ------------------------------------
# USE ITEM
# ------------------------------------
func use_item():

	if items.is_empty():
		return

	var slot = items[0]
	slot.queue_free()
	items.remove_at(0)


# ------------------------------------
# UPDATE LOCK VISIBILITY
# ------------------------------------
func update_locks():

	for i in lock_slots.size():
		lock_slots[i].visible = i >= Global.unlocked_inventory_slots
