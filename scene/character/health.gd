extends Node
class_name Health

signal value_changed(value : int)
signal death()

var _value := 5
@export var value : int:
	set(value):
		if _dead:
			return
		var prev := _value
		_value = max(0, value)
		if prev > _value:
			AudioHelper.play_hurt()
		if is_node_ready() and not _dead:
			emit_signal("value_changed", _value)
			if _value == 0:
				emit_signal("death")
				get_parent().queue_free()
	get:
		return _value

var _dead : bool
var dead:
	get:
		return _dead
