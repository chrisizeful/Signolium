extends Node2D
class_name Game

const TILE_SIZE = 16

@export var player : Character
@export var characters : Node2D

@export var camera : Camera2D
@export var pcam_ship : PhantomCamera2D
@export var pcam_player : PhantomCamera2D

@export var interface : CanvasLayer
@export var starmap : Starmap
@export var cutscene : Cutscene

@export var ship : Ship
@export var ship_enemy : Ship
@export var ship_random : Ship

var _text_first : bool

func _ready():
	randomize()
	for character in characters.get_children():
		set_enabled(character, false)
	cutscene.start_dialog("res://assets/dialog/timeline/intro.dtl")
	Dialogic.timeline_ended.connect(_align_ships_intro)
	Dialogic.Text.about_to_show_text.connect(_on_text_show)
	Dialogic.timeline_ended.connect(AudioHelper.play_click)

func _exit_tree():
	Dialogic.timeline_ended.disconnect(AudioHelper.play_click)
	if Dialogic.timeline_ended.is_connected(_align_ships_intro):
		Dialogic.timeline_ended.disconnect(_align_ships_intro)
	Dialogic.end_timeline(true)

func _on_text_show(_info : Dictionary):
	if _text_first:
		AudioHelper.play_click()
	_text_first = true

func align_ships(player_ship : Ship = ship, other_ship : Ship = ship_enemy, change_camera := true, move_player := true) -> Tween:
	# Switch to ship camera
	if change_camera:
		pcam_player.priority = 0
		pcam_ship.priority = 1
		pcam_player.follow_target = player
	# Align
	other_ship.align(player_ship)
	# Wait for ships to connect
	await get_tree().create_timer(player_ship.align_time).timeout
	# Open doors
	player_ship.set_open(true)
	other_ship.set_open(true)
	# Tween player to center of enemy ship
	if move_player:
		var ship_width := other_ship.get_width() * TILE_SIZE
		var ship_center_x := other_ship.position.x + ship_width / 2.0
		var target_x = ship_center_x - TILE_SIZE / 2.0
		var target_position := Vector2(target_x, player.global_position.y)
		var tween := create_tween()
		tween.tween_property(player, "global_position", target_position, 0.7).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		return tween
	return null

func _align_ships_intro(player_ship : Ship = ship, other_ship : Ship = ship_enemy):
	Dialogic.timeline_ended.disconnect(_align_ships_intro)
	var tween = await align_ships(player_ship, other_ship)
	# Play other part of intro
	if tween:
		await tween.finished
	Dialogic.timeline_ended.connect(_take_off)
	_text_first = false
	Dialogic.start("res://assets/dialog/timeline/intro2.dtl")

func _take_off(player_ship : Ship = ship, other_ship : Ship = ship_enemy):
	Dialogic.timeline_ended.disconnect(_take_off)
	# Close doors
	player_ship.set_open(false)
	other_ship.set_open(false)
	# Camera on player
	player.reparent(self)
	pcam_player.priority = 1
	pcam_ship.priority = 0
	pcam_player.follow_mode = PhantomCamera2D.FollowMode.SIMPLE
	pcam_player.follow_target = player
	# Move the ship off screen by tweening its position
	var target_position := Vector2(2000, player_ship.position.y)
	var tween := create_tween()
	tween.tween_property(player_ship, "position", target_position, 1.2).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	# End cutscene
	await tween.finished
	_end_cutscene()

func _end_cutscene():
	cutscene.active = false
	for character in characters.get_children():
		set_enabled(character, true)
	set_enabled(player, true)

func set_enabled(node : Node, enabled : bool):
	node.set_process(enabled)
	node.set_physics_process(enabled)
	node.set_process_input(enabled)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		var pause = load("res://scene/ui/pause/pause_menu.tscn").instantiate()
		interface.add_child(pause)
