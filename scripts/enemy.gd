extends CharacterBody2D

# --------------------------------------------------
# SETTINGS
# --------------------------------------------------
@export var speed := 80.0
@export var furniture_root: Node
@export var reach_distance := 10.0
# New: Drag your NPC container or Folder here in the Inspector
@export var npc_root: Node 

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

func _on_furniture_finished(furniture):
	if furniture != target_furniture:
		return

	global_position = furniture.global_position
	last_furniture = furniture
	target_furniture = null
	anim.visible = true
	state = "idle"

# --------------------------------------------------
# NEW SMART TARGETING LOGIC
# --------------------------------------------------
func pick_target():
	var best_furniture = null
	var max_npcs_nearby = -1 # Start at -1 so even 0 NPCs is a valid choice

	# 1. Get a list of all current NPCs in the "npcs" group
	var all_npcs = get_tree().get_nodes_in_group("npcs")

	# 2. Loop through every piece of furniture
	for f in furniture_root.get_children():
		if not f.has_method("on_possessed") or f == last_furniture:
			continue
		
		# 3. Count how many NPCs are within range of THIS furniture
		var npc_count = 0
		for npc in all_npcs:
			# Adjust '200' to change how far the ghost looks for NPCs
			if f.global_position.distance_to(npc.global_position) < 200.0:
				npc_count += 1
		
		# 4. If this furniture has more NPCs than our previous "best", save it
		if npc_count > max_npcs_nearby:
			max_npcs_nearby = npc_count
			best_furniture = f
		elif npc_count == max_npcs_nearby and best_furniture != null:
			# If there's a tie, 50% chance to switch to keep it varied
			if randf() > 0.5:
				best_furniture = f

	# 5. Set the winner as the target
	if best_furniture:
		target_furniture = best_furniture
		state = "moving"
