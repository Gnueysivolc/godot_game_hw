extends Panel

func set_texture(tex: Texture2D):
	var icon = get_node("TextureRect")
	icon.texture = tex
