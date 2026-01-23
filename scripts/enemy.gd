extends CharacterBody2D

@export var speed := 80.0                        
@export var human_npcs_root: Node               # Parent node of human NPC PathFollow2D
@export var furniture_root: Node                # Parent node of all furniture
@export var reach_distance := 10.0              
@export var hide_duration := 1.0                # Fallback time if furniture has no signal

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var target_pos := Vector2.ZERO
var current_furniture: Node = null
var state := "idle"  # "moving", "hiding", "idle"

# Keep track of globally possessed furniture
static var possessed_furniture := []

func _ready():
	randomize()
	print("[Ghost] Ready")
	pick_target()

func _physics_process(delta):
	match state:
		"moving":
			move_toward_target(delta)
		"hiding":
			# waiting for furniture signal or await timer
			pass
		"idle":
			print("[Ghost] State idle, picking new target")
			pick_target()


# Move the ghost toward the furniture
func move_toward_target(delta):
	if target_pos == Vector2.ZERO or current_furniture == null:
		print("[Ghost] No target, switching to idle")
		state = "idle"
		return

	var dir = (target_pos - global_position).normalized()
	velocity = dir * speed
	move_and_slide()

	# Flip animation based on movement direction
	anim.flip_h = velocity.x < 0
	anim.play("walk")

	# Debug
	#print("[Ghost] Moving toward:", current_furniture.name,
	#	"Pos:", global_position,
	#	"Target:", target_pos,
	#	"Velocity:", velocity)

	# Check if reached furniture
	if global_position.distance_to(target_pos) < reach_distance:
		print("[Ghost] Reached furniture:", current_furniture.name)
		await start_possession()


# Called when ghost reaches furniture
func start_possession() -> void:
	if current_furniture == null:
		print("[Ghost] No furniture to possess!")
		state = "idle"
		return

	# Prevent double possession
	if current_furniture in possessed_furniture:
		print("[Ghost] Furniture already possessed:", current_furniture.name)
		state = "idle"
		pick_target()
		return

	possessed_furniture.append(current_furniture)

	# Call furniture's possession method
	if current_furniture.has_method("on_possessed"):
		current_furniture.call("on_possessed")
		print("[Ghost] Possessing:", current_furniture.name)
	else:
		print("[Ghost] Furniture has no on_possessed method:", current_furniture.name)

	# Scare nearby humans
	for npc_follow in human_npcs_root.get_children():
		var npc = npc_follow.get_child(0)  # PathFollow2D → HumanNPC
		if npc.global_position.distance_to(current_furniture.global_position) < 100:
			npc.call("on_scared")
			print("[Ghost] Scared human:", npc.name)

	# Hide ghost immediately
	anim.visible = false
	state = "hiding"

	# Wait for furniture signal OR fallback
	if current_furniture.has_signal("possession_finished"):
		if not current_furniture.is_connected("possession_finished", Callable(self, "_on_furniture_finished")):
			current_furniture.connect("possession_finished", Callable(self, "_on_furniture_finished"))
	else:
		# Fallback: wait hide_duration seconds using await
		await get_tree().create_timer(hide_duration).timeout
		_on_furniture_finished()


# Called when furniture finishes animation OR fallback timer
func _on_furniture_finished() -> void:
	# Reappear and pick a new target
	anim.visible = true
	current_furniture = null
	state = "idle"
	print("[Ghost] Reappeared after possessing, ready to find new furniture")


# Pick a new furniture target
func pick_target():
	if furniture_root == null:
		print("[Ghost] ERROR: furniture_root not assigned!")
		return

	var furniture_list = furniture_root.get_children()
	if furniture_list.size() == 0:
		print("[Ghost] No furniture found!")
		return

	var valid_targets := []

	# Only furniture nodes that have on_possessed() and are not already possessed
	for f in furniture_list:
		if not f.has_method("on_possessed"):
			continue
		if f in possessed_furniture:
			continue
		# Optional: only furniture near humans
		for npc_follow in human_npcs_root.get_children():
			var npc = npc_follow.get_child(0)
			if npc.global_position.distance_to(f.global_position) < 100:
				valid_targets.append(f)
				break

	if valid_targets.size() == 0:
		# Fallback: pick any unpossessed furniture
		var possible := []
		for f in furniture_list:
			if f.has_method("on_possessed") and f not in possessed_furniture:
				possible.append(f)
		if possible.size() == 0:
			print("[Ghost] No possessable furniture left!")
			current_furniture = null
			target_pos = Vector2.ZERO
			state = "idle"
			return
		current_furniture = possible[randi() % possible.size()]
	else:
		current_furniture = valid_targets[randi() % valid_targets.size()]

	target_pos = current_furniture.global_position
	state = "moving"
	print("[Ghost] New target:", current_furniture.name,
		"Target Pos:", target_pos,
		"State:", state)
