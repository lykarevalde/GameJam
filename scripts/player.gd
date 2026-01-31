extends CharacterBody2D

# -----------------------------
# Movement
# -----------------------------
@export var MAX_SPEED: float = 150.0
@export var ACCELERATION: float = 400.0
@export var FRICTION: float = 700.0

var nearby_furniture: Node2D = null
var possessed_furniture: Node2D = null
var last_direction: int = 1  # 1 = right, -1 = left

@onready var sprite: AnimatedSprite2D = $face
@onready var camera: Camera2D = $Camera2D
@onready var collision: CollisionShape2D = $CollisionShape2D

# -----------------------------
# Energy System
# -----------------------------
const MAX_ENERGY: int = 6
const ENERGY_RESTORE_TIME: float = 6.0
const FLASH_INTERVAL: float = 0.5

var energy: int = MAX_ENERGY
var energy_timer: float = 0.0
var flash_timer: float = 0.0

# -----------------------------
# HUD Energy Sprite
# -----------------------------
@export var energy_sprite: Sprite2D

var energy_textures := {
	6: preload("res://assets/energy sprites/full.png"),
	5: preload("res://assets/energy sprites/5.png"),
	4: preload("res://assets/energy sprites/4.png"),
	3: preload("res://assets/energy sprites/3.png"),
	2: preload("res://assets/energy sprites/2.png"),
	1: preload("res://assets/energy sprites/1.png"),
	0: preload("res://assets/energy sprites/empty.png")
}

# -----------------------------
# Ready
# -----------------------------
func _ready() -> void:
	if energy_sprite:
		_update_energy_sprite()
	else:
		push_warning("Energy sprite not assigned in Player.gd")

# -----------------------------
# Physics
# -----------------------------
func _physics_process(delta: float) -> void:
	_handle_energy(delta)

	# -----------------
	# If possessing furniture, player stays still
	# -----------------
	if possessed_furniture:
		velocity = Vector2.ZERO
		sprite.play("face")
		move_and_slide()
		camera.global_position = possessed_furniture.global_position
		return

	# -----------------
	# Player Movement
	# -----------------
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
	camera.global_position = global_position

# -----------------------------
# Energy Handling
# -----------------------------
func _handle_energy(delta: float) -> void:
	# 1. Recharge if energy is less than MAX
	if energy < MAX_ENERGY:
		energy_timer += delta

		if energy_timer >= ENERGY_RESTORE_TIME:
			energy += 1  # Add one point instead of setting it to 1
			energy_timer = 0.0
			_update_energy_sprite()

	# 2. Flash HUD only when COMPLETELY empty
	if energy == 0 and energy_sprite:
		flash_timer += delta
		if flash_timer >= FLASH_INTERVAL:
			energy_sprite.visible = not energy_sprite.visible
			flash_timer = 0.0
	elif energy_sprite:
		energy_sprite.visible = true
# -----------------------------
# Input
# -----------------------------
func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		if possessed_furniture:
			_release_furniture()
		elif nearby_furniture and nearby_furniture.possessor == nearby_furniture.PossessorType.NONE:
			_possess_furniture()

	if Input.is_action_just_pressed("amuse") and possessed_furniture:
		if energy > 0:
			possessed_furniture.amuse(self)
		else:
			print("Energy empty! Wait for recharge.")

# -----------------------------
# Possession Helpers
# -----------------------------
func _possess_furniture() -> void:
	possessed_furniture = nearby_furniture
	possessed_furniture.possess_by_player()
	hide()
	collision.disabled = true

func _release_furniture() -> void:
	global_position = possessed_furniture.global_position
	possessed_furniture.unpossess_by_player()
	possessed_furniture = null
	show()
	collision.disabled = false

# -----------------------------
# Energy API (called by furniture)
# -----------------------------
func spend_energy() -> void:
	energy = max(energy - 1, 0)
	energy_timer = 0.0
	_update_energy_sprite()

func _update_energy_sprite() -> void:
	if energy_sprite and energy_textures.has(energy):
		energy_sprite.texture = energy_textures[energy]
		energy_sprite.visible = true

# -----------------------------
# Furniture Detection
# -----------------------------
func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("furniture"):
		nearby_furniture = body
		print("Near furniture:", body.name)

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body == nearby_furniture:
		nearby_furniture = null
		print("Left furniture:", body.name)
