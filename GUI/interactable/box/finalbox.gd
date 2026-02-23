extends Node2D

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var area: Area2D = $Area2D
@onready var sprite: Sprite2D = $Sprite2D
@onready var progress_bar: TextureProgressBar = $RespawnBar
@onready var exclamation: Sprite2D = $Exclamation

# -----------------------
# CONFIG
# -----------------------

var respawn_time := 5.0

# -----------------------
# STATE
# -----------------------

var current_player: Player = null
var player_in_range := false
var is_ready := true
var is_counting := false
var is_animating := false
var timer := 0.0
var float_time := 0.0

# -----------------------
# VISUAL SETTINGS
# -----------------------

var normal_color := Color(1,1,1,1)
var highlight_color := Color(1.3,1.3,1.3,1)

# -----------------------
# READY
# -----------------------

func _ready():
	anim.play("close")

	progress_bar.visible = false
	progress_bar.value = 0

	exclamation.visible = true

	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
	anim.animation_finished.connect(_on_animation_finished)


# -----------------------
# PROCESS
# -----------------------

func _process(delta):

	# floating exclamation effect
	if is_ready:
		float_time += delta
		exclamation.position.y = -20 + sin(float_time * 4.0) * 2.0

	# cooldown logic
	if is_counting:
		timer += delta
		
		var percent := (timer / respawn_time) * 100.0
		progress_bar.value = percent
		
		if timer >= respawn_time:
			is_counting = false
			is_ready = true
			progress_bar.visible = false
			exclamation.visible = true


# -----------------------
# PLAYER ENTER / EXIT
# -----------------------

func _on_body_entered(body):
	if body is Player:
		player_in_range = true
		current_player = body
		
		if not body.interact_pressed.is_connected(_on_player_interact):
			body.interact_pressed.connect(_on_player_interact)

		# brighten
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", highlight_color, 0.15)


func _on_body_exited(body):
	if body is Player:
		player_in_range = false
		
		if current_player and current_player.interact_pressed.is_connected(_on_player_interact):
			current_player.interact_pressed.disconnect(_on_player_interact)
		
		current_player = null
		
		# return color
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", normal_color, 0.15)


# -----------------------
# INTERACT
# -----------------------

func _on_player_interact():

	if not is_ready:
		return
		
	if is_animating:
		return

	is_animating = true
	anim.play("open_and_close")

	print("item obtained!")

	# start cooldown
	is_ready = false
	is_counting = true
	timer = 0.0

	progress_bar.value = 0
	progress_bar.visible = true
	exclamation.visible = false


# -----------------------
# ANIMATION FINISHED
# -----------------------

func _on_animation_finished(anim_name):
	if anim_name == "open_and_close":
		is_animating = false
