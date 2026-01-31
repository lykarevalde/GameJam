extends Node2D

@onready var player = get_tree().get_first_node_in_group("ghost")
@onready var prompt: Sprite2D = $CanvasLayer/InstructionPrompt
@onready var pressF = $CanvasLayer/PressF
@onready var skip = $CanvasLayer/skip
@onready var enemy = $Enemy
@onready var child = $NPC

var prompt_textures := [
	preload("res://assets/tutorial assets textboxes/1.png"), #0
	preload("res://assets/tutorial assets textboxes/2.png"), #1
	preload("res://assets/tutorial assets textboxes/3.png"), #2
	preload("res://assets/tutorial assets textboxes/4.png"), #3
	preload("res://assets/tutorial assets textboxes/5.png"), #4
	preload("res://assets/tutorial assets textboxes/6.png"), #5
	preload("res://assets/tutorial assets textboxes/7.png"), #6
	preload("res://assets/tutorial assets textboxes/8.png")  #7
]

var step = 0
var enemy_spawned := false
var fake_trust_done := false

func _ready():
	prompt.visible = true
	prompt.centered = true
	var screen_size = get_viewport_rect().size
	prompt.position.x = screen_size.x / 2
	prompt.position.y = 200
	prompt.scale = Vector2(1, 1)
	
	pressF.text = "Press F to continue"
	pressF.show()
	pressF.position = Vector2(prompt.position.x, prompt.position.y + 60)
	
	skip.text = "Press ESC to skip"
	skip.show()
	skip.position = Vector2(screen_size.x - 150, 10)
	
	enemy.visible = false
	enemy.set_physics_process(false)
	
	prompt.texture = prompt_textures[0]
	
	for child in get_tree().get_nodes_in_group("npcs"):
		child.befriended.connect(on_child_befriended)

func _process(delta):
	if Input.is_action_just_pressed("ui_cancel"):
		end_tutorial()
		return
	
	match step:
		0:#Move around
			#if player_moved():
			if Input.is_action_just_pressed("next"):
				step+=1
				_update_prompt()
		1:#Go near object and posses
			#if player.nearby_furniture != null and player.possessed_furniture != null:
			if Input.is_action_just_pressed("next"):
				step+=1
				_update_prompt()
		2:#amuse
			#if player.energy < player.MAX_ENERGY:
			if Input.is_action_just_pressed("next"):
				step+=1
				_update_prompt()
		3:#fill trust meter
			#if fake_trust_done:
			if Input.is_action_just_pressed("next"):
				step+=1
				_update_prompt()
		4:#energy
			#if player.energy < player.MAX_ENERGY:
			if Input.is_action_just_pressed("next"):
				step += 1
				_update_prompt()
		5:#unposses
			#if player.possessed_furniture == null:
			if Input.is_action_just_pressed("next"):
				step += 1
				_update_prompt()
		6:#enemy ghost
			spawn_enemy()
			#if enemy_spawned():
			if Input.is_action_just_pressed("next"):
				step += 1
				_update_prompt()
		7:#goal
			if Input.is_action_just_pressed("next"):
				end_tutorial()
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

func end_tutorial():
	ScoreData.start_game_from_main_menu = true
	get_tree().change_scene_to_file("res://scenes/game.tscn")
	#prompt.visible = false
	#pressF.hide()
	#enemy.visible = false
	#enemy.set_physics_process(false)
