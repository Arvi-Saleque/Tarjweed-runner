extends RefCounted
## DecorationSpawner — Populates chunk sides with environment props (trees, bushes, rocks).
## Uses preloaded GLB scenes from WorldGenerator.

# How many decorations per side per chunk
const MIN_DECORATIONS_PER_SIDE: int = 12
const MAX_DECORATIONS_PER_SIDE: int = 24

# X-axis placement ranges (outside the path)
const SIDE_X_MIN: float = 4.0   # Just beyond path edge
const SIDE_X_MAX: float = 20.0  # Far out for depth

# Category weights (higher = more likely to be picked)
const CATEGORY_WEIGHTS: Dictionary = {
	"trees_large": 3.0,
	"trees_pine": 2.5,
	"trees_small": 2.0,
	"bushes": 3.5,
	"flowers": 3.0,
	"rocks": 2.0,
	"rocks_small": 2.0,
	"props": 2.5,
	"ground_cover": 4.0,
	"roadside": 2.5,
	"ground_paths": 1.5,
}

# Scale ranges per category
const SCALE_RANGES: Dictionary = {
	"trees_large": Vector2(0.8, 1.4),
	"trees_pine": Vector2(0.7, 1.3),
	"trees_small": Vector2(0.7, 1.2),
	"bushes": Vector2(0.6, 1.4),
	"flowers": Vector2(0.8, 1.5),
	"rocks": Vector2(0.5, 1.2),
	"rocks_small": Vector2(0.4, 0.9),
	"props": Vector2(0.8, 1.1),
	"ground_cover": Vector2(0.5, 1.2),
	"roadside": Vector2(0.7, 1.2),
	"ground_paths": Vector2(0.6, 1.0),
}


# Mountain/hill background settings
const MOUNTAIN_CHANCE_PER_SIDE: float = 0.6   # 60% chance per side per chunk
const MOUNTAIN_X_MIN: float = 30.0            # Far from road
const MOUNTAIN_X_MAX: float = 55.0            # Very far background
const MOUNTAIN_SCALE_MIN: float = 4.0         # Large hills
const MOUNTAIN_SCALE_MAX: float = 8.0         # Massive mountains
const MOUNTAIN_Y_OFFSET: float = -1.5         # Sink slightly into ground


static func spawn_decorations(chunk: Node3D, chunk_length: float, path_width: float, generator: Node3D) -> void:
	if not generator or generator.decoration_scenes.is_empty():
		_spawn_fallback_decorations(chunk, chunk_length, path_width)
		return

	var deco_container := Node3D.new()
	deco_container.name = "Decorations"
	chunk.add_child(deco_container)

	# Spawn background mountains (separate from weighted random system)
	_spawn_background_mountains(deco_container, chunk_length, generator)

	# Spawn decorations on both sides
	for side in [-1.0, 1.0]:
		var count: int = randi_range(MIN_DECORATIONS_PER_SIDE, MAX_DECORATIONS_PER_SIDE)

		for i in count:
			var category: String = _pick_weighted_category(generator.decoration_scenes)
			var scenes: Array = generator.decoration_scenes.get(category, [])
			if scenes.is_empty():
				continue

			var scene: PackedScene = scenes[randi() % scenes.size()]
			var instance: Node3D = scene.instantiate()

			# Position
			var x: float = side * randf_range(SIDE_X_MIN, SIDE_X_MAX)
			var z: float = randf_range(0, -chunk_length)
			instance.position = Vector3(x, 0, z)

			# Random Y rotation
			instance.rotation.y = randf_range(0, TAU)

			# Random scale within category range
			var scale_range: Vector2 = SCALE_RANGES.get(category, Vector2(0.8, 1.2))
			var s: float = randf_range(scale_range.x, scale_range.y)
			instance.scale = Vector3(s, s, s)

			# Large trees deeper in, smaller stuff closer to path
			if category == "trees_large" or category == "trees_pine":
				instance.position.x = side * randf_range(6.0, SIDE_X_MAX)
			elif category == "bushes":
				instance.position.x = side * randf_range(SIDE_X_MIN, 12.0)
			elif category == "flowers":
				instance.position.x = side * randf_range(SIDE_X_MIN, 10.0)
			elif category == "rocks_small":
				instance.position.x = side * randf_range(SIDE_X_MIN, 9.0)
			elif category == "ground_cover":
				instance.position.x = side * randf_range(SIDE_X_MIN, 8.0)
				instance.position.y = 0.0
			elif category == "roadside":
				# Barrels, crates, fences — close to path edge for realism
				instance.position.x = side * randf_range(SIDE_X_MIN, 8.0)
			elif category == "ground_paths":
				# Ground path/grass patches — close and flat
				instance.position.x = side * randf_range(SIDE_X_MIN, 12.0)
				instance.position.y = 0.01

			# Disable shadow casting on large decorations to prevent road darkening
			if category in ["trees_large", "trees_pine", "rocks"]:
				_disable_shadows_recursive(instance)

			deco_container.add_child(instance)


static func _disable_shadows_recursive(node: Node) -> void:
	if node is GeometryInstance3D:
		(node as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for child in node.get_children():
		_disable_shadows_recursive(child)


static func _pick_weighted_category(available_scenes: Dictionary) -> String:
	var total_weight: float = 0.0
	var valid_categories: Array[String] = []
	var weights: Array[float] = []

	for category: String in CATEGORY_WEIGHTS:
		var scenes: Array = available_scenes.get(category, [])
		if scenes.is_empty():
			continue
		var w: float = CATEGORY_WEIGHTS[category]
		valid_categories.append(category)
		weights.append(w)
		total_weight += w

	if valid_categories.is_empty():
		return ""

	var roll: float = randf() * total_weight
	var cumulative: float = 0.0
	for i in valid_categories.size():
		cumulative += weights[i]
		if roll <= cumulative:
			return valid_categories[i]

	return valid_categories.back()


static func _spawn_background_mountains(container: Node3D, chunk_length: float, generator: Node3D) -> void:
	## Place 0-1 large mountain hills per side, far in the background.
	var mountain_scenes: Array = generator.decoration_scenes.get("mountains", [])
	if mountain_scenes.is_empty():
		return

	for side in [-1.0, 1.0]:
		if randf() > MOUNTAIN_CHANCE_PER_SIDE:
			continue

		var scene: PackedScene = mountain_scenes[randi() % mountain_scenes.size()]
		var instance: Node3D = scene.instantiate()

		# Place far from road, random Z within chunk
		var x: float = side * randf_range(MOUNTAIN_X_MIN, MOUNTAIN_X_MAX)
		var z: float = randf_range(0, -chunk_length)
		instance.position = Vector3(x, MOUNTAIN_Y_OFFSET, z)

		# Large scale for imposing background presence
		var s: float = randf_range(MOUNTAIN_SCALE_MIN, MOUNTAIN_SCALE_MAX)
		# Slight Y scale variation for different mountain profiles
		var sy: float = s * randf_range(0.7, 1.3)
		instance.scale = Vector3(s, sy, s)

		# Random Y rotation for variety
		instance.rotation.y = randf_range(0, TAU)

		# Disable shadow casting — large mountains cast shadows over the whole road
		_disable_shadows_recursive(instance)

		container.add_child(instance)


static func _spawn_fallback_decorations(chunk: Node3D, chunk_length: float, path_width: float) -> void:
	## Fallback: green cylinders as placeholder trees when GLB models aren't available
	var deco_container := Node3D.new()
	deco_container.name = "Decorations"
	chunk.add_child(deco_container)

	var tree_material := StandardMaterial3D.new()
	tree_material.albedo_color = Color(0.2, 0.5, 0.15, 1.0)

	var trunk_material := StandardMaterial3D.new()
	trunk_material.albedo_color = Color(0.4, 0.25, 0.1, 1.0)

	for side in [-1.0, 1.0]:
		var count: int = randi_range(2, 5)
		for i in count:
			var tree := Node3D.new()
			var x: float = side * randf_range(SIDE_X_MIN, 14.0)
			var z: float = randf_range(0, -chunk_length)
			tree.position = Vector3(x, 0, z)
			tree.name = "FallbackTree"

			# Trunk
			var trunk_mesh := MeshInstance3D.new()
			var trunk_cyl := CylinderMesh.new()
			trunk_cyl.top_radius = 0.15
			trunk_cyl.bottom_radius = 0.2
			trunk_cyl.height = 2.0
			trunk_cyl.material = trunk_material
			trunk_mesh.mesh = trunk_cyl
			trunk_mesh.position.y = 1.0
			trunk_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
			tree.add_child(trunk_mesh)

			# Canopy
			var canopy_mesh := MeshInstance3D.new()
			var canopy_sphere := SphereMesh.new()
			canopy_sphere.radius = randf_range(0.8, 1.5)
			canopy_sphere.height = canopy_sphere.radius * 2.0
			canopy_sphere.material = tree_material
			canopy_mesh.mesh = canopy_sphere
			canopy_mesh.position.y = 2.0 + canopy_sphere.radius * 0.5
			canopy_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
			tree.add_child(canopy_mesh)

			deco_container.add_child(tree)
