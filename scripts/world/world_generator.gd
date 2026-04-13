extends Node3D
## WorldGenerator — Manages infinite procedural chunk spawning and world scrolling.
## The world moves toward the player (player stays at Z=0).

const ThemeRegistryScript = preload("res://scripts/theme/theme_registry.gd")

const CHUNK_LENGTH: float = 20.0
const PATH_WIDTH: float = 8.0
const VIEW_DISTANCE: float = 120.0
const BEHIND_DISTANCE: float = 25.0
const INITIAL_CHUNKS: int = 8

var _chunks: Array = []
var _next_chunk_z: float = 0.0
var _chunk_container: Node3D
var _is_generating: bool = false
var _chunk_index: int = 0
var theme_id: String = "nature"
var theme_profile: Dictionary = {}

# Preloaded resources (passed to chunk spawners)
var decoration_scenes: Dictionary = {}
var obstacle_scenes: Array[PackedScene] = []
var overhead_obstacle_scenes: Array[PackedScene] = []
var giant_rock_scenes: Array[PackedScene] = []
var coin_scenes: Dictionary = {}  # "gold" -> PackedScene, etc.
var obstacle_material: StandardMaterial3D
var coin_material: StandardMaterial3D
var ground_material: StandardMaterial3D
var road_detail_material: StandardMaterial3D
var road_patch_material: StandardMaterial3D
var grass_material: StandardMaterial3D
var path_edge_material: StandardMaterial3D
var lane_marker_material: StandardMaterial3D


func _ready() -> void:
	add_to_group("world_generator")
	_chunk_container = Node3D.new()
	_chunk_container.name = "ChunkContainer"
	add_child(_chunk_container)

	theme_id = GameManager.current_visual_theme
	theme_profile = ThemeRegistryScript.get_profile(theme_id)
	_setup_materials()
	_preload_decorations()
	_preload_obstacles()
	_preload_coins()

	GameManager.game_started.connect(_on_game_started)
	GameManager.game_over_triggered.connect(_on_game_over)


func _process(delta: float) -> void:
	if not _is_generating:
		return

	# Move world toward player (+Z direction)
	_chunk_container.position.z += GameManager.current_speed * delta

	_cleanup_behind_chunks()
	_ensure_chunks_ahead()


# --- Game Flow ---

func _on_game_started() -> void:
	_clear_all_chunks()
	_chunk_index = 0
	# First chunk at +CHUNK_LENGTH so it extends behind the player at start
	_next_chunk_z = CHUNK_LENGTH
	_is_generating = true
	_spawn_initial_chunks()


func _on_game_over() -> void:
	_is_generating = false


# --- Chunk Lifecycle ---

func _spawn_initial_chunks() -> void:
	for i in INITIAL_CHUNKS:
		_spawn_next_chunk(i < 2)  # First 2 chunks are safe (no obstacles)


func _spawn_next_chunk(is_safe: bool = false) -> void:
	var chunk_script: GDScript = load("res://scripts/world/chunk.gd") as GDScript
	var chunk: Node3D = Node3D.new()
	chunk.set_script(chunk_script)
	chunk.position = Vector3(0, 0, _next_chunk_z)
	_chunk_container.add_child(chunk)

	# Call setup after adding to tree
	chunk.call("setup", _chunk_index, CHUNK_LENGTH, PATH_WIDTH, is_safe, self)

	_chunks.append(chunk)
	_next_chunk_z -= CHUNK_LENGTH
	_chunk_index += 1


func _cleanup_behind_chunks() -> void:
	var to_remove: Array = []
	for chunk in _chunks:
		# Chunk is behind player when its back edge passes BEHIND_DISTANCE
		if chunk.global_position.z > BEHIND_DISTANCE + CHUNK_LENGTH:
			to_remove.append(chunk)

	for chunk in to_remove:
		_chunks.erase(chunk)
		chunk.queue_free()


func _ensure_chunks_ahead() -> void:
	if _chunks.is_empty():
		_spawn_next_chunk()
		return

	# Check if the farthest chunk's front edge is within view distance
	var farthest_global_z: float = _chunks.back().global_position.z
	while farthest_global_z > -VIEW_DISTANCE:
		_spawn_next_chunk()
		farthest_global_z = _chunks.back().global_position.z


func _clear_all_chunks() -> void:
	for chunk in _chunks:
		if is_instance_valid(chunk):
			chunk.queue_free()
	_chunks.clear()
	_chunk_container.position = Vector3.ZERO
	_next_chunk_z = 0.0


# --- Material Setup ---

func _setup_materials() -> void:
	var road_profile: Dictionary = theme_profile.get("road", {})

	ground_material = StandardMaterial3D.new()
	ground_material.albedo_color = road_profile.get("ground", Color(0.60, 0.48, 0.31, 1.0))
	ground_material.roughness = road_profile.get("ground_roughness", 0.96)

	road_detail_material = StandardMaterial3D.new()
	road_detail_material.albedo_color = road_profile.get("detail", Color(0.68, 0.55, 0.36, 1.0))
	road_detail_material.roughness = road_profile.get("detail_roughness", 0.98)

	road_patch_material = StandardMaterial3D.new()
	road_patch_material.albedo_color = road_profile.get("patch", Color(0.42, 0.34, 0.24, 1.0))
	road_patch_material.roughness = road_profile.get("patch_roughness", 1.0)
	if road_profile.get("patch_emission_energy", 0.0) > 0.0:
		road_patch_material.emission_enabled = true
		road_patch_material.emission = road_profile.get("patch_emission", Color(0.05, 0.52, 0.72, 1.0))
		road_patch_material.emission_energy_multiplier = road_profile.get("patch_emission_energy", 0.85)

	grass_material = StandardMaterial3D.new()
	grass_material.albedo_color = road_profile.get("side", Color(0.31, 0.47, 0.24, 1.0))
	grass_material.roughness = road_profile.get("side_roughness", 0.95)

	path_edge_material = StandardMaterial3D.new()
	path_edge_material.albedo_color = road_profile.get("edge", Color(0.33, 0.26, 0.18, 1.0))
	path_edge_material.roughness = road_profile.get("edge_roughness", 0.9)
	if road_profile.has("edge_emission_energy") and road_profile.get("edge_emission_energy", 0.0) > 0.0:
		path_edge_material.emission_enabled = true
		path_edge_material.emission = road_profile.get("edge_emission", Color(0.0, 0.0, 0.0, 1.0))
		path_edge_material.emission_energy_multiplier = road_profile.get("edge_emission_energy", 0.0)

	lane_marker_material = StandardMaterial3D.new()
	lane_marker_material.albedo_color = road_profile.get("lane_marker", Color(0.73, 0.67, 0.50, 0.58))
	lane_marker_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	lane_marker_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if road_profile.get("lane_marker_emission_energy", 0.0) > 0.0:
		lane_marker_material.emission_enabled = true
		lane_marker_material.emission = road_profile.get("lane_marker_emission", Color(0.0, 0.0, 0.0, 1.0))
		lane_marker_material.emission_energy_multiplier = road_profile.get("lane_marker_emission_energy", 0.0)

	obstacle_material = StandardMaterial3D.new()
	obstacle_material.albedo_color = Color(0.75, 0.2, 0.15, 1.0) if theme_id != "cyberprank" else Color(0.15, 0.85, 0.95, 1.0)
	obstacle_material.roughness = 0.7 if theme_id != "cyberprank" else 0.28
	if theme_id == "cyberprank":
		obstacle_material.emission_enabled = true
		obstacle_material.emission = Color(0.08, 0.62, 0.94, 1.0)
		obstacle_material.emission_energy_multiplier = 1.35

	coin_material = StandardMaterial3D.new()
	coin_material.albedo_color = Color(1.0, 0.85, 0.1, 1.0)
	coin_material.metallic = 0.8
	coin_material.roughness = 0.3
	coin_material.emission_enabled = true
	coin_material.emission = Color(1.0, 0.85, 0.1, 1.0)
	coin_material.emission_energy_multiplier = 0.3


# --- Decoration Preloading ---

func _preload_decorations() -> void:
	decoration_scenes.clear()
	var decoration_profile: Dictionary = theme_profile.get("decorations", {})
	for category in decoration_profile.keys():
		decoration_scenes[category] = _load_scene_array(decoration_profile.get(category, []))

func _load_scene_array(paths: Array) -> Array[PackedScene]:
	var result: Array[PackedScene] = []
	for path: String in paths:
		if ResourceLoader.exists(path):
			var scene: PackedScene = load(path) as PackedScene
			if scene:
				result.append(scene)
	return result


# --- Obstacle & Coin Preloading ---

func _preload_obstacles() -> void:
	var obstacle_profile: Dictionary = theme_profile.get("obstacles", {})
	obstacle_scenes = _load_scene_array(obstacle_profile.get("ground", []))
	overhead_obstacle_scenes = _load_scene_array(obstacle_profile.get("overhead", []))
	giant_rock_scenes = _load_scene_array(obstacle_profile.get("giant", []))


func _preload_coins() -> void:
	coin_scenes.clear()
	var gold: Array[PackedScene] = _load_scene_array(["res://assets/Collectibles/Coins/coin-gold.glb"])

	if gold.size() > 0:
		coin_scenes["gold"] = gold[0]


func get_coin_scene(type: String) -> PackedScene:
	return coin_scenes.get("gold", null)


func get_random_obstacle_scene() -> PackedScene:
	if obstacle_scenes.is_empty():
		return null
	return obstacle_scenes[randi() % obstacle_scenes.size()]


func get_random_overhead_scene() -> PackedScene:
	if overhead_obstacle_scenes.is_empty():
		return null
	return overhead_obstacle_scenes[randi() % overhead_obstacle_scenes.size()]


func get_random_giant_rock_scene() -> PackedScene:
	if giant_rock_scenes.is_empty():
		return null
	return giant_rock_scenes[randi() % giant_rock_scenes.size()]


