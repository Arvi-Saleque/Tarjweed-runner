extends RefCounted
## ObstacleSpawner — Static utility for placing obstacles on chunks.
## Uses real GLB models via obstacle.gd script for collision and visuals.

const OBSTACLE_SCRIPT: String = "res://scripts/obstacles/obstacle.gd"

# Obstacle slot spacing within a chunk (Z positions relative to chunk origin)
const SLOT_SPACING: float = 5.0
const MIN_SLOT_OFFSET: float = 3.0  # Don't place obstacles right at chunk edges

# Scale ranges for different obstacle models (tweak for gameplay balance)
const OBSTACLE_SCALES: Dictionary = {
	"default": Vector3(1.0, 1.0, 1.0),
	"small": Vector3(0.8, 0.8, 0.8),
	"large": Vector3(1.3, 1.3, 1.3),
}


static func spawn_obstacles(chunk: Node3D, chunk_length: float, generator: Node3D) -> void:
	var difficulty: float = GameManager.difficulty_multiplier
	var frequency: float = GameManager.obstacle_frequency

	# Calculate obstacle slot positions within the chunk
	var slots: Array[float] = []
	var z: float = -MIN_SLOT_OFFSET
	while z > -(chunk_length - MIN_SLOT_OFFSET):
		slots.append(z)
		z -= SLOT_SPACING

	# For each slot, roll against frequency to decide if an obstacle spawns
	var last_obstacle_z: float = 999.0
	for slot_z: float in slots:
		if randf() > frequency:
			continue

		# Minimum spacing check
		if absf(slot_z - last_obstacle_z) < SLOT_SPACING * 0.8:
			continue

		# Pick random lane(s) to block
		var pattern: int = _pick_pattern(difficulty)
		var lanes_to_block: Array[int] = _get_lanes_for_pattern(pattern)

		for lane: int in lanes_to_block:
			var lane_x: float = GameManager.LANE_POSITIONS[lane]
			_create_obstacle(chunk, Vector3(lane_x, 0.0, slot_z), generator)

		last_obstacle_z = slot_z


static func _pick_pattern(difficulty: float) -> int:
	## Returns a pattern type:
	## 0 = single lane blocked
	## 1 = two lanes blocked (must switch to specific lane)
	var roll: float = randf()

	# At low difficulty, mostly single lane. At high difficulty, more multi-lane.
	var two_lane_chance: float = clampf(0.05 + (difficulty - 1.0) * 0.15, 0.05, 0.35)

	if roll < two_lane_chance:
		return 1  # Two lanes blocked
	return 0  # Single lane blocked


static func _get_lanes_for_pattern(pattern: int) -> Array[int]:
	match pattern:
		0:  # Single lane
			return [randi() % 3]
		1:  # Two lanes — leave one lane open
			var open_lane: int = randi() % 3
			var blocked: Array[int] = []
			for i in 3:
				if i != open_lane:
					blocked.append(i)
			return blocked
		_:
			return [1]  # Center lane default


static func _create_obstacle(parent: Node3D, pos: Vector3, generator: Node3D) -> void:
	var obs_script: GDScript = load(OBSTACLE_SCRIPT) as GDScript
	if not obs_script:
		return

	var obstacle := Area3D.new()
	obstacle.set_script(obs_script)
	obstacle.position = pos
	obstacle.name = "Obstacle"
	parent.add_child(obstacle)

	# Try to use real GLB model from generator
	var model_scene: PackedScene = null
	if generator and generator.has_method("get_random_obstacle_scene"):
		model_scene = generator.get_random_obstacle_scene()

	if model_scene:
		obstacle.call("setup", model_scene)
		# Random Y rotation for variety
		obstacle.rotation.y = randf_range(0, TAU)
		# Slight random scale variation
		var scale_var: float = randf_range(0.85, 1.15)
		obstacle.scale = Vector3(scale_var, scale_var, scale_var)
	else:
		# Fallback: placeholder box
		var fallback_mat: StandardMaterial3D = null
		if generator and generator.obstacle_material:
			fallback_mat = generator.obstacle_material
		obstacle.call("setup_placeholder", Vector3(0.8, 0.8, 0.8), fallback_mat)
