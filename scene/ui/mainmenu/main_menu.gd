extends Control

@export var play : BaseButton
@export var settings : BaseButton
@export var quit : BaseButton

func _ready() -> void:
	play.pressed.connect(_on_play_pressed)
	settings.pressed.connect(_on_settings_pressed)
	quit.pressed.connect(get_tree().quit)

func _on_play_pressed():
	pass

func _on_settings_pressed():
	pass
