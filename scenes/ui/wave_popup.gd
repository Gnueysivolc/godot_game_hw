extends CanvasLayer
class_name WavePopup

signal buff_chosen(buff_id: String)

@onready var panel: Panel = $Panel
@onready var title_label: Label = $Panel/VBoxContainer/TitleLabel
@onready var target_label: Label = $Panel/VBoxContainer/TargetLabel
@onready var timer_label: Label = $Panel/VBoxContainer/TimerLabel
@onready var time_buff_button: Button = $Panel/VBoxContainer/Buttons/TimeBuffButton
@onready var box_buff_button: Button = $Panel/VBoxContainer/Buttons/BoxBuffButton
@onready var speed_buff_button: Button = $Panel/VBoxContainer/Buttons/SpeedBuffButton
@onready var inventory_buff_button: Button = $Panel/VBoxContainer/Buttons/InventoryBuffButton
@onready var life_buff_button: Button = $Panel/VBoxContainer/Buttons/LifeBuffButton


func _ready() -> void:
	visible = false
	if not time_buff_button.pressed.is_connected(_on_time_buff_pressed):
		time_buff_button.pressed.connect(_on_time_buff_pressed)
	if not box_buff_button.pressed.is_connected(_on_box_buff_pressed):
		box_buff_button.pressed.connect(_on_box_buff_pressed)
	if not speed_buff_button.pressed.is_connected(_on_speed_buff_pressed):
		speed_buff_button.pressed.connect(_on_speed_buff_pressed)
	if not inventory_buff_button.pressed.is_connected(_on_inventory_buff_pressed):
		inventory_buff_button.pressed.connect(_on_inventory_buff_pressed)
	if not life_buff_button.pressed.is_connected(_on_life_buff_pressed):
		life_buff_button.pressed.connect(_on_life_buff_pressed)


func show_popup(wave: int, target_score: float, game_time_left: float) -> void:
	title_label.text = "Wave %d Cleared" % wave
	target_label.text = "Target Score: %.1f" % target_score
	timer_label.text = "Time Left: %s" % _format_time(game_time_left)
	visible = true


func hide_popup() -> void:
	visible = false


func update_timer_label(game_time_left: float) -> void:
	timer_label.text = "Time Left: %s" % _format_time(game_time_left)


func _on_time_buff_pressed() -> void:
	buff_chosen.emit("more_time")


func _on_box_buff_pressed() -> void:
	buff_chosen.emit("faster_boxes")


func _on_speed_buff_pressed() -> void:
	buff_chosen.emit("faster_player")


func _on_inventory_buff_pressed() -> void:
	buff_chosen.emit("inventory_up")


func _on_life_buff_pressed() -> void:
	buff_chosen.emit("life_up")


func _format_time(total_seconds: float) -> String:
	var clamped: int = max(int(ceil(total_seconds)), 0)
	var mins: int = clamped / 60
	var secs: int = clamped % 60
	return "%02d:%02d" % [mins, secs]
