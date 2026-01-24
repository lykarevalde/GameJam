extends CharacterBody2D

signal possession_finished(furniture)

@export var move_distance := 40.0
@export var move_speed := 60.0
@export var possession_time := 1.5

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var possessed := false
var timer := 0.0
var direction := 1
var origin := Vector2.ZERO

func _ready():
	origin = global_position
	#anim.play("move")

func _physics_process(delta):
	if not possessed:
		return

	velocity = Vector2(direction * move_speed, 0)
	move_and_slide()

	if abs(global_position.x - origin.x) >= move_distance:
		direction *= -1

	timer -= delta
	if timer <= 0:
		end_possession()

func on_possessed() -> bool:
	if possessed:
		return false   # 🔒 HARD LOCK

	possessed = true
	timer = possession_time
	direction = [-1, 1].pick_random()
	#anim.play("shake")


	print("[Furniture] POSSESSED:", name)
	return true

func end_possession():
	possessed = false
	velocity = Vector2.ZERO
	global_position = origin
	#anim.play("idle")

	print("[Furniture] RELEASED:", name)
	emit_signal("possession_finished", self)
