extends RefCounted
## ObstacleSpawner — Static utility for placing obstacles on chunks.
## Uses real GLB models via obstacle.gd script for collision and visuals.
## Supports different spawning modes based on GameManager.current_theme.

const OBSTACLE_SCRIPT: String = "res://scripts/obstacles/obstacle.gd"
const GIANT_ROCK_SCRIPT: String = "res://scripts/obstacles/giant_rock.gd"

# Natural mode settings
const SLOT_SPACING: float = 5.0
const MIN_SLOT_OFFSET: float = 3.0
const OVERHEAD_CHANCE_BASE: float = 0.15   # 15% chance at low difficulty
const OVERHEAD_CHANCE_MAX: float = 0.35    # 35% chance at high difficulty

# Giant rock settings (natural mode only)
const GIANT_ROCK_CHANCE: float = 0.20       # 20% per chunk
const GIANT_ROCK_MIN_DISTANCE: float = 80.0   # minimum meters between giant rocks
const GIANT_ROCK_MIN_SCORE: float = 50.0      # don't spawn until player has run 50m

# Quiz mode settings — full-row blocks the player MUST jump over
const QUIZ_MIN_ROW_GAP: float = 48.0   # ~4s at base speed (12 m/s)
const QUIZ_MAX_ROW_GAP: float = 60.0   # ~5s at base speed (12 m/s)
const QUIZ_BLOCK_HEIGHT: float = 0.6   # Low enough to jump over
const QUIZ_BLOCK_WIDTH: float = 0.9    # Per-lane block width

# Scale ranges for different obstacle models
const OBSTACLE_SCALES: Dictionary = {
	"default": Vector3(1.0, 1.0, 1.0),
	"small": Vector3(0.8, 0.8, 0.8),
	"large": Vector3(1.3, 1.3, 1.3),
}


static func spawn_obstacles(chunk: Node3D, chunk_length: float, generator: Node3D) -> void:
	if GameManager.current_theme == "quiz":
		_spawn_quiz_obstacles(chunk, chunk_length, generator)
	else:
		_spawn_natural_obstacles(chunk, chunk_length, generator)


# =============================================================================
# NATURAL MODE — original obstacle spawning (single/double lane blocks)
# =============================================================================

static func _spawn_natural_obstacles(chunk: Node3D, chunk_length: float, generator: Node3D) -> void:
	var difficulty: float = GameManager.difficulty_multiplier
	var frequency: float = GameManager.obstacle_frequency

	# Try spawning a giant rock in this chunk (rare, blocks all lanes)
	var giant_rock_spawned: bool = false
	if _should_spawn_giant_rock():
		var rock_z: float = -(chunk_length * 0.5)  # Place in middle of chunk
		_create_giant_rock(chunk, Vector3(0.0, 0.0, rock_z), generator)
		giant_rock_spawned = true
		# Track distance for spacing
		GameManager.set_meta("_last_giant_rock_dist", GameManager.distance)
		print("[GiantRock] === SPAWNED at dist=%.0f ===" % GameManager.distance)

	var slots: Array[float] = []
	var z: float = -MIN_SLOT_OFFSET
	while z > -(chunk_length - MIN_SLOT_OFFSET):
		slots.append(z)
		z -= SLOT_SPACING

	# Overhead chance scales with difficulty
	var overhead_chance: float = clampf(
		OVERHEAD_CHANCE_BASE + (difficulty - 1.0) * 0.1,
		OVERHEAD_CHANCE_BASE, OVERHEAD_CHANCE_MAX
	)

	var last_obstacle_z: float = 999.0
	for slot_z: float in slots:
		if randf() > frequency:
			continue
		if absf(slot_z - last_obstacle_z) < SLOT_SPACING * 0.8:
			continue

		# Don't place regular obstacles too close to giant rock
		if giant_rock_spawned and absf(slot_z - (-(chunk_length * 0.5))) < 12.0:
			continue

		# Decide: overhead (slide-under) or ground (jump-over / dodge)
		var is_overhead: bool = randf() < overhead_chance
		if is_overhead:
			# Overhead = single lane, player must slide under it
			var lane: int = randi() % 3
			var lane_x: float = GameManager.LANE_POSITIONS[lane]
			_create_overhead_obstacle(chunk, Vector3(lane_x, 0.0, slot_z), generator)
		else:
			# Ground obstacles — original lane-blocking pattern
			var pattern: int = _pick_pattern(difficulty)
			var lanes_to_block: Array[int] = _get_lanes_for_pattern(pattern)
			for lane: int in lanes_to_block:
				var lane_x: float = GameManager.LANE_POSITIONS[lane]
				_create_obstacle(chunk, Vector3(lane_x, 0.0, slot_z), generator)

		last_obstacle_z = slot_z


# =============================================================================
# QUIZ MODE — full-row barriers across all 3 lanes, must jump
# =============================================================================

static func _spawn_quiz_obstacles(chunk: Node3D, chunk_length: float, generator: Node3D) -> void:
	# Place full-width rows that span all 3 lanes.
	# Enforce minimum gap so player always has time to land and jump again.
	#
	# We use a static tracking variable via GameManager metadata to maintain
	# spacing across chunk boundaries.

	var last_z_key := "_quiz_last_obs_z"
	var carry_over: float = 0.0
	if GameManager.has_meta(last_z_key):
		# Distance remaining from previous chunk
		carry_over = GameManager.get_meta(last_z_key)

	# Start position within this chunk (z goes negative = forward)
	var z: float = -carry_over if carry_over > 0.0 else -QUIZ_MIN_ROW_GAP

	while z > -(chunk_length - 2.0):
		# Place a full-row barrier at this z
		_create_quiz_row(chunk, z, generator)

		# Next row at random gap within [MIN, MAX]
		var gap: float = randf_range(QUIZ_MIN_ROW_GAP, QUIZ_MAX_ROW_GAP)
		z -= gap

	# Store how much gap remains for the next chunk
	var remaining: float = -(chunk_length) - z
	if remaining > 0:
		GameManager.set_meta(last_z_key, remaining)
	else:
		GameManager.set_meta(last_z_key, 0.0)


static func _create_quiz_row(parent: Node3D, z_pos: float, generator: Node3D) -> void:
	# Create a barrier across all 3 lanes
	for lane_idx in 3:
		var lane_x: float = GameManager.LANE_POSITIONS[lane_idx]
		var pos := Vector3(lane_x, 0.0, z_pos)

		var obs_script: GDScript = load(OBSTACLE_SCRIPT) as GDScript
		if not obs_script:
			return

		var obstacle := Area3D.new()
		obstacle.set_script(obs_script)
		obstacle.position = pos
		obstacle.name = "QuizBlock"
		parent.add_child(obstacle)

		# Use a low, wide block — easy to see, must jump
		var block_mat: StandardMaterial3D = null
		if generator and generator.get("obstacle_material"):
			block_mat = generator.obstacle_material.duplicate() as StandardMaterial3D
			block_mat.albedo_color = Color(0.85, 0.35, 0.2)  # Distinctive orange-red
		obstacle.call("setup_placeholder",
			Vector3(QUIZ_BLOCK_WIDTH * 2.2, QUIZ_BLOCK_HEIGHT, 0.6),
			block_mat)


# =============================================================================
# SHARED HELPERS
# =============================================================================


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


static func _create_overhead_obstacle(parent: Node3D, pos: Vector3, generator: Node3D) -> void:
	var obs_script: GDScript = load(OBSTACLE_SCRIPT) as GDScript
	if not obs_script:
		return

	var obstacle := Area3D.new()
	obstacle.set_script(obs_script)
	obstacle.position = pos
	obstacle.name = "OverheadObstacle"
	parent.add_child(obstacle)

	# Try to use real GLB overhead model
	var model_scene: PackedScene = null
	if generator and generator.has_method("get_random_overhead_scene"):
		model_scene = generator.get_random_overhead_scene()

	if model_scene:
		obstacle.call("setup_overhead", model_scene)
		# Random Y rotation for visual variety
		obstacle.rotation.y = [0.0, PI * 0.5, PI, PI * 1.5].pick_random()
	else:
		# Fallback: placeholder overhead bar
		var bar_mat := StandardMaterial3D.new()
		bar_mat.albedo_color = Color(0.6, 0.35, 0.15)
		bar_mat.roughness = 0.8
		obstacle.call("setup_placeholder", Vector3(1.6, 0.4, 0.4), bar_mat)
		obstacle.position.y = 0.9  # Elevate fallback


# =============================================================================
# GIANT ROCK — blocks all 3 lanes, destroyed by double-tap blast
# =============================================================================

static func _should_spawn_giant_rock() -> bool:
	# Only in natural mode
	if GameManager.current_theme != "natural":
		return false

	var last_dist: float = GameManager.get_meta("_last_giant_rock_dist", -999.0) as float

	# GUARANTEED first giant rock at ~100m
	if last_dist < 0 and GameManager.distance >= 80.0:
		print("[GiantRock] GUARANTEED first spawn at dist=%.0f" % GameManager.distance)
		return true

	# After that, random with spacing enforced
	if GameManager.distance - last_dist < GIANT_ROCK_MIN_DISTANCE:
		return false
	var roll: float = randf()
	print("[GiantRock] dist=%.0f last=%.0f roll=%.2f need<%.2f" % [GameManager.distance, last_dist, roll, GIANT_ROCK_CHANCE])
	return roll < GIANT_ROCK_CHANCE


static func _create_giant_rock(parent: Node3D, pos: Vector3, generator: Node3D) -> void:
	var rock_script: GDScript = load(GIANT_ROCK_SCRIPT) as GDScript
	if not rock_script:
		return

	var rock := Area3D.new()
	rock.set_script(rock_script)
	rock.position = pos
	rock.name = "GiantRock"
	parent.add_child(rock)

	# Pick a random giant rock model
	var model_scene: PackedScene = null
	if generator and generator.has_method("get_random_giant_rock_scene"):
		model_scene = generator.get_random_giant_rock_scene()

	if model_scene:
		rock.call("setup", model_scene)
	else:
		# Fallback: use setup with null (will just be collision box)
		rock.call("setup", null)
