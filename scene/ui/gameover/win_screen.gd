extends Control

@export var return_button : BaseButton

func _ready():
	return_button.pressed.connect(_on_return_pressed)

func _on_return_pressed():
	AudioHelper.play_click()
	get_tree().change_scene_to_file("res://scene/ui/mainmenu/MainMenu.tscn")
