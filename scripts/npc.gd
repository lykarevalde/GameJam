extends CharacterBody2D

# --- SETTINGS ---
@export var speed := 60.0
@export var loiter_points_path: NodePath 

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var path_follow: PathFollow2D = get_parent()

# --- STATE & LOGIC ---
enum State { WALKING, IDLE, REACT }
var state := State.WALKING

var walk_direction := 1.0
var idle_timer := 0.0
var points_list = []
var points_cooldown = {} 

# Store the point we are currently standing at so we can "free" it later
var current_occupied_point: Node = null

var consecutive_spooks := 0
var consecutive_amuses := 0
var is_befriended := false

# --------------------------------------------------
# CORE LOOPS
# --------------------------------------------------

func _ready():
	speed = randf_range(speed * 0.8, speed * 1.2)
	
	if loiter_points_path:
		points_list = get_node(loiter_points_path).get_children()

	for f in get_tree().get_nodes_in_group("furniture"):
		f.spooked.connect(_on_spooked)
		f.amused.connect(_on_amused)

func _physics_process(delta):
	_update_cooldowns(delta)
	
	match state:
		State.WALKING:
			var old_pos = path_follow.global_position
			path_follow.progress += (speed * walk_direction) * delta
			velocity = (path_follow.global_position - old_pos) / delta
			
			_check_for_loiter_points()

			if path_follow.progress_ratio >= 1.0: 
				walk_direction = -1
			elif path_follow.progress_ratio <= 0.0: 
				walk_direction = 1

		State.IDLE:
			velocity = Vector2.ZERO
			idle_timer -= delta
			if idle_timer <= 0:
				_finish_idle()
		
		State.REACT:
			velocity = Vector2.ZERO

	_update_animations()

# --------------------------------------------------
# LOITER LOGIC (WITH OCCUPANCY CHECK)
# --------------------------------------------------

func _update_cooldowns(delta):
	var keys_to_remove = []
	for point in points_cooldown:
		points_cooldown[point] -= delta
		if points_cooldown[point] <= 0:
			keys_to_remove.append(point)
	
	for key in keys_to_remove:
		points_cooldown.erase(key)

func _check_for_loiter_points():
	for point in points_list:
		var distance = global_position.distance_to(point.global_position)
		
		# NEW: Check if the point has a "is_busy" metadata flag
		var is_busy = point.get_meta("is_busy", false)
		
		if distance < 30.0 and not points_cooldown.has(point) and not is_busy:
			if randf() < 0.6:
				_start_idle(point)
			else:
				points_cooldown[point] = 2.0
			break

func _start_idle(point):
	state = State.IDLE
	idle_timer = randf_range(3.0, 7.0)
	
	# Mark the point as busy so others skip it
	current_occupied_point = point
	current_occupied_point.set_meta("is_busy", true)
	
	points_cooldown[point] = randf_range(15.0, 25.0)
	
	if randf() < 0.3:
		walk_direction *= -1

func _finish_idle():
	# NEW: Free the point before walking away
	if current_occupied_point:
		current_occupied_point.set_meta("is_busy", false)
		current_occupied_point = null
		
	state = State.WALKING

# --------------------------------------------------
# REACTION & ANIMATION (SAME AS BEFORE)
# --------------------------------------------------

func _on_spooked(pos: Vector2):
	if is_befriended or state == State.REACT or global_position.distance_to(pos) > 120.0:
		return
	consecutive_amuses = 0 
	consecutive_spooks += 1
	_trigger_reaction("spooked" if consecutive_spooks >= 3 else "scared")

func _on_amused(pos: Vector2):
	if is_befriended or state == State.REACT or global_position.distance_to(pos) > 120.0:
		return
	consecutive_spooks = 0
	consecutive_amuses += 1
	var reaction = "smiling"
	if consecutive_amuses == 2: reaction = "amused"
	elif consecutive_amuses >= 3:
		reaction = "befriended"; is_befriended = true
	_trigger_reaction(reaction)

func _trigger_reaction(anim_name: String):
	# If we were idling at a point, free it because we are now "reacting"
	if current_occupied_point:
		current_occupied_point.set_meta("is_busy", false)
		current_occupied_point = null
		
	state = State.REACT
	if anim.sprite_frames.has_animation(anim_name):
		anim.play(anim_name)
	await get_tree().create_timer(2.0).timeout
	state = State.WALKING

func _update_animations():
	if state == State.REACT: return
	var is_moving = velocity.length() > 5.0
	if is_befriended:
		anim.play("befriended walk" if is_moving else "befriended idle")
	else:
		anim.play("walk" if is_moving else "idle")
	if velocity.x != 0:
		anim.flip_h = velocity.x < 0
