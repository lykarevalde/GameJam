extends Node2D

@export var npc_scene : PackedScene
@export var npc_per_floor := 3

@onready var spawn_points = $kids.get_children()

func _ready():
	var floor1 := []
	var floor2 := []

	for marker in spawn_points:
		if "Floor1" in marker.name:
			floor1.append(marker)
		elif "Floor2" in marker.name:
			floor2.append(marker)

	spawn_npcs(floor1, npc_per_floor)
	spawn_npcs(floor2, npc_per_floor)

func spawn_npcs(markers, count):
	for i in range(count):
		var npc = npc_scene.instantiate()
		var marker = markers.pick_random()
		npc.global_position = marker.global_position + Vector2(4,0) 
		add_child(npc)
