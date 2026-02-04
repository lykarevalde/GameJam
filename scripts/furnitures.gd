extends Node2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
var possessed := false

func on_possessed():
	possessed = true
	print(name, " is possessed!")
	if anim:
		anim.play("shake")
		print("shake")  # play possession animation

func on_possession_end():
	possessed = false
	if anim:
		anim.play("idle")
		print("idle")
