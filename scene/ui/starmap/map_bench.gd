extends StaticBody2D

@export var interact_area : Area2D
@export var interact_panel : Control

func _ready() -> void:
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)

func _on_body_entered(body : Node2D):
	var game := get_node("/root/Game") as Game
	if body != game.player:
		return
	interact_panel.visible = true

func _on_body_exited(body : Node2D):
	var game := get_node("/root/Game") as Game
	if body != game.player:
		return
	interact_panel.visible = false

func _input(event: InputEvent) -> void:
	if interact_panel.visible and event.is_action_pressed("interact"):
		var game := get_node("/root/Game") as Game
		game.starmap.show_map()
