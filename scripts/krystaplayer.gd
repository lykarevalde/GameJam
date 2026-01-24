extends CharacterBody2D

@export var MAX_SPEED := 150.0
@export var ACCELERATION := 400.0
@export var FRICTION := 700.0

var nearby_furniture: Node = null
var possessed_furniture: Node = null

@onready var sprite = $idle


func _physics_process(delta: float) -> void:
	# If possessing furniture, ghost does NOT move
	if possessed_furniture:
		velocity = Vector2.ZERO
		move_and_slide()
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
	if event.is_action_pressed("ui_accept"):  # SPACE
		if possessed_furniture:
		   # Release furniture
			possessed_furniture = null            
			show()
			$CollisionShape2D.disabled = false
		elif nearby_furniture:
			# Possess
			possessed_furniture = nearby_furniture
			possessed_furniture.possess()
			hide()
			$CollisionShape2D.disabled = true


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("furniture"): 
		nearby_furniture = body
		print("Ghost is near:", body.name)


func _on_area_2d_body_exited(body: Node2D) -> void:
	# Check if the body leaving the Area2D is furniture
	if body.is_in_group("furniture"):
		# Only clear nearby_furniture if it was this one
		if nearby_furniture == body:
			nearby_furniture = null
			print("Ghost walked away from:", body.name)
