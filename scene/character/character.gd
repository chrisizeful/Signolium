extends CharacterBody2D
class_name Character

@export var max_speed : float = 100.0
@export var acceleration : float = .02
@export var braking : float = 0.15

@export var shoot_rate : float = 0.1
var last_shoot_time : float

@onready var sprite : Sprite2D = $Sprite2D
@onready var muzzle = $Muzzle

var move_input : Vector2


var bullet_scene : PackedScene = preload("res://scene/gun/bullet.tscn")




func _physics_process(delta):
	move_input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	move_input = move_input.normalized()
	
	if move_input.length() > 0:
		velocity = velocity.lerp(move_input * max_speed, acceleration)
	else:
		velocity = velocity.lerp(Vector2.ZERO, braking)
	
	move_and_slide()
	
func _process (delta):
	sprite.flip_h = get_global_mouse_position().x < global_position.x
	
	if Input.is_action_pressed("shoot"):
		if Time.get_unix_time_from_system() - last_shoot_time > shoot_rate:
			_shoot()
	
	
func _shoot ():
	last_shoot_time = Time.get_unix_time_from_system()
	
	var bullet = bullet_scene.instantiate()
	get_tree().root.add_child(bullet)
	
	bullet.global_position = muzzle.global_position
	
	var mouse_pos = get_global_mouse_position()
	var mouse_dir = muzzle.global_position.direction_to(mouse_pos)
	
	bullet.move_dir = mouse_dir
	
	

	
