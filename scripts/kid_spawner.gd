extends Node2D

@export var npc_scene: PackedScene
@export var floor1_path: Path2D
@export var floor2_path: Path2D
@export var npc_per_floor := 5

func _ready():
	spawn_npcs(floor1_path, npc_per_floor)
	spawn_npcs(floor2_path, npc_per_floor)

func spawn_npcs(path: Path2D, count: int):
	for i in range(count):
		var follow = PathFollow2D.new()
		follow.rotates = false
		# spread evenly along path
		follow.progress_ratio = i / float(count)
		path.add_child(follow)

		var npc = npc_scene.instantiate()
		npc.position = Vector2.ZERO
		follow.add_child(npc)
