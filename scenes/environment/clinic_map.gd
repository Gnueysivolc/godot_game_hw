extends Node2D


func _ready():
	for box in get_tree().get_nodes_in_group("loot_box"):
		box.item_obtained.connect(_on_box_item_obtained)

func _on_box_item_obtained(texture):
	$inventoryUI.add_item(texture)
