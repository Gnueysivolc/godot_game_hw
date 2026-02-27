extends Control

@onready var easy_button: Button = $CenterContainer/Panel/VBoxContainer/Buttons/EasyButton
@onready var medium_button: Button = $CenterContainer/Panel/VBoxContainer/Buttons/MediumButton
@onready var hard_button: Button = $CenterContainer/Panel/VBoxContainer/Buttons/HardButton


func _ready() -> void:
	if not easy_button.pressed.is_connected(_on_easy_pressed):
		easy_button.pressed.connect(_on_easy_pressed)
	if not medium_button.pressed.is_connected(_on_medium_pressed):
		medium_button.pressed.connect(_on_medium_pressed)
	if not hard_button.pressed.is_connected(_on_hard_pressed):
		hard_button.pressed.connect(_on_hard_pressed)


func _on_easy_pressed() -> void:
	_start_game_with_difficulty("easy")


func _on_medium_pressed() -> void:
	_start_game_with_difficulty("medium")


func _on_hard_pressed() -> void:
	_start_game_with_difficulty("hard")


func _start_game_with_difficulty(difficulty_id: String) -> void:
	var ok: bool = Global.apply_difficulty_preset(difficulty_id)
	if not ok:
		push_warning("Could not apply difficulty: %s" % difficulty_id)
		return
	get_tree().change_scene_to_file("res://scenes/environment/clinic_map.tscn")
