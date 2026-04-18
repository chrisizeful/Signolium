extends Control
class_name MainMenu

@export var menu : Control
@export var logo : Control
@export var play : BaseButton
@export var settings : BaseButton
@export var quit : BaseButton

func _ready() -> void:
	play.pressed.connect(_on_play_pressed)
	settings.pressed.connect(_on_settings_pressed)
	quit.pressed.connect(get_tree().quit)

func _on_play_pressed():
	AudioHelper.play_click()
	get_tree().change_scene_to_file("res://scene/game/Game.tscn")

func _on_settings_pressed():
	AudioHelper.play_click()
	set_show_menu(false)
	add_child(load("res://scene/ui/mainmenu/Settings.tscn").instantiate())

func set_show_menu(show : bool) -> void:
	menu.visible = show
	logo.visible = show
