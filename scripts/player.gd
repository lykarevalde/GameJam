# Player.gd
extends CharacterBody2D

@export var MAX_SPEED := 150.0
@export var ACCELERATION := 400.0
@export var FRICTION := 700.0

var nearby_furniture: Node = null
var possessed_furniture: Node = null
var last_direction := 1  # 1 = right, -1 = left

@onready var sprite: AnimatedSprite2D = $face

func _physics_process(delta: float) -> void:
	# If possessing furniture, the player doesn't move
	if possessed_furniture:
		velocity = Vector2.ZERO
		sprite.play("face")
		move_and_slide()
		return

	var input_vector := Vector2.ZERO

	if Input.is_action_pressed("ui_right"):
		input_vector.x += 1
	if Input.is_action_pressed("ui_left"):
		input_vector.x -= 1
	if Input.is_action_pressed("ui_down"):
		input_vector.y += 1
	if Input.is_action_pressed("ui_up"):
		input_vector.y -= 1

	input_vector = input_vector.normalized()

	# Smooth movement
	velocity.x = move_toward(velocity.x, input_vector.x * MAX_SPEED, ACCELERATION * delta)
	velocity.y = move_toward(velocity.y, input_vector.y * MAX_SPEED, ACCELERATION * delta)

	# Animations
	if input_vector.x > 0:
		last_direction = 1
		sprite.play("right")
	elif input_vector.x < 0:
		last_direction = -1
		sprite.play("left")
	else:
		sprite.play("face")

	move_and_slide()

# -----------------------------
# Input handling
# -----------------------------
func _input(event):
	if Input.is_action_just_pressed("ui_accept"):  # SPACE
		if possessed_furniture:
			global_position = possessed_furniture.global_position
			# Unpossess
			possessed_furniture.unpossess_by_player()
			possessed_furniture = null
			show()
			$CollisionShape2D.disabled = false
		elif nearby_furniture:
			# Try to possess
			if nearby_furniture.possessor != nearby_furniture.PossessorType.NONE:
				print("Cannot possess! NPC already possessing.")
			
			else:
				possessed_furniture = nearby_furniture
				possessed_furniture.possess_by_player()
				hide()
				$CollisionShape2D.disabled = true
	# E key for amuse
	if Input.is_action_just_pressed("amuse"):
		if possessed_furniture:
			possessed_furniture.amuse()
			

# -----------------------------
# Detect furniture
# -----------------------------
func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("furniture"):
		nearby_furniture = body
		print("Near furniture:", body.name)

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body == nearby_furniture:
		nearby_furniture = null
		print("Left furniture:", body.name)
