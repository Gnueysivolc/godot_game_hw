extends Node2D

@onready var inventory_ui = $inventoryUI
@onready var order_card: OrderCard = $inventoryUI/Ordercard
@onready var submit_station: Node2D = $submit

@export var debug_time_limit: float = 15.0
@export var debug_order_sequence: Array[ItemTypes.ItemType] = [
	ItemTypes.ItemType.RED_PILL,
	ItemTypes.ItemType.BLUE_PILL,
	ItemTypes.ItemType.GREEN_PILL
]

func _ready():
	for box in get_tree().get_nodes_in_group("loot_box"):
		box.item_obtained.connect(_on_box_item_obtained)

	if submit_station and submit_station.has_signal("submit_requested"):
		if not submit_station.is_connected("submit_requested", Callable(self, "_on_submit_requested")):
			submit_station.connect("submit_requested", Callable(self, "_on_submit_requested"))

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("test"):
		_run_debug_order_test()


func _run_debug_order_test() -> void:
	if order_card == null:
		push_error("Ordercard node not found at /inventoryUI/Ordercard")
		return

	if debug_order_sequence.is_empty():
		push_warning("debug_order_sequence is empty; add at least 1 item in inspector.")
		return

	order_card.setup(debug_order_sequence, debug_time_limit)
	print("Debug order started:", debug_order_sequence)


func _on_box_item_obtained(item_type: ItemTypes.ItemType) -> void:
	inventory_ui.add_item(item_type)


func _on_submit_requested() -> void:
	inventory_ui.submit_top_item_to_order(order_card)
