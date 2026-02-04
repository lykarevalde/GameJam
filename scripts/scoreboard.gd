extends Control
class_name Scoreboard

# -------------------------
# UI Nodes
# -------------------------
@onready var score_label: Label = $MainContainer/VBoxContainer4/ScoreLabel
@onready var name_input: LineEdit = $MainContainer/VBoxContainer2/NameInput
@onready var save_button: Button = $MainContainer/VBoxContainer/SaveButton
@onready var highscore_list: VBoxContainer = $MainContainer/VBoxContainer3/HighscoreList
@onready var back_button: Button = $MainContainer/VBoxContainer5/BackButton

# -------------------------
# Constants
# -------------------------
@export var post_game_mode: bool = false  # true if coming from a finished game
const HIGHSCORE_FILE := "user://highscores.json"
const MAX_HIGHSCORES := 10
const FONT_PATH := "res://assets/fonts/Pix32.ttf"  # replace with your font path

# -------------------------
# Input Handling
# -------------------------
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == Key.KEY_P:  # press "P" to reset highscores
			reset_highscores()

# -------------------------
# READY
# -------------------------
func _ready() -> void:
	post_game_mode = ScoreData.post_game_mode
	
	# Hide input/save if we're just viewing from main menu
	name_input.visible = post_game_mode
	save_button.visible = post_game_mode
	
	# Only show player's score if post_game_mode
	score_label.visible = post_game_mode
	if post_game_mode:
		# Display win or lose along with score
		if ScoreData.game_lost:
			score_label.text = "You Lost!\nScore: %d" % ScoreData.final_score
		else:
			score_label.text = "You Won!\nScore: %d" % ScoreData.final_score

	# Load and display highscores
	_load_highscores()

	# Apply font to main score label
	_apply_font(score_label)

	# Connect save button only if in post-game mode
	if post_game_mode:
		save_button.pressed.connect(_on_save_pressed)
		
	back_button.pressed.connect(_on_back_pressed)

# -------------------------
# Save Button
# -------------------------
func _on_save_pressed() -> void:
	var player_name: String = name_input.text.strip_edges()
	if player_name == "":
		player_name = "Anonymous"

	_save_highscore(player_name, ScoreData.final_score)

	# Reset input and refresh highscores
	name_input.text = ""
	_load_highscores()

	# Go back to main game scene
	var err := get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	if err != OK:
		push_error("Failed to load game scene.")


# -------------------------
# Back Button
# -------------------------
func _on_back_pressed() -> void:
	var err := get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	if err != OK:
		push_error("Failed to load main menu scene.")


# -------------------------
# Highscore Saving
# -------------------------
func _save_highscore(name: String, score: int) -> void:
	var highscores: Array = []

	# Load existing highscores
	if FileAccess.file_exists(HIGHSCORE_FILE):
		var file = FileAccess.open(HIGHSCORE_FILE, FileAccess.ModeFlags.READ)
		var text = file.get_as_text()
		file.close()

		if text != "":
			var parsed = JSON.parse_string(text)
			if typeof(parsed) == TYPE_ARRAY:
				highscores = parsed
			else:
				push_warning("Highscore JSON corrupted. Starting fresh.")

	# Add new score
	highscores.append({"name": name, "score": int(score)})

	# Sort descending (top scores first)
	highscores.sort_custom(func(a, b):
		var score_a = int(a.get("score", 0))
		var score_b = int(b.get("score", 0))
		if score_a == score_b:
			return 0
		elif score_a < score_b:
			return 1
		else:
			return -1
	)

	# Keep only top MAX_HIGHSCORES
	if highscores.size() > MAX_HIGHSCORES:
		highscores = highscores.slice(0, MAX_HIGHSCORES)

	# Save back to file
	var file_save = FileAccess.open(HIGHSCORE_FILE, FileAccess.ModeFlags.WRITE)
	file_save.store_string(JSON.stringify(highscores))
	file_save.close()

# -------------------------
# Load and Display Highscores
# -------------------------
func _load_highscores() -> void:
	# Clear old labels
	for child in highscore_list.get_children():
		child.queue_free()

	var highscores: Array = []

	# Load highscores from file
	if FileAccess.file_exists(HIGHSCORE_FILE):
		var file = FileAccess.open(HIGHSCORE_FILE, FileAccess.ModeFlags.READ)
		var text = file.get_as_text()
		file.close()
		
		if text != "":
			var parsed = JSON.parse_string(text)
			if typeof(parsed) == TYPE_ARRAY:
				highscores = parsed
			else:
				push_warning("Highscore JSON corrupted.")

	# Sort descending just in case
	highscores.sort_custom(func(a, b):
		var score_a = int(a.get("score", 0))
		var score_b = int(b.get("score", 0))
		if score_a == score_b:
			return 0
		elif score_a < score_b:
			return 1
		else:
			return -1
	)

	# Display top MAX_HIGHSCORES
	for i in range(min(MAX_HIGHSCORES, highscores.size())):
		var entry = highscores[i]
		var label = Label.new()
		label.text = "%d. %s — %d" % [i + 1, entry.get("name", "Anonymous"), entry.get("score", 0)]
		_apply_font(label)
		highscore_list.add_child(label)

# -------------------------
# Font Helper
# -------------------------
func _apply_font(label: Label, size: int = 60) -> void:
	var font_file := load(FONT_PATH)
	if font_file == null:
		push_warning("Font file not found: %s" % FONT_PATH)
		return

	label.add_theme_font_size_override("font", size)  # size override
	label.add_theme_font_override("font", font_file)   # assign font file

func reset_highscores() -> void:
	if FileAccess.file_exists(HIGHSCORE_FILE):
		var file = FileAccess.open(HIGHSCORE_FILE, FileAccess.ModeFlags.WRITE)
		file.store_string("[]")  # write an empty array to clear highscores
		file.close()
		print("Highscores reset.")
		_load_highscores()  # refresh UI
