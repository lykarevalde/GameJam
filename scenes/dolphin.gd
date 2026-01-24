extends CharacterBody2D

@export var move_speed = 100.0
@export var possession_time = 2

var nearby_furniture: Node = null
var is_possessed = false
var possession_timer = 0.0
var nearby_ghost = null
var dolphin_jumped = false

@onready var sprite = $idle
@onready var dolphin_sprite = $dolphin  

func possess():
	is_possessed = true
	possession_timer = possession_time
	dolphin_jumped = false
	dolphin_sprite.play("dolphin")
	print("Toilet possessed – dolphin jumps!")
	
func unpossess():
	is_possessed = false
	dolphin_jumped = false
	sprite.play("idle")
	velocity = Vector2.ZERO
	if dolphin_sprite:
		dolphin_sprite.visible = false
		dolphin_sprite.stop()
	print("Possession ended!")
	

func _physics_process(delta):
	if is_possessed:
		# Movement during possession
		var dir = Input.get_axis("ui_left", "ui_right")
		velocity.x = dir * move_speed
		move_and_slide()

		# Countdown possession
		possession_timer -= delta
		if possession_timer <= 0:
			unpossess()

		# Check for DOWN key to trigger dolphin jump
		if Input.is_action_just_pressed("ui_down") and not dolphin_jumped:
			trigger_dolphin_jump()

func _ready():
	sprite.play("idle")  # Start with idle animation
	self.material = material

func _process(delta):
	if is_possessed:
		possession_timer -= delta
		if possession_timer <= 0:
			unpossess()

func trigger_dolphin_jump():
	dolphin_jumped = true  # Prevent repeat
	if dolphin_sprite:
		dolphin_sprite.visible = true
		dolphin_sprite.play("jump")  # Dolphin jump animation
		print("Dolphin jumps!")

func _on_area_2d_body_entered(body: Node) -> void:
	if body.is_in_group("furniture"):
		nearby_furniture = body
		print("Ghost is near:", body.name)

func _on_area_2d_body_exited(body: Node) -> void:
	if body == nearby_furniture:
		print("Ghost walked away from:", body.name)
		nearby_furniture = null

func highlight(on: bool):
	if on:
		sprite.material.set_shader_parameter("thickness", 1.0)  # Glow
	else:
		sprite.material.set_shader_parameter("thickness", 0.0)
