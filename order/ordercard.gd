extends Panel
class_name OrderCard

signal completed
signal failed
signal timed_out

# -----------------------
# NODES
# -----------------------

@onready var face: TextureRect = $face
@onready var time_bar: TextureProgressBar = $TextureProgressBar
@onready var slots: Array[TextureRect] = []

func _ready():
	slots.clear()
	for child in $HBoxContainer.get_children():
		if child is TextureRect:
			slots.append(child)
# -----------------------
# ICONS
# -----------------------

@export var red_icon: Texture2D
@export var blue_icon: Texture2D
@export var green_icon: Texture2D
@export var purple_icon: Texture2D
@export var red_injection_icon: Texture2D
@export var blue_injection_icon: Texture2D
@export var green_injection_icon: Texture2D
@export var purple_injection_icon: Texture2D

@export var face_normal: Texture2D
@export var face_sick: Texture2D
@export var face_sad: Texture2D

# -----------------------
# ORDER DATA
# -----------------------

var required: Array[ItemTypes.ItemType] = []
var current_step: int = 0

# -----------------------
# TIMER
# -----------------------

var duration: float = 10.0
var time_left: float = 0.0
var running: bool = false
var locked: bool = false

# -----------------------
# SETUP ORDER
# -----------------------

func setup(sequence: Array[ItemTypes.ItemType], time_limit: float):
	required = sequence.duplicate()   # duplicate for safety
	if required.size() > slots.size():
		required.resize(slots.size())
	duration = max(time_limit, 0.1)
	time_left = duration
	current_step = 0
	running = true
	locked = false

	face.texture = face_normal
	time_bar.min_value = 0.0
	time_bar.max_value = duration
	time_bar.value = time_left

	_fill_slots()
	_update_visual()


func is_active() -> bool:
	return running and not locked and current_step < required.size()


func peek_expected_item() -> ItemTypes.ItemType:
	if not is_active():
		return ItemTypes.ItemType.NONE
	return required[current_step]


# -----------------------
# PROCESS (TIMER)
# -----------------------

func _process(delta):
	if not running:
		return

	time_left -= delta
	time_bar.value = max(time_left, 0.0)

	if time_left <= 0:
		running = false
		face.texture = face_sad
		_dim_all()
		timed_out.emit()


# -----------------------
# SUBMIT ITEM
# -----------------------

func submit_item(item_type: ItemTypes.ItemType) -> bool:

	if not running or locked:
		return false

	if current_step >= required.size():
		return false

	var expected: ItemTypes.ItemType = required[current_step]

	if item_type == expected:
		current_step += 1
		_update_visual()

		if current_step >= required.size():
			running = false
			completed.emit()

		return true
	else:
		locked = true
		face.texture = face_sick
		_dim_all()
		failed.emit()
		return false


# -----------------------
# RESTART
# -----------------------

func restart():
	current_step = 0
	locked = false
	running = true
	time_left = duration
	face.texture = face_normal
	time_bar.min_value = 0.0
	time_bar.max_value = duration
	time_bar.value = time_left
	_update_visual()


# -----------------------
# VISUAL
# -----------------------

func _fill_slots():
	for i in range(slots.size()):
		if i < required.size():
			slots[i].texture = _get_icon(required[i])
			slots[i].visible = true
		else:
			slots[i].visible = false


func _update_visual():
	var count: int = min(required.size(), slots.size())
	for i in range(count):
		if i < current_step:
			slots[i].modulate = Color(1, 1, 1)
		elif i == current_step:
			slots[i].modulate = Color(1.3, 1.3, 1.3)
		else:
			slots[i].modulate = Color(0.4, 0.4, 0.4)


func _dim_all():
	for slot in slots:
		slot.modulate = Color(0.2, 0.2, 0.2)


func _get_icon(type: ItemTypes.ItemType) -> Texture2D:
	match type:
		ItemTypes.ItemType.RED_PILL:
			return red_icon
		ItemTypes.ItemType.BLUE_PILL:
			return blue_icon
		ItemTypes.ItemType.GREEN_PILL:
			return green_icon
		ItemTypes.ItemType.PURPLE_PILL:
			return purple_icon
		ItemTypes.ItemType.RED_INJECTION:
			return red_injection_icon
		ItemTypes.ItemType.BLUE_INJECTION:
			return blue_injection_icon
		ItemTypes.ItemType.GREEN_INJECTION:
			return green_injection_icon
		ItemTypes.ItemType.PURPLE_INJECTION:
			return purple_injection_icon
		_:
			return null
