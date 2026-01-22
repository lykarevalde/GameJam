extends AnimatedSprite2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	stop()
	frame = 0
	material.set_shader_parameter("thickness", 0.0)
	print("furniture ready")
	
	#pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

@onready var sprite = self

func _on_area_2d_body_entered(body):
	if body.name == "Player":
		print(body.name, " entered")
		sprite.material.set_shader_parameter("thickness", 1.0)
	#pass # Replace with function body.

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		print(body.name, " exited")
		sprite.material.set_shader_parameter("thickness", 0.0)
