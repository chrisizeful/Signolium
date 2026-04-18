extends CharacterBody2D

var speed : float = 100


func _physics_process(delta):
	velocity.x = 0
	velocity.y = 0
	
	if Input.is_key_pressed(KEY_D):
		velocity.x += speed
	
	if Input.is_key_pressed(KEY_A):
		velocity.x -= speed
	
	if Input.is_key_pressed(KEY_W):
		velocity.y -= speed
	
	if Input.is_key_pressed(KEY_S):
		velocity.y += speed
		
	move_and_slide()
