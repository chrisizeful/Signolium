extends Node
class_name Cutscene

var active := false

func _ready():
	# Setup Dialogic
	Dialogic.dialog_ending_timeline = DialogicTimeline.new()
	Dialogic.dialog_ending_timeline.from_text("")
	Dialogic.Choices.use_input_action = true

func start_dialog(timeline : String) -> void:
	active = true
	# Change camera
	var game := get_node("/root/Game") as Game
	game.pcam_player.priority = 1
	# Setup Dialogic
	Dialogic.timeline_ended.connect(_on_dialog_finished, CONNECT_ONE_SHOT)
	Dialogic.Text.speaker_updated.connect(_on_speaker_updated)
	Dialogic.start(timeline)

func _on_dialog_finished() -> void:
	active = false
	# Change camera
	var game := get_node("/root/Game") as Game
	game.pcam_player.priority = 0
	game.pcam_ship.priority = 1
	game.pcam_player.follow_target = game.player
	Dialogic.Text.speaker_updated.disconnect(_on_speaker_updated)

func _on_speaker_updated(character: DialogicCharacter) -> void:
	# Try to find target by nuickname or display name
	var game := get_node("/root/Game") as Game
	var node_name := character.display_name
	if not character.nicknames.is_empty() and not character.nicknames[0].is_empty():
		node_name = character.nicknames[0]
	var target := game.find_child(node_name, true, false)
	if target:
		game.pcam_player.follow_target = target
