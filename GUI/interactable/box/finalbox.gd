extends Node2D

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var area: Area2D = $Area2D

var player_in_range := false
var current_player: Player = null


func _ready():
	anim.play("close")
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)


func _on_body_entered(body):
	print("entered:", body)

	if body is Player:
		print("player detected")
		player_in_range = true
		current_player = body
		body.interact_pressed.connect(_on_player_interact)


func _on_body_exited(body):
	print("exited:", body)

	if body is Player:
		player_in_range = false
		if current_player:
			current_player.interact_pressed.disconnect(_on_player_interact)
		current_player = null


func _on_player_interact():
	print("interact received")

	if not player_in_range:
		return

	if anim.is_playing():
		return

	anim.play("open_and_close")
