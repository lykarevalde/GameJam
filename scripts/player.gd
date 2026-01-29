extends CharacterBody2D

@export var MAX_SPEED := 150.0
@export var ACCELERATION := 400.0
@export var FRICTION := 700.0

var nearby_furniture: Node = null
var possessed_furniture: Node = null
var last_direction := 1  # 1 = right, -1 = left

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

@onready var sprite: AnimatedSprite2D = $face

func _ready():
	# Look for the EnergySprite in the entire active scene tree
	if not energy_sprite:
		energy_sprite = get_tree().root.find_child("EnergySprite", true, false)
		
	if energy_sprite:
		# Manual position code removed! Use Anchors in your Energy Scene instead.
		_update_energy_sprite()
	else:
		print("Warning: Player couldn't find EnergySprite in the scene tree!")

func _physics_process(delta: float) -> void:
	# Gradual energy restore
	if energy < MAX_ENERGY:
		energy_timer += delta
		if energy_timer >= ENERGY_RESTORE_TIME:
			energy += 1
			energy_timer = 0.0
			_update_energy_sprite()

	# Flash energy sprite if empty
	if energy == 0 and energy_sprite:
		flash_timer += delta
		if flash_timer >= FLASH_INTERVAL:
			energy_sprite.visible = not energy_sprite.visible
			flash_timer = 0.0
	elif energy_sprite:
		energy_sprite.visible = true

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
			if energy > 0:
				# Pass 'self' so furniture can call back to spend_energy()
				possessed_furniture.amuse(self) 
			else:
				print("Energy empty! Wait for recharge.")

# -----------------------------
# Energy Management
# -----------------------------
func spend_energy() -> void:
	energy -= 1
	energy_timer = 0.0  # Reset the 10s restore clock
	_update_energy_sprite()

func _update_energy_sprite() -> void:
	if energy_sprite and energy_textures.has(energy):
		energy_sprite.texture = energy_textures[energy]
		energy_sprite.visible = true

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
