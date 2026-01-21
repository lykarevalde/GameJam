extends CharacterBody2D

@export var MOVE_SPEED := 180.0

var is_possessed := false

func possess():
	is_possessed = true

func unpossess():
	is_possessed = false
	velocity = Vector2.ZERO

@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void:
	if not is_possessed:
		return

	var input_dir := 0

	# Left / Right movement
	if Input.is_action_pressed("ui_left"):
		input_dir -= 1
	if Input.is_action_pressed("ui_right"):
		input_dir += 1

	# Heavier horizontal movement (feels like furniture)
	var target_speed := input_dir * MOVE_SPEED
	velocity.x = move_toward(velocity.x, target_speed, MOVE_SPEED * 4)

	# TEMP: float up for testing possession
	if Input.is_action_pressed("ui_up"):
		velocity.y = -MOVE_SPEED
	else:
		velocity.y = move_toward(velocity.y, 0, MOVE_SPEED * 2)

	move_and_slide()
