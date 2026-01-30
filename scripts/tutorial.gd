extends Node2D

@onready var player = get_tree().get_first_node_in_group("ghost")
@onready var label = $InstructionLabel
@onready var enemy = $Enemy

var tutorial_prompts := [
	"Press W,A,S,D to move around",
	"Go near an interactable object and press SPACE to possess it",
	"While possessing something, press E near children to amuse them",
	"keep amusing them to fill their trust meter to befriend them",
	"Amusing drains energy which regenerates over time",
	"Press SPACE again to unpossess the object",
	"Other ghosts will posses objects to scare children and can lower your trust meter",
	"Befriend as much children as you can within the time limit"
]

var step = 0

func _ready():
	enemy.visible = false
	enemy.set_physics_process(false)
	_update_prompt()

var fake_trust_done := false
var enemy_spawned := false

func _process(delta):
	match step:
		0:
			#Move around
			if player_moved():
				step+=1
				_update_prompt()
		1:
			#Go near object and posses
			if player.nearby_furniture != null and player.possessed_furniture != null:
				step+=1
				_update_prompt()
		2:
			#amuse
			if player.energy < player.MAX_ENERGY:
				step+=1
				_update_prompt()
		3:
			#fill trust meter
			if fake_trust_done:
				step+=1
				_update_prompt()
		4:
			#energy
			if player.energy < player.MAXC_ENERGY:
				step += 1
				_update_prompt()
		5:
			#unposses
			if player.possessed_furniture == null:
				step += 1
				_update_prompt()
		6:
			#enemy ghost
			#if enemy_spawned():
				step += 1
				_update_prompt()
		7:
			#goal
			pass
			
func _update_prompt():
	if step < tutorial_prompts.size():
		label.text = tutorial_prompts[step]
	else:
		label.text = ""
		
func player_moved() -> bool:
	return player.velocity.length() > 10
	
func spawn_enemy():
	enemy.visible = true
	enemy.set_physics_process(true)
