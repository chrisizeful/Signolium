extends Node2D
class_name Game

const TILE_SIZE = 16

@export var player : Character
@export var characters : Node2D

@export var camera : Camera2D
@export var pcam_ship : PhantomCamera2D
@export var pcam_player : PhantomCamera2D

@export var starmap : Starmap
@export var cutscene : Cutscene

@export var ship : Ship
@export var ship_enemy : Ship

func _ready():
	for character in characters.get_children():
		_set_enabled(character, false)
	cutscene.start_dialog("res://assets/dialog/timeline/intro.dtl")
	Dialogic.timeline_ended.connect(_align_ships)

func _align_ships():
	# Switch to ship camear
	pcam_player.priority = 0
	pcam_ship.priority = 1
	# Align
	ship_enemy.align(ship)
	Dialogic.timeline_ended.disconnect(_align_ships)
	# Wait for ships to connect
	await get_tree().create_timer(ship.align_time).timeout
	# Reparent player
	player.reparent(ship_enemy)
	pcam_player.follow_target = player
	# Tween player to center of enemy ship
	var ship_width := ship_enemy.get_width() * TILE_SIZE
	var ship_center_x := ship_enemy.position.x + ship_width / 2.0
	var target_x = ship_center_x - TILE_SIZE / 2.0
	var target_position := Vector2(target_x, player.global_position.y)
	var tween := create_tween()
	tween.tween_property(player, "global_position", target_position, 0.7).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	# Play other part of intro
	await tween.finished
	Dialogic.timeline_ended.connect(_take_off)
	Dialogic.start("res://assets/dialog/timeline/intro2.dtl")

func _take_off():
	Dialogic.timeline_ended.disconnect(_take_off)
	# Camera on player
	player.reparent(ship_enemy)
	pcam_player.priority = 1
	pcam_ship.priority = 0
	pcam_player.follow_mode = PhantomCamera2D.FollowMode.SIMPLE
	pcam_player.follow_target = player
	# Move the ship off screen by tweening its position
	var target_position := Vector2(2000, ship.position.y)
	var tween := create_tween()
	tween.tween_property(ship, "position", target_position, 1.2).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	# End cutscene
	await tween.finished
	_end_cutscene()

func _end_cutscene():
	Dialogic.timeline_ended.disconnect(_end_cutscene)
	cutscene.active = false
	for character in characters.get_children():
		_set_enabled(character, true)
	_set_enabled(player, true)

func _set_enabled(node : Node, enabled : bool):
	node.set_process(enabled)
	node.set_physics_process(enabled)
	node.set_process_input(enabled)
