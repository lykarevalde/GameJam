extends CharacterBody2D

@export var speed := 60.0
@export var scared_speed := 120.0      # 👈 NEW
@export var scared_duration := 2.0     # 👈 NEW
@export var min_turn_time := 1.0
@export var max_turn_time := 3.0

@onready var path_follow := get_parent() as PathFollow2D
@onready var anim := $AnimatedSprite2D
@onready var turn_timer := $Timer
@onready var scared_timer := Timer.new()   # 👈 NEW

var direction := 1
var last_x := 0.0
var state := "normal"   # 👈 NEW

func _ready():
	randomize()
	direction = [-1, 1].pick_random()
	anim.play("walk")
	last_x = global_position.x

	start_turn_timer()

	# Setup scared timer
	scared_timer.one_shot = true
	add_child(scared_timer)
	scared_timer.timeout.connect(_on_scared_timeout)


func _physics_process(delta):
	if state == "scared":
		path_follow.progress += scared_speed * direction * delta
	else:
		path_follow.progress += speed * direction * delta

	# Reverse at path ends
	if path_follow.progress_ratio >= 1.0 and direction == 1:
		direction = -1
	elif path_follow.progress_ratio <= 0.0 and direction == -1:
		direction = 1

	# Flip based on movement
	var dx = global_position.x - last_x
	if abs(dx) > 0.01:
		anim.flip_h = dx < 0
	last_x = global_position.x


func start_turn_timer():
	turn_timer.wait_time = randf_range(min_turn_time, max_turn_time)
	turn_timer.start()


func _on_Timer_timeout():
	if state == "normal" and randf() < 0.5:
		direction *= -1

	start_turn_timer()


var scared := false

# 👻 CALLED BY GHOST
func on_scared():
	if scared:
		return

	scared = true
	print("[Human] SCARED:", name)
	anim.play("scared")

	# Stop movement by stopping progress
	speed = 0

	await get_tree().create_timer(1.5).timeout

	# Recover
	speed = 60
	anim.play("walk")
	scared = false


func _on_scared_timeout():
	state = "normal"
	anim.play("walk")
	start_turn_timer()
	print("Human calmed down:", name)
