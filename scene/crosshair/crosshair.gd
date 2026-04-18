extends Sprite2D

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

func _process(_delta : float) -> void:
	global_position = get_canvas_transform().affine_inverse() * get_viewport().get_mouse_position()
