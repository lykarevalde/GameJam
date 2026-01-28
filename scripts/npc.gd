extends CharacterBody2D

# --- SETTINGS ---
@export var speed := 60.0
@export var ground_y := 195.0    # Bottom floor Y
@export var upstairs_y := 115.0  # Top floor Y
@export var stairs_x := 45.0     # X position of stairs

# X positions for various rooms in the house
var room_positions = [34.0, 194.0, 360.0] 

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

# --- STATE & COUNTERS ---
enum State { IDLE, WALKING_TO_STAIRS, CLIMBING, WALKING_TO_ROOM, REACT }
var state := State.IDLE

var target_room_x: float
var target_floor_y: float
var current_floor_y: float
var idle_timer := 0.0

var consecutive_spooks := 0
var consecutive_amuses := 0
var is_befriended := false # Tracks if the NPC has reached the final friendship level

# --------------------------------------------------
# CORE LOOPS
# --------------------------------------------------

func _ready():
	current_floor_y = global_position.y 
	_pick_new_destination() 

	# Connect to all furniture in the "furniture" group
	for f in get_tree().get_nodes_in_group("furniture"):
		f.spooked.connect(_on_spooked)
		f.amused.connect(_on_amused)

func _physics_process(delta):
	match state:
		State.IDLE:
			idle_timer -= delta
			if idle_timer <= 0: _pick_new_destination()
		
		State.WALKING_TO_STAIRS:
			_move_towards(stairs_x, current_floor_y, State.CLIMBING)
			
		State.CLIMBING:
			_move_towards(stairs_x, target_floor_y, State.WALKING_TO_ROOM)
			
		State.WALKING_TO_ROOM:
			_move_towards(target_room_x, target_floor_y, State.IDLE)

	move_and_slide()
	_update_animations()

# --------------------------------------------------
# MOVEMENT LOGIC
# --------------------------------------------------

func _pick_new_destination():
	target_room_x = room_positions.pick_random()
	target_floor_y = [ground_y, upstairs_y].pick_random()
	
	if target_floor_y != current_floor_y:
		state = State.WALKING_TO_STAIRS
	else:
		state = State.WALKING_TO_ROOM

func _move_towards(dest_x: float, dest_y: float, next_state: State):
	var diff_x = dest_x - global_position.x
	var diff_y = dest_y - global_position.y
	
	if abs(diff_x) > 2.0:
		velocity.x = sign(diff_x) * speed
		velocity.y = 0
	elif abs(diff_y) > 2.0:
		velocity.x = 0
		velocity.y = sign(diff_y) * speed
	else:
		velocity = Vector2.ZERO
		global_position = Vector2(dest_x, dest_y)
		current_floor_y = dest_y
		
		if next_state == State.IDLE:
			idle_timer = randf_range(2.0, 5.0)
		state = next_state

# --------------------------------------------------
# REACTION SYSTEM
# --------------------------------------------------

func _on_spooked(pos: Vector2):
	# Don't react to spooks if already befriended
	if is_befriended or state == State.REACT or global_position.distance_to(pos) > 120.0:
		return
	
	consecutive_amuses = 0 
	consecutive_spooks += 1
	
	var reaction = "scared"
	if consecutive_spooks >= 3:
		reaction = "spooked"
	
	_trigger_reaction(reaction)

func _on_amused(pos: Vector2):
	# Stop tracking amuses once friendship is permanent
	if is_befriended or state == State.REACT or global_position.distance_to(pos) > 120.0:
		return
		
	consecutive_spooks = 0
	consecutive_amuses += 1
	
	var reaction = "smiling"
	if consecutive_amuses == 2:
		reaction = "amused"
	elif consecutive_amuses >= 3:
		reaction = "befriended"
		is_befriended = true # Permanent status change
		
	_trigger_reaction(reaction)

func _trigger_reaction(anim_name: String):
	state = State.REACT
	velocity = Vector2.ZERO
	
	if anim.sprite_frames.has_animation(anim_name):
		anim.play(anim_name)
	
	# After the reaction animation plays for 2 seconds, resume life
	await get_tree().create_timer(2.0).timeout
	_pick_new_destination()

# --------------------------------------------------
# ANIMATION MANAGEMENT
# --------------------------------------------------

func _update_animations():
	# While reacting to a furniture item, let that animation play
	if state == State.REACT: 
		return
	
	var is_moving = abs(velocity.x) > 0.1 or abs(velocity.y) > 0.1
	
	if is_befriended:
		# Use permanent befriended versions of walk/idle
		if is_moving:
			if anim.animation != "befriended walk": anim.play("befriended walk")
		else:
			if anim.animation != "befriended idle": anim.play("befriended idle")
	else:
		# Use normal versions of walk/idle
		if is_moving:
			if anim.animation != "walk": anim.play("walk")
		else:
			if anim.animation != "idle": anim.play("idle")

	# Flip sprite based on movement direction
	if velocity.x != 0:
		anim.flip_h = velocity.x < 0
