extends Control

@export var resume : BaseButton
@export var main_menu : BaseButton

func _ready():
	get_tree().paused = true
	var game := get_node("/root/Game") as Game
	game.gui.visible = false
	resume.pressed.connect(_on_resume_pressed)
	main_menu.pressed.connect(_on_main_menu_pressed)

func _exit_tree():
	get_tree().paused = false
	var game := get_node("/root/Game") as Game
	game.gui.visible = true

func _on_resume_pressed():
	AudioHelper.play_click()
	queue_free()

func _on_main_menu_pressed():
	AudioHelper.play_click()
	get_tree().change_scene_to_file("res://scene/ui/mainmenu/MainMenu.tscn")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		AudioHelper.play_pause()
		queue_free()
