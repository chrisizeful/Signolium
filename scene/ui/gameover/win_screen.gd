extends Control

@export var return_button : BaseButton

func _ready():
	Jukebox.player.stop()
	return_button.pressed.connect(_on_return_pressed)

func _exit_tree():
	Jukebox.player.play()

func _on_return_pressed():
	AudioHelper.play_click()
	get_tree().change_scene_to_file("res://scene/ui/mainmenu/MainMenu.tscn")
