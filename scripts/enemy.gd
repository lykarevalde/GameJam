extends CharacterBody2D

@export var speed := 80.0                        
@export var human_npcs_root: Node               
@export var furniture_root: Node                
@export var reach_distance := 10.0              
@export var hide_duration := 1.0                # Fallback time if furniture has no signal

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var target_pos := Vector2.ZERO
var current_furniture: Node = null
var last_furniture: Node = null   # 👈 NEW
var state := "idle"  # "moving", "hiding", "idle"

# Furniture currently possessed by any ghost
static var currently_possessed := []

func _ready():
	randomize()
	print("[Ghost] Ready")
	pick_target()


func _physics_process(delta):
	match state:
		"moving":
			move_toward_target(delta)
		"hiding":
			pass
		"idle":
			pick_target()


func move_toward_target(delta):
	if target_pos == Vector2.ZERO or current_furniture == null:
		state = "idle"
		return

	var dir = (target_pos - global_position).normalized()
	velocity = dir * speed
	move_and_slide()

	anim.flip_h = velocity.x < 0
	anim.play("walk")

	if global_position.distance_to(target_pos) < reach_distance:
		print("[Ghost] Reached furniture:", current_furniture.name)
		await start_possession()


func start_possession() -> void:
	if current_furniture == null:
		state = "idle"
		return

	if current_furniture in currently_possessed:
		state = "idle"
		pick_target()
		return

	currently_possessed.append(current_furniture)

	if current_furniture.has_method("on_possessed"):
		current_furniture.call("on_possessed")
		print("[Ghost] Possessing:", current_furniture.name)

	for npc_follow in human_npcs_root.get_children():
		if npc_follow.get_child_count() == 0:
			continue
		var npc := npc_follow.get_child(0)
		print("[Ghost] Found human:", npc.name)
		if npc.global_position.distance_to(current_furniture.global_position) < 100:
			if npc.has_method("on_scared"):
				npc.call("on_scared")
				print("[Ghost] SCARED:", npc.name)
			else:
				print("[Ghost] ERROR: no on_scared() on", npc.name)

	anim.visible = false
	state = "hiding"

	if current_furniture.has_signal("possession_finished"):
		if not current_furniture.is_connected(
			"possession_finished",
			Callable(self, "_on_furniture_finished")
		):
			current_furniture.connect(
				"possession_finished",
				Callable(self, "_on_furniture_finished")
			)
	else:
		await get_tree().create_timer(hide_duration).timeout
		_on_furniture_finished()


func _on_furniture_finished() -> void:
	if current_furniture in currently_possessed:
		currently_possessed.erase(current_furniture)

	# 👈 remember last furniture
	last_furniture = current_furniture

	anim.visible = true
	current_furniture = null
	state = "idle"
	print("[Ghost] Reappeared, ready to possess new furniture")


func pick_target():
	if furniture_root == null:
		return

	var furniture_list = furniture_root.get_children()
	if furniture_list.is_empty():
		return

	var valid_targets := []

	for f in furniture_list:
		if not f.has_method("on_possessed"):
			continue
		if f in currently_possessed:
			continue
		if f == last_furniture:
			continue   # 👈 PREVENT CONSECUTIVE POSSESSION

		for npc_follow in human_npcs_root.get_children():
			var npc := npc_follow
			if npc.global_position.distance_to(f.global_position) < 100:
				valid_targets.append(f)
				break

	# If everything else is invalid, allow repossession except current
	if valid_targets.is_empty():
		for f in furniture_list:
			if f.has_method("on_possessed") \
			and f not in currently_possessed \
			and f != last_furniture:
				valid_targets.append(f)

	# Absolute fallback (only one furniture exists)
	if valid_targets.is_empty():
		for f in furniture_list:
			if f.has_method("on_possessed") and f not in currently_possessed:
				valid_targets.append(f)

	if valid_targets.is_empty():
		return

	current_furniture = valid_targets.pick_random()
	target_pos = current_furniture.global_position
	state = "moving"
	print("[Ghost] New target:", current_furniture.name)
