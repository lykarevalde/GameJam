extends Area2D

var nearby_ghost = null
@onready var sprite = $idle

func _on_body_entered(body):
	if body.is_in_group("ghost"):  # Assuming ghost is in "ghost" group
		nearby_ghost = body
		sprite.material.set_shader_parameter("thickness", 1.0)

func _on_body_exited(body):
	if body == nearby_ghost:
		nearby_ghost = null
		sprite.material.set_shader_parameter("thickness", 0.0)
