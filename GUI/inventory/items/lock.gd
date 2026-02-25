extends Panel

@export var lock_texture: Texture2D

func _ready():
	if lock_texture:
		$TextureRect.texture = lock_texture
		
		
