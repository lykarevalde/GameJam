extends Node2D

@export var npc_scene: PackedScene            # assign HumanNPC.tscn
@export var npc_per_floor := 5               # how many NPCs per floor
@export var floor1_path: Path2D              # assign Floor1Path
@export var floor2_path: Path2D              # assign Floor2Path

@onready var bgm = $BGM

func _ready():
	# Debug checks
	bgm.play()
	if npc_scene == null:
		print("ERROR: npc_scene not assigned")
	if floor1_path == null or floor2_path == null:
		print("ERROR: floor paths not assigned")
		
	

	# Spawn NPCs on both floors
#	spawn_npcs_on_path(floor1_path, npc_per_floor)
#	spawn_npcs_on_path(floor2_path, npc_per_floor)


#func spawn_npcs_on_path(path: Path2D, count: int):
#	for i in range(count):
#		# Create PathFollow2D for this NPC
#		var follow = PathFollow2D.new()
#		follow.rotates = false
#		# spread NPCs evenly along path + slight random offset
#		follow.progress_ratio = i / float(count) + randf() * 0.05
#		path.add_child(follow)

		# Instantiate NPC and parent to PathFollow2D
#		var npc = npc_scene.instantiate()
#		npc.position = Vector2.ZERO
#		follow.add_child(npc)

		


func _on_bgm_finished() -> void:
	bgm.play()
