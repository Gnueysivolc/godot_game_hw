extends Camera2D

func _ready() -> void:
	zoom = Vector2(3, 3)  # Zoom in (adjust as needed)
	enabled = true
	
	# Set limits to your room bounds - adjust these to YOUR wall positions
	limit_left = -0
	limit_right = 1050
	limit_top = 2
	limit_bottom = 590
	
	limit_smoothed = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


# In your player's _ready() or directly on the Camera2D node
