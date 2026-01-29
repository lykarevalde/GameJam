extends CharacterBody2D

signal befriended
signal amused
signal spooked(penalty: int)

# --------------------------------------------------
# SETTINGS
# --------------------------------------------------
@export var speed := 60.0
@export var loiter_points_path: NodePath 
# Increased max_trust to make the journey longer
@export var max_trust: float = 100.0 

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var path_follow: PathFollow2D = get_parent()
# Fixed path based on your hierarchy
@onready var trust_bar: TextureProgressBar = $TrustBarContainer/TrustBar 

# --------------------------------------------------
# STATE
# --------------------------------------------------
enum State { WALKING, IDLE, USING_STAIRS, REACT, PANIC }
var state := State.WALKING

var walk_direction := 1.0
var stair_cooldown := false
var loiter_timer := 0.0
var last_loiter_area: Area2D = null
var can_loiter := true

# Trust & Panic System
var trust_score: float = 0.0
var is_befriended := false
var consecutive_spooks := 0

# --------------------------------------------------
# READY & PHYSICS
# --------------------------------------------------
func _ready():
	trust_bar.max_value = max_trust
	trust_bar.value = trust_score
	trust_bar.show()

	if anim:
		if anim.material:
			anim.material = anim.material.duplicate()
		anim.animation_finished.connect(_on_anim_finished)

	for f in get_tree().get_nodes_in_group("furniture"):
		if f.has_signal("spooked"): f.spooked.connect(_on_spooked)
		if f.has_signal("amused"): f.amused.connect(_on_amused)

	for stair in get_tree().get_nodes_in_group("stairs"):
		if stair.has_signal("body_entered"):
			stair.body_entered.connect(_on_stair_entered.bind(stair))
		
	if loiter_points_path:
		var container = get_node_or_null(loiter_points_path)
		if container:
			for area in container.get_children():
				if area is Area2D:
					area.body_entered.connect(_on_loiter_entered.bind(area))

func _physics_process(delta):
	match state:
		State.WALKING, State.PANIC:
			var old_pos = path_follow.global_position
			path_follow.progress += (speed * walk_direction) * delta
			velocity = (path_follow.global_position - old_pos) / delta

			if path_follow.progress_ratio >= 1.0:
				walk_direction = -1
			elif path_follow.progress_ratio <= 0.0:
				walk_direction = 1

		State.IDLE, State.USING_STAIRS, State.REACT:
			velocity = Vector2.ZERO

	_update_animations()

# --------------------------------------------------
# SMART REACTION SYSTEM (SLOWED DOWN)
# --------------------------------------------------
func _on_spooked(ghost_pos: Vector2):
	if is_befriended or state == State.REACT or state == State.PANIC: return
	if global_position.distance_to(ghost_pos) > 120.0: return
	
	# NPC confirms spook and decides penalty amount
	var penalty := 2 if state == State.PANIC else 5
	emit_signal("spooked", penalty)
	
	consecutive_spooks += 1
	# Small decrease: Now takes many more spooks to hit 0 if they had progress
	trust_score = max(0, trust_score - 5.0) 
	_update_trust_ui()

	if consecutive_spooks >= 3:
		consecutive_spooks = 0
		_trigger_panic(ghost_pos)
	else:
		_trigger_reaction("scared")

func _on_amused(pos: Vector2):
	if is_befriended or state == State.REACT or state == State.PANIC: return
	if global_position.distance_to(pos) > 120.0: return
	
	consecutive_spooks = 0
	# Small increase: With max_trust at 300, it takes 60 "amused" triggers to win
	trust_score = min(max_trust, trust_score + 5.0) 
	_update_trust_ui()

	if trust_score >= max_trust:
		is_befriended = true
		emit_signal("befriended")
		call_deferred("_trigger_reaction", "befriended")
	else:
		emit_signal("amused")
		call_deferred("_trigger_reaction", "smiling")

func _update_trust_ui():
	# Using a Tween here would make the bar move smoothly
	var tween = create_tween()
	tween.tween_property(trust_bar, "value", trust_score, 0.5).set_trans(Tween.TRANS_SINE)

func _trigger_reaction(anim_name: String):
	state = State.REACT
	if anim.sprite_frames.has_animation(anim_name):
		anim.play(anim_name)
	await get_tree().create_timer(2.0).timeout
	if state != State.PANIC: state = State.WALKING

func _trigger_panic(ghost_pos: Vector2):
	state = State.PANIC
	anim.play("spooked")
	
	if ghost_pos.x > global_position.x:
		walk_direction = -1.0
	else:
		walk_direction = 1.0
		
	speed *= 2.5 
	await get_tree().create_timer(3.0).timeout
	speed /= 2.5
	state = State.WALKING

# --------------------------------------------------
# STAIRS & LOITER
# --------------------------------------------------
func _on_loiter_entered(_body: Node2D, area: Area2D):
	if state == State.WALKING and can_loiter and area != last_loiter_area:
		if randf() < 0.4: 
			last_loiter_area = area
			_start_loiter()

func _start_loiter():
	state = State.IDLE
	can_loiter = false
	loiter_timer = randf_range(3.0, 6.0)
	walk_direction *= -1
	await get_tree().create_timer(loiter_timer).timeout
	state = State.WALKING
	await get_tree().create_timer(2.0).timeout
	can_loiter = true

func _on_stair_entered(body, stair):
	if body != self or state != State.WALKING or stair_cooldown: return
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
	if target_floor:
		visible = false 
		last_loiter_area = null
		path_follow.get_parent().remove_child(path_follow)
		target_floor.add_child(path_follow)
		path_follow.progress_ratio = stair.target_progress_ratio
		if stair.flip_direction: walk_direction *= -1
		await get_tree().create_timer(0.5).timeout
		visible = true
		state = State.WALKING
	else:
		state = State.WALKING
	
	await get_tree().create_timer(2.0).timeout
	stair_cooldown = false

# --------------------------------------------------
# ANIMATIONS
# --------------------------------------------------
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
