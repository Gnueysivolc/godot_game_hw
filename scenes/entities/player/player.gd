extends CharacterBody2D

@export var speed: int = 400
var move_direction: Vector2 = Vector2.ZERO
var facing_direction: Vector2 = Vector2(0, 1)

@onready var anim: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	anim.play("down_idle")

func _physics_process(_delta: float) -> void:
	move_direction.x = int(Input.is_action_pressed("right")) - int(Input.is_action_pressed("left"))
	move_direction.y = int(Input.is_action_pressed("down")) - int(Input.is_action_pressed("up"))
	var motion: Vector2 = move_direction.normalized() * speed
	set_velocity(motion)
	move_and_slide()

	if motion != Vector2.ZERO:
		facing_direction = move_direction
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
		
		
		
		
		
		
