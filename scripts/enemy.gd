extends CharacterBody2D

@export var speed := 50.0
@export var min_walk_time := 1.0
@export var max_walk_time := 3.0

var direction := 0   # -1 = left, 1 = right, 0 = idle

@onready var timer: Timer = $Timer

func _ready():
	randomize()
	choose_new_direction()

func _physics_process(delta):
	velocity.x = direction * speed
	move_and_slide()

func choose_new_direction():
	# Randomly choose left, right, or stop
	direction = [-1, 0, 1].pick_random()

	# Random time before changing direction again
	timer.wait_time = randf_range(min_walk_time, max_walk_time)
	timer.start()

func _on_Timer_timeout():
	choose_new_direction()
