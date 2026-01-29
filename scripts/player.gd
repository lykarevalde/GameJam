# Player.gd
extends CharacterBody2D

@export var MAX_SPEED := 150.0
@export var ACCELERATION := 400.0
@export var FRICTION := 700.0

var nearby_furniture: Node = null
var possessed_furniture: Node = null
var last_direction := 1  # 1 = right, -1 = left

<<<<<<< Updated upstream
=======
@onready var camera: Camera2D = $Camera2D

# -----------------------------
# Energy System
# -----------------------------
const MAX_ENERGY := 6
var energy := MAX_ENERGY
var energy_timer := 0.0
const ENERGY_RESTORE_TIME := 10.0  # seconds per energy point

# Flash effect for empty energy
var flash_timer := 0.0
const FLASH_INTERVAL := 0.5  # flash every 0.5s

# -----------------------------
# HUD Energy Sprite
# -----------------------------
# Using find_child so it locates the sprite in your UI/CanvasLayer automatically
var energy_sprite: Sprite2D  

# Map energy level to texture files
var energy_textures: Dictionary = {
	6: preload("res://assets/energy sprites/full.png"),
	5: preload("res://assets/energy sprites/5.png"),
	4: preload("res://assets/energy sprites/4.png"),
	3: preload("res://assets/energy sprites/3.png"),
	2: preload("res://assets/energy sprites/2.png"),
	1: preload("res://assets/energy sprites/1.png"),
	0: preload("res://assets/energy sprites/empty.png")
}

>>>>>>> Stashed changes
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
			# MOVE CAMERA BACK TO PLAYER
			camera.reparent(self)
			camera.position = Vector2.ZERO
	
			show()
			$CollisionShape2D.disabled = false
		elif nearby_furniture:
			# Try to possess
			if nearby_furniture.possessor != nearby_furniture.PossessorType.NONE:
				print("Cannot possess! NPC already possessing.")
			
			else:
				possessed_furniture = nearby_furniture
				possessed_furniture.possess_by_player()
				
				# MOVE CAMERA TO FURNITURE
				camera.reparent(possessed_furniture)
				camera.position = Vector2.ZERO
		
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
