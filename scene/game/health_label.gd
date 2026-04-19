extends Label

@export var player : Player

func _ready():
	_on_health_changed(player.health.value)
	player.health.value_changed.connect(_on_health_changed)

func _on_health_changed(value : int) -> void:
	text = str(value)
