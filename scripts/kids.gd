extends CharacterBody2D

@export var speed := 50.0
@export var min_walk_time := 0.5
@export var max_walk_time := 1.0
@export var min_y := 200
@export var max_y := 300

var direction := 0
@onready var timer: Timer = $Timer

func _ready():
	randomize()
	choose_new_direction()

func _physics_process(delta):
	velocity.x = direction * speed
	move_and_slide()


	# Keep NPC on its floor
	if global_position.y < min_y:
		direction = 1
	elif global_position.y > max_y:
		direction = -1

func choose_new_direction():
	direction = [-1, 1].pick_random()  # always moves
	timer.wait_time = randf_range(min_walk_time, max_walk_time)
	timer.start()
