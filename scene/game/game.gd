extends Node2D
class_name Game

@export var player : Character
@export var enemy : Character

@export var camera : Camera2D
@export var pcam_ship : PhantomCamera2D
@export var pcam_player : PhantomCamera2D

@export var cutscene : Cutscene

@export var ship : Ship
@export var ship_enemy : Ship

func _ready():
	player.set_process(false)
	cutscene.start_dialog("res://assets/dialog/timeline/intro.dtl")
	Dialogic.timeline_ended.connect(_align_ships)

func _align_ships():
	ship_enemy.align(ship)
	Dialogic.timeline_ended.disconnect(_align_ships)
	await get_tree().create_timer(ship.align_time).timeout
	player.set_process(true)
	player.reparent(self)
	enemy.reparent(self)
