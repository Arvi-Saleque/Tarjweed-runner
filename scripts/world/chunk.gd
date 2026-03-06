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

	# Lane line markers (subtle visual guide)
	_create_lane_markers()


func _create_lane_markers() -> void:
	var marker_material := StandardMaterial3D.new()
	marker_material.albedo_color = Color(0.45, 0.65, 0.35, 0.6)
	marker_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	marker_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	for lane_x: float in GameManager.LANE_POSITIONS:
		var marker := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.08, 0.01, chunk_length)
		mesh.material = marker_material
		marker.mesh = mesh
		marker.position = Vector3(lane_x, 0.005, -chunk_length / 2.0)
		marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(marker)


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

	# 45% chance this chunk gets coins
	if randf() > 0.45:
		return

	var CoinPattern: GDScript = load("res://scripts/world/coin_pattern.gd") as GDScript
	if not CoinPattern:
		return

	# Pick a random lane for the coin pattern
	var lane_idx: int = randi() % GameManager.LANE_COUNT

	# Pick a pattern based on difficulty
	var pattern: int = CoinPattern.call("pick_random_pattern", GameManager.difficulty_multiplier)

	# Start position within chunk
	var start_z: float = randf_range(-3.0, -(chunk_length - 6.0))
	var start_pos := Vector3(0, 0, start_z)

	CoinPattern.call("spawn_pattern", self, pattern, start_pos, lane_idx, _generator)
