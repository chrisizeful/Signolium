extends Character
class_name Player

const coins_required := 1

signal coins_changed

var _coins := 0
var coins := 0:
	set(value):
		_coins = value
		emit_signal("coins_changed")
	get:
		return _coins

func _ready():
	health.death.connect(_on_death)

func _on_death():
	get_tree().change_scene_to_file("res://scene/ui/gameover/GameOver.tscn")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("shoot"):
		if Time.get_unix_time_from_system() - _last_shoot_time > shoot_rate:
			_shoot()
