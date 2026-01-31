# GameManager.gd
extends Node

signal score_changed(score)

var score := 0
var befriended_kids := 0
var befriended_npcs := {}
const TOTAL_KIDS := 10
var game_ending := false

@export var scoreboard_scene_path := "res://scenes/scoreboard.tscn"
@export var game_time_seconds := 300  # e.g., 60 seconds for the game
var game_timer: Timer

func _ready():
	for f in get_tree().get_nodes_in_group("furniture"):
		if f.has_signal("player_possessed_furniture"):
			f.player_possessed_furniture.connect(_on_player_possessed)

	call_deferred("_connect_npc_signals")
	
	# Create a one-shot Timer but don't start yet
	game_timer = Timer.new()
	game_timer.wait_time = game_time_seconds
	game_timer.one_shot = true
	add_child(game_timer)
	game_timer.timeout.connect(_on_game_timer_timeout)
	
	# Only start the game if the main menu flagged it
	if ScoreData.start_game_from_main_menu:
		start_game()
		ScoreData.start_game_from_main_menu = false  # reset flag
	
func start_game():
	ScoreData.game_lost = false
	befriended_npcs.clear()
	befriended_kids = 0
	game_ending = false
	# Start timer
	game_timer.start()
	print("Game started! Timer running for %d seconds." % game_time_seconds)

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
	add_score(20)

func _on_player_spooked(penalty: int):
	add_score(-penalty)

func kid_befriended(npc):
	befriended_kids += 1
	print("Kid befriended:", befriended_kids, "/", TOTAL_KIDS)
	add_score(100)

	if befriended_kids >= TOTAL_KIDS:
		call_deferred("_end_game")

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
	
func _on_game_timer_timeout():
	if befriended_kids < TOTAL_KIDS:
		print("Time's up! You lost!")
		_end_game_lost()
		
		
func _end_game_lost():
	# Stop NPCs
	for kid in get_tree().get_nodes_in_group("npcs"):
		if kid.has_method("stop_npc"):
			kid.stop_npc()
	
	# Save score & tell scoreboard we’re in post-game mode
	ScoreData.final_score = score
	ScoreData.post_game_mode = true
	ScoreData.game_lost = true  
	game_ending = false

	# reset AFTER transition
	score = 0
	befriended_kids = 0
	befriended_npcs.clear()
	
	
	# Change to scoreboard
	get_tree().change_scene_to_file(scoreboard_scene_path)
	
	
func _check_end_game():
	# This runs AFTER all signals in the frame are processed
	if befriended_kids >= TOTAL_KIDS:
		_end_game()
	else:
		game_ending = false
