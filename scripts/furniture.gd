extends CharacterBody2D

signal possession_finished(furniture)
signal spooked(position: Vector2)
signal amused(position: Vector2)
signal player_possessed_furniture

enum PossessorType { NONE, PLAYER, NPC }
var possessor := PossessorType.NONE
var move_direction := Vector2.ZERO
var anim_locked := false  # Prevents movement animation from overriding others

# NPC Possession
enum PossessionMode { MOVE, SPOOK, FLOAT }
@export var move_speed := 120.0
@export var float_height := 60.0
@export var min_possession_time := 1.5
@export var max_possession_time := 3.0
@export var spook_duration := 3.0
@export var can_move := true
@export var allowed_npc_actions: Array[PossessionMode] = [PossessionMode.MOVE, PossessionMode.SPOOK, PossessionMode.FLOAT]
@export var gravity := 900.0
@export var acceleration := 200.0
@export var friction := 300.0
@export var player_acceleration := 400.0
@export var player_friction := 700.0

var is_dropping := false
var npc_possessed := false
var action_queue: Array = []
var current_action := PossessionMode.MOVE
var timer := 0.0
var direction := 1
var anim_started := false
var chosen_float_height := 0.0
var float_base_y := 0.0

# Player Possession
@export var player_move_speed := 100.0
var player_possessed := false
var current_player_possessor: Node = null # Reference to player to spend energy

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	anim.material = anim.material.duplicate()
	if anim:
		anim.connect("animation_finished", Callable(self, "_on_anim_finished"))

func _on_anim_finished():
	# If we just finished amusing, tell the player to spend energy
	if anim.animation == "amuse":
		if current_player_possessor and current_player_possessor.has_method("spend_energy"):
			current_player_possessor.spend_energy()
			current_player_possessor = null # Clear after use
			
	# Unlock animation and return to idle
	anim_locked = false
	anim.play("idle")

# --------------------
# Physics
# --------------------
func _physics_process(delta):
	# Not possessed, gravity applies if can move
	if possessor == PossessorType.NONE:
		if can_move and not is_on_floor():
			velocity.y += gravity * delta
			is_dropping = true
		elif is_dropping:
			velocity.y = 0
			is_dropping = false
			anim.play("idle")
		move_and_slide()
		return

	# Player possession
	if possessor == PossessorType.PLAYER and can_move:
		player_control(delta)

	# NPC possession
	if possessor == PossessorType.NPC:
		npc_control(delta)

# --------------------
# Player Control
# --------------------
func player_control(delta):
	if not can_move:
		velocity = Vector2.ZERO
		return
		
	var input_vector := Vector2(
		Input.get_axis("ui_left", "ui_right"),
		Input.get_axis("ui_up", "ui_down")
	).normalized()
	
	var target_velocity = input_vector * player_move_speed

	# Smooth acceleration/deceleration
	velocity.x = move_toward(velocity.x, target_velocity.x, player_acceleration * delta)
	velocity.y = move_toward(velocity.y, target_velocity.y, player_acceleration * delta)

	move_and_slide()
	
	# ----------------------------
	# Handle animation if not locked
	# ----------------------------
	if not anim_locked:
		if input_vector.length() > 0:
			if anim.animation != "move":
				anim.play("move")
		else:
			if anim.animation != "idle":
				anim.play("idle")



# --------------------
# Possession Functions
# --------------------
func possess_by_player():
	if possessor != PossessorType.NONE: return
	possessor = PossessorType.PLAYER
	player_possessed = true
	anim.material.set_shader_parameter("thickness", 0)
	emit_signal("player_possessed_furniture")
	#print("Player possessed furniture")

func unpossess_by_player():
	player_possessed = false
	possessor = PossessorType.NONE
	current_player_possessor = null
	velocity = Vector2.ZERO
	is_dropping = can_move
	#print("Player released furniture")

func amuse(player_ref: Node):
	if possessor != PossessorType.PLAYER: return
	
	# Lock animation so player_control() won't override
	anim_locked = true
	
	# Store player reference to charge them when animation finishes
	current_player_possessor = player_ref
	anim.play("amuse")
	emit_signal("amused", global_position)

# --------------------
# NPC Possession
# --------------------
func npc_control(delta):
	match current_action:
		PossessionMode.MOVE:
			move_possession(delta)
		PossessionMode.FLOAT:
			float_possession(delta)
		PossessionMode.SPOOK:
			spook_possession()
	timer -= delta
	if timer <= 0:
		start_next_action()

func on_possessed() -> bool:
	if possessor != PossessorType.NONE: return false
	possessor = PossessorType.NPC
	npc_possessed = true
	anim_started = false
	action_queue.clear()
	var count := randi_range(1, min(2, allowed_npc_actions.size()))
	while action_queue.size() < count:
		var action = allowed_npc_actions.pick_random()
		if not can_move and action == PossessionMode.MOVE: continue
		if action not in action_queue: action_queue.append(action)
	start_next_action()
	return true

func start_next_action():
	if current_action == PossessionMode.FLOAT:
		global_position.y = float_base_y
	if action_queue.is_empty():
		end_npc_possession()
		return
	current_action = action_queue.pop_front()
	anim_started = false
	velocity = Vector2.ZERO
	match current_action:
		PossessionMode.FLOAT:
			float_base_y = global_position.y
			chosen_float_height = randf_range(float_height*0.5,float_height)
			timer = randf_range(min_possession_time,max_possession_time)
		PossessionMode.SPOOK:
			timer = spook_duration
		PossessionMode.MOVE:
			timer = randf_range(min_possession_time,max_possession_time)
			# Random direction for full 2D
			move_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()

func move_possession(delta):
	if not can_move: return
	# Smoothly accelerate towards the target velocity
	var target_velocity = move_direction * move_speed
	velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * delta)
	velocity.y = move_toward(velocity.y, target_velocity.y, acceleration * delta)	
	move_and_slide()
	
	if is_on_wall():
		move_direction = -move_direction
		
	if not anim_started:
		anim.play("move")
		anim_started = true
		emit_signal("spooked", global_position)

func float_possession(delta):
	global_position.y = float_base_y - chosen_float_height
	velocity = Vector2(direction*move_speed,0)
	move_and_slide()
	if not anim_started:
		anim.play("move")
		anim_started = true
		emit_signal("spooked", global_position)

func spook_possession():
	velocity = Vector2.ZERO
	if not anim_started:
		anim.play("spook")
		anim_started = true
		emit_signal("spooked", global_position)

func end_npc_possession():
	npc_possessed = false
	possessor = PossessorType.NONE
	velocity = Vector2.ZERO
	is_dropping = can_move
	if current_action == PossessionMode.FLOAT:
		global_position.y = float_base_y
	anim.stop()
	emit_signal("possession_finished", self)
