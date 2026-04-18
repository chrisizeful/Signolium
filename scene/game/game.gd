extends Node2D

@export var camera : Camera2D
@export var pcam : PhantomCamera2D

func _ready():
	Dialogic.start("res://assets/dialog/timeline/intro.dtl")
