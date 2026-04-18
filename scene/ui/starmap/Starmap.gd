extends Control
class_name Starmap

signal sector_clicked(cell_value: float, center_uv: Vector2)

const NOISE_SIZE := 512

@export var sectors : Control
@export var noise : FastNoiseLite
@export var animator : AnimationPlayer

var _cell_image : Image
var _cell_centers : Dictionary
var _cell_neighbors : Dictionary
var _player_icon : TextureRect

var _player_cell : float = 0.0
var _visited_cells : Array = []
var _target_icon : TextureRect
var _moved : bool

func _ready() -> void:
	_cell_image = Image.create(NOISE_SIZE, NOISE_SIZE, false, Image.FORMAT_RF)
	for y in NOISE_SIZE:
		for x in NOISE_SIZE:
			var val := noise.get_noise_2d(float(x), float(y))
			_cell_image.set_pixel(x, y, Color(val, 0.0, 0.0, 1.0))

	# Compute centroid of each cell
	var cell_sums := {}
	for y in NOISE_SIZE:
		for x in NOISE_SIZE:
			var val := _cell_image.get_pixel(x, y).r
			if not cell_sums.has(val):
				cell_sums[val] = Vector3.ZERO
			cell_sums[val] += Vector3(float(x), float(y), 1.0)
	for val in cell_sums:
		var s : Vector3 = cell_sums[val]
		_cell_centers[val] = Vector2(s.x / s.z, s.y / s.z) / float(NOISE_SIZE)

	# Build adjacency map from pixel borders
	for y in NOISE_SIZE:
		for x in NOISE_SIZE:
			var val := _cell_image.get_pixel(x, y).r
			if not _cell_neighbors.has(val):
				_cell_neighbors[val] = []
			if x < NOISE_SIZE - 1:
				var right := _cell_image.get_pixel(x + 1, y).r
				if right != val:
					if right not in _cell_neighbors[val]:
						_cell_neighbors[val].append(right)
					if not _cell_neighbors.has(right):
						_cell_neighbors[right] = []
					if val not in _cell_neighbors[right]:
						_cell_neighbors[right].append(val)
			if y < NOISE_SIZE - 1:
				var down := _cell_image.get_pixel(x, y + 1).r
				if down != val:
					if down not in _cell_neighbors[val]:
						_cell_neighbors[val].append(down)
					if not _cell_neighbors.has(down):
						_cell_neighbors[down] = []
					if val not in _cell_neighbors[down]:
						_cell_neighbors[down].append(val)

	var noise_tex := ImageTexture.create_from_image(_cell_image)
	sectors.material.set_shader_parameter("noise_texture", noise_tex)
	sectors.material.set_shader_parameter("rect_size", sectors.size)
	sectors.resized.connect(func():
		sectors.material.set_shader_parameter("rect_size", sectors.size)
	)

	_player_icon = add_sector_icon(Vector2(0.5, 0.5), preload("res://assets/ui/player-icon.png"))
	var px := clampi(int(0.5 * NOISE_SIZE), 0, NOISE_SIZE - 1)
	var py := clampi(int(0.5 * NOISE_SIZE), 0, NOISE_SIZE - 1)
	_player_cell = _cell_image.get_pixel(px, py).r
	_visited_cells.clear()
	if _player_cell not in _visited_cells:
		_visited_cells.append(_player_cell)
	_update_visited_shader()
	_target_icon = add_sector_icon(Vector2(0.3, 0.7), preload("res://assets/ui/target-icon.png"))
	# Tween to continuously blink the target icon
	var blink_tween = create_tween()
	blink_tween.set_loops()
	blink_tween.tween_property(_target_icon, "modulate:a", 0.2, 0.5).set_ease(Tween.EASE_IN_OUT)
	blink_tween.tween_property(_target_icon, "modulate:a", 1.0, 0.5).set_ease(Tween.EASE_IN_OUT)

func add_sector_icon(point_in_sector: Vector2, icon: Texture2D) -> TextureRect:
	var px := clampi(int(point_in_sector.x * NOISE_SIZE), 0, NOISE_SIZE - 1)
	var py := clampi(int(point_in_sector.y * NOISE_SIZE), 0, NOISE_SIZE - 1)
	var val := _cell_image.get_pixel(px, py).r
	var center_uv : Vector2 = _cell_centers.get(val, point_in_sector)

	var tex_rect := TextureRect.new()
	tex_rect.texture = icon
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex_rect.custom_minimum_size = Vector2(32, 32)
	tex_rect.anchors_preset = Control.PRESET_CENTER
	tex_rect.position = sectors.size * center_uv - tex_rect.custom_minimum_size / 2.0
	sectors.add_child(tex_rect)
	sectors.resized.connect(func():
		tex_rect.position = sectors.size * center_uv - tex_rect.custom_minimum_size / 2.0
	)
	return tex_rect

func show_map() -> void:
	if animator.is_playing():
		return
	var game := get_node("/root/Game") as Game
	if game.cutscene.active:
		return
	if not animator.is_playing():
		game.set_enabled(game.player, false)
		AudioHelper.play_map()
		animator.play("in")

func _input(event: InputEvent) -> void:
	var game := get_node("/root/Game") as Game
	if visible and not animator.is_playing() and event.is_action_pressed("interact"):
		AudioHelper.play_map()
		animator.play("out")
		await animator.animation_finished
		game.set_enabled(game.player, true)
		return
	if not visible or animator.is_playing():
		return
	if event is InputEventMouseMotion:
		var local := sectors.get_local_mouse_position()
		var uv := local / sectors.size
		if uv.x >= 0.0 and uv.x <= 1.0 and uv.y >= 0.0 and uv.y <= 1.0:
			var px := clampi(int(uv.x * NOISE_SIZE), 0, NOISE_SIZE - 1)
			var py := clampi(int(uv.y * NOISE_SIZE), 0, NOISE_SIZE - 1)
			var val := _cell_image.get_pixel(px, py).r
			sectors.material.set_shader_parameter("hovered_value", val)
		else:
			sectors.material.set_shader_parameter("hovered_value", -999.0)
	# Prevent moving twice...
	if _moved:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var local := sectors.get_local_mouse_position()
		var uv := local / sectors.size
		if uv.x >= 0.0 and uv.x <= 1.0 and uv.y >= 0.0 and uv.y <= 1.0:
			var px := clampi(int(uv.x * NOISE_SIZE), 0, NOISE_SIZE - 1)
			var py := clampi(int(uv.y * NOISE_SIZE), 0, NOISE_SIZE - 1)
			var val := _cell_image.get_pixel(px, py).r
			if not is_neighbor(_player_cell, val):
				return
			# Mark previous cell as visited
			if _player_cell not in _visited_cells:
				_visited_cells.append(_player_cell)
			# Mark new cell as visited too
			if val not in _visited_cells:
				_visited_cells.append(val)
			_update_visited_shader()
			var center_uv : Vector2 = _cell_centers.get(val, uv)
			_player_cell = val
			sector_clicked.emit(val, center_uv)
			_move_icon_to_cell(_player_icon, center_uv)
			_move_target_to_new_sector()
			_moved = true
			# Wait a second, close the map
			AudioHelper.play_sector()
			await get_tree().create_timer(.33).timeout
			AudioHelper.play_map()
			animator.play("out")
			await animator.animation_finished
			game.set_enabled(game.player, true)
			_moved = false
			# Spawn random ship
			_spawn_ship()

func _move_target_to_new_sector():
	# Find all possible cells not visited and not the player's current cell
	var possible_cells = []
	for cell in _cell_centers.keys():
		if cell != _player_cell and cell not in _visited_cells:
			possible_cells.append(cell)
	if possible_cells.size() == 0:
		return # No unvisited cells left
	# Find the cell with the maximum distance from the player
	var max_dist = -1
	var furthest_cells = []
	for cell in possible_cells:
		var dist = cell_distance(_player_cell, cell)
		if dist > max_dist:
			max_dist = dist
			furthest_cells = [cell]
		elif dist == max_dist:
			furthest_cells.append(cell)
	# Pick one of the furthest cells at random
	var new_target_cell = furthest_cells[randi() % furthest_cells.size()]
	var center_uv : Vector2 = _cell_centers.get(new_target_cell, Vector2(0.5, 0.5))
	_move_icon_to_cell(_target_icon, center_uv)

func _update_visited_shader():
	var arr = PackedFloat32Array(_visited_cells)
	sectors.material.set_shader_parameter("visited_values", arr)
	sectors.material.set_shader_parameter("visited_count", arr.size())

func _move_icon_to_cell(icon: TextureRect, center_uv: Vector2) -> void:
	icon.position = sectors.size * center_uv - icon.custom_minimum_size / 2.0

func is_neighbor(cell_a: float, cell_b: float) -> bool:
	if not _cell_neighbors.has(cell_a):
		return false
	return cell_b in _cell_neighbors[cell_a]

func cell_distance(cell_a: float, cell_b: float) -> int:
	if cell_a == cell_b:
		return 0
	var visited := {cell_a: true}
	var frontier := [cell_a]
	var dist := 0
	while frontier.size() > 0:
		dist += 1
		var next_frontier := []
		for cell in frontier:
			if not _cell_neighbors.has(cell):
				continue
			for neighbor in _cell_neighbors[cell]:
				if neighbor == cell_b:
					return dist
				if not visited.has(neighbor):
					visited[neighbor] = true
					next_frontier.append(neighbor)
		frontier = next_frontier
	return -1

func _get_random_ship() -> String:
	var dir = DirAccess.open("res://scene/ship/ships/")
	if dir:
		# Find all files
		dir.list_dir_begin()
		var file_name = dir.get_next()
		var files = []
		while file_name != "":
			if dir.current_is_dir():
				continue
			files.append(file_name)
			file_name = dir.get_next()
		# Choose random file
		return files[randi_range(0, len(files) - 1)]
	else:
		print("An error occurred when trying to access the path.")
	return ""

func _spawn_ship():
	var path := "res://scene/ship/ships/" + _get_random_ship()
	var ship = load(path).instantiate() as Ship
	var game := get_node("/root/Game") as Game
	if game.ship_random:
		game.ship_random.queue_free()
	game.ship_random = ship
	game.add_child(ship)
	game.align_ships(ship, game.ship_enemy, false, false)
	game.ship_enemy.bench.disabled = true
