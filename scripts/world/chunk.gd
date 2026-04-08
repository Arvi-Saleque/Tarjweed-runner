extends Node3D
## Chunk — A single segment of the endless runner world.
## Creates its own ground, obstacles, decorations, and coins.

var chunk_index: int = 0
var chunk_length: float = 20.0
var path_width: float = 8.0
var is_safe: bool = false
var _generator: Node3D = null  # Reference to WorldGenerator for shared resources


func setup(p_index: int, p_length: float, p_width: float, p_safe: bool, generator: Node3D) -> void:
	chunk_index = p_index
	chunk_length = p_length
	path_width = p_width
	is_safe = p_safe
	_generator = generator
	name = "Chunk_%d" % chunk_index

	_create_ground()
	_create_side_terrain()
	_create_path_edges()

	if not is_safe:
		_spawn_obstacles()

	_spawn_decorations()
	_spawn_coins()


# --- Ground ---

func _create_ground() -> void:
	var ground := StaticBody3D.new()
	ground.collision_layer = 1  # Ground layer
	ground.collision_mask = 0
	ground.name = "Ground"
	add_child(ground)

	# Collision shape
	var col_shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = Vector3(path_width, 0.2, chunk_length)
	col_shape.shape = box_shape
	col_shape.position = Vector3(0, -0.1, -chunk_length / 2.0)
	ground.add_child(col_shape)

	# Visual mesh
	var mesh_inst := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = Vector3(path_width, 0.2, chunk_length)
	if _generator and _generator.ground_material:
		box_mesh.material = _generator.ground_material
	mesh_inst.mesh = box_mesh
	mesh_inst.position = Vector3(0, -0.1, -chunk_length / 2.0)
	mesh_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ground.add_child(mesh_inst)

	# Add layered visual details so the road reads as a custom authored runner track.
	_create_road_surface_details()
	_create_lane_markers()
	if _is_cyber_theme():
		_create_cyber_track_accents()


func _create_lane_markers() -> void:
	var marker_material: StandardMaterial3D = null
	if _generator and _generator.get("lane_marker_material"):
		marker_material = _generator.lane_marker_material

	for lane_x: float in GameManager.LANE_POSITIONS:
		var marker := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.06, 0.01, chunk_length)
		if marker_material:
			mesh.material = marker_material
		marker.mesh = mesh
		marker.position = Vector3(lane_x, 0.005, -chunk_length / 2.0)
		marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(marker)


func _create_road_surface_details() -> void:
	var detail_material: StandardMaterial3D = null
	var patch_material: StandardMaterial3D = null
	if _generator:
		detail_material = _generator.get("road_detail_material")
		patch_material = _generator.get("road_patch_material")

	# Central worn strip keeps the track feeling intentional and helps camera framing.
	var center_strip := MeshInstance3D.new()
	var center_mesh := BoxMesh.new()
	center_mesh.size = Vector3(path_width * 0.42, 0.02, chunk_length)
	if detail_material:
		center_mesh.material = detail_material
	center_strip.mesh = center_mesh
	center_strip.position = Vector3(0.0, 0.01, -chunk_length / 2.0)
	center_strip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(center_strip)

	# Shoulder strips make the custom road feel finished and more readable.
	for side in [-1.0, 1.0]:
		var shoulder := MeshInstance3D.new()
		var shoulder_mesh := BoxMesh.new()
		shoulder_mesh.size = Vector3(0.55, 0.03, chunk_length)
		if patch_material:
			shoulder_mesh.material = patch_material
		shoulder.mesh = shoulder_mesh
		shoulder.position = Vector3(side * (path_width * 0.5 - 0.4), 0.012, -chunk_length / 2.0)
		shoulder.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(shoulder)

	# Rotate between a few subtle chunk accents so the road is controlled but not flat.
	match chunk_index % 3:
		1:
			_create_road_patch(Vector3(0.0, 0.014, -chunk_length * 0.28), Vector3(path_width * 0.34, 0.028, 2.8), patch_material)
			_create_road_patch(Vector3(path_width * 0.18, 0.014, -chunk_length * 0.66), Vector3(1.2, 0.028, 2.2), detail_material)
		2:
			_create_road_patch(Vector3(-path_width * 0.18, 0.014, -chunk_length * 0.46), Vector3(1.4, 0.028, 3.0), patch_material)
			_create_road_patch(Vector3(path_width * 0.16, 0.014, -chunk_length * 0.78), Vector3(1.0, 0.028, 1.8), detail_material)
		_:
			_create_road_patch(Vector3(0.0, 0.014, -chunk_length * 0.54), Vector3(path_width * 0.26, 0.028, 1.9), detail_material)


func _create_road_patch(pos: Vector3, size: Vector3, material: StandardMaterial3D) -> void:
	var patch := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	if material:
		mesh.material = material
	patch.mesh = mesh
	patch.position = pos
	patch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(patch)


func _create_cyber_track_accents() -> void:
	var rail_material := StandardMaterial3D.new()
	rail_material.albedo_color = Color(0.05, 0.12, 0.18, 1.0)
	rail_material.roughness = 0.18
	rail_material.metallic = 0.55
	rail_material.emission_enabled = true
	rail_material.emission = Color(0.12, 0.86, 1.0, 1.0)
	rail_material.emission_energy_multiplier = 1.2

	var pulse_material := StandardMaterial3D.new()
	pulse_material.albedo_color = Color(0.14, 0.24, 0.36, 0.96)
	pulse_material.roughness = 0.08
	pulse_material.metallic = 0.4
	pulse_material.emission_enabled = true
	pulse_material.emission = Color(0.86, 0.22, 1.0, 1.0)
	pulse_material.emission_energy_multiplier = 1.6

	for side in [-1.0, 1.0]:
		var rail := MeshInstance3D.new()
		var rail_mesh := BoxMesh.new()
		rail_mesh.size = Vector3(0.10, 0.05, chunk_length)
		rail_mesh.material = rail_material
		rail.mesh = rail_mesh
		rail.position = Vector3(side * (path_width * 0.5 - 0.18), 0.06, -chunk_length / 2.0)
		rail.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(rail)

	var pulse_count: int = int(chunk_length / 4.0)
	for idx in pulse_count:
		var pulse := MeshInstance3D.new()
		var pulse_mesh := BoxMesh.new()
		pulse_mesh.size = Vector3(path_width * 0.18, 0.028, 0.55)
		pulse_mesh.material = pulse_material
		pulse.mesh = pulse_mesh
		pulse.position = Vector3(0.0, 0.03, -(idx * 4.0) - 2.0)
		pulse.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(pulse)

		var side_pad := MeshInstance3D.new()
		var side_mesh := BoxMesh.new()
		side_mesh.size = Vector3(0.42, 0.024, 0.65)
		side_mesh.material = rail_material
		side_pad.mesh = side_mesh
		side_pad.position = Vector3(path_width * 0.24 * (-1.0 if idx % 2 == 0 else 1.0), 0.026, -(idx * 4.0) - 2.0)
		side_pad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(side_pad)


func _create_side_terrain() -> void:
	if not _generator:
		return
	var terrain_width: float = 40.0
	for side in [-1.0, 1.0]:
		var terrain := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(terrain_width, 0.18, chunk_length)
		if _generator.get("grass_material"):
			mesh.material = _generator.grass_material
		terrain.mesh = mesh
		terrain.position = Vector3(side * (path_width / 2.0 + terrain_width / 2.0), -0.11, -chunk_length / 2.0)
		terrain.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(terrain)


func _create_path_edges() -> void:
	if not _generator:
		return
	for side in [-1.0, 1.0]:
		var edge := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.15, 0.24, chunk_length)
		if _generator.get("path_edge_material"):
			mesh.material = _generator.path_edge_material
		edge.mesh = mesh
		edge.position = Vector3(side * path_width / 2.0, -0.08, -chunk_length / 2.0)
		edge.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(edge)


func _is_cyber_theme() -> bool:
	return _generator != null and _generator.get("theme_id") == "cyberprank"


# --- Obstacles ---

func _spawn_obstacles() -> void:
	var ObstacleSpawner: GDScript = load("res://scripts/world/obstacle_spawner.gd") as GDScript
	if ObstacleSpawner:
		ObstacleSpawner.call("spawn_obstacles", self, chunk_length, _generator)


# --- Decorations ---

func _spawn_decorations() -> void:
	var DecorationSpawner: GDScript = load("res://scripts/world/decoration_spawner.gd") as GDScript
	if DecorationSpawner:
		DecorationSpawner.call("spawn_decorations", self, chunk_length, path_width, _generator)


# --- Coins ---

func _spawn_coins() -> void:
	if is_safe and chunk_index == 0:
		return  # No coins on the very first chunk

	# No coins on chunks with a giant rock
	if _has_giant_rock():
		return

	# No coins on chunks with a river
	if _has_river():
		return

	# 45% chance this chunk gets coins
	if randf() > 0.45:
		return

	var CoinPattern: GDScript = load("res://scripts/world/coin_pattern.gd") as GDScript
	if not CoinPattern:
		return

	# Gather obstacle Z positions on this chunk (local space)
	var obstacle_zs: Array[float] = _get_obstacle_z_positions()

	# Pick a random lane for the coin pattern
	var lane_idx: int = randi() % GameManager.LANE_COUNT

	# Pick a pattern based on difficulty
	var pattern: int = CoinPattern.call("pick_random_pattern", GameManager.difficulty_multiplier)

	# Start position within chunk — must be at least 20m from any obstacle
	var start_z: float = randf_range(-3.0, -(chunk_length - 6.0))

	# Check if start_z is within 20m of any obstacle on this chunk
	for obs_z: float in obstacle_zs:
		if absf(start_z - obs_z) < 20.0:
			return  # Too close to an obstacle, skip coins entirely

	var start_pos := Vector3(0, 0, start_z)
	CoinPattern.call("spawn_pattern", self, pattern, start_pos, lane_idx, _generator)


func _get_obstacle_z_positions() -> Array[float]:
	## Collect the local Z positions of all obstacles and quiz obstacles on this chunk.
	var positions: Array[float] = []
	for child in get_children():
		if child.is_in_group("obstacles") or child.is_in_group("quiz_obstacles") or child.is_in_group("giant_rocks") or child.is_in_group("river_crossings"):
			positions.append(child.position.z)
	return positions


func _has_giant_rock() -> bool:
	for child in get_children():
		if child.is_in_group("giant_rocks"):
			return true
	return false


func _has_river() -> bool:
	for child in get_children():
		if child.is_in_group("river_crossings"):
			return true
	return false
