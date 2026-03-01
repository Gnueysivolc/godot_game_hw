extends Node2D

@onready var inventory_ui: InventoryUI = $inventoryUI

func _ready():
	for box in get_tree().get_nodes_in_group("loot_box"):
		box.item_obtained.connect(_on_box_item_obtained)

	if not inventory_ui.first_order_completed.is_connected(_on_first_order_completed):
		inventory_ui.first_order_completed.connect(_on_first_order_completed)

	_connect_submit_stations()


func _connect_submit_stations() -> void:
	for node in get_children():
		if not node.has_signal("submit_requested"):
			continue
		if node.is_connected("submit_requested", Callable(self, "_on_submit_requested")):
			continue
		node.connect("submit_requested", Callable(self, "_on_submit_requested"))

func _on_box_item_obtained(item_type: ItemTypes.ItemType) -> void:
	inventory_ui.add_item(item_type)


func _on_submit_requested() -> void:
	inventory_ui.submit_top_item_to_orders()


func _on_first_order_completed() -> void:
	for node in get_children():
		if not (node is CanvasItem):
			continue
		if String(node.name).to_lower().begins_with("arrow"):
			(node as CanvasItem).visible = false
