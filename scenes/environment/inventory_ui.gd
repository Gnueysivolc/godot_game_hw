extends CanvasLayer

@onready var items_vbox = $Control/MarginContainer/VBoxContainer
@onready var lock_vbox = $lock/VBoxContainer

var slot_scene = preload("res://GUI/inventory/invetory_slot.tscn")
var lock_scene = preload("res://GUI/inventory/lock.tscn")

var items: Array = []
var lock_nodes: Array = []


func _ready():
	update_locks()
	Global.inventory_upgraded.connect(update_locks)


func add_item(texture: Texture2D):

	if items.size() >= Global.unlocked_inventory_slots:
		print("Inventory full")
		return

	var slot = slot_scene.instantiate()
	slot.set_texture(texture)

	items_vbox.add_child(slot)
	items_vbox.move_child(slot, 0)

	items.insert(0, slot)


func use_item():

	if items.is_empty():
		return

	var slot = items[0]
	slot.queue_free()
	items.remove_at(0)


func update_locks():

	# Remove old locks
	for lock in lock_nodes:
		lock.queue_free()

	lock_nodes.clear()

	print("clear lock")

	var lock_count = Global.total_inventory_slots - Global.unlocked_inventory_slots

	for i in range(lock_count):
		print("add lock:", i)

		var lock = lock_scene.instantiate()

		lock_vbox.add_child(lock)     # ← bottom insert
		lock_nodes.append(lock)       # ← match visual order
		
		
		
