extends Sprite2D

@export var move_distance := 50      # How far furniture moves left/right when possessed
@export var move_speed := 50         # Pixels/sec movement speed
@export var possession_time := 2.0   # Time furniture stays possessed


var possessed := false
var direction := 1                   # 1 = right, -1 = left
var original_pos := Vector2.ZERO
var possession_timer := 0.0

@onready var sprite = self


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	stop()
	frame = 0
	original_pos = global_position
	material.set_shader_parameter("thickness", 0.0)
	print("furniture ready")
	
	#pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# Haunted movement
	if possessed:
		# Move left/right
		global_position.x += direction * move_speed * delta
		
		# Reverse at limits
		if global_position.x > original_pos.x + move_distance:
			direction = -1
		elif global_position.x < original_pos.x - move_distance:
			direction = 1
		
		# Countdown possession timer
		possession_timer -= delta
		if possession_timer <= 0:
			on_possession_end()

func _on_area_2d_body_entered(body):
	if body.name == "Player":
		print(body.name, " entered")
		sprite.material.set_shader_parameter("thickness", 1.0)
	#pass # Replace with function body.

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		print(body.name, " exited")
		sprite.material.set_shader_parameter("thickness", 0.0)

# Called by Ghost when possessing
func on_possessed():
	possessed = true
	possession_timer = possession_time
	direction = [-1, 1].pick_random()  # randomize initial move direction
	play("shake")                        # optional shake animation
	print(name, " is now possessed!")


# Called automatically when possession ends
func on_possession_end():
	possessed = false
	global_position = original_pos       # snap back to original place
	play("idle")                         # return to idle animation
	print(name, " possession ended")
