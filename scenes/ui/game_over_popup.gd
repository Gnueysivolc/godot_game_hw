extends CanvasLayer
class_name GameOverPopup

@onready var panel: Panel = $Panel
@onready var title_label: Label = $Panel/VBoxContainer/TitleLabel
@onready var cured_label: Label = $Panel/VBoxContainer/CuredLabel
@onready var satisfaction_label: Label = $Panel/VBoxContainer/SatisfactionLabel
@onready var score_label: Label = $Panel/VBoxContainer/ScoreLabel
@onready var restart_button: Button = $Panel/VBoxContainer/RestartButton

var runtime_panel_style: StyleBoxFlat
var base_bg_color: Color = Color(0.08, 0.08, 0.1, 0.96)
var base_border_color: Color = Color(0.9, 0.9, 0.9, 1.0)
var win_color_tween: Tween


func _ready() -> void:
	visible = false
	if not restart_button.pressed.is_connected(_on_restart_pressed):
		restart_button.pressed.connect(_on_restart_pressed)
	var style: StyleBoxFlat = panel.get_theme_stylebox("panel") as StyleBoxFlat
	if style != null:
		runtime_panel_style = style.duplicate() as StyleBoxFlat
		base_bg_color = runtime_panel_style.bg_color
		base_border_color = runtime_panel_style.border_color
		panel.add_theme_stylebox_override("panel", runtime_panel_style)


func show_results(cured_patients: int, average_time_left_ratio: float, final_score: float) -> void:
	if win_color_tween and win_color_tween.is_running():
		win_color_tween.kill()
	restart_button.text = "Restart"

	var used_percent: float = clamp(average_time_left_ratio * 100.0, 0.0, 100.0)
	var satisfaction_percent: float = clamp(used_percent, 0.0, 100.0)
	var is_win: bool = final_score >= Global.win_score_threshold

	if is_win:
		print("YOU WIN!!!")
		title_label.text = "YOU WIN!!!"
		_start_win_background_loop()
	else:
		title_label.text = "Game Over"
		_apply_panel_colors(base_bg_color, base_border_color)

	cured_label.text = "Patients Cured: %d" % cured_patients
	satisfaction_label.text = "Patient Satisfaction: %.1f%% (average time left)" % [satisfaction_percent]
	score_label.text = "Final Score: %.1f" % final_score
	visible = true


func show_tutorial_completed() -> void:
	if win_color_tween and win_color_tween.is_running():
		win_color_tween.kill()
	_apply_panel_colors(base_bg_color, base_border_color)

	title_label.text = "Tutorial Finished"
	cured_label.text = "You finished tutorial."
	satisfaction_label.text = "Press Reset to return to the main menu."
	score_label.text = ""
	restart_button.text = "Reset"
	visible = true


func _start_win_background_loop() -> void:
	if runtime_panel_style == null:
		return

	var cycle_colors: Array[Color] = [
		Color(1.0, 0.25, 0.25, 0.96),
		Color(1.0, 0.65, 0.2, 0.96),
		Color(1.0, 0.95, 0.2, 0.96),
		Color(0.25, 0.9, 0.35, 0.96),
		Color(0.25, 0.7, 1.0, 0.96),
		Color(0.7, 0.4, 1.0, 0.96),
	]

	win_color_tween = create_tween()
	win_color_tween.set_loops()
	for color in cycle_colors:
		win_color_tween.set_parallel(true)
		win_color_tween.tween_property(runtime_panel_style, "bg_color", color, 0.45)
		win_color_tween.tween_property(runtime_panel_style, "border_color", color.lightened(0.35), 0.45)
		win_color_tween.set_parallel(false)


func _apply_panel_colors(bg: Color, border: Color) -> void:
	if runtime_panel_style == null:
		return
	runtime_panel_style.bg_color = bg
	runtime_panel_style.border_color = border


func _on_restart_pressed() -> void:
	if win_color_tween and win_color_tween.is_running():
		win_color_tween.kill()
	_apply_panel_colors(base_bg_color, base_border_color)

	if Global.has_method("flush_movement_input"):
		Global.flush_movement_input()

	var tree: SceneTree = get_tree()
	if tree == null:
		return
	tree.paused = false
	visible = false
	tree.change_scene_to_file("res://scenes/ui/start_screen.tscn")
