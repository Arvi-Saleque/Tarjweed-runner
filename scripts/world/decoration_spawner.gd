extends RefCounted
## DecorationSpawner - Places curated Quaternius environment props in clear depth bands.
## The goal is an authored runner backdrop: clean near-road dressing, readable mid-ground,
## and low-distraction silhouettes in the far background.

const NEAR_MIN_PER_SIDE: int = 8
const NEAR_MAX_PER_SIDE: int = 12
const MID_MIN_PER_SIDE: int = 5
const MID_MAX_PER_SIDE: int = 8
const FAR_MIN_PER_SIDE: int = 4
const FAR_MAX_PER_SIDE: int = 6

const PATH_EDGE_BUFFER: float = 1.2
const NEAR_X_MIN: float = 5.2
const NEAR_X_MAX: float = 10.0
const MID_X_MIN: float = 10.0
const MID_X_MAX: float = 18.0
const FAR_X_MIN: float = 18.0
const FAR_X_MAX: float = 32.0

const NEAR_SCALE: Dictionary = {
	"grass": Vector2(0.75, 1.4),
	"flowers": Vector2(0.9, 1.35),
	"rocks_small": Vector2(0.55, 1.0),
	"bushes": Vector2(0.7, 1.15),
}

const MID_SCALE: Dictionary = {
	"bushes": Vector2(0.9, 1.4),
	"rocks": Vector2(0.9, 1.45),
	"trees_large": Vector2(0.95, 1.35),
	"trees_pine": Vector2(0.95, 1.35),
}

const FAR_SCALE: Dictionary = {
	"trees_large": Vector2(1.15, 1.9),
	"trees_pine": Vector2(1.15, 1.85),
	"background": Vector2(1.35, 2.25),
}


static func spawn_decorations(chunk: Node3D, chunk_length: float, path_width: float, generator: Node3D) -> void:
	if not generator or generator.decoration_scenes.is_empty():
		_spawn_fallback_decorations(chunk, chunk_length, path_width)
		return

	var deco_container := Node3D.new()
	deco_container.name = "Decorations"
	chunk.add_child(deco_container)

	for side in [-1.0, 1.0]:
		_spawn_near_band(deco_container, chunk_length, path_width, generator, side)
		_spawn_mid_band(deco_container, chunk_length, generator, side)
		_spawn_far_band(deco_container, chunk_length, generator, side)


static func _spawn_near_band(container: Node3D, chunk_length: float, path_width: float, generator: Node3D, side: float) -> void:
	var near_categories: Array[String] = ["grass", "grass", "grass", "bushes", "bushes", "rocks_small", "flowers"]
	var count: int = randi_range(NEAR_MIN_PER_SIDE, NEAR_MAX_PER_SIDE)

	for i in count:
		var category: String = near_categories[randi() % near_categories.size()]
		var scene := _pick_scene(generator, category)
		if scene == null:
			continue

		var instance: Node3D = scene.instantiate()
		var x: float = side * randf_range(maxf(path_width * 0.5 + PATH_EDGE_BUFFER, NEAR_X_MIN), NEAR_X_MAX)
		var z: float = randf_range(0.0, -chunk_length)
		instance.position = Vector3(x, 0.0, z)
		instance.rotation.y = randf_range(0.0, TAU)

		var scale_range: Vector2 = NEAR_SCALE.get(category, Vector2(0.9, 1.1))
		var s: float = randf_range(scale_range.x, scale_range.y)
		instance.scale = Vector3(s, s, s)

		# Keep near-road dressing low and readable.
		if category == "flowers":
			instance.position.x = side * randf_range(NEAR_X_MIN, 8.0)
		elif category == "rocks_small":
			instance.position.x = side * randf_range(NEAR_X_MIN, 8.8)
		elif category == "grass":
			instance.position.x = side * randf_range(path_width * 0.5 + 0.9, NEAR_X_MAX)

		container.add_child(instance)


static func _spawn_mid_band(container: Node3D, chunk_length: float, generator: Node3D, side: float) -> void:
	var mid_categories: Array[String] = ["bushes", "bushes", "rocks", "trees_large", "trees_pine"]
	var count: int = randi_range(MID_MIN_PER_SIDE, MID_MAX_PER_SIDE)

	for i in count:
		var category: String = mid_categories[randi() % mid_categories.size()]
		var scene := _pick_scene(generator, category)
		if scene == null:
			continue

		var instance: Node3D = scene.instantiate()
		instance.position = Vector3(
			side * randf_range(MID_X_MIN, MID_X_MAX),
			0.0,
			randf_range(0.0, -chunk_length)
		)
		instance.rotation.y = randf_range(0.0, TAU)

		var scale_range: Vector2 = MID_SCALE.get(category, Vector2(0.95, 1.2))
		var s: float = randf_range(scale_range.x, scale_range.y)
		instance.scale = Vector3(s, s, s)

		if category in ["trees_large", "trees_pine", "rocks"]:
			_disable_shadows_recursive(instance)

		container.add_child(instance)


static func _spawn_far_band(container: Node3D, chunk_length: float, generator: Node3D, side: float) -> void:
	var far_categories: Array[String] = ["trees_large", "trees_pine", "background", "background"]
	var count: int = randi_range(FAR_MIN_PER_SIDE, FAR_MAX_PER_SIDE)

	for i in count:
		var category: String = far_categories[randi() % far_categories.size()]
		var scene := _pick_scene(generator, category)
		if scene == null:
			continue

		var instance: Node3D = scene.instantiate()
		instance.position = Vector3(
			side * randf_range(FAR_X_MIN, FAR_X_MAX),
			0.0,
			randf_range(0.0, -chunk_length)
		)
		instance.rotation.y = randf_range(-0.15, 0.15)

		var scale_range: Vector2 = FAR_SCALE.get(category, Vector2(1.2, 1.8))
		var s: float = randf_range(scale_range.x, scale_range.y)
		var y_scale: float = s
		if category == "background":
			y_scale *= randf_range(1.0, 1.2)
			instance.position.y = -0.1
		instance.scale = Vector3(s, y_scale, s)

		_disable_shadows_recursive(instance)
		container.add_child(instance)


static func _pick_scene(generator: Node3D, category: String) -> PackedScene:
	var scenes: Array = generator.decoration_scenes.get(category, [])
	if scenes.is_empty():
		return null
	return scenes[randi() % scenes.size()]


static func _disable_shadows_recursive(node: Node) -> void:
	if node is GeometryInstance3D:
		(node as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for child in node.get_children():
		_disable_shadows_recursive(child)


static func _spawn_fallback_decorations(chunk: Node3D, chunk_length: float, path_width: float) -> void:
	## Minimal fallback if imported decoration scenes are unavailable.
	var deco_container := Node3D.new()
	deco_container.name = "Decorations"
	chunk.add_child(deco_container)

	var bush_material := StandardMaterial3D.new()
	bush_material.albedo_color = Color(0.28, 0.48, 0.22, 1.0)

	var rock_material := StandardMaterial3D.new()
	rock_material.albedo_color = Color(0.42, 0.39, 0.34, 1.0)

	for side in [-1.0, 1.0]:
		for i in 5:
			var x: float = side * randf_range(path_width * 0.5 + 1.2, 12.0)
			var z: float = randf_range(0.0, -chunk_length)

			var node := MeshInstance3D.new()
			if i % 2 == 0:
				var sphere := SphereMesh.new()
				sphere.radius = randf_range(0.45, 0.9)
				sphere.height = sphere.radius * 2.0
				sphere.material = bush_material
				node.mesh = sphere
				node.position = Vector3(x, sphere.radius * 0.55, z)
			else:
				var box := BoxMesh.new()
				box.size = Vector3(0.8, 0.45, 0.8)
				box.material = rock_material
				node.mesh = box
				node.position = Vector3(x, 0.22, z)
			deco_container.add_child(node)
