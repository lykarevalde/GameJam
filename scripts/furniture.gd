extends CharacterBody2D

signal possession_finished(furniture)

#ADDED SIGNALS (NPC reaction system)
signal spooked(position: Vector2)
signal amused(position: Vector2)

enum PossessorType { NONE, PLAYER, NPC }
var possessor := PossessorType.NONE
var move_direction := Vector2.ZERO

# NPC possession
enum PossessionMode { MOVE, SPOOK, FLOAT }
@export var move_speed := 120.0
@export var float_height := 60.0
@export var min_possession_time := 1.5
@export var max_possession_time := 3.0
@export var spook_duration := 3.0
@export var can_move := true

@export var allowed_npc_actions: Array[PossessionMode] = [
	PossessionMode.MOVE,
	PossessionMode.SPOOK,
	PossessionMode.FLOAT
]

@export var gravity := 900.0


var is_dropping := false
var npc_possessed := false
var action_queue: Array = []
var current_action := PossessionMode.MOVE
var timer := 0.0
var direction := 1
var anim_started := false
var chosen_float_height := 0.0
var float_base_y := 0.0

# Player possession
@export var player_move_speed := 100.0
var player_possessed := false

# Nodes
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	anim.material = anim.material.duplicate()
	if anim:
		anim.connect("animation_finished", Callable(self, "_on_anim_finished"))
	

func _on_anim_finished():
	anim.play("idle")

# shader helper
func show_can_possess():
	anim.material.set_shader_parameter("outline_color", Color(1, 1, 0)) # yellow
	anim.material.set_shader_parameter("thickness", 1.0)

func show_cannot_possess():
	anim.material.set_shader_parameter("outline_color", Color(1, 0, 0)) # red
	anim.material.set_shader_parameter("thickness", 1.0)

func clear_outline():
	anim.material.set_shader_parameter("thickness", 0.0)
	
# --------------------
# PHYSICS PROCESS
# --------------------
func _physics_process(delta):
	# --- NOT POSSESSED ---
	if possessor == PossessorType.NONE:
		if can_move:
			if not is_on_floor():
				velocity.y += gravity * delta
				is_dropping = true
			else:
				if is_dropping:
					velocity.y = 0
					is_dropping = false
					anim.play("idle")

			move_and_slide()
		else:
			velocity = Vector2.ZERO
		return

	# --- PLAYER POSSESSION ---
	if possessor == PossessorType.PLAYER:
		if can_move:
			player_control(delta)
		else:
			velocity = Vector2.ZERO
		return

	# --- NPC POSSESSION (ALWAYS RUNS) ---
	if possessor == PossessorType.NPC:
		npc_control(delta)
	else:
		velocity = Vector2.ZERO
		


# --------------------
# PLAYER CONTROL
# --------------------
func player_control(delta):
	if not can_move:
		velocity = velocity.move_toward(Vector2.ZERO, player_move_speed * 5 * delta)
		move_and_slide()
		return
		
	var input_vector := Vector2.ZERO
	input_vector.x = Input.get_axis("ui_left", "ui_right")
	input_vector.y = Input.get_axis("ui_up", "ui_down")
	input_vector = input_vector.normalized() # prevent faster diagonal speed
	
	 # Smoothly accelerate/decelerate
	var target_velocity = input_vector * player_move_speed
	velocity.x = move_toward(velocity.x, target_velocity.x, player_move_speed * 5 * delta)
	velocity.y = move_toward(velocity.y, target_velocity.y, player_move_speed * 5 * delta)

	move_and_slide()

func possess_by_player():
	if possessor != PossessorType.NONE:
		return
	possessor = PossessorType.PLAYER
	clear_outline()
	player_possessed = true
	print("Player possessed furniture")

func unpossess_by_player():
	player_possessed = false
	possessor = PossessorType.NONE
	clear_outline()
	velocity = Vector2.ZERO
	is_dropping = can_move
	print("Player released furniture")

# Called by the player to trigger the amuse animation
func amuse():
	if possessor != PossessorType.PLAYER:
		return  # Only player can amuse

	# Play the amuse animation
	anim.play("amuse")
	emit_signal("amused", global_position)   # ADDED



# --------------------
# NPC POSSESSION
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
	if possessor != PossessorType.NONE:
		return false
	possessor = PossessorType.NPC
	npc_possessed = true
	anim_started = false
	action_queue.clear()
	direction = [-1, 1].pick_random()
	var count := randi_range(1, min(2, allowed_npc_actions.size()))
	while action_queue.size() < count:
		var action = allowed_npc_actions.pick_random()
		if not can_move and action == PossessionMode.MOVE:
			continue
		if action not in action_queue:
			action_queue.append(action)
	start_next_action()
	return true


# --- NPC action methods ---
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
	if not can_move:
		velocity = velocity.move_toward(Vector2.ZERO, move_speed * 5 * delta)
		return
		
	 # Smoothly adjust velocity toward move_direction * move_speed
	var target_velocity = move_direction * move_speed
	velocity.x = move_toward(velocity.x, target_velocity.x, move_speed * 5 * delta)
	velocity.y = move_toward(velocity.y, target_velocity.y, move_speed * 5 * delta)
	move_and_slide()
	
	if is_on_wall():
		move_direction = -move_direction # bounce
	
	# flip horizontal sprite if moving left
	if abs(velocity.x) > 0:
		anim.flip_h = velocity.x < 0

	if not anim_started:
		anim.play("move")
		anim_started = true

func float_possession(delta):
	global_position.y = float_base_y - chosen_float_height
	velocity = Vector2(direction*move_speed,0)
	move_and_slide()
	if abs(velocity.x) > 0:
		anim.flip_h = velocity.x < 0
	if not anim_started:
		anim.play("move")
		anim_started = true

func spook_possession():
	velocity = Vector2.ZERO
	if not anim_started:
		anim.play("spook")
		anim_started = true
		emit_signal("spooked", global_position)   # ADDED (fires once)

func end_npc_possession():
	npc_possessed = false
	possessor = PossessorType.NONE
	velocity = Vector2.ZERO
	is_dropping = can_move
	if current_action == PossessionMode.FLOAT:
		global_position.y = float_base_y
	anim.stop()
	emit_signal("possession_finished", self)


func _on_area_2d_area_entered(area: Area2D) -> void:
	pass # Replace with function body.


func _on_area_2d_area_exited(area: Area2D) -> void:
	pass # Replace with function body.


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name != "Player":
		return

	if possessor != PossessorType.NONE:
		show_cannot_possess()   # red glow
	else:
		show_can_possess()      # yellow glow


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.name != "Player":
		return

	clear_outline()
