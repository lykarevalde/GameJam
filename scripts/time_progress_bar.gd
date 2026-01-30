extends ProgressBar

@export var game_manager_path: NodePath
var game_manager: Node
var game_timer: Timer

func _ready():
	game_manager = get_node(game_manager_path)
	game_timer = game_manager.game_timer
	
	max_value = 100
	value = 100
	set_process(true)

func _process(_delta):
	if game_timer and game_timer.time_left > 0:
		value = (game_timer.time_left / game_timer.wait_time) * 100
	else:
		value = 0
