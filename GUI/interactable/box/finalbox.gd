extends Node2D

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var area: Area2D = $Area2D
@onready var sprite: Sprite2D = $Sprite2D
@onready var progress_bar: TextureProgressBar = $RespawnBar
@onready var exclamation: Sprite2D = $Exclamation

# 🔥 ENUM VERSION
signal item_obtained(item_type: ItemTypes.ItemType)

@export_enum(
	"NONE",
	"RED_PILL",
	"BLUE_PILL",
	"GREEN_PILL",
	"PURPLE_PILL",
	"RED_INJECTION",
	"BLUE_INJECTION",
	"GREEN_INJECTION",
	"PURPLE_INJECTION",
	"CLOVIS"
) var item_type: int = int(ItemTypes.ItemType.RED_PILL)

# Visual
@export var box_sprite: Texture2D

# Audio
@export var open_sound: AudioStream

# Animation
@export var open_animation_name: String = "open_and_close"
@export var no_cooldown: bool = false

# -----------------------
# STATE
# -----------------------

var current_player: Player = null
var player_in_range: bool = false
var is_ready: bool = true
var is_counting: bool = false
var is_animating: bool = false
var timer: float = 0.0
var float_time: float = 0.0

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

	if is_ready:
		float_time += delta
		exclamation.position.y = -20 + sin(float_time * 4.0) * 2.0

	if is_counting:
		if no_cooldown:
			is_counting = false
			is_ready = true
			progress_bar.visible = false
			exclamation.visible = true
			return

		timer += delta
		
		var respawn_time: float = max(Global.box_respawn_time, 0.1)
		var percent: float = (timer / respawn_time) * 100.0
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

		var tween = create_tween()
		tween.tween_property(sprite, "modulate", highlight_color, 0.15)


func _on_body_exited(body):
	if body is Player:
		player_in_range = false
		
		if current_player and current_player.interact_pressed.is_connected(_on_player_interact):
			current_player.interact_pressed.disconnect(_on_player_interact)
		
		current_player = null
		
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

	anim.play(open_animation_name)

	if open_sound:
		$AudioStreamPlayer2D.stream = open_sound
		$AudioStreamPlayer2D.play()

	print("item obtained:", item_type)

	# 🔥 EMIT ENUM, NOT TEXTURE
	emit_signal("item_obtained", item_type)

	if no_cooldown:
		is_ready = true
		is_counting = false
		timer = 0.0
		progress_bar.value = 0
		progress_bar.visible = false
		exclamation.visible = true
		return

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
	if anim_name == open_animation_name:
		is_animating = false
