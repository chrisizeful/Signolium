extends Sprite2D
class_name Slash

@export var area : Area2D

func _ready():
	area.connect("body_entered", _on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	var game := get_node("/root/Game") as Game
	if body != game.player:
		return
	var health := body.find_child("Health", true, false) as Health
	health.value -= 1
