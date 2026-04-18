extends Node2D
class_name Ship

@export var floor_layer : TileMapLayer
@export var wall_layer : TileMapLayer

@export var drift_amount := 5.0
@export var drift_time := 2.0
@export var align_time := 1.0

var _spawn_position := Vector2.ZERO
var _noise := FastNoiseLite.new()

func _ready():
	_spawn_position = position
	_noise.seed = 12
	_noise.frequency = 0.3
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH

func _process(_delta):
	var t := Time.get_ticks_msec() / (drift_time * 1000.0)
	var drift := Vector2(
		_noise.get_noise_1d(t) * drift_amount,
		_noise.get_noise_1d(t + 100.0) * drift_amount
	)
	position = _spawn_position + drift

func _get_width() -> int:
	var cells := floor_layer.get_used_cells()
	var min_x := 0
	var max_x := 0
	for cell in cells:
		if cell.x < min_x:
			min_x = cell.x
		if cell.x > max_x:
			max_x = cell.x
	return max_x - min_x

func align(other: Ship) -> void:
	var tile_size := floor_layer.tile_set.tile_size.x
	var half_self := _get_width() * tile_size / 2.0
	var half_other := other._get_width() * tile_size / 2.0
	var new_position = Vector2(
		_spawn_position.x + half_self + half_other,
		_spawn_position.y
	)
	var tween := other.create_tween()
	tween.tween_property(other, "_spawn_position", new_position, align_time) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
