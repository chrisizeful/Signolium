extends Node
class_name Health

signal value_changed(value : int)
signal death()

var _value := 5
var value : int:
	set(value):
		if _dead:
			return
		_value = max(0, value)
		if is_node_ready() and not _dead:
			emit_signal("value_changed", "value", _value)
			if _value == 0:
				emit_signal("death")
	get:
		return _value

var _dead : bool
var dead:
	get:
		return _dead

func _ready():
	death.connect(get_parent().queue_free)
