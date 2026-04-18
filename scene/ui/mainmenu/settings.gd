extends Control
class_name Settings

@export var back : BaseButton
@export var master : HSlider
@export var sound : HSlider
@export var music : HSlider

func _ready() -> void:
	back.pressed.connect(_on_back_pressed)

	master.value = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master")))
	sound.value = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Sound")))
	music.value = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music")))

	master.value_changed.connect(_on_master_changed)
	sound.value_changed.connect(_on_sound_changed)
	music.value_changed.connect(_on_music_changed)

func _on_back_pressed():
	var menu = get_parent() as MainMenu
	menu.set_show_menu(true)
	queue_free()

func _on_master_changed(value: float):
	_set_bus_volume("Master", value)

func _on_sound_changed(value: float):
	_set_bus_volume("Sound", value)

func _on_music_changed(value: float):
	_set_bus_volume("Music", value)

func _set_bus_volume(bus_name: String, linear_value: float) -> void:
	var index = AudioServer.get_bus_index(bus_name)
	var db = linear_to_db(linear_value)
	AudioServer.set_bus_volume_db(index, db)
