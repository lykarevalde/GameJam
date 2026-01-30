extends Node2D

@onready var player = get_tree().get_first_node_in_group("ghost")
@onready var prompt: Sprite2D = $CanvasLayer/InstructionPrompt
@onready var enemy = $Enemy
@onready var child = $NPC
#@export var camera: Camera2D

var prompt_textures := [
	preload("res://assets/tutorial assets textboxes/1.png"),
	preload("res://assets/tutorial assets textboxes/2.png"),
	preload("res://assets/tutorial assets textboxes/3.png"),
	preload("res://assets/tutorial assets textboxes/4.png"),
	preload("res://assets/tutorial assets textboxes/5.png"),
	preload("res://assets/tutorial assets textboxes/6.png"),
	preload("res://assets/tutorial assets textboxes/7.png"),
	preload("res://assets/tutorial assets textboxes/8.png")
]

var step = 0
var enemy_spawned := false
var fake_trust_done := false

func _ready():
	prompt.visible = true
	prompt.position = Vector2(400, 200)
	prompt.scale = Vector2(1, 1)
	enemy.visible = false
	enemy.set_physics_process(false)
	prompt.texture = prompt_textures[0]
	for child in get_tree().get_nodes_in_group("npcs"):
		child.befriended.connect(on_child_befriended)

func _process(delta):
	match step:
		0:#Move around
			if player_moved():
				step+=1
				_update_prompt()
		1:#Go near object and posses
			if player.nearby_furniture != null and player.possessed_furniture != null:
				step+=1
				_update_prompt()
		2:#amuse
			if player.energy < player.MAX_ENERGY:
				step+=1
				_update_prompt()
		3:#fill trust meter
			if fake_trust_done:
				step+=1
				_update_prompt()
		4:#energy
			if player.energy < player.MAX_ENERGY:
				step += 1
				_update_prompt()
		5:#unposses
			if player.possessed_furniture == null:
				step += 1
				_update_prompt()
		6:#enemy ghost
			#if enemy_spawned():
				step += 1
				_update_prompt()
		7:#goal
			pass
			
func _update_prompt():
	if step < prompt_textures.size():
		prompt.texture = prompt_textures[step]
		
func player_moved() -> bool:
	return player.velocity.length() > 10
	
func spawn_enemy():
	enemy.visible = true
	enemy.set_physics_process(true)

func on_child_befriended():
	fake_trust_done = true
