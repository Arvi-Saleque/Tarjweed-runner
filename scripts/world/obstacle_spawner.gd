extends RefCounted
## ObstacleSpawner — Static utility for placing obstacles on chunks.
## Uses real GLB models via obstacle.gd script for collision and visuals.
## Supports different spawning modes based on GameManager.current_mode.

const OBSTACLE_SCRIPT: String = "res://scripts/obstacles/obstacle.gd"
const GIANT_ROCK_SCRIPT: String = "res://scripts/obstacles/giant_rock.gd"

# Natural mode settings
const SLOT_SPACING: float = 5.0
const MIN_SLOT_OFFSET: float = 3.0
const OVERHEAD_CHANCE_BASE: float = 0.15   # 15% chance at low difficulty
const OVERHEAD_CHANCE_MAX: float = 0.35    # 35% chance at high difficulty

# Giant rock settings (natural mode only)
const GIANT_ROCK_CHANCE: float = 0.35       # 35% per chunk
const GIANT_ROCK_MIN_DISTANCE: float = 80.0   # minimum meters between giant rocks
const GIANT_ROCK_MIN_SCORE: float = 50.0      # don't spawn until player has run 50m

# River crossing settings
const RIVER_CHANCE: float = 0.25              # 25% per eligible chunk
const RIVER_MIN_DISTANCE: float = 50.0        # minimum meters between rivers
const RIVER_ROAD_WIDTH: float = 8.0           # Width to cover all 3 lanes
const RIVER_DEPTH: float = 4.0                # River depth (Z direction)
const RIVER_CLEARANCE: float = 20.0           # No obstacles/coins within this distance before river

# Quiz mode settings — 4 obstacle types tied to math operations
const QUIZ_MIN_ROW_GAP: float = 70.0   # ~6s at base speed (12 m/s)
const QUIZ_MAX_ROW_GAP: float = 85.0   # ~7s at base speed (12 m/s)
const QUIZ_BLOCK_HEIGHT: float = 0.6   # Low enough to jump over
const QUIZ_BLOCK_WIDTH: float = 0.9    # Per-lane block width
# Quiz obstacle types: 0=jump, 1=slide, 2=giant_rock, 3=river
const QUIZ_TYPE_JUMP: int = 0
const QUIZ_TYPE_SLIDE: int = 1
const QUIZ_TYPE_BLAST: int = 2
const QUIZ_TYPE_RIVER: int = 3

# Scale ranges for different obstacle models
const OBSTACLE_SCALES: Dictionary = {
	"default": Vector3(1.0, 1.0, 1.0),
	"small": Vector3(0.8, 0.8, 0.8),
	"large": Vector3(1.3, 1.3, 1.3),
}


static func spawn_obstacles(chunk: Node3D, chunk_length: float, generator: Node3D) -> void:
	if GameManager.is_quiz_mode():
		_spawn_quiz_obstacles(chunk, chunk_length, generator)
	elif GameManager.is_pronunciation_mode():
		_spawn_pronunciation_obstacles(chunk, chunk_length, generator)
	else:
		_spawn_natural_obstacles(chunk, chunk_length, generator)


# =============================================================================
# NATURAL MODE — original obstacle spawning (single/double lane blocks)
# =============================================================================

static func _spawn_natural_obstacles(chunk: Node3D, chunk_length: float, generator: Node3D) -> void:
	var difficulty: float = GameManager.difficulty_multiplier
	var frequency: float = GameManager.obstacle_frequency

	# Estimate the distance this chunk represents
	# Chunks start at +20 and go negative. Chunk at Z=-100 means ~100m from start.
	var chunk_dist: float = maxf(GameManager.distance, absf(chunk.position.z))

	# Try spawning a giant rock in this chunk (rare, blocks all lanes)
	var giant_rock_spawned: bool = false
	var rock_z: float = -(chunk_length * 0.5)  # Middle of chunk
	if _should_spawn_giant_rock(chunk_dist):
		_create_giant_rock(chunk, Vector3(0.0, 0.0, rock_z), generator)
		giant_rock_spawned = true
		# Track distance for spacing
		GameManager.set_meta("_last_giant_rock_dist", chunk_dist)
		# Track global Z position for cross-chunk clearance
		var rock_global_z: float = chunk.position.z + rock_z
		var positions: Array = GameManager.get_meta("_giant_rock_positions", []) as Array
		positions.append(rock_global_z)
		GameManager.set_meta("_giant_rock_positions", positions)
		print("[GiantRock] === SPAWNED at chunk_dist=%.0f global_z=%.0f ==" % [chunk_dist, rock_global_z])

	# Try spawning a river crossing (deadly water, player must build bridge)
	var river_z_pos: float = -INF
	if not giant_rock_spawned:
		river_z_pos = _try_spawn_river(chunk, chunk_length, chunk_dist)

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

		# Don't place obstacles on top of a river
		# Don't place obstacles within 20m of a river
		if river_z_pos > -INF and absf(slot_z - river_z_pos) < RIVER_CLEARANCE:
			continue

		# Don't place regular obstacles near ANY giant rock
		# Clearance scales with speed: 40-100m before, 50-100m after
		var speed_ratio: float = clampf((GameManager.current_speed - GameManager.BASE_SPEED) / (GameManager.MAX_SPEED - GameManager.BASE_SPEED), 0.0, 1.0)
		var clear_before: float = lerpf(40.0, 100.0, speed_ratio)
		var clear_after: float = lerpf(50.0, 100.0, speed_ratio)
		var slot_global_z: float = chunk.position.z + slot_z
		var too_close: bool = false
		# Check current chunk's giant rock
		if giant_rock_spawned:
			var dist_to_rock: float = slot_z - rock_z
			if dist_to_rock > -clear_after and dist_to_rock < clear_before:
				too_close = true
		# Check all tracked giant rock positions (cross-chunk clearance)
		if not too_close:
			var positions: Array = GameManager.get_meta("_giant_rock_positions", []) as Array
			for gr_z: float in positions:
				var dist: float = slot_global_z - gr_z
				if dist > -clear_after and dist < clear_before:
					too_close = true
					break
		if too_close:
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
# PRONUNCIATION MODE — simple jump blocks spaced 100m apart
# =============================================================================

const PRONUN_ROW_GAP: float = 100.0

static func _spawn_pronunciation_obstacles(chunk: Node3D, chunk_length: float, generator: Node3D) -> void:
	var last_z_key := "_pronun_last_obs_z"
	var carry_over: float = 0.0
	if GameManager.has_meta(last_z_key):
		carry_over = GameManager.get_meta(last_z_key)

	var z: float = -carry_over if carry_over > 0.0 else -PRONUN_ROW_GAP

	while z > -(chunk_length - 2.0):
		# Place jump blocks across all 3 lanes
		for lane_idx in 3:
			var lane_x: float = GameManager.LANE_POSITIONS[lane_idx]
			var pos := Vector3(lane_x, 0.0, z)
			var obs_script: GDScript = load(OBSTACLE_SCRIPT) as GDScript
			if not obs_script:
				return
			var obstacle := Area3D.new()
			obstacle.set_script(obs_script)
			obstacle.position = pos
			obstacle.name = "PronunJumpBlock"
			chunk.add_child(obstacle)
			var block_mat := StandardMaterial3D.new()
			block_mat.albedo_color = Color(0.3, 0.5, 0.9)  # Blue for pronunciation
			obstacle.call("setup_placeholder",
				Vector3(QUIZ_BLOCK_WIDTH * 2.2, QUIZ_BLOCK_HEIGHT, 0.6),
				block_mat)

		z -= PRONUN_ROW_GAP

	var remaining: float = -(chunk_length) - z
	if remaining > 0:
		GameManager.set_meta(last_z_key, remaining)
	else:
		GameManager.set_meta(last_z_key, 0.0)


# =============================================================================
# QUIZ MODE — 4 obstacle types tied to math operations
# Type 0 (Addition): ground blocks — player must JUMP
# Type 1 (Subtraction): overhead blocks — player must SLIDE
# Type 2 (Multiplication): giant rock — player must BLAST
# Type 3 (Division): river — player must BUILD BRIDGE
# =============================================================================

static func _spawn_quiz_obstacles(chunk: Node3D, chunk_length: float, generator: Node3D) -> void:
	var last_z_key := "_quiz_last_obs_z"
	var carry_over: float = 0.0
	if GameManager.has_meta(last_z_key):
		carry_over = GameManager.get_meta(last_z_key)

	var z: float = -carry_over if carry_over > 0.0 else -QUIZ_MIN_ROW_GAP

	# Track quiz obstacle sequence index for cycling types
	var seq_key := "_quiz_obstacle_seq"
	var seq_idx: int = GameManager.get_meta(seq_key, 0) as int

	while z > -(chunk_length - 2.0):
		# Cycle through 4 types in order, then randomize
		var obs_type: int
		if seq_idx < 4:
			obs_type = seq_idx  # First 4: guaranteed one of each
		else:
			obs_type = randi() % 4  # After that: random

		_create_quiz_row_typed(chunk, z, generator, obs_type)
		seq_idx += 1

		var gap: float = randf_range(QUIZ_MIN_ROW_GAP, QUIZ_MAX_ROW_GAP)
		z -= gap

	GameManager.set_meta(seq_key, seq_idx)

	var remaining: float = -(chunk_length) - z
	if remaining > 0:
		GameManager.set_meta(last_z_key, remaining)
	else:
		GameManager.set_meta(last_z_key, 0.0)


static func _create_quiz_row_typed(parent: Node3D, z_pos: float, generator: Node3D, obs_type: int) -> void:
	## Create a quiz obstacle row based on type.
	## All rows block all 3 lanes. The type determines HOW to clear them.

	# Store the obstacle type as metadata on a marker node so QuizManager can read it
	var marker := Node3D.new()
	marker.name = "QuizObstacleMarker"
	marker.position = Vector3(0.0, 0.0, z_pos)
	marker.set_meta("quiz_obstacle_type", obs_type)
	marker.add_to_group("quiz_obstacles")
	parent.add_child(marker)

	match obs_type:
		QUIZ_TYPE_JUMP:
			# Ground blocks across all 3 lanes — answer addition to jump
			for lane_idx in 3:
				var lane_x: float = GameManager.LANE_POSITIONS[lane_idx]
				var pos := Vector3(lane_x, 0.0, z_pos)
				var obs_script: GDScript = load(OBSTACLE_SCRIPT) as GDScript
				if not obs_script:
					return
				var obstacle := Area3D.new()
				obstacle.set_script(obs_script)
				obstacle.position = pos
				obstacle.name = "QuizJumpBlock"
				parent.add_child(obstacle)
				var block_mat := StandardMaterial3D.new()
				block_mat.albedo_color = Color(0.2, 0.7, 0.3)  # Green for addition
				obstacle.call("setup_placeholder",
					Vector3(QUIZ_BLOCK_WIDTH * 2.2, QUIZ_BLOCK_HEIGHT, 0.6),
					block_mat)

		QUIZ_TYPE_SLIDE:
			# Overhead blocks across all 3 lanes — answer subtraction to slide
			for lane_idx in 3:
				var lane_x: float = GameManager.LANE_POSITIONS[lane_idx]
				var pos := Vector3(lane_x, 0.0, z_pos)
				var obs_script: GDScript = load(OBSTACLE_SCRIPT) as GDScript
				if not obs_script:
					return
				var obstacle := Area3D.new()
				obstacle.set_script(obs_script)
				obstacle.position = pos
				obstacle.name = "QuizSlideBlock"
				parent.add_child(obstacle)
				# Create overhead obstacle using placeholder
				var block_mat := StandardMaterial3D.new()
				block_mat.albedo_color = Color(0.85, 0.55, 0.1)  # Orange for subtraction
				obstacle.call("setup_placeholder",
					Vector3(QUIZ_BLOCK_WIDTH * 2.2, 0.5, 0.6),
					block_mat)
				# Elevate to overhead position (must slide under)
				obstacle.position.y = 0.9

		QUIZ_TYPE_BLAST:
			# Giant rock across all 3 lanes — answer multiplication to blast
			var rock_script: GDScript = load(GIANT_ROCK_SCRIPT) as GDScript
			if not rock_script:
				return
			var rock := Area3D.new()
			rock.set_script(rock_script)
			rock.position = Vector3(0.0, 0.0, z_pos)
			rock.name = "QuizGiantRock"
			parent.add_child(rock)
			var model_scene: PackedScene = null
			if generator and generator.has_method("get_random_giant_rock_scene"):
				model_scene = generator.get_random_giant_rock_scene()
			rock.call("setup", model_scene)
			rock.add_to_group("quiz_blast_rocks")

		QUIZ_TYPE_RIVER:
			# River across the road — answer division to build bridge
			var river := Node3D.new()
			river.name = "QuizRiverCrossing"
			river.position = Vector3(0.0, 0.0, z_pos)
			river.add_to_group("river_crossings")
			river.add_to_group("quiz_rivers")

			_add_river_visuals(river)

			# Per-lane kill zones
			for lane_idx in 3:
				var lane_x: float = GameManager.LANE_POSITIONS[lane_idx]
				var kill_zone := Area3D.new()
				kill_zone.name = "RiverKillZone_Lane%d" % lane_idx
				kill_zone.position = Vector3(lane_x, 0.5, 0.0)
				kill_zone.collision_layer = 4
				kill_zone.collision_mask = 0
				kill_zone.add_to_group("obstacles")
				kill_zone.add_to_group("river_kill_zones")
				kill_zone.set_meta("lane_index", lane_idx)
				var col := CollisionShape3D.new()
				var box := BoxShape3D.new()
				box.size = Vector3(GameManager.LANE_WIDTH, 1.5, RIVER_DEPTH - 0.2)
				col.shape = box
				kill_zone.add_child(col)
				river.add_child(kill_zone)

			parent.add_child(river)


# =============================================================================
# SHARED HELPERS
# =============================================================================


static func _add_river_visuals(river: Node3D) -> void:
	if GameManager.is_cyberprank_theme():
		_add_cyber_trench_visuals(river)
		return

	var river_width: float = RIVER_ROAD_WIDTH + 2.0

	river.add_child(_create_river_plane(
		Vector2(river_width, RIVER_DEPTH),
		0.11,
		Color(0.10, 0.36, 0.28, 0.86),
		0.18,
		Color(0.05, 0.14, 0.11, 1.0),
		0.35
	))

	river.add_child(_create_river_plane(
		Vector2(river_width + 0.35, RIVER_DEPTH + 0.55),
		0.05,
		Color(0.03, 0.10, 0.09, 0.94),
		0.92
	))

	river.add_child(_create_river_bank(river_width, -RIVER_DEPTH * 0.5 - 0.35))
	river.add_child(_create_river_bank(river_width, RIVER_DEPTH * 0.5 + 0.35))
	river.add_child(_create_foam_strip(river_width - 0.4, -RIVER_DEPTH * 0.5 + 0.18))
	river.add_child(_create_foam_strip(river_width - 0.4, RIVER_DEPTH * 0.5 - 0.18))


static func _add_cyber_trench_visuals(river: Node3D) -> void:
	var trench_width: float = RIVER_ROAD_WIDTH + 2.2

	river.add_child(_create_river_plane(
		Vector2(trench_width, RIVER_DEPTH + 0.8),
		0.02,
		Color(0.02, 0.03, 0.07, 0.98),
		0.18,
		Color(0.04, 0.12, 0.20, 1.0),
		0.35
	))

	river.add_child(_create_river_plane(
		Vector2(trench_width - 0.5, RIVER_DEPTH - 0.35),
		-0.20,
		Color(0.04, 0.10, 0.18, 0.92),
		0.06,
		Color(0.12, 0.84, 1.0, 1.0),
		3.8
	))

	river.add_child(_create_river_plane(
		Vector2(trench_width - 1.0, RIVER_DEPTH - 1.0),
		-0.28,
		Color(0.30, 0.08, 0.44, 0.76),
		0.08,
		Color(0.86, 0.18, 1.0, 1.0),
		2.1
	))

	river.add_child(_create_trench_wall(trench_width, -RIVER_DEPTH * 0.5 - 0.38))
	river.add_child(_create_trench_wall(trench_width, RIVER_DEPTH * 0.5 + 0.38))
	river.add_child(_create_trench_glow_strip(trench_width - 0.5, -RIVER_DEPTH * 0.5 + 0.16))
	river.add_child(_create_trench_glow_strip(trench_width - 0.5, RIVER_DEPTH * 0.5 - 0.16))
	river.add_child(_create_trench_core_strip(trench_width - 1.4))
	river.add_child(_create_trench_threshold(trench_width - 0.3, -RIVER_DEPTH * 0.5 - 0.10, false))
	river.add_child(_create_trench_threshold(trench_width - 0.3, RIVER_DEPTH * 0.5 + 0.10, true))

	for x_sign in [-1.0, 1.0]:
		var side_column := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.22, 0.55, RIVER_DEPTH + 0.2)
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(0.07, 0.12, 0.18, 1.0)
		material.roughness = 0.22
		material.emission_enabled = true
		material.emission = Color(0.08, 0.70, 0.96, 1.0)
		material.emission_energy_multiplier = 0.7
		mesh.material = material
		side_column.mesh = mesh
		side_column.position = Vector3(x_sign * (trench_width * 0.5 - 0.1), 0.2, 0.0)
		river.add_child(side_column)

	for lane_x in GameManager.LANE_POSITIONS:
		for z_sign in [-1.0, 1.0]:
			river.add_child(_create_trench_warning_tile(
				Vector3(lane_x, 0.03, z_sign * ((RIVER_DEPTH * 0.5) + 0.48)),
				z_sign > 0.0
			))

	for side in [-1.0, 1.0]:
		for z_sign in [-1.0, 1.0]:
			river.add_child(_create_trench_pylon(
				Vector3(side * (trench_width * 0.5 - 0.18), 0.18, z_sign * ((RIVER_DEPTH * 0.5) - 0.22)),
				side < 0.0
			))


static func _create_river_plane(size: Vector2, y: float, color: Color, roughness: float, emission: Color = Color(0, 0, 0, 1), emission_energy: float = 0.0) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = size
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	if emission_energy > 0.0:
		material.emission_enabled = true
		material.emission = emission
		material.emission_energy_multiplier = emission_energy
	plane.material = material
	mesh_instance.mesh = plane
	mesh_instance.position = Vector3(0.0, y, 0.0)
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mesh_instance


static func _create_river_bank(width: float, z_pos: float) -> MeshInstance3D:
	var bank := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(width, 0.22, 0.45)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.30, 0.25, 0.17, 1.0)
	material.roughness = 0.95
	box.material = material
	bank.mesh = box
	bank.position = Vector3(0.0, 0.06, z_pos)
	return bank


static func _create_foam_strip(width: float, z_pos: float) -> MeshInstance3D:
	var foam := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(width, 0.28)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.78, 0.89, 0.72, 0.62)
	material.roughness = 0.35
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	plane.material = material
	foam.mesh = plane
	foam.position = Vector3(0.0, 0.125, z_pos)
	foam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return foam


static func _create_trench_wall(width: float, z_pos: float) -> MeshInstance3D:
	var wall := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(width, 0.24, 0.38)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.09, 0.11, 0.16, 1.0)
	material.roughness = 0.24
	material.metallic = 0.45
	material.emission_enabled = true
	material.emission = Color(0.06, 0.56, 0.82, 1.0)
	material.emission_energy_multiplier = 0.55
	box.material = material
	wall.mesh = box
	wall.position = Vector3(0.0, 0.05, z_pos)
	return wall


static func _create_trench_glow_strip(width: float, z_pos: float) -> MeshInstance3D:
	var glow := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(width, 0.18)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.44, 0.96, 1.0, 0.82)
	material.roughness = 0.05
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.emission_enabled = true
	material.emission = Color(0.18, 0.86, 1.0, 1.0)
	material.emission_energy_multiplier = 3.0
	plane.material = material
	glow.mesh = plane
	glow.position = Vector3(0.0, 0.125, z_pos)
	glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return glow


static func _create_trench_core_strip(width: float) -> MeshInstance3D:
	var core := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(width, 0.22)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.82, 0.26, 1.0, 0.50)
	material.roughness = 0.02
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.emission_enabled = true
	material.emission = Color(0.14, 0.96, 1.0, 1.0)
	material.emission_energy_multiplier = 4.6
	plane.material = material
	core.mesh = plane
	core.position = Vector3(0.0, -0.12, 0.0)
	core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return core


static func _create_trench_threshold(width: float, z_pos: float, use_magenta: bool) -> MeshInstance3D:
	var threshold := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(width, 0.08, 0.22)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.08, 0.14, 0.18, 1.0)
	material.roughness = 0.12
	material.metallic = 0.52
	material.emission_enabled = true
	material.emission = Color(0.88, 0.24, 1.0, 1.0) if use_magenta else Color(0.12, 0.92, 1.0, 1.0)
	material.emission_energy_multiplier = 1.25
	mesh.material = material
	threshold.mesh = mesh
	threshold.position = Vector3(0.0, 0.05, z_pos)
	threshold.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return threshold


static func _create_trench_warning_tile(pos: Vector3, use_magenta: bool) -> MeshInstance3D:
	var tile := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(GameManager.LANE_WIDTH * 0.62, 0.024, 0.32)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.10, 0.18, 0.24, 0.94)
	material.roughness = 0.05
	material.metallic = 0.36
	material.emission_enabled = true
	material.emission = Color(0.14, 0.92, 1.0, 1.0) if not use_magenta else Color(0.92, 0.24, 1.0, 1.0)
	material.emission_energy_multiplier = 1.55
	mesh.material = material
	tile.mesh = mesh
	tile.position = pos
	tile.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return tile


static func _create_trench_pylon(pos: Vector3, use_magenta: bool) -> Node3D:
	var pylon := Node3D.new()
	pylon.position = pos

	var base := MeshInstance3D.new()
	var base_mesh := BoxMesh.new()
	base_mesh.size = Vector3(0.24, 0.42, 0.24)
	var base_material := StandardMaterial3D.new()
	base_material.albedo_color = Color(0.05, 0.10, 0.14, 1.0)
	base_material.roughness = 0.18
	base_material.metallic = 0.58
	base_material.emission_enabled = true
	base_material.emission = Color(0.08, 0.66, 0.92, 1.0)
	base_material.emission_energy_multiplier = 0.55
	base_mesh.material = base_material
	base.mesh = base_mesh
	pylon.add_child(base)

	var beam := MeshInstance3D.new()
	var beam_mesh := BoxMesh.new()
	beam_mesh.size = Vector3(0.08, 0.86, 0.08)
	var beam_material := StandardMaterial3D.new()
	beam_material.albedo_color = Color(0.12, 0.20, 0.26, 0.84)
	beam_material.roughness = 0.04
	beam_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	beam_material.emission_enabled = true
	beam_material.emission = Color(0.86, 0.24, 1.0, 1.0) if use_magenta else Color(0.12, 0.92, 1.0, 1.0)
	beam_material.emission_energy_multiplier = 2.6
	beam_mesh.material = beam_material
	beam.mesh = beam_mesh
	beam.position.y = 0.38
	beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pylon.add_child(beam)

	return pylon


static func _spawn_river_crossing(chunk: Node3D, chunk_length: float, chunk_dist: float) -> float:
	var river_z: float = -(chunk_length * 0.5)
	var river := Node3D.new()
	river.name = "RiverCrossing"
	river.position = Vector3(0.0, 0.0, river_z)
	river.add_to_group("river_crossings")
	_add_river_visuals(river)

	for lane_idx in 3:
		var lane_x: float = GameManager.LANE_POSITIONS[lane_idx]
		var kill_zone := Area3D.new()
		kill_zone.name = "RiverKillZone_Lane%d" % lane_idx
		kill_zone.position = Vector3(lane_x, 0.5, 0.0)
		kill_zone.collision_layer = 4
		kill_zone.collision_mask = 0
		kill_zone.add_to_group("obstacles")
		kill_zone.add_to_group("river_kill_zones")
		kill_zone.set_meta("lane_index", lane_idx)

		var col := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(GameManager.LANE_WIDTH, 1.5, RIVER_DEPTH - 0.2)
		col.shape = box
		kill_zone.add_child(col)
		river.add_child(kill_zone)

	chunk.add_child(river)
	GameManager.set_meta("_last_river_dist", chunk_dist)
	print("[River] === SPAWNED at chunk_dist=%.0f ==" % chunk_dist)
	return river_z


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

static func _should_spawn_giant_rock(chunk_dist: float) -> bool:
	# Only in normal mode
	if not GameManager.is_normal_mode():
		return false

	var last_dist: float = GameManager.get_meta("_last_giant_rock_dist", -999.0) as float

	# GUARANTEED first giant rock early so the blast obstacle is easy to verify.
	if last_dist < 0 and chunk_dist >= 20.0:
		print("[GiantRock] GUARANTEED first spawn at chunk_dist=%.0f" % chunk_dist)
		return true

	# After that, random with spacing enforced
	if chunk_dist - last_dist < GIANT_ROCK_MIN_DISTANCE:
		return false
	var roll: float = randf()
	print("[GiantRock] chunk_dist=%.0f last=%.0f roll=%.2f need<%.2f" % [chunk_dist, last_dist, roll, GIANT_ROCK_CHANCE])
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


# =============================================================================
# RIVER CROSSING — deadly water, player must hold spacebar to build bridge
# =============================================================================

static func _try_spawn_river(chunk: Node3D, chunk_length: float, chunk_dist: float) -> float:
	## Returns the local Z position of the river if spawned, or -INF if not.
	if not GameManager.is_normal_mode():
		return -INF
	if chunk_dist < 30.0:
		return -INF

	var last_river_dist: float = GameManager.get_meta("_last_river_dist", -999.0) as float
	if chunk_dist - last_river_dist < RIVER_MIN_DISTANCE:
		return -INF

	# Guaranteed first river at ~60m
	var force_spawn: bool = last_river_dist < 0.0 and chunk_dist >= 60.0
	if not force_spawn and randf() > RIVER_CHANCE:
		return -INF
	return _spawn_river_crossing(chunk, chunk_length, chunk_dist)
