extends CharacterBody2D

@export var speed := 80.0
@export var furniture_root: Node
@export var reach_distance := 10.0
@export var kid_detection_radius := 120.0
@export var furniture_cooldown_time := 4.0

var furniture_cooldowns := {} # furniture -> time left

@onready var anim := $AnimatedSprite2D

var target_furniture: Node = null
var last_furniture: Node = null
var state := "idle"

func _physics_process(delta):
	_update_cooldowns(delta)
	
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
	#for pf in human_npcs_root.get_children():
		#if pf.get_child_count() == 0:
			#continue
		#var kid = pf.get_child(0)
		#if kid.global_position.distance_to(target_furniture.global_position) < 100:
			#kid.on_scared()

func _on_furniture_finished(furniture):
	if furniture != target_furniture:
		return

	global_position = furniture.global_position
	
	furniture_cooldowns[furniture] = furniture_cooldown_time
	
	last_furniture = furniture
	target_furniture = null
	anim.visible = true
	state = "idle"

func pick_target():
	var best_furniture : Node2D = null
	var best_score := -INF

	for f in furniture_root.get_children():
		if not f.has_method("on_possessed"):
			continue
		if f == last_furniture:
			continue
		if f.possessor != f.PossessorType.NONE:
			continue
		if furniture_cooldowns.has(f):
			continue

		var score := 0.0

		# 1️⃣ Prefer furniture near kids
		score += _count_kids_near(f) * 5

		# 2️⃣ Prefer closer furniture
		score += max(0, 150 - global_position.distance_to(f.global_position)) / 10.0

		# 3️⃣ Add randomness so it’s not robotic
		score += randf_range(0, 3)

		if score > best_score:
			best_score = score
			best_furniture = f

	if best_furniture:
		target_furniture = best_furniture
		state = "moving"
	
	
func _update_cooldowns(delta):
	for f in furniture_cooldowns.keys():
		furniture_cooldowns[f] -= delta
		if furniture_cooldowns[f] <= 0:
			furniture_cooldowns.erase(f)
			
func _count_kids_near(furniture: Node) -> int:
	var count := 0
	for kid in get_tree().get_nodes_in_group("kids"):
		if kid.global_position.distance_to(furniture.global_position) <= kid_detection_radius:
			count += 1
	return count
