extends CharacterBody2D

@export var speed := 60.0
@export var scared_duration := 1.5

@onready var path_follow := get_parent() as PathFollow2D
@onready var anim := $AnimatedSprite2D

var scared := false

func _physics_process(delta):
	if scared:
		return

	path_follow.progress += speed * delta

func on_scared():
	if scared:
		return

	scared = true
	anim.play("scared")
	print("[Human] SCARED:", name)

	await get_tree().create_timer(scared_duration).timeout

	scared = false
	anim.play("walk")
