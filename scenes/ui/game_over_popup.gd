extends CanvasLayer
class_name GameOverPopup

@onready var title_label: Label = $Panel/VBoxContainer/TitleLabel
@onready var cured_label: Label = $Panel/VBoxContainer/CuredLabel
@onready var satisfaction_label: Label = $Panel/VBoxContainer/SatisfactionLabel
@onready var score_label: Label = $Panel/VBoxContainer/ScoreLabel


func _ready() -> void:
	visible = false


func show_results(cured_patients: int, average_time_left_ratio: float, final_score: float) -> void:
	var used_percent: float = clamp(average_time_left_ratio * 100.0, 0.0, 100.0)
	var satisfaction_percent: float = clamp(used_percent, 0.0, 100.0)

	title_label.text = "Game Over"
	cured_label.text = "Patients Cured: %d" % cured_patients
	satisfaction_label.text = "Patient Satisfaction: %.1f%% (average time left)" % [satisfaction_percent]
	score_label.text = "Final Score: %.1f" % final_score
	visible = true
