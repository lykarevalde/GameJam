extends CharacterBody2D

# --------------------------------------------------
# SETTINGS
# --------------------------------------------------
@export var speed := 60.0
@export var loiter_points_path: NodePath # Path to the container of Area2Ds

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var path_follow: PathFollow2D = get_parent()

# --------------------------------------------------
# STATE
# --------------------------------------------------
enum State { WALKING, IDLE, USING_STAIRS, REACT }
var state := State.WALKING

var walk_direction := 1.0
var stair_cooldown := false
var loiter_timer := 0.0

var _reaction_timer: SceneTreeTimer = null  # store the async timer

# Reaction system
var consecutive_spooks := 0
var consecutive_amuses := 0
var is_befriended := false

# --------------------------------------------------
# READY
# --------------------------------------------------
func _ready():
	# 1. Animation Setup
	if anim:
		if anim.material:
			anim.material = anim.material.duplicate()
		anim.animation_finished.connect(_on_anim_finished)

	# 2. Furniture Reactions (Signal Safety Check)
	# Connects to signals from furniture group nodes safely
	for f in get_tree().get_nodes_in_group("furniture"):
		if f.has_signal("spooked"):
			f.spooked.connect(_on_spooked)
		if f.has_signal("amused"):
			f.amused.connect(_on_amused)
		else:
			push_warning("Node " + f.name + " is in 'furniture' group but lacks custom signals.")

	# 3. Stair Areas
	for stair in get_tree().get_nodes_in_group("stairs"):
		if stair.has_signal("body_entered"):
			stair.body_entered.connect(_on_stair_entered.bind(stair))
		
	# 4. Loiter Areas
	if loiter_points_path:
		var container = get_node_or_null(loiter_points_path)
		if container:
			for area in container.get_children():
				if area is Area2D:
					area.body_entered.connect(_on_loiter_entered)
		else:
			push_error("NPC Error: loiter_points_path assigned but container node not found.")

# --------------------------------------------------
# PHYSICS
# --------------------------------------------------
func _physics_process(delta):
	match state:
		State.WALKING:
			var old_pos = path_follow.global_position
			path_follow.progress += (speed * walk_direction) * delta
			# Calculate velocity for animation flipping and logic
			velocity = (path_follow.global_position - old_pos) / delta

			if path_follow.progress_ratio >= 1.0:
				walk_direction = -1
			elif path_follow.progress_ratio <= 0.0:
				walk_direction = 1

		State.IDLE:
			velocity = Vector2.ZERO
			loiter_timer -= delta
			if loiter_timer <= 0:
				state = State.WALKING

		State.USING_STAIRS, State.REACT:
			velocity = Vector2.ZERO

	_update_animations()

# --------------------------------------------------
# LOITER LOGIC
# --------------------------------------------------
func _on_loiter_entered(body):
	if body == self and state == State.WALKING:
		if randf() < 0.4: # 40% chance to stop
			_start_loiter()

func _start_loiter():
	state = State.IDLE
	loiter_timer = randf_range(3.0, 6.0)
	if randf() > 0.5:
		walk_direction *= -1

# --------------------------------------------------
# STAIRS
# --------------------------------------------------
func _on_stair_entered(body, stair):
	if body != self or state != State.WALKING or stair_cooldown:
		return

	state = State.USING_STAIRS
	stair_cooldown = true
	_use_stairs(stair)

func _use_stairs(stair):
	if randf() > 0.5: 
		state = State.WALKING
		await get_tree().create_timer(3.0).timeout
		stair_cooldown = false
		return

	anim.play("idle")
	await get_tree().create_timer(1.0).timeout

	var target_floor = get_node_or_null(stair.target_path)
	if target_floor == null:
		var search_name = "Floor 2" if "Up" in stair.name else "Floor 1"
		target_floor = get_tree().current_scene.find_child(search_name, true, false)

	if target_floor:
		visible = false 
		if path_follow:
			path_follow.get_parent().remove_child(path_follow)
			target_floor.add_child(path_follow)
			path_follow.progress_ratio = stair.target_progress_ratio
			if stair.flip_direction:
				walk_direction *= -1
		
		await get_tree().create_timer(0.5).timeout
		visible = true
		anim.play("idle")
		await get_tree().create_timer(1.0).timeout
		state = State.WALKING
	else:
		state = State.WALKING
	
	await get_tree().create_timer(2.0).timeout
	stair_cooldown = false

# --------------------------------------------------
# REACTION SYSTEM
# --------------------------------------------------
func _on_spooked(pos: Vector2):
	if is_befriended or state == State.REACT or global_position.distance_to(pos) > 120.0: return
	consecutive_amuses = 0
	consecutive_spooks += 1
	
	get_node("/root/GameManager").add_score(-2)

	var reaction = "scared" if consecutive_spooks < 3 else "spooked"
	_trigger_reaction(reaction)

func _on_amused(pos: Vector2):
	if is_befriended or state == State.REACT or global_position.distance_to(pos) > 120.0: return
	consecutive_spooks = 0
	consecutive_amuses += 1
	
	get_node("/root/GameManager").add_score(10)
	
	var reaction = "smiling"
	if consecutive_amuses == 2: reaction = "amused"
	elif consecutive_amuses >= 3:
		reaction = "befriended"
		is_befriended = true
		get_node("/root/GameManager").kid_befriended()
	_trigger_reaction(reaction)

func _trigger_reaction(anim_name: String):
	state = State.REACT
	if anim.sprite_frames.has_animation(anim_name):
		anim.play(anim_name)
	else:
		# Fallback if specific animation is missing
		anim.play("idle")
	
	# Save the timer to cancel if needed
	_reaction_timer = Engine.get_main_loop().create_timer(2.0)
	await _reaction_timer
	_reaction_timer = null

	state = State.WALKING

func _on_anim_finished():
	if state == State.REACT:
		state = State.WALKING
	_update_animations()

func _update_animations():
	if state == State.REACT: return
	
	var is_moving = velocity.length() > 5.0
	var anim_prefix = "befriended " if is_befriended else ""
	var anim_name = anim_prefix + ("walk" if is_moving else "idle")
	
	if anim.sprite_frames.has_animation(anim_name):
		anim.play(anim_name)
		
	if velocity.x != 0: 
		anim.flip_h = velocity.x < 0
		
		
func _stop_reaction_timer():
	# Just clear reference so NPC won't await it anymore
	_reaction_timer = null
	state = State.WALKING
