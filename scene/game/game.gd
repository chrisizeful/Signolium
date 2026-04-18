extends Node2D
class_name Game

@export var player : Character

@export var camera : Camera2D
@export var pcam_ship : PhantomCamera2D
@export var pcam_player : PhantomCamera2D

@export var cutscene : Cutscene

func _ready():
	cutscene.start_dialog("res://assets/dialog/timeline/intro.dtl")
