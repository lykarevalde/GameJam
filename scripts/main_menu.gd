extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_play_pressed() -> void:
	# Pass a flag to tell the game scene that it should start immediately
	ScoreData.start_game_from_main_menu = true
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _on_how_to_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/tutorial.tscn")

func _on_scoreboard_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/scoreboard.tscn")


func _on_credits_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/game.tscn")
