extends CharacterBody2D
class_name Character

@export var max_speed : float = 180.0
@export var acceleration : float = 8.0
@export var braking : float = 12.0

@export var shoot_rate : float = 0.1
var last_shoot_time : float

@onready var sprite : Sprite2D = $Sprite2D
@onready var gun = $Center/Handgun
@onready var muzzle = $Center/Handgun/Muzzle

var move_input : Vector2

func _physics_process(_delta : float):
	if name != "Player":
		return
	
	move_input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	move_input = move_input.normalized()

	if move_input != Vector2.ZERO:
		velocity = velocity.move_toward(move_input * max_speed, acceleration * max_speed * _delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, braking * max_speed * _delta)

	if velocity.length() > max_speed:
		velocity = velocity.normalized() * max_speed

	move_and_slide()
	
func _process(_delta : float):
	if name != "Player":
		return
	
	sprite.flip_h = get_global_mouse_position().x < global_position.x
	gun.scale.x = -1 if sprite.flip_h else 1
	
	if Input.is_action_pressed("shoot"):
		if Time.get_unix_time_from_system() - last_shoot_time > shoot_rate:
			_shoot()
	
func _shoot():
	AudioHelper.play_shoot()
	last_shoot_time = Time.get_unix_time_from_system()
	
	var scene : PackedScene = preload("res://scene/gun/bullet.tscn")
	var bullet = scene.instantiate()
	get_tree().root.add_child(bullet)
	
	var mouse_pos = get_global_mouse_position()
	bullet.shooter = self
	bullet.global_position = muzzle.global_position
	bullet.move_dir = muzzle.global_position.direction_to(mouse_pos)
