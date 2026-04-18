@tool
extends EditorScript

const TILESET_PATH := "res://assets/ship/ship_tileset.tres"
const ALPHA_THRESHOLD := 1
const PHYSICS_LAYER := 0
const SIMPLIFY_EPSILON := 2.0

func _run() -> void:
	var tileset: TileSet = load(TILESET_PATH) as TileSet
	var source_count := tileset.get_source_count()
	for src_idx in source_count:
		var source_id := tileset.get_source_id(src_idx)
		var source := tileset.get_source(source_id)

		var atlas_source: TileSetAtlasSource = source as TileSetAtlasSource
		var texture: Texture2D = atlas_source.texture
		var image: Image = texture.get_image()
		if image.is_compressed():
			image.decompress()
		var tile_size: Vector2i = atlas_source.texture_region_size
		var tiles_processed := 0

		for tile_idx in atlas_source.get_tiles_count():
			var coords: Vector2i = atlas_source.get_tile_id(tile_idx)
			for alt_idx in atlas_source.get_alternative_tiles_count(coords):
				var alt_id := atlas_source.get_alternative_tile_id(coords, alt_idx)
				var tile_data: TileData = atlas_source.get_tile_data(coords, alt_id)
				if tile_data == null:
					continue
				# Skip tiles that don't have the "solid" custom data set to true.
				var is_solid: bool = false
				if tileset.get_custom_data_layers_count() > 0:
					var solid_val = tile_data.get_custom_data("solid")
					if solid_val is bool:
						is_solid = solid_val
				if not is_solid:
					# Clear any existing physics polygons and skip.
					tile_data.set_collision_polygons_count(PHYSICS_LAYER, 0)
					continue
				# Region in the atlas image for this tile.
				var region_pos := Vector2i(
					coords.x * tile_size.x + atlas_source.margins.x + coords.x * atlas_source.separation.x,
					coords.y * tile_size.y + atlas_source.margins.y + coords.y * atlas_source.separation.y,
				)
				var polygons := _build_collision_polygons(image, region_pos, tile_size)
				tile_data.set_collision_polygons_count(PHYSICS_LAYER, 0)
				if polygons.size() > 0:
					tile_data.set_collision_polygons_count(PHYSICS_LAYER, polygons.size())
					for p_idx in polygons.size():
						tile_data.set_collision_polygon_points(PHYSICS_LAYER, p_idx, polygons[p_idx])
					tiles_processed += 1
		print("TilesetPhysicsGenerator: Processed %d tiles in source %d." % [tiles_processed, source_id])
	var err := ResourceSaver.save(tileset, TILESET_PATH)
	if err != OK:
		printerr("TilesetPhysicsGenerator: Failed to save TileSet (error %d)." % err)
	else:
		print("TilesetPhysicsGenerator: Saved TileSet to '%s'." % TILESET_PATH)

func _build_collision_polygons(image: Image, origin: Vector2i, size: Vector2i) -> Array[PackedVector2Array]:
	var bitmap := BitMap.new()
	bitmap.create(size)
	for y in size.y:
		for x in size.x:
			var px := origin + Vector2i(x, y)
			if px.x >= image.get_width() or px.y >= image.get_height():
				continue
			var color := image.get_pixelv(px)
			bitmap.set_bitv(Vector2i(x, y), int(color.a * 255.0) >= ALPHA_THRESHOLD)

	var rect := Rect2i(Vector2i.ZERO, size)
	var raw_polygons: Array[PackedVector2Array] = bitmap.opaque_to_polygons(rect)
	if raw_polygons.is_empty():
		return []

	var half := Vector2(size) * 0.5
	var result: Array[PackedVector2Array] = []
	for poly in raw_polygons:
		var simplified := poly
		if SIMPLIFY_EPSILON > 0.0 and poly.size() > 4:
			simplified = _simplify_polyline(poly, SIMPLIFY_EPSILON)
			if simplified.size() < 3:
				simplified = poly
		var centered := PackedVector2Array()
		centered.resize(simplified.size())
		for i in simplified.size():
			centered[i] = simplified[i] - half
		if centered.size() >= 3:
			var convex_parts := Geometry2D.decompose_polygon_in_convex(centered)
			for convex in convex_parts:
				if convex.size() >= 3:
					result.append(convex)
	return result

func _simplify_polyline(points: PackedVector2Array, epsilon: float) -> PackedVector2Array:
	if points.size() < 3:
		return points
	var max_dist := 0.0
	var max_idx := 0
	var start := points[0]
	var end := points[points.size() - 1]
	for i in range(1, points.size() - 1):
		var dist := _point_line_distance(points[i], start, end)
		if dist > max_dist:
			max_dist = dist
			max_idx = i
	if max_dist > epsilon:
		var left := _simplify_polyline(points.slice(0, max_idx + 1), epsilon)
		var right := _simplify_polyline(points.slice(max_idx), epsilon)
		# Merge, removing the duplicate junction point.
		var merged := PackedVector2Array()
		for i in left.size() - 1:
			merged.append(left[i])
		for p in right:
			merged.append(p)
		return merged
	else:
		return PackedVector2Array([start, end])

func _point_line_distance(point: Vector2, line_start: Vector2, line_end: Vector2) -> float:
	var line_vec := line_end - line_start
	var len_sq := line_vec.length_squared()
	if len_sq == 0.0:
		return point.distance_to(line_start)
	var t := clampf((point - line_start).dot(line_vec) / len_sq, 0.0, 1.0)
	var projection := line_start + t * line_vec
	return point.distance_to(projection)
