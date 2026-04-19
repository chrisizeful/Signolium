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
	health.death.connect(_on_death)
	health.value_changed.connect(_on_health_changed)
	area.connect("body_entered", _on_body_entered)

func _on_body_entered(body : Node2D):
	if body.name == "Player":
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
	if _never_liked:
		return
	var game := get_node("/root/Game") as Game
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
		_follow(delta)
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

func _follow(delta : float):
	var game := get_node("/root/Game") as Game
	if not game.player:
		return

	var follow_distance := 96.0
	var stop_distance := 64.0
	var to_player := game.player.global_position - global_position
	var dist := to_player.length()

	if dist > follow_distance:
		var dir := to_player.normalized()
		velocity = velocity.move_toward(dir * max_speed * 0.5, acceleration * max_speed * delta * 0.5)
	elif dist < stop_distance:
		velocity = velocity.move_toward(Vector2.ZERO, braking * max_speed * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, braking * max_speed * delta * 0.5)

	if velocity.length() > max_speed * 0.5:
		velocity = velocity.normalized() * max_speed * 0.5

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
