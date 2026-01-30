extends CharacterBody2D

signal befriended
signal amused
signal spooked(penalty: int)

# --------------------------------------------------
# SETTINGS
# --------------------------------------------------
@export var speed := 60.0
@export var loiter_points_path: NodePath
@export var max_trust := 25.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var path_follow: PathFollow2D = get_parent()
@onready var trust_bar: TextureProgressBar = $TrustBarContainer/TrustBar

# --------------------------------------------------
# STATE
# --------------------------------------------------
enum State { WALKING, IDLE, USING_STAIRS, REACT, PANIC }
var state := State.WALKING

var walk_direction := 1.0
var stair_cooldown := false
var last_loiter_area: Area2D
var can_loiter := true
var is_stopped := false

# Trust
var trust_score := 0.0
var is_befriended := false
var consecutive_spooks := 0

# --------------------------------------------------
# TIMERS (FSM BASED)
# --------------------------------------------------
@onready var reaction_timer := Timer.new()
@onready var panic_timer := Timer.new()
@onready var loiter_timer := Timer.new()
@onready var stair_timer := Timer.new()

# --------------------------------------------------
# READY
# --------------------------------------------------
func _ready():
	trust_bar.max_value = max_trust
	trust_bar.value = trust_score
	trust_bar.show()

	_add_timer(reaction_timer, _on_reaction_timeout)
	_add_timer(panic_timer, _on_panic_timeout)
	_add_timer(loiter_timer, _on_loiter_timeout)
	_add_timer(stair_timer, _on_stair_timeout)

	anim.animation_finished.connect(_on_anim_finished)

	for f in get_tree().get_nodes_in_group("furniture"):
		if f.has_signal("spooked"): f.spooked.connect(_on_spooked)
		if f.has_signal("amused"): f.amused.connect(_on_amused)

	for stair in get_tree().get_nodes_in_group("stairs"):
		stair.body_entered.connect(_on_stair_entered.bind(stair))

	if loiter_points_path:
		var c = get_node_or_null(loiter_points_path)
		if c:
			for a in c.get_children():
				if a is Area2D:
					a.body_entered.connect(_on_loiter_entered.bind(a))

# --------------------------------------------------
# TIMER SETUP HELPER
# --------------------------------------------------
func _add_timer(t: Timer, callback: Callable):
	add_child(t)
	t.one_shot = true
	t.timeout.connect(callback)

# --------------------------------------------------
# PHYSICS
# --------------------------------------------------
func _physics_process(delta):
	match state:
		State.WALKING, State.PANIC:
			var old_pos = path_follow.global_position
			path_follow.progress += speed * walk_direction * delta
			velocity = (path_follow.global_position - old_pos) / delta

			if path_follow.progress_ratio >= 1.0:
				walk_direction = -1
			elif path_follow.progress_ratio <= 0.0:
				walk_direction = 1

		_:
			velocity = Vector2.ZERO

	_update_animation()

# --------------------------------------------------
# REACTIONS
# --------------------------------------------------
func _on_spooked(pos: Vector2):
	if is_befriended or state in [State.REACT, State.PANIC]: return
	if global_position.distance_to(pos) > 120: return

	var penalty := 2 if state == State.PANIC else 5
	emit_signal("spooked", penalty)

	consecutive_spooks += 1
	trust_score = max(0, trust_score - 5)
	_update_trust()

	if consecutive_spooks >= 3:
		consecutive_spooks = 0
		_trigger_panic(pos)
	else:
		_trigger_reaction("scared")

func _on_amused(pos: Vector2):
	if is_befriended or state in [State.REACT, State.PANIC]: return
	if global_position.distance_to(pos) > 120: return

	consecutive_spooks = 0
	trust_score = min(max_trust, trust_score + 5)
	_update_trust()

	if trust_score >= max_trust:
		is_befriended = true
		emit_signal("befriended")
		_trigger_reaction("befriended")
	else:
		emit_signal("amused")
		_trigger_reaction("smiling")

func _trigger_reaction(anim_name: String):
	if is_stopped: return
	state = State.REACT
	anim.play(anim_name)
	reaction_timer.start(2.0)

func _on_reaction_timeout():
	if is_stopped: return
	if state != State.PANIC:
		state = State.WALKING

# --------------------------------------------------
# PANIC
# --------------------------------------------------
func _trigger_panic(pos: Vector2):
	if is_stopped: return

	state = State.PANIC
	anim.play("spooked")
	walk_direction = -1 if pos.x > global_position.x else 1
	speed *= 2.5
	panic_timer.start(3.0)

func _on_panic_timeout():
	if is_stopped: return
	speed /= 2.5
	state = State.WALKING

# --------------------------------------------------
# LOITER
# --------------------------------------------------
func _on_loiter_entered(body, area):
	if body != self: return
	if state != State.WALKING or not can_loiter or area == last_loiter_area: return
	if randf() < 0.4:
		last_loiter_area = area
		_start_loiter()

func _start_loiter():
	state = State.IDLE
	can_loiter = false
	walk_direction *= -1
	loiter_timer.start(randf_range(3.0, 6.0))

func _on_loiter_timeout():
	if is_stopped: return

	if state == State.IDLE:
		state = State.WALKING
		loiter_timer.start(2.0)
	else:
		can_loiter = true

# --------------------------------------------------
# STAIRS (SIMPLIFIED SAFE VERSION)
# --------------------------------------------------
func _on_stair_entered(body, stair):
	if body != self or stair_cooldown or state != State.WALKING: return
	stair_cooldown = true
	state = State.USING_STAIRS
	stair_timer.start(2.0)

func _on_stair_timeout():
	if is_stopped: return
	stair_cooldown = false
	state = State.WALKING

# --------------------------------------------------
# UI / ANIMATION
# --------------------------------------------------
func _update_trust():
	var t = create_tween()
	t.tween_property(trust_bar, "value", trust_score, 0.4)

func _on_anim_finished():
	if state == State.REACT:
		state = State.WALKING

func _update_animation():
	if state == State.REACT: return

	var moving = velocity.length() > 5
	var prefix = "befriended " if is_befriended else ""
	var name = prefix + ("walk" if moving else "idle")

	if anim.sprite_frames.has_animation(name):
		anim.play(name)

	if velocity.x != 0:
		anim.flip_h = velocity.x < 0

# --------------------------------------------------
# SAFE SHUTDOWN
# --------------------------------------------------
func stop_npc():
	is_stopped = true
	state = State.IDLE
	velocity = Vector2.ZERO

	reaction_timer.stop()
	panic_timer.stop()
	loiter_timer.stop()
	stair_timer.stop()

	set_physics_process(false)
	set_process(false)
