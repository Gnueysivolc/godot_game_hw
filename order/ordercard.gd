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
@export var face_by_length_easy: Texture2D
@export var face_by_length_medium: Texture2D
@export var face_by_length_hard: Texture2D
@export var time_color_normal: Color = Color(0.2, 0.9, 0.35, 1.0)
@export var time_color_warning: Color = Color(1.0, 0.8, 0.2, 1.0)
@export var time_color_danger: Color = Color(1.0, 0.2, 0.2, 1.0)

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
var resolved: bool = false
var base_face_texture: Texture2D

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
	resolved = false

	base_face_texture = _get_face_for_required_count(required.size())
	face.texture = base_face_texture
	time_bar.min_value = 0.0
	time_bar.max_value = duration
	time_bar.value = time_left
	_update_time_bar_color()

	_fill_slots()
	_update_visual()


func is_active() -> bool:
	return running and not locked and current_step < required.size()


func peek_expected_item() -> ItemTypes.ItemType:
	if not is_active():
		return ItemTypes.ItemType.NONE
	return required[current_step]


func get_time_left() -> float:
	return max(time_left, 0.0)


func get_required_count() -> int:
	return required.size()


func get_duration() -> float:
	return max(duration, 0.1)


# -----------------------
# PROCESS (TIMER)
# -----------------------

func _process(delta):
	if not running or resolved:
		return

	time_left -= delta
	time_bar.value = max(time_left, 0.0)
	_update_time_bar_color()

	if time_left <= 0:
		running = false
		resolved = true
		face.texture = face_sad
		_dim_all()
		timed_out.emit()


# -----------------------
# SUBMIT ITEM
# -----------------------

func submit_item(item_type: ItemTypes.ItemType) -> bool:

	if not running or locked or resolved:
		return false

	if current_step >= required.size():
		return false

	var expected: ItemTypes.ItemType = required[current_step]

	if item_type == expected:
		current_step += 1
		_update_visual()

		if current_step >= required.size():
			running = false
			resolved = true
			completed.emit()

		return true
	else:
		# Wrong items should not instantly fail/delete the order.
		# They are simply consumed by submit station and order remains active.
		return false


# -----------------------
# RESTART
# -----------------------

func restart():
	current_step = 0
	locked = false
	running = true
	resolved = false
	time_left = duration
	face.texture = base_face_texture
	time_bar.min_value = 0.0
	time_bar.max_value = duration
	time_bar.value = time_left
	_update_time_bar_color()
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


func _update_time_bar_color() -> void:
	var ratio: float = 0.0
	if duration > 0.0:
		ratio = clamp(time_left / duration, 0.0, 1.0)

	if ratio <= 0.5:
		time_bar.tint_progress = time_color_danger
	elif ratio <= 0.75:
		time_bar.tint_progress = time_color_warning
	else:
		time_bar.tint_progress = time_color_normal


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


func _get_face_for_required_count(item_count: int) -> Texture2D:
	# 1-2 -> normal, 3-4 -> sad, 5-6 -> very_sad
	if item_count >= 5:
		return _resolve_face_texture(face_by_length_hard, "res://order/very_sad.png")
	if item_count >= 3:
		return _resolve_face_texture(face_by_length_medium, "res://order/sad.png")
	return _resolve_face_texture(face_by_length_easy, "res://order/normal.png")


func _resolve_face_texture(exported_tex: Texture2D, fallback_path: String) -> Texture2D:
	if exported_tex != null:
		return exported_tex

	if ResourceLoader.exists(fallback_path):
		var loaded: Resource = load(fallback_path)
		if loaded is Texture2D:
			return loaded

	# Final fallback to current default face if dedicated files are not present yet.
	return face_normal
