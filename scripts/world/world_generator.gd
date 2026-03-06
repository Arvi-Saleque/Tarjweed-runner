extends Node3D
## WorldGenerator — Manages infinite procedural chunk spawning and world scrolling.
## The world moves toward the player (player stays at Z=0).

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

# Preloaded resources (passed to chunk spawners)
var decoration_scenes: Dictionary = {}
var obstacle_scenes: Array[PackedScene] = []
var coin_scenes: Dictionary = {}  # "gold" -> PackedScene, etc.
var obstacle_material: StandardMaterial3D
var coin_material: StandardMaterial3D
var ground_material: StandardMaterial3D
var grass_material: StandardMaterial3D
var path_edge_material: StandardMaterial3D


func _ready() -> void:
	_chunk_container = Node3D.new()
	_chunk_container.name = "ChunkContainer"
	add_child(_chunk_container)

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
	# Dirt path material
	ground_material = StandardMaterial3D.new()
	ground_material.albedo_color = Color(0.55, 0.42, 0.28, 1.0)
	ground_material.roughness = 0.95

	# Grass terrain for sides
	grass_material = StandardMaterial3D.new()
	grass_material.albedo_color = Color(0.28, 0.50, 0.18, 1.0)
	grass_material.roughness = 0.95

	# Path border edge
	path_edge_material = StandardMaterial3D.new()
	path_edge_material.albedo_color = Color(0.38, 0.30, 0.20, 1.0)
	path_edge_material.roughness = 0.9

	obstacle_material = StandardMaterial3D.new()
	obstacle_material.albedo_color = Color(0.75, 0.2, 0.15, 1.0)
	obstacle_material.roughness = 0.7

	coin_material = StandardMaterial3D.new()
	coin_material.albedo_color = Color(1.0, 0.85, 0.1, 1.0)
	coin_material.metallic = 0.8
	coin_material.roughness = 0.3
	coin_material.emission_enabled = true
	coin_material.emission = Color(1.0, 0.85, 0.1, 1.0)
	coin_material.emission_energy_multiplier = 0.3


# --- Decoration Preloading ---

func _preload_decorations() -> void:
	decoration_scenes = {
		"trees_large": _load_scene_array([
			"res://assets/Environment/Trees/tree_blocks.glb",
			"res://assets/Environment/Trees/tree_cone.glb",
			"res://assets/Environment/Trees/tree_default.glb",
			"res://assets/Environment/Trees/tree_detailed.glb",
		]),
		"trees_small": _load_scene_array([
			"res://assets/Environment/ExtraProps/tree_small.glb",
			"res://assets/Environment/ExtraProps/tree_tall.glb",
			"res://assets/Environment/ExtraProps/tree_thin.glb",
		]),
		"bushes": _load_scene_array([
			"res://assets/Environment/Bushes/plant_bush.glb",
			"res://assets/Environment/Bushes/plant_bushDetailed.glb",
			"res://assets/Environment/Bushes/plant_bushSmall.glb",
			"res://assets/Environment/ExtraProps/plant_bushLarge.glb",
		]),
		"rocks": _load_scene_array([
			"res://assets/Environment/ExtraProps/rock_largeA.glb",
			"res://assets/Environment/ExtraProps/rock_largeB.glb",
			"res://assets/Environment/ExtraProps/rock_largeC.glb",
			"res://assets/Environment/ExtraProps/rock_tallA.glb",
			"res://assets/Environment/ExtraProps/rock_tallB.glb",
			"res://assets/Environment/ExtraProps/rock_tallC.glb",
		]),
		"props": _load_scene_array([
			"res://assets/Environment/ExtraProps/log.glb",
			"res://assets/Environment/ExtraProps/log_large.glb",
			"res://assets/Environment/ExtraProps/stump_old.glb",
			"res://assets/Environment/ExtraProps/stump_round.glb",
		]),
		"ground_cover": _load_scene_array([
			"res://assets/Environment/ExtraProps/grass_large.glb",
		]),
	}


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
	obstacle_scenes = _load_scene_array([
		"res://assets/Obstacles/ExtraObstacleProps/barrel.glb",
		"res://assets/Obstacles/ExtraObstacleProps/crate.glb",
		"res://assets/Obstacles/ExtraObstacleProps/crate-strong.glb",
		"res://assets/Obstacles/ExtraObstacleProps/fence-broken.glb",
		"res://assets/Obstacles/ExtraObstacleProps/fence-low-broken.glb",
		"res://assets/Obstacles/ExtraObstacleProps/trap-spikes.glb",
		"res://assets/Obstacles/ExtraObstacleProps/trap-spikes-large.glb",
		"res://assets/Obstacles/RocksSmall/cliff_blockHalf_rock.glb",
		"res://assets/Obstacles/RocksSmall/cliff_blockQuarter_rock.glb",
	])


func _preload_coins() -> void:
	var gold: Array[PackedScene] = _load_scene_array(["res://assets/Collectibles/Coins/coin-gold.glb"])
	var silver: Array[PackedScene] = _load_scene_array(["res://assets/Collectibles/Coins/coin-silver.glb"])
	var bronze: Array[PackedScene] = _load_scene_array(["res://assets/Collectibles/Coins/coin-bronze.glb"])

	if gold.size() > 0:
		coin_scenes["gold"] = gold[0]
	if silver.size() > 0:
		coin_scenes["silver"] = silver[0]
	if bronze.size() > 0:
		coin_scenes["bronze"] = bronze[0]


func get_coin_scene(type: String) -> PackedScene:
	return coin_scenes.get(type, coin_scenes.get("gold", null))


func get_random_obstacle_scene() -> PackedScene:
	if obstacle_scenes.is_empty():
		return null
	return obstacle_scenes[randi() % obstacle_scenes.size()]
