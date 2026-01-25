extends CharacterBody2D

# Sprites
@onready var idle_sprite = self
@onready var amuse_sprite = $amuse_sprite
@onready var spook_sprite = $spook_sprite

# State
var is_animating := false
var nearby_player := false

# ==========================
# PLAYER AMUSE
# ==========================
func amuse():
	if not nearby_player:
		return
	if is_animating:
		return

	is_animating = true
	_show_only(amuse_sprite)
	amuse_sprite.play("amuse")
	print("Furniture: Player is amused!")

func _on_amuse_animation_finished():
	_reset()

# ==========================
# ENEMY SPOOK
# ==========================
func spook():
	if is_animating:
		return

	is_animating = true
	_show_only(spook_sprite)

	var animations = ["spook1", "spook2", "spook3"]
	spook_sprite.play(animations.pick_random())
	print("Furniture: Spooked an enemy!")

func _on_spook_animation_finished():
	_reset()

# ==========================
# HELPERS
# ==========================
func _reset():
	idle_sprite.show()
	amuse_sprite.hide()
	spook_sprite.hide()
	idle_sprite.play("idle")
	is_animating = false

func _show_only(sprite):
	idle_sprite.hide()
	amuse_sprite.hide()
	spook_sprite.hide()
	sprite.show()

# ==========================
# PLAYER DETECTION
# ==========================
func _on_area_2d_body_entered(body):
	if body.is_in_group("Player"):
		nearby_player = true

func _on_area_2d_body_exited(body):
	if body.is_in_group("Player"):
		nearby_player = false
