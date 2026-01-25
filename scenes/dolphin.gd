extends CharacterBody2D

@export var move_speed = 100.0

var is_possessed = false
var nearby_furniture: Node = null

@onready var sprite = $idle  # Toilet sprite
@onready var dolphin_sprite = $dolphin # Dolphin sprite

func _ready():
	velocity = Vector2.ZERO
	sprite.play("idle")
	sprite.material.set_shader_parameter("thickness", 0.0)
	if dolphin_sprite:
		dolphin_sprite.visible = false

@warning_ignore("unused_parameter")
func _physics_process(delta):
	if is_possessed:
		# Movement during possession
		var dir = Input.get_axis("ui_left", "ui_right")
		velocity.x = dir * move_speed


		# Check for DOWN key to trigger dolphin jump 
		if Input.is_action_just_pressed("animate"):
			trigger_dolphin_jump()

func possess():
	is_possessed = true
	sprite.play("dolphin")
	print("Furniture possessed!")

func unpossess():
	is_possessed = false
	velocity = Vector2.ZERO
	sprite.play("idle")
	if dolphin_sprite:
		dolphin_sprite.visible = false
		dolphin_sprite.stop()
	print("Possession ended!")

func trigger_dolphin_jump():
	if dolphin_sprite:
		sprite.hide()
		
		dolphin_sprite.stop()
		dolphin_sprite.frame = 0
		
		dolphin_sprite.visible = true
		dolphin_sprite.play("dolphin")  # Dolphin jump animation
		print("Dolphin jumps!")

func _on_area_2d_body_entered(body):
	if body.name == "Player":
		print(body.name, " entered")
		sprite.material.set_shader_parameter("thickness", 1.0)
	#pass # Replace with function body.

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		print(body.name, " exited")
		sprite.material.set_shader_parameter("thickness", 0.0)

func _on_dolphin_animation_finished() -> void:
	if dolphin_sprite:
		dolphin_sprite.visible = false
		dolphin_sprite.stop()
		dolphin_sprite.frame = 0
		dolphin_sprite.play("dolphin")
		sprite.visible = true 
		sprite.play("idle")
