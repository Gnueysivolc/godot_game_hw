extends Node

@onready var order_card: OrderCard = $Ordercard2


func _ready() -> void:
	print("TEST SCRIPT READY")
	randomize()

	if order_card == null:
		push_error("Ordercard2 not found!")
		return

	# Create properly typed sequence
	var sequence: Array[ItemTypes.ItemType] = [
		ItemTypes.ItemType.RED_PILL,
		ItemTypes.ItemType.BLUE_PILL,
		ItemTypes.ItemType.GREEN_PILL
	]

	order_card.setup(sequence, 15.0)

	# Connect signals safely (avoid duplicate connections)
	if not order_card.completed.is_connected(_on_completed):
		order_card.completed.connect(_on_completed)

	if not order_card.failed.is_connected(_on_failed):
		order_card.failed.connect(_on_failed)

	if not order_card.timed_out.is_connected(_on_timeout):
		order_card.timed_out.connect(_on_timeout)


func _process(_delta: float) -> void:
	# Press T → submit random pill
	if Input.is_action_just_pressed("test"):
		_submit_random()


func _submit_random() -> void:
	var pool: Array[ItemTypes.ItemType] = [
		ItemTypes.ItemType.RED_PILL,
		ItemTypes.ItemType.BLUE_PILL,
		ItemTypes.ItemType.GREEN_PILL
	]

	var item: ItemTypes.ItemType = pool.pick_random()

	print("Submitting:", item)

	if order_card:
		order_card.submit_item(item)


func _on_completed() -> void:
	print("ORDER COMPLETED 🎉")


func _on_failed() -> void:
	print("ORDER FAILED ❌")


func _on_timeout() -> void:
	print("ORDER TIMED OUT ⏰")
