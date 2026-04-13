extends RefCounted
## DecorationSpawner - Places curated Quaternius environment props in clear depth bands.
## The goal is an authored runner backdrop: clean near-road dressing, readable mid-ground,
## and low-distraction silhouettes in the far background.

const CyberAmbientMotionScript = preload("res://scripts/world/cyber_ambient_motion.gd")

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

const CYBER_FAMILY_ORDER: Array[String] = [
	"pod_hub",
	"sign_corridor",
	"machine_yard",
	"dome_cluster",
	"support_bay",
	"service_sprawl",
]


static func spawn_decorations(chunk: Node3D, chunk_length: float, path_width: float, generator: Node3D) -> void:
	if not generator or generator.decoration_scenes.is_empty():
		_spawn_fallback_decorations(chunk, chunk_length, path_width)
		return

	var deco_container := Node3D.new()
	deco_container.name = "Decorations"
	chunk.add_child(deco_container)

	if _is_cyber_theme(generator):
		_spawn_cyber_decorations(chunk, deco_container, chunk_length, path_width, generator)
		return

	for side in [-1.0, 1.0]:
		_spawn_near_band(deco_container, chunk_length, path_width, generator, side)
		_spawn_mid_band(deco_container, chunk_length, generator, side)
		_spawn_far_band(deco_container, chunk_length, generator, side)


static func _spawn_cyber_decorations(chunk: Node3D, container: Node3D, chunk_length: float, path_width: float, generator: Node3D) -> void:
	var chunk_index: int = int(chunk.get("chunk_index"))
	for side in [-1.0, 1.0]:
		var family: String = _get_cyber_family(chunk_index, side)
		_spawn_cyber_near_band(container, chunk_length, path_width, generator, side, family, chunk_index)
		_spawn_cyber_mid_band(container, chunk_length, generator, side, family, chunk_index)
		_spawn_cyber_far_band(container, chunk_length, generator, side, family, chunk_index)
	_spawn_cyber_overhead_scenery(container, chunk_length, path_width, generator, chunk_index)


static func _spawn_cyber_near_band(container: Node3D, chunk_length: float, path_width: float, generator: Node3D, side: float, family: String, chunk_index: int) -> void:
	var count: int = randi_range(7, 10)
	var categories: Array[String] = _get_cyber_near_categories(family)

	for i in count:
		var scene := _pick_scene_from_categories(generator, categories)
		if scene == null:
			continue

		var instance: Node3D = scene.instantiate()
		var z: float = randf_range(0.0, -chunk_length)
		instance.position = Vector3(side * randf_range(path_width * 0.5 + 0.95, 9.4), 0.0, z)
		instance.rotation.y = randf_range(-0.12, 0.12) if family in ["sign_corridor", "support_bay"] else randf_range(0.0, TAU)

		var category: String = _guess_scene_category(generator, scene)
		var scale_range: Vector2 = _get_near_scale(generator, category)
		var scale_mul: float = 1.0
		if family == "sign_corridor" and category == "flowers":
			scale_mul = 1.12
		elif family == "machine_yard" and category == "rocks_small":
			scale_mul = 1.1
		var s: float = randf_range(scale_range.x, scale_range.y) * scale_mul
		instance.scale = Vector3(s, s, s)

		if category == "grass":
			instance.position.x = side * randf_range(path_width * 0.5 + 0.9, 11.0)
		elif category == "flowers":
			instance.position.x = side * randf_range(6.2, 9.0)
			instance.position.y = 0.04
		elif category == "rocks_small":
			instance.position.x = side * randf_range(5.9, 9.4)

		_apply_cyber_ambient_motion(instance, category, generator, chunk_index, side)
		container.add_child(instance)


static func _spawn_cyber_mid_band(container: Node3D, chunk_length: float, generator: Node3D, side: float, family: String, chunk_index: int) -> void:
	var count: int = randi_range(4, 6)
	var categories: Array[String] = _get_cyber_mid_categories(family)

	for i in count:
		var scene := _pick_scene_from_categories(generator, categories)
		if scene == null:
			continue

		var instance: Node3D = scene.instantiate()
		var category: String = _guess_scene_category(generator, scene)
		var depth_shift: float = randf_range(0.0, 2.0)
		var x_range: Vector2 = _get_cyber_mid_x_range(category)
		instance.position = Vector3(
			side * randf_range(x_range.x + depth_shift, x_range.y),
			0.0,
			randf_range(0.0, -chunk_length)
		)
		instance.rotation.y = randf_range(-0.08, 0.08) if category in ["signals", "infrastructure"] else randf_range(0.0, TAU)

		var scale_range: Vector2 = _get_mid_scale(generator, category if MID_SCALE.has(category) else "rocks")
		var scale_mul: float = 1.0
		if family == "dome_cluster" and category in ["pods", "background"]:
			scale_mul = 1.12
		elif family == "service_sprawl" and category == "service_props":
			scale_mul = 1.15
		if category in ["pods", "infrastructure", "trees_large", "trees_pine"]:
			scale_mul *= 0.84
		var s: float = randf_range(scale_range.x, scale_range.y) * scale_mul
		instance.scale = Vector3(s, s, s)

		_apply_cyber_ambient_motion(instance, category, generator, chunk_index, side)
		container.add_child(instance)


static func _spawn_cyber_far_band(container: Node3D, chunk_length: float, generator: Node3D, side: float, family: String, chunk_index: int) -> void:
	var count: int = randi_range(4, 6)
	var categories: Array[String] = _get_cyber_far_categories(family)

	for i in count:
		var scene := _pick_scene_from_categories(generator, categories)
		if scene == null:
			continue

		var instance: Node3D = scene.instantiate()
		var category: String = _guess_scene_category(generator, scene)
		var x_range: Vector2 = _get_cyber_far_x_range(category)
		instance.position = Vector3(
			side * randf_range(x_range.x, x_range.y),
			0.0,
			randf_range(0.0, -chunk_length)
		)
		instance.rotation.y = randf_range(-0.12, 0.12)

		var scale_range: Vector2 = _get_far_scale(generator, category if FAR_SCALE.has(category) else "background")
		var scale_mul: float = 1.0
		if category == "skyline":
			scale_mul = 1.12
		elif family == "dome_cluster" and category == "background":
			scale_mul = 1.15
		if category in ["background", "skyline", "infrastructure"]:
			scale_mul *= 0.82
		var s: float = randf_range(scale_range.x, scale_range.y) * scale_mul
		var y_scale: float = s * randf_range(1.0, 1.25)
		instance.scale = Vector3(s, y_scale, s)
		instance.position.y = -0.08 if category in ["background", "skyline"] else 0.0

		_disable_shadows_recursive(instance)
		_apply_cyber_ambient_motion(instance, category, generator, chunk_index, side)
		container.add_child(instance)


static func _spawn_cyber_overhead_scenery(container: Node3D, chunk_length: float, path_width: float, generator: Node3D, chunk_index: int) -> void:
	if chunk_index % 3 != 1:
		return
	var scene := _pick_scene(generator, "scenic_overhead")
	if scene == null:
		return

	var instance: Node3D = scene.instantiate()
	var side: float = -1.0 if chunk_index % 2 == 0 else 1.0
	instance.position = Vector3(side * randf_range(path_width * 0.5 + 10.0, 15.5), randf_range(7.0, 9.5), randf_range(-4.0, -(chunk_length - 4.0)))
	instance.rotation.y = PI * 0.5
	var s: float = randf_range(0.85, 1.15)
	instance.scale = Vector3(s, s, s)
	_disable_shadows_recursive(instance)
	_disable_collisions_recursive(instance)
	_apply_cyber_ambient_motion(instance, "scenic_overhead", generator, chunk_index, side)
	container.add_child(instance)


static func _get_cyber_mid_x_range(category: String) -> Vector2:
	match category:
		"pods", "infrastructure", "trees_large", "trees_pine":
			return Vector2(16.0, 26.0)
		"signals":
			return Vector2(12.5, 20.5)
		"service_props":
			return Vector2(10.0, 17.0)
		_:
			return Vector2(MID_X_MIN, MID_X_MAX + 2.0)


static func _get_cyber_far_x_range(category: String) -> Vector2:
	match category:
		"background", "skyline", "infrastructure":
			return Vector2(30.0, 46.0)
		"trees_large":
			return Vector2(24.0, 38.0)
		"trees_pine":
			return Vector2(22.0, 34.0)
		_:
			return Vector2(FAR_X_MIN + 4.0, FAR_X_MAX + 10.0)


static func _get_cyber_family(chunk_index: int, side: float) -> String:
	var side_offset: int = 0 if side < 0.0 else 2
	return CYBER_FAMILY_ORDER[posmod(chunk_index + side_offset, CYBER_FAMILY_ORDER.size())]


static func _get_cyber_near_categories(family: String) -> Array[String]:
	match family:
		"pod_hub":
			return ["service_props", "service_props", "signals", "rocks_small", "grass"]
		"sign_corridor":
			return ["signals", "signals", "service_props", "flowers", "rocks_small"]
		"machine_yard":
			return ["service_props", "service_props", "rocks_small", "rocks_small", "grass"]
		"dome_cluster":
			return ["flowers", "signals", "service_props", "rocks_small", "grass"]
		"support_bay":
			return ["service_props", "grass", "signals", "service_props", "rocks_small"]
		_:
			return ["service_props", "service_props", "signals", "grass", "rocks_small"]


static func _get_cyber_mid_categories(family: String) -> Array[String]:
	match family:
		"pod_hub":
			return ["pods", "pods", "infrastructure", "rocks"]
		"sign_corridor":
			return ["signals", "signals", "infrastructure", "trees_pine"]
		"machine_yard":
			return ["infrastructure", "infrastructure", "rocks", "bushes"]
		"dome_cluster":
			return ["pods", "pods", "rocks", "flowers"]
		"support_bay":
			return ["infrastructure", "trees_pine", "service_props", "rocks"]
		_:
			return ["service_props", "infrastructure", "rocks", "trees_large"]


static func _get_cyber_far_categories(family: String) -> Array[String]:
	match family:
		"pod_hub":
			return ["skyline", "background", "skyline", "trees_large"]
		"sign_corridor":
			return ["skyline", "skyline", "background", "trees_large"]
		"machine_yard":
			return ["skyline", "infrastructure", "background", "trees_large"]
		"dome_cluster":
			return ["background", "background", "skyline", "trees_large"]
		"support_bay":
			return ["skyline", "infrastructure", "skyline", "background"]
		_:
			return ["skyline", "background", "trees_large", "background"]


static func _pick_scene_from_categories(generator: Node3D, categories: Array[String]) -> PackedScene:
	var shuffled := categories.duplicate()
	shuffled.shuffle()
	for category in shuffled:
		var scene := _pick_scene(generator, category)
		if scene != null:
			return scene
	return null


static func _guess_scene_category(generator: Node3D, scene: PackedScene) -> String:
	for category in generator.decoration_scenes.keys():
		var scenes: Array = generator.decoration_scenes.get(category, [])
		if scene in scenes:
			return String(category)
	return ""


static func _spawn_near_band(container: Node3D, chunk_length: float, path_width: float, generator: Node3D, side: float) -> void:
	var near_categories: Array[String] = ["grass", "grass", "grass", "bushes", "bushes", "rocks_small", "flowers"]
	if _is_cyber_theme(generator):
		near_categories = ["grass", "grass", "rocks_small", "bushes", "flowers", "flowers"]
	elif _is_park_theme(generator):
		near_categories = ["grass", "grass", "grass", "flowers", "flowers", "bushes", "rocks_small"]
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

		var scale_range: Vector2 = _get_near_scale(generator, category)
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
	if _is_cyber_theme(generator):
		mid_categories = ["bushes", "rocks", "trees_pine", "trees_pine", "flowers"]
	elif _is_park_theme(generator):
		mid_categories = ["bushes", "flowers", "rocks", "trees_large", "trees_large", "trees_pine"]
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

		var scale_range: Vector2 = _get_mid_scale(generator, category)
		var s: float = randf_range(scale_range.x, scale_range.y)
		instance.scale = Vector3(s, s, s)

		if category in ["trees_large", "trees_pine", "rocks"] and not _is_cyber_theme(generator):
			_disable_shadows_recursive(instance)

		container.add_child(instance)


static func _spawn_far_band(container: Node3D, chunk_length: float, generator: Node3D, side: float) -> void:
	var far_categories: Array[String] = ["trees_large", "trees_pine", "background", "background"]
	if _is_cyber_theme(generator):
		far_categories = ["trees_large", "background", "background", "background"]
	elif _is_park_theme(generator):
		far_categories = ["trees_large", "trees_large", "trees_pine", "background"]
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

		var scale_range: Vector2 = _get_far_scale(generator, category)
		var s: float = randf_range(scale_range.x, scale_range.y)
		var y_scale: float = s
		if category == "background":
			y_scale *= randf_range(1.0, 1.2)
			instance.position.y = -0.1
		elif _is_cyber_theme(generator) and category == "trees_large":
			instance.position.y = -0.05
		instance.scale = Vector3(s, y_scale, s)

		_disable_shadows_recursive(instance)
		container.add_child(instance)


static func _pick_scene(generator: Node3D, category: String) -> PackedScene:
	var scenes: Array = generator.decoration_scenes.get(category, [])
	if scenes.is_empty():
		return null
	return scenes[randi() % scenes.size()]


static func _is_cyber_theme(generator: Node3D) -> bool:
	return generator != null and generator.get("theme_id") == "cyberprank"


static func _is_park_theme(generator: Node3D) -> bool:
	return generator != null and generator.get("theme_id") == "park"


static func _get_near_scale(generator: Node3D, category: String) -> Vector2:
	if _is_cyber_theme(generator):
		match category:
			"grass":
				return Vector2(0.70, 1.15)
			"flowers":
				return Vector2(0.80, 1.12)
			"rocks_small":
				return Vector2(0.65, 1.05)
			"bushes":
				return Vector2(0.75, 1.15)
			"service_props":
				return Vector2(0.72, 1.08)
			"signals":
				return Vector2(0.80, 1.12)
	if _is_park_theme(generator):
		match category:
			"grass":
				return Vector2(0.9, 1.35)
			"flowers":
				return Vector2(0.95, 1.4)
			"rocks_small":
				return Vector2(0.6, 0.95)
			"bushes":
				return Vector2(0.85, 1.2)
	return NEAR_SCALE.get(category, Vector2(0.9, 1.1))


static func _get_mid_scale(generator: Node3D, category: String) -> Vector2:
	if _is_cyber_theme(generator):
		match category:
			"bushes":
				return Vector2(0.75, 1.05)
			"rocks":
				return Vector2(1.0, 1.4)
			"trees_large":
				return Vector2(1.2, 1.8)
			"trees_pine":
				return Vector2(1.15, 1.95)
			"flowers":
				return Vector2(0.9, 1.35)
			"pods":
				return Vector2(1.0, 1.35)
			"infrastructure":
				return Vector2(1.1, 1.55)
			"service_props":
				return Vector2(0.95, 1.22)
			"signals":
				return Vector2(1.0, 1.25)
	if _is_park_theme(generator):
		match category:
			"bushes":
				return Vector2(1.0, 1.45)
			"rocks":
				return Vector2(0.95, 1.3)
			"trees_large":
				return Vector2(1.15, 1.65)
			"trees_pine":
				return Vector2(1.0, 1.45)
			"flowers":
				return Vector2(1.0, 1.35)
	return MID_SCALE.get(category, Vector2(0.95, 1.2))


static func _get_far_scale(generator: Node3D, category: String) -> Vector2:
	if _is_cyber_theme(generator):
		match category:
			"trees_large":
				return Vector2(1.8, 2.8)
			"trees_pine":
				return Vector2(1.5, 2.3)
			"background":
				return Vector2(2.0, 3.0)
			"skyline":
				return Vector2(2.2, 3.2)
			"infrastructure":
				return Vector2(1.6, 2.4)
	if _is_park_theme(generator):
		match category:
			"trees_large":
				return Vector2(1.45, 2.1)
			"trees_pine":
				return Vector2(1.3, 1.9)
			"background":
				return Vector2(1.6, 2.35)
	return FAR_SCALE.get(category, Vector2(1.2, 1.8))


static func _disable_shadows_recursive(node: Node) -> void:
	if node is GeometryInstance3D:
		(node as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for child in node.get_children():
		_disable_shadows_recursive(child)


static func _disable_collisions_recursive(node: Node) -> void:
	if node is CollisionObject3D:
		(node as CollisionObject3D).collision_layer = 0
		(node as CollisionObject3D).collision_mask = 0
	for child in node.get_children():
		_disable_collisions_recursive(child)


static func _apply_cyber_ambient_motion(instance: Node3D, category: String, generator: Node3D, chunk_index: int, side: float) -> void:
	if not _is_cyber_theme(generator):
		return
	var motion_profile: Dictionary = generator.theme_profile.get("ambient_motion", {})
	if not bool(motion_profile.get("enabled", false)):
		return

	var config: Dictionary = {
		"phase": float(chunk_index) * 0.73 + side * 0.41 + absf(instance.position.z) * 0.037,
	}

	match category:
		"signals":
			config["bob_height"] = float(motion_profile.get("signal_bob_height", 0.10))
			config["bob_speed"] = float(motion_profile.get("signal_bob_speed", 1.4))
			config["yaw_speed"] = float(motion_profile.get("signal_yaw_speed", 0.24)) * side
			config["sway_angle"] = 0.035
			config["sway_speed"] = 1.7
			config["roll_angle"] = 0.02
			config["light_range"] = 5.4
			config["light_min"] = float(motion_profile.get("signal_light_min", 0.35))
			config["light_max"] = float(motion_profile.get("signal_light_max", 0.88))
			config["light_speed"] = 2.4
			config["light_offset"] = Vector3(0.0, 1.7, 0.0)
			config["light_color"] = Color(0.10, 0.92, 1.0, 1.0) if side < 0.0 else Color(0.96, 0.22, 1.0, 1.0)
		"service_props":
			config["bob_height"] = float(motion_profile.get("service_bob_height", 0.04))
			config["bob_speed"] = float(motion_profile.get("service_bob_speed", 1.1))
			config["yaw_speed"] = float(motion_profile.get("service_yaw_speed", 0.12)) * side
			config["z_sway"] = 0.03
			if posmod(chunk_index + int(absf(instance.position.z)), 3) == 0:
				config["light_range"] = 3.8
				config["light_min"] = float(motion_profile.get("service_light_min", 0.18))
				config["light_max"] = float(motion_profile.get("service_light_max", 0.46))
				config["light_speed"] = 1.8
				config["light_offset"] = Vector3(0.0, 0.9, 0.0)
				config["light_color"] = Color(1.0, 0.72, 0.22, 1.0)
		"infrastructure", "skyline":
			if posmod(chunk_index + int(absf(instance.position.x)), 4) != 0:
				return
			config["light_range"] = 6.5
			config["light_min"] = 0.10
			config["light_max"] = 0.34
			config["light_speed"] = 1.1
			config["light_offset"] = Vector3(0.0, 2.8, 0.0)
			config["light_color"] = Color(0.10, 0.92, 1.0, 1.0)
		"scenic_overhead":
			config["bob_height"] = float(motion_profile.get("overhead_bob_height", 0.18))
			config["bob_speed"] = float(motion_profile.get("overhead_bob_speed", 0.9))
			config["yaw_speed"] = float(motion_profile.get("overhead_yaw_speed", 0.16)) * -side
			config["sway_angle"] = 0.02
			config["sway_speed"] = 1.1
			config["light_range"] = 7.2
			config["light_min"] = float(motion_profile.get("overhead_light_min", 0.26))
			config["light_max"] = float(motion_profile.get("overhead_light_max", 0.72))
			config["light_speed"] = 1.5
			config["light_offset"] = Vector3(0.0, 1.2, 0.0)
			config["light_color"] = Color(0.12, 0.88, 1.0, 1.0)
		_:
			return

	var motion := Node.new()
	motion.name = "CyberAmbientMotion"
	motion.set_script(CyberAmbientMotionScript)
	instance.add_child(motion)
	motion.call("configure", config)


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
