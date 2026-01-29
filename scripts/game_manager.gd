# GameManager.gd
extends Node

signal score_changed(score)
signal game_won
signal game_lost

# -----------------------------
# GAME STATE
# -----------------------------
var score := 0
var befriended_kids := 0
const TOTAL_KIDS := 2  # total NPC kids to befriend

# Path to your scoreboard scene
@export var scoreboard_scene_path := "res://scenes/scoreboard.tscn"

func _ready():
	# Connect furniture signals for scoring
	for f in get_tree().get_nodes_in_group("furniture"):
		if f.has_signal("player_possessed"):
			f.player_possessed.connect(_on_player_possessed)
		if f.has_signal("player_amused"):
			f.player_amused.connect(_on_player_amused)

	# Connect kid signals for befriending
	for kid in get_tree().get_nodes_in_group("kids"):
		if kid.has_method("is_befriended"):
			kid.connect("tree_exited", Callable(self, "_check_kid_befriended"))

	
	connect("game_won", Callable(self, "_show_scoreboard"))
	connect("game_lost", Callable(self, "_show_scoreboard"))

# -----------------------------
# SCORING
# -----------------------------
func add_score(amount: int) -> void:
	score += amount
	print("Score: ", score)
	emit_signal("score_changed", score)

func _on_player_possessed() -> void:
	add_score(5)

func _on_player_amused() -> void:
	add_score(10)

func kid_befriended():
	befriended_kids += 1
	add_score(100)
	print("Befriended kids: ", befriended_kids, " / ", TOTAL_KIDS)

	if befriended_kids >= TOTAL_KIDS:
		print("YOU WON!!!!!")
		print("Final Score: ", score)
		
		ScoreData.final_score = score
		
		emit_signal("game_won")
		end_game()


func _check_kid_befriended() -> void:
	# This function checks if a kid is befriended (for signals)
	var befriended_count = 0
	for kid in get_tree().get_nodes_in_group("kids"):
		if kid.has_method("is_befriended") and kid.is_befriended:
			befriended_count += 1
	befriended_kids = befriended_count
	if befriended_kids >= TOTAL_KIDS:
		emit_signal("game_won")


func end_game():
	reset_game_state()
	reset_npcs()

func reset_game_state():
	score = 0
	befriended_kids = 0

func reset_npcs():
	for kid in get_tree().get_nodes_in_group("kids"):
		if kid.is_inside_tree():
			kid.state = kid.State.WALKING
			kid.is_befriended = false
			kid.consecutive_amuses = 0
			kid.consecutive_spooks = 0


# -----------------------------
# GAME OVER / SCOREBOARD
# -----------------------------
func _show_scoreboard() -> void:
	# Check if the scoreboard scene exists
	if not FileAccess.file_exists(scoreboard_scene_path):
		push_error("Scoreboard scene not found at: %s" % scoreboard_scene_path)
		return

	# Change scene properly
	var err = get_tree().change_scene_to_file(scoreboard_scene_path)
	if err != OK:
		push_error("Failed to load scoreboard scene.")
	else:
		print("Scoreboard shown. Final Score: ", score)
