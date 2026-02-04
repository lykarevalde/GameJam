extends Sprite2D

@export var margin := Vector2(20, 40)

func _process(_delta):
	if not texture:
		return

	var viewport_size = get_viewport().get_visible_rect().size
	var rect = get_rect().size

	position = Vector2(
		viewport_size.x - rect.x / 2 - margin.x,
		viewport_size.y - rect.y / 2 - margin.y
	)
