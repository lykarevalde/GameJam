# GameManager.gd
extends Node

signal score_changed(score)

var score := 0
var befriended_kids := 0
const TOTAL_KIDS := 1

@export var scoreboard_scene_path := "res://scenes/scoreboard.tscn"

func _ready():
	for f in get_tree().get_nodes_in_group("furniture"):
		if f.has_signal("player_possessed_furniture"):
			f.player_possessed_furniture.connect(_on_player_possessed)

	call_deferred("_connect_npc_signals")

# -----------------------------
# SCORING
# -----------------------------
func add_score(amount: int):
	score += amount
	emit_signal("score_changed", score)
	print("Score:", score)

func _on_player_possessed():
	add_score(5)

func _on_player_amused():
	add_score(10)

func _on_player_spooked(penalty: int):
	add_score(-penalty)

func kid_befriended():
	befriended_kids += 1
	add_score(100)

	if befriended_kids >= TOTAL_KIDS:
		ScoreData.final_score = score
		_end_game()

# -----------------------------
# NPC SIGNALS
# -----------------------------
func _connect_npc_signals():
	for kid in get_tree().get_nodes_in_group("npcs"):
		kid.befriended.connect(kid_befriended)
		kid.amused.connect(_on_player_amused)
		kid.spooked.connect(_on_player_spooked)

# -----------------------------
# GAME END (SAFE)
# -----------------------------
func _end_game():
	#  Stop NPCs FIRST
	for kid in get_tree().get_nodes_in_group("npcs"):
		if kid.has_method("stop_npc"):
			kid.stop_npc()
	
	# Save score & tell scoreboard we’re in post-game mode
	ScoreData.final_score = score
	ScoreData.post_game_mode = true
	
	# Reset state
	score = 0
	befriended_kids = 0

	#  Change scene LAST
	get_tree().change_scene_to_file(scoreboard_scene_path)
