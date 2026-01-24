extends CharacterBody2D

signal possession_finished(furniture)

enum PossessionMode {
	MOVE,
	SPOOK,
	FLOAT
}

@export var move_distance := 40.0
@export var move_speed := 60.0
@export var float_height := 60.0
@export var min_possession_time := 1.5
@export var max_possession_time := 3.0
@export var spook_duration := 3.0

@onready var anim: AnimatedSprite2D = $Toilet

var possessed := false
var timer := 0.0
var direction := 1

# Action system
var action_queue: Array = []
var current_action := PossessionMode.MOVE

# Animation + float helpers
var anim_started := false
var chosen_float_height := 0.0
var float_base_y := 0.0


func _physics_process(delta):
	if not possessed:
		return

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




func move_possession(delta):
	velocity = Vector2(direction * move_speed, 0)
	move_and_slide()

	if abs(velocity.x) > 0:
		anim.flip_h = velocity.x < 0

	if not anim_started:
		anim.play("move")
		anim_started = true


func float_possession(delta):
	# Lock Y up, allow X movement
	global_position.y = float_base_y - chosen_float_height

	velocity = Vector2(direction * move_speed, 0)
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




func on_possessed() -> bool:
	if possessed:
		return false

	possessed = true
	anim_started = false
	action_queue.clear()

	direction = [-1, 1].pick_random()

	# Choose 1 or 2 UNIQUE actions
	var count := randi_range(1, 2)
	while action_queue.size() < count:
		var action = PossessionMode.values().pick_random()
		if action not in action_queue:
			action_queue.append(action)

	start_next_action()

	print("[Furniture] POSSESSED:", name, "Actions:", action_queue)
	return true


func start_next_action():
	# Finish FLOAT cleanly (drop back down)
	if current_action == PossessionMode.FLOAT:
		global_position.y = float_base_y

	if action_queue.is_empty():
		end_possession()
		return

	current_action = action_queue.pop_front()
	anim_started = false
	velocity = Vector2.ZERO

	match current_action:
		PossessionMode.FLOAT:
			float_base_y = global_position.y
			chosen_float_height = randf_range(float_height * 0.5, float_height)
			timer = randf_range(min_possession_time, max_possession_time)

		PossessionMode.SPOOK:
			timer = spook_duration

		PossessionMode.MOVE:
			timer = randf_range(min_possession_time, max_possession_time)

	print("→ Action:", current_action, "Duration:", timer)


func end_possession():
	possessed = false
	velocity = Vector2.ZERO

	# Ensure float always ends grounded
	if current_action == PossessionMode.FLOAT:
		global_position.y = float_base_y

	if anim:
		anim.stop()

	print("[Furniture] RELEASED:", name)
	emit_signal("possession_finished", self)
