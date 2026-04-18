extends Area2D

@export var speed : float = 200.0
@export var owner_group : String
@onready var destroy_timer : Timer = $DestroyTimer

var move_dir : Vector2

func _process (delta):
	translate(move_dir * speed * delta)


func _on_body_entered(body):
	pass # Replace with function body.

func _on_destroy_timer_timeout() -> void:
	queue_free()
	
