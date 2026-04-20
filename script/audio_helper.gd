extends Node

func play_sound(path : String):
	var sound := AudioStreamPlayer.new()
	sound.process_mode = Node.PROCESS_MODE_ALWAYS
	sound.bus = "Sound"
	sound.stream = load(path)
	add_child(sound)
	sound.finished.connect(sound.queue_free)
	sound.play()

func play_click():
	play_sound("res://assets/audio/Click.wav")

func play_map():
	play_sound("res://assets/audio/Map.wav")

func play_sector():
	play_sound("res://assets/audio/Sector.wav")

func play_pause():
	play_sound("res://assets/audio/Pause.wav")

func play_slash():
	play_sound("res://assets/audio/Slash.wav")

func play_hurt():
	play_sound("res://assets/audio/Hurt.wav")

func play_pickup():
	play_sound("res://assets/audio/Pickup.wav")

func play_coin():
	play_sound("res://assets/audio/Pickup.wav")

func play_error():
	play_sound("res://assets/audio/Error.wav")

func play_shoot():
	var files := [
		"res://assets/audio/Shoot0.wav",
		"res://assets/audio/Shoot1.wav",
		"res://assets/audio/Shoot2.wav"
	]
	play_sound(files[randi_range(0, len(files) - 1)])
