extends Control
class_name MainMenu

@export var menu : Control
@export var play : BaseButton
@export var settings : BaseButton
@export var quit : BaseButton

func _ready() -> void:
	play.pressed.connect(_on_play_pressed)
	settings.pressed.connect(_on_settings_pressed)
	quit.pressed.connect(get_tree().quit)

func _on_play_pressed():
	get_tree().change_scene_to_file("res://scene/game/Game.tscn")

func _on_settings_pressed():
	menu.visible = false
	add_child(load("res://scene/ui/mainmenu/Settings.tscn").instantiate())
