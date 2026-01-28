extends CharacterBody2D

# --- SETTINGS ---
@export var speed := 60.0
# In the Inspector, click this and select your "LoiterPoints" node
@export var loiter_points_path: NodePath 

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var path_follow: PathFollow2D = get_parent()

# --- STATE & LOGIC ---
enum State { WALKING, IDLE, REACT }
var state := State.WALKING

var walk_direction := 1.0
var idle_timer := 0.0
var points_list = []
var last_visited_point = null

var consecutive_spooks := 0
var consecutive_amuses := 0
var is_befriended := false

# --------------------------------------------------
# CORE LOOPS
# --------------------------------------------------

func _ready():
	# Fill the list of markers to stop at
	if loiter_points_path:
		points_list = get_node(loiter_points_path).get_children()

	# Connect to all furniture in the "furniture" group
	for f in get_tree().get_nodes_in_group("furniture"):
		f.spooked.connect(_on_spooked)
		f.amused.connect(_on_amused)

func _physics_process(delta):
	match state:
		State.WALKING:
			var old_pos = path_follow.global_position
			path_follow.progress += (speed * walk_direction) * delta
			velocity = (path_follow.global_position - old_pos) / delta
			
			# 1. Check if we are near a loiter point
			_check_for_loiter_points()

			# 2. Reset "last visited" if we move away, so we can stop there again later
			if last_visited_point and global_position.distance_to(last_visited_point.global_position) > 50.0:
				last_visited_point = null

			# 3. Flip direction at path ends
			if path_follow.progress_ratio >= 1.0: 
				walk_direction = -1
			elif path_follow.progress_ratio <= 0.0: 
				walk_direction = 1

		State.IDLE:
			velocity = Vector2.ZERO
			idle_timer -= delta
			if idle_timer <= 0:
				state = State.WALKING
		
		State.REACT:
			velocity = Vector2.ZERO

	_update_animations()

# --------------------------------------------------
# LOITER LOGIC
# --------------------------------------------------

func _check_for_loiter_points():
	for point in points_list:
		# Increased detection range to 30.0 pixels for better reliability
		var distance = global_position.distance_to(point.global_position)
		
		if distance < 30.0 and last_visited_point != point:
			last_visited_point = point
			
			# CHANCE TO STOP: 0.8 means 80% chance to stop. 
			# If they aren't stopping enough, keep this high!
			if randf() < 0.8:
				_start_idle()
			
			break

func _start_idle():
	state = State.IDLE
	# How long they stand still in the room
	idle_timer = randf_range(3.0, 6.0)
	
	# After stopping, 50% chance to change mind and walk back
	if randf() > 0.5:
		walk_direction *= -1

# --------------------------------------------------
# REACTION SYSTEM
# --------------------------------------------------

func _on_spooked(pos: Vector2):
	if is_befriended or state == State.REACT or global_position.distance_to(pos) > 120.0:
		return
	
	consecutive_amuses = 0 
	consecutive_spooks += 1
	
	var reaction = "scared"
	if consecutive_spooks >= 3:
		reaction = "spooked"
	
	_trigger_reaction(reaction)

func _on_amused(pos: Vector2):
	if is_befriended or state == State.REACT or global_position.distance_to(pos) > 120.0:
		return
		
	consecutive_spooks = 0
	consecutive_amuses += 1
	
	var reaction = "smiling"
	if consecutive_amuses == 2:
		reaction = "amused"
	elif consecutive_amuses >= 3:
		reaction = "befriended"
		is_befriended = true
		
	_trigger_reaction(reaction)

func _trigger_reaction(anim_name: String):
	state = State.REACT
	if anim.sprite_frames.has_animation(anim_name):
		anim.play(anim_name)
	
	await get_tree().create_timer(2.0).timeout
	state = State.WALKING

# --------------------------------------------------
# ANIMATION MANAGEMENT
# --------------------------------------------------

func _update_animations():
	if state == State.REACT: 
		return
	
	var is_moving = velocity.length() > 5.0
	
	if is_befriended:
		anim.play("befriended walk" if is_moving else "befriended idle")
	else:
		anim.play("walk" if is_moving else "idle")

	if velocity.x != 0:
		anim.flip_h = velocity.x < 0
