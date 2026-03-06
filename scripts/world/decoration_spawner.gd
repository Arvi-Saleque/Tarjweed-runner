extends RefCounted
## DecorationSpawner — Populates chunk sides with environment props (trees, bushes, rocks).
## Uses preloaded GLB scenes from WorldGenerator.

# How many decorations per side per chunk
const MIN_DECORATIONS_PER_SIDE: int = 3
const MAX_DECORATIONS_PER_SIDE: int = 7

# X-axis placement ranges (outside the path)
const SIDE_X_MIN: float = 4.5   # Just beyond path edge
const SIDE_X_MAX: float = 18.0  # Far out for depth

# Category weights (higher = more likely to be picked)
const CATEGORY_WEIGHTS: Dictionary = {
	"trees_large": 3.0,
	"trees_small": 2.5,
	"bushes": 3.0,
	"rocks": 2.0,
	"props": 1.5,
	"ground_cover": 2.0,
}

# Scale ranges per category
const SCALE_RANGES: Dictionary = {
	"trees_large": Vector2(0.8, 1.3),
	"trees_small": Vector2(0.7, 1.2),
	"bushes": Vector2(0.6, 1.4),
	"rocks": Vector2(0.5, 1.2),
	"props": Vector2(0.8, 1.1),
	"ground_cover": Vector2(0.5, 1.0),
}


static func spawn_decorations(chunk: Node3D, chunk_length: float, path_width: float, generator: Node3D) -> void:
	if not generator or generator.decoration_scenes.is_empty():
		_spawn_fallback_decorations(chunk, chunk_length, path_width)
		return

	var deco_container := Node3D.new()
	deco_container.name = "Decorations"
	chunk.add_child(deco_container)

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
			if category == "trees_large":
				instance.position.x = side * randf_range(6.0, SIDE_X_MAX)
			elif category == "bushes":
				instance.position.x = side * randf_range(SIDE_X_MIN, 10.0)
			elif category == "ground_cover":
				instance.position.x = side * randf_range(SIDE_X_MIN, 8.0)
				instance.position.y = 0.0

			deco_container.add_child(instance)


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
