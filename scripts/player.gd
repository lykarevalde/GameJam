extends CharacterBody2D

@export var MAX_SPEED := 150.0
@export var ACCELERATION := 400.0
@export var FRICTION := 700.0

var nearby_furniture: Node = null
var possessed_furniture: Node = null
var last_direction := 1  # 1 = right, -1 = left

@onready var sprite: AnimatedSprite2D = $face
@onready var camera: Camera2D = $Camera2D

func _physics_process(delta: float) -> void:
	# Smooth movement if not possessing
	if not possessed_furniture:
		var input_vector := Vector2(
			Input.get_axis("ui_left", "ui_right"),
			Input.get_axis("ui_up", "ui_down")
		).normalized()
		
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
	else:
		# Possessing furniture, player stops
		velocity = Vector2.ZERO
		sprite.play("face")
		move_and_slide()

	# Camera follow
	if possessed_furniture:
		camera.global_position = possessed_furniture.global_position
	else:
		camera.global_position = global_position

# -----------------------------
# Input handling
# -----------------------------
func _input(event):
	if Input.is_action_just_pressed("ui_accept"):  # SPACE
		if possessed_furniture:
			# Release furniture
			global_position = possessed_furniture.global_position
			possessed_furniture.unpossess_by_player()
			possessed_furniture = null
			show()
			$CollisionShape2D.disabled = false
		elif nearby_furniture and nearby_furniture.possessor == nearby_furniture.PossessorType.NONE:
			# Possess furniture
			possessed_furniture = nearby_furniture
			possessed_furniture.possess_by_player()
			hide()
			$CollisionShape2D.disabled = true

	if Input.is_action_just_pressed("amuse") and possessed_furniture:
		possessed_furniture.amuse(self)

# -----------------------------
# Detect furniture
# -----------------------------
func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("furniture"):
		nearby_furniture = body

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body == nearby_furniture:
		nearby_furniture = null
