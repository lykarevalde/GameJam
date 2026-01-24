extends CharacterBody2D

@export var speed := 80.0
@export var human_npcs_root: Node
@export var furniture_root: Node
@export var reach_distance := 10.0

@onready var anim := $AnimatedSprite2D

var target_furniture: Node = null
var last_furniture: Node = null
var state := "idle"

func _physics_process(delta):
	match state:
		"idle":
			pick_target()
		"moving":
			move_to_target(delta)

func move_to_target(delta):
	if not is_instance_valid(target_furniture):
		state = "idle"
		return

	var dir = (target_furniture.global_position - global_position).normalized()
	velocity = dir * speed
	move_and_slide()

	if velocity.x < 0:
		anim.play("left")
	elif velocity.x > 0:
		anim.play("right")

	if global_position.distance_to(target_furniture.global_position) <= reach_distance:
		try_possess()

func try_possess():
	if not target_furniture.on_possessed():
		state = "idle"
		return

	anim.visible = false
	state = "hiding"

	target_furniture.possession_finished.connect(
		_on_furniture_finished,
		CONNECT_ONE_SHOT
	)

	# scare humans
	for pf in human_npcs_root.get_children():
		if pf.get_child_count() == 0:
			continue
		var kid = pf.get_child(0)
		if kid.global_position.distance_to(target_furniture.global_position) < 100:
			kid.on_scared()

func _on_furniture_finished(furniture):
	if furniture != target_furniture:
		return

	global_position = furniture.global_position
	
	last_furniture = furniture
	target_furniture = null
	anim.visible = true
	state = "idle"

func pick_target():
	var choices := []

	for f in furniture_root.get_children():
		if not f.has_method("on_possessed"):
			continue
		if f == last_furniture:
			continue
		choices.append(f)

	if choices.is_empty():
		return

	target_furniture = choices.pick_random()
	state = "moving"
