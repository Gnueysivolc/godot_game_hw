extends Panel

var item_type: ItemTypes.ItemType = ItemTypes.ItemType.NONE

var icon: TextureRect

@export var red_icon: Texture2D
@export var blue_icon: Texture2D
@export var green_icon: Texture2D
@export var purple_icon: Texture2D
@export var red_injection: Texture2D
@export var blue_injection: Texture2D
@export var purple_injection: Texture2D
@export var green_injection: Texture2D


func _ready():
	icon = $TextureRect


func set_item(type: ItemTypes.ItemType):

	item_type = type

	# ensure icon is ready
	if icon == null:
		icon = $TextureRect

	match type:
		ItemTypes.ItemType.RED_PILL:
			icon.texture = red_icon
		ItemTypes.ItemType.BLUE_PILL:
			icon.texture = blue_icon
		ItemTypes.ItemType.GREEN_PILL:
			icon.texture = green_icon
		ItemTypes.ItemType.PURPLE_PILL:
			icon.texture = purple_icon
		ItemTypes.ItemType.RED_INJECTION:
			icon.texture = red_injection
		ItemTypes.ItemType.GREEN_INJECTION:
			icon.texture = green_injection
		ItemTypes.ItemType.BLUE_INJECTION:
			icon.texture = blue_injection
		ItemTypes.ItemType.PURPLE_INJECTION:
			icon.texture = purple_injection
		_:
			icon.texture = null
