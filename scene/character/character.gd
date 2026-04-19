extends CharacterBody2D
class_name Character

@export var max_speed := 180.0
@export var acceleration := 8.0
@export var braking := 12.0

@export var shoot_rate := 0.1
var _last_shoot_time : float

@onready var health := $Health
@onready var sprite := $Sprite2D
@onready var gun := $Center/Handgun
@onready var muzzle := $Center/Handgun/Muzzle
@onready var area := $Area2D
@onready var alert := $Alert

var facing : Vector2
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
		
	_set_facing()
	move_and_slide()

func _process(_delta : float):
	if name != "Player":
		return
	
	sprite.flip_h = get_global_mouse_position().x < global_position.x
	gun.scale.x = -1 if sprite.flip_h else 1

	if Input.is_action_pressed("shoot"):
		if Time.get_unix_time_from_system() - _last_shoot_time > shoot_rate:
			_shoot()

func _set_facing():
	if velocity.length() > 0.01:
		facing = velocity.normalized()

func _shoot():
	AudioHelper.play_shoot()
	_last_shoot_time = Time.get_unix_time_from_system()
	var scene : PackedScene = preload("res://scene/gun/bullet.tscn")
	var bullet = scene.instantiate()
	get_tree().root.add_child(bullet)
	var mouse_pos = get_global_mouse_position()
	bullet.shooter = self
	bullet.global_position = muzzle.global_position
	bullet.move_dir = muzzle.global_position.direction_to(mouse_pos)

func shoot_at(target: Node2D):
	AudioHelper.play_shoot()
	var scene : PackedScene = preload("res://scene/gun/bullet.tscn")
	var bullet = scene.instantiate()
	get_tree().root.add_child(bullet)
	bullet.shooter = self
	bullet.global_position = muzzle.global_position
	bullet.move_dir = muzzle.global_position.direction_to(target.global_position)
