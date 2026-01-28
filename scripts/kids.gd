extends CharacterBody2D

@export var speed := 60.0
@export var scared_speed := 100.0
@export var scared_duration := 1.5

@onready var path_follow := get_parent() as PathFollow2D
@onready var anim := $AnimatedSprite2D

var scared := false

#func _ready():
	#for furniture in get_tree().get_nodes_in_group("furniture"):
		#furniture.possession_started.connect(on_furniture_possessed)


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
	

func on_furniture_possessed():
	if scared:
		return

	scared = true
	#anim.play("scared")
	print("[Kid] I SAW POSSESSED FURNITURE!")

	await get_tree().create_timer(scared_duration).timeout

	scared = false
	#anim.play("walk")
