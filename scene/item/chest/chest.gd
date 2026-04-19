extends Sprite2D
class_name Chest

@export var area : Area2D

func _ready():
	area.body_entered.connect(_on_body_entered)

func _on_body_entered(node : Node2D) -> void:
	var game := get_node("/root/Game") as Game
	if node == game.player:
		AudioHelper.play_coin()
		game.player.coins += 1
		queue_free()
