extends Node

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	var player := AudioStreamPlayer.new()
	player.stream = load("res://assets/audio/music/playlist.tres") as AudioStreamPlaylist
	player.bus = "Music"
	add_child(player)
	player.play()
