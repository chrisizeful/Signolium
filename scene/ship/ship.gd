extends Node2D
class_name Ship

@export var drift_amount := 5.0
@export var drift_time := 2.0

var _spawn_position := Vector2.ZERO
var _noise := FastNoiseLite.new()
var _noise_offset := 0.0

func _ready():
	_spawn_position = position
	_noise.seed = randi()
	_noise.frequency = 0.3
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_drift_to_next()

func _next_point() -> Vector2:
	_noise_offset += 5.0
	return _spawn_position + Vector2(
		_noise.get_noise_1d(_noise_offset) * drift_amount,
		_noise.get_noise_1d(_noise_offset + 100.0) * drift_amount
	)

func _drift_to_next():
	var tween := create_tween()
	tween.tween_property(self, "position", _next_point(), drift_time) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween.finished.connect(_drift_to_next)
