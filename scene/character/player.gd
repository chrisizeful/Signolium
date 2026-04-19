extends Character
class_name Player

func _ready():
	health.death.connect(_on_death)

func _on_death():
	get_tree().change_scene_to_file("res://scene/ui/gameover/GameOver.tscn")
