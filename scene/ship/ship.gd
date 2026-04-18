extends Node2D
class_name Ship

@export var floor_layer : TileMapLayer
@export var wall_layer : TileMapLayer
@export var exit_layer : TileMapLayer
@export var closed_layer : TileMapLayer
@export var bench : MapBench

@export var align_time := 1.0

func get_width() -> int:
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
	var half_self := get_width() * tile_size / 2.0
	var half_other := other.get_width() * tile_size / 2.0
	var new_position = Vector2(
		position.x + half_self + half_other,
		position.y
	)
	var tween := other.create_tween()
	tween.tween_property(other, "position", new_position, align_time) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

func set_open(open : bool):
	closed_layer.visible = not open
	closed_layer.collision_enabled = not open
