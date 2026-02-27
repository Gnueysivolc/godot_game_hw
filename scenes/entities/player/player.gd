class_name Player
extends CharacterBody2D

signal direction_changed(new_direction: Vector2)

signal interact_pressed

var speed: int = 0
var move_direction: Vector2 = Vector2.ZERO
var facing_direction: Vector2 = Vector2.ZERO
@onready var anim: AnimationPlayer = $AnimationPlayer

@onready var inventory_ui = get_parent().get_node("inventoryUI")



func _ready() -> void:
	speed = Global.player_move_speed
	facing_direction = Global.player_default_facing_direction
	anim.play("down_idle")

func _physics_process(_delta: float) -> void:
	speed = Global.player_move_speed
	if not DisplayServer.window_is_focused():
		move_direction = Vector2.ZERO
		set_velocity(Vector2.ZERO)
		play_idle()
		return

	move_direction.x = int(Input.is_action_pressed("right")) - int(Input.is_action_pressed("left"))
	move_direction.y = int(Input.is_action_pressed("down")) - int(Input.is_action_pressed("up"))
	var motion: Vector2 = move_direction.normalized() * speed
	set_velocity(motion)
	move_and_slide()

	if motion != Vector2.ZERO:
		var old_direction = facing_direction
		facing_direction = move_direction
		if facing_direction != old_direction:
			direction_changed.emit(facing_direction)
		play_walk()
	else:
		play_idle()

func play_walk() -> void:
	if facing_direction.y < 0:
		anim.play("walk_up")
	elif facing_direction.y > 0:
		anim.play("walk_down")
	elif facing_direction.x < 0:
		anim.play("walk_left")
	elif facing_direction.x > 0:
		anim.play("walk_right")

func play_idle() -> void:
	if facing_direction.y < 0:
		anim.play("up_idle")
	elif facing_direction.y > 0:
		anim.play("down_idle")
	elif facing_direction.x < 0:
		anim.play("left_idle")
	elif facing_direction.x > 0:
		anim.play("right_idle")


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		move_direction = Vector2.ZERO
		set_velocity(Vector2.ZERO)
		
		
		
# listen to keyboard events
func _input(event):

	# Keep inventory debug upgrade off the generic mouse click action so
	# UI button clicks don't accidentally add extra inventory slots.
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_U:
		print("Upgrade inventory by:", Global.debug_inventory_upgrade_amount)
		Global.increase_inventory_size(Global.debug_inventory_upgrade_amount)

	if event.is_action_pressed("interact"):
		interact_pressed.emit()
		
		
		
		

		
		
		
		
		
		
		
