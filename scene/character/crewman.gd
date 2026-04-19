extends Character
class_name DefaultCrewman

static var _never_liked = false

@export var enabled := false
@export var violent := true
@export var follow := false

var _wander_timer := 0.0
var _wander_dir := Vector2.ZERO
var _wander_pause := false
var _violent_mode := false

func _ready():
	var textures := [
		"res://assets/character/RedCoat.png",
		"res://assets/character/YellowCoat.png",
		"res://assets/character/BlueCoat.png"
	]
	sprite.texture = load(textures[randi() % textures.size()])
	shoot_rate = .66
	health.death.connect(_on_death)
	health.value_changed.connect(_on_health_changed)
	area.connect("body_entered", _on_body_entered)
 
func _on_body_entered(body : Node2D):
	var game := get_node("/root/Game") as Game
	if body == game.player:
		_toggle_violent()

func _toggle_violent():
	if not _violent_mode and violent:
		if not _violent_mode:
			_show_alert()
		_violent_mode = true
		follow = true

func _show_alert():
	alert.visible = true
	await get_tree().create_timer(1.0).timeout
	alert.visible = false

func _on_death():
	var game := get_node("/root/Game") as Game
	# If this is the original ship and every enemy is dead, we win
	print(game.is_boss(), ", ", game.enemy_count())
	if game.is_boss() and game.enemy_count() == 0:
		get_tree().call_deferred("change_scene_to_file", "res://scene/ui/gameover/WinScreen.tscn")
		return
	# Chance to spawn heart
	if randf() < .33:
		var heart := load("res://scene/item/heart/Heart.tscn").instantiate() as Heart
		game.root.call_deferred("add_child", heart)
		heart.set_deferred("global_position", global_position)
	# Crewman death dialog
	if _never_liked:
		return
	game.cutscene.start_dialog("res://assets/dialog/timeline/crewman_death.dtl")
	game.set_enabled(game.player, false)
	Dialogic.timeline_ended.connect(func():
		if game and game.player:
			game.set_enabled(game.player, true)
			game.cutscene.active = false
	)
	_never_liked = true

func _on_health_changed(_value : int):
	_toggle_violent()

func _physics_process(delta : float) -> void:
	if not enabled:
		return

	if follow:
		_follow()
		_attack()
	else:
		_wander(delta)

	_set_facing()
	move_and_slide()

func _attack():
	var game := get_node("/root/Game") as Game
	if _violent_mode and Time.get_unix_time_from_system() - _last_shoot_time > shoot_rate:
		if randf() < .5:
			_melee(game.player)
		else:
			shoot_at(game.player)
		_last_shoot_time = Time.get_unix_time_from_system()

func _melee(target : Node2D):
	AudioHelper.play_slash()
	var slash := load("res://scene/gun/slash.tscn").instantiate() as Slash
	var to_target := (target.global_position - global_position)
	var offset := to_target.normalized() * 16.0
	slash.position = offset
	slash.rotation = to_target.angle()
	add_child(slash)
	await get_tree().create_timer(.5).timeout
	slash.queue_free()

func _follow():
	var game := get_node("/root/Game") as Game
	if not game.player:
		return
	navagent.target_position = game.player.global_position
	if navagent.is_navigation_finished():
		velocity = Vector2.ZERO
		return
	var next_pos = navagent.get_next_path_position()
	var direction = (next_pos - global_position).normalized()
	velocity = direction * (max_speed * .2)

func _wander(delta : float):
		_wander_timer -= delta
		if _wander_timer <= 0.0:
			if _wander_pause:
				var angle = randf_range(0, TAU)
				_wander_dir = Vector2(cos(angle), sin(angle)).normalized()
				_wander_timer = randf_range(1.0, 2.5)
				_wander_pause = false
			else:
				_wander_dir = Vector2.ZERO
				_wander_timer = randf_range(0.5, 1.2)
				_wander_pause = true

		var wander_speed := max_speed * 0.25
		velocity = velocity.move_toward(_wander_dir * wander_speed, acceleration * max_speed * delta * 0.5)
		if velocity.length() > wander_speed:
			velocity = velocity.normalized() * wander_speed
