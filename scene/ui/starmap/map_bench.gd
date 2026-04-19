extends StaticBody2D
class_name MapBench

@export var interact_area : Area2D
@export var interact_panel : Control

var _disabled : bool
var disabled : bool:
	set(value):
		if value and interact_panel.visible:
			interact_panel.visible = false
		_disabled = value
	get:
		return _disabled

func _ready() -> void:
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)

func _on_body_entered(body : Node2D):
	var game := get_node("/root/Game") as Game
	if body != game.player:
		return
	if disabled:
		if not game.ship_random:
			return
		var enemy_count = 0
		for child in game.ship_random.get_children():
			if child is DefaultCrewman:
				enemy_count += 1
		if enemy_count == 0:
			disabled = false
		else:
			return
	interact_panel.visible = true

func _on_body_exited(body : Node2D):
	var game := get_node("/root/Game") as Game
	if body != game.player:
		return
	interact_panel.visible = false

func _input(event: InputEvent) -> void:
	if not disabled and interact_panel.visible and event.is_action_pressed("interact"):
		var game := get_node("/root/Game") as Game
		game.starmap.show_map()
