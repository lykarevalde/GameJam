extends CharacterBody2D

@export var speed := 60.0
@export var min_turn_time := 1.0
@export var max_turn_time := 3.0

@onready var path_follow := get_parent() as PathFollow2D
@onready var anim := $AnimatedSprite2D
@onready var turn_timer := $Timer

var direction := 1
var last_x := 0.0

func _ready():
	randomize()
	direction = [-1, 1].pick_random()
	anim.play("walk")
	last_x = global_position.x

	start_turn_timer()

func _physics_process(delta):
	path_follow.progress += speed * direction * delta

	# Reverse at path ends (hard stop)
	if path_follow.progress_ratio >= 1.0 and direction == 1:
		direction = -1
	elif path_follow.progress_ratio <= 0.0 and direction == -1:
		direction = 1

	# Flip based on actual movement
	var dx = global_position.x - last_x
	if abs(dx) > 0.01:
		anim.flip_h = dx < 0
	last_x = global_position.x

func start_turn_timer():
	turn_timer.wait_time = randf_range(min_turn_time, max_turn_time)
	turn_timer.start()

func _on_Timer_timeout():
	# Randomly decide whether to turn around
	if randf() < 0.5:
		direction *= -1

	start_turn_timer()
