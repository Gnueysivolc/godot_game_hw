extends Node2D

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var area: Area2D = $Area2D
@onready var sprite: Sprite2D = $Sprite2D
@onready var exclamation: Sprite2D = $Exclamation

signal submit_requested

# Visual
@export var box_sprite: Texture2D

# Audio
@export var open_sound: AudioStream

# Animation
@export var open_animation_name: String = "open_and_close"

# -----------------------
# STATE
# -----------------------

var current_player: Player = null
var float_time := 0.0

# -----------------------
# VISUAL SETTINGS
# -----------------------

var normal_color: Color = Color(1,1,1,1)
var highlight_color: Color = Color(1.3,1.3,1.3,1)

# -----------------------
# READY
# -----------------------

func _ready():

	if box_sprite:
		sprite.texture = box_sprite

	anim.play("close")

	exclamation.visible = false

	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
	anim.animation_finished.connect(_on_animation_finished)

# -----------------------
# PROCESS
# -----------------------

func _process(delta):
	float_time += delta
	exclamation.position.y = -20 + sin(float_time * 4.0) * 2.0

# -----------------------
# PLAYER ENTER / EXIT
# -----------------------

func _on_body_entered(body):
	if body is Player:
		current_player = body
		
		if not body.interact_pressed.is_connected(_on_player_interact):
			body.interact_pressed.connect(_on_player_interact)

		var tween = create_tween()
		tween.tween_property(sprite, "modulate", highlight_color, 0.15)


func _on_body_exited(body):
	if body is Player:
		if current_player and current_player.interact_pressed.is_connected(_on_player_interact):
			current_player.interact_pressed.disconnect(_on_player_interact)
		
		current_player = null
		
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", normal_color, 0.15)

# -----------------------
# INTERACT
# -----------------------

func _on_player_interact():
	anim.play(open_animation_name)
	emit_signal("submit_requested")

# -----------------------
# ANIMATION FINISHED
# -----------------------

func _on_animation_finished(anim_name):
	if anim_name == open_animation_name:
		anim.play("close")
