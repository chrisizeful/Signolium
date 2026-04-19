extends Sprite2D
class_name Heart

@export var area : Area2D

func _ready():
	area.body_entered.connect(_on_body_entered)

func _on_body_entered(node : Node2D) -> void:
	var game := get_node("/root/Game") as Game
	if node == game.player:
		AudioHelper.play_pickup()
		game.player.health.value += 2
		queue_free()
