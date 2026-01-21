extends CharacterBody2D

@export var MAX_SPEED := 150.0
@export var ACCELERATION := 400.0
@export var FRICTION := 700.0

var nearby_furniture: Node = null
var possessed_furniture: Node = null

func _physics_process(delta: float) -> void:
	# If possessing furniture, ghost does NOT move
	if possessed_furniture:
		velocity = Vector2.ZERO
		return

	var input_dir := Vector2.ZERO

	if Input.is_action_pressed("ui_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("ui_right"):
		input_dir.x += 1
	if Input.is_action_pressed("ui_up"):
		input_dir.y -= 1
	if Input.is_action_pressed("ui_down"):
		input_dir.y += 1

	input_dir = input_dir.normalized()

	if input_dir != Vector2.ZERO:
		velocity = velocity.move_toward(
			input_dir * MAX_SPEED,
			ACCELERATION * delta
		)
	else:
		velocity = velocity.move_toward(
			Vector2.ZERO,
			FRICTION * delta
		)

	move_and_slide()

func _input(event):
	if event.is_action_pressed("ui_accept"):
		# Unpossess
		if possessed_furniture:
			possessed_furniture.unpossess()
			possessed_furniture = null

		# Possess
		elif nearby_furniture:
			possessed_furniture = nearby_furniture
			possessed_furniture.possess()
