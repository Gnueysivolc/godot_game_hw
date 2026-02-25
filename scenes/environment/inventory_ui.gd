extends CanvasLayer

@onready var vbox = $Control/MarginContainer/VBoxContainer
var slot_scene = preload("res://GUI/inventory/invetory_slot.tscn")

var items: Array = []

func add_item(texture: Texture2D):
	var slot = slot_scene.instantiate()
	slot.set_texture(texture)

	vbox.add_child(slot)
	vbox.move_child(slot, 0)

	items.insert(0, slot)



func use_item():
	if items.is_empty():
		return
	
	var slot = items[0]
	slot.queue_free()
	items.remove_at(0)
