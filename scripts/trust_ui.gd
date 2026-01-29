extends CanvasLayer

@onready var bar = $TextureProgressBar

func _ready():
	hide() # Hide until player is near
	# Connect global NPC signals
	for npc in get_tree().get_nodes_in_group("npcs"):
		npc.trust_changed.connect(_update_bar)
		npc.player_near_npc.connect(_show_ui)
		npc.player_left_npc.connect(_hide_ui)

func _show_ui(npc):
	_update_bar(npc.trust_score, npc.max_trust, npc)
	show()

func _hide_ui(_npc):
	hide()

func _update_bar(value, max_val, _npc):
	bar.max_value = max_val
	bar.value = value
